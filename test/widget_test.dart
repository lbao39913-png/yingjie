import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/app/app.dart';
import 'package:yingjie/core/providers/app_providers.dart';
import 'package:yingjie/core/storage/token_store.dart';
import 'package:yingjie/data/api/api_provider.dart';
import 'package:yingjie/data/mock/mock_auth_api.dart';
import 'package:yingjie/data/mock/mock_cloud_sync_api.dart';
import 'package:yingjie/data/mock/mock_media_api.dart';
import 'package:yingjie/services/api_service.dart';
import 'package:yingjie/services/auth_service.dart';
import 'package:yingjie/services/favorite_service.dart';
import 'package:yingjie/services/history_service.dart';
import 'package:yingjie/services/search_service.dart';
import 'package:yingjie/services/settings_service.dart';
import 'package:yingjie/services/sync_service.dart';

void main() {
  testWidgets('app shell shows Yingjie home', (tester) async {
    final mediaApi = ApiProvider(
      mediaApi: MockMediaApi(latency: Duration.zero),
    );
    final favorites = FavoriteService();
    final history = HistoryService();
    final search = SearchService(mediaApi);
    final auth = AuthService(
      api: MockAuthApi(),
      tokens: MemoryTokenStore(),
      sync: SyncService(
        api: MockCloudSyncApi(),
        favorites: favorites,
        history: history,
        search: search,
        settings: SettingsService(),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(ApiService(mediaApi)),
          authServiceProvider.overrideWithValue(auth),
        ],
        child: const YingjieApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('影界'), findsWidgets);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('搜索影片、演员、导演'), findsOneWidget);
  });
}
