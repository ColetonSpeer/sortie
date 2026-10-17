import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/data/coordination/control_folder.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/domain/services/services.dart';
import 'package:sortie/services/coordination/control_messages.dart';
import 'package:sortie/services/coordination/coordination_service.dart';

import 'harness.dart';

/// No jitter so simultaneous claimants land in the same second.
const noJitter = LeaseTimers(claimBackoffJitter: Duration.zero);

void main() {
  coordinationTest('single device becomes leader with epoch 1 and heartbeats', (h) {
    final a = h.addDevice('aaa');
    h.startAll();
    h.elapse(const Duration(seconds: 40));
    expect(a.isLeader, isTrue);
    expect(a.service.epoch, 1);
    expect(h.ofType('lease-claim').single.deviceId, a.id);
    expect(h.ofType('presence').where((p) => p.deviceId == a.id).length, 1, reason: 'newest presence kept');
    h.elapse(const Duration(minutes: 3));
    expect(h.ofType('lease-beat').length, 1, reason: 'append new beat, delete previous');
    expect(a.isLeader, isTrue);
    final devices = h.wait(a.devices());
    expect(devices.single.isLeader, isTrue);
    expect(devices.single.isThisDevice, isTrue);
  });

  /// The fake server executes commands atomically, so two live services can
  /// never interleave their claims; a competitor's claim is planted by hand
  /// in the same server second as ours to exercise the tie-break.
  void plantClaim(Harness h, String dev, int priority, {int epoch = 1}) {
    final raw = h.wait(h.rawControl(FakeAsyncClock(h.fa)));
    h.wait(raw.append(ControlMessageDraft(
      type: 'lease-claim',
      deviceId: Harness.idOf(dev),
      messageId: ControlMessageIds.leaseClaim(Harness.idOf(dev), epoch),
      seq: epoch,
      epoch: epoch,
      priority: priority,
      body: {'deviceName': dev, 'platform': 'linux', 'priority': priority, 'epoch': epoch},
    )));
    h.wait(raw.dispose());
  }

  coordinationTest('same-second claims: higher priority wins on both sides', (h) {
    final desk = h.addDevice('aaa', priority: LeaderPriority.desktop);
    desk.service.start();
    h.elapse(const Duration(seconds: 7)); // backoff for p30 is exactly 7 s
    expect(h.ofType('lease-claim').single.deviceId, desk.id);
    plantClaim(h, 'bbb', LeaderPriority.androidForegroundService);
    expect(h.ofType('lease-claim').map((c) => c.internalDate).toSet().length, 1, reason: 'same server second');
    h.elapse(const Duration(seconds: 15));
    expect(desk.isLeader, isTrue);
    expect(desk.service.epoch, 1);
    // The loser's device evaluates the same folder and reaches the same answer,
    // deleting its own void claim on its first evaluation.
    final phone = h.addDevice('bbb', priority: LeaderPriority.androidForegroundService);
    phone.service.start();
    h.elapse(const Duration(seconds: 5));
    expect(phone.state, CoordinationState.follower);
    expect(phone.service.lastEvaluation?.activeLease?.deviceId, desk.id);
    expect(h.ofType('lease-claim').map((c) => c.deviceId), [desk.id], reason: 'void claim removed by its owner');
  }, timers: noJitter);

  coordinationTest('same-second claims with equal priority: smaller deviceId wins (and we lose gracefully)', (h) {
    final b = h.addDevice('bbb');
    b.service.start();
    h.elapse(const Duration(seconds: 7));
    plantClaim(h, 'aaa', LeaderPriority.desktop); // lexically smaller, same second
    h.elapse(const Duration(seconds: 15));
    expect(b.state, CoordinationState.follower);
    expect(b.service.lastEvaluation?.activeLease?.deviceId, Harness.idOf('aaa'));
    expect(h.ofType('lease-claim').map((c) => c.deviceId), [Harness.idOf('aaa')], reason: 'b deleted its losing claim');
    // Nobody heartbeats for the planted winner: after TTL b takes over with epoch 2.
    h.elapse(const Duration(minutes: 4));
    expect(b.isLeader, isTrue);
    expect(b.service.epoch, 2);
  }, timers: noJitter);

  coordinationTest('a late claimant sees the fresh lease and stays follower without appending', (h) {
    final a = h.addDevice('aaa');
    a.service.start();
    h.elapse(const Duration(seconds: 40));
    expect(a.isLeader, isTrue);
    final b = h.addDevice('bbb');
    b.service.start();
    h.elapse(const Duration(seconds: 60));
    expect(b.state, CoordinationState.follower);
    expect(h.ofType('lease-claim').map((c) => c.deviceId), [a.id]);
    final seen = h.wait(b.devices());
    expect(seen.map((d) => d.deviceId).toSet(), {a.id, b.id});
    expect(seen.firstWhere((d) => d.deviceId == a.id).isLeader, isTrue);
  });

  coordinationTest('leader dies -> follower takes over at TTL using server time despite +/-30 min clock skew', (h) {
    final a = h.addDevice('aaa', skew: const Duration(minutes: -30));
    final b = h.addDevice('bbb', skew: const Duration(minutes: 30));
    a.service.start();
    h.elapse(const Duration(seconds: 40));
    expect(a.isLeader, isTrue);
    b.service.start();
    h.elapse(const Duration(seconds: 30));
    expect(b.state, CoordinationState.follower);
    // Simulate a crash: no release, no more beats.
    h.wait(a.service.stop(graceful: false));
    final lastBeat = [...h.ofType('lease-claim'), ...h.ofType('lease-beat')].map((m) => m.internalDate).reduce((x, y) => x.isAfter(y) ? x : y);
    // Until TTL after the last beat nothing happens.
    final untilTtl = lastBeat.add(const Duration(seconds: 180)).difference(h.server.clock.now());
    h.elapse(untilTtl - const Duration(seconds: 5));
    expect(b.state, CoordinationState.follower);
    expect(h.ofType('lease-claim').where((c) => c.deviceId == b.id), isEmpty);
    // After TTL (+ backoff + confirm) b leads with a new epoch.
    h.elapse(const Duration(seconds: 45));
    expect(b.isLeader, isTrue);
    expect(b.service.epoch, 2);
    final claim = h.ofType('lease-claim').firstWhere((c) => c.deviceId == b.id);
    expect(claim.internalDate.isAfter(lastBeat.add(const Duration(seconds: 180))), isTrue);
  });

  coordinationTest('higher-priority device preempts and the old leader yields with a release', (h) {
    final phone = h.addDevice('ppp', priority: LeaderPriority.androidWorkManager);
    phone.service.start();
    h.elapse(const Duration(seconds: 50));
    expect(phone.isLeader, isTrue);
    expect(phone.service.epoch, 1);
    final desk = h.addDevice('ddd', priority: LeaderPriority.desktop);
    desk.service.start();
    h.elapse(const Duration(seconds: 60));
    expect(desk.isLeader, isTrue);
    expect(desk.service.epoch, 2);
    expect(phone.state, CoordinationState.follower);
    expect(h.ofType('lease-release').where((r) => r.deviceId == phone.id && r.epoch == 1), isNotEmpty);
    expect(h.ofType('lease-beat').where((b) => b.deviceId == phone.id), isEmpty);
    // The preempted device does not fight back.
    h.elapse(const Duration(minutes: 4));
    expect(desk.isLeader, isTrue);
    expect(phone.state, CoordinationState.follower);
  });

  coordinationTest('a phone arriving long after the leader vanished takes over at once and sorts the backlog', (h) {
    final desk = h.addDevice('ddd', priority: LeaderPriority.desktop);
    desk.service.start();
    h.elapse(const Duration(seconds: 40));
    expect(desk.isLeader, isTrue);
    h.deliver('while the desk led');
    h.elapse(const Duration(seconds: 10));
    expect(h.ofType('decision'), isNotEmpty);
    h.wait(desk.service.stop(graceful: false));
    h.elapse(const Duration(minutes: 30));
    final phone = h.addDevice('ppp', priority: LeaderPriority.ios);
    phone.service.start();
    // Claim + confirm window only: no backoff.
    h.elapse(const Duration(seconds: 14));
    expect(phone.isLeader, isTrue);
    expect(phone.service.epoch, 2);
    // No handoff wait either: the leader loop is already running.
    h.deliver('arrived after the takeover', notify: [phone]);
    h.elapse(const Duration(seconds: 4));
    expect(h.ofType('decision').where((d) => d.deviceId == phone.id), isNotEmpty, reason: 'classified right after the takeover');
  });

  coordinationTest('graceful release -> fast takeover well before TTL', (h) {
    final a = h.addDevice('aaa');
    final b = h.addDevice('bbb');
    a.service.start();
    h.elapse(const Duration(seconds: 40));
    b.service.start();
    h.elapse(const Duration(seconds: 30));
    expect(a.isLeader, isTrue);
    expect(b.state, CoordinationState.follower);
    h.wait(a.service.stop());
    expect(h.ofType('lease-release').single.deviceId, a.id);
    h.elapse(const Duration(seconds: 45));
    expect(b.isLeader, isTrue, reason: 'took over long before the 180 s TTL');
    expect(b.service.epoch, 2);
  });

  coordinationTest('a reconnecting old leader syncs, follows, and later claims a NEW epoch', (h) {
    final a = h.addDevice('aaa');
    final b = h.addDevice('bbb');
    a.service.start();
    h.elapse(const Duration(seconds: 40));
    b.service.start();
    h.elapse(const Duration(seconds: 30));
    expect(a.service.epoch, 1);
    h.wait(a.service.stop(graceful: false));
    h.elapse(const Duration(minutes: 4));
    expect(b.isLeader, isTrue);
    expect(b.service.epoch, 2);
    a.service.start();
    h.elapse(const Duration(seconds: 60));
    expect(a.state, CoordinationState.follower, reason: 'b holds a fresh lease');
    expect(a.service.epoch, isNull);
    h.wait(b.service.stop());
    h.elapse(const Duration(seconds: 60));
    expect(a.isLeader, isTrue);
    expect(a.service.epoch, 3);
  });

  coordinationTest('idempotent claim after a dropped APPEND response', (h) {
    final a = h.addDevice('aaa');
    a.service.start();
    // Presence is the first append; drop the response of the next one (the claim).
    h.elapse(const Duration(seconds: 2));
    expect(h.ofType('presence'), isNotEmpty);
    h.server.dropNextAppendResponses = 1;
    h.elapse(const Duration(seconds: 40));
    expect(a.isLeader, isTrue);
    expect(h.ofType('lease-claim').length, 1);
  });

  coordinationTest('a device that never primed its server clock does not claim', (h) {
    // Refusing connections keeps the device in Connecting: nothing appended.
    h.server.refuseConnections = true;
    final a = h.addDevice('aaa');
    a.service.start();
    h.elapse(const Duration(minutes: 2));
    expect(a.state, CoordinationState.connecting);
    expect(a.service.serverClock.primed, isFalse);
    expect(h.controlMessages(), isEmpty);
    h.server.refuseConnections = false;
    h.elapse(const Duration(minutes: 6));
    expect(a.isLeader, isTrue);
  });

  coordinationTest('mayLead=false never claims even when alone', (h) {
    final a = h.addDevice('aaa', mayLead: () => false);
    a.service.start();
    h.elapse(const Duration(minutes: 2));
    expect(a.state, CoordinationState.follower);
    expect(h.ofType('lease-claim'), isEmpty);
    expect(h.ofType('presence').single.priority, -1, reason: 'advertises that it never leads');
  });

  coordinationTest('ServerClock estimate tracks the server, not the skewed device clock', (h) {
    final a = h.addDevice('aaa', skew: const Duration(hours: 5));
    a.service.start();
    h.elapse(const Duration(seconds: 30));
    final est = a.service.serverClock.now();
    final real = h.server.clock.now();
    expect(est.difference(real).abs(), lessThanOrEqualTo(const Duration(seconds: 2)));
    expect(a.clock.now().difference(real).abs(), greaterThan(const Duration(hours: 4)));
  });
}
