import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/features/compose/compose_screen.dart';
import 'package:sortie/features/compose/quote.dart';

import '../fakes/ui_fakes.dart';

void main() {
  testWidgets('reply to mail addressed to an alias picks the alias identity', (tester) async {
    final f = UiFakes();
    final h = DemoData.messages[7]; // To: alias@example.invalid
    expect(h.to.single.email, 'alias@example.invalid');

    await tester.pumpWidget(f.app(ComposeScreen(accountId: h.accountId, replyUid: h.uid, sourceFolder: h.folderPath)));
    await tester.pumpAndSettle();

    expect(find.text('Demo Alias <alias@example.invalid>'), findsOneWidget);
    expect(find.text('Re: ${h.subject}'), findsOneWidget);
    expect(find.textContaining('wrote:'), findsOneWidget);
  });

  testWidgets('new message uses the default identity and Send calls sync.send', (tester) async {
    final f = UiFakes();
    await tester.pumpWidget(f.app(const ComposeScreen(accountId: DemoData.accountId)));
    await tester.pumpAndSettle();

    expect(find.text('Demo User <demo@example.invalid>'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'name@example.com').first, 'pat@example.invalid');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Subject'), 'Hello');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(f.sync.sent, hasLength(1));
    expect(f.sync.sent.single.$2, 'id-main');
    expect(f.sync.sent.single.$3, ['pat@example.invalid']);
  });

  testWidgets('new message pre-fills the signature with the cursor at the top', (tester) async {
    final f = UiFakes();
    await tester.pumpWidget(f.app(const ComposeScreen(accountId: DemoData.accountId)));
    await tester.pumpAndSettle();

    final body = tester.widget<TextField>(find.byWidgetPredicate((w) => w is TextField && w.expands));
    expect(body.controller!.text, '\n\n-- \nDemo User (this is fake data)');
    expect(body.controller!.selection, const TextSelection.collapsed(offset: 0));
  });

  testWidgets('reply puts the cursor above the signature, and the signature above the quote', (tester) async {
    final f = UiFakes();
    final h = DemoData.messages[0];
    await tester.pumpWidget(f.app(ComposeScreen(accountId: h.accountId, replyUid: h.uid, sourceFolder: h.folderPath)));
    await tester.pumpAndSettle();

    final body = tester.widget<TextField>(find.byWidgetPredicate((w) => w is TextField && w.expands));
    final text = body.controller!.text;
    expect(text, startsWith('\n\n-- \nDemo User (this is fake data)\n\nOn '));
    expect(text, contains('wrote:'));
    expect(body.controller!.selection, const TextSelection.collapsed(offset: 0));
    expect(tester.widget<EditableText>(find.byType(EditableText).last).focusNode.hasFocus, isTrue);
  });

  testWidgets('right-clicking a recipient chip can move it to Cc/Bcc or remove it', (tester) async {
    final f = UiFakes();
    await tester.pumpWidget(f.app(const ComposeScreen(accountId: DemoData.accountId)));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'name@example.com').first, 'pat@example.invalid');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    Finder chipIn(String line) => find.descendant(of: find.byKey(ValueKey('recipients-$line')), matching: find.byType(InputChip));
    expect(chipIn('To'), findsOneWidget);
    expect(find.byKey(const ValueKey('recipients-Cc')), findsNothing);

    await tester.tapAt(tester.getCenter(chipIn('To')), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.text('Move to To'), findsNothing);
    await tester.tap(find.text('Move to Cc'));
    await tester.pumpAndSettle();
    expect(chipIn('To'), findsNothing);
    expect(chipIn('Cc'), findsOneWidget);

    await tester.tapAt(tester.getCenter(chipIn('Cc')), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to Bcc'));
    await tester.pumpAndSettle();
    expect(chipIn('Cc'), findsNothing);
    expect(chipIn('Bcc'), findsOneWidget);

    await tester.longPress(chipIn('Bcc'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsNothing);
  });

  test('Quote.pickIdentity falls back to the default identity', () {
    final h = DemoData.messages[0];
    expect(Quote.pickIdentity(DemoData.identities, h)!.id, 'id-main');
    expect(Quote.pickIdentity(DemoData.identities, DemoData.messages[7])!.id, 'id-alias');
  });
}
