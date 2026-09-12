import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_provider.dart';
import '../../data/api/auth_api.dart';
import '../../data/api/cloud_sync_api.dart';
import '../../data/mock/mock_auth_api.dart';
import '../../data/mock/mock_cloud_sync_api.dart';
import '../../data/remote/remote_auth_api.dart';
import '../../data/remote/remote_cloud_sync_api.dart';
import '../../data/api/cloud_video_api.dart';
import '../../data/mock/mock_cloud_video_api.dart';
import '../../data/remote/remote_cloud_video_api.dart';
import '../../features/player/video_engine.dart';
import '../../features/player/video_player_engine.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/cache_service.dart';
import '../../services/favorite_service.dart';
import '../../services/history_service.dart';
import '../../services/player_service.dart';
import '../../services/search_service.dart';
import '../../services/settings_service.dart';
import '../../services/sync_service.dart';
import '../../services/update_service.dart';
import '../../services/cloud_video_service.dart';
import '../../services/cloud_video_sync_service.dart';
import '../../services/local_video_service.dart';
import '../../services/privacy_lock_service.dart';
import '../../services/system_video_picker.dart';
import '../../services/upload_service.dart';
import '../../services/video_picker.dart';
import '../config/app_config.dart';
import '../network/dio_client.dart';
import '../storage/token_store.dart';

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

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return SecureTokenStore();
});

final authApiProvider = Provider<AuthApi>((ref) {
  if (AppConfig.useMockApi) {
    return MockAuthApi();
  }
  return RemoteAuthApi(ref.watch(dioClientProvider).raw);
});

final cloudSyncApiProvider = Provider<CloudSyncApi>((ref) {
  if (AppConfig.useMockApi) {
    return MockCloudSyncApi();
  }
  return RemoteCloudSyncApi(ref.watch(dioClientProvider).raw);
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    api: ref.watch(cloudSyncApiProvider),
    favorites: ref.watch(favoriteServiceProvider),
    history: ref.watch(historyServiceProvider),
    search: ref.watch(searchServiceProvider),
    settings: ref.watch(settingsServiceProvider),
  );
});

final authServiceProvider = Provider<AuthService>((ref) {
  final videos = ref.watch(cloudVideoSyncServiceProvider);
  final service = AuthService(
    api: ref.watch(authApiProvider),
    tokens: ref.watch(tokenStoreProvider),
    sync: ref.watch(syncServiceProvider),
    afterLogin: videos.pull,
  );
  ref.onDispose(service.dispose);
  return service;
});

final cloudVideoApiProvider = Provider<CloudVideoApi>((ref) {
  if (AppConfig.useMockApi) {
    return MockCloudVideoApi();
  }
  return RemoteCloudVideoApi(ref.watch(dioClientProvider).raw);
});

final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService();
});

final localVideoServiceProvider = Provider<LocalVideoService>((ref) {
  return LocalVideoService();
});

final privacyLockServiceProvider = Provider<PrivacyLockService>((ref) {
  return PrivacyLockService();
});

final videoPickerProvider = Provider<VideoPicker>((ref) {
  return const SystemVideoPicker();
});

final cloudVideoServiceProvider = Provider<CloudVideoService>((ref) {
  return CloudVideoService(
    api: ref.watch(cloudVideoApiProvider),
    tokens: ref.watch(tokenStoreProvider),
    upload: ref.watch(uploadServiceProvider),
  );
});

final cloudVideoSyncServiceProvider = Provider<CloudVideoSyncService>((ref) {
  return CloudVideoSyncService(
    api: ref.watch(cloudVideoApiProvider),
    videos: ref.watch(cloudVideoServiceProvider),
  );
});
