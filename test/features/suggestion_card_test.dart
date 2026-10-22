import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/domain/repositories/repositories.dart';
import 'package:sortie/features/mailbox/message_list.dart';
import 'package:sortie/features/sort_log/sort_log_screen.dart';

import '../fakes/ui_fakes.dart';

Future<RuleSuggestion> suggestionForInboxSender(UiFakes f) async {
  final inbox = await f.messages.list(const MessageQuery(accountId: DemoData.accountId, folderPath: 'INBOX', limit: 50));
  final from = inbox.first.from!.email;
  return RuleSuggestion(
    id: 'sug-test',
    accountId: DemoData.accountId,
    match: {'from': from},
    folderPath: 'Work/Invoices',
    rationale: 'You moved 3 messages from $from to Work/Invoices by hand',
    confidence: 0.9,
    source: SuggestionSource.pattern,
    evidenceCount: 3,
    examples: const ['Order # confirmation'],
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  testWidgets('Accept creates the rule and applies it to the matching inbox messages', (tester) async {
    final f = UiFakes();
    final s = await suggestionForInboxSender(f);
    f.advisor.setPending([s]);
    f.coordinator.applyRuleCount = 2;

    await tester.pumpWidget(f.app(const SortLogScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('suggestion:sug-test')), findsOneWidget);
    expect(find.text('${s.matchLabel} → Work/Invoices'), findsOneWidget);
    expect(find.textContaining('3 messages · pattern'), findsOneWidget);

    await tester.tap(find.byKey(const Key('accept:sug-test')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Also apply to the'), findsOneWidget, reason: 'the inbox has messages from that sender');
    final box = tester.widget<CheckboxListTile>(find.byKey(const Key('applyToInbox')));
    expect(box.value, isTrue, reason: 'default on');
    await tester.tap(find.byKey(const Key('acceptConfirm')));
    await tester.pumpAndSettle();

    expect(f.advisor.calls, contains('accept:sug-test'));
    expect(f.coordinator.calls, contains('applyRuleToInbox:rule-sug-test'));
    expect(find.byKey(const Key('suggestion:sug-test')), findsNothing);
    expect(find.textContaining('2 messages queued'), findsOneWidget);
  });

  testWidgets('Dismiss removes the card without creating a rule', (tester) async {
    final f = UiFakes();
    f.advisor.setPending([DemoData.suggestions().first]);

    await tester.pumpWidget(f.app(const SortLogScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dismiss:sug-1')));
    await tester.pumpAndSettle();

    expect(f.advisor.calls, ['dismiss:sug-1']);
    expect(f.coordinator.calls.where((c) => c.startsWith('applyRuleToInbox')), isEmpty);
    expect(find.byKey(const Key('suggestion:sug-1')), findsNothing);
    expect(find.text('Suggested rules'), findsNothing);
  });

  testWidgets('Edit changes the folder before accepting', (tester) async {
    final f = UiFakes();
    f.advisor.setPending([DemoData.suggestions().first]);

    await tester.pumpWidget(f.app(const SortLogScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit:sug-1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editValue')), 'orders@calix.com');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('editConfirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('acceptConfirm')));
    await tester.pumpAndSettle();

    expect(f.advisor.accepted.single.$1, 'sug-1');
    expect(f.advisor.accepted.single.$2, {'from': 'orders@calix.com'});
    expect(f.advisor.accepted.single.$3, 'Work/Invoices');
  });

  testWidgets('Inbox shows a dismissable banner while suggestions are pending', (tester) async {
    final f = UiFakes();
    f.advisor.setPending(DemoData.suggestions());

    await tester.pumpWidget(f.app(const MessageListPane(accountId: DemoData.accountId, folderPath: 'INBOX', selectedUid: null, showMenuButton: false)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('suggestionBanner')), findsOneWidget);
    expect(find.text('2 suggested sorting rules'), findsOneWidget);

    await tester.tap(find.byTooltip('Hide for now'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('suggestionBanner')), findsNothing);
  });

  testWidgets('a new-folder suggestion offers Under Inbox / Top level and accepts the chosen path', (tester) async {
    final f = UiFakes();
    final s = RuleSuggestion(
      id: 'sug-new',
      accountId: DemoData.accountId,
      match: const {'from': 'orders@supplier.example'},
      folderPath: 'INBOX.Supplier orders',
      rationale: 'Deleted repeatedly, worth keeping',
      confidence: 0.8,
      source: SuggestionSource.model,
      evidenceCount: 4,
      examples: const ['Order shipped'],
      createdAt: DateTime.utc(2026, 1, 1),
      createsFolder: true,
    );
    f.advisor.setPending([s]);
    await tester.pumpWidget(f.app(const SortLogScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('INBOX.Supplier orders (new folder)'), findsOneWidget);
    await tester.tap(find.text('Top level'));
    await tester.pumpAndSettle();
    expect(find.textContaining('→ Supplier orders (new folder)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('accept:sug-new')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('acceptConfirm')));
    await tester.pumpAndSettle();
    expect(f.advisor.calls, contains('accept:sug-new'));
    expect(f.advisor.lastAcceptFolder, 'Supplier orders');
  });

  testWidgets('accepting a subfolder suggestion can move the parent folder\'s matching mail into it', (tester) async {
    final f = UiFakes();
    final parent = (await f.messages.list(const MessageQuery(accountId: DemoData.accountId, limit: 500))).map((h) => h.folderPath).firstWhere((p) => p != 'INBOX');
    final inParent = await f.messages.list(MessageQuery(accountId: DemoData.accountId, folderPath: parent, limit: 50));
    final from = inParent.first.from!.email;
    final s = RuleSuggestion(
      id: 'sug-sub',
      accountId: DemoData.accountId,
      match: {'from': from},
      folderPath: '$parent/Vendor',
      rationale: 'Split',
      confidence: 0.8,
      source: SuggestionSource.model,
      evidenceCount: 1,
      examples: const [],
      createdAt: DateTime.utc(2026, 1, 1),
      createsFolder: true,
    );
    f.advisor.setPending([s]);
    await tester.pumpWidget(f.app(const SortLogScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Under ${parent.split('/').last}'), findsOneWidget, reason: 'the proposed parent is a placement choice');
    await tester.tap(find.byKey(const Key('accept:sug-sub')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('moveFromParent')), findsOneWidget);
    await tester.tap(find.byKey(const Key('acceptConfirm')));
    await tester.pumpAndSettle();
    expect(f.advisor.lastAcceptFolder, '$parent/Vendor');
    final n = inParent.where((h) => h.from!.email == from).length;
    expect(f.sync.calls.where((c) => c.startsWith('move:')), isNotEmpty, reason: '$n message(s) moved from $parent');
  });
}
