sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException({
    String message = '网络连接失败，请检查网络',
    Object? cause,
  }) : super(message, cause: cause);
}

class ServerException extends AppException {
  const ServerException({
    String message = '服务器暂时不可用',
    Object? cause,
  }) : super(message, cause: cause);
}

class NotFoundException extends AppException {
  const NotFoundException({
    String message = '影片不存在或已下架',
    Object? cause,
  }) : super(message, cause: cause);
}

class PlaybackException extends AppException {
  const PlaybackException({
    String message = '当前线路无法播放，请尝试其他线路',
    Object? cause,
  }) : super(message, cause: cause);
}

class CacheException extends AppException {
  const CacheException({
    String message = '本地数据读取失败',
    Object? cause,
  }) : super(message, cause: cause);
}

class AuthException extends AppException {
  const AuthException({
    String message = '登录失败，请稍后重试',
    Object? cause,
  }) : super(message, cause: cause);
}

class UnknownException extends AppException {
  const UnknownException({
    String message = '发生未知错误，请稍后重试',
    Object? cause,
  }) : super(message, cause: cause);
}
