import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/core/clock.dart';
import 'package:sortie/data/coordination/control_folder.dart';
import 'package:sortie/services/coordination/control_messages.dart';
import 'package:sortie/services/coordination/lease_manager.dart';
import 'package:sortie/services/coordination/server_clock.dart';

import 'harness.dart';

/// Header-only control message builder for pure evaluation tests.
ControlMessage msg(int uid, String type, String dev, DateTime at, {int? epoch, int? priority, int? upto}) => ControlMessage(
      uid: uid,
      internalDate: at,
      type: type,
      deviceId: dev,
      messageId: '<$type-$dev-$uid@sortie.invalid>',
      seq: uid,
      epoch: epoch,
      priority: priority,
      snapshotUpto: upto,
    );

void main() {
  final t0 = DateTime.utc(2026, 1, 1, 12);
  const ttl = Duration(seconds: 180);

  /// Pure evaluator; the folder is never touched.
  LeaseManager pure(String me, {int priority = 30}) {
    final clock = FakeClock();
    final sc = ServerClock(clock)..observe(t0);
    return LeaseManager(folder: _NoFolder(), serverClock: sc, me: Harness.identity(me, priority: priority), timers: const LeaseTimers());
  }

  group('evaluate', () {
    test('single claim of epoch 1 is the active lease', () {
      final e = pure('a').evaluate([msg(1, 'lease-claim', 'a', t0, epoch: 1, priority: 30)], serverNow: t0.add(const Duration(seconds: 30)));
      expect(e.activeLease?.deviceId, 'a');
      expect(e.activeLease?.epoch, 1);
      expect(e.epochMax, 1);
      expect(e.voidClaims, isEmpty);
    });

    test('same-second claims: higher priority wins, equal priority -> smaller deviceId', () {
      final m = pure('x');
      final byPriority = m.evaluate([
        msg(1, 'lease-claim', 'bbb', t0, epoch: 1, priority: 15),
        msg(2, 'lease-claim', 'aaa', t0, epoch: 1, priority: 30),
      ], serverNow: t0);
      expect(byPriority.activeLease?.deviceId, 'aaa');
      expect(byPriority.voidClaims.map((c) => c.deviceId), ['bbb']);
      final byId = m.evaluate([
        msg(1, 'lease-claim', 'bbb', t0, epoch: 1, priority: 30),
        msg(2, 'lease-claim', 'aaa', t0, epoch: 1, priority: 30),
      ], serverNow: t0);
      expect(byId.activeLease?.deviceId, 'aaa');
      expect(byId.voidClaims.single.deviceId, 'bbb');
    });

    test('earlier INTERNALDATE wins within an epoch regardless of priority', () {
      final e = pure('x').evaluate([
        msg(1, 'lease-claim', 'low', t0, epoch: 1, priority: 10),
        msg(2, 'lease-claim', 'high', t0.add(const Duration(seconds: 1)), epoch: 1, priority: 30),
      ], serverNow: t0);
      expect(e.activeLease?.deviceId, 'low');
      expect(e.voidClaims.single.deviceId, 'high');
    });

    test('late claimant with a higher epoch while the lease is fresh is illegitimate', () {
      final e = pure('x').evaluate([
        msg(1, 'lease-claim', 'a', t0, epoch: 1, priority: 30),
        msg(2, 'lease-beat', 'a', t0.add(const Duration(seconds: 60)), epoch: 1),
        msg(3, 'lease-claim', 'b', t0.add(const Duration(seconds: 90)), epoch: 2, priority: 30),
      ], serverNow: t0.add(const Duration(seconds: 100)));
      expect(e.activeLease?.deviceId, 'a');
      expect(e.voidClaims.single.deviceId, 'b');
      expect(e.epochMax, 2);
    });

    test('claim after the previous lease expired is legitimate; freshness uses lastBeat + TTL', () {
      final m = pure('x');
      final msgs = [
        msg(1, 'lease-claim', 'a', t0, epoch: 1, priority: 30),
        msg(2, 'lease-beat', 'a', t0.add(const Duration(seconds: 60)), epoch: 1),
        msg(3, 'lease-claim', 'b', t0.add(const Duration(seconds: 60) + ttl + const Duration(seconds: 5)), epoch: 2, priority: 30),
      ];
      final now = t0.add(const Duration(seconds: 60) + ttl + const Duration(seconds: 10));
      final e = m.evaluate(msgs, serverNow: now);
      expect(e.activeLease?.deviceId, 'b');
      expect(e.activeLease?.epoch, 2);
      expect(e.voidClaims, isEmpty);
      // Before b's claim existed, a's lease had simply expired: nobody leads.
      final expired = m.evaluate(msgs.sublist(0, 2), serverNow: now);
      expect(expired.activeLease, isNull);
      expect(expired.epochMax, 1);
    });

    test('release makes a follow-up claim legitimate and the released lease unfresh', () {
      final e = pure('x').evaluate([
        msg(1, 'lease-claim', 'a', t0, epoch: 1, priority: 30),
        msg(2, 'lease-release', 'a', t0.add(const Duration(seconds: 30)), epoch: 1),
        msg(3, 'lease-claim', 'b', t0.add(const Duration(seconds: 40)), epoch: 2, priority: 30),
      ], serverNow: t0.add(const Duration(seconds: 45)));
      expect(e.activeLease?.deviceId, 'b');
      expect(e.holders[1]?.released, isTrue);
    });

    test('preemption: a higher-priority claim of the next epoch is legitimate', () {
      final e = pure('x').evaluate([
        msg(1, 'lease-claim', 'phone', t0, epoch: 1, priority: 15),
        msg(2, 'lease-beat', 'phone', t0.add(const Duration(seconds: 60)), epoch: 1),
        msg(3, 'lease-claim', 'desk', t0.add(const Duration(seconds: 70)), epoch: 2, priority: 30),
      ], serverNow: t0.add(const Duration(seconds: 75)));
      expect(e.activeLease?.deviceId, 'desk');
      expect(e.activeLease?.epoch, 2);
    });

    test('a device may supersede its own fresh lease with a new epoch', () {
      final e = pure('a').evaluate([
        msg(1, 'lease-claim', 'a', t0, epoch: 1, priority: 30),
        msg(2, 'lease-claim', 'a', t0.add(const Duration(seconds: 10)), epoch: 2, priority: 30),
      ], serverNow: t0.add(const Duration(seconds: 15)));
      expect(e.activeLease?.epoch, 2);
      expect(e.voidClaims, isEmpty);
    });

    test('snapshot lastEpoch counts towards epochMax', () {
      final e = pure('a').evaluate([msg(1, 'snapshot', 'a', t0, epoch: 7, upto: 100)], serverNow: t0);
      expect(e.activeLease, isNull);
      expect(e.epochMax, 7);
    });

    test('shouldPreempt only when strictly higher priority than the holder', () {
      final claims = [msg(1, 'lease-claim', Harness.idOf('holder'), t0, epoch: 1, priority: 20)];
      expect(pure('me', priority: 30).shouldPreempt(pure('me', priority: 30).evaluate(claims, serverNow: t0)), isTrue);
      expect(pure('me', priority: 20).shouldPreempt(pure('me', priority: 20).evaluate(claims, serverNow: t0)), isFalse);
      expect(pure('holder', priority: 100).shouldPreempt(pure('holder', priority: 100).evaluate(claims, serverNow: t0)), isFalse);
    });
  });

  group('claiming over the fake server', () {
    test('unprimed device refuses to claim and appends nothing', () {
      fakeAsync((fa) {
        final h = Harness(fa);
        final clock = FakeAsyncClock(fa);
        final folder = h.wait(h.rawControl(clock));
        final lm = LeaseManager(folder: folder, serverClock: ServerClock(clock), me: Harness.identity('a'), timers: const LeaseTimers());
        final r = h.wait(lm.tryClaim(skipBackoff: true));
        expect(r.refused, isTrue);
        expect(r.won, isFalse);
        expect(h.ofType('lease-claim'), isEmpty);
        h.wait(folder.dispose());
      });
    });

    test('late claimant sees a fresh lease and does not claim; a planted void claim is cleaned up by its owner', () {
      fakeAsync((fa) {
        final h = Harness(fa);
        final clockA = FakeAsyncClock(fa);
        final clockB = FakeAsyncClock(fa, skew: const Duration(minutes: 30));
        final fa0 = h.wait(h.rawControl(clockA));
        final fb = h.wait(h.rawControl(clockB));
        final scA = ServerClock(clockA);
        final scB = ServerClock(clockB);
        final a = LeaseManager(folder: fa0, serverClock: scA, me: Harness.identity('aaa'), timers: const LeaseTimers());
        final b = LeaseManager(folder: fb, serverClock: scB, me: Harness.identity('bbb'), timers: const LeaseTimers());
        // Prime both clocks with a presence-like append.
        final aId = Harness.idOf('aaa');
        final bId = Harness.idOf('bbb');
        scA.observe(h.wait(fa0.append(ControlMessageDraft(type: 'presence', deviceId: aId, messageId: '<presence-aaa-1@sortie.invalid>', seq: 1, body: const {}))).internalDate);
        scB.observe(h.wait(fb.append(ControlMessageDraft(type: 'presence', deviceId: bId, messageId: '<presence-bbb-1@sortie.invalid>', seq: 1, body: const {}))).internalDate);
        final won = h.wait(a.tryClaim(skipBackoff: true), timeout: const Duration(seconds: 30));
        expect(won.won, isTrue);
        expect(won.epoch, 1);
        h.elapse(const Duration(seconds: 5));
        final lost = h.wait(b.tryClaim(skipBackoff: true), timeout: const Duration(seconds: 30));
        expect(lost.won, isFalse);
        expect(h.ofType('lease-claim').map((c) => c.deviceId), [aId], reason: 'b never appended');

        // b appends an illegitimate epoch-2 claim by hand; evaluation voids it and b deletes its own.
        h.wait(fb.append(ControlMessageDraft(type: 'lease-claim', deviceId: bId, messageId: ControlMessageIds.leaseClaim(bId, 2), seq: 2, epoch: 2, priority: 30, body: const {})));
        final headers = h.wait(fb.fetchHeaders());
        final eval = b.evaluate(headers);
        expect(eval.activeLease?.deviceId, aId);
        expect(eval.voidClaims.single.deviceId, bId);
        final removed = h.wait(b.cleanupStale(headers, eval));
        expect(removed, isNotEmpty);
        expect(h.ofType('lease-claim').map((c) => c.deviceId), [aId]);
        h.wait(fa0.dispose());
        h.wait(fb.dispose());
      });
    });

    test('idempotent claim after a dropped APPEND response leaves exactly one claim', () {
      fakeAsync((fa) {
        final h = Harness(fa);
        final clock = FakeAsyncClock(fa);
        final folder = h.wait(h.rawControl(clock));
        final sc = ServerClock(clock);
        final lm = LeaseManager(folder: folder, serverClock: sc, me: Harness.identity('a'), timers: const LeaseTimers());
        sc.observe(h.wait(folder.append(ControlMessageDraft(type: 'presence', deviceId: 'a', messageId: '<presence-a-1@sortie.invalid>', seq: 1, body: const {}))).internalDate);
        h.server.dropNextAppendResponses = 1;
        final r = h.wait(lm.tryClaim(skipBackoff: true), timeout: const Duration(seconds: 30));
        expect(r.won, isTrue);
        expect(h.ofType('lease-claim').length, 1);
        expect(h.countCommands('APPEND'), 2, reason: 'presence + one claim; no re-append');
        h.wait(folder.dispose());
      });
    });

    test('heartbeat keeps only the newest beat; release deletes beats', () {
      fakeAsync((fa) {
        final h = Harness(fa);
        final clock = FakeAsyncClock(fa);
        final folder = h.wait(h.rawControl(clock));
        final sc = ServerClock(clock);
        final lm = LeaseManager(folder: folder, serverClock: sc, me: Harness.identity('a'), timers: const LeaseTimers());
        sc.observe(h.wait(folder.append(ControlMessageDraft(type: 'presence', deviceId: 'a', messageId: '<presence-a-1@sortie.invalid>', seq: 1, body: const {}))).internalDate);
        final r = h.wait(lm.tryClaim(skipBackoff: true), timeout: const Duration(seconds: 30));
        h.wait(lm.heartbeat(r.epoch!));
        h.wait(lm.heartbeat(r.epoch!));
        h.wait(lm.heartbeat(r.epoch!));
        expect(h.ofType('lease-beat').length, 1);
        expect(h.wait(lm.fence(r.epoch!)), isTrue);
        h.wait(lm.release(r.epoch!));
        expect(h.ofType('lease-beat'), isEmpty);
        expect(h.ofType('lease-release').single.epoch, r.epoch);
        expect(lm.evaluate(h.wait(folder.fetchHeaders())).activeLease, isNull);
        h.wait(folder.dispose());
      });
    });
  });

  test('claimBackoff scales with priority and is capped', () {
    const t = LeaseTimers();
    expect(t.claimBackoff(100, 0), Duration.zero);
    expect(t.claimBackoff(30, 0), const Duration(seconds: 7));
    expect(t.claimBackoff(30, 1), const Duration(seconds: 10));
    expect(t.claimBackoff(10, 1), const Duration(seconds: 12));
    expect(t.claimBackoff(0, 1), const Duration(seconds: 13));
    expect(const LeaseTimers(claimBackoffCap: Duration(seconds: 5)).claimBackoff(0, 1), const Duration(seconds: 5));
  });
}

class _NoFolder implements ControlFolder {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnsupportedError('pure evaluation only');
}
