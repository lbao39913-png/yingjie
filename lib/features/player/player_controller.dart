import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/route_args.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../models/play_source.dart';
import '../../models/playback_record.dart';
import '../../models/video.dart';
import '../../services/api_service.dart';
import '../../services/history_service.dart';
import '../../services/player_service.dart';
import '../../services/settings_service.dart';
import 'video_engine.dart';

enum PlayerStatus {
  initial,
  initializing,
    ready,
    playing,
    paused,
    buffering,
    completed,
    error,
  }

class PlayerState {
  const PlayerState({
    this.status = PlayerStatus.initial,
    this.mediaId = '',
    this.title = '',
    this.playUrl = '',
    this.episodeId,
    this.sourceId,
    this.error,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1,
    this.muted = false,
    this.fullscreen = false,
    this.controlsVisible = true,
    this.seeking = false,
    this.resumeAt,
    this.cover = '',
    this.year,
    this.genres = const [],
    this.shouldReturn = false,
    this.speed = 1.0,
    this.mediaTitle = '',
    this.episodeName = '',
    this.isTv = false,
    this.hasNext = false,
    this.hasPrevious = false,
  });

  final PlayerStatus status;
  final String mediaId;
  final String title;
  final String playUrl;
  final String? episodeId;
  final String? sourceId;
  final AppException? error;
  final Duration position;
  final Duration duration;
  final double volume;
  final bool muted;
  final bool fullscreen;
  final bool controlsVisible;
  final bool seeking;
  final Duration? resumeAt;
  final String cover;
  final int? year;
  final List<String> genres;
  final bool shouldReturn;
  final double speed;
  final String mediaTitle;
  final String episodeName;
  final bool isTv;
  final bool hasNext;
  final bool hasPrevious;

  bool get isPlaying => status == PlayerStatus.playing;

  bool get isBuffering => status == PlayerStatus.buffering;

  PlayerState copyWith({
    PlayerStatus? status,
    String? mediaId,
    String? title,
    String? playUrl,
    String? episodeId,
    String? sourceId,
    AppException? error,
    bool clearError = false,
    Duration? position,
    Duration? duration,
    double? volume,
    bool? muted,
    bool? fullscreen,
    bool? controlsVisible,
    bool? seeking,
    Duration? resumeAt,
    bool clearResume = false,
    String? cover,
    int? year,
    List<String>? genres,
    bool? shouldReturn,
    double? speed,
    String? mediaTitle,
    String? episodeName,
    bool? isTv,
    bool? hasNext,
    bool? hasPrevious,
  }) {
    return PlayerState(
      status: status ?? this.status,
      mediaId: mediaId ?? this.mediaId,
      title: title ?? this.title,
      playUrl: playUrl ?? this.playUrl,
      episodeId: episodeId ?? this.episodeId,
      sourceId: sourceId ?? this.sourceId,
      error: clearError ? null : (error ?? this.error),
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      muted: muted ?? this.muted,
      fullscreen: fullscreen ?? this.fullscreen,
      controlsVisible: controlsVisible ?? this.controlsVisible,
      seeking: seeking ?? this.seeking,
      resumeAt: clearResume ? null : (resumeAt ?? this.resumeAt),
      cover: cover ?? this.cover,
      year: year ?? this.year,
      genres: genres ?? this.genres,
      shouldReturn: shouldReturn ?? this.shouldReturn,
      speed: speed ?? this.speed,
      mediaTitle: mediaTitle ?? this.mediaTitle,
      episodeName: episodeName ?? this.episodeName,
      isTv: isTv ?? this.isTv,
      hasNext: hasNext ?? this.hasNext,
      hasPrevious: hasPrevious ?? this.hasPrevious,
    );
  }
}

class PlayerController extends StateNotifier<PlayerState> {
  PlayerController(
    this._args,
    this._api,
    this._player,
    this._history,
    this._engineFactory, {
    this.hideDelay = AppConstants.playerControlsHide,
    SettingsService? settings,
  }) : _settings = settings ?? SettingsService(),
       super(
          PlayerState(
            status: PlayerStatus.initial,
            mediaId: _args.mediaId,
            title: _args.title ?? '',
            playUrl: _args.playUrl ?? '',
            episodeId: _args.episodeId,
            sourceId: _args.sourceId,
            cover: _args.cover ?? '',
            year: _args.year,
            genres: _args.genres,
          ),
        ) {
    load();
  }

