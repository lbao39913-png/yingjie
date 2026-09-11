import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/storage/token_store.dart';

void main() {
  group('MemoryTokenStore', () {
    test('saves and reads tokens', () async {
      final store = MemoryTokenStore();
      await store.save(accessToken: 'a1', refreshToken: 'r1');
      expect(await store.readAccessToken(), 'a1');
      expect(await store.readRefreshToken(), 'r1');
    });

    test('clear removes tokens', () async {
      final store = MemoryTokenStore();
      await store.save(accessToken: 'a1', refreshToken: 'r1');
      await store.clear();
      expect(await store.readAccessToken(), isNull);
      expect(await store.readRefreshToken(), isNull);
    });
  });
}
