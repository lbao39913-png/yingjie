import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class PlayerCompletedView extends StatelessWidget {
  const PlayerCompletedView({
    super.key,
    required this.onReplay,
    this.onNext,
    this.hasNext = false,
  });

  final VoidCallback onReplay;
  final VoidCallback? onNext;
  final bool hasNext;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x99000000),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '播放完成',
              style: TextStyle(
                color: YingjieTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onReplay,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('重新播放'),
            ),
            if (hasNext && onNext != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('player-completed-next'),
                onPressed: onNext,
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('播放下一集'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
