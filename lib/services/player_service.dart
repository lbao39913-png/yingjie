import '../core/errors/app_exception.dart';
import '../models/episode.dart';
import '../models/play_source.dart';
import '../models/playback_record.dart';
import '../models/video.dart';

class PlayLaunch {
  const PlayLaunch({
    required this.mediaId,
    required this.title,
    required this.playUrl,
    this.episodeId,
    this.sourceId,
    this.cover = '',
    this.year,
    this.genres = const [],
    this.episodeName = '',
    this.isTv = false,
  });

  final String mediaId;
  final String title;
  final String playUrl;
  final String? episodeId;
  final String? sourceId;
  final String cover;
  final int? year;
  final List<String> genres;
  final String episodeName;
  final bool isTv;
}

/// Playback orchestration stays here, not in widgets.
class PlayerService {
  PlaySource? resolveSource(Video video, {String? sourceId}) {
    if (video.sources.isEmpty) {
      return null;
    }
    if (sourceId == null) {
      return video.sources.first;
    }
    for (final source in video.sources) {
      if (source.id == sourceId) {
        return source;
      }
    }
    return video.sources.first;
  }

  Episode? resolveEpisode(PlaySource source, {String? episodeId}) {
    if (source.episodes.isEmpty) {
      return null;
    }
    if (episodeId == null) {
      return source.episodes.first;
    }
    for (final episode in source.episodes) {
      if (episode.id == episodeId) {
        return episode;
      }
    }
    return source.episodes.first;
  }

  Episode? nextEpisode(PlaySource source, String currentEpisodeId) {
    final index =
        source.episodes.indexWhere((item) => item.id == currentEpisodeId);
    if (index < 0 || index + 1 >= source.episodes.length) {
      return null;
    }
    return source.episodes[index + 1];
  }

  Episode? previousEpisode(PlaySource source, String currentEpisodeId) {
    final index =
        source.episodes.indexWhere((item) => item.id == currentEpisodeId);
    if (index <= 0) {
      return null;
    }
    return source.episodes[index - 1];
  }

  PlayLaunch? resolveLaunch(
    Video video, {
    String? sourceId,
    String? episodeId,
  }) {
    final source = resolveSource(video, sourceId: sourceId);
    if (source == null) {
      return null;
    }
    final episode = resolveEpisode(source, episodeId: episodeId);
    if (episode == null || episode.resolvedUrl.isEmpty) {
      return null;
    }
    return PlayLaunch(
      mediaId: video.id,
      title: video.playerTitleFor(episode),
      playUrl: episode.resolvedUrl,
      episodeId: episode.id,
      sourceId: source.id,
      cover: video.cover,
      year: video.year,
      genres: video.genres,
      episodeName: episode.name,
      isTv: video.isTv,
    );
  }

  void ensurePlayable(Episode? episode) {
    if (episode == null || episode.resolvedUrl.isEmpty) {
      throw const PlaybackException();
    }
  }

  PlaybackRecord buildRecord({
    required Video video,
    required Episode episode,
    required String sourceId,
    required int positionMs,
    required int durationMs,
  }) {
    return PlaybackRecord(
      videoId: video.id,
      title: video.title,
      cover: video.cover,
      episodeId: episode.id,
      episodeName: episode.name,
      sourceId: sourceId,
      positionMs: positionMs,
      durationMs: durationMs,
      watchedAt: DateTime.now(),
      year: video.year,
      genres: video.genres,
    );
  }
}
