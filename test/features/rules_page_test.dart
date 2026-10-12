import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/features/settings/rules_page.dart';
import 'package:sortie/services/sorter/user_rules.dart';

import '../fakes/ui_fakes.dart';

SortRule imported({String id = 'tb-1', bool enabled = true}) => SortRule(
      id: id,
      accountId: DemoData.accountId,
      priority: 10,
      match: const RuleMatch(from: 'helpdesk@example.test'),
      action: RuleAction.moveTo,
      folderPath: 'Work/Invoices',
      hits: 3,
      enabled: enabled,
      name: 'Helpdesk tickets',
    );

void main() {
  testWidgets('lists rules with name, criteria, folder and hits', (tester) async {
    final f = UiFakes();
    await f.rules.upsert(imported(), DateTime.utc(2026));
    await tester.pumpWidget(f.app(const RulesPage()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('rule:tb-1')), findsOneWidget);
    expect(find.text('Helpdesk tickets'), findsOneWidget);
    expect(find.textContaining('from helpdesk@example.test'), findsOneWidget);
    expect(find.textContaining('→ Work/Invoices'), findsOneWidget);
    expect(find.textContaining('matched 3 times'), findsOneWidget);
  });

  testWidgets('the switch disables a rule and keeps everything else', (tester) async {
    final f = UiFakes();
    await f.rules.upsert(imported(), DateTime.utc(2026));
    await tester.pumpWidget(f.app(const RulesPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('enabled:tb-1')));
    await tester.pumpAndSettle();
    final r = (await f.rules.load(DemoData.accountId)).single;
    expect(r.enabled, isFalse);
    expect(r.name, 'Helpdesk tickets');
    expect(r.folderPath, 'Work/Invoices');
    expect(r.hits, 3);
  });

  testWidgets('Add rule saves a new rule and applies it to the inbox', (tester) async {
    final f = UiFakes();
    f.coordinator.applyRuleCount = 2;
    await tester.pumpWidget(f.app(const RulesPage()));
    await tester.pumpAndSettle();
    expect(find.textContaining('No rules yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addRule')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('ruleName')), 'Calix orders');
    await tester.tap(find.byKey(const Key('ruleField0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Subject contains').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('ruleValue0')), 'Order Acknowledgement');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byKey(const Key('ruleSave'))).onPressed, isNull, reason: 'needs a folder');
    await tester.tap(find.byKey(const Key('ruleFolder')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Work/Invoices').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ruleSave')));
    await tester.pumpAndSettle();

    final r = (await f.rules.load(DemoData.accountId)).single;
    expect(r.name, 'Calix orders');
    expect(r.match.subjectContains, 'Order Acknowledgement');
    expect(r.folderPath, 'Work/Invoices');
    expect(r.enabled, isTrue);
    expect(f.coordinator.calls, contains('applyRuleToInbox:${r.id}'));
    expect(find.textContaining('2 messages queued'), findsOneWidget);
    expect(find.text('Calix orders'), findsOneWidget);
  });

  testWidgets('Edit keeps the id and rewrites the criteria; Delete removes', (tester) async {
    final f = UiFakes();
    await f.rules.upsert(imported(), DateTime.utc(2026));
    await tester.pumpWidget(f.app(const RulesPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('rule:tb-1')));
    await tester.pumpAndSettle();
    expect(find.text('Edit rule'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('ruleValue0')), 'support@example.test');
    await tester.tap(find.byKey(const Key('ruleSave')));
    await tester.pumpAndSettle();
    var r = (await f.rules.load(DemoData.accountId)).single;
    expect(r.id, 'tb-1');
    expect(r.match.from, 'support@example.test');
    expect(r.hits, 3, reason: 'hit counter survives edits');

    await tester.tap(find.byKey(const Key('menu:tb-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteConfirm')));
    await tester.pumpAndSettle();
    expect(await f.rules.load(DemoData.accountId), isEmpty);
    expect(find.byKey(const Key('rule:tb-1')), findsNothing);
  });

  testWidgets('Run all applies every rule through the coordinator', (tester) async {
    final f = UiFakes();
    f.coordinator.applyRuleCount = 5;
    await f.rules.upsert(imported(), DateTime.utc(2026));
    await tester.pumpWidget(f.app(const RulesPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('runAllRules')));
    await tester.pumpAndSettle();
    expect(f.coordinator.calls, contains('applyRulesToInbox'));
    expect(find.textContaining('5 messages queued'), findsOneWidget);
  });
}
