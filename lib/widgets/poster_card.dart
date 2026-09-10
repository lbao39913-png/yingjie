import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/video.dart';
import 'cover_image.dart';

class PosterCard extends StatelessWidget {
  const PosterCard({
    super.key,
    required this.video,
    required this.onTap,
    this.width = 118,
  });

  final Video video;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final card = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: CoverImage(url: video.cover),
          ),
          const SizedBox(height: 8),
          Text(
            video.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: YingjieTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (video.year != null)
            Text(
              '${video.year}',
              style: const TextStyle(
                color: YingjieTheme.textMuted,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
    if (width == null) {
      return card;
    }
    return SizedBox(width: width, child: card);
  }
}
