import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/config/app_config.dart';
import 'package:yingjie/features/about/about_page.dart';

void main() {
  testWidgets('about page shows version and privacy copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AboutPage()),
    );
    expect(find.text('关于影界'), findsOneWidget);
    expect(find.text(AppConfig.appName), findsOneWidget);
    expect(
      find.text('版本 ${AppConfig.versionName} (${AppConfig.versionCode})'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('about-privacy')), findsOneWidget);
    expect(find.textContaining('合法授权'), findsOneWidget);
    expect(find.textContaining('未授权片源'), findsOneWidget);
  });
}
