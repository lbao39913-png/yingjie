import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/storage/local_storage.dart';
import 'package:yingjie/core/storage/token_store.dart';
import 'package:yingjie/data/mock/mock_auth_api.dart';
import 'package:yingjie/data/mock/mock_cloud_video_api.dart';
import 'package:yingjie/models/cloud_video.dart';
import 'package:yingjie/models/local_video.dart';
import 'package:yingjie/services/byte_source.dart';
import 'package:yingjie/services/cloud_video_service.dart';
import 'package:yingjie/services/local_video_service.dart';
import 'package:yingjie/services/upload_service.dart';

void main() {
  late Directory tempDir;
  late MockAuthApi authApi;
  late MockCloudVideoApi videoApi;
  late MemoryTokenStore tokens;
  late CloudVideoService cloud;
  late LocalVideoService local;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yingjie_cloud_video_');
    await LocalStorage.initForTest(tempDir.path);
    authApi = MockAuthApi();
    videoApi = MockCloudVideoApi(chunkSize: 4);
    tokens = MemoryTokenStore();
    cloud = CloudVideoService(
      api: videoApi,
      tokens: tokens,
      upload: UploadService(chunkRetries: 1),
    );
    local = LocalVideoService();
  });

  tearDown(() async {
    cloud.dispose();
    local.dispose();
    await LocalStorage.resetForTest();
  });

  Future<String> login(String account) async {
    final session = await authApi.register(account: account, password: 'secret');
    await tokens.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session.user.id;
  }

  test('upload from local keeps the local item', () async {
    final userId = await login('alice');
    final imported = await local.import(
      title: 'clip',
      filePath: '/tmp/clip.mp4',
      sizeBytes: 8,
    );
    final uploaded = await cloud.uploadFromLocal(
      local: imported,
      source: MemoryByteSource(const [1, 2, 3, 4, 5, 6, 7, 8]),
    );
    expect(uploaded.status, CloudVideoStatus.uploaded);
    expect(uploaded.userId, userId);
    expect(local.getById(imported.id), isNotNull);
    expect(cloud.cachedPublic(userId), hasLength(1));
  });

  test('deleting cloud does not remove the local import', () async {
    await login('alice');
    final imported = await local.import(
      title: 'clip',
      filePath: '/tmp/clip.mp4',
      sizeBytes: 4,
    );
    final uploaded = await cloud.uploadFromLocal(
      local: imported,
      source: MemoryByteSource(const [1, 2, 3, 4]),
    );
    await cloud.deleteCloud(uploaded.id);
    expect(local.getById(imported.id), isNotNull);
    expect(cloud.cachedPublic(uploaded.userId), isEmpty);
  });

  test('private videos are hidden from the public cache', () async {
    final userId = await login('alice');
    final imported = await local.import(
      title: 'clip',
      filePath: '/tmp/clip.mp4',
      sizeBytes: 4,
    );
    final uploaded = await cloud.uploadFromLocal(
      local: imported,
      source: MemoryByteSource(const [9, 8, 7, 6]),
    );
    await cloud.setPrivate(id: uploaded.id, isPrivate: true);
    expect(cloud.cachedPublic(userId), isEmpty);
    expect(cloud.cachedPrivate(userId).map((item) => item.id), [uploaded.id]);
  });

  test('play url falls back to the local file for mock cloud', () async {
    await login('alice');
    const video = LocalVideo(
      id: 'local-1',
      title: 'clip',
      filePath: '/tmp/clip.mp4',
      sizeBytes: 4,
    );
    final uploaded = await cloud.uploadFromLocal(
      local: video,
      source: MemoryByteSource(const [1, 2, 3, 4]),
    );
    final url = await cloud.playUrlFor(uploaded);
    expect(url.startsWith('file:'), isTrue);
    expect(url.contains('clip.mp4'), isTrue);
  });
}
