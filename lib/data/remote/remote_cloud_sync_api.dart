import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';
import '../../models/json_values.dart';
import '../../models/user_cloud_data.dart';
import '../api/cloud_sync_api.dart';

class RemoteCloudSyncApi implements CloudSyncApi {
  RemoteCloudSyncApi(this._dio);

  final Dio _dio;

  @override
  Future<UserCloudData> pull({required String accessToken}) async {
    final data = await _send(
      method: 'GET',
      accessToken: accessToken,
    );
    return UserCloudData.fromJson(data);
  }

  @override
  Future<void> push({
    required String accessToken,
    required UserCloudData data,
  }) async {
    await _send(
      method: 'PUT',
      accessToken: accessToken,
      body: data.toJson(),
    );
  }

  Future<Map<String, dynamic>> _send({
    required String method,
    required String accessToken,
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        ApiConfig.syncDataPath,
        data: body,
        options: Options(
          method: method,
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      return JsonValues.map(response.data) ?? <String, dynamic>{};
    } catch (error) {
      final mapped = ErrorMapper.map(error);
      if (mapped is NetworkException || mapped is AuthException) {
        throw mapped;
      }
      throw const ServerException(message: '服务器异常，请稍后重试');
    }
  }
}
