import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../services/search_service.dart';

class SearchHistoryController extends StateNotifier<List<String>> {
  SearchHistoryController(this._search) : super(const []) {
    _subscription = _search.changes.listen((_) => load());
    load();
  }

  final SearchService _search;
  StreamSubscription<void>? _subscription;
  bool _disposed = false;

  void load() {
    if (_disposed) {
      return;
    }
    state = _search.history();
  }

  Future<void> remove(String keyword) {
    return _search.removeHistory(keyword);
  }

  Future<void> clear() {
    return _search.clearHistory();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}

final searchHistoryControllerProvider =
    StateNotifierProvider.autoDispose<SearchHistoryController, List<String>>(
  (ref) {
    return SearchHistoryController(ref.watch(searchServiceProvider));
  },
);
