import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/video.dart';
import 'poster_card.dart';

class SectionBlock extends StatelessWidget {
  const SectionBlock({
    super.key,
    required this.title,
    required this.items,
    required this.onTapVideo,
    this.onMore,
  });

  final String title;
  final List<Video> items;
  final ValueChanged<Video> onTapVideo;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: YingjieTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onMore != null)
                TextButton(
                  onPressed: onMore,
                  child: const Text('更多'),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 230,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final video = items[index];
              return PosterCard(
                video: video,
                onTap: () => onTapVideo(video),
              );
            },
          ),
        ),
      ],
    );
  }
}
