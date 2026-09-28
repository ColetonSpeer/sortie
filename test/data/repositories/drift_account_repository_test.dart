import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';

import '../test_support.dart';

void main() {
  test('schema v3: identities round-trip signatureHtml (present and null)', () async {
    final t = await TestDb.open();
    expect(t.db.schemaVersion, 3);
    await t.accounts.upsert(testAccount());
    await t.accounts.upsertIdentity(const Identity(id: 'i1', accountId: testAccountId, name: 'T', email: 'test@example.com', signature: 'sig', signatureHtml: '<b>sig</b>', isDefault: true));
    await t.accounts.upsertIdentity(const Identity(id: 'i2', accountId: testAccountId, name: 'T', email: 'alias@example.com', signature: 'plain'));
    final list = await t.accounts.identities(testAccountId);
    expect(list.map((i) => i.id), ['i1', 'i2']);
    expect(list[0].signatureHtml, '<b>sig</b>');
    expect(list[1].signatureHtml, isNull);
    // Update clears the HTML again.
    await t.accounts.upsertIdentity(const Identity(id: 'i1', accountId: testAccountId, name: 'T', email: 'test@example.com', signature: 'sig', isDefault: true));
    expect((await t.accounts.identities(testAccountId)).first.signatureHtml, isNull);
    final cols = await t.db.customSelect('PRAGMA table_info(identities)').get();
    expect(cols.map((r) => r.data['name']), contains('signature_html'));
    await t.close();
  });
}
