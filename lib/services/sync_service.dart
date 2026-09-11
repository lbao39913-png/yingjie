import '../core/errors/app_exception.dart';
import '../data/api/cloud_sync_api.dart';
import '../models/user_cloud_data.dart';
import 'favorite_service.dart';
import 'history_service.dart';
import 'search_service.dart';
import 'settings_service.dart';

class SyncService {
  SyncService._(
    this._api,
    this._favorites,
    this._history,
    this._search,
    this._settings,
  );

  factory SyncService({
    required CloudSyncApi api,
    required FavoriteService favorites,
    required HistoryService history,
    required SearchService search,
    required SettingsService settings,
  }) {
    return SyncService._(api, favorites, history, search, settings);
  }

  final CloudSyncApi _api;
  final FavoriteService _favorites;
  final HistoryService _history;
  final SearchService _search;
  final SettingsService _settings;

  Future<void> pullAndMerge(String accessToken) async {
    UserCloudData cloud;
    try {
      cloud = await _api.pull(accessToken: accessToken);
    } on AppException {
      return;
    }
    await _favorites.mergeAll(cloud.favorites);
    await _history.mergeAll(cloud.playbackHistory);
    await _search.mergeHistory(cloud.searchHistory);
    await _settings.mergeFromCloud(
      autoPlay: cloud.autoPlay,
      autoReturnAfterCompletion: cloud.autoReturnAfterCompletion,
      playSpeed: cloud.playSpeed,
    );
    await push(accessToken);
  }

  Future<void> push(String accessToken) async {
    try {
      await _api.push(
        accessToken: accessToken,
        data: snapshot(),
      );
    } on AppException {
      return;
    }
  }

  UserCloudData snapshot() {
    return UserCloudData(
      favorites: _favorites.all(),
      playbackHistory: _history.all(),
      searchHistory: _search.history(),
      autoPlay: _settings.autoPlay,
      autoReturnAfterCompletion: _settings.autoReturnAfterCompletion,
      playSpeed: _settings.playSpeed,
    );
  }
}
