import 'package:dio/dio.dart';

import '../mock/mock_media_api.dart';
import '../remote/remote_media_api.dart';
import 'media_api.dart';
import 'movie_api_adapter.dart';
import 'series_api_adapter.dart';

/// Single entry for media APIs. Swap adapters without touching UI.
class ApiProvider {
  ApiProvider({required this.mediaApi});

  final MediaApi mediaApi;

  MovieApiAdapter get movies => mediaApi;

  SeriesApiAdapter get series => mediaApi;

  factory ApiProvider.fromConfig({
    required bool useMock,
    required Dio dio,
  }) {
    if (useMock) {
      return ApiProvider(mediaApi: MockMediaApi());
    }
    return ApiProvider(mediaApi: RemoteMediaApi(dio));
  }
}
