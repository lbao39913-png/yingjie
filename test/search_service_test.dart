import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/errors/app_exception.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/data/api/api_provider.dart';
import 'package:yingjie/data/mock/mock_media_api.dart';
import 'package:yingjie/models/paged_result.dart';
import 'package:yingjie/models/video.dart';
import 'package:yingjie/services/search_service.dart';

void main() {
  late Directory tempDir;
  late SearchService service;
  late _CountingMockMediaApi api;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_search_');
    await LocalStorage.initForTest(tempDir.path);
    api = _CountingMockMediaApi(latency: Duration.zero);
    service = SearchService(ApiProvider(mediaApi: api));
  });

  tearDown(() async {
    await LocalStorage.resetForTest();
  });

  test('empty keyword does not hit api or history', () async {
    final result = await service.search('   ');
    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull?.items, isEmpty);
    expect(api.searchCalls, 0);
    expect(service.history(), isEmpty);
  });

  test('normal search returns matching video', () async {
    final result = await service.search('Sintel');
    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull?.items.single.id, 'sintel');
    expect(api.searchCalls, 1);
  });

  test('search success stores history', () async {
    await service.search('Sintel');
    expect(service.history(), ['Sintel']);
  });

  test('search with no results stays successful and empty', () async {
    final result = await service.search('zzzz-not-found');
    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull?.items, isEmpty);
  });

  test('search failure maps to chinese network error', () async {
    api.failSearch = true;
    final result = await service.search('Sintel');
    expect(result.isSuccess, isFalse);
    expect(
      result.when(success: (_) => null, failure: (error) => error),
      isA<NetworkException>(),
    );
    expect(
      result.when(success: (_) => '', failure: (error) => error.message),
      '网络连接失败，请检查网络',
    );
    expect(service.history(), isEmpty);
  });

  test('history can delete one keyword', () async {
    await service.addHistory('Sintel');
    await service.addHistory('Bunny');
    await service.removeHistory('Sintel');
    expect(service.history(), ['Bunny']);
  });

  test('history can be cleared', () async {
    await service.addHistory('Sintel');
    await service.clearHistory();
    expect(service.history(), isEmpty);
  });

  test('count and changes follow history edits', () async {
    var n = 0;
    final sub = service.changes.listen((_) => n += 1);
    await service.addHistory('Sintel');
    expect(service.count(), 1);
    await service.removeHistory('Sintel');
    await service.addHistory('Bunny');
    await service.clearHistory();
    await Future<void>.delayed(Duration.zero);
    expect(service.count(), 0);
    expect(n, 4);
    await sub.cancel();
  });

  test('search paginates without mixing pages', () async {
    final page1 = await service.search('for', page: 1, pageSize: 2);
    final page2 = await service.search('for', page: 2, pageSize: 2);
    final first = page1.dataOrNull!;
    final second = page2.dataOrNull!;
    expect(first.items, hasLength(2));
    expect(first.hasMore, isTrue);
    expect(second.items, isNotEmpty);
    expect(second.items.first.id, isNot(first.items.first.id));
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
