import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/models/episode.dart';
import 'package:yingjie/models/play_source.dart';
import 'package:yingjie/models/video.dart';

void main() {
  test('heroImage falls back to cover', () {
    const video = Video(id: '1', title: 't', cover: 'cover.png');
    expect(video.heroImage, 'cover.png');
  });

  test('heroImage prefers backdrop', () {
    const video = Video(
      id: '1',
      title: 't',
      cover: 'cover.png',
      backdrop: 'back.png',
    );
    expect(video.heroImage, 'back.png');
  });

  test('playUrl reads first episode', () {
    const video = Video(
      id: '1',
      title: 't',
      cover: 'c',
      sources: [
        PlaySource(
          id: 's',
          name: 's',
          episodes: [Episode(id: 'e', name: '1', url: 'https://x/a.mp4')],
        ),
      ],
    );
    expect(video.playUrl, 'https://x/a.mp4');
  });

  test('durationLabel formats minutes', () {
    const video = Video(
      id: '1',
      title: 't',
      cover: 'c',
      durationMinutes: 15,
    );
    expect(video.durationLabel, '15 分钟');
  });

  test('fromJson accepts missing sources and top-level playUrl', () {
    final video = Video.fromJson({
      'id': 12,
      'title': 'X',
      'cover': 'c',
      'year': '2010',
      'rating': '8.2',
      'playUrl': 'https://example.invalid/a.mp4',
    });
    expect(video.id, '12');
    expect(video.year, 2010);
    expect(video.rating, 8.2);
    expect(video.playUrl, 'https://example.invalid/a.mp4');
    expect(video.isMovie, isTrue);
    expect(video.type, MediaType.movie);
  });

  test('fromJson top-level episodes become a default source', () {
    final video = Video.fromJson({
      'id': 's',
      'title': '剧',
      'cover': 'c',
      'episodes': [
        {'id': '1', 'name': '第1集', 'url': 'https://example.invalid/1.mp4'},
        {'id': '2', 'name': '第2集', 'url': 'https://example.invalid/2.mp4'},
      ],
    });
    expect(video.isTv, isTrue);
    expect(video.episodeCount, 2);
    expect(video.episodes.first.resolvedUrl, 'https://example.invalid/1.mp4');
    expect(video.playerTitleFor(video.episodes[1]), '剧 · 第2集');
  });

  test('fromJson ignores broken source payloads', () {
    final video = Video.fromJson({
      'id': 's',
      'title': 'T',
      'cover': 'c',
      'sources': 'bad',
      'episodes': 1,
    });
    expect(video.sources, isEmpty);
    expect(video.playUrl, isNull);
  });

  test('episode falls back to nested video sources', () {
    final episode = Episode.fromJson({
      'id': 'e',
      'name': '第3集',
      'sources': [
        {'url': 'https://example.invalid/a.mp4', 'quality': '720p'},
      ],
    });
    expect(episode.resolvedUrl, 'https://example.invalid/a.mp4');
    expect(episode.quality, '720p');
    expect(episode.number, 3);
  });
}
