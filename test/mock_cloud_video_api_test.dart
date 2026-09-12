import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/errors/app_exception.dart';
import 'package:yingjie/data/mock/mock_auth_api.dart';
import 'package:yingjie/data/mock/mock_cloud_video_api.dart';
import 'package:yingjie/models/cloud_video.dart';
import 'package:yingjie/services/byte_source.dart';
import 'package:yingjie/services/upload_service.dart';

void main() {
  late MockAuthApi auth;
  late MockCloudVideoApi api;

  setUp(() {
    auth = MockAuthApi();
    api = MockCloudVideoApi(chunkSize: 4);
  });

  test('cloud videos are isolated by access token', () async {
    final alice = await auth.register(account: 'alice', password: 'secret');
    final bob = await auth.register(account: 'bob', password: 'secret');
    final created = await api.create(
      accessToken: alice.accessToken,
      title: 'alice-clip',
      sizeBytes: 8,
    );
    final aliceList = await api.list(accessToken: alice.accessToken);
    final bobList = await api.list(accessToken: bob.accessToken);
    expect(aliceList.map((item) => item.id), [created.id]);
    expect(bobList, isEmpty);
    await expectLater(
      api.get(accessToken: bob.accessToken, id: created.id),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('private videos stay out of the public list', () async {
    final session = await auth.register(account: 'alice', password: 'secret');
    await api.create(
      accessToken: session.accessToken,
      title: 'public',
      sizeBytes: 4,
    );
    final hidden = await api.create(
      accessToken: session.accessToken,
      title: 'secret',
      sizeBytes: 4,
      isPrivate: true,
    );
    final visible = await api.list(accessToken: session.accessToken);
    final all = await api.list(
      accessToken: session.accessToken,
      includePrivate: true,
    );
    expect(visible.map((item) => item.title), ['public']);
    expect(all.map((item) => item.title), containsAll(['public', 'secret']));
    expect(all.firstWhere((item) => item.id == hidden.id).isPrivate, isTrue);
  });

  test('chunked upload completes without keeping the whole file in the record',
      () async {
    final session = await auth.register(account: 'alice', password: 'secret');
    final created = await api.create(
      accessToken: session.accessToken,
      title: 'clip',
      sizeBytes: 8,
    );
    final upload = await api.startUpload(
      accessToken: session.accessToken,
      id: created.id,
    );
    expect(upload.chunkTotal, 2);
    await api.uploadChunk(
      accessToken: session.accessToken,
      id: created.id,
      uploadId: upload.uploadId,
      index: 0,
      bytes: const [1, 2, 3, 4],
    );
    await api.uploadChunk(
      accessToken: session.accessToken,
      id: created.id,
      uploadId: upload.uploadId,
      index: 1,
      bytes: const [5, 6, 7, 8],
    );
    final done = await api.completeUpload(
      accessToken: session.accessToken,
      id: created.id,
      uploadId: upload.uploadId,
    );
    expect(done.status, CloudVideoStatus.uploaded);
    expect(done.sizeBytes, 8);
  });

  test('upload service retries a failed chunk', () async {
    final session = await auth.register(account: 'alice', password: 'secret');
    final created = await api.create(
      accessToken: session.accessToken,
      title: 'clip',
      sizeBytes: 4,
    );
    api.onChunk = (id, index) => 1;
    final started = await api.startUpload(
      accessToken: session.accessToken,
      id: created.id,
    );
    final uploaded = await UploadService(chunkRetries: 2).upload(
      api: api,
      accessToken: session.accessToken,
      videoId: created.id,
      source: MemoryByteSource(const [1, 2, 3, 4]),
      session: started,
    );
    expect(uploaded.status, CloudVideoStatus.uploaded);
  });
}
