import 'dart:math';

import '../../core/errors/app_exception.dart';
import '../../models/user.dart';
import '../api/auth_api.dart';

class _MockAccount {
  _MockAccount({
    required this.user,
    required this.passwordHash,
  });

  final User user;
  final int passwordHash;
}

class MockAuthApi implements AuthApi {
  MockAuthApi({Random? random}) : _random = random ?? Random();

  final Random _random;
  final Map<String, _MockAccount> _accounts = {};
  final Map<String, String> _accessToUser = {};
  final Map<String, String> _refreshToUser = {};

  int get accountCount => _accounts.length;

  @override
  Future<AuthSession> register({
    required String account,
    required String password,
  }) async {
    final username = account.trim();
    _requireCredentials(username, password);
    if (_accounts.containsKey(username)) {
      throw const AuthException(message: '该账号已被注册');
    }
    final user = User(
      id: 'user-${_accounts.length + 1}',
      username: username,
      nickname: username,
      createdAt: DateTime.now().toUtc(),
    );
    _accounts[username] = _MockAccount(
      user: user,
      passwordHash: password.hashCode,
    );
    return _issue(user);
  }

  @override
  Future<AuthSession> login({
    required String account,
    required String password,
  }) async {
    final username = account.trim();
    _requireCredentials(username, password);
    final stored = _accounts[username];
    if (stored == null || stored.passwordHash != password.hashCode) {
      throw const AuthException(message: '账号或密码错误');
    }
    return _issue(stored.user);
  }

  @override
  Future<void> logout({required String accessToken}) async {
    final userId = _accessToUser.remove(accessToken);
    if (userId == null) {
      return;
    }
    _refreshToUser.removeWhere((_, id) => id == userId);
  }

  @override
  Future<User> getCurrentUser({required String accessToken}) async {
    final userId = _accessToUser[accessToken];
    if (userId == null) {
      throw const AuthException(message: '登录已过期，请重新登录');
    }
    return _userById(userId);
  }

  @override
  Future<AuthSession> refreshToken({required String refreshToken}) async {
    final userId = _refreshToUser.remove(refreshToken);
    if (userId == null) {
      throw const AuthException(message: '登录已过期，请重新登录');
    }
    _accessToUser.removeWhere((_, id) => id == userId);
    return _issue(_userById(userId));
  }

  void expireAccess(String accessToken) {
    _accessToUser.remove(accessToken);
  }

  void expireRefresh(String refreshToken) {
    _refreshToUser.remove(refreshToken);
  }

  void _requireCredentials(String account, String password) {
    if (account.isEmpty || password.isEmpty) {
      throw const AuthException(message: '账号或密码错误');
    }
  }

  User _userById(String userId) {
    for (final item in _accounts.values) {
      if (item.user.id == userId) {
        return item.user;
      }
    }
    throw const AuthException(message: '登录已过期，请重新登录');
  }

  AuthSession _issue(User user) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final nonce = _random.nextInt(1 << 32);
    final access = 'acc.${user.id}.$stamp.$nonce';
    final refresh = 'ref.${user.id}.$stamp.$nonce';
    _accessToUser[access] = user.id;
    _refreshToUser[refresh] = user.id;
    return AuthSession(
      user: user,
      accessToken: access,
      refreshToken: refresh,
    );
  }
}
