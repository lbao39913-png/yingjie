import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/features/player/player_time.dart';

void main() {
  test('formats mm:ss and h:mm:ss', () {
    expect(formatPlayerTime(const Duration(seconds: 32)), '00:32');
    expect(formatPlayerTime(const Duration(minutes: 12, seconds: 35)), '12:35');
    expect(formatPlayerTime(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
  });

  test('formats current and duration range', () {
    expect(
      formatPlayerTimeRange(const Duration(seconds: 32), const Duration(minutes: 2)),
      '00:32 / 02:00',
    );
    expect(
      formatPlayerTimeRange(
        const Duration(hours: 1, minutes: 2, seconds: 3),
        const Duration(hours: 2),
      ),
      '1:02:03 / 2:00:00',
    );
  });
}
