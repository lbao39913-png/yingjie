import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/errors/app_exception.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/data/api/api_provider.dart';
import 'package:yingjie/data/api/cloud_sync_api.dart';
import 'package:yingjie/data/mock/mock_cloud_sync_api.dart';
import 'package:yingjie/data/mock/mock_media_api.dart';
import 'package:yingjie/models/playback_record.dart';
import 'package:yingjie/models/user_cloud_data.dart';
import 'package:yingjie/models/video.dart';
import 'package:yingjie/services/favorite_service.dart';
import 'package:yingjie/services/history_service.dart';
import 'package:yingjie/services/search_service.dart';
import 'package:yingjie/services/settings_service.dart';
import 'package:yingjie/services/sync_service.dart';

void main() {
  late Directory tempDir;
  late FavoriteService favorites;
  late HistoryService history;
  late SearchService search;
  late SettingsService settings;
  late MockCloudSyncApi cloudApi;
  late SyncService sync;

  const token = 'acc.user-1.1.1';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_sync_');
    await LocalStorage.initForTest(tempDir.path);
    favorites = FavoriteService();
    history = HistoryService();
    search = SearchService(
      ApiProvider(mediaApi: MockMediaApi(latency: Duration.zero)),
    );
    settings = SettingsService();
    cloudApi = MockCloudSyncApi();
    sync = SyncService(
      api: cloudApi,
      favorites: favorites,
      history: history,
      search: search,
      settings: settings,
    );
  });

  tearDown(() async {
    await LocalStorage.resetForTest();
  });

  test('pullAndMerge merges cloud data into empty local storage', () async {
    cloudApi.seed('user-1', _cloudData());
    await sync.pullAndMerge(token);
    expect(favorites.contains('cloud-fav'), isTrue);
    expect(history.load('cloud-fav')?.videoId, 'cloud-fav');
    expect(search.history(), contains('云关键词'));
    expect(settings.autoPlay, isFalse);
  });

  test('pullAndMerge keeps local favorites and dedupes', () async {
    await favorites.add(const Video(id: 'local-fav', title: '本地', cover: ''));
    cloudApi.seed('user-1', _cloudData());
    await sync.pullAndMerge(token);
    expect(favorites.contains('local-fav'), isTrue);
    expect(favorites.contains('cloud-fav'), isTrue);
    expect(favorites.all().length, 2);
  });

  test('merge keeps the newer playback record', () async {
    await history.save(
      PlaybackRecord(
        videoId: 'cloud-fav',
        title: '本地较新',
        cover: '',
        episodeId: '',
        episodeName: '',
        positionMs: 9000,
        durationMs: 10000,
        watchedAt: DateTime(2026, 9, 20),
      ),
    );
    cloudApi.seed('user-1', _cloudData());
    await sync.pullAndMerge(token);
    expect(history.load('cloud-fav')?.title, '本地较新');
  });

  test('settings only fills missing keys', () async {
    await settings.setAutoPlay(true);
    cloudApi.seed('user-1', _cloudData());
    await sync.pullAndMerge(token);
    expect(settings.autoPlay, isTrue);
  });

  test('push writes merged snapshot to cloud', () async {
    await favorites.add(const Video(id: 'local-fav', title: '本地', cover: ''));
    cloudApi.seed('user-1', _cloudData());
    await sync.pullAndMerge(token);
    final stored = cloudApi.stored('user-1');
    expect(stored, isNotNull);
    expect(stored!.favorites.map((v) => v.id), contains('local-fav'));
  });

  test('pull failure does not throw', () async {
    final failing = SyncService(
      api: _FailingCloudApi(),
      favorites: favorites,
      history: history,
      search: search,
      settings: settings,
    );
    await expectLater(failing.pullAndMerge(token), completes);
  });

  test('push failure does not throw', () async {
    final failing = SyncService(
      api: _FailingCloudApi(),
      favorites: favorites,
      history: history,
      search: search,
      settings: settings,
    );
    await expectLater(failing.push(token), completes);
  });
}

UserCloudData _cloudData() {
  return UserCloudData(
    favorites: const [
      Video(id: 'cloud-fav', title: '云端收藏', cover: ''),
    ],
    playbackHistory: [
      PlaybackRecord(
        videoId: 'cloud-fav',
        title: '云端记录',
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

class _FailingCloudApi implements CloudSyncApi {
  @override
  Future<UserCloudData> pull({required String accessToken}) {
    throw const ServerException(message: '服务器异常，请稍后重试');
  }

  @override
  Future<void> push({
    required String accessToken,
    required UserCloudData data,
  }) {
    throw const ServerException(message: '服务器异常，请稍后重试');
  }
}
