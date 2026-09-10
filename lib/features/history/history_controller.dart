import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../models/playback_record.dart';
import '../../services/history_service.dart';

enum HistoryStatus { initial, loading, success, empty, error }

class HistoryState {
  const HistoryState({
    this.status = HistoryStatus.initial,
    this.items = const [],
    this.error,
  });

  final HistoryStatus status;
  final List<PlaybackRecord> items;
  final AppException? error;

  HistoryState copyWith({
    HistoryStatus? status,
    List<PlaybackRecord>? items,
    AppException? error,
    bool clearError = false,
  }) {
    return HistoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class HistoryController extends StateNotifier<HistoryState> {
  HistoryController(this._history) : super(const HistoryState()) {
    _subscription = _history.changes.listen((_) => load());
    load();
  }

  final HistoryService _history;
  StreamSubscription<void>? _subscription;
  bool _disposed = false;

  void load() {
    if (_disposed) {
      return;
    }
    try {
      final items = _history.all();
      if (items.isEmpty) {
        state = const HistoryState(status: HistoryStatus.empty);
        return;
      }
      state = HistoryState(
        status: HistoryStatus.success,
        items: items,
      );
    } catch (error) {
      if (_disposed) {
        return;
      }
      if (state.items.isNotEmpty) {
        return;
      }
      state = HistoryState(
        status: HistoryStatus.error,
        error: ErrorMapper.map(error),
      );
    }
  }

  Future<void> remove(String mediaId, {String? episodeId}) async {
    await _history.remove(mediaId, episodeId: episodeId);
  }

  Future<void> clear() async {
    await _history.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}

final historyControllerProvider =
    StateNotifierProvider.autoDispose<HistoryController, HistoryState>(
  (ref) {
    return HistoryController(ref.watch(historyServiceProvider));
  },
);
