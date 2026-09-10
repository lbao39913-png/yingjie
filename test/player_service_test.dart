import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/errors/app_exception.dart';
import 'package:yingjie/data/mock/mock_catalog.dart';
import 'package:yingjie/models/episode.dart';
import 'package:yingjie/models/play_source.dart';
import 'package:yingjie/models/video.dart';
import 'package:yingjie/services/player_service.dart';

void main() {
  test('resolves next and previous episodes', () {
    const source = PlaySource(
      id: 's1',
      name: '线路 1',
      episodes: [
        Episode(id: 'e1', name: '1', url: 'https://example.invalid/1.mp4'),
        Episode(id: 'e2', name: '2', url: 'https://example.invalid/2.mp4'),
      ],
    );

    expect(PlayerService().nextEpisode(source, 'e1')?.id, 'e2');
    expect(PlayerService().previousEpisode(source, 'e2')?.id, 'e1');
    expect(PlayerService().nextEpisode(source, 'e2'), isNull);
  });

  test('empty url is not playable', () {
    expect(
      () => PlayerService().ensurePlayable(
        const Episode(id: 'e', name: 'x', url: ''),
      ),
      throwsA(isA<PlaybackException>()),
    );
  });

  test('default source is the first one', () {
    const video = Video(
      id: 'v',
      title: 't',
      cover: 'c',
      sources: [
        PlaySource(id: 'a', name: 'A'),
        PlaySource(id: 'b', name: 'B'),
      ],
    );
    expect(PlayerService().resolveSource(video)?.id, 'a');
    expect(PlayerService().resolveSource(video, sourceId: 'b')?.id, 'b');
  });

  test('resolveLaunch fills mediaId title and playUrl', () {
    final video = MockCatalog.videos.first;
    final launch = PlayerService().resolveLaunch(video);
    expect(launch, isNotNull);
    expect(launch!.mediaId, video.id);
    expect(launch.title, video.title);
    expect(launch.playUrl, isNotEmpty);
    expect(launch.episodeId, isNotEmpty);
    expect(launch.sourceId, isNotEmpty);
    expect(launch.cover, video.cover);
    expect(launch.year, video.year);
    expect(launch.genres, video.genres);
  });

  test('resolveLaunch is null when no playable episode', () {
    const video = Video(id: 'x', title: 't', cover: 'c');
    expect(PlayerService().resolveLaunch(video), isNull);
  });

  test('resolveLaunch uses series title with episode name', () {
    final video = MockCatalog.videos.firstWhere(
      (item) => item.id == 'sample-series-a',
    );
    final launch = PlayerService().resolveLaunch(
      video,
      episodeId: 'sample-series-a-2',
    );
    expect(launch, isNotNull);
    expect(launch!.title, '示例剧集 A · 第2集');
    expect(launch.episodeId, 'sample-series-a-2');
    expect(launch.episodeName, '第2集');
    expect(launch.isTv, isTrue);
    expect(launch.playUrl, isNotEmpty);
  });
}
