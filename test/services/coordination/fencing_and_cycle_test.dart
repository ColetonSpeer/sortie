import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/data/coordination/control_folder.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/domain/services/services.dart';
import 'package:sortie/services/coordination/control_messages.dart';

import '../../fakes/fake_classifier.dart';
import 'harness.dart';

void main() {
  coordinationTest('connection dropped before the batch: zero MOVE commands, Connecting, then recovery with a new epoch', (h) {
    final a = h.lead('aaa');
    final m = h.deliver('Invoice 1');
    h.elapse(const Duration(seconds: 3));
    expect(h.ofType('decision').length, 1);
    expect(h.wait(a.pending()).length, 1);
    // The next command (of any connection) drops it and the server stays closed.
    h.server.refuseConnections = true;
    h.server.commandsUntilDisconnect = 1;
    h.markSeen(m);
    h.elapse(const Duration(minutes: 10));
    expect(h.countCommands('UID MOVE'), 0, reason: 'no MOVE without a live, fenced control connection');
    expect(h.folderOf(m), 'INBOX');
    expect(a.state, CoordinationState.connecting);
    // Server back: reconnect, re-lead with a NEW epoch, finish the job after the grace restarts.
    h.server.refuseConnections = false;
    h.elapse(const Duration(minutes: 6));
    expect(a.isLeader, isTrue);
    expect(a.service.epoch, 2);
    h.elapse(const Duration(minutes: 8));
    expect(h.folderOf(m), 'Finance');
    expect(h.countCommands('UID MOVE'), 1);
  });

  coordinationTest('fence failure: a claim that lands right before the batch aborts it with zero MOVE commands', (h) {
    final a = h.lead('aaa');
    final m = h.deliver('Invoice 1');
    h.elapse(const Duration(seconds: 3));
    h.markSeen(m);
    a.service.onMessageOpened(m.key);
    h.elapse(const Duration(seconds: 2));
    // Plant a preempting claim; its IDLE notification is debounced 200 ms,
    // while closing the message on the leader schedules the batch at once,
    // so only the fence's own refetch can see the new claim.
    final raw = h.wait(h.rawControl(FakeAsyncClock(h.fa)));
    final other = Harness.idOf('zzz');
    h.wait(raw.append(ControlMessageDraft(
      type: 'lease-claim',
      deviceId: other,
      messageId: ControlMessageIds.leaseClaim(other, 2),
      seq: 2,
      epoch: 2,
      priority: LeaderPriority.preferred,
      body: const {},
    )));
    a.service.onMessageClosed(m.key);
    h.fa.elapse(const Duration(milliseconds: 50));
    expect(h.commands('NOOP'), isNotEmpty, reason: 'fence ran');
    expect(h.countCommands('UID MOVE'), 0, reason: 'fence saw the higher epoch and aborted the batch');
    h.elapse(const Duration(seconds: 5));
    expect(h.countCommands('UID MOVE'), 0);
    expect(h.folderOf(m), 'INBOX');
    expect(a.state, CoordinationState.follower);
    expect(h.ofType('lease-release').where((r) => r.deviceId == a.id && r.epoch == 1), isNotEmpty);
    h.wait(raw.dispose());
  });

  coordinationTest('iOS runForegroundCycle alone: claims, sorts one batch, releases, all within budget', (h) {
    final ios = h.addDevice('iii', platform: DevicePlatform.ios, priority: LeaderPriority.ios, classifier: ScriptedClassifier(mode: SortMode.moveNow));
    final m = h.deliver('Invoice 1'); // cached locally by the sync layer; no coordinator is running yet
    final states = <CoordinationState>[];
    ios.service.state.listen(states.add);
    final start = h.fa.elapsed;
    var finished = false;
    ios.service.runForegroundCycle(budget: const Duration(seconds: 25)).then((_) => finished = true);
    h.elapse(const Duration(seconds: 25));
    expect(finished, isTrue);
    expect(h.fa.elapsed - start, lessThanOrEqualTo(const Duration(seconds: 25)));
    expect(states, containsAllInOrder([CoordinationState.connecting, CoordinationState.syncing, CoordinationState.candidate, CoordinationState.leader, CoordinationState.yielding, CoordinationState.stopped]));
    expect(h.folderOf(m), 'Finance', reason: 'reconcile picked up unclassified INBOX mail via the local cache');
    expect(h.ofType('lease-claim').single.deviceId, ios.id);
    expect(h.ofType('lease-release').single.deviceId, ios.id);
    expect(h.ofType('lease-beat'), isEmpty);
    expect(ios.state, CoordinationState.stopped);
    // Nothing lingers: a desktop coming later finds no fresh lease and leads at once.
    final desk = h.lead('ddd');
    expect(desk.service.epoch, 2);
  }, config: SortConfig(mode: SortingMode.auto, enabledAt: DateTime.utc(2025)));

  coordinationTest('iOS never claims when a desktop is present', (h) {
    h.lead('ddd');
    final ios = h.addDevice('iii', platform: DevicePlatform.ios, priority: LeaderPriority.ios, classifier: ScriptedClassifier(mode: SortMode.moveNow));
    var finished = false;
    ios.service.runForegroundCycle(budget: const Duration(seconds: 25)).then((_) => finished = true);
    h.elapse(const Duration(seconds: 25));
    expect(finished, isTrue);
    expect(h.ofType('lease-claim').where((c) => c.deviceId == ios.id), isEmpty);
    expect(h.ofType('presence').where((p) => p.deviceId == ios.id).length, 1, reason: 'still announces itself');
    expect(ios.state, CoordinationState.stopped);
  });

  coordinationTest('iOS defers to a present desktop even when no lease is held yet', (h) {
    // Desktop is connected but its claim has not landed (still in backoff).
    final desk = h.addDevice('ddd');
    desk.service.start();
    h.elapse(const Duration(seconds: 2));
    expect(desk.state, CoordinationState.candidate);
    expect(h.ofType('lease-claim'), isEmpty);
    final ios = h.addDevice('iii', platform: DevicePlatform.ios, priority: LeaderPriority.ios);
    var finished = false;
    ios.service.runForegroundCycle().then((_) => finished = true);
    h.elapse(const Duration(seconds: 5));
    expect(finished, isTrue);
    expect(h.ofType('lease-claim').where((c) => c.deviceId == ios.id), isEmpty);
    h.elapse(const Duration(seconds: 30));
    expect(desk.isLeader, isTrue);
  });
}
