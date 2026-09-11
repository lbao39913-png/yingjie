import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/app/route_args.dart';
import 'package:yingjie/core/constants/app_constants.dart';
import 'package:yingjie/core/errors/app_exception.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/data/api/api_provider.dart';
import 'package:yingjie/data/mock/mock_media_api.dart';
import 'package:yingjie/features/player/player_controller.dart';
import 'package:yingjie/features/player/video_engine.dart';
import 'package:yingjie/models/playback_record.dart';
import 'package:yingjie/services/api_service.dart';
import 'package:yingjie/services/history_service.dart';
import 'package:yingjie/services/player_service.dart';
import 'package:yingjie/services/settings_service.dart';

import 'fake_video_engine.dart';

void main() {
  const args = PlayerRouteArgs(
    mediaId: 'sintel',
    title: 'Sintel',
    playUrl: 'https://example.invalid/sintel.mp4',
    episodeId: 'e1',
    sourceId: 's1',
    cover: 'https://example.invalid/sintel.jpg',
    year: 2010,
    genres: ['动画', '奇幻'],
  );

  PlayerController build({
    PlayerRouteArgs route = args,
    FakeVideoEngine? engine,
    VideoEngineFactory? factory,
    Duration hideDelay = Duration.zero,
    HistoryService? history,
    ApiService? api,
    SettingsService? settings,
  }) {
    return PlayerController(
      route,
      api ??
          ApiService(
            ApiProvider(mediaApi: MockMediaApi(latency: Duration.zero)),
          ),
      PlayerService(),
      history ?? HistoryService(),
      factory ?? () => engine ?? FakeVideoEngine(),
      hideDelay: hideDelay,
      settings: settings,
    );
  }

  test('playUrl mediaId and title are passed into engine', () async {
    final engine = FakeVideoEngine();
    final controller = build(engine: engine);
    await pumpController();

    expect(controller.state.mediaId, 'sintel');
    expect(controller.state.title, 'Sintel');
    expect(controller.state.playUrl, 'https://example.invalid/sintel.mp4');
    expect(engine.openedUrl.toString(), 'https://example.invalid/sintel.mp4');
    expect(controller.state.status, PlayerStatus.playing);
    controller.dispose();
  });

  test('initializes to playing on success', () async {
    final controller = build();
    await pumpController();
    expect(controller.state.status, PlayerStatus.playing);
    expect(controller.state.duration, const Duration(seconds: 120));
    controller.dispose();
  });

  test('invalid url becomes chinese playback error', () async {
    final engine = FakeVideoEngine();
    final controller = build(
      route: const PlayerRouteArgs(mediaId: 'x', playUrl: 'not-a-url'),
      engine: engine,
    );
    await pumpController();
    expect(controller.state.status, PlayerStatus.error);
    expect(controller.state.error, isA<PlaybackException>());
    expect(controller.state.error?.message, '播放失败，请检查网络后重试');
    expect(engine.openCount, 0);
    controller.dispose();
  });

  test('engine open failure can retry with a new engine', () async {
    var index = 0;
    final engines = [
      FakeVideoEngine(failOpen: true),
      FakeVideoEngine(),
    ];
    final controller = build(factory: () => engines[index++]);
    await pumpController();
    expect(controller.state.status, PlayerStatus.error);

    await controller.retry();
    expect(controller.state.status, PlayerStatus.playing);
    expect(engines[0].disposeCount, 1);
    expect(engines[1].openCount, 1);
    controller.dispose();
  });

  test('play and pause update status', () async {
    final engine = FakeVideoEngine();
    final controller = build(engine: engine);
    await pumpController();
    await controller.pause();
    expect(controller.state.status, PlayerStatus.paused);
    expect(engine.pauseCount, 1);
    await controller.play();
    expect(controller.state.status, PlayerStatus.playing);
    expect(engine.playCount, greaterThan(1));
    controller.dispose();
  });

  test('mute toggles volume', () async {
    final engine = FakeVideoEngine();
    final controller = build(engine: engine);
    await pumpController();
    await controller.toggleMute();
    expect(controller.state.muted, isTrue);
    expect(engine.currentVolume, 0);
    await controller.toggleMute();
    expect(controller.state.muted, isFalse);
    expect(engine.currentVolume, 1);
    controller.dispose();
  });

  test('progress ticks update position', () async {
    final engine = FakeVideoEngine();
    final controller = build(engine: engine);
    await pumpController();
    engine.tick(const Duration(seconds: 32));
    expect(controller.state.position, const Duration(seconds: 32));
    controller.dispose();
  });

  test('seek updates engine and state', () async {
    final engine = FakeVideoEngine();
    final controller = build(engine: engine);
    await pumpController();
    await controller.onSeekEnd(const Duration(seconds: 10));
    expect(engine.position, const Duration(seconds: 10));
    expect(controller.state.position, const Duration(seconds: 10));
    expect(engine.seekCount, 1);
    controller.dispose();
  });

  test('completed status is emitted by engine', () async {
    final engine = FakeVideoEngine();
    final controller = build(engine: engine);
    await pumpController();
    engine.emitCompleted();
    await pumpController();
    expect(controller.state.status, PlayerStatus.completed);
    await controller.replay();
    expect(controller.state.status, PlayerStatus.playing);
    expect(controller.state.position, Duration.zero);
    controller.dispose();
  });

  test('auto play off stays paused with controls visible', () async {
    final engine = FakeVideoEngine();
    final controller = build(
      engine: engine,
      settings: _FakeSettings(play: false),
    );
    await pumpController();
    expect(controller.state.status, PlayerStatus.paused);
    expect(controller.state.controlsVisible, isTrue);
    expect(engine.playCount, 0);
    controller.dispose();
  });

  test('completed can request auto return', () async {
    final engine = FakeVideoEngine();
    final controller = build(
      engine: engine,
      settings: _FakeSettings(back: true),
    );
    await pumpController();
    engine.emitCompleted();
    await pumpController();
    expect(controller.state.status, PlayerStatus.completed);
    expect(controller.state.shouldReturn, isTrue);
    controller.dispose();
  });

  testWidgets('controls hide after delay while playing', (tester) async {
    final controller = build(hideDelay: const Duration(seconds: 3));
    await tester.pump();
    expect(controller.state.controlsVisible, isTrue);
    await tester.pump(const Duration(seconds: 3));
    expect(controller.state.controlsVisible, isFalse);
    controller.toggleControls();
    expect(controller.state.controlsVisible, isTrue);
    controller.dispose();
  });

  test('toggleControls shows and hides immediately', () async {
    final controller = build();
    await pumpController();
    expect(controller.state.controlsVisible, isTrue);
    controller.toggleControls();
    expect(controller.state.controlsVisible, isFalse);
    controller.toggleControls();
    expect(controller.state.controlsVisible, isTrue);
    controller.dispose();
  });

  test('fullscreen flag toggles', () async {
    final controller = build();
    await pumpController();
    expect(controller.state.fullscreen, isFalse);
    controller.toggleFullscreen();
    expect(controller.state.fullscreen, isTrue);
    controller.toggleFullscreen();
    expect(controller.state.fullscreen, isFalse);
    controller.dispose();
  });

  test('dispose releases engine and ignores later ticks', () async {
    final engine = FakeVideoEngine();
    final controller = build(engine: engine);
    await pumpController();
    controller.dispose();
    expect(engine.disposeCount, 1);
    engine.tick(const Duration(seconds: 50));
  });

  test('stale engine session does not override the new player', () async {
    final engines = <FakeVideoEngine>[];
    final controller = build(
      factory: () {
        final engine = FakeVideoEngine();
        engines.add(engine);
        if (engines.length == 1) {
          engine.openGate = Completer<void>();
        }
        return engine;
      },
    );
    await pumpController();
    expect(controller.state.status, PlayerStatus.initializing);

    final retry = controller.retry();
    await pumpController();
    expect(controller.state.status, PlayerStatus.playing);
    expect(engines[1].openedUrl, isNotNull);

    final gate = engines.first.openGate;
    if (gate != null && !gate.isCompleted) {
      gate.complete();
    }
    await retry;
    await pumpController();
    expect(controller.state.status, PlayerStatus.playing);
    expect(engines.first.disposeCount, 1);
    controller.dispose();
  });

  test('missing playUrl fetches detail by mediaId', () async {
    final engine = FakeVideoEngine();
    final controller = build(
      route: const PlayerRouteArgs(mediaId: 'sintel', title: 'Sintel'),
      engine: engine,
    );
    await pumpController();
    expect(controller.state.status, PlayerStatus.playing);
    expect(controller.state.playUrl, contains('.mp4'));
    expect(engine.openedUrl, isNotNull);
    controller.dispose();
  });

  test('progress is saved and offered as resume', () async {
    final dir = await Directory.systemTemp.createTemp('yingjie_player_');
    await LocalStorage.initForTest(dir.path);
    addTearDown(() async {
      await LocalStorage.resetForTest();
    });

    final history = HistoryService();
    final engine = FakeVideoEngine();
    final controller = build(engine: engine, history: history);
    await pumpController();
    engine.tick(const Duration(seconds: 32));
    await controller.persistProgress();
    final saved = history.load('sintel');
    expect(saved?.positionMs, 32000);
    expect(saved?.cover, 'https://example.invalid/sintel.jpg');
    expect(saved?.year, 2010);
    expect(saved?.genres, ['动画', '奇幻']);
    controller.dispose();

    final engine2 = FakeVideoEngine();
    final next = build(engine: engine2, history: history);
    await pumpController();
    expect(next.state.resumeAt, const Duration(seconds: 32));
    await next.resumeFromHistory();
    expect(engine2.currentPosition, const Duration(seconds: 32));
    expect(next.state.resumeAt, isNull);
    next.dispose();
  });

  test('progress below 5 seconds is not saved', () async {
    final dir = await Directory.systemTemp.createTemp('yingjie_player_min_');
    await LocalStorage.initForTest(dir.path);
    addTearDown(() async {
      await LocalStorage.resetForTest();
    });

    final history = HistoryService();
    final engine = FakeVideoEngine();
    final controller = build(engine: engine, history: history);
    await pumpController();
    engine.tick(const Duration(milliseconds: 4999));
    await controller.persistProgress();
    expect(history.load('sintel'), isNull);
    controller.dispose();
  });

  test('near end progress deletes history', () async {
    final dir = await Directory.systemTemp.createTemp('yingjie_player_end_');
    await LocalStorage.initForTest(dir.path);
    addTearDown(() async {
      await LocalStorage.resetForTest();
    });

    final history = HistoryService();
    await history.save(
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
    );
    final engine = FakeVideoEngine();
    final controller = build(engine: engine, history: history);
    await pumpController();
    engine.tick(const Duration(seconds: 116));
    await controller.persistProgress();
    expect(history.load('sintel'), isNull);
    controller.dispose();
  });

  test('detail launch fills cover year and genres into history', () async {
    final dir = await Directory.systemTemp.createTemp('yingjie_player_meta_');
    await LocalStorage.initForTest(dir.path);
    addTearDown(() async {
      await LocalStorage.resetForTest();
    });

    final history = HistoryService();
    final engine = FakeVideoEngine();
    final controller = build(
      route: const PlayerRouteArgs(mediaId: 'sintel', title: 'Sintel'),
      engine: engine,
      history: history,
    );
    await pumpController();
    engine.tick(const Duration(seconds: 32));
    await controller.persistProgress();
    final saved = history.load('sintel');
    expect(saved?.cover, contains('Sintel.jpg'));
    expect(saved?.year, 2010);
    expect(saved?.genres, ['动画', '奇幻']);
    controller.dispose();
  });

  test('applies play speed from settings', () async {
    final engine = FakeVideoEngine();
    final controller = build(
      engine: engine,
      settings: _FakeSettings(speed: 1.25),
    );
    await pumpController();
    expect(engine.currentSpeed, 1.25);
    expect(controller.state.speed, 1.25);
    controller.dispose();
  });

  test('setSpeed updates engine and snaps to whitelist', () async {
    final engine = FakeVideoEngine();
    final settings = _FakeSettings();
    final controller = build(engine: engine, settings: settings);
    await pumpController();
    await controller.setSpeed(1.5);
    expect(engine.currentSpeed, 1.5);
    expect(controller.state.speed, 1.5);
    expect(settings.speed, 1.5);
    await controller.setSpeed(1.1);
    expect(controller.state.speed, 1.0);
    expect(engine.currentSpeed, 1.0);
    controller.dispose();
  });

  test('resume history stays paused until user chooses', () async {
    final history = _MemoryHistory();
    history.records['sintel'] = PlaybackRecord(
      videoId: 'sintel',
      title: 'Sintel',
      cover: '',
      episodeId: 'e1',
      episodeName: '',
      positionMs: 32000,
      durationMs: 120000,
      watchedAt: DateTime(2026, 9, 10),
    );
    final engine = FakeVideoEngine();
    final controller = build(engine: engine, history: history);
    await pumpController();
    expect(controller.state.status, PlayerStatus.paused);
    expect(controller.state.resumeAt, const Duration(seconds: 32));
    expect(engine.playCount, 0);
    await controller.resumeFromStart();
    expect(engine.currentPosition, Duration.zero);
    expect(controller.state.resumeAt, isNull);
    expect(controller.state.status, PlayerStatus.playing);
    controller.dispose();
  });

  test('buffering status follows engine and togglePlay pauses', () async {
    final engine = FakeVideoEngine();
    final controller = build(engine: engine);
    await pumpController();
    engine.emitBuffering(true);
    expect(controller.state.status, PlayerStatus.buffering);
    await controller.togglePlay();
    expect(controller.state.status, PlayerStatus.paused);
    expect(engine.pauseCount, 1);
    controller.dispose();
  });

  test('engine error during playback uses abnormal message', () async {
    final engine = FakeVideoEngine();
    final controller = build(engine: engine);
    await pumpController();
    engine.emitError();
    await pumpController();
    expect(controller.state.status, PlayerStatus.error);
    expect(controller.state.error?.message, '播放异常，请检查网络后重试');
    controller.dispose();
  });

  test('app background pauses playback', () async {
    final engine = FakeVideoEngine();
    final controller = build(engine: engine);
    await pumpController();
    await controller.onAppBackground();
    expect(controller.state.status, PlayerStatus.paused);
    expect(engine.pauseCount, 1);
    controller.dispose();
  });

  testWidgets('writes history every 10 seconds while playing', (tester) async {
    final history = _MemoryHistory();
    final engine = FakeVideoEngine();
    final controller = build(engine: engine, history: history);
    await tester.pump();
    engine.tick(const Duration(seconds: 32));
    expect(history.load('sintel'), isNull);
    await tester.pump(AppConstants.playbackSaveInterval);
    await tester.pump();
    expect(history.load('sintel')?.positionMs, 32000);
    controller.dispose();
  });

  test('playNext disposes the previous engine and opens the next episode', () async {
    final engines = <FakeVideoEngine>[];
    final controller = build(
      route: const PlayerRouteArgs(mediaId: 'sample-series-a'),
      factory: () {
        final engine = FakeVideoEngine();
        engines.add(engine);
        return engine;
      },
    );
    await pumpController();
    expect(controller.state.status, PlayerStatus.playing);
    expect(controller.state.episodeId, 'sample-series-a-1');
    expect(controller.state.hasNext, isTrue);
    expect(controller.state.hasPrevious, isFalse);
    expect(controller.state.title, '示例剧集 A · 第1集');
    await controller.playNext();
    await pumpController();
    expect(engines.first.disposeCount, 1);
    expect(controller.state.episodeId, 'sample-series-a-2');
    expect(controller.state.position, Duration.zero);
    expect(controller.state.hasPrevious, isTrue);
    expect(controller.state.title, '示例剧集 A · 第2集');
    expect(engines[1].openedUrl.toString(), contains('bunny/movie'));
    controller.dispose();
  });

  test('completed auto plays the next episode', () async {
    final engines = <FakeVideoEngine>[];
    final controller = build(
      route: const PlayerRouteArgs(mediaId: 'sample-series-a'),
      factory: () {
        final engine = FakeVideoEngine();
        engines.add(engine);
        return engine;
      },
    );
    await pumpController();
    engines.first.emitCompleted();
    await pumpController();
    await pumpController();
    expect(controller.state.episodeId, 'sample-series-a-2');
    expect(controller.state.status, PlayerStatus.playing);
    expect(controller.state.shouldReturn, isFalse);
    controller.dispose();
  });

  test('last episode complete can request auto return', () async {
    final engine = FakeVideoEngine();
    final controller = build(
      route: const PlayerRouteArgs(
        mediaId: 'sample-series-a',
        episodeId: 'sample-series-a-3',
      ),
      engine: engine,
      settings: _FakeSettings(back: true),
    );
    await pumpController();
    expect(controller.state.hasNext, isFalse);
    engine.emitCompleted();
    await pumpController();
    expect(controller.state.status, PlayerStatus.completed);
    expect(controller.state.shouldReturn, isTrue);
    controller.dispose();
  });
}

