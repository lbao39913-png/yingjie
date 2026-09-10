import 'app_config.dart';

/// All HTTP endpoints live here. Change [baseUrl] to switch servers.
class ApiConfig {
  ApiConfig._();

  static const String _devBaseUrl = 'https://api.dev.yingjie.local';
  static const String _prodBaseUrl = 'https://api.yingjie.local';

  static String get baseUrl {
    return switch (AppConfig.env) {
      AppEnv.development => _devBaseUrl,
      AppEnv.production => _prodBaseUrl,
    };
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 15);

  static const String homePath = '/v1/home';
  static const String moviesPath = '/v1/movies';
  static const String seriesPath = '/v1/series';
  static const String animePath = '/v1/anime';
  static const String varietyPath = '/v1/variety';
  static const String searchPath = '/v1/search';
  static const String suggestPath = '/v1/search/suggest';
  static const String categoriesPath = '/v1/categories';
  static const String bannersPath = '/v1/banners';
  static const String recommendPath = '/v1/recommend';

  static String videoDetailPath(String id) => '/v1/videos/$id';
}

/// Version check is independent from the media catalog API.
class UpdateConfig {
  UpdateConfig._();

  static String get baseUrl => ApiConfig.baseUrl;

  static const String versionPath = '/v1/app/version';
}
