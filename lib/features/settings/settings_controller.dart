import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../services/cache_service.dart';
import '../../services/favorite_service.dart';
import '../../services/history_service.dart';
import '../../services/search_service.dart';
import '../../services/settings_service.dart';

class SettingsState {
  const SettingsState({
    this.autoPlay = true,
    this.autoReturnAfterCompletion = false,
    this.cacheBytes = 0,
    this.cacheLabel = '暂无可清理缓存',
    this.cacheBusy = false,
    this.favoriteCount = 0,
    this.historyCount = 0,
    this.searchCount = 0,
  });

  final bool autoPlay;
  final bool autoReturnAfterCompletion;
  final int cacheBytes;
  final String cacheLabel;
  final bool cacheBusy;
  final int favoriteCount;
  final int historyCount;
  final int searchCount;

  SettingsState copyWith({
    bool? autoPlay,
    bool? autoReturnAfterCompletion,
    int? cacheBytes,
    String? cacheLabel,
    bool? cacheBusy,
    int? favoriteCount,
    int? historyCount,
    int? searchCount,
  }) {
    return SettingsState(
      autoPlay: autoPlay ?? this.autoPlay,
      autoReturnAfterCompletion:
          autoReturnAfterCompletion ?? this.autoReturnAfterCompletion,
      cacheBytes: cacheBytes ?? this.cacheBytes,
      cacheLabel: cacheLabel ?? this.cacheLabel,
      cacheBusy: cacheBusy ?? this.cacheBusy,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      historyCount: historyCount ?? this.historyCount,
      searchCount: searchCount ?? this.searchCount,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController({
    required this._settings,
    required this._cache,
    required this._favorites,
    required this._history,
    required this._search,
  }) : super(const SettingsState()) {
    _subscriptions = [
      _settings.changes.listen((_) => _loadLocal()),
      _favorites.changes.listen((_) => _loadLocal()),
      _history.changes.listen((_) => _loadLocal()),
      _search.changes.listen((_) => _loadLocal()),
    ];
    _loadLocal();
    unawaited(refreshCache());
  }

  final SettingsService _settings;
  final CacheService _cache;
  final FavoriteService _favorites;
  final HistoryService _history;
  final SearchService _search;
  late final List<StreamSubscription<void>> _subscriptions;
  bool _disposed = false;

  void _loadLocal() {
    if (_disposed) {
      return;
    }
    state = state.copyWith(
      autoPlay: _settings.autoPlay,
      autoReturnAfterCompletion: _settings.autoReturnAfterCompletion,
      favoriteCount: _favorites.count(),
      historyCount: _history.count(),
      searchCount: _search.count(),
    );
  }

  Future<void> refreshCache() async {
    if (_disposed) {
      return;
    }
    state = state.copyWith(cacheBusy: true);
    final bytes = await _cache.sizeBytes();
    if (_disposed) {
      return;
    }
    state = state.copyWith(
      cacheBytes: bytes,
      cacheLabel: _cache.sizeLabel(bytes),
      cacheBusy: false,
    );
  }

  Future<void> setAutoPlay(bool value) {
    return _settings.setAutoPlay(value);
  }

  Future<void> setAutoReturnAfterCompletion(bool value) {
    return _settings.setAutoReturnAfterCompletion(value);
  }

  Future<void> clearCache() async {
    if (_disposed) {
      return;
    }
    state = state.copyWith(cacheBusy: true);
    await _cache.clearCache();
    await refreshCache();
  }

  Future<void> clearSearchHistory() {
    return _search.clearHistory();
  }

  Future<void> clearFavorites() {
    return _favorites.clear();
  }

  Future<void> clearPlaybackHistory() {
    return _history.clear();
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

final settingsControllerProvider =
    StateNotifierProvider.autoDispose<SettingsController, SettingsState>((ref) {
  return SettingsController(
    settings: ref.watch(settingsServiceProvider),
    cache: ref.watch(cacheServiceProvider),
    favorites: ref.watch(favoriteServiceProvider),
    history: ref.watch(historyServiceProvider),
    search: ref.watch(searchServiceProvider),
  );
});
