import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/errors/app_exception.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/data/mock/mock_catalog.dart';
import 'package:yingjie/features/favorites/favorites_controller.dart';
import 'package:yingjie/models/video.dart';
import 'package:yingjie/services/favorite_service.dart';

class _FlakyFavorites extends FavoriteService {
  bool fail = true;

  @override
  List<Video> all() {
    if (fail) {
      throw const CacheException();
    }
    return super.all();
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_fav_ctrl_');
    await LocalStorage.initForTest(tempDir.path);
  });

  tearDown(() async {
    await LocalStorage.resetForTest();
  });

  test('empty favorites are empty status', () {
    final controller = FavoritesController(FavoriteService());
    expect(controller.state.status, FavoritesStatus.empty);
    expect(controller.state.items, isEmpty);
    controller.dispose();
  });

  test('loads stored favorites newest first', () async {
    final service = FavoriteService();
    await service.add(MockCatalog.videos[0]);
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await service.add(MockCatalog.videos[1]);
    final controller = FavoritesController(service);
    expect(controller.state.status, FavoritesStatus.success);
    expect(
      controller.state.items.map((item) => item.id).toList(),
      [MockCatalog.videos[1].id, MockCatalog.videos[0].id],
    );
    controller.dispose();
  });

  test('remove updates list and can become empty', () async {
    final service = FavoriteService();
    await service.add(MockCatalog.videos[0]);
    await service.add(MockCatalog.videos[1]);
    final controller = FavoritesController(service);
    await controller.remove(MockCatalog.videos[1].id);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.items.single.id, MockCatalog.videos[0].id);
    await controller.remove(MockCatalog.videos[0].id);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.status, FavoritesStatus.empty);
    controller.dispose();
  });

  test('detail-style toggle is reflected by the controller', () async {
    final service = FavoriteService();
    final controller = FavoritesController(service);
    expect(controller.state.status, FavoritesStatus.empty);
    await service.toggle(MockCatalog.videos[2]);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.status, FavoritesStatus.success);
    expect(controller.state.items.single.id, MockCatalog.videos[2].id);
    await service.toggle(MockCatalog.videos[2]);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.status, FavoritesStatus.empty);
    controller.dispose();
  });

  test('load failure can retry', () async {
    final service = _FlakyFavorites();
    final controller = FavoritesController(service);
    expect(controller.state.status, FavoritesStatus.error);
    expect(controller.state.error, isA<CacheException>());
    await service.add(MockCatalog.videos.first);
    service.fail = false;
    controller.load();
    expect(controller.state.status, FavoritesStatus.success);
    expect(controller.state.items, hasLength(1));
    controller.dispose();
  });
}
