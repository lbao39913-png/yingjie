import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yingjie/core/providers/app_providers.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/data/api/api_provider.dart';
import 'package:yingjie/data/mock/mock_media_api.dart';
import 'package:yingjie/features/mine/mine_page.dart';
import 'package:yingjie/models/playback_record.dart';
import 'package:yingjie/models/video.dart';
import 'package:yingjie/services/favorite_service.dart';
import 'package:yingjie/services/history_service.dart';
import 'package:yingjie/services/search_service.dart';

void main() {
  late Directory tempDir;
  late FavoriteService favorites;
  late HistoryService history;
  late SearchService search;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_mine_');
    await LocalStorage.initForTest(tempDir.path);
    favorites = FavoriteService();
    history = HistoryService();
    search = SearchService(
      ApiProvider(mediaApi: MockMediaApi(latency: Duration.zero)),
    );
  });

  tearDown(() async {
    await LocalStorage.resetForTest();
  });

  Future<void> pumpMine(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/mine',
      routes: [
        GoRoute(
          path: '/mine',
          builder: (context, state) => const MinePage(),
        ),
        GoRoute(
          path: '/favorites',
          builder: (context, state) => const Scaffold(body: Text('收藏页')),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const Scaffold(body: Text('历史页')),
        ),
        GoRoute(
          path: '/search-history',
          builder: (context, state) => const Scaffold(body: Text('搜索记录页')),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(body: Text('设置页')),
        ),
        GoRoute(
          path: '/about',
          builder: (context, state) => const Scaffold(body: Text('关于页')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoriteServiceProvider.overrideWithValue(favorites),
          historyServiceProvider.overrideWithValue(history),
          searchServiceProvider.overrideWithValue(search),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('mine page shows local user without login', (tester) async {
    await pumpMine(tester);
    expect(find.text('我的'), findsOneWidget);
    expect(find.text('影界用户'), findsOneWidget);
    expect(find.text('本地用户 · 无需登录'), findsOneWidget);
    expect(find.text('0 部'), findsNWidgets(2));
    expect(find.text('0 条'), findsOneWidget);
  });

  testWidgets('counts follow local data', (tester) async {
    await tester.runAsync(() async {
      await favorites.add(
        const Video(id: 'sintel', title: 'Sintel', cover: ''),
      );
      await history.save(
        PlaybackRecord(
          videoId: 'sintel',
          title: 'Sintel',
          cover: '',
          episodeId: 'e1',
          episodeName: '',
          positionMs: 12000,
          durationMs: 120000,
          watchedAt: DateTime(2026, 9, 10),
        ),
      );
      await search.addHistory('Sintel');
    });
    await pumpMine(tester);
    expect(find.text('1 部'), findsNWidgets(2));
    expect(find.text('1 条'), findsOneWidget);
  });

  testWidgets('favorites tile opens favorites tab', (tester) async {
    await pumpMine(tester);
    await tester.tap(find.byKey(const Key('mine-favorites')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('收藏页'), findsOneWidget);
  });

  testWidgets('settings tile opens settings', (tester) async {
    await pumpMine(tester);
    await tester.tap(find.byKey(const Key('mine-settings')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('设置页'), findsOneWidget);
  });

  testWidgets('about tile opens about', (tester) async {
    await pumpMine(tester);
    await tester.tap(find.byKey(const Key('mine-about')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('关于页'), findsOneWidget);
  });
}
