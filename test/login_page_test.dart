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
import 'package:yingjie/data/mock/mock_media_api.dart';
import 'package:yingjie/features/auth/login_page.dart';
import 'package:yingjie/features/auth/register_page.dart';
import 'package:yingjie/services/auth_service.dart';
import 'package:yingjie/services/favorite_service.dart';
import 'package:yingjie/services/history_service.dart';
import 'package:yingjie/services/search_service.dart';
import 'package:yingjie/services/settings_service.dart';
import 'package:yingjie/services/sync_service.dart';

void main() {
  late Directory tempDir;
  late MockAuthApi authApi;
  late AuthService auth;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_login_');
    await LocalStorage.initForTest(tempDir.path);
    authApi = MockAuthApi();
    auth = AuthService(
      api: authApi,
      tokens: MemoryTokenStore(),
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
  });

  tearDown(() async {
    auth.dispose();
    await LocalStorage.resetForTest();
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/mine',
          builder: (context, state) => const Scaffold(body: Text('我的页')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(auth)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
  }

  testWidgets('login page renders fields and submit', (tester) async {
    await pumpLogin(tester);
    expect(find.text('登录'), findsWidgets);
    expect(find.byKey(const Key('login-account')), findsOneWidget);
    expect(find.byKey(const Key('login-password')), findsOneWidget);
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
  });

  testWidgets('login with wrong password shows Chinese error', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(
      find.byKey(const Key('login-account')),
      'nobody',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'wrong',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('login-error')), findsOneWidget);
    expect(find.text('账号或密码错误'), findsOneWidget);
  });

  testWidgets('login navigates to mine on success', (tester) async {
    await authApi.register(account: 'alice', password: 'secret');
    await pumpLogin(tester);
    await tester.enterText(
      find.byKey(const Key('login-account')),
      'alice',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'secret',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('我的页'), findsOneWidget);
  });

  testWidgets('register link opens register page', (tester) async {
    await pumpLogin(tester);
    await tester.tap(find.byKey(const Key('login-go-register')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('register-submit')), findsOneWidget);
  });
}
