import '../../models/user_cloud_data.dart';

abstract class CloudSyncApi {
  Future<UserCloudData> pull({required String accessToken});

  Future<void> push({
    required String accessToken,
    required UserCloudData data,
  });
}