Future<void> pumpController() => Future<void>.delayed(Duration.zero);

class _FakeSettings extends SettingsService {
  _FakeSettings({this.play = true, this.back = false, this.speed = 1.0});

  final bool play;
  final bool back;
  double speed;

  @override
  bool get autoPlay => play;

  @override
  bool get autoReturnAfterCompletion => back;

  @override
  double get playSpeed => speed;

  @override
  Future<void> setPlaySpeed(double value) async {
    speed = AppConstants.normalizeSpeed(value);
  }
}

class _MemoryHistory extends HistoryService {
  final Map<String, PlaybackRecord> records = {};

  @override
  PlaybackRecord? load(String mediaId, {String? episodeId}) {
    final id = mediaId.trim();
    final ep = (episodeId ?? '').trim();
    if (ep.isNotEmpty) {
      return records[HistoryService.storageKey(id, ep)] ?? records[id];
    }
    return records[id];
  }

  @override
  Future<void> save(PlaybackRecord record) async {
    records[record.videoId] = record;
    records[HistoryService.storageKey(record.videoId, record.episodeId)] =
        record;
  }

  @override
  Future<void> remove(String mediaId, {String? episodeId}) async {
    final id = mediaId.trim();
    final ep = (episodeId ?? '').trim();
    if (ep.isNotEmpty) {
      records.remove(HistoryService.storageKey(id, ep));
    }
    records.remove(id);
  }
}