  final PlayerRouteArgs _args;
  final ApiService _api;
  final PlayerService _player;
  final HistoryService _history;
  final VideoEngineFactory _engineFactory;
  final Duration hideDelay;
  final SettingsService _settings;

  VideoEngine? _engine;
  StreamSubscription<VideoEngineEvent>? _events;
  Timer? _hideTimer;
  Timer? _persistTimer;
  bool _disposed = false;
  int _session = 0;
  double _lastUnmutedVolume = 1;
  PlaySource? _playlist;
  Video? _video;
  String? _activeEpisodeId;
  bool _skipResume = false;
  bool _ignoreDirectUrl = false;

  VideoEngine? get engine => _engine;

  Future<void> load() async {
    final session = ++_session;
    _set(
      state.copyWith(
        status: PlayerStatus.initializing,
        controlsVisible: true,
        clearError: true,
        clearResume: true,
      ),
    );
    await _replaceEngine();
    if (_disposed || session != _session) {
      return;
    }

    try {
      final resolved = await _resolvePlayUrl();
      if (_disposed || session != _session) {
        return;
      }
      if (resolved == null) {
        _set(
          state.copyWith(
            status: PlayerStatus.error,
            error: const PlaybackException(message: '播放失败，请检查网络后重试'),
          ),
        );
        _skipResume = false;
        return;
      }

      final skipResume = _skipResume;
      _skipResume = false;
      final uri = Uri.tryParse(resolved.playUrl);
      if (uri == null || !uri.hasScheme || resolved.playUrl.trim().isEmpty) {
        _set(
          state.copyWith(
            status: PlayerStatus.error,
            error: const PlaybackException(message: '播放失败，请检查网络后重试'),
            playUrl: resolved.playUrl,
            title: resolved.title,
            mediaId: resolved.mediaId,
          ),
        );
        return;
      }

      _set(
        state.copyWith(
          mediaId: resolved.mediaId,
          title: resolved.title,
          playUrl: resolved.playUrl,
          episodeId: resolved.episodeId,
          sourceId: resolved.sourceId,
          resumeAt: skipResume
              ? null
              : _resumeOf(resolved.mediaId, resolved.episodeId),
          clearResume: skipResume,
          cover: resolved.cover,
          year: resolved.year,
          genres: resolved.genres,
          mediaTitle: resolved.isTv ? _video?.title ?? resolved.title : resolved.title,
          episodeName: resolved.episodeName,
          isTv: resolved.isTv,
          hasNext: _hasNext(resolved.episodeId),
          hasPrevious: _hasPrevious(resolved.episodeId),
          position: Duration.zero,
        ),
      );

      await _engine!.open(uri);
      if (_disposed || session != _session) {
        return;
      }

      final speed = _settings.playSpeed;
      await _engine!.setPlaybackSpeed(speed);
      if (_disposed || session != _session) {
        return;
      }
      _set(state.copyWith(speed: speed));
      _syncEngine(status: PlayerStatus.ready);
      if (state.resumeAt != null) {
        _syncEngine(status: PlayerStatus.paused, controlsVisible: true);
        return;
      }
      if (_settings.autoPlay) {
        await _engine!.play();
        if (_disposed || session != _session) {
          return;
        }
        _syncEngine(status: PlayerStatus.playing);
        _startPersistTimer();
        _scheduleHide();
      } else {
        _syncEngine(status: PlayerStatus.paused, controlsVisible: true);
      }
    } catch (error) {
      if (_disposed || session != _session) {
        return;
      }
      _set(
        state.copyWith(
          status: PlayerStatus.error,
          error: _mapPlayError(error),
        ),
      );
    }
  }

  Future<void> retry() => load();

  Future<void> playNext() => _switchEpisode(next: true);

  Future<void> playPrevious() => _switchEpisode(next: false);

