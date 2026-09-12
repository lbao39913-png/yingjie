import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../models/cloud_video.dart';
import '../api/cloud_video_api.dart';

class _StoredUpload {
  _StoredUpload({
    required this.uploadId,
    required this.chunkSize,
    required this.chunkTotal,
  });

  final String uploadId;
  final int chunkSize;
  final int chunkTotal;
  final Set<int> received = <int>{};
}

class MockCloudVideoApi implements CloudVideoApi {
  MockCloudVideoApi({
    this.resolveUserId,
    this.chunkSize = AppConstants.uploadChunkSize,
  });

  final String? Function(String accessToken)? resolveUserId;
  final int chunkSize;
  final Map<String, Map<String, CloudVideo>> _byUser = {};
  final Map<String, _StoredUpload> _uploads = {};
  int _seq = 0;
  int _uploadSeq = 0;

  int Function(String id, int index)? onChunk;

  @override
  Future<List<CloudVideo>> list({
    required String accessToken,
    bool includePrivate = false,
  }) async {
    final userId = _userId(accessToken);
    final items = (_byUser[userId] ?? {}).values.toList(growable: false);
    if (includePrivate) {
      return items;
    }
    return items.where((item) => !item.isPrivate).toList(growable: false);
  }

  @override
  Future<CloudVideo> create({
    required String accessToken,
    required String title,
    required int sizeBytes,
    bool isPrivate = false,
  }) async {
    final userId = _userId(accessToken);
    final now = DateTime.now().toUtc();
    _seq += 1;
    final video = CloudVideo(
      id: 'cv-$userId-$_seq',
      userId: userId,
      title: title.trim().isEmpty ? '未命名视频' : title.trim(),
      sizeBytes: sizeBytes < 0 ? 0 : sizeBytes,
      isPrivate: isPrivate,
      status: CloudVideoStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    _videos(userId)[video.id] = video;
    return video;
  }

  @override
  Future<CloudVideo> get({
    required String accessToken,
    required String id,
  }) async {
    return _owned(accessToken, id);
  }

  @override
  Future<void> delete({
    required String accessToken,
    required String id,
  }) async {
    final video = _owned(accessToken, id);
    _videos(video.userId).remove(id);
    _uploads.remove(id);
  }

  @override
  Future<UploadSession> startUpload({
    required String accessToken,
    required String id,
  }) async {
    final video = _owned(accessToken, id);
    _uploadSeq += 1;
    final total = _chunkTotal(video.sizeBytes);
    final session = _StoredUpload(
      uploadId: 'up-$_uploadSeq',
      chunkSize: chunkSize,
      chunkTotal: total,
    );
    _uploads[id] = session;
    final next = video.copyWith(
      status: CloudVideoStatus.uploading,
      uploadId: session.uploadId,
      chunkTotal: total,
      chunkIndex: 0,
      uploadedBytes: 0,
      updatedAt: DateTime.now().toUtc(),
    );
    _videos(video.userId)[id] = next;
    return UploadSession(
      videoId: id,
      uploadId: session.uploadId,
      chunkSize: session.chunkSize,
      chunkTotal: session.chunkTotal,
    );
  }

  @override
  Future<void> uploadChunk({
    required String accessToken,
    required String id,
    required String uploadId,
    required int index,
    required List<int> bytes,
  }) async {
    final video = _owned(accessToken, id);
    final session = _uploads[id];
    if (session == null || session.uploadId != uploadId) {
      throw const ServerException(message: '上传未完成，请重试');
    }
    if (index < 0 || index >= session.chunkTotal) {
      throw const ServerException(message: '上传未完成，请重试');
    }
    final fail = onChunk?.call(id, index) ?? 0;
    if (fail > 0) {
      onChunk = null;
      throw const NetworkException(message: '网络连接失败，请检查网络');
    }
    session.received.add(index);
    final uploaded = _uploadedBytes(video.sizeBytes, session);
    _videos(video.userId)[id] = video.copyWith(
      status: CloudVideoStatus.uploading,
      uploadedBytes: uploaded,
      chunkIndex: session.received.length,
      chunkTotal: session.chunkTotal,
      uploadId: session.uploadId,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<CloudVideo> completeUpload({
    required String accessToken,
    required String id,
    required String uploadId,
  }) async {
    final video = _owned(accessToken, id);
    final session = _uploads[id];
    if (session == null ||
        session.uploadId != uploadId ||
        session.received.length != session.chunkTotal) {
      throw const ServerException(message: '上传未完成，请重试');
    }
    _uploads.remove(id);
    final next = video.copyWith(
      status: CloudVideoStatus.uploaded,
      uploadedBytes: video.sizeBytes,
      chunkIndex: session.chunkTotal,
      chunkTotal: session.chunkTotal,
      uploadId: uploadId,
      playUrl: '',
      updatedAt: DateTime.now().toUtc(),
    );
    _videos(video.userId)[id] = next;
    return next;
  }

  @override
  Future<String> downloadUrl({
    required String accessToken,
    required String id,
  }) async {
    final video = _owned(accessToken, id);
    if (!video.isUploaded) {
      throw const ServerException(message: '视频尚未上传完成');
    }
    final remote = video.playUrl.trim();
    if (remote.isNotEmpty) {
      return remote;
    }
    return 'mock://videos/${video.userId}/${video.id}';
  }

  @override
  Future<CloudVideo> patch({
    required String accessToken,
    required String id,
    String? title,
    bool? isPrivate,
  }) async {
    final video = _owned(accessToken, id);
    final next = video.copyWith(
      title: title ?? video.title,
      isPrivate: isPrivate ?? video.isPrivate,
      updatedAt: DateTime.now().toUtc(),
    );
    _videos(video.userId)[id] = next;
    return next;
  }

  CloudVideo? stored(String userId, String id) {
    return _byUser[userId]?[id];
  }

  List<CloudVideo> storedFor(String userId) {
    return (_byUser[userId] ?? {}).values.toList(growable: false);
  }

  Map<String, CloudVideo> _videos(String userId) {
    return _byUser.putIfAbsent(userId, () => <String, CloudVideo>{});
  }

  CloudVideo _owned(String accessToken, String id) {
    final userId = _userId(accessToken);
    final video = _videos(userId)[id];
    if (video == null) {
      throw const NotFoundException(message: '视频不存在');
    }
    return video;
  }

  int _chunkTotal(int sizeBytes) {
    if (sizeBytes <= 0) {
      return 1;
    }
    return (sizeBytes + chunkSize - 1) ~/ chunkSize;
  }

  int _uploadedBytes(int sizeBytes, _StoredUpload session) {
    if (session.chunkTotal <= 0) {
      return 0;
    }
    var total = 0;
    for (final index in session.received) {
      final offset = index * session.chunkSize;
      var len = session.chunkSize;
      if (offset + len > sizeBytes) {
        len = sizeBytes - offset;
      }
      if (len > 0) {
        total += len;
      }
    }
    return total;
  }

  String _userId(String accessToken) {
    if (resolveUserId != null) {
      final id = resolveUserId!(accessToken);
      if (id == null || id.isEmpty) {
        throw const AuthException(message: '登录已过期，请重新登录');
      }
      return id;
    }
    final parts = accessToken.split('.');
    if (parts.length < 2 || parts[1].isEmpty) {
      throw const AuthException(message: '登录已过期，请重新登录');
    }
    return parts[1];
  }
}
