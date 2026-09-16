import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/services/sync/backoff.dart';

void main() {
  test('base schedule doubles from 1 s and caps at 300 s', () {
    final b = Backoff();
    expect(b.baseFor(1), const Duration(seconds: 1));
    expect(b.baseFor(2), const Duration(seconds: 2));
    expect(b.baseFor(5), const Duration(seconds: 16));
    expect(b.baseFor(9), const Duration(seconds: 256));
    expect(b.baseFor(10), const Duration(seconds: 300));
    expect(b.baseFor(40), const Duration(seconds: 300));
  });

  test('next() applies at most ±20 % jitter and stays within bounds', () {
    final b = Backoff(random: Random(42));
    for (var n = 1; n <= 15; n++) {
      final d = b.next();
      final base = b.baseFor(n);
      expect(d.inMilliseconds, greaterThanOrEqualTo(max(1000, (base.inMilliseconds * 0.8).floor())));
      expect(d.inMilliseconds, lessThanOrEqualTo(min(300000, (base.inMilliseconds * 1.2).ceil())));
    }
    expect(b.attempt, 15);
  });

  test('reset() restarts from the minimum', () {
    final b = Backoff(jitter: 0);
    b.next();
    b.next();
    b.next();
    expect(b.next(), const Duration(seconds: 8));
    b.reset();
    expect(b.next(), const Duration(seconds: 1));
  });
}