  Future<void> togglePlay() async {
    if (state.status == PlayerStatus.completed) {
      await replay();
      return;
    }
    if (state.isPlaying || state.isBuffering) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> play() async {
    if (_engine == null || !(_engine?.isInitialized ?? false)) {
      return;
    }
    await _engine!.play();
    if (_disposed) {
      return;
    }
    _syncEngine(status: PlayerStatus.playing, controlsVisible: true);
    _startPersistTimer();
    _scheduleHide();
  }

  Future<void> pause() async {
    await _engine?.pause();
    if (_disposed) {
      return;
    }
    _hideTimer?.cancel();
    _stopPersistTimer();
    _syncEngine(status: PlayerStatus.paused, controlsVisible: true);
    await persistProgress();
  }

  Future<void> replay() async {
    if (_engine == null || !(_engine?.isInitialized ?? false)) {
      await load();
      return;
    }
    await _engine!.seekTo(Duration.zero);
    await _engine!.play();
    if (_disposed) {
      return;
    }
    _syncEngine(
      status: PlayerStatus.playing,
      position: Duration.zero,
      controlsVisible: true,
    );
    _startPersistTimer();
    _scheduleHide();
  }

  void onSeekStart() {
    _hideTimer?.cancel();
    _set(state.copyWith(seeking: true, controlsVisible: true));
  }

  void onSeekChanged(Duration position) {
    _set(state.copyWith(position: position, seeking: true));
  }

  Future<void> onSeekEnd(Duration position) async {
    await _engine?.seekTo(position);
    if (_disposed) {
      return;
    }
    _syncEngine(seeking: false, position: position, controlsVisible: true);
    await persistProgress();
    _scheduleHide();
  }

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    if (clamped > 0) {
      _lastUnmutedVolume = clamped;
    }
    await _engine?.setVolume(clamped);
    if (_disposed) {
      return;
    }
    _set(
      state.copyWith(
        volume: clamped,
        muted: clamped == 0,
        controlsVisible: true,
      ),
    );
    _scheduleHide();
  }

  Future<void> toggleMute() async {
    if (state.muted || state.volume == 0) {
      await setVolume(_lastUnmutedVolume == 0 ? 1 : _lastUnmutedVolume);
    } else {
      _lastUnmutedVolume = state.volume;
      await setVolume(0);
    }
  }

  void toggleFullscreen() {
    _set(
      state.copyWith(
        fullscreen: !state.fullscreen,
        controlsVisible: true,
      ),
    );
    _scheduleHide();
  }

  void toggleControls() {
    if (state.resumeAt != null) {
      return;
    }
    if (state.controlsVisible) {
      _hideTimer?.cancel();
      _set(state.copyWith(controlsVisible: false));
      return;
    }
    _set(state.copyWith(controlsVisible: true));
    _scheduleHide();
  }

  Future<void> resumeFromHistory() async {
    final resumeAt = state.resumeAt;
    if (resumeAt == null) {
      return;
    }
    _set(state.copyWith(clearResume: true, controlsVisible: true));
    await onSeekEnd(resumeAt);
    await play();
  }

  Future<void> resumeFromStart() async {
    _set(state.copyWith(clearResume: true, controlsVisible: true));
    await onSeekEnd(Duration.zero);
    await play();
  }

  Future<void> setSpeed(double speed) async {
    final next = AppConstants.normalizeSpeed(speed);
    await _engine?.setPlaybackSpeed(next);
    if (_disposed) {
      return;
    }
    await _settings.setPlaySpeed(next);
    if (_disposed) {
      return;
    }
    _set(state.copyWith(speed: next, controlsVisible: true));
    _scheduleHide();
  }

  Future<void> onAppBackground() {
    if (state.status == PlayerStatus.playing ||
        state.status == PlayerStatus.buffering) {
      return pause();
    }
    return persistProgress();
  }

  Future<void> persistProgress() async {
    final mediaId = state.mediaId.trim();
    if (mediaId.isEmpty) {
      return;
    }
    final positionMs = state.position.inMilliseconds;
    final durationMs = state.duration.inMilliseconds;
    if (durationMs <= 0) {
      return;
    }
    if (positionMs < AppConstants.playbackResumeMinMs) {
      return;
    }
    if (durationMs - positionMs <= AppConstants.playbackNearEndMs) {
      await _history.remove(mediaId, episodeId: state.episodeId);
      return;
    }
    await _history.save(
      _recordFor(mediaId, positionMs, durationMs),
    );
  }

  Duration? _resumeOf(String mediaId, String? episodeId) {
    final record = _history.load(mediaId, episodeId: episodeId);
    if (record == null) {
      return null;
    }
    if (record.positionMs < AppConstants.playbackResumeMinMs) {
      return null;
    }
    if (record.durationMs - record.positionMs <= AppConstants.playbackNearEndMs) {
      return null;
    }
    return Duration(milliseconds: record.positionMs);
  }

