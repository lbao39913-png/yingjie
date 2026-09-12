class AppConstants {
  AppConstants._();

  static const int defaultPageSize = 12;
  static const int homeRecommendPageSize = 6;
  static const int searchPageSize = 6;
  static const int searchHistoryLimit = 20;
  static const int detailRelatedLimit = 8;
  static const Duration searchDebounce = Duration(milliseconds: 400);
  static const Duration splashDelay = Duration(milliseconds: 300);
  static const Duration playerControlsHide = Duration(seconds: 3);
  static const int playbackResumeMinMs = 5000;
  static const int playbackNearEndMs = 5000;
  static const Duration playbackSaveInterval = Duration(seconds: 10);
  static const List<double> playerSpeeds = [
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    2.0,
  ];

  static const String hiveSettingsBox = 'settings';
  static const String hiveSearchHistoryBox = 'search_history';
  static const String hiveFavoritesBox = 'favorites';
  static const String hivePlaybackHistoryBox = 'playback_history';
  static const String hiveLocalVideosBox = 'local_videos';
  static const String hiveCloudVideosBox = 'cloud_videos';

  static const int uploadChunkSize = 256 * 1024;
  static const int uploadChunkRetries = 2;
  static const String settingPrivacyPinHashPrefix = 'privacy_pin_hash_';
  static const String settingPrivacyPinSaltPrefix = 'privacy_pin_salt_';

  static const String defaultPlaySpeed = '1.0';
  static const String settingAutoPlay = 'auto_play';
  static const String settingAutoReturnAfterCompletion =
      'auto_return_after_completion';
  static const String settingPlaySpeed = 'play_speed';

  static double normalizeSpeed(double speed) {
    var closest = playerSpeeds.first;
    var best = (speed - closest).abs();
    for (final item in playerSpeeds.skip(1)) {
      final delta = (speed - item).abs();
      if (delta < best) {
        closest = item;
        best = delta;
      }
    }
    return closest;
  }
}
