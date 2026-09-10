import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../player_time.dart';

class PlayerProgress extends StatelessWidget {
  const PlayerProgress({
    super.key,
    required this.position,
    required this.duration,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final max = duration.inMilliseconds <= 0 ? 1.0 : duration.inMilliseconds.toDouble();
    final value = position.inMilliseconds.clamp(0, max.toInt()).toDouble();
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: YingjieTheme.accent,
            inactiveTrackColor: Colors.white24,
            thumbColor: YingjieTheme.accent,
          ),
          child: Slider(
            key: const Key('player-progress'),
            min: 0,
            max: max,
            value: value,
            onChangeStart: onChangeStart,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            formatPlayerTimeRange(position, duration),
            key: const Key('player-time'),
            style: const TextStyle(color: YingjieTheme.textPrimary, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
