import '../core/errors/app_exception.dart';
import '../data/api/cloud_video_api.dart';
import 'cloud_video_service.dart';

class CloudVideoSyncService {
  CloudVideoSyncService({
    required this._api,
    required this._videos,
  });

  final CloudVideoApi _api;
  final CloudVideoService _videos;

  Future<void> pull(String accessToken, {String? userId}) async {
    try {
      final items = await _api.list(
        accessToken: accessToken,
        includePrivate: true,
      );
      var id = userId?.trim() ?? '';
      if (id.isEmpty && items.isNotEmpty) {
        id = items.first.userId;
      }
      if (id.isEmpty) {
        id = _userIdFromToken(accessToken);
      }
      if (id.isEmpty) {
        return;
      }
      await _videos.replaceUserCache(id, items);
    } on AppException {
      return;
    }
  }

  String _userIdFromToken(String accessToken) {
    final parts = accessToken.split('.');
    if (parts.length < 2) {
      return '';
    }
    return parts[1];
  }
}
