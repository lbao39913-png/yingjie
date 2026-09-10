import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: YingjieTheme.textMuted),
            selectedIcon: Icon(Icons.home_rounded, color: YingjieTheme.accent),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined, color: YingjieTheme.textMuted),
            selectedIcon: Icon(Icons.grid_view_rounded, color: YingjieTheme.accent),
            label: '分类',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border, color: YingjieTheme.textMuted),
            selectedIcon: Icon(Icons.favorite, color: YingjieTheme.accent),
            label: '收藏',
          ),
          NavigationDestination(
            icon: Icon(Icons.history, color: YingjieTheme.textMuted),
            selectedIcon: Icon(Icons.history, color: YingjieTheme.accent),
            label: '历史',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: YingjieTheme.textMuted),
            selectedIcon: Icon(Icons.person, color: YingjieTheme.accent),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
