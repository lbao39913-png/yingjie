import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import 'mine_controller.dart';

class MinePage extends ConsumerWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mineControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const _UserCard(),
          const SizedBox(height: 20),
          _MineTile(
            key: const Key('mine-favorites'),
            icon: Icons.favorite_rounded,
            title: '我的收藏',
            subtitle: '${state.favoriteCount} 部',
            onTap: () => context.go('/favorites'),
          ),
          _MineTile(
            key: const Key('mine-history'),
            icon: Icons.history_rounded,
            title: '播放历史',
            subtitle: '${state.historyCount} 部',
            onTap: () => context.go('/history'),
          ),
          _MineTile(
            key: const Key('mine-search-history'),
            icon: Icons.search_rounded,
            title: '搜索记录',
            subtitle: '${state.searchCount} 条',
            onTap: () => context.push('/search-history'),
          ),
          const SizedBox(height: 12),
          _MineTile(
            key: const Key('mine-settings'),
            icon: Icons.settings_rounded,
            title: '设置',
            subtitle: '播放与本地数据',
            onTap: () => context.push('/settings'),
          ),
          _MineTile(
            key: const Key('mine-about'),
            icon: Icons.info_outline_rounded,
            title: '关于影界',
            subtitle: '版本与隐私说明',
            onTap: () => context.push('/about'),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: YingjieTheme.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: YingjieTheme.surface,
            child: Icon(
              Icons.person_rounded,
              color: YingjieTheme.accent,
              size: 32,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '影界用户',
                  style: TextStyle(
                    color: YingjieTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '本地用户 · 无需登录',
                  style: TextStyle(
                    color: YingjieTheme.textMuted,
                    fontSize: 13,
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

class _MineTile extends StatelessWidget {
  const _MineTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: YingjieTheme.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: YingjieTheme.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: YingjieTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: YingjieTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: YingjieTheme.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
