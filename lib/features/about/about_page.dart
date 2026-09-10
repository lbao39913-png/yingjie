import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于影界')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: YingjieTheme.card,
              child: Icon(
                Icons.movie_filter_rounded,
                color: YingjieTheme.accent,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              AppConfig.appName,
              style: TextStyle(
                color: YingjieTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              '版本 ${AppConfig.versionName} (${AppConfig.versionCode})',
              key: Key('about-version'),
              style: TextStyle(
                color: YingjieTheme.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: YingjieTheme.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '影界仅播放合法授权内容，不提供未授权片源。收藏、历史、搜索记录和播放设置保存在本机，无需登录。',
              key: Key('about-privacy'),
              style: TextStyle(
                color: YingjieTheme.textPrimary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
