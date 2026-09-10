import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../models/video.dart';
import '../../services/favorite_service.dart';

enum FavoritesStatus { initial, loading, success, empty, error }

class FavoritesState {
  const FavoritesState({
    this.status = FavoritesStatus.initial,
    this.items = const [],
    this.error,
  });

  final FavoritesStatus status;
  final List<Video> items;
  final AppException? error;

  FavoritesState copyWith({
    FavoritesStatus? status,
    List<Video>? items,
    AppException? error,
    bool clearError = false,
  }) {
    return FavoritesState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class FavoritesController extends StateNotifier<FavoritesState> {
  FavoritesController(this._favorites) : super(const FavoritesState()) {
    _subscription = _favorites.changes.listen((_) => load());
    load();
  }

  final FavoriteService _favorites;
  StreamSubscription<void>? _subscription;
  bool _disposed = false;

  void load() {
    if (_disposed) {
      return;
    }
    try {
      final items = _favorites.all();
      if (items.isEmpty) {
        state = const FavoritesState(status: FavoritesStatus.empty);
        return;
      }
      state = FavoritesState(
        status: FavoritesStatus.success,
        items: items,
      );
    } catch (error) {
      if (_disposed) {
        return;
      }
      if (state.items.isNotEmpty) {
        return;
      }
      state = FavoritesState(
        status: FavoritesStatus.error,
        error: ErrorMapper.map(error),
      );
    }
  }

  Future<void> remove(String id) async {
    await _favorites.remove(id);
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}

final favoritesControllerProvider =
    StateNotifierProvider.autoDispose<FavoritesController, FavoritesState>(
  (ref) {
    return FavoritesController(ref.watch(favoriteServiceProvider));
  },
);
