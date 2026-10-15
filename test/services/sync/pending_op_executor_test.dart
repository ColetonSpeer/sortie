import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/data/mail/imap_gateway.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/services/sync/folder_synchronizer.dart';
import 'package:sortie/services/sync/pending_op_executor.dart';

import '../../data/test_support.dart';
import '../../fakes/fake_imap_server.dart';

void main() {
  late TestDb t;
  late FakeImapServer server;
  late FakeImapGateway gw;
  late RecordingSmtpGateway smtp;
  late PendingOpExecutor exec;
  final files = <String, List<int>>{};

  setUp(() async {
    t = await TestDb.open();
    await t.accounts.upsert(testAccount());
    await t.accounts.upsertIdentity(const Identity(id: 'id1', accountId: testAccountId, name: 'Test', email: 'test@example.com', isDefault: true));
    server = FakeImapServer();
    server.createMailbox('Archive', specialUse: SpecialUse.archive);
    server.createMailbox('Sent', specialUse: SpecialUse.sent);
    gw = FakeImapGateway(server);
    await gw.connect(testAccount(), 'pw');
    smtp = RecordingSmtpGateway();
    files.clear();
    exec = PendingOpExecutor(
      ops: t.pendingOps,
      messages: t.messages,
      folders: t.folders,
      accounts: t.accounts,
      credentials: MemoryCredentialStore()..map['account.$testAccountId.password'] = 'pw',
      smtp: smtp,
      clock: t.clock,
      readFile: (p) async => files[p]!,
      deleteFile: (p) async => files.remove(p),
    );
    // Folder list + INBOX cache as the session would have produced them.
    final listed = await gw.listFolders();
    await t.folders.replaceAll(testAccountId, [
      for (final f in listed) Folder(accountId: testAccountId, path: f.path, name: f.name, delimiter: f.delimiter, specialUse: f.specialUse, uidValidity: f.uidValidity, uidNext: f.uidNext),
    ]);
  });

  tearDown(() => t.close());

  Future<void> syncInbox() => FolderSynchronizer(accountId: testAccountId, messages: t.messages, folders: t.folders, clock: t.clock).sync(gw, 'INBOX');

  test('SetFlagsOp is idempotent', () async {
    final h = makeHeader();
    final uid = server.deliver('INBOX', h);
    await syncInbox();
    final op = SetFlagsOp(id: 'op1', accountId: testAccountId, createdAt: t.clock.now(), folderPath: 'INBOX', uidValidity: server.mailboxes['INBOX']!.uidValidity, messageIdHashes: [h.messageIdHash], uids: [uid], add: {r'\Seen', SortieKeywords.pending});
    await exec.execute(op, gw);
    await exec.execute(op, gw);
    expect(server.mailboxes['INBOX']!.messages[uid]!.flags, containsAll([r'\Seen', SortieKeywords.pending]));
  });

  test('MoveOp uses COPYUID mapping, relinks locally and is a no-op when re-run', () async {
    final h = makeHeader(subject: 'move me');
    final uid = server.deliver('INBOX', h);
    await syncInbox();
    final uv = server.mailboxes['INBOX']!.uidValidity;
    // Optimistic local move as SyncEngine.move does.
    await t.messages.moveLocally(testAccountId, 'INBOX', [uid], 'Archive');
    final op = MoveOp(id: 'mv1', accountId: testAccountId, createdAt: t.clock.now(), fromFolder: 'INBOX', toFolder: 'Archive', uidValidity: uv, messageIdHashes: [h.messageIdHash], uids: [uid]);
    await exec.execute(op, gw);
    expect(server.mailboxes['INBOX']!.messages, isEmpty);
    expect(server.mailboxes['Archive']!.messages.length, 1);
    final newUid = server.mailboxes['Archive']!.uids.single;
    final local = await t.messages.byMessageIdHash(testAccountId, h.messageIdHash);
    expect(local!.folderPath, 'Archive');
    expect(local.uid, newUid, reason: 'relinked from COPYUID');

    await exec.execute(op, gw); // replay after a lost response
    expect(server.mailboxes['Archive']!.messages.length, 1);
    expect(server.mailboxes['INBOX']!.messages, isEmpty);
  });

  test('MoveOp re-finds messages by Message-ID after a UIDVALIDITY change', () async {
    final h = makeHeader(subject: 'relink');
    final other = makeHeader(subject: 'other');
    final uid = server.deliver('INBOX', h);
    server.deliver('INBOX', other);
    await syncInbox();
    final oldUv = server.mailboxes['INBOX']!.uidValidity;
    final op = MoveOp(id: 'mv2', accountId: testAccountId, createdAt: t.clock.now(), fromFolder: 'INBOX', toFolder: 'Archive', uidValidity: oldUv, messageIdHashes: [h.messageIdHash], uids: [uid]);

    server.externalDelete('INBOX', 2); // shifts things around
    server.bumpUidValidity('INBOX'); // recorded UID now stale
    await exec.execute(op, gw);
    expect(server.mailboxes['Archive']!.messages.values.single.headers['message-id'], h.messageId);
    expect(server.mailboxes['INBOX']!.messages, isEmpty);
    expect(server.commandLog.any((c) => c.contains('HEADER Message-ID')), isTrue);
  });

  test('MoveOp creates a missing destination folder', () async {
    final h = makeHeader();
    final uid = server.deliver('INBOX', h);
    await syncInbox();
    final op = MoveOp(id: 'mv3', accountId: testAccountId, createdAt: t.clock.now(), fromFolder: 'INBOX', toFolder: 'Work/New', uidValidity: server.mailboxes['INBOX']!.uidValidity, messageIdHashes: [h.messageIdHash], uids: [uid]);
    await exec.execute(op, gw);
    expect(server.mailboxes['Work/New']!.messages.length, 1);
  });

  test('DeleteOp moves to Trash when known, expunges when permanent', () async {
    server.createMailbox('Trash', specialUse: SpecialUse.trash);
    await t.folders.replaceAll(testAccountId, [
      for (final f in await gw.listFolders()) Folder(accountId: testAccountId, path: f.path, name: f.name, delimiter: f.delimiter, specialUse: f.specialUse),
    ]);
    final a = makeHeader(), b = makeHeader();
    final ua = server.deliver('INBOX', a), ub = server.deliver('INBOX', b);
    await syncInbox();
    final uv = server.mailboxes['INBOX']!.uidValidity;
    await exec.execute(DeleteOp(id: 'd1', accountId: testAccountId, createdAt: t.clock.now(), folderPath: 'INBOX', uidValidity: uv, messageIdHashes: [a.messageIdHash], uids: [ua]), gw);
    await exec.execute(DeleteOp(id: 'd2', accountId: testAccountId, createdAt: t.clock.now(), folderPath: 'INBOX', uidValidity: uv, messageIdHashes: [b.messageIdHash], uids: [ub], permanent: true), gw);
    expect(server.mailboxes['Trash']!.messages.length, 1);
    expect(server.mailboxes['INBOX']!.messages, isEmpty);
  });

  test('AppendOp is idempotent by Message-ID and survives a lost response', () async {
    files['/spool/a.eml'] = utf8.encode('From: test@example.com\r\nTo: x@y\r\nSubject: draft\r\nMessage-ID: <draft1@example.com>\r\nDate: Thu, 1 Jan 2026 10:00:00 +0000\r\n\r\nhello');
    server.createMailbox('Drafts', specialUse: SpecialUse.drafts);
    server.dropNextAppendResponses = 1;
    final op = AppendOp(id: 'ap1', accountId: testAccountId, createdAt: t.clock.now(), folderPath: 'Drafts', rawMessagePath: '/spool/a.eml', flags: {r'\Draft'});
    await exec.execute(op, gw);
    expect(server.mailboxes['Drafts']!.messages.length, 1);
    expect(files, isEmpty, reason: 'spool file removed after success');
    files['/spool/a.eml'] = utf8.encode('From: test@example.com\r\nSubject: draft\r\nMessage-ID: <draft1@example.com>\r\n\r\nhello');
    await exec.execute(op, gw);
    expect(server.mailboxes['Drafts']!.messages.length, 1, reason: 'no duplicate');
  });

  test('AppendOp with supersedesMessageId replaces the previous draft copy', () async {
    server.createMailbox('Drafts', specialUse: SpecialUse.drafts);
    files['/spool/d1.eml'] = utf8.encode('From: test@example.com\r\nSubject: draft\r\nMessage-ID: <d1@example.com>\r\n\r\nv1');
    await exec.execute(AppendOp(id: 'd1', accountId: testAccountId, createdAt: t.clock.now(), folderPath: 'Drafts', rawMessagePath: '/spool/d1.eml', flags: {r'\Draft'}), gw);
    files['/spool/d2.eml'] = utf8.encode('From: test@example.com\r\nSubject: draft\r\nMessage-ID: <d2@example.com>\r\n\r\nv2');
    await exec.execute(AppendOp(id: 'd2', accountId: testAccountId, createdAt: t.clock.now(), folderPath: 'Drafts', rawMessagePath: '/spool/d2.eml', flags: {r'\Draft'}, supersedesMessageId: '<d1@example.com>'), gw);
    final drafts = server.mailboxes['Drafts']!.messages.values.toList();
    expect(drafts.length, 1);
    expect(drafts.single.headers['message-id'], '<d2@example.com>');
    // Superseding a copy that is already gone is harmless.
    files['/spool/d3.eml'] = utf8.encode('From: test@example.com\r\nSubject: draft\r\nMessage-ID: <d3@example.com>\r\n\r\nv3');
    await exec.execute(AppendOp(id: 'd3', accountId: testAccountId, createdAt: t.clock.now(), folderPath: 'Drafts', rawMessagePath: '/spool/d3.eml', supersedesMessageId: '<gone@example.com>'), gw);
    expect(server.mailboxes['Drafts']!.messages.length, 2);
  });

  test('SendOp removes the autosaved draft after the Sent copy; DeleteOp resolves raw Message-IDs', () async {
    server.createMailbox('Drafts', specialUse: SpecialUse.drafts);
    await t.folders.replaceAll(testAccountId, [
      for (final f in await gw.listFolders()) Folder(accountId: testAccountId, path: f.path, name: f.name, delimiter: f.delimiter, specialUse: f.specialUse),
    ]);
    files['/spool/d.eml'] = utf8.encode('From: test@example.com\r\nSubject: hi\r\nMessage-ID: <auto@example.com>\r\n\r\ndraft');
    await exec.execute(AppendOp(id: 'a', accountId: testAccountId, createdAt: t.clock.now(), folderPath: 'Drafts', rawMessagePath: '/spool/d.eml'), gw);
    files['/spool/d2.eml'] = utf8.encode('From: test@example.com\r\nSubject: other\r\nMessage-ID: <other@example.com>\r\n\r\ndraft');
    await exec.execute(AppendOp(id: 'a2', accountId: testAccountId, createdAt: t.clock.now(), folderPath: 'Drafts', rawMessagePath: '/spool/d2.eml'), gw);
    expect(server.mailboxes['Drafts']!.messages.length, 2);

    files['/spool/s.eml'] = utf8.encode('From: test@example.com\r\nTo: bob@example.com\r\nSubject: hi\r\nMessage-ID: <final@example.com>\r\nDate: Thu, 1 Jan 2026 10:00:00 +0000\r\n\r\nbody');
    await exec.execute(SendOp(id: 's', accountId: testAccountId, createdAt: t.clock.now(), identityId: 'id1', rawMessagePath: '/spool/s.eml', recipients: const ['bob@example.com'], draftMessageId: '<auto@example.com>'), gw);
    expect(smtp.sent.length, 1);
    expect(server.mailboxes['Sent']!.messages.length, 1);
    expect(server.mailboxes['Drafts']!.messages.values.map((m) => m.headers['message-id']), ['<other@example.com>']);

    await exec.execute(DeleteOp(id: 'x', accountId: testAccountId, createdAt: t.clock.now(), folderPath: 'Drafts', uidValidity: 0, messageIdHashes: const [], uids: const [], permanent: true, messageIds: const ['<other@example.com>']), gw);
    expect(server.mailboxes['Drafts']!.messages, isEmpty);
  });

  test('SendOp: SMTP once, Sent-APPEND retried, never re-sent after acceptance', () async {
    final raw = utf8.encode('From: test@example.com\r\nTo: bob@example.com\r\nSubject: hi\r\nMessage-ID: <send1@example.com>\r\nDate: Thu, 1 Jan 2026 10:00:00 +0000\r\n\r\nbody');
    files['/spool/s.eml'] = raw;
    final op = SendOp(id: 's1', accountId: testAccountId, createdAt: t.clock.now(), identityId: 'id1', rawMessagePath: '/spool/s.eml', recipients: const ['bob@example.com']);
    await t.pendingOps.enqueue(op);

    // Connection drops exactly at the APPEND to Sent (SELECT, SEARCH, APPEND).
    server.commandsUntilDisconnect = 3;
    await expectLater(exec.drain(testAccountId, gw), throwsA(isA<ImapGatewayException>()));
    expect(smtp.sent.length, 1);
    expect(server.mailboxes['Sent']!.messages, isEmpty);
    final pending = await t.pendingOps.pending(testAccountId);
    expect(pending.single, isA<SendOp>().having((o) => o.smtpAccepted, 'smtpAccepted', true));

    final gw2 = FakeImapGateway(server, name: 'conn2');
    await gw2.connect(testAccount(), 'pw');
    expect(await exec.drain(testAccountId, gw2), 1);
    expect(smtp.sent.length, 1, reason: 'never re-sent');
    expect(server.mailboxes['Sent']!.messages.values.single.flags, contains(r'\Seen'));
    expect(await t.pendingOps.pending(testAccountId), isEmpty);
    expect(files, isEmpty);
  });

  test('SendOp SMTP failure is deferred, not dropped', () async {
    files['/spool/f.eml'] = utf8.encode('From: a@b\r\nTo: c@d\r\nSubject: x\r\nMessage-ID: <f@b>\r\n\r\nz');
    await t.pendingOps.enqueue(SendOp(id: 's2', accountId: testAccountId, createdAt: t.clock.now(), identityId: 'id1', rawMessagePath: '/spool/f.eml', recipients: const ['c@d']));
    smtp.fail = true;
    expect(await exec.drain(testAccountId, gw), 0);
    expect(await t.pendingOps.pending(testAccountId), isEmpty, reason: 'in retry cool-down');
    t.clock.advance(const Duration(minutes: 5));
    expect((await t.pendingOps.pending(testAccountId)).length, 1);
    smtp.fail = false;
    expect(await exec.drain(testAccountId, gw), 1);
    expect(smtp.sent.length, 1);
  });

  test('drain executes FIFO and continues past a bad op', () async {
    final h = makeHeader();
    final uid = server.deliver('INBOX', h);
    await syncInbox();
    final uv = server.mailboxes['INBOX']!.uidValidity;
    await t.pendingOps.enqueue(AppendOp(id: 'bad', accountId: testAccountId, createdAt: t.clock.now(), folderPath: 'Nope', rawMessagePath: '/missing', flags: const {}));
    t.clock.advance(const Duration(seconds: 1));
    await t.pendingOps.enqueue(SetFlagsOp(id: 'good', accountId: testAccountId, createdAt: t.clock.now(), folderPath: 'INBOX', uidValidity: uv, messageIdHashes: [h.messageIdHash], uids: [uid], add: {r'\Flagged'}));
    expect(await exec.drain(testAccountId, gw), 1);
    expect(server.mailboxes['INBOX']!.messages[uid]!.flags, contains(r'\Flagged'));
    expect((await t.pendingOps.allIncludingFailed(testAccountId)).map((o) => o.id), ['bad']);
  });
}
