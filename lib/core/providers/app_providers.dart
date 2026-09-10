import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_provider.dart';
import '../../features/player/video_engine.dart';
import '../../features/player/video_player_engine.dart';
import '../../services/api_service.dart';
import '../../services/cache_service.dart';
import '../../services/favorite_service.dart';
import '../../services/history_service.dart';
import '../../services/player_service.dart';
import '../../services/search_service.dart';
import '../../services/settings_service.dart';
import '../../services/update_service.dart';
import '../config/app_config.dart';
import '../network/dio_client.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final apiProvider = Provider<ApiProvider>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ApiProvider.fromConfig(
    useMock: AppConfig.useMockApi,
    dio: dio.raw,
  );
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(apiProvider));
});

final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService(ref.watch(apiProvider));
});

final favoriteServiceProvider = Provider<FavoriteService>((ref) {
  return FavoriteService();
});

final playerServiceProvider = Provider<PlayerService>((ref) {
  return PlayerService();
});

final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService();
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

final videoEngineFactoryProvider = Provider<VideoEngineFactory>((ref) {
  return VideoPlayerEngine.new;
});

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(ref.watch(dioClientProvider).raw);
});
