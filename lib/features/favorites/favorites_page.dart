import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/video.dart';
import '../../widgets/async_feedback.dart';
import '../../widgets/cover_image.dart';
import 'favorites_controller.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  Future<void> _remove(
    BuildContext context,
    FavoritesController controller,
    Video video,
  ) async {
    await controller.remove(video.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已取消收藏')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoritesControllerProvider);
    final controller = ref.read(favoritesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('我的收藏')),
      body: switch (state.status) {
        FavoritesStatus.initial || FavoritesStatus.loading => const SizedBox.expand(),
        FavoritesStatus.error => ErrorPanel(
            message: state.error?.message ?? '本地数据读取失败',
            onRetry: controller.load,
          ),
        FavoritesStatus.empty => const _FavoritesEmpty(),
        FavoritesStatus.success => _FavoritesGrid(
            items: state.items,
            onOpen: (video) => context.push('/detail/${video.id}'),
            onRemove: (video) => _remove(context, controller, video),
          ),
      },
    );
  }
}

class _FavoritesEmpty extends StatelessWidget {
  const _FavoritesEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_border_rounded,
              size: 56,
              color: YingjieTheme.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              '还没有收藏影片',
              style: TextStyle(
                color: YingjieTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '看到喜欢的影片，\n点击收藏后就会出现在这里',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: YingjieTheme.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('favorites-go-home'),
              onPressed: () => context.go('/home'),
              child: const Text('去发现影片'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesGrid extends StatelessWidget {
  const _FavoritesGrid({
    required this.items,
    required this.onOpen,
    required this.onRemove,
  });

  final List<Video> items;
  final ValueChanged<Video> onOpen;
  final ValueChanged<Video> onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 0.48,
      ),
      itemBuilder: (context, index) {
        final video = items[index];
        return _FavoriteCard(
          key: Key('favorite-card-${video.id}'),
          video: video,
          onTap: () => onOpen(video),
          onLongPress: () => onRemove(video),
        );
      },
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    super.key,
    required this.video,
    required this.onTap,
    required this.onLongPress,
  });

  final Video video;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (video.year != null) '${video.year}',
      ...video.genres.take(2),
      if (video.rating != null) video.rating!.toStringAsFixed(1),
    ].join(' · ');
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Column(
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
          if (meta.isNotEmpty)
            Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: YingjieTheme.textMuted,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}
