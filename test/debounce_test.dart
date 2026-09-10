import 'package:flutter_test/flutter_test.dart';
import 'package:yingjie/core/utils/debounce.dart';

void main() {
  testWidgets('debouncer only runs the last action', (tester) async {
      var count = 0;
      var last = '';
      final debouncer = Debouncer(duration: const Duration(milliseconds: 400));

      debouncer.run(() {
        count++;
        last = 'a';
      });
      debouncer.run(() {
        count++;
        last = 'b';
      });
      debouncer.run(() {
        count++;
        last = 'c';
      });

      await tester.pump(const Duration(milliseconds: 399));
      expect(count, 0);

      await tester.pump(const Duration(milliseconds: 1));
      expect(count, 1);
      expect(last, 'c');
      debouncer.dispose();
  });
}
