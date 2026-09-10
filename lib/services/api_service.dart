import '../core/errors/error_mapper.dart';
import '../core/network/api_result.dart';
import '../data/api/api_provider.dart';
import '../models/category.dart';
import '../models/home_feed.dart';
import '../models/paged_result.dart';
import '../models/video.dart';

class ApiService {
  ApiService(this._api);

  final ApiProvider _api;

  Future<ApiResult<HomeFeed>> fetchHome() {
    return _guard(() => _api.mediaApi.fetchHome());
  }

  Future<ApiResult<PagedResult<Video>>> fetchRecommend({
    int page = 1,
    int pageSize = 12,
  }) {
    return _guard(
      () => _api.mediaApi.fetchRecommend(page: page, pageSize: pageSize),
    );
  }

  Future<ApiResult<PagedResult<Video>>> fetchMovies({
    int page = 1,
    int pageSize = 12,
  }) {
    return _guard(
      () => _api.movies.fetchMovies(page: page, pageSize: pageSize),
    );
  }

  Future<ApiResult<PagedResult<Video>>> fetchSeries({
    int page = 1,
    int pageSize = 12,
  }) {
    return _guard(
      () => _api.series.fetchSeries(page: page, pageSize: pageSize),
    );
  }

  Future<ApiResult<Video>> fetchDetail(String id) {
    return _guard(() => _api.mediaApi.fetchDetail(id));
  }

  Future<ApiResult<List<Category>>> fetchCategories() {
    return _guard(() => _api.mediaApi.fetchCategories());
  }

  Future<ApiResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return ApiSuccess(await action());
    } catch (error) {
      return ApiFailure(ErrorMapper.map(error));
    }
  }
}
