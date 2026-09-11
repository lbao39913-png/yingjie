import 'json_values.dart';
import 'playback_record.dart';
import 'video.dart';

class UserCloudData {
  const UserCloudData({
    this.favorites = const [],
    this.playbackHistory = const [],
    this.searchHistory = const [],
    this.autoPlay,
    this.autoReturnAfterCompletion,
    this.playSpeed,
  });

  final List<Video> favorites;
  final List<PlaybackRecord> playbackHistory;
  final List<String> searchHistory;
  final bool? autoPlay;
  final bool? autoReturnAfterCompletion;
  final double? playSpeed;

  factory UserCloudData.fromJson(Map<String, dynamic> json) {
    return UserCloudData(
      favorites: JsonValues.maps(json['favorites'])
          .map(Video.fromJson)
          .where((item) => item.id.trim().isNotEmpty)
          .toList(growable: false),
      playbackHistory: JsonValues.maps(json['playbackHistory'])
          .map(PlaybackRecord.fromJson)
          .where((item) => item.videoId.trim().isNotEmpty)
          .toList(growable: false),
      searchHistory: JsonValues.strings(json['searchHistory'])
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      autoPlay: json['autoPlay'] is bool ? json['autoPlay'] as bool : null,
      autoReturnAfterCompletion: json['autoReturnAfterCompletion'] is bool
          ? json['autoReturnAfterCompletion'] as bool
          : null,
      playSpeed: JsonValues.decimal(json['playSpeed']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'favorites':
          favorites.map((item) => item.toJson()).toList(growable: false),
      'playbackHistory': playbackHistory
          .map((item) => item.toJson())
          .toList(growable: false),
      'searchHistory': searchHistory,
      'autoPlay': autoPlay,
      'autoReturnAfterCompletion': autoReturnAfterCompletion,
      'playSpeed': playSpeed,
    };
  }
}
