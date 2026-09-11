import '../../core/errors/app_exception.dart';
import '../../models/user_cloud_data.dart';
import '../api/cloud_sync_api.dart';

class MockCloudSyncApi implements CloudSyncApi {
  MockCloudSyncApi({this.resolveUserId});

  final String? Function(String accessToken)? resolveUserId;
  final Map<String, UserCloudData> _byUser = {};

  @override
  Future<UserCloudData> pull({required String accessToken}) async {
    final userId = _userId(accessToken);
    return _byUser[userId] ?? const UserCloudData();
  }

  @override
  Future<void> push({
    required String accessToken,
    required UserCloudData data,
  }) async {
    final userId = _userId(accessToken);
    _byUser[userId] = data;
  }

  void seed(String userId, UserCloudData data) {
    _byUser[userId] = data;
  }

  UserCloudData? stored(String userId) => _byUser[userId];

  String _userId(String accessToken) {
    if (resolveUserId != null) {
      final id = resolveUserId!(accessToken);
      if (id == null || id.isEmpty) {
        throw const AuthException(message: '登录已过期，请重新登录');
      }
      return id;
    }
    final parts = accessToken.split('.');
    if (parts.length < 2 || parts[1].isEmpty) {
      throw const AuthException(message: '登录已过期，请重新登录');
    }
    return parts[1];
  }
}
