import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/services/coordination/lease_manager.dart';
import 'package:sortie/services/coordination/read_guard.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1, 12);
  const cfg = SortConfig(mode: SortingMode.auto, leaveUntilRead: LeaveUntilRead.all, graceMinutes: 7);
  ReadGuard guard() => ReadGuard(timers: const LeaseTimers());

  ReadGuardVerdict eval(ReadGuard g, {SortMode mode = SortMode.moveAfterRead, bool seen = false, bool bulk = false, Set<String> held = const {}, Map<String, DateTime> closed = const {}, DateTime? now, SortConfig config = cfg}) =>
      g.evaluate(mid: 'm1', mode: mode, isSeen: seen, isBulk: bulk, heldMids: held, recentlyClosedAt: closed, serverNow: now ?? t0, config: config);

  test('suggestOnly / keep never auto-move', () {
    final g = guard();
    expect(eval(g, mode: SortMode.suggestOnly, seen: true).allowed, isFalse);
    expect(eval(g, mode: SortMode.keep, seen: true).allowed, isFalse);
  });

  test('unseen never moves under leaveUntilRead=all; moveNow ignores the seen rule', () {
    final g = guard();
    final v = eval(g);
    expect(v.allowed, isFalse);
    expect(v.reason, 'unseen');
    expect(v.retryAfter, isNull);
    expect(eval(g, mode: SortMode.moveNow).allowed, isTrue);
  });

  test('personalOnly waits only for non-bulk mail; none never waits', () {
    final g = guard();
    const personal = SortConfig(mode: SortingMode.auto, leaveUntilRead: LeaveUntilRead.personalOnly);
    expect(eval(g, bulk: true, config: personal).allowed, isTrue);
    expect(eval(g, bulk: false, config: personal).allowed, isFalse);
    const none = SortConfig(mode: SortingMode.auto, leaveUntilRead: LeaveUntilRead.none);
    expect(eval(g, config: none).allowed, isTrue);
  });

  test('seen moves after grace measured in server time', () {
    final g = guard();
    g.observeSeen('m1', t0);
    final v1 = eval(g, seen: true, now: t0.add(const Duration(minutes: 3)));
    expect(v1.allowed, isFalse);
    expect(v1.reason, 'grace');
    expect(v1.retryAfter, const Duration(minutes: 4));
    expect(eval(g, seen: true, now: t0.add(const Duration(minutes: 7))).allowed, isTrue);
  });

  test('first evaluation of a seen message starts the grace period itself', () {
    final g = guard();
    expect(eval(g, seen: true, now: t0).allowed, isFalse);
    expect(g.seenObservedAt('m1'), t0);
    expect(eval(g, seen: true, now: t0.add(const Duration(minutes: 7))).allowed, isTrue);
  });

  test('presence hold blocks even a moveNow decision', () {
    final g = guard();
    final v = eval(g, mode: SortMode.moveNow, held: {'m1'});
    expect(v.allowed, isFalse);
    expect(v.reason, 'open-elsewhere');
    expect(v.retryAfter, const Duration(seconds: 180));
  });

  test('recentlyClosed fast path: settle 30 s then move instead of full grace', () {
    final g = guard();
    final closedAt = t0;
    final early = eval(g, seen: true, closed: {'m1': closedAt}, now: t0.add(const Duration(seconds: 10)));
    expect(early.allowed, isFalse);
    expect(early.reason, 'settling');
    expect(early.retryAfter, const Duration(seconds: 20));
    final late = eval(g, seen: true, closed: {'m1': closedAt}, now: t0.add(const Duration(seconds: 30)));
    expect(late.allowed, isTrue);
    expect(late.reason, 'closed-elsewhere');
  });

  test('local open blocks; local close of a seen message allows immediately', () {
    final g = guard();
    g.onLocalOpen('m1');
    expect(eval(g, seen: true, mode: SortMode.moveNow).reason, 'open-here');
    g.onLocalClose('m1', t0);
    final v = eval(g, seen: true, now: t0.add(const Duration(seconds: 1)));
    expect(v.allowed, isTrue);
    expect(v.reason, 'closed-here');
    expect(eval(g, seen: false, now: t0.add(const Duration(seconds: 1))).reason, 'unseen');
  });
}
