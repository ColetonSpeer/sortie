import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/data/local/database.dart' as db;
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/services/sorter/rule_advisor.dart';
import 'package:sortie/services/sorter/sort_evidence.dart';

import '../../fixtures/corpus.dart';
import 'test_support.dart';

const advisorAi = AiSettings(usage: AiUsageMode.advisor, kind: AiProviderKind.openAiCompat, baseUrl: 'http://10.0.0.5:11434/v1', model: 'llama3');
Map<String, dynamic> suggestionsJson(List<Map<String, dynamic>> items) => {'suggestions': items};

Future<List<db.SortEvidenceData>> evidence(Harness h) => h.database.select(h.database.sortEvidence).get();

void main() {
  late Harness h;

  group('deleted mail as evidence', () {
    test('recent Trash is scanned once; repeat runs do not count it again; the model sees "deleted" rows', () async {
      h = await Harness.create(ai: advisorAi);
      for (var i = 0; i < 4; i++) {
        h.messages.headers.add(Corpus.msg(folder: Corpus.trash, from: 'alerts@prtg.example', subject: 'Sensor down $i', daysAgo: i + 1));
      }
      h.messages.headers.add(Corpus.msg(folder: Corpus.trash, from: 'old@prtg.example', subject: 'ancient', daysAgo: 400));
      h.fake.script = (req) => suggestionsJson([]);
      await h.sorter.advisor.runNow(Corpus.account);
      final rows = await evidence(h);
      final deleted = rows.where((r) => r.kind == EvidenceKind.trashed.name).toList();
      expect(deleted.single.fromAddr, 'alerts@prtg.example');
      expect(deleted.single.seenCount, 4);
      expect(rows.where((r) => r.fromAddr == 'old@prtg.example'), isEmpty, reason: 'older than the lookback');
      expect(h.fake.lastRequest.user, contains('deleted x4 | from: alerts@prtg.example'));
      expect(h.fake.lastRequest.system.single.text, contains('"deleted" rows are mail the owner threw away'));

      await h.sorter.advisor.runNow(Corpus.account, force: true);
      final again = (await evidence(h)).where((r) => r.kind == EvidenceKind.trashed.name).single;
      expect(again.seenCount, 4, reason: 'idempotent');
    });
  });

  group('new folders', () {
    test('a <new> proposal becomes a suggestion that creates the folder on accept, following the account convention', () async {
      h = await Harness.create(ai: advisorAi);
      for (var i = 0; i < 3; i++) {
        h.messages.headers.add(Corpus.msg(folder: Corpus.trash, from: 'orders@supplier.example', subject: 'Order $i shipped', daysAgo: i + 1));
      }
      h.fake.script = (req) => suggestionsJson([
            {'kind': 'from', 'value': 'orders@supplier.example', 'folder': '<new>', 'newFolder': 'Supplier orders', 'placement': 'top', 'rationale': 'deleted repeatedly, worth keeping', 'confidence': 0.8, 'exampleIds': ['e1']},
            {'kind': 'domain', 'value': 'bank.example', 'folder': '<new>', 'newFolder': 'Receipts', 'rationale': 'already a folder', 'confidence': 0.8, 'exampleIds': <String>[]},
            {'kind': 'from', 'value': 'ops@apollo.example', 'folder': '<new>', 'newFolder': 'Alerts', 'placement': 'under', 'parent': Corpus.apollo, 'rationale': 'belongs with Apollo', 'confidence': 0.8, 'exampleIds': <String>[]},
          ]);
      final run = await h.sorter.advisor.runNow(Corpus.account);
      expect(run.modelSuggestions, 3);
      expect((await h.sorter.suggestions.pending(Corpus.account)).map((s) => s.folderPath), contains('${Corpus.apollo}/Alerts'), reason: 'a subfolder of an existing folder');
      expect(((((h.fake.lastRequest.jsonSchema['properties'] as Map)['suggestions'] as Map)['items'] as Map)['properties'] as Map)['parent'], isNotNull);
      final schema = (((h.fake.lastRequest.jsonSchema['properties'] as Map)['suggestions'] as Map)['items'] as Map)['properties'] as Map;
      expect(((schema['folder'] as Map)['enum'] as List), contains('<new>'));
      expect(((schema['placement'] as Map)['enum'] as List), ['inbox', 'top', 'under']);
      final pending = await h.sorter.suggestions.pending(Corpus.account);
      final fresh = pending.firstWhere((s) => s.createsFolder);
      expect(fresh.folderPath, 'Supplier orders', reason: 'this account keeps folders at the top level');
      final existing = pending.firstWhere((s) => !s.createsFolder);
      expect(existing.folderPath, Corpus.receipts, reason: 'a "new" name that already exists resolves to that folder');
      expect(fresh.toJson()['newFolder'], isTrue);

      // Accepting: no create hook on this device -> refused, nothing written.
      await expectLater(h.sorter.advisor.accept(fresh.id), throwsA(isA<StateError>()));
      expect(await h.sorter.rules.load(Corpus.account), isEmpty);
    });

    test('with a create hook the folder is created before the rule', () async {
      final created = <String>[];
      h = await Harness.create(ai: advisorAi, createFolder: (a, p) async => created.add(p));
      h.messages.headers.add(Corpus.msg(folder: Corpus.trash, from: 'orders@supplier.example', subject: 'Order shipped', daysAgo: 1));
      h.fake.script = (req) => suggestionsJson([
            {'kind': 'from', 'value': 'orders@supplier.example', 'folder': '<new>', 'newFolder': 'Supplier orders', 'rationale': 'x', 'confidence': 0.8, 'exampleIds': ['e1']},
          ]);
      await h.sorter.advisor.runNow(Corpus.account);
      final s = (await h.sorter.suggestions.pending(Corpus.account)).single;
      final ruleId = await h.sorter.advisor.accept(s.id);
      expect(created, ['Supplier orders']);
      final rule = (await h.sorter.rules.load(Corpus.account)).singleWhere((r) => r.id == ruleId);
      expect(rule.folderPath, 'Supplier orders');
    });

    test('folders under INBOX get INBOX-prefixed paths', () async {
      h = await Harness.create(ai: advisorAi);
      for (final name in ['Tickets', 'Meetings', 'Orders']) {
        await h.database.into(h.database.folders).insert(db.FoldersCompanion.insert(
              accountId: Corpus.account,
              path: 'INBOX.$name',
              name: name,
              delimiter: '.',
              specialUse: const Value('none'),
            ));
      }
      for (final path in [Corpus.invoices, Corpus.newsletters, Corpus.family, Corpus.receipts, Corpus.apollo, Corpus.oldArchive]) {
        await (h.database.delete(h.database.folders)..where((f) => f.path.equals(path))).go();
      }
      expect(await h.sorter.advisor.newFolderPath(Corpus.account, 'Suppliers'), 'INBOX.Suppliers');
      expect(await h.sorter.advisor.newFolderPath(Corpus.account, 'Newsletters', placement: FolderPlacement.top), 'Newsletters', reason: 'the model may keep reference mail out of the inbox tree');
      expect(await h.sorter.advisor.newFolderPath(Corpus.account, 'Orders', placement: FolderPlacement.inbox), 'INBOX.Orders');
      expect(RuleAdvisor.replacePlacement('INBOX.Suppliers', FolderPlacement.top), 'Suppliers');
      expect(RuleAdvisor.replacePlacement('Suppliers', FolderPlacement.inbox), 'INBOX.Suppliers');
      expect(await h.sorter.advisor.newFolderPath(Corpus.account, 'Orders', placement: FolderPlacement.under, parent: 'INBOX.Tickets'), 'INBOX.Tickets.Orders');
      expect(RuleAdvisor.replacePlacement('INBOX.Tickets.Orders', FolderPlacement.top), 'Orders');
      expect(RuleAdvisor.replacePlacement('Orders', FolderPlacement.under, parent: 'INBOX.Tickets'), 'INBOX.Tickets.Orders');
      expect(RuleAdvisor.cleanFolderName('  Vendor/Invoices!! '), 'Vendor Invoices');
      expect(RuleAdvisor.cleanFolderName('///'), isNull);
    });
  });

  group('folder review', () {
    test('runs on the first pass, proposes subfolders only, then waits a month (a day after Ask now)', () async {
      h = await Harness.create(ai: advisorAi);
      // Make Invoices big enough to be reviewed.
      for (var i = 0; i < 45; i++) {
        h.messages.headers.add(Corpus.msg(folder: Corpus.invoices, from: i.isEven ? 'billing@calix.example' : 'ar@adtran.example', subject: 'Invoice $i', daysAgo: i));
      }
      await h.sorter.profiles.bootstrap(Corpus.account, h.settings.config);
      h.messages.headers.add(Corpus.msg(folder: Corpus.trash, from: 'x@y.example', subject: 'junk', daysAgo: 1));
      var reviews = 0;
      h.fake.script = (req) {
        if (req.system.single.text.startsWith(RuleAdvisor.reviewInstructions)) {
          reviews++;
          expect(req.system.single.text, contains('### ${Corpus.invoices}'));
          expect(req.user, contains(RegExp('${RegExp.escape(Corpus.invoices)}: \\d+ messages')));
          return suggestionsJson([
            {'kind': 'from', 'value': 'billing@calix.example', 'folder': '<new>', 'newFolder': 'Calix', 'placement': 'under', 'parent': Corpus.invoices, 'rationale': 'half the folder is Calix billing', 'confidence': 0.8, 'exampleIds': <String>[]},
            {'kind': 'from', 'value': 'ar@adtran.example', 'folder': Corpus.receipts, 'rationale': 'not a subfolder', 'confidence': 0.9, 'exampleIds': <String>[]},
          ]);
        }
        return suggestionsJson([]);
      };
      final run = await h.sorter.advisor.runNow(Corpus.account);
      expect(reviews, 1);
      expect(run.modelSuggestions, 1, reason: 'the non-subfolder answer is ignored in a review');
      final s = (await h.sorter.suggestions.pending(Corpus.account)).single;
      expect(s.createsFolder, isTrue);
      expect(s.folderPath, '${Corpus.invoices}/Calix');
      expect(h.settings.strings['advisor.lastFolderReview.${Corpus.account}'], isNotNull);

      await h.sorter.advisor.runNow(Corpus.account);
      expect(reviews, 1, reason: 'Ask now within a day does not review again');
      h.clock.advance(const Duration(days: 2));
      await h.sorter.advisor.runNow(Corpus.account);
      expect(reviews, 2, reason: 'Ask now after a day reviews again');
      h.clock.advance(const Duration(days: 10));
      await h.sorter.advisor.runNow(Corpus.account, force: false);
      expect(reviews, 2, reason: 'the scheduled pass waits for the monthly interval');
    });
  });
}
