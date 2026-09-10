import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yingjie/core/errors/app_exception.dart';
import 'package:yingjie/core/providers/app_providers.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/features/history/history_page.dart';
import 'package:yingjie/models/playback_record.dart';
import 'package:yingjie/services/history_service.dart';

class _FlakyHistory extends HistoryService {
  bool fail = true;

  @override
  List<PlaybackRecord> all() {
    if (fail) {
      throw const CacheException();
    }
    return super.all();
  }
}

void main() {
  late Directory tempDir;
  late HistoryService history;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_hist_page_');
    await LocalStorage.initForTest(tempDir.path);
    history = HistoryService();
  });

  tearDown(() async {
    await LocalStorage.resetForTest();
  });

  Future<void> pumpHistory(
    WidgetTester tester, {
    HistoryService? service,
  }) async {
    final router = GoRouter(
      initialLocation: '/history',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('首页')),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryPage(),
        ),
        GoRoute(
          path: '/player/:id',
          name: 'player',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return Scaffold(body: Text('播放:$id'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyServiceProvider.overrideWithValue(service ?? history),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> save(WidgetTester tester, PlaybackRecord record) async {
    await tester.runAsync(() async {
      await history.save(record);
    });
  }

  testWidgets('empty history show chinese empty state', (tester) async {
    await pumpHistory(tester);
    expect(find.text('观看历史'), findsOneWidget);
    expect(find.text('还没有观看记录'), findsOneWidget);
    expect(find.text('去发现影片'), findsOneWidget);
  });

  testWidgets('go discover opens home', (tester) async {
    await pumpHistory(tester);
    await tester.tap(find.byKey(const Key('history-go-home')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('首页'), findsOneWidget);
  });

  testWidgets('stored history renders title percent and relative time', (tester) async {
    await save(
      tester,
      PlaybackRecord(
        videoId: 'sintel',
        title: 'Sintel',
        cover: '',
        episodeId: 'e1',
        episodeName: '',
        positionMs: 32000,
        durationMs: 120000,
        watchedAt: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    );
    await pumpHistory(tester);
    expect(find.text('Sintel'), findsOneWidget);
    expect(find.text('已观看 27%'), findsOneWidget);
    expect(find.text('3分钟前'), findsOneWidget);
    expect(find.byKey(const Key('history-card-sintel')), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('history-progress-sintel')),
    );
    expect(bar.value, closeTo(32 / 120, 0.0001));
  });

  testWidgets('multiple history items all appear', (tester) async {
    await save(tester, _card('a', title: 'A'));
    await save(tester, _card('b', title: 'B'));
    await save(tester, _card('c', title: 'C'));
    await pumpHistory(tester);
    expect(find.byKey(const Key('history-card-a')), findsOneWidget);
    expect(find.byKey(const Key('history-card-b')), findsOneWidget);
    expect(find.byKey(const Key('history-card-c')), findsOneWidget);
  });

  testWidgets('tap history opens matching player id', (tester) async {
    await save(tester, _card('sintel', title: 'Sintel'));
    await pumpHistory(tester);
    await tester.tap(find.byKey(const Key('history-card-sintel')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('播放:sintel'), findsOneWidget);
  });

  testWidgets('long press removes history and updates ui', (tester) async {
    await save(tester, _card('sintel', title: 'Sintel'));
    await pumpHistory(tester);
    final inkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const Key('history-card-sintel')),
        matching: find.byType(InkWell),
      ),
    );
    expect(inkWell.onLongPress, isNotNull);
    await tester.runAsync(() async {
      inkWell.onLongPress!.call();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('还没有观看记录'), findsOneWidget);
    expect(find.text('已删除'), findsOneWidget);
    expect(history.load('sintel'), isNull);
  });

  testWidgets('clear confirms then empties history', (tester) async {
    await save(tester, _card('sintel', title: 'Sintel'));
    await save(tester, _card('bunny', title: 'Bunny'));
    await pumpHistory(tester);
    await tester.runAsync(() async {
      tester.widget<TextButton>(find.byKey(const Key('history-clear'))).onPressed!.call();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
    expect(find.text('清空观看历史'), findsOneWidget);
    await tester.runAsync(() async {
      tester
          .widget<TextButton>(find.byKey(const Key('history-clear-confirm')))
          .onPressed!
          .call();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('还没有观看记录'), findsOneWidget);
    expect(find.text('已清空观看历史'), findsOneWidget);
    expect(history.all(), isEmpty);
  });

  testWidgets('broken cover shows fallback instead of crashing', (tester) async {
    await save(tester, _card('broken', title: 'Broken Cover'));
    await pumpHistory(tester);
    expect(find.text('Broken Cover'), findsOneWidget);
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
  });

  testWidgets('load failure shows chinese error and retry', (tester) async {
    final service = _FlakyHistory();
    await pumpHistory(tester, service: service);
    expect(find.text('本地数据读取失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    await tester.runAsync(() async {
      await service.save(_card('sintel', title: 'Sintel'));
    });
    service.fail = false;
    await tester.tap(find.text('重试'));
    await tester.pump();
    expect(find.text('Sintel'), findsOneWidget);
  });

  testWidgets('series history shows title and episode', (tester) async {
    await save(
      tester,
      PlaybackRecord(
        videoId: 'sample-series-a',
        title: '示例剧集 A',
        cover: '',
        episodeId: 'sample-series-a-1',
        episodeName: '第1集',
        positionMs: 32000,
        durationMs: 120000,
        watchedAt: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    );
    await pumpHistory(tester);
    expect(find.text('示例剧集 A · 第1集'), findsOneWidget);
    expect(
      find.byKey(const Key('history-card-sample-series-a-sample-series-a-1')),
      findsOneWidget,
    );
  });
}

PlaybackRecord _card(String id, {required String title}) {
  return PlaybackRecord(
    videoId: id,
    title: title,
    cover: '',
    episodeId: 'e1',
    episodeName: '',
    positionMs: 32000,
    durationMs: 120000,
    watchedAt: DateTime(2026, 9, 10),
  );
}
