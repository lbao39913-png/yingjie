import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/models/playback_record.dart';

void main() {
  final record = PlaybackRecord(
    videoId: 'sintel',
    title: 'Sintel',
    cover: 'https://example.invalid/s.jpg',
    episodeId: 'e1',
    episodeName: '1',
    positionMs: 32000,
    durationMs: 120000,
    watchedAt: DateTime(2026, 9, 10, 12),
    year: 2010,
    genres: ['动画', '奇幻'],
  );

  test('watched percent uses position against duration', () {
    expect(record.progress, closeTo(32 / 120, 0.0001));
    expect(record.watchedPercent, 27);
    expect(
      PlaybackRecord(
        videoId: 'x',
        title: 'x',
        cover: '',
        episodeId: '',
        episodeName: '',
        positionMs: 10,
        durationMs: 0,
        watchedAt: DateTime(2026, 1, 1),
      ).watchedPercent,
      0,
    );
  });

  test('relative watched label uses chinese units', () {
    final now = DateTime(2026, 9, 10, 18);
    expect(
      record.relativeWatchedLabel(DateTime(2026, 9, 10, 12, 0, 20)),
      '刚刚',
    );
    expect(
      PlaybackRecord(
        videoId: 'x',
        title: 'x',
        cover: '',
        episodeId: '',
        episodeName: '',
        positionMs: 1,
        durationMs: 10,
        watchedAt: now.subtract(const Duration(minutes: 3)),
      ).relativeWatchedLabel(now),
      '3分钟前',
    );
    expect(
      PlaybackRecord(
        videoId: 'x',
        title: 'x',
        cover: '',
        episodeId: '',
        episodeName: '',
        positionMs: 1,
        durationMs: 10,
        watchedAt: now.subtract(const Duration(hours: 5)),
      ).relativeWatchedLabel(now),
      '5小时前',
    );
    expect(
      PlaybackRecord(
        videoId: 'x',
        title: 'x',
        cover: '',
        episodeId: '',
        episodeName: '',
        positionMs: 1,
        durationMs: 10,
        watchedAt: now.subtract(const Duration(days: 2)),
      ).relativeWatchedLabel(now),
      '2天前',
    );
    expect(
      PlaybackRecord(
        videoId: 'x',
        title: 'x',
        cover: '',
        episodeId: '',
        episodeName: '',
        positionMs: 1,
        durationMs: 10,
        watchedAt: DateTime(2026, 1, 8),
      ).relativeWatchedLabel(now),
      '2026-01-08',
    );
  });

  test('json keeps cover year and genres', () {
    final parsed = PlaybackRecord.fromJson(record.toJson());
    expect(parsed.cover, record.cover);
    expect(parsed.year, 2010);
    expect(parsed.genres, ['动画', '奇幻']);
    expect(parsed.positionMs, 32000);
  });

  test('displayTitle appends episode name for series', () {
    expect(record.displayTitle, 'Sintel · 1');
    expect(
      PlaybackRecord(
        videoId: 's',
        title: '示例剧集 A',
        cover: '',
        episodeId: '1',
        episodeName: '第1集',
        positionMs: 1,
        durationMs: 10,
        watchedAt: DateTime(2026, 1, 1),
      ).displayTitle,
      '示例剧集 A · 第1集',
    );
    expect(
      PlaybackRecord(
        videoId: 's',
        title: 'Sintel',
        cover: '',
        episodeId: 'e1',
        episodeName: '正片',
        positionMs: 1,
        durationMs: 10,
        watchedAt: DateTime(2026, 1, 1),
      ).displayTitle,
      'Sintel',
    );
  });
}
