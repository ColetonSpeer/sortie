import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/domain/repositories/repositories.dart';

import '../test_support.dart';

void main() {
  late TestDb t;

  setUp(() async => t = await TestDb.open());
  tearDown(() => t.close());

  MessageHeader h(int uid, {String subject = 'Subject', String folder = 'INBOX', String from = 'alice@example.com', Set<String> flags = const {}}) =>
      makeHeader(subject: subject, folderPath: folder, from: from, accountId: testAccountId, flags: flags).copyWith(uid: uid, uidValidity: 7);

  test('upsert, list ordering, byUid and flags round trip', () async {
    final a = h(1, subject: 'older');
    final b = h(2, subject: 'newer').copyWith(flags: {r'\Seen', SortieKeywords.pending});
    await t.messages.upsertHeaders([a, b]);
    final list = await t.messages.list(const MessageQuery(accountId: testAccountId, folderPath: 'INBOX'));
    expect(list.map((x) => x.subject), ['newer', 'older']);
    final got = (await t.messages.byUid(testAccountId, 'INBOX', 2))!;
    expect(got.flags, {r'\Seen', SortieKeywords.pending});
    expect(got.hasSortiePending, isTrue);
    expect(got.messageId, b.messageId);
    expect(got.to.single.email, 'test@example.com');
    expect(got.uidValidity, 7);
    expect(await t.messages.maxUid(testAccountId, 'INBOX'), 2);
    expect(await t.messages.knownUids(testAccountId, 'INBOX'), [1, 2]);

    await t.messages.updateFlags(testAccountId, 'INBOX', {1: {r'\Flagged'}});
    expect((await t.messages.byUid(testAccountId, 'INBOX', 1))!.flags, {r'\Flagged'});
  });

  test('FTS search covers subject, sender and cached body text', () async {
    final inv = h(1, subject: 'Invoice 2026-09 from Acme', from: 'billing@acme.example');
    final news = h(2, subject: 'Weekly newsletter', from: 'news@list.example');
    await t.messages.upsertHeaders([inv, news]);
    expect((await t.messages.search(testAccountId, 'invoice')).single.uid, 1);
    expect((await t.messages.search(testAccountId, 'acme')).single.uid, 1);
    expect((await t.messages.search(testAccountId, 'newslet')).single.uid, 2, reason: 'prefix match');
    expect(await t.messages.search(testAccountId, 'zebra'), isEmpty);
    expect(await t.messages.search(testAccountId, 'inv "unbalanced'), isEmpty, reason: 'quotes never break the query');

    await t.messages.cacheBodyText(testAccountId, news.messageIdHash, 'this issue covers the zebra migration');
    expect((await t.messages.search(testAccountId, 'zebra')).single.uid, 2);
    expect((await t.messages.byUid(testAccountId, 'INBOX', 2))!.snippet, startsWith('this issue covers'));

    // Re-upserting the header keeps the indexed body and the snippet.
    await t.messages.upsertHeaders([news.copyWith(flags: {r'\Seen'})]);
    expect((await t.messages.search(testAccountId, 'zebra')).single.uid, 2);
    expect((await t.messages.byUid(testAccountId, 'INBOX', 2))!.snippet, startsWith('this issue covers'));

    // Removing the last copy drops the FTS row.
    await t.messages.removeByUids(testAccountId, 'INBOX', [2]);
    expect(await t.messages.search(testAccountId, 'zebra'), isEmpty);
    expect(await t.messages.search(testAccountId, 'invoice'), isNotEmpty);
  });

  test('moveLocally moves the row, keeps hash and sets new uid or null', () async {
    final a = h(10, subject: 'a');
    final b = h(11, subject: 'b');
    await t.messages.upsertHeaders([a, b]);
    await t.messages.moveLocally(testAccountId, 'INBOX', [10, 11], 'Archive', newUids: {10: 3});
    expect(await t.messages.knownUids(testAccountId, 'INBOX'), isEmpty);
    final moved = await t.messages.list(const MessageQuery(accountId: testAccountId, folderPath: 'Archive'));
    expect(moved.length, 2);
    final ma = moved.singleWhere((x) => x.messageIdHash == a.messageIdHash);
    final mb = moved.singleWhere((x) => x.messageIdHash == b.messageIdHash);
    expect(ma.uid, 3);
    expect(ma.uidValidity, 7);
    expect(mb.uid, 0, reason: 'null uid maps to 0 until relinked');
    expect(await t.messages.knownUids(testAccountId, 'Archive'), [3]);

    await t.messages.relinkUid(testAccountId, 'Archive', b.messageIdHash, 4, 9);
    expect(await t.messages.knownUids(testAccountId, 'Archive'), [3, 4]);
    expect((await t.messages.byUid(testAccountId, 'Archive', 4))!.uidValidity, 9);
    // Search still finds moved rows.
    expect((await t.messages.search(testAccountId, 'b')).single.folderPath, 'Archive');
  });

  test('invalidateUids + upsert relinks, deleteOrphans drops the rest', () async {
    final a = h(1, subject: 'stays');
    final b = h(2, subject: 'gone');
    await t.messages.upsertHeaders([a, b]);
    await t.messages.invalidateUids(testAccountId, 'INBOX');
    expect(await t.messages.knownUids(testAccountId, 'INBOX'), isEmpty);
    await t.messages.upsertHeaders([a.copyWith(uid: 100, uidValidity: 8)]);
    await t.messages.deleteOrphans(testAccountId, 'INBOX');
    final rows = await t.messages.list(const MessageQuery(accountId: testAccountId, folderPath: 'INBOX'));
    expect(rows.single.uid, 100);
    expect(rows.single.uidValidity, 8);
    expect(await t.messages.byMessageIdHash(testAccountId, b.messageIdHash), isNull);
  });

  test('body cache: LRU pruning evicts least recently accessed first', () async {
    final a = h(1), b = h(2), c = h(3);
    await t.messages.upsertHeaders([a, b, c]);
    await t.messages.cacheBody(testAccountId, a.messageIdHash, MessageBody(text: 'a' * 100, html: '<p>${'a' * 100}</p>'));
    t.clock.advance(const Duration(seconds: 1));
    await t.messages.cacheBody(testAccountId, b.messageIdHash, MessageBody(text: 'b' * 100));
    t.clock.advance(const Duration(seconds: 1));
    await t.messages.cacheBody(testAccountId, c.messageIdHash, MessageBody(text: 'c' * 100, inlineParts: {'cid1': List.filled(50, 7)}));
    t.clock.advance(const Duration(seconds: 1));
    final body = await t.messages.cachedBody(testAccountId, a.messageIdHash); // touch a
    expect(body!.html, isNotNull);
    final cc = await t.messages.cachedBody(testAccountId, c.messageIdHash);
    expect(cc!.inlineParts['cid1'], List.filled(50, 7));

    final total = await t.messages.bodyCacheSize();
    final removed = await t.messages.pruneBodyCache(total - 1);
    expect(removed, 1);
    expect(await t.messages.cachedBody(testAccountId, b.messageIdHash), isNull, reason: 'b was least recently used');
    expect(await t.messages.cachedBody(testAccountId, a.messageIdHash), isNotNull);
  });

  test('watch emits on changes', () async {
    final stream = t.messages.watch(const MessageQuery(accountId: testAccountId, folderPath: 'INBOX'));
    final expectation = expectLater(stream.map((l) => l.length), emitsInOrder([0, 1]));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await t.messages.upsertHeaders([h(1)]);
    await expectation;
  });
}
