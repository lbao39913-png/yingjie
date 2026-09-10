import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/providers/app_providers.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/data/api/api_provider.dart';
import 'package:yingjie/data/mock/mock_catalog.dart';
import 'package:yingjie/data/mock/mock_media_api.dart';
import 'package:yingjie/features/settings/settings_page.dart';
import 'package:yingjie/models/playback_record.dart';
import 'package:yingjie/models/video.dart';
import 'package:yingjie/services/cache_service.dart';
import 'package:yingjie/services/favorite_service.dart';
import 'package:yingjie/services/history_service.dart';
import 'package:yingjie/services/search_service.dart';
import 'package:yingjie/services/settings_service.dart';

void main() {
  late Directory tempDir;
  late SettingsService settings;
  late FavoriteService favorites;
  late HistoryService history;
  late SearchService search;
  late int cacheBytes;
  late bool cacheCleared;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_settings_page_');
    await LocalStorage.initForTest(tempDir.path);
    settings = SettingsService();
    favorites = FavoriteService();
    history = HistoryService();
    search = SearchService(
      ApiProvider(mediaApi: MockMediaApi(latency: Duration.zero)),
    );
    cacheBytes = 2048;
    cacheCleared = false;
  });

  tearDown(() async {
    await LocalStorage.resetForTest();
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsServiceProvider.overrideWithValue(settings),
          favoriteServiceProvider.overrideWithValue(favorites),
          historyServiceProvider.overrideWithValue(history),
          searchServiceProvider.overrideWithValue(search),
          cacheServiceProvider.overrideWithValue(
            CacheService(
              measure: () async => cacheBytes,
              clear: () async {
                cacheCleared = true;
                cacheBytes = 0;
              },
            ),
          ),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('defaults auto play on and shows cache size', (tester) async {
    await pumpSettings(tester);
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('进入播放页自动播放'), findsOneWidget);
    final autoPlay = tester.widget<SwitchListTile>(
      find.byKey(const Key('settings-auto-play')),
    );
    expect(autoPlay.value, isTrue);
    final autoReturn = tester.widget<SwitchListTile>(
      find.byKey(const Key('settings-auto-return')),
    );
    expect(autoReturn.value, isFalse);
    expect(find.text('缓存大小 2.0 KB'), findsOneWidget);
  });

  testWidgets('toggling auto play persists', (tester) async {
    await pumpSettings(tester);
    await tester.runAsync(() async {
      tester
          .widget<SwitchListTile>(find.byKey(const Key('settings-auto-play')))
          .onChanged
          ?.call(false);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(settings.autoPlay, isFalse);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('settings-auto-play')))
          .value,
      isFalse,
    );
  });

  testWidgets('clear cache confirm does not wipe favorites', (tester) async {
    await tester.runAsync(() async {
      await favorites.add(
        const Video(id: 'sintel', title: 'Sintel', cover: ''),
      );
    });
    await pumpSettings(tester);
    await tester.runAsync(() async {
      tester
          .widget<ListTile>(
            find.descendant(
              of: find.byKey(const Key('settings-clear-cache')),
              matching: find.byType(ListTile),
            ),
          )
          .onTap!
          .call();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
    expect(find.textContaining('不会删除收藏'), findsOneWidget);
    await tester.runAsync(() async {
      tester
          .widget<TextButton>(
            find.byKey(const Key('settings-clear-cache-confirm')),
          )
          .onPressed!
          .call();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(cacheCleared, isTrue);
    expect(favorites.contains('sintel'), isTrue);
    expect(find.text('暂无可清理缓存'), findsOneWidget);
  });

  testWidgets('clear favorites confirm leaves history', (tester) async {
    await tester.runAsync(() async {
      await favorites.add(
        Video(
          id: MockCatalog.videos.first.id,
          title: MockCatalog.videos.first.title,
          cover: '',
        ),
      );
      await history.save(
        PlaybackRecord(
          videoId: MockCatalog.videos.first.id,
          title: 'Sintel',
          cover: '',
          episodeId: 'e1',
          episodeName: '',
          positionMs: 12000,
          durationMs: 120000,
          watchedAt: DateTime(2026, 9, 10),
        ),
      );
    });
    await pumpSettings(tester);
    expect(find.text('1 部'), findsNWidgets(2));
    await tester.runAsync(() async {
      tester
          .widget<ListTile>(
            find.descendant(
              of: find.byKey(const Key('settings-clear-favorites')),
              matching: find.byType(ListTile),
            ),
          )
          .onTap!
          .call();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
    await tester.runAsync(() async {
      tester
          .widget<TextButton>(
            find.byKey(const Key('settings-clear-favorites-confirm')),
          )
          .onPressed!
          .call();
    });
    await tester.pump();
    await tester.runAsync(() async {
      for (var i = 0; i < 20 && favorites.all().isNotEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(favorites.all(), isEmpty);
    expect(history.all(), hasLength(1));
  });
}
