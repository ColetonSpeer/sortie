import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/features/message_view/message_screen.dart';

import '../fakes/ui_fakes.dart';

void main() {
  testWidgets('message view holds the read guard while open and releases it on dispose', (tester) async {
    final f = UiFakes();
    final h = DemoData.messages[0];

    await tester.pumpWidget(f.app(MessageScreen(accountId: h.accountId, folderPath: h.folderPath, uid: h.uid, standalone: false)));
    await tester.pumpAndSettle();

    expect(f.coordinator.opened, [h.key]);
    expect(f.coordinator.closed, isEmpty);
    expect(f.sync.calls, contains('markSeen:${h.folderPath}:${h.uid}:true'));
    expect(find.text(h.subject), findsOneWidget);
    // Pending banner for the moveAfterRead decision.
    expect(find.textContaining('Will move to Work/Invoices after you finish reading'), findsOneWidget);

    await tester.pumpWidget(f.app(const SizedBox()));
    await tester.pumpAndSettle();
    expect(f.coordinator.closed, [h.key]);
  });

  testWidgets('message view stays open and offers Undo when the message is moved', (tester) async {
    final f = UiFakes();
    final h = DemoData.messages[0];

    await tester.pumpWidget(f.app(MessageScreen(accountId: h.accountId, folderPath: h.folderPath, uid: h.uid, standalone: false)));
    await tester.pumpAndSettle();

    await f.coordinator.moveNow(h.key);
    await tester.pumpAndSettle();

    expect(find.text(h.subject), findsOneWidget);
    expect(find.text('Moved to Work/Invoices'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(f.coordinator.calls, contains('undo:dec-0'));
    await tester.pump(const Duration(seconds: 10)); // let SnackBar timers expire

  });
}
