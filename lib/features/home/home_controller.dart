import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../models/home_feed.dart';
import '../../models/video.dart';
import '../../services/api_service.dart';

enum HomeStatus { loading, ready, empty, error }

class HomeState {
  const HomeState({
    this.status = HomeStatus.loading,
    this.feed,
    this.error,
    this.recommend = const [],
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.refreshing = false,
  });

  final HomeStatus status;
  final HomeFeed? feed;
  final AppException? error;
  final List<Video> recommend;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final bool refreshing;

  HomeState copyWith({
    HomeStatus? status,
    HomeFeed? feed,
    AppException? error,
    bool clearError = false,
    List<Video>? recommend,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    bool? refreshing,
  }) {
    return HomeState(
      status: status ?? this.status,
      feed: feed ?? this.feed,
      error: clearError ? null : (error ?? this.error),
      recommend: recommend ?? this.recommend,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      refreshing: refreshing ?? this.refreshing,
    );
  }
}

class HomeController extends StateNotifier<HomeState> {
  HomeController(this._api) : super(const HomeState()) {
    load();
  }

  final ApiService _api;
  bool _loadInFlight = false;
  bool _moreInFlight = false;

  Future<void> load({bool refresh = false}) async {
    if (_loadInFlight) {
      return;
    }
    _loadInFlight = true;
    state = state.copyWith(
      status: refresh ? state.status : HomeStatus.loading,
      refreshing: refresh,
      clearError: true,
    );

    try {
      final feedFuture = _api.fetchHome();
      final recFuture = _api.fetchRecommend(
        page: 1,
        pageSize: AppConstants.homeRecommendPageSize,
      );
      final feedResult = await feedFuture;
      final recResult = await recFuture;

      final failure = feedResult.when(
        success: (_) => recResult.when(
          success: (_) => null,
          failure: (error) => error,
        ),
        failure: (error) => error,
      );

      if (failure != null) {
        state = state.copyWith(
          status: HomeStatus.error,
          error: failure,
          refreshing: false,
        );
        return;
      }

      final feed = feedResult.dataOrNull!;
      final paged = recResult.dataOrNull!;

      state = HomeState(
        status: feed.isEmpty && paged.items.isEmpty
            ? HomeStatus.empty
            : HomeStatus.ready,
        feed: feed,
        recommend: paged.items,
        page: 1,
        hasMore: paged.hasMore,
        refreshing: false,
      );
    } catch (error) {
      state = state.copyWith(
        status: HomeStatus.error,
        error: ErrorMapper.map(error),
        refreshing: false,
      );
    } finally {
      _loadInFlight = false;
    }
  }

  Future<void> loadMore() async {
    if (_moreInFlight || _loadInFlight || !state.hasMore || state.loadingMore) {
      return;
    }
    _moreInFlight = true;
    state = state.copyWith(loadingMore: true);
    final nextPage = state.page + 1;
    try {
      final result = await _api.fetchRecommend(
        page: nextPage,
        pageSize: AppConstants.homeRecommendPageSize,
      );
      result.when(
        success: (paged) {
          state = state.copyWith(
            recommend: [...state.recommend, ...paged.items],
            page: nextPage,
            hasMore: paged.hasMore,
            loadingMore: false,
          );
        },
        failure: (_) {
          state = state.copyWith(loadingMore: false);
        },
      );
    } catch (_) {
      state = state.copyWith(loadingMore: false);
    } finally {
      _moreInFlight = false;
    }
  }
}

final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeState>((ref) {
  return HomeController(ref.watch(apiServiceProvider));
});
