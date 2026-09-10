import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../models/video.dart';
import '../../services/api_service.dart';
import '../../services/favorite_service.dart';
import '../../services/player_service.dart';

enum DetailStatus { loading, ready, error }

class DetailState {
  const DetailState({
    this.status = DetailStatus.loading,
    this.video,
    this.related = const [],
    this.error,
    this.favorited = false,
  });

  final DetailStatus status;
  final Video? video;
  final List<Video> related;
  final AppException? error;
  final bool favorited;

  DetailState copyWith({
    DetailStatus? status,
    Video? video,
    List<Video>? related,
    AppException? error,
    bool clearError = false,
    bool? favorited,
  }) {
    return DetailState(
      status: status ?? this.status,
      video: video ?? this.video,
      related: related ?? this.related,
      error: clearError ? null : (error ?? this.error),
      favorited: favorited ?? this.favorited,
    );
  }
}

class DetailController extends StateNotifier<DetailState> {
  DetailController(
    this._videoId,
    this._api,
    this._favorites,
    this._player,
  ) : super(const DetailState()) {
    load();
  }

  final String _videoId;
  final ApiService _api;
  final FavoriteService _favorites;
  final PlayerService _player;
  bool _loadInFlight = false;

  Future<void> load() async {
    if (_loadInFlight) {
      return;
    }
    final id = _videoId.trim();
    if (id.isEmpty) {
      state = const DetailState(
        status: DetailStatus.error,
        error: NotFoundException(),
      );
      return;
    }

    _loadInFlight = true;
    state = const DetailState(status: DetailStatus.loading);
    try {
      final detailFuture = _api.fetchDetail(id);
      final relatedFuture = _api.fetchRecommend(
        page: 1,
        pageSize: AppConstants.detailRelatedLimit + 1,
      );
      final detailResult = await detailFuture;
      final relatedResult = await relatedFuture;

      final detailError = detailResult.when(
        success: (_) => null,
        failure: (error) => error,
      );
      if (detailError != null) {
        state = DetailState(
          status: DetailStatus.error,
          error: detailError,
        );
        return;
      }

      final video = detailResult.dataOrNull!;
      final related = relatedResult.when(
        success: (paged) {
          return paged.items
              .where((item) => item.id != video.id)
              .take(AppConstants.detailRelatedLimit)
              .toList(growable: false);
        },
        failure: (_) => const <Video>[],
      );
      state = DetailState(
        status: DetailStatus.ready,
        video: video,
        related: related,
        favorited: _favorites.contains(video.id),
      );
    } catch (error) {
      state = DetailState(
        status: DetailStatus.error,
        error: ErrorMapper.map(error),
      );
    } finally {
      _loadInFlight = false;
    }
  }

  Future<void> toggleFavorite() async {
    final video = state.video;
    if (video == null) {
      return;
    }
    final favorited = await _favorites.toggle(video);
    state = state.copyWith(favorited: favorited);
  }

  PlayLaunch? resolveLaunch() {
    final video = state.video;
    if (video == null) {
      return null;
    }
    return _player.resolveLaunch(video);
  }

  PlayLaunch? resolveEpisodeLaunch(String episodeId) {
    final video = state.video;
    if (video == null) {
      return null;
    }
    return _player.resolveLaunch(video, episodeId: episodeId);
  }
}

final detailControllerProvider = StateNotifierProvider.autoDispose
    .family<DetailController, DetailState, String>((ref, videoId) {
  return DetailController(
    videoId,
    ref.watch(apiServiceProvider),
    ref.watch(favoriteServiceProvider),
    ref.watch(playerServiceProvider),
  );
});
