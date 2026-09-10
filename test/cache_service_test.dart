import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/services/cache_service.dart';

void main() {
  test('zero bytes uses chinese empty cache label', () {
    final service = CacheService(
      measure: () async => 0,
      clear: () async {},
    );
    expect(service.sizeLabel(0), '暂无可清理缓存');
  });

  test('formats kb and mb without guessing', () {
    final service = CacheService(
      measure: () async => 0,
      clear: () async {},
    );
    expect(service.sizeLabel(2048), '缓存大小 2.0 KB');
    expect(service.sizeLabel(2 * 1024 * 1024), '缓存大小 2.0 MB');
  });

  test('clearCache uses injected clearer', () async {
    var cleared = false;
    final service = CacheService(
      measure: () async => 12,
      clear: () async {
        cleared = true;
      },
    );
    expect(await service.sizeBytes(), 12);
    await service.clearCache();
    expect(cleared, isTrue);
  });
}
