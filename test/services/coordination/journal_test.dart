import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/services/coordination/coordination_service.dart';

import '../../fakes/fake_classifier.dart';
import 'harness.dart';

void main() {
  coordinationTest('decisions materialise identically on two followers', (h) {
    final a = h.lead('aaa');
    final b = h.follow('bbb');
    final c = h.follow('ccc');
    final m1 = h.deliver('Invoice 1');
    final m2 = h.deliver('Newsletter 2', listId: '<list.example.test>');
    h.deliver('Personal note'); // keep -> no badge
    h.elapse(const Duration(seconds: 5));
    final pa = h.wait(a.pending());
    final pb = h.wait(b.pending());
    final pc = h.wait(c.pending());
    expect(pa.keys.toSet(), {m1.key, m2.key});
    for (final p in [pb, pc]) {
      expect(p.keys.toSet(), pa.keys.toSet());
      for (final k in pa.keys) {
        expect(p[k]!.decisionId, pa[k]!.decisionId);
        expect(p[k]!.destination, pa[k]!.destination);
        expect(p[k]!.confidence, pa[k]!.confidence);
        expect(p[k]!.mode, pa[k]!.mode);
      }
    }
    expect(h.wait(b.log()).length, h.wait(a.log()).length);
    // A move by the leader is followed too.
    h.markSeen(m1);
    h.elapse(const Duration(minutes: 8));
    expect(h.folderOf(m1), 'Finance');
    expect(h.wait(b.pending()).keys.toSet(), {m2.key});
    expect(h.wait(c.pending()).keys.toSet(), {m2.key});
    final moved = h.wait(c.log()).where((e) => e.type == 'moved').single;
    expect(moved.toFolder, 'Finance');
    expect(moved.deviceId, a.id);
  });

  coordinationTest('compaction: snapshot appended before expunge; a late joiner reconstructs the same pending map', (h) {
    final a = h.lead('aaa');
    final ms = <MessageHeader>[];
    for (var i = 0; i < 4; i++) {
      ms.add(h.deliver('Invoice $i'));
      h.elapse(const Duration(seconds: 3)); // one decision record each
    }
    h.markSeen(ms[0]);
    h.elapse(const Duration(minutes: 8));
    expect(h.folderOf(ms[0]), 'Finance');
    final journalBefore = h.controlMessages().where((m) => m.isJournal).length;
    expect(journalBefore, greaterThan(3));
    final before = h.wait(a.pending());
    expect(before.length, 3);
    h.wait(a.service.runMaintenance());
    h.settle();
    final snap = h.ofType('snapshot').single;
    expect(h.controlMessages().where((m) => m.isJournal), isEmpty, reason: 'journal folded into the snapshot');
    final log = h.server.commandLog;
    final snapAppend = log.lastIndexWhere((c) => c.contains('APPEND Sortie'));
    final expunge = log.lastIndexWhere((c) => c.contains('UID EXPUNGE'));
    expect(snapAppend, lessThan(expunge), reason: 'APPEND snapshot, confirm, then EXPUNGE');
    expect(snap.snapshotUpto, greaterThan(0));
    expect(snap.epoch, 1);
    // Leader keeps its own view.
    expect(h.wait(a.pending()).keys.toSet(), before.keys.toSet());
    expect(h.wait(a.log()).where((e) => e.type == 'moved').length, 1, reason: 'log survives locally');
    // A late joiner rebuilds from the snapshot alone.
    final z = h.follow('zzz');
    h.elapse(const Duration(seconds: 3));
    final late = h.wait(z.pending());
    expect(late.keys.toSet(), before.keys.toSet());
    for (final k in before.keys) {
      expect(late[k]!.decisionId, before[k]!.decisionId);
    }
    expect(h.wait(z.log()).where((e) => e.type == 'moved').length, 1, reason: 'log carried in the snapshot');
    expect(h.wait(z.log()).where((e) => e.type == 'moved').single.subject, 'Invoice 0');
  }, timers: const LeaseTimers(compactionMaxJournal: 3));

  coordinationTest('no compaction below the thresholds', (h) {
    final a = h.lead('aaa');
    h.deliver('Invoice 1');
    h.elapse(const Duration(seconds: 3));
    h.wait(a.service.runMaintenance());
    h.settle();
    expect(h.ofType('snapshot'), isEmpty);
    expect(h.ofType('decision').length, 1);
  });

  coordinationTest('control folder UIDVALIDITY change -> cursor reset and full resync with identical badges', (h) {
    final a = h.lead('aaa');
    final b = h.follow('bbb');
    h.deliver('Invoice 1');
    h.deliver('Invoice 2');
    h.elapse(const Duration(seconds: 3));
    final before = h.wait(b.pending());
    expect(before.length, 2);
    final oldUv = h.controlBox!.uidValidity;
    h.server.bumpUidValidity('Sortie');
    h.elapse(const Duration(minutes: 6)); // poll fallback re-selects and notices
    expect(h.wait(a.pending()).length, 2);
    final after = h.wait(b.pending());
    expect(after.keys.toSet(), before.keys.toSet());
    expect(after.values.map((v) => v.decisionId).toSet(), before.values.map((v) => v.decisionId).toSet());
    final cursor = h.wait(b.db.select(b.db.journalCursors).getSingle());
    expect(cursor.uidValidity, isNot(oldUv));
    expect(cursor.uidValidity, h.controlBox!.uidValidity);
    expect(cursor.lastAppliedUid, h.controlMessages().where((m) => m.isJournal).map((m) => m.uid).reduce((x, y) => x > y ? x : y));
    expect(a.isLeader, isTrue, reason: 'the lease survives: same records, new UIDs');
  });

  coordinationTest('config: last writer by UID wins on every device', (h) {
    final a = h.lead('aaa');
    final b = h.follow('bbb');
    h.wait(a.service.putConfig(const SortConfig(mode: SortingMode.auto, graceMinutes: 5)));
    h.wait(b.service.putConfig(const SortConfig(mode: SortingMode.auto, graceMinutes: 9)));
    h.elapse(const Duration(seconds: 2));
    expect(h.wait(a.settings.sortConfig(accountId)).graceMinutes, 9);
    expect(h.wait(b.settings.sortConfig(accountId)).graceMinutes, 9);
    h.wait(b.service.putConfig(const SortConfig(mode: SortingMode.auto, graceMinutes: 3)));
    h.wait(a.service.putConfig(const SortConfig(mode: SortingMode.auto, graceMinutes: 11)));
    h.elapse(const Duration(seconds: 2));
    expect(h.wait(a.settings.sortConfig(accountId)).graceMinutes, 11);
    expect(h.wait(b.settings.sortConfig(accountId)).graceMinutes, 11);
    expect(h.ofType('config').length, 4);
    final c = h.follow('ccc', config: const SortConfig(mode: SortingMode.off));
    h.elapse(const Duration(seconds: 2));
    expect(h.wait(c.settings.sortConfig(accountId)).graceMinutes, 11, reason: 'late joiner replays the journal');
    expect(h.wait(c.settings.sortConfig(accountId)).mode, SortingMode.auto);
  });

  coordinationTest('a duplicate journal record (re-appended after an ambiguous failure) is applied once', (h) {
    final a = h.lead('aaa', classifier: ScriptedClassifier(mode: SortMode.moveNow));
    h.server.dropNextAppendResponses = 1; // hits the decision append
    final m = h.deliver('Invoice 1');
    h.elapse(const Duration(seconds: 5));
    expect(h.folderOf(m), 'Finance');
    expect(h.ofType('decision').length, 1, reason: 'Message-ID search found the stored record');
    expect(h.wait(a.log()).where((e) => e.type == 'decision').length, 1);
  });
}
