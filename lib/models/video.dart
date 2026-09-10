import 'episode.dart';
import 'json_values.dart';
import 'play_source.dart';

enum MediaType {
  movie,
  tv;

  static MediaType parse(Object? raw, {int episodeCount = 0}) {
    final value = raw?.toString().trim().toLowerCase() ?? '';
    if (value == 'tv' || value == 'series' || value == 'show') {
      return MediaType.tv;
    }
    if (value == 'movie' || value == 'film') {
      return MediaType.movie;
    }
    if (episodeCount > 1) {
      return MediaType.tv;
    }
    return MediaType.movie;
  }
}

class Video {
  const Video({
    required this.id,
    required this.title,
    required this.cover,
    this.subtitle = '',
    this.description = '',
    this.backdrop = '',
    this.year,
    this.region,
    this.category,
    this.genres = const [],
    this.director,
    this.actors = const [],
    this.rating,
    this.durationMinutes,
    this.sources = const [],
    this.updatedAt,
    this.type = MediaType.movie,
  });

  final String id;
  final String title;
  final String cover;
  final String subtitle;
  final String description;
  final String backdrop;
  final int? year;
  final String? region;
  final String? category;
  final List<String> genres;
  final String? director;
  final List<String> actors;
  final double? rating;
  final int? durationMinutes;
  final List<PlaySource> sources;
  final DateTime? updatedAt;
  final MediaType type;

  PlaySource? get defaultSource => sources.isEmpty ? null : sources.first;

  List<Episode> get episodes => defaultSource?.episodes ?? const [];

  int get episodeCount => episodes.length;

  bool get isTv => type == MediaType.tv || episodeCount > 1;

  bool get isMovie => !isTv;

  String get heroImage {
    final value = backdrop.trim();
    return value.isEmpty ? cover : value;
  }

  String? get playUrl {
    final source = defaultSource;
    if (source == null || source.episodes.isEmpty) {
      return null;
    }
    final url = source.episodes.first.resolvedUrl;
    return url.isEmpty ? null : url;
  }

  String playerTitleFor(Episode? episode) {
    if (!isTv || episode == null) {
      return title;
    }
    final name = episode.name.trim();
    if (name.isEmpty || name == '正片') {
      return title;
    }
    return '$title · $name';
  }

  String? get durationLabel {
    final minutes = durationMinutes;
    if (minutes == null || minutes <= 0) {
      return null;
    }
    return '$minutes 分钟';
  }

  factory Video.fromJson(Map<String, dynamic> json) {
    var sources = JsonValues.maps(json['sources'])
        .map(PlaySource.fromJson)
        .toList();
    if (sources.isEmpty) {
      final topEpisodes = JsonValues.maps(json['episodes']);
      if (topEpisodes.isNotEmpty) {
        sources = [
          PlaySource(
            id: 'default',
            name: '默认线路',
            episodes: topEpisodes.map(Episode.fromJson).toList(growable: false),
          ),
        ];
      }
    }
    if (sources.isEmpty) {
      var playUrl = JsonValues.string(json['playUrl']).trim();
      if (playUrl.isEmpty) {
        playUrl = JsonValues.string(json['url']).trim();
      }
      if (playUrl.isNotEmpty) {
        var episodeId = JsonValues.string(json['episodeId']);
        if (episodeId.isEmpty) {
          episodeId = '1';
        }
        var episodeName = JsonValues.string(json['episodeName']);
        if (episodeName.isEmpty) {
          episodeName = '正片';
        }
        sources = [
          PlaySource(
            id: 'default',
            name: '默认线路',
            episodes: [
              Episode(
                id: episodeId,
                name: episodeName,
                url: playUrl,
              ),
            ],
          ),
        ];
      }
    }
    final episodeCount =
        sources.isEmpty ? 0 : sources.first.episodes.length;
    return Video(
      id: JsonValues.string(json['id']),
      title: JsonValues.string(json['title']),
      cover: JsonValues.string(json['cover']),
      subtitle: JsonValues.string(json['subtitle']),
      description: JsonValues.string(json['description']),
      backdrop: JsonValues.string(json['backdrop']),
      year: JsonValues.integer(json['year']),
      region: JsonValues.string(json['region']).isEmpty
          ? null
          : JsonValues.string(json['region']),
      category: JsonValues.string(json['category']).isEmpty
          ? null
          : JsonValues.string(json['category']),
      genres: JsonValues.strings(json['genres']),
      director: JsonValues.string(json['director']).isEmpty
          ? null
          : JsonValues.string(json['director']),
      actors: JsonValues.strings(json['actors']),
      rating: JsonValues.decimal(json['rating']),
      durationMinutes: JsonValues.integer(json['durationMinutes']),
      sources: sources,
      updatedAt: JsonValues.date(json['updatedAt']),
      type: MediaType.parse(
        json['type'] ?? json['mediaType'],
        episodeCount: episodeCount,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'cover': cover,
      'subtitle': subtitle,
      'description': description,
      'backdrop': backdrop,
      'year': year,
      'region': region,
      'category': category,
      'genres': genres,
      'director': director,
      'actors': actors,
      'rating': rating,
      'durationMinutes': durationMinutes,
      'sources': sources.map((item) => item.toJson()).toList(growable: false),
      'updatedAt': updatedAt?.toIso8601String(),
      'type': type == MediaType.tv ? 'tv' : 'movie',
    };
  }
}
