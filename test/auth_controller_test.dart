import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/providers/app_providers.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/core/storage/token_store.dart';
import 'package:yingjie/data/api/api_provider.dart';
import 'package:yingjie/data/mock/mock_auth_api.dart';
import 'package:yingjie/data/mock/mock_cloud_sync_api.dart';
import 'package:yingjie/data/mock/mock_media_api.dart';
import 'package:yingjie/features/auth/auth_controller.dart';
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
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_auth_ctrl_');
    await LocalStorage.initForTest(tempDir.path);
    authApi = MockAuthApi();
    final favorites = FavoriteService();
    final history = HistoryService();
    final search = SearchService(
      ApiProvider(mediaApi: MockMediaApi(latency: Duration.zero)),
    );
    auth = AuthService(
      api: authApi,
      tokens: MemoryTokenStore(),
      sync: SyncService(
        api: MockCloudSyncApi(),
        favorites: favorites,
        history: history,
        search: search,
        settings: SettingsService(),
      ),
    );
    container = ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(auth)],
    );
    container.listen(authControllerProvider, (_, __) {});
  });

  tearDown(() async {
    container.dispose();
    auth.dispose();
    await LocalStorage.resetForTest();
  });

  test('login returns true and recovers from error', () async {
    await authApi.register(account: 'alice', password: 'secret');
    final notifier = container.read(authControllerProvider.notifier);
    expect(
      await notifier.login(account: 'alice', password: 'secret'),
      isTrue,
    );
    expect(container.read(authControllerProvider).busy, isFalse);
  });

  test('login failure exposes Chinese error message', () async {
    final notifier = container.read(authControllerProvider.notifier);
    final ok = await notifier.login(account: 'nobody', password: 'x');
    expect(ok, isFalse);
    expect(
      container.read(authControllerProvider).errorMessage,
      '账号或密码错误',
    );
  });

  test('register rejects mismatched password locally', () async {
    final notifier = container.read(authControllerProvider.notifier);
    final ok = await notifier.register(
      account: 'alice',
      password: 'secret',
      confirmPassword: 'other',
    );
    expect(ok, isFalse);
    expect(
      container.read(authControllerProvider).errorMessage,
      '两次密码不一致',
    );
  });
}
