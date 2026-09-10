class DetailRouteArgs {
  const DetailRouteArgs({required this.id});

  final String id;

  factory DetailRouteArgs.parse(String? id) {
    return DetailRouteArgs(id: (id ?? '').trim());
  }
}

class PlayerRouteArgs {
  const PlayerRouteArgs({
    required this.mediaId,
    this.title,
    this.playUrl,
    this.episodeId,
    this.sourceId,
    this.cover,
    this.year,
    this.genres = const [],
  });

  final String mediaId;
  final String? title;
  final String? playUrl;
  final String? episodeId;
  final String? sourceId;
  final String? cover;
  final int? year;
  final List<String> genres;

  factory PlayerRouteArgs.parse({
    required String? id,
    Map<String, String> query = const {},
  }) {
    final rawGenres = query['genres'] ?? '';
    return PlayerRouteArgs(
      mediaId: (id ?? '').trim(),
      title: query['title'],
      playUrl: query['playUrl'],
      episodeId: query['episodeId'],
      sourceId: query['sourceId'],
      cover: query['cover'],
      year: int.tryParse(query['year'] ?? ''),
      genres: rawGenres
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
    );
  }

  Map<String, String> toQuery() {
    return {
      if (title != null && title!.isNotEmpty) 'title': title!,
      if (playUrl != null && playUrl!.isNotEmpty) 'playUrl': playUrl!,
      if (episodeId != null && episodeId!.isNotEmpty) 'episodeId': episodeId!,
      if (sourceId != null && sourceId!.isNotEmpty) 'sourceId': sourceId!,
      if (cover != null && cover!.isNotEmpty) 'cover': cover!,
      if (year != null) 'year': '$year',
      if (genres.isNotEmpty) 'genres': genres.join(','),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerRouteArgs &&
        other.mediaId == mediaId &&
        other.title == title &&
        other.playUrl == playUrl &&
        other.episodeId == episodeId &&
        other.sourceId == sourceId &&
        other.cover == cover &&
        other.year == year &&
        other.genres.join(',') == genres.join(',');
  }

  @override
  int get hashCode =>
      Object.hash(mediaId, title, playUrl, episodeId, sourceId, cover, year, Object.hashAll(genres));
}
