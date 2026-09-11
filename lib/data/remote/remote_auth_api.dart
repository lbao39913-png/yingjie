import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';
import '../../models/json_values.dart';
import '../../models/user.dart';
import '../api/auth_api.dart';

class RemoteAuthApi implements AuthApi {
  RemoteAuthApi(this._dio);

  final Dio _dio;

  @override
  Future<AuthSession> register({
    required String account,
    required String password,
  }) {
    return _session(
      ApiConfig.authRegisterPath,
      data: {'account': account.trim(), 'password': password},
    );
  }

  @override
  Future<AuthSession> login({
    required String account,
    required String password,
  }) {
    return _session(
      ApiConfig.authLoginPath,
      data: {'account': account.trim(), 'password': password},
    );
  }

  @override
  Future<void> logout({required String accessToken}) async {
    await _send(
      ApiConfig.authLogoutPath,
      data: const {},
      accessToken: accessToken,
    );
  }

  @override
  Future<User> getCurrentUser({required String accessToken}) async {
    final data = await _send(
      ApiConfig.authMePath,
      method: 'GET',
      accessToken: accessToken,
    );
    return User.fromJson(_userMap(data));
  }

  @override
  Future<AuthSession> refreshToken({required String refreshToken}) {
    return _session(
      ApiConfig.authRefreshPath,
      data: {'refreshToken': refreshToken},
    );
  }

  Future<AuthSession> _session(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    final payload = await _send(path, data: data);
    final user = User.fromJson(_userMap(payload));
    final access = JsonValues.string(payload['accessToken']);
    final refresh = JsonValues.string(payload['refreshToken']);
    if (user.id.isEmpty || access.isEmpty || refresh.isEmpty) {
      throw const ServerException(message: '服务器异常，请稍后重试');
    }
    return AuthSession(
      user: user,
      accessToken: access,
      refreshToken: refresh,
    );
  }

  Map<String, dynamic> _userMap(Map<String, dynamic> payload) {
    return JsonValues.map(payload['user']) ?? payload;
  }

  Future<Map<String, dynamic>> _send(
    String path, {
    String method = 'POST',
    Map<String, dynamic>? data,
    String? accessToken,
  }) async {
    try {
      final options = Options(
        method: method,
        headers: accessToken == null || accessToken.isEmpty
            ? null
            : {'Authorization': 'Bearer $accessToken'},
      );
      final response = await _dio.request<dynamic>(
        path,
        data: data,
        options: options,
      );
      final mapped = JsonValues.map(response.data);
      return mapped ?? <String, dynamic>{};
    } catch (error) {
      throw _mapAuthError(error);
    }
  }

  AppException _mapAuthError(Object error) {
    final mapped = ErrorMapper.map(error);
    if (mapped is AuthException) {
      return mapped;
    }
    if (error is DioException && error.response?.statusCode == 400) {
      return const AuthException(message: '账号或密码错误');
    }
    if (mapped is NetworkException) {
      return mapped;
    }
    if (mapped is ServerException) {
      return const ServerException(message: '服务器异常，请稍后重试');
    }
    return mapped;
  }
}
