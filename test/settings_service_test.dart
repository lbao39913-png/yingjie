import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/services/settings_service.dart';

void main() {
  late Directory tempDir;
  late SettingsService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_settings_');
    await LocalStorage.initForTest(tempDir.path);
    service = SettingsService();
  });

  tearDown(() async {
    await LocalStorage.resetForTest();
  });

  test('defaults auto play on and auto return off', () {
    expect(service.autoPlay, isTrue);
    expect(service.autoReturnAfterCompletion, isFalse);
    expect(service.playSpeed, 1.0);
  });

  test('persists playback settings across reopen', () async {
    await service.setAutoPlay(false);
    await service.setAutoReturnAfterCompletion(true);
    await service.setPlaySpeed(1.5);
    await LocalStorage.resetForTest();
    await LocalStorage.initForTest(tempDir.path);
    final reopened = SettingsService();
    expect(reopened.autoPlay, isFalse);
    expect(reopened.autoReturnAfterCompletion, isTrue);
    expect(reopened.playSpeed, 1.5);
  });

  test('play speed snaps to whitelist', () async {
    await service.setPlaySpeed(1.1);
    expect(service.playSpeed, 1.0);
    await service.setPlaySpeed(1.2);
    expect(service.playSpeed, 1.25);
  });

  test('writes notify listeners', () async {
    var n = 0;
    final sub = service.changes.listen((_) => n += 1);
    await service.setAutoPlay(false);
    await Future<void>.delayed(Duration.zero);
    expect(n, 1);
    await sub.cancel();
  });
}
