import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/storage/local_storage.dart';

class PrivacyLockService {
  PrivacyLockService({Random? random}) : _random = random ?? Random.secure();

  final Random _random;
  String? _unlockedUserId;

  bool hasPin(String userId) {
    final id = userId.trim();
    if (id.isEmpty) {
      return false;
    }
    try {
      final hash = LocalStorage.settingsBox().get(_hashKey(id));
      return hash is String && hash.isNotEmpty;
    } on CacheException {
      return false;
    }
  }

  bool isUnlocked(String userId) {
    return _unlockedUserId != null && _unlockedUserId == userId.trim();
  }

  void lock() {
    _unlockedUserId = null;
  }

  Future<void> setPin({
    required String userId,
    required String pin,
    required String confirmPin,
  }) async {
    final id = userId.trim();
    if (id.isEmpty) {
      throw const AuthException(message: '登录后才能设置隐私 PIN');
    }
    _requirePin(pin);
    if (pin != confirmPin) {
      throw const AuthException(message: '两次 PIN 不一致');
    }
    final salt = _newSalt();
    try {
      await LocalStorage.settingsBox().put(_saltKey(id), salt);
      await LocalStorage.settingsBox().put(_hashKey(id), _hash(pin, salt));
      _unlockedUserId = id;
    } on CacheException {
      throw const CacheException(message: '本地数据读取失败');
    }
  }

  Future<bool> unlock({
    required String userId,
    required String pin,
  }) async {
    final id = userId.trim();
    if (id.isEmpty) {
      throw const AuthException(message: '登录后才能查看隐私视频');
    }
    _requirePin(pin);
    try {
      final salt = LocalStorage.settingsBox().get(_saltKey(id));
      final hash = LocalStorage.settingsBox().get(_hashKey(id));
      if (salt is! String || hash is! String || salt.isEmpty || hash.isEmpty) {
        throw const AuthException(message: '请先设置隐私 PIN');
      }
      if (_hash(pin, salt) != hash) {
        throw const AuthException(message: 'PIN 错误');
      }
      _unlockedUserId = id;
      return true;
    } on AuthException {
      rethrow;
    } on CacheException {
      throw const CacheException(message: '本地数据读取失败');
    }
  }

  void _requirePin(String pin) {
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      throw const AuthException(message: '请输入 4 到 6 位数字 PIN');
    }
  }

  String _newSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hash(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  String _hashKey(String userId) =>
      '${AppConstants.settingPrivacyPinHashPrefix}$userId';

  String _saltKey(String userId) =>
      '${AppConstants.settingPrivacyPinSaltPrefix}$userId';
}
