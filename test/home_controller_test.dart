import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/constants/app_constants.dart';
import 'package:yingjie/core/errors/app_exception.dart';
import 'package:yingjie/data/api/api_provider.dart';
import 'package:yingjie/data/api/media_api.dart';
import 'package:yingjie/data/mock/mock_media_api.dart';
import 'package:yingjie/features/home/home_controller.dart';
import 'package:yingjie/models/category.dart';
import 'package:yingjie/models/home_feed.dart';
import 'package:yingjie/models/paged_result.dart';
import 'package:yingjie/models/video.dart';
import 'package:yingjie/services/api_service.dart';

void main() {
  test('loads home feed and first recommend page', () async {
    final controller = HomeController(
      ApiService(
        ApiProvider(mediaApi: MockMediaApi(latency: Duration.zero)),
      ),
    );

    await pumpController();

    expect(controller.state.status, HomeStatus.ready);
    expect(controller.state.feed?.banners, isNotEmpty);
    expect(controller.state.recommend, hasLength(AppConstants.homeRecommendPageSize));
    expect(controller.state.hasMore, isTrue);
    controller.dispose();
  });

  test('loadMore appends the next recommend page', () async {
    final controller = HomeController(
      ApiService(
        ApiProvider(mediaApi: MockMediaApi(latency: Duration.zero)),
      ),
    );
    await pumpController();

    final firstCount = controller.state.recommend.length;
    await controller.loadMore();

    expect(controller.state.recommend.length, greaterThan(firstCount));
    expect(controller.state.page, 2);
    controller.dispose();
  });

  test('maps api failure to chinese error state', () async {
    final controller = HomeController(
      ApiService(ApiProvider(mediaApi: _FailingMediaApi())),
    );
    await pumpController();

    expect(controller.state.status, HomeStatus.error);
    expect(controller.state.error, isA<NetworkException>());
    expect(controller.state.error?.message, '网络连接失败，请检查网络');
    controller.dispose();
  });
}

Future<void> pumpController() => Future<void>.delayed(Duration.zero);

class _FailingMediaApi implements MediaApi {
  Never _fail() => throw const NetworkException();

  @override
  Future<HomeFeed> fetchHome() async => _fail();

  @override
  Future<PagedResult<Video>> fetchRecommend({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async =>
      _fail();

  @override
  Future<PagedResult<Video>> fetchMovies({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async =>
      _fail();

  @override
  Future<PagedResult<Video>> fetchSeries({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async =>
      _fail();

  @override
  Future<PagedResult<Video>> fetchAnime({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async =>
      _fail();

  @override
  Future<PagedResult<Video>> fetchVariety({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async =>
      _fail();

  @override
  Future<PagedResult<Video>> search(
    String keyword, {
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async =>
      _fail();

  @override
  Future<List<String>> suggest(String keyword) async => _fail();

  @override
  Future<Video> fetchDetail(String id) async => _fail();

  @override
  Future<List<Category>> fetchCategories() async => _fail();
}
