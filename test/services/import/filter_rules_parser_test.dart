import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/services/import/thunderbird/filter_rules_parser.dart';

import 'fixtures.dart';

void main() {
  test('parses all records with conditions and actions', () {
    final filters = parseFilterRules(filterRules);
    expect(filters.length, 12);
    expect(filters.first.name, 'from is');
    expect(filters.first.enabled, isTrue);
    expect(filters.first.conditions.single.field, 'from');
    expect(filters.first.conditions.single.op, 'is');
    expect(filters.first.conditions.single.value, 'order.management@calix.com');
    expect(filters.first.actions.single.type, 'Move to folder');
    expect(filters.first.actions.single.value, 'imap://jane%40example.test@mail.example.test/INBOX/Calix%20orders');

    final disabled = filters.firstWhere((f) => f.name == 'disabled one');
    expect(disabled.enabled, isFalse);

    final and2 = filters.firstWhere((f) => f.name == 'and of two');
    expect(and2.conditions.length, 2);
    expect(and2.anyCondition, isFalse);

    final or2 = filters.firstWhere((f) => f.name == 'or of two');
    expect(or2.anyCondition, isTrue);
    expect(or2.conditions.map((c) => c.value), ['a@vendor.test', 'invoice']);

    final custom = filters.firstWhere((f) => f.name == 'custom header');
    expect(custom.conditions.single.field, 'List-Id');
    expect(custom.conditions.single.op, 'contains');

    final multi = filters.firstWhere((f) => f.name == 'copy with extra action');
    expect(multi.actions.map((a) => a.type), ['Mark flagged', 'Copy to folder']);
    expect(multi.folderActions.single.value, endsWith('Nope%2FMissing'));

    final markRead = filters.firstWhere((f) => f.name == 'mark read only');
    expect(markRead.folderActions, isEmpty);
  });

  test('values keep commas and parentheses', () {
    final c = parseCondition('AND (body,contains,unreachable, please check (urgent)) AND (subject,is,a (b), c)');
    expect(c.terms.length, 2);
    expect(c.terms[0].value, 'unreachable, please check (urgent)');
    expect(c.terms[1].value, 'a (b), c');
    expect(c.any, isFalse);
    final o = parseCondition('OR (from,is,a@b.c) OR ("X-Custom",contains,x,y)');
    expect(o.any, isTrue);
    expect(o.terms[1].field, 'X-Custom');
    expect(o.terms[1].value, 'x,y');
  });

  test('folder URI decoding', () {
    expect(folderPathFromUri('imap://jane%40example.test@mail.example.test/INBOX/Calix%20orders'), 'INBOX/Calix orders');
    expect(folderPathFromUri('imap://u@h/Lists'), 'Lists');
    expect(folderPathFromUri('imap://u@h/INBOX/Nope%2FMissing'), 'INBOX/Nope/Missing');
    expect(folderPathFromUri('mailbox://nobody@Local%20Folders'), isNull);
  });
}
