import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/domain/repositories/repositories.dart';
import 'package:sortie/domain/services/services.dart';
import 'package:sortie/services/sync/account_sync_session.dart';
import 'package:sortie/services/sync/sync_engine.dart';

import '../../data/test_support.dart';
import '../../fakes/fake_imap_server.dart';

void main() {
  late TestDb t;
  late FakeImapServer server;
  late SyncEngine engine;
  late Directory spool;
  late MemoryCredentialStore creds;

  const tuning = SyncTuning(
    eventDebounce: Duration(milliseconds: 20),
    pollInterval: Duration(milliseconds: 200),
    backoffMin: Duration(milliseconds: 50),
    backoffMax: Duration(milliseconds: 200),
    otherFoldersEvery: Duration(hours: 1),
  );

  setUp(() async {
    t = await TestDb.open();
    await t.accounts.upsert(testAccount());
    creds = MemoryCredentialStore()..map[CredentialStore.accountPassword(testAccountId)] = 'pw';
    server = FakeImapServer();
    server.createMailbox('Archive', specialUse: SpecialUse.archive);
    spool = await Directory.systemTemp.createTemp('sortie-spool');
    engine = SyncEngine(
      accounts: t.accounts,
      folders: t.folders,
      messages: t.messages,
      pendingOps: t.pendingOps,
      credentials: creds,
      gatewayFactory: (a) => () => FakeImapGateway(server, name: 'c${server.connections.length}'),
      smtp: RecordingSmtpGateway(),
      clock: t.clock,
      spoolDir: spool,
      tuning: tuning,
      pruneBodyCache: t.messages.pruneBodyCache,
    );
  });

  tearDown(() async {
    await engine.stop();
    await t.close();
    await spool.delete(recursive: true);
  });

  test('Sent and the other folders are read right after start, not after the first cadence', () async {
    server.createMailbox('Sent', specialUse: SpecialUse.sent);
    final reply = makeHeader(subject: 'Re: hello', folderPath: 'Sent');
    server.deliver('Sent', reply, body: const MessageBody(text: 'my reply'));
    await engine.startAccount(testAccountId);
    MessageHeader? cached;
    for (var i = 0; i < 50 && cached == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      cached = (await t.messages.list(const MessageQuery(accountId: testAccountId, folderPath: 'Sent'))).firstOrNull;
    }
    expect(cached?.subject, 'Re: hello', reason: 'otherFoldersEvery is an hour here; the first pass must not wait for it');
  });

  test('delivered message reaches the repository and newInboxMessages', () async {
    final h = makeHeader(subject: 'welcome');
    server.deliver('INBOX', h, body: const MessageBody(text: 'hello there'));
    final first = engine.newInboxMessages(testAccountId).first;
    await engine.startAccount(testAccountId);

    final batch = await first.timeout(const Duration(seconds: 5));
    expect(batch.single.subject, 'welcome');
    expect(batch.single.accountId, testAccountId);
    final cached = await t.messages.list(const MessageQuery(accountId: testAccountId, folderPath: 'INBOX'));
    expect(cached.single.messageIdHash, h.messageIdHash);
    expect((await t.folders.all(testAccountId)).map((f) => f.path), containsAll(['INBOX', 'Archive']));
    await eventually(() => engine.capabilities(testAccountId) != null);

    // IDLE: a later delivery shows up without polling.
    await eventually(() async => (await engine.watchStatus(testAccountId).first).state == AccountSyncState.idling);
    final second = engine.newInboxMessages(testAccountId).first;
    server.deliver('INBOX', makeHeader(subject: 'second'));
    expect((await second.timeout(const Duration(seconds: 5))).single.subject, 'second');
    expect(server.connections.length, 2, reason: 'idle + command connection');

    // Body on demand is cached.
    final uid = cached.single.uid;
    final body = await engine.body(testAccountId, 'INBOX', uid);
    expect(body.text, 'hello there');
    expect((await t.messages.cachedBody(testAccountId, h.messageIdHash))!.text, 'hello there');
  });

  test('user actions apply optimistically and drain to the server', () async {
    final h = makeHeader(subject: 'to archive');
    final uid = server.deliver('INBOX', h);
    await engine.startAccount(testAccountId);
    await eventually(() async => (await t.messages.knownUids(testAccountId, 'INBOX')).isNotEmpty);
    await eventually(() async => (await engine.watchStatus(testAccountId).first).state == AccountSyncState.idling);

    await engine.markSeen(testAccountId, 'INBOX', uid);
    expect((await t.messages.byUid(testAccountId, 'INBOX', uid))!.isSeen, isTrue, reason: 'optimistic');
    await eventually(() => server.mailboxes['INBOX']!.messages[uid]!.flags.contains(r'\Seen'));

    await engine.move(testAccountId, 'INBOX', [uid], 'Archive');
    expect(await t.messages.byUid(testAccountId, 'INBOX', uid), isNull, reason: 'moved locally');
    await eventually(() => server.mailboxes['Archive']!.messages.length == 1);
    await eventually(() async => (await t.pendingOps.pending(testAccountId)).isEmpty);
    await eventually(() async => (await t.messages.byMessageIdHash(testAccountId, h.messageIdHash))?.uid == server.mailboxes['Archive']!.uids.single);
  });

  test('a send leaves over SMTP while the command connection is busy; the Sent copy follows', () async {
    server.createMailbox('Sent', specialUse: SpecialUse.sent);
    final uid = server.deliver('INBOX', makeHeader(subject: 'slow body'));
    final smtp = RecordingSmtpGateway();
    engine = SyncEngine(
      accounts: t.accounts,
      folders: t.folders,
      messages: t.messages,
      pendingOps: t.pendingOps,
      credentials: creds,
      gatewayFactory: (a) => () => FakeImapGateway(server, name: 'c${server.connections.length}'),
      smtp: smtp,
      clock: t.clock,
      spoolDir: spool,
      tuning: tuning,
    );
    await engine.startAccount(testAccountId);
    await eventually(() async => (await engine.watchStatus(testAccountId).first).state == AccountSyncState.idling);

    // Occupy the command chain with a body fetch that does not return.
    final gate = Completer<void>();
    server.bodyGate = gate.future;
    final body = engine.body(testAccountId, 'INBOX', uid);
    await eventually(() => server.commandLog.any((c) => c.contains('UID FETCH $uid BODY')));

    final raw = utf8.encode('From: test@example.com\r\nTo: bob@example.com\r\nSubject: urgent\r\nMessage-ID: <urgent@example.com>\r\n\r\nnow');
    await engine.send(testAccountId, 'id1', ['bob@example.com'], raw);
    await eventually(() => smtp.sent.length == 1, reason: 'SMTP must not wait for the IMAP command chain');
    expect(server.mailboxes['Sent']!.messages, isEmpty, reason: 'the Sent copy needs IMAP, which is still busy');
    final queued = await t.pendingOps.pending(testAccountId);
    expect(queued.single, isA<SendOp>().having((o) => o.smtpAccepted, 'smtpAccepted', true));

    gate.complete();
    await body;
    await eventually(() => server.mailboxes['Sent']!.messages.length == 1);
    await eventually(() async => (await t.pendingOps.pending(testAccountId)).isEmpty);
    expect(smtp.sent.length, 1, reason: 'never re-sent');
  });

  test('syncOnce refreshes the inbox without a running session and disconnects', () async {
    server.deliver('INBOX', makeHeader(subject: 'while frozen'));
    expect(engine.isRunning(testAccountId), isFalse);
    await engine.primeAccounts();
    expect(await engine.syncOnce(testAccountId), 1);
    expect((await t.messages.knownUids(testAccountId, 'INBOX')).length, 1);
    expect(server.connections, isEmpty, reason: 'one-shot: nothing left open');
    expect(engine.isRunning(testAccountId), isFalse);
  });

  test('auth failure is reported and connection loss reconnects with backoff', () async {
    server.refuseAuth = true;
    await engine.startAccount(testAccountId);
    await eventually(() async => (await engine.watchStatus(testAccountId).first).state == AccountSyncState.authFailed);
    server.refuseAuth = false;
    await engine.syncNow(testAccountId).catchError((_) {}); // pokes the session out of the auth wait
    await eventually(() async => (await engine.watchStatus(testAccountId).first).state == AccountSyncState.idling, timeout: const Duration(seconds: 10));

    server.commandsUntilDisconnect = 1;
    server.deliver('INBOX', makeHeader());
    await eventually(() async {
      final s = (await engine.watchStatus(testAccountId).first).state;
      return s == AccountSyncState.backoff || s == AccountSyncState.connecting;
    }, timeout: const Duration(seconds: 10));
    await eventually(() async => (await engine.watchStatus(testAccountId).first).state == AccountSyncState.idling, timeout: const Duration(seconds: 10));
    await eventually(() async => (await t.messages.knownUids(testAccountId, 'INBOX')).length == 1);
  });

  test('degrades to single-connection polling when the second login fails', () async {
    var logins = 0;
    engine = SyncEngine(
      accounts: t.accounts,
      folders: t.folders,
      messages: t.messages,
      pendingOps: t.pendingOps,
      credentials: creds,
      gatewayFactory: (a) => () {
        logins++;
        if (logins == 2) server.refuseConnections = true;
        if (logins == 3) server.refuseConnections = false;
        return FakeImapGateway(server, name: 'c$logins');
      },
      smtp: RecordingSmtpGateway(),
      clock: t.clock,
      spoolDir: spool,
      tuning: tuning,
    );
    await engine.startAccount(testAccountId);
    await eventually(() async => (await engine.watchStatus(testAccountId).first).state == AccountSyncState.idling);
    expect(server.connections.length, 1);
    server.deliver('INBOX', makeHeader(subject: 'polled'));
    await eventually(() async => (await t.messages.knownUids(testAccountId, 'INBOX')).length == 1, timeout: const Duration(seconds: 5));
    expect(server.commandLog.where((c) => c.endsWith('IDLE')), isEmpty);
  });
}
