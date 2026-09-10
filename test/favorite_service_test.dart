import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/errors/app_exception.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/data/mock/mock_catalog.dart';
import 'package:yingjie/models/playback_record.dart';
import 'package:yingjie/models/video.dart';
import 'package:yingjie/services/favorite_service.dart';
import 'package:yingjie/services/history_service.dart';

void main() {
  late Directory tempDir;
  late FavoriteService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_fav_');
    await LocalStorage.initForTest(tempDir.path);
    service = FavoriteService();
  });

  tearDown(() async {
    await LocalStorage.resetForTest();
  });

  test('toggle adds then removes a video', () async {
    final video = MockCatalog.videos.first;
    expect(service.contains(video.id), isFalse);
    expect(await service.toggle(video), isTrue);
    expect(service.contains(video.id), isTrue);
    expect(service.all().single.id, video.id);
    expect(await service.toggle(video), isFalse);
    expect(service.contains(video.id), isFalse);
    expect(service.all(), isEmpty);
  });

  test('empty id is ignored', () async {
    await service.add(const Video(id: '  ', title: 't', cover: 'c'));
    expect(service.all(), isEmpty);
    expect(service.contains(''), isFalse);
  });

  test('all returns newest favorites first', () async {
    final a = MockCatalog.videos[0];
    final b = MockCatalog.videos[1];
    final c = MockCatalog.videos[2];
    await service.add(a);
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await service.add(b);
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await service.add(c);
    expect(service.all().map((item) => item.id).toList(), [c.id, b.id, a.id]);
  });

  test('duplicate add keeps a single record', () async {
    final video = MockCatalog.videos.first;
    await service.add(video);
    await service.add(video);
    expect(service.all(), hasLength(1));
  });

  test('favorites survive hive reopen', () async {
    final video = MockCatalog.videos.first;
    await service.add(video);
    await LocalStorage.resetForTest();
    await LocalStorage.initForTest(tempDir.path);
    expect(FavoriteService().contains(video.id), isTrue);
    expect(FavoriteService().all().single.id, video.id);
  });

  test('all throws when hive is not ready', () async {
    await LocalStorage.resetForTest();
    expect(FavoriteService().all, throwsA(isA<CacheException>()));
  });

  test('count and clear remove every favorite', () async {
    await service.add(MockCatalog.videos[0]);
    await service.add(MockCatalog.videos[1]);
    expect(service.count(), 2);
    await service.clear();
    expect(service.count(), 0);
    expect(service.all(), isEmpty);
  });

  test('clearing favorites does not touch playback history', () async {
    final history = HistoryService();
    final video = MockCatalog.videos.first;
    await service.add(video);
    await history.save(
      PlaybackRecord(
        videoId: video.id,
        title: video.title,
        cover: '',
        episodeId: 'e1',
        episodeName: '',
        positionMs: 12000,
        durationMs: 120000,
        watchedAt: DateTime(2026, 9, 10),
      ),
    );
    await service.clear();
    expect(service.all(), isEmpty);
    expect(history.load(video.id)?.positionMs, 12000);
  });
}
