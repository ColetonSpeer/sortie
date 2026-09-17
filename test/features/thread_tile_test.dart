import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/features/mailbox/message_list.dart';
import 'package:sortie/features/mailbox/message_tile.dart';
import 'package:sortie/features/mailbox/thread_tile.dart';
import 'package:sortie/features/mailbox/threading.dart';

import '../fakes/ui_fakes.dart';

void main() {
  const own = {'demo@example.invalid', 'alias@example.invalid'};
  final inbox = DemoData.messages.where((m) => m.folderPath == 'INBOX').toList();
  final threads = buildThreads(inbox, ownAddresses: own);
  MessageThread threadOf(int uid) => threads.singleWhere((t) => t.messages.any((m) => m.uid == uid));

  Widget wrap(UiFakes f, MessageThread t, {Set<MessageKey> selection = const {}, VoidCallback? onSelectAll}) =>
      f.app(Scaffold(
        body: ListView(children: [
          ThreadTile(
            thread: t,
            ownAddresses: own,
            selection: selection,
            buildMessageTile: (h) => MessageTile(
              header: h,
              selected: false,
              checked: selection.contains(h.key),
              selectionMode: selection.isNotEmpty,
              onTap: () {},
              onToggleCheck: () {},
            ),
            onSelectAll: onSelectAll ?? () {},
            onToggleAll: () {},
          ),
        ]),
      ));

  test('demo inbox contains the three seeded conversations', () {
    expect(threadOf(1005).messages.map((m) => m.uid), [1037, 1005, 1038]); // planning
    expect(threadOf(1001).messages.map((m) => m.uid), [1039, 1001, 1040]); // lunch, last reply from the user
    expect(threadOf(1004).messages.map((m) => m.uid), [1004, 1041]); // build, intermediate missing
    expect(threads.where((t) => !t.isSingle), hasLength(3));
  });

  testWidgets('collapsed header shows the count and expands to reveal the inner tiles', (tester) async {
    final f = UiFakes();
    final t = threadOf(1005);
    await tester.pumpWidget(wrap(f, t));
    await tester.pump();

    expect(find.text('3'), findsOneWidget); // count pill
    expect(find.text('Pat, Sam'), findsOneWidget); // participant summary
    expect(find.text('Q3 planning notes'), findsOneWidget); // root subject on the header
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(find.byType(MessageTile), findsNothing);

    await tester.tap(find.text('Q3 planning notes'));
    await tester.pumpAndSettle();
    expect(find.byType(MessageTile), findsNWidgets(3));
    // Oldest first inside the expansion.
    final tiles = tester.widgetList<MessageTile>(find.byType(MessageTile)).map((w) => w.header.uid).toList();
    expect(tiles, [1037, 1005, 1038]);

    await tester.tap(find.byTooltip('Collapse conversation'));
    await tester.pumpAndSettle();
    expect(find.byType(MessageTile), findsNothing);
  });

  testWidgets('"you" appears in the summary and long-press selects the whole thread', (tester) async {
    final f = UiFakes();
    final t = threadOf(1001);
    var selectAll = 0;
    await tester.pumpWidget(wrap(f, t, onSelectAll: () => selectAll++));
    await tester.pump();

    expect(find.text('Sam, Pat, you'), findsOneWidget);
    await tester.longPress(find.text('Sam, Pat, you'));
    await tester.pumpAndSettle();
    expect(selectAll, 1);
  });

  testWidgets('single-message thread renders the plain tile without a chevron', (tester) async {
    final f = UiFakes();
    final t = threadOf(1000);
    expect(t.isSingle, isTrue);
    await tester.pumpWidget(wrap(f, t));
    await tester.pump();

    expect(find.byType(MessageTile), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsNothing);
  });

  testWidgets('message list groups by conversation and the overflow menu toggles it off', (tester) async {
    final f = UiFakes();
    await tester.pumpWidget(f.app(const MessageListPane(
      accountId: DemoData.accountId,
      folderPath: 'INBOX',
      selectedUid: null,
      showMenuButton: false,
    )));
    await tester.pumpAndSettle();

    expect(find.byType(ThreadTile), findsWidgets);
    expect(find.text('Pat, Sam'), findsOneWidget);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Group by conversation'));
    await tester.pumpAndSettle();

    expect((await f.settings.device()).threadedView, isFalse);
    expect(find.byType(ThreadTile), findsNothing);
    expect(find.text('Pat, Sam'), findsNothing);
  });

  testWidgets('long-press on a collapsed header in the list selects all its messages', (tester) async {
    final f = UiFakes();
    await tester.pumpWidget(f.app(const MessageListPane(
      accountId: DemoData.accountId,
      folderPath: 'INBOX',
      selectedUid: null,
      showMenuButton: false,
    )));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Pat, Sam'));
    await tester.pumpAndSettle();
    expect(find.text('3 selected'), findsOneWidget);
  });
}
