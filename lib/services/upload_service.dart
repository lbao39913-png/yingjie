import 'dart:math';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../data/api/cloud_video_api.dart';
import '../models/cloud_video.dart';
import 'byte_source.dart';

typedef UploadProgress = void Function(int sent, int total);

class UploadService {
  UploadService({this.chunkRetries = AppConstants.uploadChunkRetries});

  final int chunkRetries;

  Future<CloudVideo> upload({
    required CloudVideoApi api,
    required String accessToken,
    required String videoId,
    required ByteSource source,
    required UploadSession session,
    UploadProgress? onProgress,
  }) async {
    final chunkSize = session.chunkSize <= 0
        ? AppConstants.uploadChunkSize
        : session.chunkSize;
    var index = session.nextChunkIndex;
    if (index < 0) {
      index = 0;
    }
    final total = source.length;
    while (index < session.chunkTotal) {
      final offset = index * chunkSize;
      final len = min(chunkSize, max(0, total - offset));
      final bytes = len == 0 ? const <int>[] : await source.read(offset, len);
      await _sendChunk(
        api: api,
        accessToken: accessToken,
        videoId: videoId,
        uploadId: session.uploadId,
        index: index,
        bytes: bytes,
      );
      final sent = min(total, offset + bytes.length);
      onProgress?.call(sent, total);
      index += 1;
    }
    return api.completeUpload(
      accessToken: accessToken,
      id: videoId,
      uploadId: session.uploadId,
    );
  }

  Future<void> _sendChunk({
    required CloudVideoApi api,
    required String accessToken,
    required String videoId,
    required String uploadId,
    required int index,
    required List<int> bytes,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        await api.uploadChunk(
          accessToken: accessToken,
          id: videoId,
          uploadId: uploadId,
          index: index,
          bytes: bytes,
        );
        return;
      } catch (error) {
        attempt += 1;
        if (attempt > chunkRetries) {
          if (error is AppException) {
            rethrow;
          }
          throw const NetworkException();
        }
      }
    }
  }
}
