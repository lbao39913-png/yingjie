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
import 'package:yingjie/features/library/private_videos_page.dart';
import 'package:yingjie/models/local_video.dart';
import 'package:yingjie/services/auth_service.dart';
import 'package:yingjie/services/byte_source.dart';
import 'package:yingjie/services/cloud_video_service.dart';
import 'package:yingjie/services/favorite_service.dart';
import 'package:yingjie/services/history_service.dart';
import 'package:yingjie/services/privacy_lock_service.dart';
import 'package:yingjie/services/search_service.dart';
import 'package:yingjie/services/settings_service.dart';
import 'package:yingjie/services/sync_service.dart';
import 'package:yingjie/services/upload_service.dart';

void main() {
  late Directory tempDir;
  late AuthService auth;
  late MockAuthApi authApi;
  late MemoryTokenStore tokens;
  late CloudVideoService cloud;
  late PrivacyLockService lock;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_private_page_');
    await LocalStorage.initForTest(tempDir.path);
    tokens = MemoryTokenStore();
    authApi = MockAuthApi();
    cloud = CloudVideoService(
      api: MockCloudVideoApi(chunkSize: 4),
      tokens: tokens,
      upload: UploadService(),
    );
    lock = PrivacyLockService();
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
    );
    await auth.restore();
  });

  tearDown(() async {
    auth.dispose();
    cloud.dispose();
    await LocalStorage.resetForTest();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/private-videos',
      routes: [
        GoRoute(
          path: '/private-videos',
          builder: (context, state) => const PrivateVideosPage(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Text('登录页')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(auth),
          cloudVideoServiceProvider.overrideWithValue(cloud),
          privacyLockServiceProvider.overrideWithValue(lock),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('signed out users are sent to login', (tester) async {
    await pumpPage(tester);
    expect(find.text('登录后才能查看隐私视频'), findsOneWidget);
    await tester.tap(find.text('去登录'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('登录页'), findsOneWidget);
  });

  testWidgets('logged in without pin shows setup form', (tester) async {
    await tester.runAsync(() async {
      await auth.register(
        account: 'alice',
        password: 'secret',
        confirmPassword: 'secret',
      );
    });
    await pumpPage(tester);
    expect(find.text('设置隐私 PIN'), findsOneWidget);
    expect(find.byKey(const Key('privacy-pin')), findsOneWidget);
  });

  testWidgets('logged in user sets pin then sees private videos', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await auth.register(
        account: 'alice',
        password: 'secret',
        confirmPassword: 'secret',
      );
      await cloud.uploadFromLocal(
        local: const LocalVideo(
          id: 'local-1',
          title: 'hidden',
          filePath: '/tmp/hidden.mp4',
          sizeBytes: 4,
        ),
        isPrivate: true,
        source: MemoryByteSource(const [1, 2, 3, 4]),
      );
      await lock.setPin(
        userId: auth.currentUser!.id,
        pin: '2580',
        confirmPin: '2580',
      );
    });
    await pumpPage(tester);
    expect(find.text('hidden'), findsOneWidget);
    expect(find.text('仅自己可见'), findsOneWidget);
  });
}
