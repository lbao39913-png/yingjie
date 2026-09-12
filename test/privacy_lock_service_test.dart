import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/errors/app_exception.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/services/privacy_lock_service.dart';

void main() {
  late Directory tempDir;
  late PrivacyLockService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_privacy_');
    await LocalStorage.initForTest(tempDir.path);
    service = PrivacyLockService();
  });

  tearDown(() async {
    await LocalStorage.resetForTest();
  });

  test('stores hashed pin and rejects the wrong pin', () async {
    await service.setPin(userId: 'user-1', pin: '1234', confirmPin: '1234');
    expect(service.hasPin('user-1'), isTrue);
    expect(service.isUnlocked('user-1'), isTrue);
    service.lock();
    expect(service.isUnlocked('user-1'), isFalse);
    await expectLater(
      service.unlock(userId: 'user-1', pin: '0000'),
      throwsA(isA<AuthException>()),
    );
    expect(service.isUnlocked('user-1'), isFalse);
    await service.unlock(userId: 'user-1', pin: '1234');
    expect(service.isUnlocked('user-1'), isTrue);
    final raw = LocalStorage.settingsBox().values.map((item) => '$item').join();
    expect(raw.contains('1234'), isFalse);
  });

  test('mismatched confirm pin is rejected', () async {
    await expectLater(
      service.setPin(userId: 'user-1', pin: '1234', confirmPin: '4321'),
      throwsA(isA<AuthException>()),
    );
    expect(service.hasPin('user-1'), isFalse);
  });

  test('pins are isolated per user', () async {
    await service.setPin(userId: 'user-1', pin: '1111', confirmPin: '1111');
    service.lock();
    expect(service.hasPin('user-2'), isFalse);
    await service.setPin(userId: 'user-2', pin: '2222', confirmPin: '2222');
    service.lock();
    await expectLater(
      service.unlock(userId: 'user-2', pin: '1111'),
      throwsA(isA<AuthException>()),
    );
  });
}
