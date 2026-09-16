import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/data/local/repositories/pending_op_codec.dart';
import 'package:sortie/domain/entities/entities.dart';

import '../test_support.dart';

void main() {
  final at = DateTime.utc(2026, 9, 16, 12);

  PendingOp roundTrip(PendingOp op) => PendingOpCodec.decode(
        id: op.id,
        accountId: op.accountId,
        createdAt: op.createdAt,
        type: PendingOpCodec.typeOf(op),
        payloadJson: PendingOpCodec.encode(op),
      );

  test('SetFlagsOp', () {
    final op = SetFlagsOp(id: '1', accountId: 'a', createdAt: at, folderPath: 'INBOX', uidValidity: 5, messageIdHashes: const ['h1', 'h2'], uids: const [10, 11], add: {r'\Seen', SortieKeywords.pending}, remove: {r'\Flagged'});
    final d = roundTrip(op) as SetFlagsOp;
    expect(d.folderPath, 'INBOX');
    expect(d.uidValidity, 5);
    expect(d.messageIdHashes, ['h1', 'h2']);
    expect(d.uids, [10, 11]);
    expect(d.add, {r'\Seen', SortieKeywords.pending});
    expect(d.remove, {r'\Flagged'});
    expect(d.createdAt, at);
  });

  test('MoveOp', () {
    final d = roundTrip(MoveOp(id: '2', accountId: 'a', createdAt: at, fromFolder: 'INBOX', toFolder: 'Work/Invoices', uidValidity: 1, messageIdHashes: const ['h'], uids: const [3], cause: 'auto')) as MoveOp;
    expect(d.fromFolder, 'INBOX');
    expect(d.toFolder, 'Work/Invoices');
    expect(d.cause, 'auto');
    expect(d.uids, [3]);
  });

  test('DeleteOp', () {
    final d = roundTrip(DeleteOp(id: '3', accountId: 'a', createdAt: at, folderPath: 'Trash', uidValidity: 2, messageIdHashes: const ['h'], uids: const [9], permanent: true)) as DeleteOp;
    expect(d.permanent, isTrue);
    expect(d.folderPath, 'Trash');
  });

  test('AppendOp', () {
    final d = roundTrip(AppendOp(id: '4', accountId: 'a', createdAt: at, folderPath: 'Drafts', rawMessagePath: '/x/y.eml', flags: {r'\Draft', r'\Seen'})) as AppendOp;
    expect(d.rawMessagePath, '/x/y.eml');
    expect(d.flags, {r'\Draft', r'\Seen'});
  });

  test('SendOp', () {
    final d = roundTrip(SendOp(id: '5', accountId: 'a', createdAt: at, identityId: 'i', rawMessagePath: '/s.eml', recipients: const ['a@b', 'c@d'], smtpAccepted: true)) as SendOp;
    expect(d.identityId, 'i');
    expect(d.recipients, ['a@b', 'c@d']);
    expect(d.smtpAccepted, isTrue);
  });

  test('unknown type is a FormatException', () {
    expect(() => PendingOpCodec.decode(id: 'x', accountId: 'a', createdAt: at, type: 'nope', payloadJson: '{}'), throwsFormatException);
  });

  test('repository round trip with markSmtpAccepted and retry schedule', () async {
    final t = await TestDb.open();
    addTearDown(t.close);
    final op = SendOp(id: 's', accountId: 'a', createdAt: at, identityId: 'i', rawMessagePath: '/s.eml', recipients: const ['a@b']);
    await t.pendingOps.enqueue(op);
    expect((await t.pendingOps.pending('a')).single, isA<SendOp>().having((o) => o.smtpAccepted, 'accepted', false));
    await t.pendingOps.markSmtpAccepted('s');
    expect((await t.pendingOps.pending('a')).single, isA<SendOp>().having((o) => o.smtpAccepted, 'accepted', true));
    await t.pendingOps.markFailed('s', 'boom');
    expect(await t.pendingOps.pending('a'), isEmpty);
    t.clock.advance(const Duration(seconds: 31));
    expect((await t.pendingOps.pending('a')).length, 1);
    expect(await t.pendingOps.watchCount('a').first, 1);
    await t.pendingOps.markDone('s');
    expect(await t.pendingOps.watchCount('a').first, 0);
  });
}
