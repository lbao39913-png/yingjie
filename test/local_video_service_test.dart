import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/services/local_video_service.dart';

void main() {
  late Directory tempDir;
  late LocalVideoService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_local_video_');
    await LocalStorage.initForTest(tempDir.path);
    service = LocalVideoService();
  });

  tearDown(() async {
    service.dispose();
    await LocalStorage.resetForTest();
  });

  test('import stores metadata and remove only drops the list item', () async {
    final video = await service.import(
      title: 'clip.mp4',
      filePath: '/tmp/clip.mp4',
      sizeBytes: 2048,
    );
    expect(service.all(), hasLength(1));
    expect(service.getById(video.id)?.filePath, '/tmp/clip.mp4');
    await service.remove(video.id);
    expect(service.all(), isEmpty);
  });

  test('empty path is rejected', () async {
    expect(
      () => service.import(title: 'x', filePath: '  ', sizeBytes: 1),
      throwsA(isA<Exception>()),
    );
  });
}
