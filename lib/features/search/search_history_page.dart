import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import 'search_history_controller.dart';

class SearchHistoryPage extends ConsumerWidget {
  const SearchHistoryPage({super.key});

  Future<void> _confirmClear(
    BuildContext context,
    SearchHistoryController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('清空搜索记录'),
          content: const Text('清空后无法恢复这些关键词'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              key: const Key('search-history-clear-confirm'),
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
      const SnackBar(content: Text('已清空搜索记录')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(searchHistoryControllerProvider);
    final controller = ref.read(searchHistoryControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索记录'),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              key: const Key('search-history-clear'),
              onPressed: () => _confirmClear(context, controller),
              child: const Text('清空'),
            ),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                '还没有搜索记录',
                style: TextStyle(color: YingjieTheme.textMuted),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final keyword = items[index];
                return Material(
                  color: YingjieTheme.card,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    key: Key('search-history-$keyword'),
                    title: Text(keyword),
                    trailing: IconButton(
                      key: Key('search-history-remove-$keyword'),
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => controller.remove(keyword),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
