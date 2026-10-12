import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/data/ai/ai_provider.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/domain/services/services.dart';
import 'package:sortie/services/sorter/rule_advisor.dart';
import 'package:sortie/services/sorter/sort_evidence.dart';
import 'package:sortie/services/sorter/user_rules.dart';

import '../../fixtures/corpus.dart';
import 'test_support.dart';

const advisorAi = AiSettings(kind: AiProviderKind.openAiCompat, baseUrl: 'http://10.0.0.5:11434/v1', model: 'llama3');

ClassificationInput inp(MessageHeader h) => ClassificationInput(header: h);

MessageHeader arrival(String from) => Corpus.arrivals().map((a) => a.$1).firstWhere((m) => m.from!.email == from);

Correction move(String from, String folder, {CorrectionKind kind = CorrectionKind.manualFile, String? listId, String subject = 'Hello #1', String? predicted}) {
  final h = Corpus.msg(folder: Corpus.inbox, from: from, subject: subject, listId: listId, daysAgo: 0);
  return Correction(
    id: h.messageIdHash,
    key: h.key,
    kind: kind,
    weight: 1.0,
    actualFolder: folder,
    predictedFolder: predicted,
    at: Corpus.today,
    fromAddress: from,
    fromDomain: h.from!.domain,
    listId: listId,
    subjectNorm: subject,
  );
}

Map<String, dynamic> suggestionsJson(List<Map<String, dynamic>> items) => {'suggestions': items};

