import 'dart:async';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/error_mapper.dart';
import '../core/network/api_result.dart';
import '../core/storage/local_storage.dart';
import '../data/api/api_provider.dart';
import '../models/paged_result.dart';
import '../models/video.dart';

class SearchService {
  SearchService(this._api);

  final ApiProvider _api;
  static const _historyKey = 'keywords';
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  Future<ApiResult<PagedResult<Video>>> search(
    String keyword, {
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      return ApiSuccess(
        PagedResult<Video>(
          items: const [],
          page: page,
          pageSize: pageSize,
          total: 0,
        ),
      );
    }
    try {
      final result = await _api.mediaApi.search(
        trimmed,
        page: page,
        pageSize: pageSize,
      );
      if (page == 1) {
        await addHistory(trimmed);
      }
      return ApiSuccess(result);
    } catch (error) {
      return ApiFailure(ErrorMapper.map(error));
    }
  }

  Future<ApiResult<List<String>>> suggest(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      return const ApiSuccess([]);
    }
    try {
      return ApiSuccess(await _api.mediaApi.suggest(trimmed));
    } catch (error) {
      return ApiFailure(ErrorMapper.map(error));
    }
  }

  List<String> history() {
    try {
      final raw = LocalStorage.searchHistoryBox().get(_historyKey);
      if (raw is List) {
        return raw.map((item) => item.toString()).toList();
      }
      return const [];
    } on CacheException {
      return const [];
    }
  }

  Future<void> addHistory(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final items = history().where((item) => item != trimmed).toList();
    items.insert(0, trimmed);
    await _writeHistory(items.take(AppConstants.searchHistoryLimit).toList());
  }

  Future<void> mergeHistory(List<String> keywords) async {
    final local = history();
    final seen = <String>{...local};
    final merged = [...local];
    for (final keyword in keywords) {
      final trimmed = keyword.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) {
        continue;
      }
      merged.add(trimmed);
    }
    if (merged.length == local.length) {
      return;
    }
    await _writeHistory(
      merged.take(AppConstants.searchHistoryLimit).toList(),
    );
  }

  Future<void> removeHistory(String keyword) {
    final items = history().where((item) => item != keyword).toList();
    return _writeHistory(items);
  }

  Future<void> _writeHistory(List<String> items) async {
    try {
      await LocalStorage.searchHistoryBox().put(_historyKey, items);
      _notify();
    } on CacheException {
      return;
    }
  }

  Future<void> clearHistory() async {
    try {
      await LocalStorage.clearSearchHistory();
      _notify();
    } on CacheException {
      return;
    }
  }

  int count() {
    return history().length;
  }

  void _notify() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
