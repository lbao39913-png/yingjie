import '../../models/cloud_video.dart';

abstract class CloudVideoApi {
  Future<List<CloudVideo>> list({
    required String accessToken,
    bool includePrivate = false,
  });

  Future<CloudVideo> create({
    required String accessToken,
    required String title,
    required int sizeBytes,
    bool isPrivate = false,
  });

  Future<CloudVideo> get({
    required String accessToken,
    required String id,
  });

  Future<void> delete({
    required String accessToken,
    required String id,
  });

  Future<UploadSession> startUpload({
    required String accessToken,
    required String id,
  });

  Future<void> uploadChunk({
    required String accessToken,
    required String id,
    required String uploadId,
    required int index,
    required List<int> bytes,
  });

  Future<CloudVideo> completeUpload({
    required String accessToken,
    required String id,
    required String uploadId,
  });

  Future<String> downloadUrl({
    required String accessToken,
    required String id,
  });

  Future<CloudVideo> patch({
    required String accessToken,
    required String id,
    String? title,
    bool? isPrivate,
  });
}
