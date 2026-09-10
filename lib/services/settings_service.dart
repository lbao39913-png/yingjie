import 'dart:async';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/storage/local_storage.dart';

class SettingsService {
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  bool get autoPlay => _readBool(AppConstants.settingAutoPlay, true);

  bool get autoReturnAfterCompletion =>
      _readBool(AppConstants.settingAutoReturnAfterCompletion, false);

  Future<void> setAutoPlay(bool value) {
    return _writeBool(AppConstants.settingAutoPlay, value);
  }

  Future<void> setAutoReturnAfterCompletion(bool value) {
    return _writeBool(AppConstants.settingAutoReturnAfterCompletion, value);
  }

  double get playSpeed {
    try {
      final raw = LocalStorage.settingsBox().get(AppConstants.settingPlaySpeed);
      if (raw is num) {
        return AppConstants.normalizeSpeed(raw.toDouble());
      }
      if (raw is String) {
        return AppConstants.normalizeSpeed(double.tryParse(raw) ?? 1.0);
      }
      return 1.0;
    } on CacheException {
      return 1.0;
    }
  }

  Future<void> setPlaySpeed(double value) async {
    try {
      await LocalStorage.settingsBox().put(
        AppConstants.settingPlaySpeed,
        AppConstants.normalizeSpeed(value),
      );
      _notify();
    } on CacheException {
      return;
    }
  }

  bool _readBool(String key, bool fallback) {
    try {
      final raw = LocalStorage.settingsBox().get(key);
      if (raw is bool) {
        return raw;
      }
      return fallback;
    } on CacheException {
      return fallback;
    }
  }

  Future<void> _writeBool(String key, bool value) async {
    try {
      await LocalStorage.settingsBox().put(key, value);
      _notify();
    } on CacheException {
      return;
    }
  }

  void _notify() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
