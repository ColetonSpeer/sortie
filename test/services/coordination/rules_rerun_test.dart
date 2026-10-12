import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/services/sorter/user_rules.dart';

import '../../fakes/fake_classifier.dart';
import 'harness.dart';

SortRule domainRule(String id, {String domain = 'example.test', String folder = 'Finance', String? body}) => SortRule(
      id: id,
      accountId: accountId,
      priority: 10,
      match: body == null ? RuleMatch(fromDomain: domain) : RuleMatch(bodyContains: body),
      action: RuleAction.moveTo,
      folderPath: folder,
    );

void main() {
  coordinationTest('a changed rule set re-runs over inbox mail that was kept earlier (no AI involved)', (h) {
    final cls = ScriptedClassifier(rules: {'invoice': 'Finance'});
    final a = h.lead('aaa', classifier: cls);
    final m = h.deliver('Weekly report');
    h.elapse(const Duration(seconds: 3));
    expect(h.wait(a.pending()), isEmpty, reason: 'nothing matched: kept');
    expect(cls.classified.length, 1);

    // The rule arrives (import, edit, or another device); the classifier now
    // knows what to do with the subject, standing in for the rule layer.
    cls.rules['report'] = 'Finance';
    h.wait(a.rules.upsert(domainRule('r1'), DateTime.utc(2026)));
    h.elapse(const Duration(seconds: 10));

    expect(cls.classified.length, 2, reason: 'the kept message was classified again');
    final badges = h.wait(a.pending());
    expect(badges.keys.map((k) => k.messageIdHash), [m.messageIdHash]);
    expect(badges.values.single.destination, 'Finance');
    expect(h.wait(a.settings.getString('rulesApplied.$accountId')), isNotNull);

    // Same rule set again: nothing is re-run.
    h.elapse(const Duration(minutes: 1));
    expect(cls.classified.length, 2);
  });

  coordinationTest('rules on the body fetch the text when re-running over the inbox', (h) {
    final cls = ScriptedClassifier(rules: {'zoom': 'Finance'});
    final a = h.lead('aaa', classifier: cls);
    final hdr = h.header('Catch-up');
    final uid = h.server.deliver('INBOX', hdr, body: const MessageBody(text: 'Join: https://zoom.us/j/123'));
    final stored = h.server.mailboxes['INBOX']!.messages[uid]!.header;
    a.repo.upsertHeaders([stored]);
    a.sync.emitNew(accountId, [stored]);
    h.elapse(const Duration(seconds: 3));
    expect(h.wait(a.pending()), isEmpty, reason: 'subject has no keyword: kept');

    cls.rules['catch-up'] = 'Finance';
    h.wait(a.rules.upsert(domainRule('r2', body: 'zoom.us'), DateTime.utc(2026)));
    h.elapse(const Duration(seconds: 10));
    expect(h.wait(a.pending()).length, 1, reason: 'body rule matched after fetching the text');

    // A body rule that matches nothing re-queues nothing.
    h.wait(a.rules.upsert(domainRule('r3', body: 'teams.microsoft.com'), DateTime.utc(2026)));
    final before = cls.classified.length;
    h.elapse(const Duration(seconds: 10));
    expect(cls.classified.length, before);
  });

  coordinationTest('suggest-only takeover catches up mail that arrived while no leader ran', (h) {
    final cls = ScriptedClassifier(rules: {'invoice': 'Finance'});
    final a = h.lead('aaa', classifier: cls);
    h.deliver('Invoice 1');
    h.elapse(const Duration(seconds: 3));
    expect(h.wait(a.pending()).length, 1, reason: 'live arrival classified');

    // Laptop asleep: the leader is gone while a message arrives. The sync
    // cache learns about it later without a new-message event.
    h.wait(a.service.stop());
    // The harness dates every message 2026-01-01 00:00; the server receipt
    // time is what bounds the catch-up, as in the real cache.
    final missed = h.deliver('Invoice 2', notify: const []).copyWith(internalDate: a.clock.now());
    a.repo.upsertHeaders([missed]);

    a.service.start();
    h.elapse(const Duration(seconds: 40));
    expect(a.isLeader, isTrue);
    final badges = h.wait(a.pending());
    expect(badges.keys.map((k) => k.messageIdHash), contains(missed.messageIdHash), reason: 'reconcile classified the missed message');
  }, config: const SortConfig(mode: SortingMode.suggestOnly));

  coordinationTest('onResume re-checks the inbox without a restart', (h) {
    final cls = ScriptedClassifier(rules: {'invoice': 'Finance'});
    final a = h.lead('aaa', classifier: cls);
    h.deliver('Invoice 1');
    h.elapse(const Duration(seconds: 3));
    final missed = h.deliver('Invoice 2', notify: const []).copyWith(internalDate: a.clock.now());
    a.repo.upsertHeaders([missed]);
    h.elapse(const Duration(seconds: 3));
    expect(h.wait(a.pending()).length, 1, reason: 'no event: not yet classified');

    a.service.onResume(const Duration(minutes: 30));
    h.elapse(const Duration(seconds: 5));
    expect(h.wait(a.pending()).keys.map((k) => k.messageIdHash), contains(missed.messageIdHash));
  }, config: const SortConfig(mode: SortingMode.suggestOnly));
}
