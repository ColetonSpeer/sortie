import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/services/coordination/shared_config_sync.dart';

import 'harness.dart';

void main() {
  coordinationTest('a pending suggestion travels in the rules section; accepting on B makes a rule on A and clears it on both', (h) {
    final a = h.lead('aaa');
    final b = h.follow('bbb');
    final s = h.wait(a.suggestions.insert(
      accountId: accountId,
      match: const {'from': 'orders@shop.test'},
      folderPath: 'Finance',
      rationale: 'You moved 2 messages from orders@shop.test to Finance by hand',
      confidence: 0.9,
      source: SuggestionSource.pattern,
      evidenceCount: 2,
      examples: const ['Order # shipped'],
      now: a.clock.now(),
    ));
    h.elapse(const Duration(seconds: 4));
    final onB = h.wait(b.suggestions.pending(accountId));
    expect(onB.map((x) => x.id), [s.id]);
    expect(onB.single.match, {'from': 'orders@shop.test'});
    expect(onB.single.folderPath, 'Finance');
    expect(onB.single.source, SuggestionSource.pattern);
    expect(h.ofType('rules').length, 1, reason: 'one record carries items + suggestions');
    final total = h.controlMessages().length;
    h.elapse(const Duration(seconds: 10));
    expect(h.controlMessages().length, total, reason: 'the receiver must not echo');

    // Accept on the phone (B): rule appears on A, suggestion gone on both.
    final ruleId = h.wait(b.suggestions.accept(s.id, b.clock.now()));
    h.elapse(const Duration(seconds: 4));
    final rulesOnA = h.wait(a.rules.load(accountId));
    expect(rulesOnA.map((r) => r.id), [ruleId]);
    expect(rulesOnA.single.match.from, 'orders@shop.test');
    expect(rulesOnA.single.folderPath, 'Finance');
    expect(h.wait(a.suggestions.pending(accountId)), isEmpty, reason: 'absent from the writer list and a matching rule exists -> accepted');
    expect(h.wait(b.suggestions.pending(accountId)), isEmpty);
    expect(h.ofType('rules').length, 2);
    final last = h.bodyJson(h.ofType('rules').last.uid);
    expect((last['items'] as List).length, 1);
    expect(last['suggestions'], isEmpty);
  });

  coordinationTest('dismissing on A closes the suggestion on B; a record without a suggestions key leaves local ones alone', (h) {
    final a = h.lead('aaa');
    final b = h.follow('bbb');
    final s = h.wait(a.suggestions.insert(
      accountId: accountId,
      match: const {'listId': 'news.test'},
      folderPath: 'Newsletters',
      rationale: 'x',
      confidence: 0.8,
      source: SuggestionSource.model,
      evidenceCount: 5,
      examples: const [],
      now: a.clock.now(),
    ));
    h.elapse(const Duration(seconds: 4));
    expect(h.wait(b.suggestions.pending(accountId)).single.id, s.id);
    h.wait(a.suggestions.dismiss(s.id, a.clock.now()));
    h.elapse(const Duration(seconds: 4));
    expect(h.wait(b.suggestions.pending(accountId)), isEmpty);
    expect(h.wait(a.rules.load(accountId)), isEmpty, reason: 'dismiss creates no rule');

    // An older app version publishes `{items: [...]}` only: nothing is closed.
    final s2 = h.wait(b.suggestions.insert(
      accountId: accountId,
      match: const {'from': 'x@y.test'},
      folderPath: 'Finance',
      rationale: 'x',
      confidence: 0.9,
      source: SuggestionSource.pattern,
      evidenceCount: 2,
      examples: const [],
      now: b.clock.now(),
    ));
    h.wait(b.service.sharedConfig!.applyRecord('rules', const {'items': <Object>[]}, at: b.clock.now()));
    expect(h.wait(b.suggestions.pending(accountId)).single.id, s2.id);
  });

  test('rules-section hash covers suggestions, and absent == empty', () {
    const items = <Map<String, dynamic>>[];
    final withOne = SharedConfigSync.hashOf('rules', {
      'items': items,
      'suggestions': [
        {'id': 's1', 'match': {'from': 'a@b.c'}, 'folder': 'F', 'confidence': 0.9},
      ],
    });
    expect(withOne, isNot(SharedConfigSync.hashOf('rules', {'items': items})));
    expect(SharedConfigSync.hashOf('rules', {'items': items, 'suggestions': const <Object>[]}), SharedConfigSync.hashOf('rules', {'items': items}));
    expect(SharedConfigSync.isDefaultBody('rules', {'items': items, 'suggestions': const <Object>[]}), isTrue);
    expect(SharedConfigSync.isDefaultBody('rules', {'items': items, 'suggestions': const <Object>[{'id': 's1'}]}), isFalse);
  });
}
