import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/core/wake_detector.dart';

void main() {
  test('a wall-clock jump far beyond the tick interval is reported as a wake', () {
    fakeAsync((fa) {
      var now = DateTime.utc(2026, 1, 1);
      final d = WakeDetector(now: () => now);
      final wakes = <Duration>[];
      d.wakes.listen(wakes.add);
      d.start();
      // Normal ticking: the wall clock keeps pace with the timer.
      for (var i = 0; i < 5; i++) {
        now = now.add(const Duration(seconds: 20));
        fa.elapse(const Duration(seconds: 20));
      }
      expect(wakes, isEmpty);
      // Asleep for 40 minutes: the next tick sees the whole gap at once.
      now = now.add(const Duration(minutes: 40));
      fa.elapse(const Duration(seconds: 20));
      expect(wakes, [const Duration(minutes: 40)]);
      // A one-minute stall (GC, heavy load) is not a wake.
      now = now.add(const Duration(seconds: 80));
      fa.elapse(const Duration(seconds: 20));
      expect(wakes.length, 1);
      d.dispose();
      fa.flushMicrotasks();
    });
  });
}
