import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/errors/app_exception.dart';
import 'package:yingjie/data/mock/mock_media_api.dart';
import 'package:yingjie/data/mock/mock_catalog.dart';
import 'package:yingjie/models/video.dart';

void main() {
  final api = MockMediaApi(latency: Duration.zero);

  test('home feed returns legal sample catalog', () async {
    final feed = await api.fetchHome();
    expect(feed.isEmpty, isFalse);
    expect(feed.hot, isNotEmpty);
    expect(feed.banners, isNotEmpty);
  });

  test('recommend paginates sample catalog', () async {
    final page1 = await api.fetchRecommend(page: 1, pageSize: 6);
    expect(page1.items, hasLength(6));
    expect(page1.hasMore, isTrue);

    final last = await api.fetchRecommend(page: 3, pageSize: 6);
    expect(last.items, isNotEmpty);
    expect(last.hasMore, isFalse);
  });

  test('search matches title', () async {
    final result = await api.search('Sintel');
    expect(result.total, 1);
    expect(result.items.first.id, 'sintel');
  });

  test('empty keyword returns no search results', () async {
    final result = await api.search('   ');
    expect(result.items, isEmpty);
    expect(result.total, 0);
  });

  test('suggest returns title matches', () async {
    final items = await api.suggest('Sin');
    expect(items, contains('Sintel'));
  });

  test('missing video throws NotFoundException', () async {
    expect(
      () => api.fetchDetail('missing-id'),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('detail includes backdrop duration and playUrl', () async {
    final video = await api.fetchDetail('sintel');
    expect(video.id, 'sintel');
    expect(video.backdrop, isNotEmpty);
    expect(video.durationMinutes, 15);
    expect(video.heroImage, isNotEmpty);
    expect(video.playUrl, isNotEmpty);
  });

  test('catalog keeps 13 movies and adds two multi-episode series', () {
    expect(MockCatalog.videos, hasLength(15));
    final movies = MockCatalog.videos.where((item) => item.isMovie).toList();
    final series = MockCatalog.videos.where((item) => item.isTv).toList();
    expect(movies, hasLength(13));
    expect(series, hasLength(2));
    expect(series.every((item) => item.type == MediaType.tv), isTrue);
    expect(series.every((item) => item.episodeCount >= 3), isTrue);
    for (final video in MockCatalog.videos) {
      expect(video.playUrl, isNotEmpty);
      expect(video.playUrl, startsWith('https://'));
    }
  });

  test('series detail returns ordered episodes with unique urls', () async {
    final video = await api.fetchDetail('sample-series-a');
    expect(video.isTv, isTrue);
    expect(video.episodes, hasLength(3));
    expect(video.episodes.map((item) => item.name).toList(), [
      '第1集',
      '第2集',
      '第3集',
    ]);
    expect(
      video.episodes.map((item) => item.resolvedUrl).toSet(),
      hasLength(3),
    );
  });
}
