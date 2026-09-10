import '../../core/constants/app_constants.dart';
import '../../models/category.dart';
import '../../models/home_feed.dart';
import '../../models/paged_result.dart';
import '../../models/video.dart';
import 'movie_api_adapter.dart';
import 'series_api_adapter.dart';

abstract class MediaApi implements MovieApiAdapter, SeriesApiAdapter {
  Future<HomeFeed> fetchHome();

  Future<PagedResult<Video>> fetchRecommend({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  });

  Future<PagedResult<Video>> fetchAnime({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  });

  Future<PagedResult<Video>> fetchVariety({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  });

  Future<PagedResult<Video>> search(
    String keyword, {
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  });

  Future<List<String>> suggest(String keyword);

  Future<Video> fetchDetail(String id);

  Future<List<Category>> fetchCategories();
}
