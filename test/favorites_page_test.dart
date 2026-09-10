import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yingjie/core/errors/app_exception.dart';
import 'package:yingjie/core/providers/app_providers.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/data/api/api_provider.dart';
import 'package:yingjie/data/mock/mock_catalog.dart';
import 'package:yingjie/data/mock/mock_media_api.dart';
import 'package:yingjie/features/favorites/favorites_page.dart';
import 'package:yingjie/models/video.dart';
import 'package:yingjie/services/api_service.dart';
import 'package:yingjie/services/favorite_service.dart';

class _FlakyFavorites extends FavoriteService {
  bool fail = true;

  @override
  List<Video> all() {
    if (fail) {
      throw const CacheException();
    }
    return super.all();
  }
}

Video _card(Video video) {
  return Video(
    id: video.id,
    title: video.title,
    cover: '',
    year: video.year,
    genres: video.genres,
    rating: video.rating,
  );
}

void main() {
  late Directory tempDir;
  late FavoriteService favorites;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_fav_page_');
    await LocalStorage.initForTest(tempDir.path);
    favorites = FavoriteService();
  });

  tearDown(() async {
    await LocalStorage.resetForTest();
  });

  Future<void> pumpFavorites(
    WidgetTester tester, {
    FavoriteService? service,
  }) async {
    final router = GoRouter(
      initialLocation: '/favorites',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('首页')),
        ),
        GoRoute(
          path: '/favorites',
          builder: (context, state) => const FavoritesPage(),
        ),
        GoRoute(
          path: '/detail/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return Scaffold(body: Text('详情:$id'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(
            ApiService(
              ApiProvider(mediaApi: MockMediaApi(latency: Duration.zero)),
            ),
          ),
          favoriteServiceProvider.overrideWithValue(service ?? favorites),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> save(WidgetTester tester, Video video) async {
    await tester.runAsync(() async {
      await favorites.add(video);
    });
  }

  testWidgets('empty favorites show chinese empty state', (tester) async {
    await pumpFavorites(tester);
    expect(find.text('我的收藏'), findsOneWidget);
    expect(find.text('还没有收藏影片'), findsOneWidget);
    expect(find.text('去发现影片'), findsOneWidget);
  });

  testWidgets('go discover opens home', (tester) async {
    await pumpFavorites(tester);
    await tester.tap(find.byKey(const Key('favorites-go-home')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('首页'), findsOneWidget);
  });

  testWidgets('stored favorites render title year genre and rating', (tester) async {
    await save(
      tester,
      const Video(
        id: 'sintel',
        title: 'Sintel',
        cover: '',
        year: 2010,
        genres: ['动画', '奇幻'],
        rating: 7.5,
      ),
    );
    await pumpFavorites(tester);
    expect(find.text('Sintel'), findsOneWidget);
    expect(find.textContaining('2010'), findsOneWidget);
    expect(find.textContaining('动画'), findsOneWidget);
    expect(find.textContaining('7.5'), findsOneWidget);
    expect(find.byKey(const Key('favorite-card-sintel')), findsOneWidget);
  });

  testWidgets('multiple favorites all appear', (tester) async {
    await save(tester, _card(MockCatalog.videos[0]));
    await save(tester, _card(MockCatalog.videos[1]));
    await save(tester, _card(MockCatalog.videos[2]));
    await pumpFavorites(tester);
    expect(find.byKey(Key('favorite-card-${MockCatalog.videos[0].id}')), findsOneWidget);
    expect(find.byKey(Key('favorite-card-${MockCatalog.videos[1].id}')), findsOneWidget);
    expect(find.byKey(Key('favorite-card-${MockCatalog.videos[2].id}')), findsOneWidget);
  });

  testWidgets('tap favorite opens matching detail id', (tester) async {
    await save(
      tester,
      _card(MockCatalog.videos.firstWhere((item) => item.id == 'sintel')),
    );
    await pumpFavorites(tester);
    await tester.tap(find.byKey(const Key('favorite-card-sintel')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('详情:sintel'), findsOneWidget);
  });

  testWidgets('long press removes favorite and updates ui', (tester) async {
    await save(
      tester,
      _card(MockCatalog.videos.firstWhere((item) => item.id == 'sintel')),
    );
    await pumpFavorites(tester);
    final inkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const Key('favorite-card-sintel')),
        matching: find.byType(InkWell),
      ),
    );
    expect(inkWell.onLongPress, isNotNull);
    await tester.runAsync(() async {
      inkWell.onLongPress!.call();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('还没有收藏影片'), findsOneWidget);
    expect(find.text('已取消收藏'), findsOneWidget);
    expect(favorites.contains('sintel'), isFalse);
  });

  testWidgets('broken cover shows fallback instead of crashing', (tester) async {
    await save(
      tester,
      const Video(id: 'broken', title: 'Broken Cover', cover: ''),
    );
    await pumpFavorites(tester);
    expect(find.text('Broken Cover'), findsOneWidget);
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
  });

  testWidgets('load failure shows chinese error and retry', (tester) async {
    final service = _FlakyFavorites();
    await pumpFavorites(tester, service: service);
    expect(find.text('本地数据读取失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    await tester.runAsync(() async {
      await service.add(_card(MockCatalog.videos.first));
    });
    service.fail = false;
    await tester.tap(find.text('重试'));
    await tester.pump();
    expect(find.text(MockCatalog.videos.first.title), findsOneWidget);
  });

  testWidgets('detail favorite then unfavorite syncs favorites page', (tester) async {
    await pumpFavorites(tester);
    expect(find.text('还没有收藏影片'), findsOneWidget);

    await tester.runAsync(() async {
      await favorites.toggle(
        _card(MockCatalog.videos.firstWhere((item) => item.id == 'sintel')),
      );
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const Key('favorite-card-sintel')), findsOneWidget);

    await tester.runAsync(() async {
      await favorites.toggle(
        _card(MockCatalog.videos.firstWhere((item) => item.id == 'sintel')),
      );
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('还没有收藏影片'), findsOneWidget);
    expect(find.byKey(const Key('favorite-card-sintel')), findsNothing);
  });
}
