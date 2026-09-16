import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/data/mail/imap_gateway.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/domain/repositories/repositories.dart';
import 'package:sortie/services/sync/folder_synchronizer.dart';

import '../../data/test_support.dart';
import '../../fakes/fake_imap_server.dart';

void main() {
  late TestDb t;
  late FakeImapServer server;
  late FakeImapGateway gw;
  late FolderSynchronizer sync;

  setUp(() async {
    t = await TestDb.open();
    await t.accounts.upsert(testAccount());
    server = FakeImapServer();
    gw = FakeImapGateway(server);
    await gw.connect(testAccount(), 'pw');
    sync = FolderSynchronizer(accountId: testAccountId, messages: t.messages, folders: t.folders, clock: t.clock, initialWindow: 5, backfillPage: 2);
  });

  tearDown(() => t.close());

  Future<List<MessageHeader>> inbox() => t.messages.list(const MessageQuery(accountId: testAccountId, folderPath: 'INBOX'));

  test('initial sync caches the newest window and reports backfill', () async {
    for (var i = 0; i < 8; i++) {
      server.deliver('INBOX', makeHeader(subject: 'm$i'));
    }
    final r = await sync.sync(gw, 'INBOX');
    expect(r.initial, isTrue);
    expect(r.newMessages.length, 5);
    expect(r.backfillRemaining, 3);
    expect((await inbox()).length, 5);
    expect(await t.messages.knownUids(testAccountId, 'INBOX'), [4, 5, 6, 7, 8]);
    final f = await t.folders.byPath(testAccountId, 'INBOX');
    expect(f!.uidValidity, server.mailboxes['INBOX']!.uidValidity);
    expect(f.uidNext, 9);

    expect(await sync.backfill(gw, 'INBOX'), 2);
    expect(await t.messages.knownUids(testAccountId, 'INBOX'), [2, 3, 4, 5, 6, 7, 8]);
    expect(await sync.backfill(gw, 'INBOX'), 1);
    expect(await sync.backfill(gw, 'INBOX'), 0);
  });

  test('new UIDs, flag changes and deletions are picked up incrementally', () async {
    final u1 = server.deliver('INBOX', makeHeader(subject: 'first'));
    final u2 = server.deliver('INBOX', makeHeader(subject: 'second'));
    await sync.sync(gw, 'INBOX');

    final u3 = server.deliver('INBOX', makeHeader(subject: 'third'));
    var r = await sync.sync(gw, 'INBOX');
    expect(r.initial, isFalse);
    expect(r.newMessages.map((h) => h.uid), [u3]);
    expect(r.flagChanges, isEmpty);
    expect(r.removedUids, isEmpty);

    server.externalSetFlags('INBOX', u1, add: {r'\Seen'});
    r = await sync.sync(gw, 'INBOX');
    expect(r.newMessages, isEmpty);
    expect(r.flagChanges.map((h) => h.uid), [u1]);
    expect(r.flagChanges.single.isSeen, isTrue);
    expect((await t.messages.byUid(testAccountId, 'INBOX', u1))!.isSeen, isTrue);

    server.externalDelete('INBOX', u2);
    r = await sync.sync(gw, 'INBOX');
    expect(r.removedUids, [u2]);
    expect(await t.messages.knownUids(testAccountId, 'INBOX'), [u1, u3]);

    // Nothing changed: no churn.
    r = await sync.sync(gw, 'INBOX');
    expect(r.newMessages, isEmpty);
    expect(r.flagChanges, isEmpty);
    expect(r.removedUids, isEmpty);
  });

  test('UIDVALIDITY change relinks cached rows by Message-ID', () async {
    final h1 = makeHeader(subject: 'keep me');
    final h2 = makeHeader(subject: 'and me');
    server.deliver('INBOX', h1);
    server.deliver('INBOX', h2);
    await sync.sync(gw, 'INBOX');
    final oldUv = server.mailboxes['INBOX']!.uidValidity;
    await t.messages.cacheBodyText(testAccountId, h1.messageIdHash, 'body one');

    server.externalDelete('INBOX', 1);
    server.bumpUidValidity('INBOX');
    final newUv = server.mailboxes['INBOX']!.uidValidity;
    expect(newUv, isNot(oldUv));

    final r = await sync.sync(gw, 'INBOX');
    expect(r.uidValidityChanged, isTrue);
    expect(r.newMessages, isEmpty, reason: 'same messages, only UIDs changed');
    final rows = await inbox();
    expect(rows.length, 1);
    expect(rows.single.messageIdHash, h2.messageIdHash);
    expect(rows.single.uid, 1);
    expect(rows.single.uidValidity, newUv);
    expect((await t.folders.byPath(testAccountId, 'INBOX'))!.uidValidity, newUv);
    // Body cache of the removed message is gone; orphan cleanup ran.
    expect(await t.messages.cachedBody(testAccountId, h1.messageIdHash), isNull);
  });

  test('works without CONDSTORE by re-fetching flags over the window', () async {
    server = FakeImapServer(supportsCondStore: false);
    gw = FakeImapGateway(server);
    await gw.connect(testAccount(), 'pw');
    final u = server.deliver('INBOX', makeHeader());
    await sync.sync(gw, 'INBOX');
    server.externalSetFlags('INBOX', u, add: {r'\Flagged'});
    final r = await sync.sync(gw, 'INBOX');
    expect(r.flagChanges.single.isFlagged, isTrue);
    expect(gw.selectedPath, 'INBOX');
    expect(server.commandLog.any((c) => c.contains('(FLAGS)')), isTrue);
  });

  test('gateway errors propagate as ImapGatewayException', () async {
    server.deliver('INBOX', makeHeader());
    await sync.sync(gw, 'INBOX');
    server.commandsUntilDisconnect = 1;
    await expectLater(sync.sync(gw, 'INBOX'), throwsA(isA<ImapGatewayException>().having((e) => e.isConnectionLost, 'lost', true)));
  });
}
