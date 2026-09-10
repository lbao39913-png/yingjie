import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yingjie/core/providers/app_providers.dart';
import 'package:yingjie/data/api/api_provider.dart';
import 'package:yingjie/data/mock/mock_media_api.dart';
import 'package:yingjie/features/player/player_chrome.dart';
import 'package:yingjie/features/player/player_page.dart';
import 'package:yingjie/services/api_service.dart';
import 'package:yingjie/services/history_service.dart';
import 'package:yingjie/services/settings_service.dart';
import 'package:yingjie/models/playback_record.dart';

import 'fake_video_engine.dart';

void main() {
  testWidgets('player shows title and back returns to detail', (tester) async {
    final chrome = _FakeChrome();
    final engine = FakeVideoEngine();
    final router = GoRouter(
      initialLocation: '/detail/sintel',
      routes: [
        GoRoute(
          path: '/detail/:id',
          builder: (context, state) => const Scaffold(body: Text('详情页')),
        ),
        GoRoute(
          path: '/player/:id',
          builder: (context, state) {
            return PlayerPage(
              videoId: state.pathParameters['id'] ?? '',
              title: 'Sintel',
              playUrl: 'https://example.invalid/sintel.mp4',
              chrome: chrome,
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(
            ApiService(
              ApiProvider(mediaApi: MockMediaApi(latency: Duration.zero)),
            ),
          ),
          videoEngineFactoryProvider.overrideWithValue(() => engine),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    expect(find.text('详情页'), findsOneWidget);

    router.push('/player/sintel');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('Sintel'), findsOneWidget);
    expect(find.byKey(const Key('player-play-pause')), findsOneWidget);

    await tester.tap(find.byKey(const Key('player-back')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('详情页'), findsOneWidget);
    expect(chrome.restoreCount, 1);
  });

  testWidgets('shows current and total time', (tester) async {
    await _pumpPlayer(tester);
    expect(find.byKey(const Key('player-time')), findsOneWidget);
    expect(find.text('00:00 / 02:00'), findsOneWidget);
  });

  testWidgets('speed sheet updates playback rate', (tester) async {
    final engine = await _pumpPlayer(tester);
    await tester.tap(find.byKey(const Key('player-speed')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('倍速'), findsOneWidget);
    await tester.tap(find.byKey(const Key('player-speed-1.5')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(engine.currentSpeed, 1.5);
  });

  testWidgets('buffering overlay stays after controls hide', (tester) async {
    final engine = await _pumpPlayer(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const Key('player-play-pause')), findsNothing);
    engine.emitBuffering(true);
    await tester.pump();
    expect(find.byKey(const Key('player-buffering')), findsOneWidget);
  });

  testWidgets('resume prompt offers continue and start over', (tester) async {
    await _pumpPlayer(
      tester,
      history: _SeedHistory(
        PlaybackRecord(
          videoId: 'sintel',
          title: 'Sintel',
          cover: '',
          episodeId: 'e1',
          episodeName: '',
          positionMs: 32000,
          durationMs: 120000,
          watchedAt: DateTime(2026, 9, 10),
        ),
      ),
    );
    expect(find.byKey(const Key('player-resume')), findsOneWidget);
    expect(find.byKey(const Key('player-resume-start')), findsOneWidget);
    expect(find.byKey(const Key('player-play-pause')), findsNothing);
    expect(find.textContaining('从 00:32 继续'), findsOneWidget);
  });

  testWidgets('background lifecycle pauses playback', (tester) async {
    final engine = await _pumpPlayer(tester);
    expect(engine.pauseCount, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(engine.pauseCount, 1);
  });

  testWidgets('auto play off keeps paused controls', (tester) async {
    await _pumpPlayer(tester, settings: _PausedSettings());
    expect(find.byKey(const Key('player-play-pause')), findsOneWidget);
  });
}

Future<FakeVideoEngine> _pumpPlayer(
  WidgetTester tester, {
  HistoryService? history,
  SettingsService? settings,
}) async {
  final engine = FakeVideoEngine();
  final router = GoRouter(
    initialLocation: '/player/sintel',
    routes: [
      GoRoute(
        path: '/player/:id',
        builder: (context, state) {
          return PlayerPage(
            videoId: state.pathParameters['id'] ?? '',
            title: 'Sintel',
            playUrl: 'https://example.invalid/sintel.mp4',
            chrome: _FakeChrome(),
          );
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiServiceProvider.overrideWithValue(
          ApiService(
            ApiProvider(mediaApi: MockMediaApi(latency: Duration.zero)),
          ),
        ),
        videoEngineFactoryProvider.overrideWithValue(() => engine),
        if (history != null) historyServiceProvider.overrideWithValue(history),
        if (settings != null) settingsServiceProvider.overrideWithValue(settings),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
  return engine;
}

class _SeedHistory extends HistoryService {
  _SeedHistory(this.record);

  final PlaybackRecord record;

  @override
  PlaybackRecord? load(String mediaId, {String? episodeId}) {
    return mediaId == record.videoId ? record : null;
  }
}

class _PausedSettings extends SettingsService {
  @override
  bool get autoPlay => false;
}

class _FakeChrome extends PlayerChrome {
  int enterCount = 0;
  int exitCount = 0;
  int restoreCount = 0;

  @override
  Future<void> enterFullscreen() async {
    enterCount++;
  }

  @override
  Future<void> exitFullscreen() async {
    exitCount++;
  }

  @override
  Future<void> restore() async {
    restoreCount++;
  }
}
