import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/domain/services/services.dart';
import 'package:sortie/features/mailbox/message_tile.dart';

import '../fakes/ui_fakes.dart';

void main() {
  Widget tile(UiFakes f, MessageHeader h, PendingBadge? badge) => f.app(Scaffold(
        body: MessageTile(
          header: h,
          selected: false,
          checked: false,
          selectionMode: false,
          onTap: () {},
          onToggleCheck: () {},
          badge: badge,
        ),
      ));

  testWidgets('shows "→ folder · confidence" chip for moveAfterRead decisions', (tester) async {
    final f = UiFakes();
    final h = DemoData.messages[0];
    final badge = DemoData.pendingBadges()[h.key]!;
    expect(badge.mode, SortMode.moveAfterRead);

    await tester.pumpWidget(tile(f, h, badge));
    await tester.pump();

    expect(find.text('→ Work/Invoices · 91%'), findsOneWidget);
    expect(find.text(h.subject), findsOneWidget);
  });

  testWidgets('shows "Suggest: folder [Move] [No]" for suggestOnly decisions', (tester) async {
    final f = UiFakes();
    final h = DemoData.messages[5];
    final badge = DemoData.pendingBadges()[h.key]!;
    expect(badge.mode, SortMode.suggestOnly);

    await tester.pumpWidget(tile(f, h, badge));
    await tester.pump();

    expect(find.text('Suggest: Work/Projects'), findsOneWidget);
    expect(find.text('[Move]'), findsOneWidget);
    expect(find.text('[No]'), findsOneWidget);

    await tester.tap(find.text('[Move]'));
    await tester.pumpAndSettle();
    expect(f.coordinator.calls, contains('moveNow:${h.key}'));
  });

  testWidgets('no chip without a pending decision; unread dot and attachment icon present', (tester) async {
    final f = UiFakes();
    final h = DemoData.messages[0]; // unread, has attachment
    await tester.pumpWidget(tile(f, h, null));
    await tester.pump();
    expect(find.textContaining('→ '), findsNothing);
    expect(find.byIcon(Icons.attach_file), findsOneWidget);
  });
}
