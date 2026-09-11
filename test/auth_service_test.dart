import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/errors/app_exception.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/core/storage/token_store.dart';
import 'package:yingjie/data/api/api_provider.dart';
import 'package:yingjie/data/mock/mock_auth_api.dart';
import 'package:yingjie/data/mock/mock_cloud_sync_api.dart';
import 'package:yingjie/data/mock/mock_media_api.dart';
import 'package:yingjie/models/playback_record.dart';
import 'package:yingjie/models/user.dart';
import 'package:yingjie/models/user_cloud_data.dart';
import 'package:yingjie/models/video.dart';
import 'package:yingjie/services/auth_service.dart';
import 'package:yingjie/services/favorite_service.dart';
import 'package:yingjie/services/history_service.dart';
import 'package:yingjie/services/search_service.dart';
import 'package:yingjie/services/settings_service.dart';
import 'package:yingjie/services/sync_service.dart';

void main() {
  late Directory tempDir;
  late MockAuthApi authApi;
  late MemoryTokenStore tokens;
  late FavoriteService favorites;
  late HistoryService history;
  late SearchService search;
  late SettingsService settings;
  late MockCloudSyncApi cloudApi;
  late AuthService service;

  SyncService buildSync() {
    return SyncService(
      api: cloudApi,
      favorites: favorites,
      history: history,
      search: search,
      settings: settings,
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_auth_');
    await LocalStorage.initForTest(tempDir.path);
    authApi = MockAuthApi();
    tokens = MemoryTokenStore();
    favorites = FavoriteService();
    history = HistoryService();
    search = SearchService(
      ApiProvider(mediaApi: MockMediaApi(latency: Duration.zero)),
    );
    settings = SettingsService();
    cloudApi = MockCloudSyncApi();
    service = AuthService(
      api: authApi,
      tokens: tokens,
      sync: buildSync(),
    );
  });

  tearDown(() async {
    service.dispose();
    await LocalStorage.resetForTest();
  });

  test('starts unknown then restores to logged out without token', () async {
    expect(service.status, AuthStatus.unknown);
    await service.restore();
    expect(service.status, AuthStatus.loggedOut);
    expect(service.isLoggedIn, isFalse);
  });

  test('register signs the user in and stores tokens', () async {
    await service.register(
      account: 'alice',
      password: 'secret',
      confirmPassword: 'secret',
    );
    expect(service.isLoggedIn, isTrue);
    expect(service.currentUser?.username, 'alice');
    expect(await tokens.readAccessToken(), isNotNull);
    expect(await tokens.readRefreshToken(), isNotNull);
    expect(authApi.accountCount, 1);
  });

  test('register rejects mismatched password', () async {
    await expectLater(
      service.register(
        account: 'alice',
        password: 'secret',
        confirmPassword: 'other',
      ),
      throwsA(
        isA<AuthException>().having((e) => e.message, 'message', '两次密码不一致'),
      ),
    );
    expect(service.isLoggedIn, isFalse);
  });

  test('login rejects wrong password with Chinese message', () async {
    await authApi.register(account: 'alice', password: 'secret');
    await expectLater(
      service.login(account: 'alice', password: 'wrong'),
      throwsA(
        isA<AuthException>()
            .having((e) => e.message, 'message', '账号或密码错误'),
      ),
    );
    expect(service.isLoggedIn, isFalse);
  });

  test('login rejects unknown account', () async {
    await expectLater(
      service.login(account: 'nobody', password: 'secret'),
      throwsA(isA<AuthException>()),
    );
  });

  test('restore refreshes a stored session', () async {
    final session = await authApi.register(
      account: 'alice',
      password: 'secret',
    );
    await tokens.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    final restored = AuthService(
      api: authApi,
      tokens: tokens,
      sync: buildSync(),
    );
    await restored.restore();
    expect(restored.isLoggedIn, isTrue);
    expect(restored.currentUser?.username, 'alice');
    restored.dispose();
  });

  test('restore clears invalid refresh token', () async {
    await tokens.save(accessToken: 'a', refreshToken: 'invalid');
    await service.restore();
    expect(service.isLoggedIn, isFalse);
    expect(await tokens.readRefreshToken(), isNull);
  });

  test('logout clears tokens but keeps local data', () async {
    await service.register(
      account: 'alice',
      password: 'secret',
      confirmPassword: 'secret',
    );
    await favorites.add(const Video(id: 'sintel', title: 'Sintel', cover: ''));
    await service.logout();
    expect(service.isLoggedIn, isFalse);
    expect(await tokens.readAccessToken(), isNull);
    expect(favorites.contains('sintel'), isTrue);
  });

  test('login merges cloud data then pushes snapshot', () async {
    await authApi.register(account: 'alice', password: 'secret');
    cloudApi.seed('user-1', _cloudSeed());
    await service.login(account: 'alice', password: 'secret');
    expect(favorites.contains('cloud-fav'), isTrue);
    expect(history.load('cloud-fav')?.videoId, 'cloud-fav');
    expect(search.history(), contains('云关键词'));
    expect(settings.autoPlay, isFalse);
    expect(cloudApi.stored('user-1')?.favorites, isNotEmpty);
  });
}

UserCloudData _cloudSeed() {
  return UserCloudData(
    favorites: const [
      Video(id: 'cloud-fav', title: '云端收藏', cover: ''),
    ],
    playbackHistory: [
      PlaybackRecord(
        videoId: 'cloud-fav',
        title: '云端收藏',
        cover: '',
        episodeId: '',
        episodeName: '',
        positionMs: 1000,
        durationMs: 10000,
        watchedAt: DateTime(2026, 9, 1),
      ),
    ],
    searchHistory: const ['云关键词'],
    autoPlay: false,
  );
}
