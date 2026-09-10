import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class PlayerErrorView extends StatelessWidget {
  const PlayerErrorView({
    super.key,
    required this.onRetry,
    this.message,
  });

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final isAbnormal = (message ?? '').contains('播放异常');
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: YingjieTheme.textMuted,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                isAbnormal ? '播放异常' : '播放失败',
                style: const TextStyle(
                  color: YingjieTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '请检查网络后重试',
                style: TextStyle(color: YingjieTheme.textMuted),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('player-retry'),
                onPressed: onRetry,
                child: const Text('重新加载'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
