import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../player_controller.dart';
import '../player_time.dart';
import 'player_progress.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.state,
    required this.onBack,
    required this.onPlayPause,
    required this.onToggleMute,
    required this.onToggleFullscreen,
    required this.onSeekStart,
    required this.onSeekChanged,
    required this.onSeekEnd,
    required this.onResume,
    required this.onResumeFromStart,
    required this.onSetSpeed,
    this.onPrevious,
    this.onNext,
  });

  final PlayerState state;
  final VoidCallback onBack;
  final VoidCallback onPlayPause;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onSeekStart;
  final ValueChanged<Duration> onSeekChanged;
  final ValueChanged<Duration> onSeekEnd;
  final VoidCallback onResume;
  final VoidCallback onResumeFromStart;
  final ValueChanged<double> onSetSpeed;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xCC0B0D12),
            Color(0x00000000),
            Color(0x00000000),
            Color(0xCC0B0D12),
          ],
          stops: [0, 0.28, 0.68, 1],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  key: const Key('player-back'),
                  tooltip: '返回',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
                Expanded(
                  child: Text(
                    state.title.isEmpty ? '播放' : state.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: YingjieTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const Spacer(),
            if (state.resumeAt != null) _ResumePrompt(
              resumeAt: state.resumeAt!,
              onResume: onResume,
              onResumeFromStart: onResumeFromStart,
            ),
            if (state.resumeAt == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (state.isTv)
                    IconButton(
                      key: const Key('player-previous'),
                      tooltip: '上一集',
                      onPressed: state.hasPrevious ? onPrevious : null,
                      icon: const Icon(
                        Icons.skip_previous_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  IconButton(
                    key: const Key('player-play-pause'),
                    onPressed: onPlayPause,
                    iconSize: 56,
                    icon: Icon(
                      state.isPlaying || state.isBuffering
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_filled_rounded,
                      color: Colors.white,
                    ),
                  ),
                  if (state.isTv)
                    IconButton(
                      key: const Key('player-next'),
                      tooltip: '下一集',
                      onPressed: state.hasNext ? onNext : null,
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                children: [
                  PlayerProgress(
                    position: state.position,
                    duration: state.duration,
                    onChangeStart: (_) => onSeekStart(),
                    onChanged: (value) {
                      onSeekChanged(Duration(milliseconds: value.round()));
                    },
                    onChangeEnd: (value) {
                      onSeekEnd(Duration(milliseconds: value.round()));
                    },
                  ),
                  Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        key: const Key('player-speed'),
                        onPressed: () => _showSpeeds(context),
                        child: Text(
                          '${_speedLabel(state.speed)}x',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        key: const Key('player-mute'),
                        tooltip: state.muted ? '取消静音' : '静音',
                        onPressed: onToggleMute,
                        icon: Icon(
                          state.muted || state.volume == 0
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        key: const Key('player-fullscreen'),
                        tooltip: state.fullscreen ? '退出全屏' : '全屏',
                        onPressed: onToggleFullscreen,
                        icon: Icon(
                          state.fullscreen
                              ? Icons.fullscreen_exit_rounded
                              : Icons.fullscreen_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSpeeds(BuildContext context) async {
    final selected = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: YingjieTheme.card,
      useRootNavigator: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '倍速',
                      style: TextStyle(
                        color: YingjieTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                for (final speed in AppConstants.playerSpeeds)
                  ListTile(
                    key: Key('player-speed-$speed'),
                    title: Text('${_speedLabel(speed)}x'),
                    trailing: speed == state.speed
                        ? const Icon(Icons.check_rounded, color: YingjieTheme.accent)
                        : null,
                    onTap: () => Navigator.of(context).pop(speed),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) {
      onSetSpeed(selected);
    }
  }

  static String _speedLabel(double speed) {
    if (speed == speed.roundToDouble()) {
      return speed.toStringAsFixed(1);
    }
    return speed.toString();
  }
}

class _ResumePrompt extends StatelessWidget {
  const _ResumePrompt({
    required this.resumeAt,
    required this.onResume,
    required this.onResumeFromStart,
  });

  final Duration resumeAt;
  final VoidCallback onResume;
  final VoidCallback onResumeFromStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          const Text(
            '继续播放',
            style: TextStyle(
              color: YingjieTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '从 ${formatPlayerTime(resumeAt)} 继续',
            style: const TextStyle(color: YingjieTheme.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                key: const Key('player-resume'),
                onPressed: onResume,
                child: const Text('继续播放'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: const Key('player-resume-start'),
                onPressed: onResumeFromStart,
                child: const Text('从头播放'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
