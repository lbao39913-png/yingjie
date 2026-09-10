import 'package:dio/dio.dart';

import 'app_exception.dart';

class ErrorMapper {
  ErrorMapper._();

  static AppException map(Object error) {
    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      return _mapDio(error);
    }

    return UnknownException(cause: error);
  }

  static AppException _mapDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkException(cause: error);
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        if (status == 404) {
          return NotFoundException(cause: error);
        }
        return ServerException(cause: error);
      case DioExceptionType.cancel:
        return const UnknownException(message: '请求已取消');
      case DioExceptionType.badCertificate:
        return NetworkException(cause: error);
      case DioExceptionType.unknown:
        return UnknownException(cause: error);
      case DioExceptionType.transformTimeout:
        return NetworkException(cause: error);
    }
  }
}
