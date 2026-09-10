import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/constants/app_constants.dart';
import 'package:yingjie/core/errors/app_exception.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/data/api/api_provider.dart';
import 'package:yingjie/data/mock/mock_media_api.dart';
import 'package:yingjie/features/detail/detail_controller.dart';
import 'package:yingjie/models/paged_result.dart';
import 'package:yingjie/models/video.dart';
import 'package:yingjie/services/api_service.dart';
import 'package:yingjie/services/favorite_service.dart';
import 'package:yingjie/services/player_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_detail_');
    await LocalStorage.initForTest(tempDir.path);
  });

  tearDown(() async {
    await LocalStorage.resetForTest();
  });

  DetailController buildController(_SpyMediaApi api, {String id = 'sintel'}) {
    return DetailController(
      id,
      ApiService(ApiProvider(mediaApi: api)),
      FavoriteService(),
      PlayerService(),
    );
  }

  test('loads detail by id and related excludes current video', () async {
    final api = _SpyMediaApi(latency: Duration.zero);
    final controller = buildController(api);
    await pumpController();

    expect(controller.state.status, DetailStatus.ready);
    expect(controller.state.video?.id, 'sintel');
    expect(controller.state.video?.durationMinutes, 15);
    expect(controller.state.related, isNotEmpty);
    expect(
      controller.state.related.every((item) => item.id != 'sintel'),
      isTrue,
    );
    expect(
      controller.state.related.length,
      lessThanOrEqualTo(AppConstants.detailRelatedLimit),
    );
    expect(api.detailCalls, 1);
    controller.dispose();
  });

  test('empty id is not found and skips api', () async {
    final api = _SpyMediaApi(latency: Duration.zero);
    final controller = buildController(api, id: '  ');
    expect(controller.state.status, DetailStatus.error);
    expect(controller.state.error, isA<NotFoundException>());
    expect(controller.state.error?.message, '影片不存在或已下架');
    expect(api.detailCalls, 0);
    expect(api.recommendCalls, 0);
    controller.dispose();
  });

  test('missing video maps to chinese not found', () async {
    final api = _SpyMediaApi(latency: Duration.zero);
    final controller = buildController(api, id: 'missing-id');
    await pumpController();
    expect(controller.state.status, DetailStatus.error);
    expect(controller.state.error, isA<NotFoundException>());
    expect(controller.state.error?.message, '影片不存在或已下架');
    controller.dispose();
  });

  test('detail network failure keeps chinese error', () async {
    final api = _SpyMediaApi(latency: Duration.zero)..failDetail = true;
    final controller = buildController(api);
    await pumpController();
    expect(controller.state.status, DetailStatus.error);
    expect(controller.state.error, isA<NetworkException>());
    expect(controller.state.error?.message, '网络连接失败，请检查网络');
    controller.dispose();
  });

  test('related failure still shows detail', () async {
    final api = _SpyMediaApi(latency: Duration.zero)..failRecommend = true;
    final controller = buildController(api);
    await pumpController();
    expect(controller.state.status, DetailStatus.ready);
    expect(controller.state.video?.id, 'sintel');
    expect(controller.state.related, isEmpty);
    controller.dispose();
  });

  test('toggle favorite persists locally', () async {
    final api = _SpyMediaApi(latency: Duration.zero);
    final controller = buildController(api);
    await pumpController();
    expect(controller.state.favorited, isFalse);

    await controller.toggleFavorite();
    expect(controller.state.favorited, isTrue);
    expect(FavoriteService().contains('sintel'), isTrue);

    await controller.toggleFavorite();
    expect(controller.state.favorited, isFalse);
    expect(FavoriteService().contains('sintel'), isFalse);
    controller.dispose();
  });

  test('resolveLaunch passes mediaId title and playUrl', () async {
    final api = _SpyMediaApi(latency: Duration.zero);
    final controller = buildController(api);
    await pumpController();
    final launch = controller.resolveLaunch();
    expect(launch, isNotNull);
    expect(launch!.mediaId, 'sintel');
    expect(launch.title, 'Sintel');
    expect(launch.playUrl, isNotEmpty);
    expect(launch.episodeId, isNotEmpty);
    expect(launch.sourceId, isNotEmpty);
    controller.dispose();
  });
}

Future<void> pumpController() => Future<void>.delayed(Duration.zero);

class _SpyMediaApi extends MockMediaApi {
  _SpyMediaApi({super.latency});

  int detailCalls = 0;
  int recommendCalls = 0;
  bool failDetail = false;
  bool failRecommend = false;

  @override
  Future<Video> fetchDetail(String id) {
    detailCalls++;
    if (failDetail) {
      throw const NetworkException();
    }
    return super.fetchDetail(id);
  }

  @override
  Future<PagedResult<Video>> fetchRecommend({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) {
    recommendCalls++;
    if (failRecommend) {
      throw const NetworkException();
    }
    return super.fetchRecommend(page: page, pageSize: pageSize);
  }
}
