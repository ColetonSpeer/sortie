import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';

import '../../fakes/fake_classifier.dart';
import '../../fakes/fake_imap_server.dart';
import 'harness.dart';

void main() {
  const pending = SortieKeywords.pending;
  const done = SortieKeywords.done;

  coordinationTest('a classified message gets a pending badge and $pending; unseen never moves under leaveUntilRead=all', (h) {
    final a = h.lead('aaa');
    final m = h.deliver('Invoice 1');
    h.elapse(const Duration(seconds: 3));
    expect(a.classifier.classified.map((x) => x.messageIdHash), [m.messageIdHash]);
    final badges = h.wait(a.pending());
    expect(badges.length, 1);
    expect(badges.values.single.destination, 'Finance');
    expect(badges.values.single.mode, SortMode.moveAfterRead);
    expect(h.flagsOf('INBOX', m), contains(pending));
    expect(h.ofType('decision').length, 1);
    h.elapse(const Duration(minutes: 20));
    expect(h.folderOf(m), 'INBOX');
    expect(h.countCommands('UID MOVE'), 0);
  });

  coordinationTest('seen message moves after the grace period, measured on the server clock', (h) {
    final a = h.lead('aaa');
    final m = h.deliver('Invoice 2');
    h.elapse(const Duration(seconds: 3));
    h.markSeen(m);
    h.elapse(const Duration(seconds: 5));
    final row = h.wait((a.db.select(a.db.sortDecisions)..where((t) => t.messageIdHash.equals(m.messageIdHash))).getSingle());
    expect(row.seenObservedAt, isNotNull, reason: 'first-seen time is persisted so a restart keeps the grace');
    h.elapse(const Duration(minutes: 6) - const Duration(seconds: 5));
    expect(h.folderOf(m), 'INBOX', reason: 'grace is 7 min');
    h.elapse(const Duration(minutes: 2));
    expect(h.folderOf(m), 'Finance');
    expect(h.flagsOf('Finance', m), containsAll([done]));
    expect(h.flagsOf('Finance', m), isNot(contains(pending)));
    expect(h.ofType('moved').length, 1);
    expect(h.wait(a.pending()), isEmpty);
    expect(a.repo.inFolder('Finance', m.messageIdHash), isNotNull, reason: 'moveLocally called');
    final log = h.wait(a.log());
    expect(log.map((e) => e.type), containsAll(['decision', 'moved']));
    expect(log.firstWhere((e) => e.type == 'moved').undoable, isTrue);
    expect(log.firstWhere((e) => e.type == 'moved').subject, 'Invoice 2');
  });

  coordinationTest('moveNow decisions ignore the seen rule but still wait for fencing', (h) {
    final a = h.lead('aaa', classifier: ScriptedClassifier(mode: SortMode.moveNow));
    final m = h.deliver('Invoice 3');
    h.elapse(const Duration(seconds: 5));
    expect(h.folderOf(m), 'Finance');
    expect(a.service.epoch, 1);
    // NOOP + refetch precede the MOVE (fence).
    final log = h.server.commandLog;
    final move = log.indexWhere((c) => c.contains('UID MOVE'));
    expect(log.sublist(0, move).where((c) => c.endsWith('NOOP')), isNotEmpty);
  });

  coordinationTest('suggestOnly config: badges appear but nothing ever moves', (h) {
    final a = h.lead('aaa', config: const SortConfig(mode: SortingMode.suggestOnly), classifier: ScriptedClassifier(mode: SortMode.moveNow));
    final m = h.deliver('Invoice 4');
    h.elapse(const Duration(seconds: 3));
    final badges = h.wait(a.pending());
    expect(badges.values.single.mode, SortMode.suggestOnly);
    h.markSeen(m);
    h.elapse(const Duration(minutes: 10));
    expect(h.folderOf(m), 'INBOX');
  });

  coordinationTest('a presence hold from another device blocks the move and expires after presenceTTL', (h) {
    h.lead('aaa');
    final b = h.follow('bbb');
    final m = h.deliver('Invoice 5');
    h.elapse(const Duration(seconds: 3));
    b.service.onMessageOpened(m.key);
    h.elapse(const Duration(seconds: 2));
    h.markSeen(m);
    h.elapse(const Duration(minutes: 9));
    expect(h.folderOf(m), 'INBOX', reason: 'held open on bbb');
    // bbb crashes with the message open: its presence ages out.
    h.wait(b.service.stop(graceful: false));
    h.elapse(const Duration(seconds: 100));
    expect(h.folderOf(m), 'INBOX', reason: 'presence still fresh (TTL 180 s)');
    h.elapse(const Duration(seconds: 100));
    expect(h.folderOf(m), 'Finance');
  });

  coordinationTest('recentlyClosed fast path: closing a seen message elsewhere moves it after reopenSettle instead of grace', (h) {
    h.lead('aaa');
    final b = h.follow('bbb');
    final m = h.deliver('Invoice 6');
    h.elapse(const Duration(seconds: 3));
    b.service.onMessageOpened(m.key);
    h.elapse(const Duration(seconds: 2));
    h.markSeen(m);
    b.service.onMessageClosed(m.key);
    h.elapse(const Duration(seconds: 15));
    expect(h.folderOf(m), 'INBOX', reason: 'settling (30 s)');
    h.elapse(const Duration(seconds: 30));
    expect(h.folderOf(m), 'Finance', reason: 'moved well before the 7 min grace');
  });

  coordinationTest("on the leader's own UI the move happens immediately on close", (h) {
    final a = h.lead('aaa');
    final m = h.deliver('Invoice 7');
    h.elapse(const Duration(seconds: 3));
    a.service.onMessageOpened(m.key);
    h.markSeen(m);
    h.elapse(const Duration(seconds: 5));
    expect(h.folderOf(m), 'INBOX');
    a.service.onMessageClosed(m.key);
    h.elapse(const Duration(seconds: 2));
    expect(h.folderOf(m), 'Finance');
  });

  coordinationTest('external move of a pending message -> resolved, badge cleared, correction for the actual folder', (h) {
    final a = h.lead('aaa');
    final m = h.deliver('Invoice 8');
    h.elapse(const Duration(seconds: 3));
    expect(h.wait(a.pending()).length, 1);
    h.server.createMailbox('Archive');
    h.externalMove(m, 'Archive');
    h.elapse(const Duration(minutes: 6)); // leader poll interval
    expect(h.wait(a.pending()), isEmpty);
    expect(h.ofType('resolved').length, 1);
    expect(h.wait(a.log()).where((e) => e.type == 'resolved').single.cause, 'external-move');
    final c = a.classifier.corrections.single;
    expect(c.kind, CorrectionKind.externalMove);
    expect(c.actualFolder, 'Archive');
    expect(c.predictedFolder, 'Finance');
    expect(h.countCommands('UID MOVE'), 0);
  });

  coordinationTest('external move into the predicted Sortie destination -> correction confirming it', (h) {
    final a = h.lead('aaa');
    final m = h.deliver('Invoice 9');
    h.elapse(const Duration(seconds: 3));
    h.server.createMailbox('Finance');
    h.externalMove(m, 'Finance');
    h.elapse(const Duration(minutes: 6));
    expect(h.wait(a.pending()), isEmpty);
    expect(a.classifier.corrections.single.actualFolder, 'Finance');
    expect(h.ofType('correction').length, 1);
  });

  coordinationTest('externally deleted pending message -> resolved{deleted} without a correction', (h) {
    final a = h.lead('aaa');
    final m = h.deliver('Invoice 10');
    h.elapse(const Duration(seconds: 3));
    h.server.externalDelete('INBOX', m.uid);
    a.repo.removeByUids(accountId, 'INBOX', [m.uid]);
    h.elapse(const Duration(minutes: 6));
    expect(h.wait(a.pending()), isEmpty);
    expect(h.wait(a.log()).where((e) => e.type == 'resolved').single.cause, 'deleted');
    expect(a.classifier.corrections, isEmpty);
  });

  coordinationTest('a $done message back in INBOX is never re-sorted', (h) {
    final a = h.lead('aaa', classifier: ScriptedClassifier(mode: SortMode.moveNow));
    final m = h.deliver('Invoice 11', flags: {done});
    h.elapse(const Duration(seconds: 10));
    expect(a.classifier.classified, isEmpty);
    expect(h.folderOf(m), 'INBOX');
    expect(h.ofType('decision'), isEmpty);
  });

  coordinationTest('control folder deleted -> recreated, re-seeded from the local view; a late joiner sees the same badges', (h) {
    final a = h.lead('aaa');
    final m = h.deliver('Invoice 12');
    h.elapse(const Duration(seconds: 3));
    final before = h.wait(a.pending());
    expect(before.length, 1);
    h.server.deleteMailbox('Sortie');
    h.elapse(const Duration(minutes: 3));
    expect(h.controlBox, isNotNull, reason: 'recreated');
    expect(a.isLeader, isTrue);
    expect(h.ofType('snapshot').length, 1, reason: 're-seeded from the local view');
    expect(h.wait(a.pending()).keys.single, m.key);
    expect(h.flagsOf('INBOX', m), contains(pending), reason: 'second recovery source untouched');
    final c = h.follow('ccc');
    h.elapse(const Duration(seconds: 3));
    final late = h.wait(c.pending());
    expect(late.keys.single, m.key);
    expect(late.values.single.decisionId, before.values.single.decisionId);
  });

  coordinationTest('a server without custom keywords still sorts (journal-only mode)', (h) {
    final a = h.lead('aaa', classifier: ScriptedClassifier(mode: SortMode.moveNow));
    final m = h.deliver('Invoice 13');
    h.elapse(const Duration(seconds: 5));
    expect(h.folderOf(m), 'Finance');
    expect(h.commands(pending), isEmpty, reason: 'no keyword STORE attempted');
    expect(h.commands(done), isEmpty);
    expect(h.wait(a.pending()), isEmpty);
  }, server: () => FakeImapServer(allowKeywords: false));

  coordinationTest('takeover reconciles $pending mail: already-seen pending starts grace at takeover time', (h) {
    final a = h.lead('aaa');
    final b = h.follow('bbb');
    final m = h.deliver('Invoice 14');
    h.elapse(const Duration(seconds: 3));
    h.markSeen(m);
    h.elapse(const Duration(minutes: 5));
    h.wait(a.service.stop());
    h.elapse(const Duration(seconds: 60));
    expect(b.isLeader, isTrue);
    expect(h.folderOf(m), 'INBOX', reason: 'new leader restarts the grace period');
    h.elapse(const Duration(minutes: 8));
    expect(h.folderOf(m), 'Finance');
    expect(b.classifier.classified, isEmpty, reason: 'decision already existed; not re-classified');
  });
}
