import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/app/app.dart';
import 'package:yingjie/core/providers/app_providers.dart';
import 'package:yingjie/data/api/api_provider.dart';
import 'package:yingjie/data/mock/mock_media_api.dart';
import 'package:yingjie/services/api_service.dart';

void main() {
  testWidgets('app shell shows Yingjie home', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(
            ApiService(
              ApiProvider(mediaApi: MockMediaApi(latency: Duration.zero)),
            ),
          ),
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
