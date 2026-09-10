import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import 'router.dart';
import 'theme.dart';

class YingjieApp extends StatelessWidget {
  const YingjieApp({super.key});

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
