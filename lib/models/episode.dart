import 'json_values.dart';
import 'video_source.dart';

class Episode {
  const Episode({
    required this.id,
    required this.name,
    required this.url,
    this.quality,
    this.episodeNumber = 0,
    this.mediaId = '',
    this.sources = const [],
  });

  final String id;
  final String name;
  final String url;
  final String? quality;
  final int episodeNumber;
  final String mediaId;
  final List<VideoSource> sources;

  String get resolvedUrl {
    final direct = url.trim();
    if (direct.isNotEmpty) {
      return direct;
    }
    for (final source in sources) {
      final value = source.url.trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  int get number {
    if (episodeNumber > 0) {
      return episodeNumber;
    }
    final match = RegExp(r'(\d+)').firstMatch(name);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  factory Episode.fromJson(Map<String, dynamic> json) {
    final sources = JsonValues.maps(json['sources'])
        .map(VideoSource.fromJson)
        .toList(growable: false);
    var url = JsonValues.string(json['url']).trim();
    if (url.isEmpty) {
      url = JsonValues.string(json['playUrl']).trim();
    }
    if (url.isEmpty && sources.isNotEmpty) {
      url = sources.first.url.trim();
    }
    var name = JsonValues.string(json['name']);
    if (name.isEmpty) {
      name = JsonValues.string(json['title']);
    }
    var number = JsonValues.integer(json['episodeNumber']) ??
        JsonValues.integer(json['index']) ??
        0;
    if (number <= 0) {
      final match = RegExp(r'(\d+)').firstMatch(name);
      number = int.tryParse(match?.group(1) ?? '') ?? 0;
    }
    var id = JsonValues.string(json['id']);
    if (id.isEmpty && number > 0) {
      id = '$number';
    }
    final quality = JsonValues.string(json['quality']);
    return Episode(
      id: id,
      name: name,
      url: url,
      quality: quality.isEmpty
          ? (sources.isEmpty ? null : sources.first.quality)
          : quality,
      episodeNumber: number,
      mediaId: JsonValues.string(json['mediaId']),
      sources: sources,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      if (quality != null) 'quality': quality,
      'episodeNumber': episodeNumber,
      'mediaId': mediaId,
      'sources': sources.map((item) => item.toJson()).toList(growable: false),
    };
  }
}
