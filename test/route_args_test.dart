import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/app/route_args.dart';

void main() {
  test('player args keep mediaId title and playUrl', () {
    const args = PlayerRouteArgs(
      mediaId: 'sintel',
      title: 'Sintel',
      playUrl: 'https://example.invalid/s.mp4',
      episodeId: 'e1',
      sourceId: 's1',
    );
    expect(args.toQuery(), {
      'title': 'Sintel',
      'playUrl': 'https://example.invalid/s.mp4',
      'episodeId': 'e1',
      'sourceId': 's1',
    });

    final parsed = PlayerRouteArgs.parse(
      id: 'sintel',
      query: args.toQuery(),
    );
    expect(parsed.mediaId, 'sintel');
    expect(parsed.title, 'Sintel');
    expect(parsed.playUrl, 'https://example.invalid/s.mp4');
  });

  test('detail args trim id', () {
    expect(DetailRouteArgs.parse('  abc  ').id, 'abc');
    expect(DetailRouteArgs.parse(null).id, isEmpty);
  });
}