  Future<PlayLaunch?> _resolvePlayUrl() async {
    await _bindPlaylist();
    if (_disposed) {
      return null;
    }
    final episodeId = _activeEpisodeId ?? _args.episodeId;
    final direct = (_args.playUrl ?? '').trim();
    if (direct.isNotEmpty && !_ignoreDirectUrl) {
      return PlayLaunch(
        mediaId: _args.mediaId,
        title: (_args.title ?? '').trim().isEmpty ? '影片' : _args.title!.trim(),
        playUrl: direct,
        episodeId: episodeId,
        sourceId: _args.sourceId,
        cover: _args.cover ?? '',
        year: _args.year,
        genres: _args.genres,
        episodeName: _episodeNameOf(episodeId),
        isTv: _video?.isTv ?? false,
      );
    }
    final id = _args.mediaId.trim();
    if (id.isEmpty) {
      return null;
    }
    final video = _video;
    if (video == null) {
      return null;
    }
    return _player.resolveLaunch(
      video,
      sourceId: _args.sourceId,
      episodeId: episodeId,
    );
  }

  Future<void> _bindPlaylist() async {
    final id = _args.mediaId.trim();
    if (id.isEmpty) {
      return;
    }
    if (_video?.id == id && _playlist != null) {
      return;
    }
    final result = await _api.fetchDetail(id);
    result.when(
      success: (video) {
        _video = video;
        _playlist = _player.resolveSource(video, sourceId: _args.sourceId);
      },
      failure: (_) {},
    );
  }

  Future<void> _switchEpisode({required bool next}) async {
    final source = _playlist;
    final currentId = state.episodeId;
    if (source == null || currentId == null || currentId.isEmpty) {
      return;
    }
    final episode = next
        ? _player.nextEpisode(source, currentId)
        : _player.previousEpisode(source, currentId);
    if (episode == null) {
      return;
    }
    await persistProgress();
    if (_disposed) {
      return;
    }
    _skipResume = true;
    _ignoreDirectUrl = true;
    _activeEpisodeId = episode.id;
    await load();
  }

  bool _hasNext(String? episodeId) {
    final source = _playlist;
    if (source == null || episodeId == null || episodeId.isEmpty) {
      return false;
    }
    return _player.nextEpisode(source, episodeId) != null;
  }

  bool _hasPrevious(String? episodeId) {
    final source = _playlist;
    if (source == null || episodeId == null || episodeId.isEmpty) {
      return false;
    }
    return _player.previousEpisode(source, episodeId) != null;
  }

  String _episodeNameOf(String? episodeId) {
    final source = _playlist;
    if (source == null || episodeId == null) {
      return '';
    }
    return _player.resolveEpisode(source, episodeId: episodeId)?.name ?? '';
  }

  Future<void> _replaceEngine() async {
    await _events?.cancel();
    final previous = _engine;
    _engine = _engineFactory();
    _engine!.attach(_onEngineChanged);
    _events = _engine!.events.listen(_onEngineEvent);
    await previous?.dispose();
  }

  void _onEngineChanged() {
    if (_disposed || state.seeking) {
      return;
    }
    if (state.status == PlayerStatus.error ||
        state.status == PlayerStatus.initializing) {
      return;
    }
    _syncEngine();
  }

  void _onEngineEvent(VideoEngineEvent event) {
    if (_disposed) {
      return;
    }
    switch (event) {
      case VideoEngineEvent.completed:
        _hideTimer?.cancel();
        _stopPersistTimer();
        unawaited(
          _history.remove(state.mediaId, episodeId: state.episodeId),
        );
        if (state.hasNext && _settings.autoPlay) {
          unawaited(playNext());
          return;
        }
        _syncEngine(
          status: PlayerStatus.completed,
          controlsVisible: true,
        );
        if (!state.hasNext && _settings.autoReturnAfterCompletion) {
          _set(state.copyWith(shouldReturn: true));
        }
      case VideoEngineEvent.error:
        _hideTimer?.cancel();
        _stopPersistTimer();
        _set(
          state.copyWith(
            status: PlayerStatus.error,
            error: const PlaybackException(message: '播放异常，请检查网络后重试'),
            controlsVisible: true,
          ),
        );
    }
  }

