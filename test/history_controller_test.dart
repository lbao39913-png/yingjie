import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/errors/app_exception.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/features/history/history_controller.dart';
import 'package:yingjie/models/playback_record.dart';
import 'package:yingjie/services/history_service.dart';

class _FlakyHistory extends HistoryService {
  bool fail = true;

  @override
  List<PlaybackRecord> all() {
    if (fail) {
      throw const CacheException();
    }
    return super.all();
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_hist_ctrl_');
    await LocalStorage.initForTest(tempDir.path);
  });

  tearDown(() async {
    await LocalStorage.resetForTest();
  });

  test('empty history is empty status', () {
    final controller = HistoryController(HistoryService());
    expect(controller.state.status, HistoryStatus.empty);
    expect(controller.state.items, isEmpty);
    controller.dispose();
  });

  test('loads stored history newest first', () async {
    final service = HistoryService();
    await service.save(_record('a', watchedAt: DateTime(2026, 1, 1)));
    await service.save(_record('b', watchedAt: DateTime(2026, 2, 1)));
    final controller = HistoryController(service);
    expect(controller.state.status, HistoryStatus.success);
    expect(
      controller.state.items.map((item) => item.videoId).toList(),
      ['b', 'a'],
    );
    controller.dispose();
  });

  test('remove updates list and can become empty', () async {
    final service = HistoryService();
    await service.save(_record('a'));
    await service.save(_record('b'));
    final controller = HistoryController(service);
    await controller.remove('b');
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.items.single.videoId, 'a');
    await controller.remove('a');
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.status, HistoryStatus.empty);
    controller.dispose();
  });

  test('clear empties history', () async {
    final service = HistoryService();
    await service.save(_record('a'));
    await service.save(_record('b'));
    final controller = HistoryController(service);
    await controller.clear();
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.status, HistoryStatus.empty);
    controller.dispose();
  });

  test('player-style save is reflected by the controller', () async {
    final service = HistoryService();
    final controller = HistoryController(service);
    expect(controller.state.status, HistoryStatus.empty);
    await service.save(_record('sintel'));
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.status, HistoryStatus.success);
    expect(controller.state.items.single.videoId, 'sintel');
    controller.dispose();
  });

  test('load failure can retry', () async {
    final service = _FlakyHistory();
    final controller = HistoryController(service);
    expect(controller.state.status, HistoryStatus.error);
    expect(controller.state.error, isA<CacheException>());
    await service.save(_record('sintel'));
    service.fail = false;
    controller.load();
    expect(controller.state.status, HistoryStatus.success);
    expect(controller.state.items, hasLength(1));
    controller.dispose();
  });
}

PlaybackRecord _record(
  String id, {
  DateTime? watchedAt,
}) {
  return PlaybackRecord(
    videoId: id,
    title: id,
    cover: '',
    episodeId: 'e1',
    episodeName: '',
    positionMs: 32000,
    durationMs: 120000,
    watchedAt: watchedAt ?? DateTime(2026, 9, 10),
  );
}
