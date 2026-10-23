import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sortie/core/hashing.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/features/mailbox/message_list.dart';
import 'package:sortie/features/shell/adaptive_scaffold.dart';
import 'package:sortie/router/app_router.dart';

import '../fakes/ui_fakes.dart';

const _work = 'work-account';

Future<void> _addWorkAccount(UiFakes f) async {
  await f.accounts.upsert(const Account(
    id: _work,
    displayName: 'Work',
    email: 'me@work.invalid',
    username: 'me@work.invalid',
    imap: ImapEndpoint(host: 'imap.work.invalid', port: 993, security: ConnectionSecurity.tls),
    smtp: SmtpEndpoint(host: 'smtp.work.invalid', port: 587, security: ConnectionSecurity.starttls),
  ));
  await f.folders.replaceAll(_work, const [
    Folder(accountId: _work, path: 'INBOX', name: 'INBOX', delimiter: '/', specialUse: SpecialUse.inbox),
    Folder(accountId: _work, path: 'Sent', name: 'Sent', delimiter: '/', specialUse: SpecialUse.sent),
    Folder(accountId: _work, path: 'Trash', name: 'Trash', delimiter: '/', specialUse: SpecialUse.trash),
  ]);
  await f.messages.upsertHeaders([
    MessageHeader(
      accountId: _work,
      folderPath: 'INBOX',
      uid: 7,
      uidValidity: 1,
      messageIdHash: messageIdHash(messageId: '<w7@work.invalid>'),
      messageId: '<w7@work.invalid>',
      subject: 'Quarterly numbers',
      from: const MailAddress('boss@work.invalid', 'Boss'),
      to: const [MailAddress('me@work.invalid')],
      date: DateTime.now(),
      flags: const {},
      size: 100,
    ),
  ]);
}

/// The pane behind a tiny router so taps can be observed as routes.
Widget _routed(UiFakes f, String initial, {required Size size}) {
  final router = GoRouter(initialLocation: initial, routes: [
    GoRoute(
      path: '/mail/:accountId/:folder',
      builder: (_, s) => MessageListPane(
        accountId: Uri.decodeComponent(s.pathParameters['accountId']!),
        folderPath: Uri.decodeComponent(s.pathParameters['folder']!),
        selectedUid: null,
        showMenuButton: false,
      ),
      routes: [
        GoRoute(path: 'message/:uid', builder: (_, s) => Scaffold(body: Text('opened ${s.uri}', key: const Key('opened')))),
      ],
    ),
  ]);
  return ProviderScope(
    overrides: f.overrides(),
    // Below the View's own MediaQuery, or the size would be ignored.
    child: MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => MediaQuery(data: MediaQueryData(size: size), child: child!),
    ),
  );
}

void main() {
  testWidgets('All inboxes lists both accounts with labels and opens a message under its own account', (tester) async {
    final f = UiFakes();
    await _addWorkAccount(f);
    await tester.pumpWidget(_routed(f, Routes.allInboxes, size: const Size(1200, 800)));
    await tester.pumpAndSettle();
    expect(find.text('All inboxes'), findsOneWidget);
    expect(find.text('Quarterly numbers'), findsOneWidget);
    expect(find.text(DemoData.messages.firstWhere((m) => m.folderPath == 'INBOX').subject), findsWidgets);
    expect(find.text('Work'), findsOneWidget, reason: 'the work row is tagged with its account');
    expect(find.text('Demo Mailbox (fake)'), findsWidgets);

    await tester.tap(find.text('Quarterly numbers'));
    await tester.pumpAndSettle();
    final opened = tester.widget<Text>(find.byKey(const Key('opened'))).data!;
    expect(opened, contains('/mail/all/INBOX/message/7'));
    expect(opened, contains('acct=$_work'));
  });

  testWidgets('the rail offers All inboxes only with more than one account', (tester) async {
    // Tall viewport so the lazily built rail shows every account's folders.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final f = UiFakes();
    await tester.pumpWidget(f.app(const Scaffold(body: SizedBox(width: 260, child: FolderRail(accountId: DemoData.accountId, selectedFolder: 'INBOX')))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('allInboxes')), findsNothing);

    await _addWorkAccount(f);
    await tester.pumpWidget(f.app(const Scaffold(body: SizedBox(width: 260, child: FolderRail(accountId: Routes.allAccounts, selectedFolder: 'INBOX')))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('allInboxes')), findsOneWidget);
    expect(find.text('Work'), findsWidgets, reason: 'each account heads its own folder section');
    expect(find.text('Inbox'), findsNWidgets(2));
    expect(find.text('2 accounts'), findsOneWidget);
  });

  testWidgets('phone: swiping a conversation right deletes its messages in this folder, not the Sent copy', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final f = UiFakes();
    await tester.pumpWidget(_routed(f, Routes.mailbox(DemoData.accountId, 'INBOX'), size: const Size(400, 800)));
    await tester.pumpAndSettle();
    // The "lunch" conversation: three inbox messages (1039, 1001, 1040).
    final subjectRow = find.text(DemoData.messages.singleWhere((m) => m.uid == 1001).subject);
    expect(subjectRow, findsOneWidget);
    await tester.drag(subjectRow, const Offset(300, 0));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    final deletes = f.sync.calls.where((c) => c.startsWith('delete:')).toList();
    expect(deletes, hasLength(1));
    expect(deletes.single, startsWith('delete:INBOX:'));
    expect(deletes.single, 'delete:INBOX:[1039, 1001, 1040]');
    for (final sentUid in DemoData.messages.where((m) => m.folderPath == 'Sent').map((m) => m.uid)) {
      expect(deletes.single, isNot(contains('$sentUid')), reason: 'Sent copies are never part of a folder swipe');
    }
  });
}