void main() {
  late Harness h;
  tearDown(() => h.close());

  group('advisor / off mode in classify()', () {
    test('advisor mode never calls the provider; unplaced mail becomes unsorted evidence, de-duplicated', () async {
      h = await Harness.create(ai: advisorAi);
      final stranger = arrival('stranger@random.example');
      final out = await h.sorter.classify(Corpus.account, [inp(arrival('billing@acme.com')), inp(stranger)], h.settings.config);
      expect(h.fake.callCount, 0);
      expect(out[0].layer, SortLayer.learned, reason: 'learned stats still sort');
      expect(out[0].destination, Corpus.invoices);
      expect(out[1].mode, SortMode.keep);
      expect(out[1].reason, '[no rule]');

      await h.sorter.classify(Corpus.account, [inp(stranger)], h.settings.config);
      final rows = await h.sorter.evidence.unconsumed(Corpus.account);
      expect(rows.length, 1, reason: 'learned decisions are not evidence; repeats de-duplicate');
      expect(rows.single.kind, 'unsorted');
      expect(rows.single.fromAddr, 'stranger@random.example');
      expect(rows.single.seenCount, 2);
      expect(rows.single.folder, isNull);
      expect(h.fake.callCount, 0);
    });

    test('off mode: no model calls from classify or bootstrap', () async {
      h = await Harness.create(ai: advisorAi.copyWith(usage: AiUsageMode.off));
      final out = await h.sorter.classify(Corpus.account, [inp(arrival('stranger@random.example'))], h.settings.config);
      expect(out.single.reason, '[no rule]');
      await h.sorter.bootstrap(Corpus.account, h.settings.config);
      expect(h.fake.callCount, 0);
    });

    test('perMessage mode still asks the model', () async {
      h = await Harness.create();
      await h.sorter.classify(Corpus.account, [inp(arrival('stranger@random.example'))], h.settings.config);
      expect(h.fake.callCount, 1);
      expect(await h.sorter.evidence.unconsumed(Corpus.account), isEmpty);
    });

    test('dry runs record nothing', () async {
      h = await Harness.create(ai: advisorAi);
      await h.sorter.classify(Corpus.account, [inp(arrival('stranger@random.example'))], h.settings.config, dryRun: true);
      expect(await h.sorter.evidence.unconsumed(Corpus.account), isEmpty);
    });
  });

  group('evidence from corrections', () {
    test('manual moves and undos are recorded with counts and examples; disposal and dismiss are not', () async {
      h = await Harness.create(ai: advisorAi);
      await h.sorter.recordCorrection(move('orders@newshop.example', Corpus.receipts, subject: 'Order 1234 shipped'));
      await h.sorter.recordCorrection(move('orders@newshop.example', Corpus.receipts, subject: 'Order 1235 shipped'));
      await h.sorter.recordCorrection(move('orders@newshop.example', Corpus.receipts, subject: 'Your receipt'));
      await h.sorter.recordCorrection(move('news@example.com', Corpus.inbox, kind: CorrectionKind.undo, predicted: Corpus.newsletters, listId: 'news.example.com'));
      await h.sorter.recordCorrection(move('spam@bad.example', Corpus.trash));
      await h.sorter.recordCorrection(move('x@bad.example', Corpus.inbox, kind: CorrectionKind.badgeDismiss, predicted: Corpus.family));
      final rows = await h.sorter.evidence.unconsumed(Corpus.account);
      expect(rows.map((r) => r.kind).toSet(), {'manualMove', 'undo'});
      final moves = rows.singleWhere((r) => r.kind == 'manualMove');
      expect(moves.fromAddr, 'orders@newshop.example');
      expect(moves.folder, Corpus.receipts);
      expect(moves.seenCount, 3);
      expect(SortEvidenceStore.examplesOf(moves), ['Order # shipped', 'Your receipt']);
      final undo = rows.singleWhere((r) => r.kind == 'undo');
      expect(undo.listId, 'news.example.com');
      expect(undo.folder, 'INBOX');
    });

    test('table is bounded per account, consumed rows evicted first, then the oldest', () async {
      h = await Harness.create(ai: advisorAi);
      final store = SortEvidenceStore(h.database, h.clock, stats: h.sorter.stats, maxRows: 10);
      for (var i = 0; i < 10; i++) {
        h.clock.advance(const Duration(minutes: 1));
        await store.recordUnsorted(Corpus.account, Corpus.msg(folder: Corpus.inbox, from: 'u$i@many.example', subject: 's$i', daysAgo: 0));
      }
      final all = await store.unconsumed(Corpus.account);
      final consumed = all.where((r) => r.fromAddr == 'u7@many.example' || r.fromAddr == 'u8@many.example').map((r) => r.id);
      await store.consume(consumed, h.clock.now());
      for (var i = 10; i < 13; i++) {
        h.clock.advance(const Duration(minutes: 1));
        await store.recordUnsorted(Corpus.account, Corpus.msg(folder: Corpus.inbox, from: 'u$i@many.example', subject: 's$i', daysAgo: 0));
      }
      final left = await (h.database.select(h.database.sortEvidence)).get();
      expect(left.length, 10);
      final senders = left.map((r) => r.fromAddr).toSet();
      expect(senders, isNot(contains('u7@many.example')), reason: 'consumed rows go first');
      expect(senders, isNot(contains('u8@many.example')));
      expect(senders, isNot(contains('u0@many.example')), reason: 'then the oldest unconsumed');
      expect(senders, contains('u12@many.example'));
    });
  });

  group('pattern pre-pass', () {
    test('two manual moves to one folder -> suggestion; conflicting folders -> none', () async {
      h = await Harness.create(ai: advisorAi);
      h.provider = null;
      await h.sorter.recordCorrection(move('orders@newshop.example', Corpus.receipts, subject: 'Order 1 shipped'));
      await h.sorter.recordCorrection(move('orders@newshop.example', Corpus.receipts, subject: 'Order 2 shipped'));
      await h.sorter.recordCorrection(move('mixed@corp.example', Corpus.receipts));
      await h.sorter.recordCorrection(move('mixed@corp.example', Corpus.invoices));
      final run = await h.sorter.advisor.runNow(Corpus.account);
      expect(run.patternSuggestions, 1);
      expect(run.modelRan, isFalse);
      expect(run.skippedReason, 'no AI provider configured');
      final s = (await h.sorter.advisor.pending(Corpus.account)).single;
      expect(s.match, {'from': 'orders@newshop.example'});
      expect(s.folderPath, Corpus.receipts);
      expect(s.source, SuggestionSource.pattern);
      expect(s.confidence, 0.9);
      expect(s.evidenceCount, 2);
      expect(s.examples, ['Order # shipped']);
      expect(s.matchLabel, 'Mail from orders@newshop.example');
      // Running again does not duplicate.
      final again = await h.sorter.advisor.runNow(Corpus.account);
      expect(again.patternSuggestions, 0);
      expect((await h.sorter.advisor.pending(Corpus.account)).length, 1);
    });

    test('list beats sender; domain only for non free-mail; an undo blocks the group', () async {
      h = await Harness.create(ai: advisorAi);
      h.provider = null;
      await h.sorter.recordCorrection(move('a@deals.example', Corpus.newsletters, listId: 'deals.example'));
      await h.sorter.recordCorrection(move('b@deals.example', Corpus.newsletters, listId: 'deals.example'));
      await h.sorter.recordCorrection(move('aunt@gmail.com', Corpus.family));
      await h.sorter.recordCorrection(move('cousin@gmail.com', Corpus.family));
      await h.sorter.recordCorrection(move('ap@corp.example', Corpus.invoices));
      await h.sorter.recordCorrection(move('billing2@corp.example', Corpus.invoices));
      await h.sorter.recordCorrection(move('flip@flop.example', Corpus.receipts));
      await h.sorter.recordCorrection(move('flip@flop.example', Corpus.receipts));
      await h.sorter.recordCorrection(move('flip@flop.example', Corpus.inbox, kind: CorrectionKind.undo, predicted: Corpus.receipts));
      await h.sorter.advisor.runNow(Corpus.account);
      final pending = await h.sorter.advisor.pending(Corpus.account);
      expect(pending.map((s) => s.match).toList(), unorderedEquals([
        {'listId': 'deals.example'},
        {'fromDomain': 'corp.example'},
      ]));
      expect(pending.map((s) => s.folderPath).toSet(), {Corpus.newsletters, Corpus.invoices});
    });

    test('an existing rule for the same match and folder suppresses the suggestion', () async {
      h = await Harness.create(ai: advisorAi);
      h.provider = null;
      await h.sorter.rules.upsert(const SortRule(id: 'r1', accountId: Corpus.account, priority: 1, match: RuleMatch(from: 'orders@newshop.example'), action: RuleAction.moveTo, folderPath: Corpus.receipts), h.clock.now());
      await h.sorter.recordCorrection(move('orders@newshop.example', Corpus.receipts));
      await h.sorter.recordCorrection(move('orders@newshop.example', Corpus.receipts));
      expect((await h.sorter.advisor.runNow(Corpus.account)).total, 0);
    });
  });

  group('model pass', () {
    Future<void> seedUnsorted(Harness h) async {
      final inputs = [
        inp(arrival('stranger@random.example')),
        inp(arrival('promo@deals.example')),
        inp(arrival('noreply@bank.example')),
        inp(Corpus.msg(folder: Corpus.inbox, from: 'longwinded@random.example', subject: 'one two three four five six seven eight', daysAgo: 0)),
      ];
      await h.sorter.classify(Corpus.account, inputs, h.settings.config);
    }

    test('request shape: cacheable profiles block, folder enum, no bodies, subjects cut under headersOnly; invalid replies dropped; cost recorded', () async {
      h = await Harness.create(ai: advisorAi.copyWith(privacy: PrivacyLevel.headersOnly));
      await seedUnsorted(h);
      await h.sorter.rules.upsert(const SortRule(id: 'r1', accountId: Corpus.account, priority: 1, match: RuleMatch(from: 'x@y.example'), action: RuleAction.moveTo, folderPath: Corpus.invoices), h.clock.now());
      expect(h.fake.callCount, 0);
      h.fake.script = (req) => suggestionsJson([
            {'kind': 'list', 'value': 'deals.example', 'folder': Corpus.newsletters, 'rationale': 'bulk promo list matches Newsletters', 'confidence': 0.8, 'exampleIds': ['e2']},
            {'kind': 'from', 'value': 'noreply@bank.example', 'folder': 'Nope/Missing', 'rationale': 'x', 'confidence': 0.9, 'exampleIds': <String>[]},
            {'kind': 'from', 'value': 'stranger@random.example', 'folder': Corpus.family, 'rationale': 'x', 'confidence': 0.3, 'exampleIds': <String>[]},
            {'kind': 'from', 'value': 'x@y.example', 'folder': Corpus.invoices, 'rationale': 'dup of rule', 'confidence': 0.95, 'exampleIds': <String>[]},
            {'kind': 'domain', 'value': 'gmail.com', 'folder': Corpus.family, 'rationale': 'free mail', 'confidence': 0.95, 'exampleIds': <String>[]},
            {'kind': 'list', 'value': 'deals.example', 'folder': Corpus.newsletters, 'rationale': 'duplicate in batch', 'confidence': 0.7, 'exampleIds': <String>[]},
          ]);
      final run = await h.sorter.advisor.runNow(Corpus.account);
      expect(run.modelRan, isTrue);
      expect(run.modelSuggestions, 1);
      expect(h.fake.callCount, 1);
      final req = h.fake.lastRequest;
      expect(req.system.single.cacheable, isTrue);
      expect(req.system.single.text, startsWith(RuleAdvisor.instructions));
      expect(req.system.single.text, contains('### ${Corpus.invoices}'));
      final folderEnum = (((req.jsonSchema['properties'] as Map)['suggestions'] as Map)['items'] as Map)['properties'] as Map;
      expect(((folderEnum['folder'] as Map)['enum'] as List), containsAll([Corpus.invoices, Corpus.newsletters, Corpus.family, Corpus.receipts]));
      expect(((folderEnum['folder'] as Map)['enum'] as List), isNot(contains('INBOX')));
      expect(req.user, isNot(contains('Body:')));
      expect(req.user, contains('e1 |'));
      expect(req.user, contains('"one two three four five six…"'));
      expect(req.user, isNot(contains('seven')));
      expect(req.user, contains('from x@y.example -> ${Corpus.invoices}'));
      final pending = await h.sorter.advisor.pending(Corpus.account);
      expect(pending.single.match, {'listId': 'deals.example'});
      expect(pending.single.folderPath, Corpus.newsletters);
      expect(pending.single.source, SuggestionSource.model);
      expect(pending.single.confidence, 0.8);
      expect(pending.single.evidenceCount, greaterThanOrEqualTo(1));
      final usage = await h.database.select(h.database.aiUsage).get();
      expect(usage.where((u) => u.kind == 'advisor').length, 1);
    });

    test('dismissed suggestions are not re-proposed; interval and evidence threshold gate maybeRun', () async {
      h = await Harness.create(ai: advisorAi);
      await seedUnsorted(h);
      h.fake.script = (req) => suggestionsJson([
            {'kind': 'list', 'value': 'deals.example', 'folder': Corpus.newsletters, 'rationale': 'x', 'confidence': 0.8, 'exampleIds': ['e2']},
          ]);
      expect((await h.sorter.advisor.runNow(Corpus.account)).modelSuggestions, 1);
      final s = (await h.sorter.advisor.pending(Corpus.account)).single;
      await h.sorter.advisor.dismiss(s.id);
      expect(await h.sorter.advisor.pending(Corpus.account), isEmpty);
      final again = await h.sorter.advisor.runNow(Corpus.account);
      expect(again.modelRan, isTrue);
      expect(again.modelSuggestions, 0, reason: 'dismissed (match, folder) is remembered');
      // Not forced: fewer than 10 unsent rows -> no model call.
      final calls = h.fake.callCount;
      final gated = await h.sorter.advisor.maybeRun(Corpus.account);
      expect(gated.modelRan, isFalse);
      expect(gated.skippedReason, contains('waiting for more evidence'));
      expect(h.fake.callCount, calls);
    });

    test('maybeRun honours advisorIntervalHours once enough evidence exists', () async {
      h = await Harness.create(ai: advisorAi.copyWith(advisorIntervalHours: 6));
      for (var i = 0; i < 12; i++) {
        await h.sorter.evidence.recordUnsorted(Corpus.account, Corpus.msg(folder: Corpus.inbox, from: 'u$i@many.example', subject: 's$i', daysAgo: 0));
      }
      h.fake.script = (req) => suggestionsJson([]);
      expect((await h.sorter.advisor.maybeRun(Corpus.account)).modelRan, isTrue);
      for (var i = 12; i < 24; i++) {
        await h.sorter.evidence.recordUnsorted(Corpus.account, Corpus.msg(folder: Corpus.inbox, from: 'u$i@many.example', subject: 's$i', daysAgo: 0));
      }
      final soon = await h.sorter.advisor.maybeRun(Corpus.account);
      expect(soon.modelRan, isFalse);
      expect(soon.skippedReason, startsWith('next model check'));
      h.clock.advance(const Duration(hours: 7));
      expect((await h.sorter.advisor.maybeRun(Corpus.account)).modelRan, isTrue);
      expect(h.fake.callCount, 2);
    });

    test('model pass is skipped in perMessage / off mode and when the cap is hit', () async {
      h = await Harness.create(ai: advisorAi.copyWith(usage: AiUsageMode.off));
      expect((await h.sorter.advisor.runNow(Corpus.account)).skippedReason, 'AI usage is off');
      h.settings.aiSettings = advisorAi.copyWith(usage: AiUsageMode.perMessage);
      expect((await h.sorter.advisor.runNow(Corpus.account)).skippedReason, 'advisor runs only in advisor mode');
      h.settings.aiSettings = advisorAi.copyWith(dailyCapUsd: 0.001);
      await h.sorter.costs.record(kind: 'sort', modelId: 'claude-sonnet-5', usage: const TokenUsage(input: 100000, output: 10000));
      expect((await h.sorter.advisor.runNow(Corpus.account)).skippedReason, 'spend cap reached');
      expect(h.fake.callCount, 0);
    });
  });

  group('accept', () {
    test('creates a moveTo rule with the match, consumes the evidence, and the rule sorts from then on', () async {
      h = await Harness.create(ai: advisorAi);
      h.provider = null;
      await h.sorter.recordCorrection(move('orders@newshop.example', Corpus.receipts));
      await h.sorter.recordCorrection(move('orders@newshop.example', Corpus.receipts));
      await h.sorter.advisor.runNow(Corpus.account);
      final s = (await h.sorter.advisor.pending(Corpus.account)).single;
      final ruleId = await h.sorter.advisor.accept(s.id);
      final rule = (await h.sorter.rules.load(Corpus.account)).singleWhere((r) => r.id == ruleId);
      expect(rule.match.from, 'orders@newshop.example');
      expect(rule.action, RuleAction.moveTo);
      expect(rule.folderPath, Corpus.receipts);
      expect(await h.sorter.advisor.pending(Corpus.account), isEmpty);
      expect((await h.sorter.evidence.unconsumed(Corpus.account)).where((r) => r.fromAddr == 'orders@newshop.example'), isEmpty);
      final out = await h.sorter.classify(Corpus.account, [inp(Corpus.msg(folder: Corpus.inbox, from: 'orders@newshop.example', subject: 'Order 9', daysAgo: 0))], h.settings.config);
      expect(out.single.layer, SortLayer.rule);
      expect(out.single.destination, Corpus.receipts);
    });

    test('edits on accept are honoured', () async {
      h = await Harness.create(ai: advisorAi);
      h.provider = null;
      await h.sorter.recordCorrection(move('orders@newshop.example', Corpus.receipts));
      await h.sorter.recordCorrection(move('orders@newshop.example', Corpus.receipts));
      await h.sorter.advisor.runNow(Corpus.account);
      final s = (await h.sorter.advisor.pending(Corpus.account)).single;
      final ruleId = await h.sorter.advisor.accept(s.id, match: {'fromDomain': 'newshop.example'}, folderPath: Corpus.invoices);
      final rule = (await h.sorter.rules.load(Corpus.account)).singleWhere((r) => r.id == ruleId);
      expect(rule.match.fromDomain, 'newshop.example');
      expect(rule.folderPath, Corpus.invoices);
    });
  });
}
