import 'json_values.dart';

class LocalVideo {
  const LocalVideo({
    required this.id,
    required this.title,
    required this.filePath,
    required this.sizeBytes,
    this.durationMs,
    this.cover = '',
    this.createdAt,
  });

  final String id;
  final String title;
  final String filePath;
  final int sizeBytes;
  final int? durationMs;
  final String cover;
  final DateTime? createdAt;

  String get playUrl {
    final path = filePath.trim();
    if (path.isEmpty) {
      return '';
    }
    final uri = Uri.tryParse(path);
    if (uri != null && uri.hasScheme) {
      return path;
    }
    return Uri.file(path).toString();
  }

  factory LocalVideo.fromJson(Map<String, dynamic> json) {
    return LocalVideo(
      id: JsonValues.string(json['id']),
      title: JsonValues.string(json['title']),
      filePath: JsonValues.string(json['filePath']),
      sizeBytes: JsonValues.integer(json['sizeBytes']) ?? 0,
      durationMs: JsonValues.integer(json['durationMs']),
      cover: JsonValues.string(json['cover']),
      createdAt: JsonValues.date(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'sizeBytes': sizeBytes,
      'durationMs': durationMs,
      'cover': cover,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