  void _syncEngine({
    PlayerStatus? status,
    bool? controlsVisible,
    bool? seeking,
    Duration? position,
  }) {
    final engine = _engine;
    var nextStatus = status ?? state.status;
    if (status == null &&
        engine != null &&
        !(seeking ?? state.seeking) &&
        nextStatus != PlayerStatus.error &&
        nextStatus != PlayerStatus.completed &&
        nextStatus != PlayerStatus.initializing) {
      if (engine.isBuffering &&
          (nextStatus == PlayerStatus.playing ||
              nextStatus == PlayerStatus.buffering)) {
        nextStatus = PlayerStatus.buffering;
      } else if (nextStatus == PlayerStatus.buffering && !engine.isBuffering) {
        nextStatus =
            engine.isPlaying ? PlayerStatus.playing : PlayerStatus.paused;
      }
    }
    _set(
      state.copyWith(
        status: nextStatus,
        position: position ?? engine?.position ?? state.position,
        duration: engine?.duration ?? state.duration,
        volume: state.muted ? 0 : (engine?.volume ?? state.volume),
        controlsVisible: controlsVisible ?? state.controlsVisible,
        seeking: seeking ?? state.seeking,
        speed: engine?.playbackSpeed ?? state.speed,
      ),
    );
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (_disposed || hideDelay == Duration.zero) {
      return;
    }
    if (state.status != PlayerStatus.playing) {
      return;
    }
    _hideTimer = Timer(hideDelay, () {
      if (_disposed || state.status != PlayerStatus.playing) {
        return;
      }
      _set(state.copyWith(controlsVisible: false));
    });
  }

  void _startPersistTimer() {
    _persistTimer?.cancel();
    _persistTimer = Timer.periodic(AppConstants.playbackSaveInterval, (_) {
      if (_disposed) {
        return;
      }
      unawaited(persistProgress());
    });
  }

  void _stopPersistTimer() {
    _persistTimer?.cancel();
    _persistTimer = null;
  }

  AppException _mapPlayError(Object error) {
    final mapped = ErrorMapper.map(error);
    if (mapped is PlaybackException) {
      return mapped;
    }
    return const PlaybackException(message: '播放失败，请检查网络后重试');
  }

  void _set(PlayerState next) {
    if (_disposed) {
      return;
    }
    state = next;
  }

  @override
  void dispose() {
    _disposed = true;
    _hideTimer?.cancel();
    _stopPersistTimer();
    _events?.cancel();
    final record = _snapshotRecord();
    final engine = _engine;
    _engine = null;
    super.dispose();
    unawaited(engine?.dispose());
    if (record != null) {
      unawaited(_history.save(record));
    }
  }

  PlaybackRecord? _snapshotRecord() {
    final mediaId = state.mediaId.trim();
    final durationMs = state.duration.inMilliseconds;
    final positionMs = state.position.inMilliseconds;
    if (mediaId.isEmpty || durationMs <= 0) {
      return null;
    }
    if (positionMs < AppConstants.playbackResumeMinMs) {
      return null;
    }
    if (durationMs - positionMs <= AppConstants.playbackNearEndMs) {
      return null;
    }
    return _recordFor(mediaId, positionMs, durationMs);
  }

  PlaybackRecord _recordFor(String mediaId, int positionMs, int durationMs) {
    final existing = _history.load(mediaId, episodeId: state.episodeId);
    final cover = state.cover.trim().isNotEmpty
        ? state.cover
        : (existing?.cover ?? '');
    final genres =
        state.genres.isNotEmpty ? state.genres : (existing?.genres ?? const []);
    final title = state.mediaTitle.trim().isNotEmpty
        ? state.mediaTitle
        : state.title;
    final episodeName = state.episodeName.trim().isNotEmpty
        ? state.episodeName
        : (existing?.episodeName ?? '');
    return PlaybackRecord(
      videoId: mediaId,
      title: title,
      cover: cover,
      episodeId: state.episodeId ?? '',
      episodeName: episodeName,
      positionMs: positionMs,
      durationMs: durationMs,
      watchedAt: DateTime.now(),
      sourceId: state.sourceId,
      year: state.year ?? existing?.year,
      genres: genres,
    );
  }
}

final playerControllerProvider = StateNotifierProvider.autoDispose
    .family<PlayerController, PlayerState, PlayerRouteArgs>((ref, args) {
  return PlayerController(
    args,
    ref.watch(apiServiceProvider),
    ref.watch(playerServiceProvider),
    ref.watch(historyServiceProvider),
    ref.watch(videoEngineFactoryProvider),
    settings: ref.watch(settingsServiceProvider),
  );
});
