import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/providers/app_providers.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/data/api/api_provider.dart';
import 'package:yingjie/data/mock/mock_media_api.dart';
import 'package:yingjie/features/detail/detail_page.dart';
import 'package:yingjie/services/api_service.dart';
import 'package:yingjie/services/favorite_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_detail_page_');
    await LocalStorage.initForTest(tempDir.path);
  });

  tearDown(() async {
    await LocalStorage.resetForTest();
  });

  Future<void> pumpDetail(WidgetTester tester, String videoId) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(
            ApiService(
              ApiProvider(mediaApi: MockMediaApi(latency: Duration.zero)),
            ),
          ),
          favoriteServiceProvider.overrideWithValue(FavoriteService()),
        ],
        child: MaterialApp(home: DetailPage(videoId: videoId)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('detail page shows title play and related', (tester) async {
    await pumpDetail(tester, 'sintel');
    expect(find.text('Sintel'), findsWidgets);
    expect(find.text('立即播放'), findsOneWidget);
    expect(find.text('简介'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pump();
    expect(find.text('相关推荐'), findsOneWidget);
  });

  testWidgets('missing id shows chinese not found and retry', (tester) async {
    await pumpDetail(tester, 'missing-id');
    expect(find.text('影片不存在或已下架'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('series detail shows episode picker instead of play now', (tester) async {
    await pumpDetail(tester, 'sample-series-a');
    expect(find.text('示例剧集 A'), findsWidgets);
    expect(find.text('选集'), findsOneWidget);
    expect(find.text('第1集'), findsOneWidget);
    expect(find.text('第2集'), findsOneWidget);
    expect(find.text('第3集'), findsOneWidget);
    expect(find.text('立即播放'), findsNothing);
    expect(find.byKey(const Key('episode-sample-series-a-1')), findsOneWidget);
  });
}
