import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/debounce.dart';
import '../../models/video.dart';
import '../../services/search_service.dart';

enum SearchStatus { initial, searching, success, empty, error }

class SearchState {
  const SearchState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.results = const [],
    this.suggestions = const [],
    this.history = const [],
    this.error,
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.refreshing = false,
  });

  final SearchStatus status;
  final String query;
  final List<Video> results;
  final List<String> suggestions;
  final List<String> history;
  final AppException? error;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final bool refreshing;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<Video>? results,
    List<String>? suggestions,
    List<String>? history,
    AppException? error,
    bool clearError = false,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    bool? refreshing,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      suggestions: suggestions ?? this.suggestions,
      history: history ?? this.history,
      error: clearError ? null : (error ?? this.error),
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      refreshing: refreshing ?? this.refreshing,
    );
  }
}

class SearchController extends StateNotifier<SearchState> {
  SearchController(
    this._search, {
    this.pageSize = AppConstants.searchPageSize,
    Duration debounce = AppConstants.searchDebounce,
  }) : _debouncer = Debouncer(duration: debounce),
       super(const SearchState()) {
    state = state.copyWith(history: _search.history());
  }

  final SearchService _search;
  final int pageSize;
  final Debouncer _debouncer;

  int _searchSeq = 0;
  int _suggestSeq = 0;
  bool _searchInFlight = false;
  bool _moreInFlight = false;
  String? _inFlightQuery;

  void onQueryChanged(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      _debouncer.cancel();
      _suggestSeq++;
      state = state.copyWith(suggestions: const []);
      return;
    }
    _debouncer.run(() {
      _loadSuggestions(trimmed);
    });
  }

  Future<void> submit(String keyword) {
    final trimmed = keyword.trim();
    _debouncer.cancel();
    if (trimmed.isEmpty) {
      _suggestSeq++;
      state = state.copyWith(
        status: SearchStatus.initial,
        query: '',
        results: const [],
        suggestions: const [],
        page: 1,
        hasMore: false,
        loadingMore: false,
        refreshing: false,
        clearError: true,
      );
      return Future<void>.value();
    }
    return _searchPage(trimmed, page: 1, refresh: false);
  }

  Future<void> retry() {
    if (state.query.isEmpty) {
      return Future<void>.value();
    }
    return _searchPage(state.query, page: 1, refresh: false);
  }

  Future<void> refresh() {
    if (state.query.isEmpty) {
      return Future<void>.value();
    }
    return _searchPage(state.query, page: 1, refresh: true);
  }

  Future<void> loadMore() async {
    if (_moreInFlight ||
        _searchInFlight ||
        !state.hasMore ||
        state.loadingMore ||
        state.query.isEmpty) {
      return;
    }
    _moreInFlight = true;
    state = state.copyWith(loadingMore: true);
    final nextPage = state.page + 1;
    final seq = _searchSeq;
    try {
      final result = await _search.search(
        state.query,
        page: nextPage,
        pageSize: pageSize,
      );
      if (seq != _searchSeq) {
        return;
      }
      result.when(
        success: (paged) {
          state = state.copyWith(
            results: [...state.results, ...paged.items],
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
      if (seq == _searchSeq) {
        state = state.copyWith(loadingMore: false);
      }
    } finally {
      _moreInFlight = false;
    }
  }

  Future<void> removeHistory(String keyword) async {
    await _search.removeHistory(keyword);
    state = state.copyWith(history: _search.history());
  }

  Future<void> clearHistory() async {
    await _search.clearHistory();
    state = state.copyWith(history: const []);
  }

  Future<void> resetToInitial() async {
    _debouncer.dispose();
    _searchSeq++;
    _suggestSeq++;
    _searchInFlight = false;
    _inFlightQuery = null;
    state = SearchState(history: _search.history());
  }

  Future<void> _loadSuggestions(String keyword) async {
    final seq = ++_suggestSeq;
    final result = await _search.suggest(keyword);
    if (seq != _suggestSeq) {
      return;
    }
    result.when(
      success: (items) {
        state = state.copyWith(suggestions: items);
      },
      failure: (_) {
        state = state.copyWith(suggestions: const []);
      },
    );
  }

  Future<void> _searchPage(
    String keyword, {
    required int page,
    required bool refresh,
  }) async {
    if (!refresh &&
        _searchInFlight &&
        _inFlightQuery == keyword &&
        page == 1) {
      return;
    }
    if (refresh && _searchInFlight) {
      return;
    }

    _searchInFlight = true;
    _inFlightQuery = keyword;
    final seq = ++_searchSeq;
    _suggestSeq++;

    if (refresh) {
      state = state.copyWith(
        query: keyword,
        suggestions: const [],
        refreshing: true,
        clearError: true,
      );
    } else {
      state = state.copyWith(
        status: SearchStatus.searching,
        query: keyword,
        results: const [],
        suggestions: const [],
        page: 1,
        hasMore: false,
        loadingMore: false,
        refreshing: false,
        clearError: true,
      );
    }

    try {
      final result = await _search.search(
        keyword,
        page: page,
        pageSize: pageSize,
      );
      if (seq != _searchSeq) {
        return;
      }
      result.when(
        success: (paged) {
          state = state.copyWith(
            status: paged.items.isEmpty ? SearchStatus.empty : SearchStatus.success,
            results: paged.items,
            history: _search.history(),
            page: page,
            hasMore: paged.hasMore,
            loadingMore: false,
            refreshing: false,
            clearError: true,
          );
        },
        failure: (error) {
          if (refresh && state.results.isNotEmpty) {
            state = state.copyWith(
              refreshing: false,
              error: error,
            );
            return;
          }
          state = state.copyWith(
            status: SearchStatus.error,
            error: error,
            refreshing: false,
            loadingMore: false,
          );
        },
      );
    } catch (error) {
      if (seq != _searchSeq) {
        return;
      }
      final mapped = ErrorMapper.map(error);
      if (refresh && state.results.isNotEmpty) {
        state = state.copyWith(refreshing: false, error: mapped);
        return;
      }
      state = state.copyWith(
        status: SearchStatus.error,
        error: mapped,
        refreshing: false,
        loadingMore: false,
      );
    } finally {
      if (seq == _searchSeq) {
        _searchInFlight = false;
        _inFlightQuery = null;
      }
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}

final searchControllerProvider =
    StateNotifierProvider.autoDispose<SearchController, SearchState>((ref) {
  return SearchController(ref.watch(searchServiceProvider));
});
