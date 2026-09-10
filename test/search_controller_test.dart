import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/errors/app_exception.dart';
import 'package:yingjie/data/api/api_provider.dart';
import 'package:yingjie/data/mock/mock_media_api.dart';
import 'package:yingjie/features/search/search_controller.dart';
import 'package:yingjie/models/paged_result.dart';
import 'package:yingjie/models/video.dart';
import 'package:yingjie/services/search_service.dart';

void main() {
  SearchController buildController(_CountingMockMediaApi api, {int pageSize = 6}) {
    return SearchController(
      SearchService(ApiProvider(mediaApi: api)),
      pageSize: pageSize,
      debounce: Duration.zero,
    );
  }

  test('empty keyword stays initial and skips api', () async {
    final api = _CountingMockMediaApi(latency: Duration.zero);
    final controller = buildController(api);
    await controller.submit('   ');
    expect(controller.state.status, SearchStatus.initial);
    expect(controller.state.results, isEmpty);
    expect(api.searchCalls, 0);
    controller.dispose();
  });

  test('normal search succeeds', () async {
    final api = _CountingMockMediaApi(latency: Duration.zero);
    final controller = buildController(api);
    await controller.submit('Sintel');
    expect(controller.state.status, SearchStatus.success);
    expect(controller.state.results.single.id, 'sintel');
    expect(controller.state.query, 'Sintel');
    controller.dispose();
  });

  test('search with no results is empty', () async {
    final api = _CountingMockMediaApi(latency: Duration.zero);
    final controller = buildController(api);
    await controller.submit('zzzz-not-found');
    expect(controller.state.status, SearchStatus.empty);
    expect(controller.state.results, isEmpty);
    controller.dispose();
  });

  test('search failure keeps chinese error', () async {
    final api = _CountingMockMediaApi(latency: Duration.zero)..failSearch = true;
    final controller = buildController(api);
    await controller.submit('Sintel');
    expect(controller.state.status, SearchStatus.error);
    expect(controller.state.error, isA<NetworkException>());
    expect(controller.state.error?.message, '网络连接失败，请检查网络');
    controller.dispose();
  });

  test('loadMore appends results and keeps previous items', () async {
    final api = _CountingMockMediaApi(latency: Duration.zero);
    final controller = buildController(api, pageSize: 2);
    await controller.submit('for');
    final first = List<Video>.from(controller.state.results);
    expect(first, hasLength(2));
    await controller.loadMore();
    expect(controller.state.results.length, greaterThan(first.length));
    expect(controller.state.results.take(2).map((item) => item.id), first.map((item) => item.id));
    expect(controller.state.page, 2);
    controller.dispose();
  });

  test('duplicate in-flight search is ignored', () async {
    final api = _CountingMockMediaApi(latency: const Duration(milliseconds: 40));
    final controller = buildController(api);
    final first = controller.submit('Sintel');
    final second = controller.submit('Sintel');
    await Future.wait([first, second]);
    expect(api.searchCalls, 1);
    expect(controller.state.status, SearchStatus.success);
    controller.dispose();
  });

  test('refresh failure keeps existing results', () async {
    final api = _CountingMockMediaApi(latency: Duration.zero);
    final controller = buildController(api);
    await controller.submit('Sintel');
    expect(controller.state.results, isNotEmpty);
    api.failSearch = true;
    await controller.refresh();
    expect(controller.state.status, SearchStatus.success);
    expect(controller.state.results.single.id, 'sintel');
    expect(controller.state.refreshing, isFalse);
    controller.dispose();
  });

  testWidgets('suggestions are debounced', (tester) async {
      final api = _CountingMockMediaApi(latency: Duration.zero);
      final controller = SearchController(
        SearchService(ApiProvider(mediaApi: api)),
        debounce: const Duration(milliseconds: 400),
      );
      controller.onQueryChanged('s');
      controller.onQueryChanged('si');
      controller.onQueryChanged('sin');
      await tester.pump(const Duration(milliseconds: 399));
      expect(api.suggestCalls, 0);
      await tester.pump(const Duration(milliseconds: 1));
      expect(api.suggestCalls, 1);
      expect(controller.state.suggestions, contains('Sintel'));
      controller.dispose();
  });
}

class _CountingMockMediaApi extends MockMediaApi {
  _CountingMockMediaApi({super.latency});

  int searchCalls = 0;
  int suggestCalls = 0;
  bool failSearch = false;

  @override
  Future<PagedResult<Video>> search(
    String keyword, {
    int page = 1,
    int pageSize = 12,
  }) {
    searchCalls++;
    if (failSearch) {
      throw const NetworkException();
    }
    return super.search(keyword, page: page, pageSize: pageSize);
  }

  @override
  Future<List<String>> suggest(String keyword) {
    suggestCalls++;
    return super.suggest(keyword);
  }
}
