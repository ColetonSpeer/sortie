import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/core/clock.dart';
import 'package:sortie/services/coordination/server_clock.dart';

void main() {
  test('unprimed until first observation; now() throws', () {
    final c = ServerClock(FakeClock());
    expect(c.primed, isFalse);
    expect(() => c.now(), throwsStateError);
    expect(c.nowOrNull(), isNull);
  });

  test('now() = last INTERNALDATE + monotonic elapsed, unaffected by wall-clock jumps', () {
    final clock = FakeClock(DateTime.utc(2030, 5, 5));
    final c = ServerClock(clock);
    final server = DateTime.utc(2026, 1, 1, 12, 0, 0);
    c.observe(server);
    clock.advance(const Duration(seconds: 90));
    expect(c.now(), server.add(const Duration(seconds: 90)));
    clock.skew(const Duration(hours: -7)); // wall clock jumps back
    expect(c.now(), server.add(const Duration(seconds: 90)));
    clock.skew(const Duration(days: 400)); // and forward
    expect(c.now(), server.add(const Duration(seconds: 90)));
  });

  test('isExpired / untilExpiry use server time', () {
    final clock = FakeClock();
    final c = ServerClock(clock);
    final t0 = DateTime.utc(2026, 1, 1, 12);
    c.observe(t0);
    const ttl = Duration(seconds: 180);
    expect(c.isExpired(t0, ttl), isFalse);
    clock.advance(const Duration(seconds: 180));
    expect(c.isExpired(t0, ttl), isFalse, reason: 'fresh iff internalDate >= now - ttl');
    clock.advance(const Duration(seconds: 1));
    expect(c.isExpired(t0, ttl), isTrue);
    expect(c.untilExpiry(t0, ttl), Duration.zero);
    expect(c.untilExpiry(t0.add(const Duration(minutes: 10)), ttl), const Duration(minutes: 9, seconds: 59));
  });

  test('stale observations never move the estimate backwards', () {
    final clock = FakeClock();
    final c = ServerClock(clock);
    final t0 = DateTime.utc(2026, 1, 1, 12);
    c.observe(t0);
    clock.advance(const Duration(seconds: 60));
    c.observe(t0.add(const Duration(seconds: 10))); // an old INTERNALDATE
    expect(c.now(), t0.add(const Duration(seconds: 60)));
    c.observe(t0.add(const Duration(seconds: 61))); // server slightly ahead: accepted
    expect(c.now(), t0.add(const Duration(seconds: 61)));
  });
}
