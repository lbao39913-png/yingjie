import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/providers/app_providers.dart';
import 'router.dart';
import 'theme.dart';

class YingjieApp extends ConsumerStatefulWidget {
  const YingjieApp({super.key});

  @override
  ConsumerState<YingjieApp> createState() => _YingjieAppState();
}

class _YingjieAppState extends ConsumerState<YingjieApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authServiceProvider).restore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: YingjieTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
