import 'json_values.dart';

class VideoSource {
  const VideoSource({
    required this.url,
    this.id = '',
    this.quality,
    this.name,
  });

  final String id;
  final String url;
  final String? quality;
  final String? name;

  factory VideoSource.fromJson(Map<String, dynamic> json) {
    final quality = JsonValues.string(json['quality']);
    final name = JsonValues.string(json['name']);
    final url = JsonValues.string(json['url']).trim();
    return VideoSource(
      id: JsonValues.string(json['id']),
      url: url.isNotEmpty ? url : JsonValues.string(json['playUrl']).trim(),
      quality: quality.isEmpty ? null : quality,
      name: name.isEmpty ? null : name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      if (quality != null) 'quality': quality,
      if (name != null) 'name': name,
    };
  }
}
