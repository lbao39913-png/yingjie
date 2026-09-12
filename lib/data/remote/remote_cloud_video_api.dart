import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';
import '../../models/cloud_video.dart';
import '../../models/json_values.dart';
import '../api/cloud_video_api.dart';

class RemoteCloudVideoApi implements CloudVideoApi {
  RemoteCloudVideoApi(this._dio);

  final Dio _dio;

  @override
  Future<List<CloudVideo>> list({
    required String accessToken,
    bool includePrivate = false,
  }) async {
    final data = await _send(
      ApiConfig.videosPath,
      method: 'GET',
      accessToken: accessToken,
      query: {'privacy': includePrivate ? 'all' : 'public'},
    );
    final items = JsonValues.maps(data['items'] ?? data['videos'] ?? data['data']);
    return items.map(CloudVideo.fromJson).toList(growable: false);
  }

  @override
  Future<CloudVideo> create({
    required String accessToken,
    required String title,
    required int sizeBytes,
    bool isPrivate = false,
  }) async {
    final data = await _send(
      ApiConfig.videosPath,
      accessToken: accessToken,
      body: {
        'title': title.trim(),
        'sizeBytes': sizeBytes,
        'isPrivate': isPrivate,
      },
    );
    return _video(data);
  }

  @override
  Future<CloudVideo> get({
    required String accessToken,
    required String id,
  }) async {
    final data = await _send(
      ApiConfig.libraryVideoPath(id),
      method: 'GET',
      accessToken: accessToken,
    );
    return _video(data);
  }

  @override
  Future<void> delete({
    required String accessToken,
    required String id,
  }) async {
    await _send(
      ApiConfig.libraryVideoPath(id),
      method: 'DELETE',
      accessToken: accessToken,
    );
  }

  @override
  Future<UploadSession> startUpload({
    required String accessToken,
    required String id,
  }) async {
    final data = await _send(
      ApiConfig.libraryVideoUploadPath(id),
      accessToken: accessToken,
      body: const {'action': 'start'},
    );
    return UploadSession.fromJson(data);
  }

  @override
  Future<void> uploadChunk({
    required String accessToken,
    required String id,
    required String uploadId,
    required int index,
    required List<int> bytes,
  }) async {
    try {
      await _dio.request<dynamic>(
        ApiConfig.libraryVideoUploadPath(id),
        data: Uint8List.fromList(bytes),
        options: Options(
          method: 'POST',
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/octet-stream',
            'X-Upload-Id': uploadId,
            'X-Chunk-Index': '$index',
          },
        ),
      );
    } catch (error) {
      throw _map(error);
    }
  }

  @override
  Future<CloudVideo> completeUpload({
    required String accessToken,
    required String id,
    required String uploadId,
  }) async {
    final data = await _send(
      ApiConfig.libraryVideoUploadPath(id),
      accessToken: accessToken,
      body: {
        'action': 'complete',
        'uploadId': uploadId,
      },
    );
    return _video(data);
  }

  @override
  Future<String> downloadUrl({
    required String accessToken,
    required String id,
  }) async {
    final data = await _send(
      ApiConfig.libraryVideoDownloadPath(id),
      method: 'GET',
      accessToken: accessToken,
    );
    final url = JsonValues.string(data['url'] ?? data['playUrl']);
    if (url.isEmpty) {
      throw const ServerException(message: '服务器异常，请稍后重试');
    }
    return url;
  }

  @override
  Future<CloudVideo> patch({
    required String accessToken,
    required String id,
    String? title,
    bool? isPrivate,
  }) async {
    final data = await _send(
      ApiConfig.libraryVideoPath(id),
      method: 'PATCH',
      accessToken: accessToken,
      body: {
        if (title != null) 'title': title,
        if (isPrivate != null) 'isPrivate': isPrivate,
      },
    );
    return _video(data);
  }

  CloudVideo _video(Map<String, dynamic> data) {
    final mapped = JsonValues.map(data['video']) ?? data;
    final video = CloudVideo.fromJson(mapped);
    if (video.id.isEmpty) {
      throw const ServerException(message: '服务器异常，请稍后重试');
    }
    return video;
  }

  Future<Map<String, dynamic>> _send(
    String path, {
    String method = 'POST',
    required String accessToken,
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      return JsonValues.map(response.data) ?? <String, dynamic>{};
    } catch (error) {
      throw _map(error);
    }
  }

  AppException _map(Object error) {
    final mapped = ErrorMapper.map(error);
    if (mapped is NetworkException || mapped is AuthException) {
      return mapped;
    }
    if (mapped is NotFoundException) {
      return const NotFoundException(message: '视频不存在');
    }
    return const ServerException(message: '服务器异常，请稍后重试');
  }
}
