import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/services/import/thunderbird/filter_rules_parser.dart';
import 'package:sortie/services/import/thunderbird/rule_mapper.dart';
import 'package:sortie/services/sorter/user_rules.dart';

import 'fixtures.dart';

Folder _f(String path, {String delimiter = '/'}) => Folder(accountId: 'a1', path: path, name: path.split(delimiter).last, delimiter: delimiter);

MessageHeader _h({String from = 'x@y.test', String subject = '', String? listId, List<String> to = const []}) => MessageHeader(
      accountId: 'a1',
      folderPath: 'INBOX',
      uid: 1,
      uidValidity: 1,
      messageIdHash: 'h',
      subject: subject,
      from: MailAddress(from),
      to: [for (final t in to) MailAddress(t)],
      listId: listId,
      date: DateTime(2026),
    );

void main() {
  final folders = [_f('INBOX'), _f('INBOX/Calix orders'), _f('INBOX/Vendors'), _f('INBOX/Alerts'), _f('Lists')];
  final filters = parseFilterRules(filterRules);
  const mapper = RuleMapper();
  final byName = {for (final f in filters) f.name: mapper.map(f, accountId: 'a1', folders: folders, priority: 10)};

  test('every real-world shape maps and matches', () {
    SortRule rule(String n) => byName[n]!.rules.single;

    expect(rule('from is').match.from, 'order.management@calix.com');
    expect(rule('from is').folderPath, 'INBOX/Calix orders');
    expect(rule('from is').match.matches(_h(from: 'Order.Management@calix.com')), isTrue);

    expect(rule('from ends with').match.fromEndsWith, '@calix.com');
    expect(rule('from ends with').match.matches(_h(from: 'a@calix.com')), isTrue);
    expect(rule('from ends with').match.matches(_h(from: 'a@calix.com.evil')), isFalse);

    expect(rule('subject contains').match.subjectContains, 'Calix Order Acknowledgement');
    expect(rule('subject is').match.subjectIs, 'SDP Error in Hickory');
    expect(rule('subject is').match.matches(_h(subject: 'sdp error in hickory')), isTrue);
    expect(rule('subject is').match.matches(_h(subject: 'Re: SDP Error in Hickory')), isFalse);

    final body = rule('body contains');
    expect(body.match.bodyContains, 'unreachable, please check (urgent)');
    expect(body.match.matches(_h()), isFalse, reason: 'no body at classify time -> no match');
    expect(body.match.matches(_h(), bodyText: 'Host UNREACHABLE, please check (urgent) now'), isTrue);

    final and2 = rule('and of two');
    expect(and2.match.from, 'order.management@calix.com');
    expect(and2.match.subjectContains, 'Calix Order Acknowledgement');
    expect(and2.match.any, isFalse);
    expect(and2.match.matches(_h(from: 'order.management@calix.com', subject: 'x')), isFalse);
    expect(and2.match.matches(_h(from: 'order.management@calix.com', subject: 'Calix Order Acknowledgement 12')), isTrue);

    expect(rule('disabled one').enabled, isFalse);

    final dropped = byName['status read dropped']!;
    expect(dropped.droppedStatusRead, isTrue);
    expect(dropped.rules.single.match.subjectIs, 'SDP Error in Hickory');

    final or2 = rule('or of two');
    expect(or2.match.any, isTrue);
    expect(or2.match.matches(_h(from: 'a@vendor.test')), isTrue);
    expect(or2.match.matches(_h(subject: 'Your INVOICE')), isTrue);
    expect(or2.match.matches(_h()), isFalse);

    final custom = rule('custom header');
    expect(custom.match.headerContains?.name, 'List-Id');
    expect(custom.folderPath, 'Lists');
    expect(custom.match.matches(_h(listId: '<dev.lists.example.test>')), isTrue);

    expect(byName['mark read only']!.imported, isFalse);
    expect(byName['mark read only']!.skippedReason, contains('Mark read'));

    final copy = byName['copy with extra action']!;
    expect(copy.imported, isTrue);
    expect(copy.missingFolder, isTrue);
    expect(copy.folderPath, 'INBOX/Nope/Missing');
    expect(copy.rules.single.match.toContains, 'team@example.test');
  });

  test('ids are stable and rules round-trip through JSON', () {
    final a = byName['and of two']!.rules.single;
    final b = mapper.map(filters.firstWhere((f) => f.name == 'and of two'), accountId: 'a1', folders: folders, priority: 99).rules.single;
    expect(a.id, b.id);
    expect(a.id, startsWith('tb-'));
    for (final o in byName.values) {
      for (final r in o.rules) {
        final back = SortRule.fromJson(r.toJson());
        expect(back.toJson(), r.toJson());
        expect(back.enabled, r.enabled);
        expect(back.name, r.name);
      }
    }
  });

  test('OR with colliding fields splits into one rule per term', () {
    final f = parseFilterRules('name="two froms"\nenabled="yes"\naction="Move to folder"\nactionValue="imap://u@h/INBOX/Vendors"\ncondition="OR (from,is,a@x.test) OR (from,is,b@x.test)"\n').single;
    final o = mapper.map(f, accountId: 'a1', folders: folders, priority: 10);
    expect(o.rules.length, 2);
    expect(o.rules.map((r) => r.match.from), ['a@x.test', 'b@x.test']);
    expect(o.rules.map((r) => r.id).toSet().length, 2);
  });

  test('folder resolution normalises delimiter and case', () {
    final dotted = [_f('INBOX', delimiter: '.'), _f('INBOX.Calix Orders', delimiter: '.')];
    expect(RuleMapper.resolveFolder('INBOX/Calix orders', dotted), (path: 'INBOX.Calix Orders', missing: false));
    expect(RuleMapper.resolveFolder('INBOX/Missing', dotted), (path: 'INBOX.Missing', missing: true));
    expect(RuleMapper.resolveFolder('Calix orders', folders), (path: 'INBOX/Calix orders', missing: false), reason: 'INBOX prefix tolerated');
  });

  test('folder hints merge and dedupe', () {
    expect(FolderHints.merge('', ['from a@b.c']), 'Rules: from a@b.c');
    expect(FolderHints.merge('Vendor invoices', ['from a@b.c']), 'Vendor invoices\nRules: from a@b.c');
    expect(FolderHints.merge('Vendor invoices\nRules: from a@b.c', ['from a@b.c', "subject contains 'x'"]), "Vendor invoices\nRules: from a@b.c | subject contains 'x'");
  });
}
