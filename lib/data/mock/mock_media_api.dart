import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../models/category.dart';
import '../../models/home_feed.dart';
import '../../models/paged_result.dart';
import '../../models/video.dart';
import '../api/media_api.dart';
import 'mock_catalog.dart';

class MockMediaApi implements MediaApi {
  MockMediaApi({this.latency = const Duration(milliseconds: 280)});

  final Duration latency;

  @override
  Future<HomeFeed> fetchHome() async {
    await _wait();
    return HomeFeed(
      banners: MockCatalog.videos.take(3).toList(growable: false),
      hot: MockCatalog.videos.take(6).toList(growable: false),
      latest: MockCatalog.videos.reversed.take(6).toList(growable: false),
      movies: _byCategory('movie'),
      series: _byCategory('series'),
      anime: _byCategory('anime'),
      variety: _byCategory('variety'),
    );
  }

  @override
  Future<PagedResult<Video>> fetchRecommend({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) {
    return _page(MockCatalog.videos, page: page, pageSize: pageSize);
  }

  @override
  Future<PagedResult<Video>> fetchMovies({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) {
    return _page(_byCategory('movie'), page: page, pageSize: pageSize);
  }

  @override
  Future<PagedResult<Video>> fetchSeries({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) {
    return _page(_byCategory('series'), page: page, pageSize: pageSize);
  }

  @override
  Future<PagedResult<Video>> fetchAnime({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) {
    return _page(_byCategory('anime'), page: page, pageSize: pageSize);
  }

  @override
  Future<PagedResult<Video>> fetchVariety({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) {
    return _page(_byCategory('variety'), page: page, pageSize: pageSize);
  }

  @override
  Future<PagedResult<Video>> search(
    String keyword, {
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) {
    final q = keyword.trim().toLowerCase();
    if (q.isEmpty) {
      return _page(const [], page: page, pageSize: pageSize);
    }
    final matched = MockCatalog.videos.where((video) {
      return video.title.toLowerCase().contains(q) ||
          video.subtitle.toLowerCase().contains(q) ||
          video.genres.any((genre) => genre.toLowerCase().contains(q));
    }).toList(growable: false);
    return _page(matched, page: page, pageSize: pageSize);
  }

  @override
  Future<List<String>> suggest(String keyword) async {
    await _wait();
    final q = keyword.trim().toLowerCase();
    if (q.isEmpty) {
      return const [];
    }
    final seen = <String>{};
    final items = <String>[];
    for (final video in MockCatalog.videos) {
      final candidates = <String>[video.title, ...video.genres];
      for (final token in candidates) {
        if (token.toLowerCase().contains(q) && seen.add(token)) {
          items.add(token);
          if (items.length >= 8) {
            return items;
          }
        }
      }
    }
    return items;
  }

  @override
  Future<Video> fetchDetail(String id) async {
    await _wait();
    for (final video in MockCatalog.videos) {
      if (video.id == id) {
        return video;
      }
    }
    throw const NotFoundException();
  }

  @override
  Future<List<Category>> fetchCategories() async {
    await _wait();
    return MockCatalog.categories;
  }

  List<Video> _byCategory(String category) {
    return MockCatalog.videos
        .where((video) => video.category == category)
        .toList(growable: false);
  }

  Future<PagedResult<Video>> _page(
    List<Video> source, {
    required int page,
    required int pageSize,
  }) async {
    await _wait();
    final start = (page - 1) * pageSize;
    if (start >= source.length) {
      return PagedResult<Video>(
        items: const [],
        page: page,
        pageSize: pageSize,
        total: source.length,
      );
    }
    final end = (start + pageSize).clamp(0, source.length);
    return PagedResult<Video>(
      items: source.sublist(start, end),
      page: page,
      pageSize: pageSize,
      total: source.length,
    );
  }

  Future<void> _wait() {
    if (latency == Duration.zero) {
      return Future<void>.value();
    }
    return Future<void>.delayed(latency);
  }

}
