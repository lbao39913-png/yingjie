import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../models/cloud_video.dart';
import '../../services/auth_service.dart';
import '../../services/cloud_video_service.dart';
import '../../services/privacy_lock_service.dart';

enum PrivateGate { login, setupPin, locked, open }

class PrivateVideosState {
  const PrivateVideosState({
    this.gate = PrivateGate.login,
    this.items = const [],
    this.error,
    this.busy = false,
  });

  final PrivateGate gate;
  final List<CloudVideo> items;
  final AppException? error;
  final bool busy;

  PrivateVideosState copyWith({
    PrivateGate? gate,
    List<CloudVideo>? items,
    AppException? error,
    bool clearError = false,
    bool? busy,
  }) {
    return PrivateVideosState(
      gate: gate ?? this.gate,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
      busy: busy ?? this.busy,
    );
  }
}

class PrivateVideosController extends StateNotifier<PrivateVideosState> {
  PrivateVideosController({
    required this._auth,
    required this._lock,
    required this._videos,
  }) : super(const PrivateVideosState()) {
    _subscriptions = [
      _auth.changes.listen((_) => refresh()),
      _videos.changes.listen((_) => refresh()),
    ];
    refresh();
  }

  final AuthService _auth;
  final PrivacyLockService _lock;
  final CloudVideoService _videos;
  late final List<StreamSubscription<void>> _subscriptions;
  bool _disposed = false;

  String get userId => _auth.currentUser?.id ?? '';

  void refresh() {
    if (_disposed) {
      return;
    }
    if (!_auth.isLoggedIn) {
      _lock.lock();
      state = const PrivateVideosState(gate: PrivateGate.login);
      return;
    }
    final id = userId;
    if (!_lock.hasPin(id)) {
      state = const PrivateVideosState(gate: PrivateGate.setupPin);
      return;
    }
    if (!_lock.isUnlocked(id)) {
      state = const PrivateVideosState(gate: PrivateGate.locked);
      return;
    }
    state = PrivateVideosState(
      gate: PrivateGate.open,
      items: _videos.cachedPrivate(id),
    );
  }

  Future<bool> setupPin({
    required String pin,
    required String confirmPin,
  }) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _lock.setPin(userId: userId, pin: pin, confirmPin: confirmPin);
      refresh();
      return true;
    } on AppException catch (error) {
      if (_disposed) {
        return false;
      }
      state = state.copyWith(busy: false, error: error);
      return false;
    }
  }

  Future<bool> unlock(String pin) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _lock.unlock(userId: userId, pin: pin);
      refresh();
      return true;
    } on AppException catch (error) {
      if (_disposed) {
        return false;
      }
      state = state.copyWith(busy: false, error: error, gate: PrivateGate.locked);
      return false;
    }
  }

  Future<void> setPublic(CloudVideo video) async {
    try {
      await _videos.setPrivate(id: video.id, isPrivate: false);
      refresh();
    } on AppException catch (error) {
      if (_disposed) {
        return;
      }
      state = state.copyWith(error: error);
    }
  }

  Future<void> deleteCloud(String id) async {
    try {
      await _videos.deleteCloud(id);
      refresh();
    } on AppException catch (error) {
      if (_disposed) {
        return;
      }
      state = state.copyWith(error: error);
    }
  }

  Future<String> playUrlFor(CloudVideo video) {
    return _videos.playUrlFor(video);
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

final privateVideosControllerProvider = StateNotifierProvider.autoDispose<
    PrivateVideosController, PrivateVideosState>((ref) {
  return PrivateVideosController(
    auth: ref.watch(authServiceProvider),
    lock: ref.watch(privacyLockServiceProvider),
    videos: ref.watch(cloudVideoServiceProvider),
  );
});
