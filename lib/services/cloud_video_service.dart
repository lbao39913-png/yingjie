import 'dart:async';

import '../core/errors/app_exception.dart';
import '../core/storage/local_storage.dart';
import '../core/storage/token_store.dart';
import '../data/api/cloud_video_api.dart';
import '../models/cloud_video.dart';
import '../models/local_video.dart';
import 'byte_source.dart';
import 'upload_service.dart';

class CloudVideoService {
  CloudVideoService({
    required this._api,
    required this._tokens,
    required this._upload,
  });

  final CloudVideoApi _api;
  final TokenStore _tokens;
  final UploadService _upload;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  List<CloudVideo> cached({
    required String userId,
    required bool includePrivate,
  }) {
    final id = userId.trim();
    if (id.isEmpty) {
      return const [];
    }
    try {
      final items = <CloudVideo>[];
      for (final raw in LocalStorage.cloudVideosBox().values) {
        if (raw is! Map) {
          continue;
        }
        final video = CloudVideo.fromJson(Map<String, dynamic>.from(raw));
        if (video.userId != id) {
          continue;
        }
        if (!includePrivate && video.isPrivate) {
          continue;
        }
        if (includePrivate && !video.isPrivate) {
          continue;
        }
        items.add(video);
      }
      items.sort((a, b) {
        final left = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
      return items;
    } on CacheException {
      return const [];
    }
  }

  List<CloudVideo> cachedPublic(String userId) {
    return cached(userId: userId, includePrivate: false);
  }

  List<CloudVideo> cachedPrivate(String userId) {
    return cached(userId: userId, includePrivate: true);
  }

  Future<void> replaceUserCache(String userId, List<CloudVideo> videos) async {
    final id = userId.trim();
    if (id.isEmpty) {
      return;
    }
    try {
      final box = LocalStorage.cloudVideosBox();
      final previous = <String, CloudVideo>{};
      for (final raw in box.values) {
        if (raw is! Map) {
          continue;
        }
        final item = CloudVideo.fromJson(Map<String, dynamic>.from(raw));
        if (item.userId == id) {
          previous[item.id] = item;
        }
      }
      final keys = box.keys.where((key) {
        return key.toString().startsWith('$id::');
      }).toList(growable: false);
      for (final key in keys) {
        await box.delete(key);
      }
      for (final video in videos) {
        final merged = video.copyWith(
          localPath: video.localPath.isNotEmpty
              ? video.localPath
              : (previous[video.id]?.localPath ?? ''),
        );
        await box.put(_key(id, merged.id), merged.toJson());
      }
      _notify();
    } on CacheException {
      return;
    }
  }

  Future<CloudVideo> uploadFromLocal({
    required LocalVideo local,
    bool isPrivate = false,
    ByteSource? source,
    UploadProgress? onProgress,
  }) async {
    final token = await _requireToken();
    CloudVideo created;
    try {
      created = await _api.create(
        accessToken: token,
        title: local.title,
        sizeBytes: local.sizeBytes,
        isPrivate: isPrivate,
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException(message: '上传失败，请重试');
    }
    var pending = created.copyWith(
      localPath: local.filePath,
      status: CloudVideoStatus.uploading,
    );
    await _save(pending);
    try {
      final bytes = source ?? await FileByteSource.open(local.filePath);
      final session = await _api.startUpload(
        accessToken: token,
        id: created.id,
      );
      pending = pending.copyWith(
        uploadId: session.uploadId,
        chunkTotal: session.chunkTotal,
        status: CloudVideoStatus.uploading,
      );
      await _save(pending);
      final uploaded = await _upload.upload(
        api: _api,
        accessToken: token,
        videoId: created.id,
        source: bytes,
        session: session,
        onProgress: (sent, total) {
          onProgress?.call(sent, total);
          unawaited(
            _save(
              pending.copyWith(
                uploadedBytes: sent,
                status: CloudVideoStatus.uploading,
              ),
            ),
          );
        },
      );
      final next = uploaded.copyWith(
        localPath: local.filePath,
        isPrivate: isPrivate,
        status: CloudVideoStatus.uploaded,
        uploadedBytes: local.sizeBytes,
      );
      await _save(next);
      return next;
    } catch (error) {
      final failed = pending.copyWith(status: CloudVideoStatus.failed);
      await _save(failed);
      if (error is AppException) {
        rethrow;
      }
      throw const NetworkException(message: '上传失败，请重试');
    }
  }

  Future<CloudVideo> retryUpload({
    required CloudVideo video,
    ByteSource? source,
    UploadProgress? onProgress,
  }) async {
    final path = video.localPath.trim();
    if (path.isEmpty) {
      throw const CacheException(message: '无法读取所选视频');
    }
    final token = await _requireToken();
    var pending = video.copyWith(status: CloudVideoStatus.uploading);
    await _save(pending);
    try {
      final bytes = source ?? await FileByteSource.open(path);
      final session = await _api.startUpload(
        accessToken: token,
        id: video.id,
      );
      pending = pending.copyWith(
        uploadId: session.uploadId,
        chunkTotal: session.chunkTotal,
        status: CloudVideoStatus.uploading,
      );
      await _save(pending);
      final uploaded = await _upload.upload(
        api: _api,
        accessToken: token,
        videoId: video.id,
        source: bytes,
        session: session,
        onProgress: onProgress,
      );
      final next = uploaded.copyWith(
        localPath: path,
        isPrivate: video.isPrivate,
        status: CloudVideoStatus.uploaded,
        uploadedBytes: video.sizeBytes,
      );
      await _save(next);
      return next;
    } catch (error) {
      await _save(pending.copyWith(status: CloudVideoStatus.failed));
      if (error is AppException) {
        rethrow;
      }
      throw const NetworkException(message: '上传失败，请重试');
    }
  }

  Future<void> deleteCloud(String id) async {
    final token = await _requireToken();
    try {
      await _api.delete(accessToken: token, id: id);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException(message: '删除失败，请重试');
    }
    try {
      final box = LocalStorage.cloudVideosBox();
      final keys = box.keys.where((key) {
        return key.toString().endsWith('::$id');
      }).toList(growable: false);
      for (final key in keys) {
        await box.delete(key);
      }
      _notify();
    } on CacheException {
      return;
    }
  }

  Future<CloudVideo> setPrivate({
    required String id,
    required bool isPrivate,
  }) async {
    final token = await _requireToken();
    try {
      final updated = await _api.patch(
        accessToken: token,
        id: id,
        isPrivate: isPrivate,
      );
      final existing = _find(id);
      final next = updated.copyWith(
        localPath: existing?.localPath ?? updated.localPath,
      );
      await _save(next);
      return next;
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException(message: '服务器异常，请稍后重试');
    }
  }

  Future<String> playUrlFor(CloudVideo video) async {
    final local = video.resolvedPlayUrl;
    if (local != null &&
        (local.startsWith('file:') ||
            local.startsWith('content:') ||
            local.startsWith('http://') ||
            local.startsWith('https://'))) {
      return local;
    }
    if (!video.isUploaded) {
      throw const PlaybackException(message: '视频尚未上传完成');
    }
    final token = await _requireToken();
    try {
      final url = await _api.downloadUrl(accessToken: token, id: video.id);
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return url;
      }
    } on AppException {
      // Fall through to local file when mock cloud has no real URL.
    }
    if (local != null && local.isNotEmpty && !local.startsWith('mock:')) {
      return local;
    }
    final path = video.localPath.trim();
    if (path.isNotEmpty) {
      return Uri.file(path).toString();
    }
    throw const PlaybackException(message: '当前线路无法播放，请尝试其他线路');
  }

  CloudVideo? _find(String id) {
    try {
      for (final raw in LocalStorage.cloudVideosBox().values) {
        if (raw is! Map) {
          continue;
        }
        final video = CloudVideo.fromJson(Map<String, dynamic>.from(raw));
        if (video.id == id) {
          return video;
        }
      }
    } on CacheException {
      return null;
    }
    return null;
  }

  Future<void> _save(CloudVideo video) async {
    if (video.id.isEmpty || video.userId.isEmpty) {
      return;
    }
    try {
      await LocalStorage.cloudVideosBox().put(
        _key(video.userId, video.id),
        video.toJson(),
      );
      _notify();
    } on CacheException {
      return;
    }
  }

  Future<String> _requireToken() async {
    final token = await _tokens.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthException(message: '登录后才能上传云视频');
    }
    return token;
  }

  String _key(String userId, String id) => '$userId::$id';

  void _notify() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  void dispose() {
    _changes.close();
  }
}
