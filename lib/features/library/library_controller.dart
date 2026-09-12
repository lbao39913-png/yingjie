import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/storage/token_store.dart';
import '../../models/cloud_video.dart';
import '../../models/local_video.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/cloud_video_service.dart';
import '../../services/cloud_video_sync_service.dart';
import '../../services/local_video_service.dart';
import '../../services/video_picker.dart';

enum LibraryStatus { loading, ready, error }

class LibraryState {
  const LibraryState({
    this.status = LibraryStatus.loading,
    this.local = const [],
    this.cloud = const [],
    this.auth = const AuthSnapshot(),
    this.error,
    this.busyId = '',
    this.notice = '',
  });

  final LibraryStatus status;
  final List<LocalVideo> local;
  final List<CloudVideo> cloud;
  final AuthSnapshot auth;
  final AppException? error;
  final String busyId;
  final String notice;

  bool get loggedIn => auth.isLoggedIn;

  String get userId => auth.user?.id ?? '';

  LibraryState copyWith({
    LibraryStatus? status,
    List<LocalVideo>? local,
    List<CloudVideo>? cloud,
    AuthSnapshot? auth,
    AppException? error,
    bool clearError = false,
    String? busyId,
    String? notice,
  }) {
    return LibraryState(
      status: status ?? this.status,
      local: local ?? this.local,
      cloud: cloud ?? this.cloud,
      auth: auth ?? this.auth,
      error: clearError ? null : (error ?? this.error),
      busyId: busyId ?? this.busyId,
      notice: notice ?? this.notice,
    );
  }
}

class LibraryController extends StateNotifier<LibraryState> {
  LibraryController({
    required this._local,
    required this._cloud,
    required this._sync,
    required this._auth,
    required this._picker,
    required this._tokens,
  }) : super(const LibraryState()) {
    _subscriptions = [
      _local.changes.listen((_) => refresh()),
      _cloud.changes.listen((_) => refresh()),
      _auth.changes.listen((_) => refresh()),
    ];
    refresh();
    unawaited(pullCloud());
  }

  final LocalVideoService _local;
  final CloudVideoService _cloud;
  final CloudVideoSyncService _sync;
  final AuthService _auth;
  final VideoPicker _picker;
  final TokenStore _tokens;
  late final List<StreamSubscription<void>> _subscriptions;
  bool _disposed = false;

  void refresh() {
    if (_disposed) {
      return;
    }
    final auth = _auth.snapshot;
    state = state.copyWith(
      status: LibraryStatus.ready,
      local: _local.all(),
      cloud: auth.user == null
          ? const []
          : _cloud.cachedPublic(auth.user!.id),
      auth: auth,
      clearError: true,
    );
  }

  Future<void> pullCloud() async {
    if (!_auth.isLoggedIn) {
      refresh();
      return;
    }
    final token = await _tokens.readAccessToken();
    if (token == null || token.isEmpty) {
      refresh();
      return;
    }
    await _sync.pull(token, userId: _auth.currentUser?.id);
    refresh();
  }

  Future<void> importLocal() async {
    try {
      final picked = await _picker.pickVideo();
      if (picked == null) {
        return;
      }
      await _local.import(
        title: _titleFromName(picked.name),
        filePath: picked.path,
        sizeBytes: picked.sizeBytes,
      );
    } on AppException catch (error) {
      _setError(error);
    } catch (_) {
      _setError(const CacheException(message: '无法读取所选视频'));
    }
  }

  Future<void> importPicked(PickedLocalVideo picked) {
    return _local.import(
      title: _titleFromName(picked.name),
      filePath: picked.path,
      sizeBytes: picked.sizeBytes,
    );
  }

  Future<void> removeLocal(String id) async {
    await _local.remove(id);
  }

  Future<void> uploadLocal(LocalVideo video, {bool isPrivate = false}) async {
    if (!_auth.isLoggedIn) {
      _setError(const AuthException(message: '登录后才能上传云视频'));
      return;
    }
    state = state.copyWith(busyId: video.id, notice: '');
    try {
      await _cloud.uploadFromLocal(local: video, isPrivate: isPrivate);
      if (_disposed) {
        return;
      }
      state = state.copyWith(
        busyId: '',
        notice: isPrivate ? '已加入隐私视频' : '已加入云视频',
      );
      refresh();
    } on AppException catch (error) {
      if (_disposed) {
        return;
      }
      state = state.copyWith(busyId: '', error: error);
    } catch (_) {
      if (_disposed) {
        return;
      }
      state = state.copyWith(
        busyId: '',
        error: const NetworkException(message: '上传失败，请重试'),
      );
    }
  }

  Future<void> retryCloud(CloudVideo video) async {
    state = state.copyWith(busyId: video.id, notice: '');
    try {
      await _cloud.retryUpload(video: video);
      if (_disposed) {
        return;
      }
      state = state.copyWith(busyId: '', notice: '已加入云视频');
      refresh();
    } on AppException catch (error) {
      if (_disposed) {
        return;
      }
      state = state.copyWith(busyId: '', error: error);
    }
  }

  Future<void> deleteCloud(String id) async {
    try {
      await _cloud.deleteCloud(id);
      refresh();
    } on AppException catch (error) {
      _setError(error);
    }
  }

  Future<void> setPrivate(CloudVideo video, bool isPrivate) async {
    try {
      await _cloud.setPrivate(id: video.id, isPrivate: isPrivate);
      refresh();
    } on AppException catch (error) {
      _setError(error);
    }
  }

  Future<String> playUrlFor(CloudVideo video) {
    return _cloud.playUrlFor(video);
  }

  void clearNotice() {
    if (state.notice.isNotEmpty) {
      state = state.copyWith(notice: '');
    }
  }

  String _titleFromName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '本地视频';
    }
    final dot = trimmed.lastIndexOf('.');
    if (dot <= 0) {
      return trimmed;
    }
    return trimmed.substring(0, dot);
  }

  void _setError(AppException error) {
    if (_disposed) {
      return;
    }
    state = state.copyWith(status: LibraryStatus.ready, error: error);
  }

  @override
  void dispose() {
    _disposed = true;
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}

final libraryControllerProvider =
    StateNotifierProvider.autoDispose<LibraryController, LibraryState>((ref) {
  return LibraryController(
    local: ref.watch(localVideoServiceProvider),
    cloud: ref.watch(cloudVideoServiceProvider),
    sync: ref.watch(cloudVideoSyncServiceProvider),
    auth: ref.watch(authServiceProvider),
    picker: ref.watch(videoPickerProvider),
    tokens: ref.watch(tokenStoreProvider),
  );
});
