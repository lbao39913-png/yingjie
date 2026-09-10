import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_args.dart';
import 'player_chrome.dart';
import 'player_controller.dart';
import 'widgets/player_completed.dart';
import 'widgets/player_controls.dart';
import 'widgets/player_error.dart';
import 'widgets/player_loading.dart';

class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({
    super.key,
    required this.videoId,
    this.title,
    this.playUrl,
    this.episodeId,
    this.sourceId,
    this.cover,
    this.year,
    this.genres = const [],
    this.chrome = const PlayerChrome(),
  });

  final String videoId;
  final String? title;
  final String? playUrl;
  final String? episodeId;
  final String? sourceId;
  final String? cover;
  final int? year;
  final List<String> genres;
  final PlayerChrome chrome;

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage>
    with WidgetsBindingObserver {
  late final PlayerRouteArgs _args = PlayerRouteArgs(
    mediaId: widget.videoId,
    title: widget.title,
    playUrl: widget.playUrl,
    episodeId: widget.episodeId,
    sourceId: widget.sourceId,
    cover: widget.cover,
    year: widget.year,
    genres: widget.genres,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.chrome.exitFullscreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.chrome.restore();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(
        ref.read(playerControllerProvider(_args).notifier).onAppBackground(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerControllerProvider(_args));
    final controller = ref.read(playerControllerProvider(_args).notifier);

    ref.listen<bool>(
      playerControllerProvider(_args).select((value) => value.fullscreen),
      (previous, next) {
        if (next) {
          widget.chrome.enterFullscreen();
        } else {
          widget.chrome.exitFullscreen();
        }
      },
    );

    ref.listen<bool>(
      playerControllerProvider(_args).select((value) => value.shouldReturn),
      (previous, next) {
        if (next && context.canPop()) {
          context.pop();
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: ColoredBox(
        color: Colors.black,
        child: state.fullscreen
            ? _PlayerStage(state: state, controller: controller)
            : SafeArea(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _PlayerStage(state: state, controller: controller),
                  ),
                ),
              ),
      ),
    );
  }
}

class _PlayerStage extends ConsumerWidget {
  const _PlayerStage({
    required this.state,
    required this.controller,
  });

  final PlayerState state;
  final PlayerController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: controller.toggleControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          if (state.status == PlayerStatus.initial ||
              state.status == PlayerStatus.initializing)
            const PlayerLoading(),
          if (state.status == PlayerStatus.error)
            PlayerErrorView(
              onRetry: controller.retry,
              message: state.error?.message,
            ),
          if (state.status != PlayerStatus.initial &&
              state.status != PlayerStatus.initializing &&
              state.status != PlayerStatus.error)
            _VideoSurface(controller: controller),
          if (state.status == PlayerStatus.completed)
            PlayerCompletedView(
              onReplay: controller.replay,
              hasNext: state.hasNext,
              onNext: controller.playNext,
            ),
          if (state.isBuffering)
            const IgnorePointer(
              child: Center(
                child: SizedBox(
                  key: Key('player-buffering'),
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (state.controlsVisible &&
              state.status != PlayerStatus.initializing &&
              state.status != PlayerStatus.initial &&
              state.status != PlayerStatus.error)
            PlayerControls(
              state: state,
              onBack: () => context.pop(),
              onPlayPause: controller.togglePlay,
              onToggleMute: controller.toggleMute,
              onToggleFullscreen: controller.toggleFullscreen,
              onSeekStart: controller.onSeekStart,
              onSeekChanged: controller.onSeekChanged,
              onSeekEnd: controller.onSeekEnd,
              onResume: controller.resumeFromHistory,
              onResumeFromStart: controller.resumeFromStart,
              onSetSpeed: controller.setSpeed,
              onPrevious: controller.playPrevious,
              onNext: controller.playNext,
            ),
        ],
      ),
    );
  }
}

class _VideoSurface extends StatelessWidget {
  const _VideoSurface({required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final engine = controller.engine;
    if (engine == null || !engine.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 16,
        height: 16 / engine.aspectRatio,
        child: engine.buildView(),
      ),
    );
  }
}
