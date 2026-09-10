import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../config/app_config.dart';

class DioClient {
  DioClient({Dio? dio}) : _dio = dio ?? _create();

  final Dio _dio;

  Dio get raw => _dio;

  static Dio _create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        requestBody: AppConfig.env.isDevelopment,
        responseBody: AppConfig.env.isDevelopment,
      ),
    );

    return dio;
  }
}
