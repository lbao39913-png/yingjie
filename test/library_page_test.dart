import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yingjie/core/providers/app_providers.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/core/storage/token_store.dart';
import 'package:yingjie/data/api/api_provider.dart';
import 'package:yingjie/data/mock/mock_auth_api.dart';
import 'package:yingjie/data/mock/mock_cloud_sync_api.dart';
import 'package:yingjie/data/mock/mock_cloud_video_api.dart';
import 'package:yingjie/data/mock/mock_media_api.dart';
import 'package:yingjie/features/library/library_page.dart';
import 'package:yingjie/services/auth_service.dart';
import 'package:yingjie/services/cloud_video_service.dart';
import 'package:yingjie/services/cloud_video_sync_service.dart';
import 'package:yingjie/services/favorite_service.dart';
import 'package:yingjie/services/history_service.dart';
import 'package:yingjie/services/local_video_service.dart';
import 'package:yingjie/services/search_service.dart';
import 'package:yingjie/services/settings_service.dart';
import 'package:yingjie/services/sync_service.dart';
import 'package:yingjie/services/upload_service.dart';
import 'package:yingjie/services/video_picker.dart';

class _FakePicker implements VideoPicker {
  PickedLocalVideo? next;

  @override
  Future<PickedLocalVideo?> pickVideo() async => next;
}

void main() {
  late Directory tempDir;
  late LocalVideoService local;
  late MockCloudVideoApi videoApi;
  late CloudVideoService cloud;
  late AuthService auth;
  late MockAuthApi authApi;
  late MemoryTokenStore tokens;
  late _FakePicker picker;
  late CloudVideoSyncService syncVideos;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_library_page_');
    await LocalStorage.initForTest(tempDir.path);
    local = LocalVideoService();
    videoApi = MockCloudVideoApi(chunkSize: 4);
    tokens = MemoryTokenStore();
    cloud = CloudVideoService(
      api: videoApi,
      tokens: tokens,
      upload: UploadService(),
    );
    syncVideos = CloudVideoSyncService(api: videoApi, videos: cloud);
    authApi = MockAuthApi();
    auth = AuthService(
      api: authApi,
      tokens: tokens,
      sync: SyncService(
        api: MockCloudSyncApi(),
        favorites: FavoriteService(),
        history: HistoryService(),
        search: SearchService(
          ApiProvider(mediaApi: MockMediaApi(latency: Duration.zero)),
        ),
        settings: SettingsService(),
      ),
      afterLogin: syncVideos.pull,
    );
    picker = _FakePicker();
    await auth.restore();
  });

  tearDown(() async {
    auth.dispose();
    cloud.dispose();
    local.dispose();
    await LocalStorage.resetForTest();
  });

  Future<void> pumpLibrary(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/videos',
      routes: [
        GoRoute(
          path: '/videos',
          builder: (context, state) => const LibraryPage(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Text('登录页')),
        ),
        GoRoute(
          path: '/player/:id',
          builder: (context, state) => const Scaffold(body: Text('播放页')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localVideoServiceProvider.overrideWithValue(local),
          cloudVideoServiceProvider.overrideWithValue(cloud),
          cloudVideoSyncServiceProvider.overrideWithValue(syncVideos),
          authServiceProvider.overrideWithValue(auth),
          videoPickerProvider.overrideWithValue(picker),
          tokenStoreProvider.overrideWithValue(tokens),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('local tab imports a picked file', (tester) async {
    await tester.runAsync(() async {
      await local.import(
        title: 'demo',
        filePath: '/tmp/demo.mp4',
        sizeBytes: 12,
      );
    });
    await pumpLibrary(tester);
    expect(find.text('demo'), findsOneWidget);
    expect(find.text('本地'), findsWidgets);
  });

  testWidgets('cloud tab asks login when signed out', (tester) async {
    await pumpLibrary(tester);
    await tester.tap(find.byKey(const Key('library-tab-cloud')));
    await tester.pumpAndSettle();
    expect(find.text('登录后查看云视频'), findsOneWidget);
    await tester.tap(find.text('去登录'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('登录页'), findsOneWidget);
  });
}
