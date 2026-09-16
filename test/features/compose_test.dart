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

  test('Quote.pickIdentity falls back to the default identity', () {
    final h = DemoData.messages[0];
    expect(Quote.pickIdentity(DemoData.identities, h)!.id, 'id-main');
    expect(Quote.pickIdentity(DemoData.identities, DemoData.messages[7])!.id, 'id-alias');
  });
}
