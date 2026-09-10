import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/providers/app_providers.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/data/api/api_provider.dart';
import 'package:yingjie/data/mock/mock_media_api.dart';
import 'package:yingjie/features/search/search_history_page.dart';
import 'package:yingjie/services/search_service.dart';

void main() {
  late Directory tempDir;
  late SearchService search;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_search_hist_page_');
    await LocalStorage.initForTest(tempDir.path);
    search = SearchService(
      ApiProvider(mediaApi: MockMediaApi(latency: Duration.zero)),
    );
  });

  tearDown(() async {
    await LocalStorage.resetForTest();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchServiceProvider.overrideWithValue(search),
        ],
        child: const MaterialApp(home: SearchHistoryPage()),
      ),
    );
    await tester.pump();
  }

  testWidgets('empty search history shows chinese empty state', (tester) async {
    await pumpPage(tester);
    expect(find.text('搜索记录'), findsOneWidget);
    expect(find.text('还没有搜索记录'), findsOneWidget);
  });

  testWidgets('stored keywords can be removed one by one', (tester) async {
    await tester.runAsync(() async {
      await search.addHistory('Sintel');
      await search.addHistory('Bunny');
    });
    await pumpPage(tester);
    expect(find.text('Bunny'), findsOneWidget);
    expect(find.text('Sintel'), findsOneWidget);
    await tester.runAsync(() async {
      tester
          .widget<IconButton>(
            find.byKey(const Key('search-history-remove-Sintel')),
          )
          .onPressed!
          .call();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('Sintel'), findsNothing);
    expect(find.text('Bunny'), findsOneWidget);
  });

  testWidgets('clear confirm wipes all keywords', (tester) async {
    await tester.runAsync(() async {
      await search.addHistory('Sintel');
    });
    await pumpPage(tester);
    await tester.runAsync(() async {
      tester
          .widget<TextButton>(find.byKey(const Key('search-history-clear')))
          .onPressed!
          .call();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
    await tester.runAsync(() async {
      tester
          .widget<TextButton>(
            find.byKey(const Key('search-history-clear-confirm')),
          )
          .onPressed!
          .call();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('还没有搜索记录'), findsOneWidget);
    expect(search.history(), isEmpty);
  });
}
