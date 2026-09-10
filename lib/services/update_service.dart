import 'package:dio/dio.dart';

import '../core/config/app_config.dart';
import '../core/config/api_config.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/error_mapper.dart';
import '../core/network/api_result.dart';
import '../models/app_version.dart';

class UpdateService {
  UpdateService(this._dio);

  final Dio _dio;

  Future<ApiResult<AppVersion>> check() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        UpdateConfig.versionPath,
        options: Options(
          extra: const {'independent': true},
        ),
      );
      final data = response.data;
      if (data == null) {
        return const ApiFailure(
          ServerException(),
        );
      }
      return ApiSuccess(AppVersion.fromJson(data));
    } catch (error) {
      return ApiFailure(ErrorMapper.map(error));
    }
  }

  bool shouldPrompt(AppVersion remote) {
    return remote.versionCode > AppConfig.versionCode;
  }
}
