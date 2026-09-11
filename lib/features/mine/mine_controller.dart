import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../services/favorite_service.dart';
import '../../services/history_service.dart';
import '../../services/search_service.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';

class MineState {
  const MineState({
    this.favoriteCount = 0,
    this.historyCount = 0,
    this.searchCount = 0,
    this.auth = const AuthSnapshot(),
  });

  final int favoriteCount;
  final int historyCount;
  final int searchCount;
  final AuthSnapshot auth;

  MineState copyWith({
    int? favoriteCount,
    int? historyCount,
    int? searchCount,
    AuthSnapshot? auth,
  }) {
    return MineState(
      favoriteCount: favoriteCount ?? this.favoriteCount,
      historyCount: historyCount ?? this.historyCount,
      searchCount: searchCount ?? this.searchCount,
      auth: auth ?? this.auth,
    );
  }
}

class MineController extends StateNotifier<MineState> {
  MineController({
    required this._favorites,
    required this._history,
    required this._search,
    required this._auth,
  }) : super(const MineState()) {
    _subscriptions = [
      _favorites.changes.listen((_) => load()),
      _history.changes.listen((_) => load()),
      _search.changes.listen((_) => load()),
      _auth.changes.listen((_) => load()),
    ];
    load();
  }

  final FavoriteService _favorites;
  final HistoryService _history;
  final SearchService _search;
  final AuthService _auth;
  late final List<StreamSubscription<void>> _subscriptions;
  bool _disposed = false;

  void load() {
    if (_disposed) {
      return;
    }
    state = MineState(
      favoriteCount: _favorites.count(),
      historyCount: _history.count(),
      searchCount: _search.count(),
      auth: _auth.snapshot,
    );
  }

  Future<void> logout() => _auth.logout();

  @override
  void dispose() {
    _disposed = true;
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}

final mineControllerProvider =
    StateNotifierProvider.autoDispose<MineController, MineState>((ref) {
  return MineController(
    favorites: ref.watch(favoriteServiceProvider),
    history: ref.watch(historyServiceProvider),
    search: ref.watch(searchServiceProvider),
    auth: ref.watch(authServiceProvider),
  );
});
