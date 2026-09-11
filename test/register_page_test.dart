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
    tempDir = await Directory.systemTemp.createTemp('yingjie_register_');
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

  Future<void> pumpRegister(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/register',
      routes: [
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

  testWidgets('register page renders fields', (tester) async {
    await pumpRegister(tester);
    expect(find.text('注册'), findsWidgets);
    expect(find.byKey(const Key('register-account')), findsOneWidget);
    expect(find.byKey(const Key('register-password')), findsOneWidget);
    expect(find.byKey(const Key('register-confirm')), findsOneWidget);
  });

  testWidgets('mismatched passwords show Chinese error', (tester) async {
    await pumpRegister(tester);
    await tester.enterText(
      find.byKey(const Key('register-account')),
      'alice',
    );
    await tester.enterText(
      find.byKey(const Key('register-password')),
      'secret',
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm')),
      'other',
    );
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('两次密码不一致'), findsOneWidget);
  });

  testWidgets('duplicate account shows Chinese error', (tester) async {
    await authApi.register(account: 'alice', password: 'secret');
    await pumpRegister(tester);
    await tester.enterText(
      find.byKey(const Key('register-account')),
      'alice',
    );
    await tester.enterText(
      find.byKey(const Key('register-password')),
      'secret',
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm')),
      'secret',
    );
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('该账号已被注册'), findsOneWidget);
  });

  testWidgets('register success navigates to mine', (tester) async {
    await pumpRegister(tester);
    await tester.enterText(
      find.byKey(const Key('register-account')),
      'alice',
    );
    await tester.enterText(
      find.byKey(const Key('register-password')),
      'secret',
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm')),
      'secret',
    );
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('我的页'), findsOneWidget);
    expect(auth.isLoggedIn, isTrue);
  });
}
