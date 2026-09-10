import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../app/theme.dart';

class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.url,
    this.borderRadius = 16,
  });

  final String url;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: url.trim().isEmpty
          ? const CoverPlaceholder(failed: true)
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => const CoverPlaceholder(),
              errorWidget: (context, url, error) {
                return const CoverPlaceholder(failed: true);
              },
            ),
    );
  }
}

class CoverPlaceholder extends StatelessWidget {
  const CoverPlaceholder({super.key, this.failed = false});

  final bool failed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: YingjieTheme.card,
      child: Center(
        child: Icon(
          failed ? Icons.broken_image_outlined : Icons.movie_outlined,
          color: YingjieTheme.textMuted,
          size: 32,
        ),
      ),
    );
  }
}
