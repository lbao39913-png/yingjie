import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../widgets/skeleton.dart';

class PlayerLoading extends StatelessWidget {
  const PlayerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PulseSkeleton(width: double.infinity, height: double.infinity, radius: 0),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: YingjieTheme.accent,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  '正在加载影片',
                  style: TextStyle(
                    color: YingjieTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
