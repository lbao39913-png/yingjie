import 'json_values.dart';

class PlaybackRecord {
  const PlaybackRecord({
    required this.videoId,
    required this.title,
    required this.cover,
    required this.episodeId,
    required this.episodeName,
    required this.positionMs,
    required this.durationMs,
    required this.watchedAt,
    this.sourceId,
    this.year,
    this.genres = const [],
  });

  final String videoId;
  final String title;
  final String cover;
  final String episodeId;
  final String episodeName;
  final int positionMs;
  final int durationMs;
  final DateTime watchedAt;
  final String? sourceId;
  final int? year;
  final List<String> genres;

  String get displayTitle {
    final ep = episodeName.trim();
    if (ep.isEmpty || ep == '正片') {
      return title;
    }
    if (title.contains(ep)) {
      return title;
    }
    return '$title · $ep';
  }

  String get historyKey {
    final ep = episodeId.trim();
    if (ep.isEmpty) {
      return videoId;
    }
    return '$videoId|$ep';
  }

  String get cardKey {
    final name = episodeName.trim();
    if (name.isEmpty || name == '正片') {
      return videoId;
    }
    return '$videoId-$episodeId';
  }

  double get progress {
    if (durationMs <= 0) {
      return 0;
    }
    final value = positionMs / durationMs;
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }

  int get watchedPercent => (progress * 100).round();

  String relativeWatchedLabel([DateTime? now]) {
    final delta = (now ?? DateTime.now()).difference(watchedAt);
    if (delta.inSeconds < 60) {
      return '刚刚';
    }
    if (delta.inMinutes < 60) {
      return '${delta.inMinutes}分钟前';
    }
    if (delta.inHours < 24) {
      return '${delta.inHours}小时前';
    }
    if (delta.inDays < 7) {
      return '${delta.inDays}天前';
    }
    final month = watchedAt.month.toString().padLeft(2, '0');
    final day = watchedAt.day.toString().padLeft(2, '0');
    return '${watchedAt.year}-$month-$day';
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'cover': cover,
      'episodeId': episodeId,
      'episodeName': episodeName,
      'positionMs': positionMs,
      'durationMs': durationMs,
      'watchedAt': watchedAt.toIso8601String(),
      'sourceId': sourceId,
      'year': year,
      'genres': genres,
    };
  }

  factory PlaybackRecord.fromJson(Map<String, dynamic> json) {
    return PlaybackRecord(
      videoId: JsonValues.string(json['videoId']),
      title: JsonValues.string(json['title']),
      cover: JsonValues.string(json['cover']),
      episodeId: JsonValues.string(json['episodeId']),
      episodeName: JsonValues.string(json['episodeName']),
      positionMs: JsonValues.integer(json['positionMs']) ?? 0,
      durationMs: JsonValues.integer(json['durationMs']) ?? 0,
      watchedAt: JsonValues.date(json['watchedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sourceId: JsonValues.string(json['sourceId']).isEmpty
          ? null
          : JsonValues.string(json['sourceId']),
      year: JsonValues.integer(json['year']),
      genres: JsonValues.strings(json['genres']),
    );
  }
}
