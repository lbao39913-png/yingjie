import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';
import '../../models/category.dart';
import '../../models/home_feed.dart';
import '../../models/json_values.dart';
import '../../models/paged_result.dart';
import '../../models/video.dart';
import '../api/media_api.dart';

class RemoteMediaApi implements MediaApi {
  RemoteMediaApi(this._dio);

  final Dio _dio;

  @override
  Future<HomeFeed> fetchHome() async {
    final data = await _getJson(ApiConfig.homePath);
    return HomeFeed(
      banners: _videos(data['banners']),
      hot: _videos(data['hot']),
      latest: _videos(data['latest']),
      movies: _videos(data['movies']),
      series: _videos(data['series']),
      anime: _videos(data['anime']),
      variety: _videos(data['variety']),
    );
  }

  @override
  Future<PagedResult<Video>> fetchMovies({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) {
    return _paged(ApiConfig.moviesPath, page: page, pageSize: pageSize);
  }

  @override
  Future<PagedResult<Video>> fetchSeries({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) {
    return _paged(ApiConfig.seriesPath, page: page, pageSize: pageSize);
  }

  @override
  Future<PagedResult<Video>> fetchAnime({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) {
    return _paged(ApiConfig.animePath, page: page, pageSize: pageSize);
  }

  @override
  Future<PagedResult<Video>> fetchVariety({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) {
    return _paged(ApiConfig.varietyPath, page: page, pageSize: pageSize);
  }

  @override
  Future<PagedResult<Video>> fetchRecommend({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) {
    return _paged(ApiConfig.recommendPath, page: page, pageSize: pageSize);
  }

  @override
  Future<PagedResult<Video>> search(
    String keyword, {
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) {
    return _paged(
      ApiConfig.searchPath,
      page: page,
      pageSize: pageSize,
      query: {'q': keyword},
    );
  }

  @override
  Future<List<String>> suggest(String keyword) async {
    final data = await _getJson(
      ApiConfig.suggestPath,
      query: {'q': keyword},
    );
    final items = data['items'] as List<dynamic>? ?? const [];
    return items.map((item) => item.toString()).toList(growable: false);
  }

  @override
  Future<Video> fetchDetail(String id) async {
    final data = await _getJson(ApiConfig.videoDetailPath(id));
    if (data.isEmpty) {
      throw const NotFoundException();
    }
    return Video.fromJson(data);
  }

  @override
  Future<List<Category>> fetchCategories() async {
    final data = await _getJson(ApiConfig.categoriesPath);
    final items = data['items'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(Category.fromJson)
        .toList(growable: false);
  }

  Future<PagedResult<Video>> _paged(
    String path, {
    required int page,
    required int pageSize,
    Map<String, dynamic>? query,
  }) async {
    final data = await _getJson(
      path,
      query: {
        'page': page,
        'pageSize': pageSize,
        ...?query,
      },
    );
    return PagedResult<Video>(
      items: _videos(data['items']),
      page: JsonValues.integer(data['page']) ?? page,
      pageSize: JsonValues.integer(data['pageSize']) ?? pageSize,
      total: JsonValues.integer(data['total']) ?? 0,
    );
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
      return response.data ?? const {};
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  List<Video> _videos(Object? raw) {
    return JsonValues.maps(raw).map(Video.fromJson).toList(growable: false);
  }
}
