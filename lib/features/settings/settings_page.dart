import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import 'settings_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<bool> _confirm({
    required BuildContext context,
    required String title,
    required String content,
    required Key confirmKey,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              key: confirmKey,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  Future<void> _snack(BuildContext context, String message) async {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const _SectionTitle('播放'),
          _Card(
            child: Column(
              children: [
                SwitchListTile(
                  key: const Key('settings-auto-play'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('进入播放页自动播放'),
                  subtitle: const Text('关闭后需手动点击播放'),
                  value: state.autoPlay,
                  onChanged: controller.setAutoPlay,
                ),
                SwitchListTile(
                  key: const Key('settings-auto-return'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('播放完成后自动返回'),
                  subtitle: const Text('默认关闭，避免误退回上一页'),
                  value: state.autoReturnAfterCompletion,
                  onChanged: controller.setAutoReturnAfterCompletion,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('本地数据'),
          _Card(
            child: Column(
              children: [
                _DataTile(
                  key: const Key('settings-clear-cache'),
                  title: '清理图片缓存',
                  subtitle: state.cacheBusy ? '正在计算…' : state.cacheLabel,
                  onTap: () async {
                    final ok = await _confirm(
                      context: context,
                      title: '清理图片缓存',
                      content: '只会清理封面等图片缓存，不会删除收藏、历史和搜索记录',
                      confirmKey: const Key('settings-clear-cache-confirm'),
                    );
                    if (!ok) {
                      return;
                    }
                    await controller.clearCache();
                    if (context.mounted) {
                      await _snack(context, '已清理图片缓存');
                    }
                  },
                ),
                _DataTile(
                  key: const Key('settings-clear-search'),
                  title: '清空搜索记录',
                  subtitle: '${state.searchCount} 条',
                  onTap: () async {
                    final ok = await _confirm(
                      context: context,
                      title: '清空搜索记录',
                      content: '清空后无法恢复这些关键词',
                      confirmKey: const Key('settings-clear-search-confirm'),
                    );
                    if (!ok) {
                      return;
                    }
                    await controller.clearSearchHistory();
                    if (context.mounted) {
                      await _snack(context, '已清空搜索记录');
                    }
                  },
                ),
                _DataTile(
                  key: const Key('settings-clear-favorites'),
                  title: '清空收藏',
                  subtitle: '${state.favoriteCount} 部',
                  onTap: () async {
                    final ok = await _confirm(
                      context: context,
                      title: '清空收藏',
                      content: '清空后无法恢复这些收藏，观看历史不会受影响',
                      confirmKey: const Key('settings-clear-favorites-confirm'),
                    );
                    if (!ok) {
                      return;
                    }
                    await controller.clearFavorites();
                    if (context.mounted) {
                      await _snack(context, '已清空收藏');
                    }
                  },
                ),
                _DataTile(
                  key: const Key('settings-clear-history'),
                  title: '清空观看历史',
                  subtitle: '${state.historyCount} 部',
                  onTap: () async {
                    final ok = await _confirm(
                      context: context,
                      title: '清空观看历史',
                      content: '清空后无法恢复这些记录，收藏不会受影响',
                      confirmKey: const Key('settings-clear-history-confirm'),
                    );
                    if (!ok) {
                      return;
                    }
                    await controller.clearPlaybackHistory();
                    if (context.mounted) {
                      await _snack(context, '已清空观看历史');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: YingjieTheme.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YingjieTheme.card,
      borderRadius: BorderRadius.circular(16),
      child: child,
    );
  }
}

class _DataTile extends StatelessWidget {
  const _DataTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: YingjieTheme.textMuted,
      ),
      onTap: onTap,
    );
  }
}
