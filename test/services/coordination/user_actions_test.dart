import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';

import '../../fakes/fake_classifier.dart';
import 'harness.dart';

void main() {
  const pending = SortieKeywords.pending;
  const done = SortieKeywords.done;

  coordinationTest('undo from a follower moves the message back, keeps $done, and the leader never re-sorts it', (h) {
    final a = h.lead('aaa', classifier: ScriptedClassifier(mode: SortMode.moveNow));
    final b = h.follow('bbb');
    final m = h.deliver('Invoice 1');
    h.elapse(const Duration(seconds: 5));
    expect(h.folderOf(m), 'Finance');
    final entry = h.wait(b.log()).firstWhere((e) => e.type == 'moved');
    expect(entry.undoable, isTrue);
    h.wait(b.service.undo(entry.decisionId!));
    h.elapse(const Duration(seconds: 2));
    expect(h.folderOf(m), 'INBOX');
    expect(h.flagsOf('INBOX', m), contains(done));
    expect(h.ofType('undo').single.deviceId, b.id);
    expect(b.classifier.corrections.single.kind, CorrectionKind.undo);
    expect(b.classifier.corrections.single.actualFolder, 'INBOX');
    // The sync layer reports it as new INBOX mail on the leader; it stays put.
    final back = h.server.mailboxes['INBOX']!.messages.values.single;
    a.repo.upsertHeaders([back.header.copyWith(flags: {...back.flags})]);
    a.sync.emitNew(accountId, [back.header.copyWith(flags: {...back.flags})]);
    h.elapse(const Duration(minutes: 6));
    expect(h.folderOf(m), 'INBOX');
    expect(a.classifier.classified.length, 1, reason: 'not classified again');
    expect(h.ofType('decision').length, 1);
    final statusA = h.wait(a.db.select(a.db.sortDecisions).getSingle()).status;
    final statusB = h.wait(b.db.select(b.db.sortDecisions).getSingle()).status;
    expect(statusA, DecisionStatus.undone.name);
    expect(statusB, DecisionStatus.undone.name);
    expect(h.wait(a.log()).firstWhere((e) => e.type == 'moved' && e.cause == 'auto').undoable, isFalse);
  });

  coordinationTest('keepInInbox resolves the badge with a badgeDismiss correction and marks the mail done', (h) {
    final a = h.lead('aaa');
    final b = h.follow('bbb');
    final m = h.deliver('Invoice 2');
    h.elapse(const Duration(seconds: 3));
    expect(h.wait(b.pending()).length, 1);
    h.wait(b.service.keepInInbox(m.key));
    h.elapse(const Duration(seconds: 2));
    expect(h.wait(a.pending()), isEmpty);
    expect(h.wait(b.pending()), isEmpty);
    expect(h.flagsOf('INBOX', m), contains(done));
    expect(h.flagsOf('INBOX', m), isNot(contains(pending)));
    expect(b.classifier.corrections.single.kind, CorrectionKind.badgeDismiss);
    expect(h.wait(a.log()).firstWhere((e) => e.type == 'resolved').cause, 'keep');
    h.markSeen(m);
    h.elapse(const Duration(minutes: 10));
    expect(h.folderOf(m), 'INBOX', reason: 'kept for good');
  });

  coordinationTest('changeDestination moves the mail and journals a badgeWrong correction', (h) {
    final a = h.lead('aaa');
    final b = h.follow('bbb');
    final m = h.deliver('Invoice 3');
    h.elapse(const Duration(seconds: 3));
    h.wait(b.service.changeDestination(m.key, 'Newsletters'));
    h.elapse(const Duration(seconds: 2));
    expect(h.folderOf(m), 'Newsletters');
    expect(h.flagsOf('Newsletters', m), contains(done));
    final c = b.classifier.corrections.single;
    expect(c.kind, CorrectionKind.badgeWrong);
    expect(c.predictedFolder, 'Finance');
    expect(c.actualFolder, 'Newsletters');
    expect(h.wait(a.pending()), isEmpty);
    expect(h.wait(a.log()).firstWhere((e) => e.type == 'moved').cause, 'correction');
    expect(h.wait(a.db.select(a.db.sortDecisions).getSingle()).status, DecisionStatus.corrected.name);
    expect(h.wait(a.db.select(a.db.corrections).get()).length, 1, reason: 'corrections mirror on the leader');
  });

  coordinationTest('markRight records a badgeRight correction and leaves the badge pending', (h) {
    final a = h.lead('aaa');
    final m = h.deliver('Invoice 4');
    h.elapse(const Duration(seconds: 3));
    h.wait(a.service.markRight(m.key));
    h.elapse(const Duration(seconds: 2));
    expect(a.classifier.corrections.single.kind, CorrectionKind.badgeRight);
    expect(h.wait(a.pending()).length, 1);
    expect(h.folderOf(m), 'INBOX');
  });

  coordinationTest('moveNow executes a pending decision at once from any device', (h) {
    final a = h.lead('aaa');
    final b = h.follow('bbb');
    final m = h.deliver('Invoice 5');
    h.elapse(const Duration(seconds: 3));
    h.wait(b.service.moveNow(m.key));
    h.elapse(const Duration(seconds: 2));
    expect(h.folderOf(m), 'Finance');
    expect(h.flagsOf('Finance', m), contains(done));
    expect(h.wait(a.pending()), isEmpty);
    expect(h.wait(a.db.select(a.db.sortDecisions).getSingle()).status, DecisionStatus.accepted.name);
    expect(b.repo.inFolder('Finance', m.messageIdHash), isNotNull);
  });

  coordinationTest('user actions throw while disconnected', (h) {
    final a = h.addDevice('aaa');
    expect(() => h.wait(a.service.markRight(MessageKey(accountId: accountId, messageIdHash: 'x'))), throwsStateError);
  });
}
