import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../errors/app_exception.dart';

class LocalStorage {
  LocalStorage._();

  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) {
      return;
    }
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<dynamic>(AppConstants.hiveSettingsBox),
      Hive.openBox<dynamic>(AppConstants.hiveSearchHistoryBox),
      Hive.openBox<dynamic>(AppConstants.hiveFavoritesBox),
      Hive.openBox<dynamic>(AppConstants.hivePlaybackHistoryBox),
      Hive.openBox<dynamic>(AppConstants.hiveLocalVideosBox),
      Hive.openBox<dynamic>(AppConstants.hiveCloudVideosBox),
    ]);
    _ready = true;
  }

  static Future<void> initForTest(String path) async {
    try {
      await Hive.close();
    } catch (_) {}
    _ready = false;
    Hive.init(path);
    await Future.wait([
      Hive.openBox<dynamic>(AppConstants.hiveSettingsBox),
      Hive.openBox<dynamic>(AppConstants.hiveSearchHistoryBox),
      Hive.openBox<dynamic>(AppConstants.hiveFavoritesBox),
      Hive.openBox<dynamic>(AppConstants.hivePlaybackHistoryBox),
      Hive.openBox<dynamic>(AppConstants.hiveLocalVideosBox),
      Hive.openBox<dynamic>(AppConstants.hiveCloudVideosBox),
    ]);
    _ready = true;
  }

  static Future<void> resetForTest() async {
    try {
      await Hive.close();
    } catch (_) {}
    _ready = false;
  }

  static Box<dynamic> settingsBox() => _box(AppConstants.hiveSettingsBox);

  static Box<dynamic> searchHistoryBox() =>
      _box(AppConstants.hiveSearchHistoryBox);

  static Box<dynamic> favoritesBox() => _box(AppConstants.hiveFavoritesBox);

  static Box<dynamic> playbackHistoryBox() =>
      _box(AppConstants.hivePlaybackHistoryBox);

  static Box<dynamic> localVideosBox() => _box(AppConstants.hiveLocalVideosBox);

  static Box<dynamic> cloudVideosBox() => _box(AppConstants.hiveCloudVideosBox);

  static Future<void> clearPlaybackHistory() {
    return playbackHistoryBox().clear();
  }

  static Future<void> clearSearchHistory() {
    return searchHistoryBox().clear();
  }

  static Future<void> clearCache() async {
    await Future.wait([
      settingsBox().clear(),
      searchHistoryBox().clear(),
      favoritesBox().clear(),
      playbackHistoryBox().clear(),
    ]);
  }

  static Box<dynamic> _box(String name) {
    if (!_ready || !Hive.isBoxOpen(name)) {
      throw CacheException(cause: StateError('Hive box $name is not open'));
    }
    return Hive.box<dynamic>(name);
  }
}
