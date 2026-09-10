import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_args.dart';
import '../../app/theme.dart';
import '../../models/playback_record.dart';
import '../../widgets/async_feedback.dart';
import '../../widgets/cover_image.dart';
import 'history_controller.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  Future<void> _remove(
    BuildContext context,
    HistoryController controller,
    PlaybackRecord record,
  ) async {
    await controller.remove(record.videoId, episodeId: record.episodeId);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已删除')),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    HistoryController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('清空观看历史'),
          content: const Text('清空后无法恢复这些记录'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              key: const Key('history-clear-confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('清空'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    await controller.clear();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已清空观看历史')),
    );
  }

  void _openPlayer(BuildContext context, PlaybackRecord record) {
    final args = PlayerRouteArgs(
      mediaId: record.videoId,
      title: record.title,
      episodeId: record.episodeId.isEmpty ? null : record.episodeId,
      sourceId: record.sourceId,
      cover: record.cover,
      year: record.year,
      genres: record.genres,
    );
    context.pushNamed(
      'player',
      pathParameters: {'id': args.mediaId},
      queryParameters: args.toQuery(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyControllerProvider);
    final controller = ref.read(historyControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('观看历史'),
        actions: [
          if (state.status == HistoryStatus.success)
            TextButton(
              key: const Key('history-clear'),
              onPressed: () => _confirmClear(context, controller),
              child: const Text('清空'),
            ),
        ],
      ),
      body: switch (state.status) {
        HistoryStatus.initial || HistoryStatus.loading => const SizedBox.expand(),
        HistoryStatus.error => ErrorPanel(
            message: state.error?.message ?? '本地数据读取失败',
            onRetry: controller.load,
          ),
        HistoryStatus.empty => const _HistoryEmpty(),
        HistoryStatus.success => _HistoryGrid(
            items: state.items,
            onOpen: (record) => _openPlayer(context, record),
            onRemove: (record) => _remove(context, controller, record),
          ),
      },
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 56,
              color: YingjieTheme.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              '还没有观看记录',
              style: TextStyle(
                color: YingjieTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '看过的影片会出现在这里，\n可以从中继续播放',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: YingjieTheme.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('history-go-home'),
              onPressed: () => context.go('/home'),
              child: const Text('去发现影片'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryGrid extends StatelessWidget {
  const _HistoryGrid({
    required this.items,
    required this.onOpen,
    required this.onRemove,
  });

  final List<PlaybackRecord> items;
  final ValueChanged<PlaybackRecord> onOpen;
  final ValueChanged<PlaybackRecord> onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 0.42,
      ),
      itemBuilder: (context, index) {
        final record = items[index];
        return _HistoryCard(
          key: Key('history-card-${record.cardKey}'),
          record: record,
          onTap: () => onOpen(record),
          onLongPress: () => onRemove(record),
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    super.key,
    required this.record,
    required this.onTap,
    required this.onLongPress,
  });

  final PlaybackRecord record;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CoverImage(url: record.cover),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: LinearProgressIndicator(
                    key: Key('history-progress-${record.cardKey}'),
                    value: record.progress,
                    minHeight: 4,
                    backgroundColor: Colors.black38,
                    color: YingjieTheme.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            record.displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: YingjieTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '已观看 ${record.watchedPercent}%',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: YingjieTheme.textMuted,
              fontSize: 11,
            ),
          ),
          Text(
            record.relativeWatchedLabel(),
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
