import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/user.dart';
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
          _UserCard(state: state),
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
  const _UserCard({required this.state});

  final MineState state;

  @override
  Widget build(BuildContext context) {
    final auth = state.auth;
    final loggedIn = auth.isLoggedIn;
    final restoring =
        auth.status == AuthStatus.unknown || auth.status == AuthStatus.loading;
    return Material(
      color: YingjieTheme.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: loggedIn ? null : const Key('mine-login'),
        onTap: loggedIn || restoring
            ? null
            : () => context.push('/login'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: YingjieTheme.surface,
                child: Icon(
                  Icons.person_rounded,
                  color: YingjieTheme.accent,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restoring
                          ? '正在恢复登录...'
                          : loggedIn
                              ? (auth.user?.nickname ??
                                  auth.user?.username ??
                                  '影界用户')
                              : '未登录',
                      style: const TextStyle(
                        color: YingjieTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (loggedIn)
                      Text(
                        auth.user?.username ?? '',
                        style: const TextStyle(
                          color: YingjieTheme.textMuted,
                          fontSize: 13,
                        ),
                      )
                    else if (!restoring)
                      const Text(
                        '登录 / 注册',
                        style: TextStyle(
                          color: YingjieTheme.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (loggedIn)
                TextButton(
                  key: const Key('mine-logout'),
                  onPressed: () => _confirmLogout(context),
                  child: const Text('退出登录'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定退出当前账号吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              key: const Key('logout-confirm'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('退出登录'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      final container = ProviderScope.containerOf(context);
      await container.read(mineControllerProvider.notifier).logout();
    }
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
