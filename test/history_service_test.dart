import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/errors/app_exception.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/data/mock/mock_catalog.dart';
import 'package:yingjie/models/playback_record.dart';
import 'package:yingjie/services/favorite_service.dart';
import 'package:yingjie/services/history_service.dart';

void main() {
  late Directory tempDir;
  late HistoryService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_history_');
    await LocalStorage.initForTest(tempDir.path);
    service = HistoryService();
  });

  tearDown(() async {
    await LocalStorage.resetForTest();
  });

  test('saves and loads progress by mediaId', () async {
    await service.save(
      PlaybackRecord(
        videoId: 'sintel',
        title: 'Sintel',
        cover: '',
        episodeId: 'e1',
        episodeName: '',
        positionMs: 32000,
        durationMs: 120000,
        watchedAt: DateTime(2026, 9, 10),
      ),
    );
    expect(service.load('sintel')?.positionMs, 32000);
    await service.remove('sintel');
    expect(service.load('sintel'), isNull);
  });

  test('all returns newest watched first', () async {
    await service.save(_record('a', watchedAt: DateTime(2026, 1, 1)));
    await service.save(_record('b', watchedAt: DateTime(2026, 3, 1)));
    await service.save(_record('c', watchedAt: DateTime(2026, 2, 1)));
    expect(
      service.all().map((item) => item.videoId).toList(),
      ['b', 'c', 'a'],
    );
  });

  test('same mediaId overwrites previous progress', () async {
    await service.save(_record('sintel', positionMs: 12000));
    await service.save(_record('sintel', positionMs: 48000, title: 'Sintel'));
    expect(service.all(), hasLength(1));
    expect(service.load('sintel')?.positionMs, 48000);
    expect(service.load('sintel')?.title, 'Sintel');
  });

  test('all skips broken records', () async {
    await service.save(_record('sintel'));
    await LocalStorage.playbackHistoryBox().put('bad', 'not-a-map');
    await LocalStorage.playbackHistoryBox().put('empty', {'title': 'x'});
    expect(service.all().map((item) => item.videoId).toList(), ['sintel']);
    expect(service.load('bad'), isNull);
  });

  test('clear removes every playback record', () async {
    await service.save(_record('a'));
    await service.save(_record('b'));
    await service.clear();
    expect(service.all(), isEmpty);
    expect(service.load('a'), isNull);
  });

  test('count matches saved records', () async {
    await service.save(_record('a'));
    await service.save(_record('b'));
    expect(service.count(), 2);
    await service.clear();
    expect(service.count(), 0);
  });

  test('save remove and clear notify changes', () async {
    var count = 0;
    final sub = service.changes.listen((_) => count += 1);
    await service.save(_record('sintel'));
    await service.remove('sintel');
    await service.save(_record('sintel'));
    await service.clear();
    await Future<void>.delayed(Duration.zero);
    expect(count, 4);
    await sub.cancel();
  });

  test('clearing history does not touch favorites', () async {
    final favorites = FavoriteService();
    final video = MockCatalog.videos.first;
    await favorites.add(video);
    await service.save(_record(video.id));
    await service.clear();
    expect(service.all(), isEmpty);
    expect(favorites.contains(video.id), isTrue);
    expect(favorites.all().single.id, video.id);
  });

  test('all throws when hive is not ready', () async {
    await LocalStorage.resetForTest();
    expect(service.all, throwsA(isA<CacheException>()));
  });

  test('empty id is ignored', () async {
    await service.save(_record('  '));
    expect(service.all(), isEmpty);
    expect(service.load(''), isNull);
  });

  test('same show different episodes are stored separately', () async {
    await service.save(
      _record(
        'sample-series-a',
        title: '示例剧集 A',
        episodeId: 'sample-series-a-1',
        episodeName: '第1集',
        positionMs: 12000,
      ),
    );
    await service.save(
      _record(
        'sample-series-a',
        title: '示例剧集 A',
        episodeId: 'sample-series-a-2',
        episodeName: '第2集',
        positionMs: 48000,
        watchedAt: DateTime(2026, 9, 11),
      ),
    );
    expect(service.all(), hasLength(2));
    expect(
      service.load('sample-series-a', episodeId: 'sample-series-a-1')?.positionMs,
      12000,
    );
    expect(
      service.load('sample-series-a', episodeId: 'sample-series-a-2')?.positionMs,
      48000,
    );
    await service.remove('sample-series-a', episodeId: 'sample-series-a-1');
    expect(service.all(), hasLength(1));
    expect(service.all().single.episodeId, 'sample-series-a-2');
  });

  test('legacy movie key still loads without episodeId', () async {
    await service.save(_record('sintel', title: 'Sintel'));
    expect(service.load('sintel')?.title, 'Sintel');
    expect(service.load('sintel', episodeId: 'e1')?.positionMs, 32000);
  });
}

PlaybackRecord _record(
  String id, {
  String? title,
  int positionMs = 32000,
  DateTime? watchedAt,
  String episodeId = 'e1',
  String episodeName = '',
}) {
  return PlaybackRecord(
    videoId: id,
    title: title ?? id,
    cover: '',
    episodeId: episodeId,
    episodeName: episodeName,
    positionMs: positionMs,
    durationMs: 120000,
    watchedAt: watchedAt ?? DateTime(2026, 9, 10),
  );
}
