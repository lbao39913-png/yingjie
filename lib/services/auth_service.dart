import 'dart:async';

import '../core/errors/app_exception.dart';
import '../core/storage/token_store.dart';
import '../data/api/auth_api.dart';
import '../models/user.dart';
import 'sync_service.dart';

class AuthService {
  AuthService._(this._api, this._tokens, this._sync);

  factory AuthService({
    required AuthApi api,
    required TokenStore tokens,
    required SyncService sync,
  }) {
    return AuthService._(api, tokens, sync);
  }

  final AuthApi _api;
  final TokenStore _tokens;
  final SyncService _sync;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  AuthSnapshot _snapshot = const AuthSnapshot();

  Stream<void> get changes => _changes.stream;

  AuthSnapshot get snapshot => _snapshot;

  AuthStatus get status => _snapshot.status;

  User? get currentUser => _snapshot.user;

  bool get isLoggedIn => _snapshot.isLoggedIn;

  Future<void> restore() async {
    _set(const AuthSnapshot(status: AuthStatus.loading));
    final refresh = await _tokens.readRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      await _tokens.clear();
      _set(const AuthSnapshot(status: AuthStatus.loggedOut));
      return;
    }
    try {
      final session = await _api.refreshToken(refreshToken: refresh);
      await _persist(session);
      _set(
        AuthSnapshot(
          status: AuthStatus.loggedIn,
          user: session.user,
        ),
      );
      await _sync.pullAndMerge(session.accessToken);
    } catch (_) {
      await _tokens.clear();
      _set(const AuthSnapshot(status: AuthStatus.loggedOut));
    }
  }

  Future<void> login({
    required String account,
    required String password,
  }) {
    return _authenticate(
      () => _api.login(account: account.trim(), password: password),
    );
  }

  Future<void> register({
    required String account,
    required String password,
    required String confirmPassword,
  }) async {
    final trimmed = account.trim();
    if (trimmed.isEmpty || password.isEmpty) {
      throw const AuthException(message: '账号或密码错误');
    }
    if (password != confirmPassword) {
      throw const AuthException(message: '两次密码不一致');
    }
    await _authenticate(
      () => _api.register(account: trimmed, password: password),
    );
  }

  Future<void> logout() async {
    _set(_snapshot.copyWith(status: AuthStatus.loading));
    final access = await _tokens.readAccessToken();
    if (access != null && access.isNotEmpty) {
      try {
        await _api.logout(accessToken: access);
      } catch (_) {}
    }
    await _tokens.clear();
    _set(const AuthSnapshot(status: AuthStatus.loggedOut));
  }

  Future<void> _authenticate(Future<AuthSession> Function() action) async {
    _set(_snapshot.copyWith(status: AuthStatus.loading, errorMessage: ''));
    try {
      final session = await action();
      await _persist(session);
      _set(
        AuthSnapshot(
          status: AuthStatus.loggedIn,
          user: session.user,
        ),
      );
      await _sync.pullAndMerge(session.accessToken);
    } on AppException catch (error) {
      _set(
        AuthSnapshot(
          status: AuthStatus.error,
          errorMessage: error.message,
        ),
      );
      rethrow;
    } catch (error) {
      _set(
        const AuthSnapshot(
          status: AuthStatus.error,
          errorMessage: '服务器异常，请稍后重试',
        ),
      );
      throw const ServerException(message: '服务器异常，请稍后重试');
    }
  }

  Future<void> _persist(AuthSession session) {
    return _tokens.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
  }

  void _set(AuthSnapshot snapshot) {
    _snapshot = snapshot;
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  void dispose() {
    _changes.close();
  }
}
