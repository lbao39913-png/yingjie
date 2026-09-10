import 'package:flutter/material.dart';

import '../app/theme.dart';

class PhasePlaceholder extends StatelessWidget {
  const PhasePlaceholder({
    super.key,
    required this.title,
    required this.summary,
  });

  final String title;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: YingjieTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              summary,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: YingjieTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
