import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/data/ai/ai_provider.dart';
import 'package:sortie/data/ai/fake_ai_provider.dart';
import 'package:sortie/data/local/database.dart' as db;
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/domain/services/services.dart';
import 'package:sortie/services/sorter/decision_gates.dart';
import 'package:sortie/services/sorter/user_rules.dart';

import '../../fixtures/corpus.dart';
import 'test_support.dart';

ClassificationInput inp(MessageHeader h, {String? body}) => ClassificationInput(header: h, bodyText: body);

MessageHeader arrival(String from) => Corpus.arrivals().map((a) => a.$1).firstWhere((m) => m.from!.email == from);

void main() {
  late Harness h;
  tearDown(() => h.close());

  group('golden corpus', () {
    test('returns exactly one decision per input, in order, keep when nothing applies', () async {
      h = await Harness.create();
      final inputs = [for (final (m, _) in Corpus.arrivals()) inp(m)];
      final out = await h.sorter.classify(Corpus.account, inputs, h.settings.config);
      expect(out.length, inputs.length);
      for (var i = 0; i < inputs.length; i++) {
        expect(out[i].key, inputs[i].header.key);
      }
      final stranger = out[inputs.indexWhere((i) => i.header.from!.email == 'stranger@random.example')];
      expect(stranger.mode, SortMode.keep);
      expect(stranger.destination, 'INBOX');
    });

    test('learned layer decides a well-known sender without asking the model', () async {
      h = await Harness.create();
      final out = await h.sorter.classify(Corpus.account, [inp(arrival('billing@acme.com')), inp(arrival('stranger@random.example'))], h.settings.config);
      expect(out[0].layer, SortLayer.learned);
      expect(out[0].destination, Corpus.invoices);
      expect(out[0].mode, SortMode.moveNow);
      expect(out[0].matchedKey, 'from_addr:billing@acme.com');
      expect(h.fake.callCount, 1);
      expect(h.fake.lastRequest.user, isNot(contains('billing@acme.com')));
      expect(FakeAiProvider.messageIds(h.fake.lastRequest), ['m1']);
    });

    test('rules beat learned stats and the model', () async {
      h = await Harness.create();
      final now = h.clock.now();
      await h.sorter.rules.upsert(const SortRule(id: 'r1', accountId: Corpus.account, priority: 1, match: RuleMatch(from: 'billing@acme.com'), action: RuleAction.moveTo, folderPath: Corpus.receipts), now);
      await h.sorter.rules.upsert(const SortRule(id: 'r2', accountId: Corpus.account, priority: 2, match: RuleMatch(fromDomain: 'random.example'), action: RuleAction.keepInInbox), now);
      h.fake.script = (r) => FakeAiProvider.allTo(r, Corpus.newsletters);
      final out = await h.sorter.classify(Corpus.account, [inp(arrival('billing@acme.com')), inp(arrival('stranger@random.example'))], h.settings.config);
      expect(out[0].layer, SortLayer.rule);
      expect(out[0].destination, Corpus.receipts);
      expect(out[0].confidence, 1.0);
      expect(out[1].layer, SortLayer.rule);
      expect(out[1].mode, SortMode.keep);
      expect(h.fake.callCount, 0);
      final rows = await h.sorter.rules.load(Corpus.account);
      expect(rows.map((r) => r.hits).toList(), [1, 1]);
    });

    test('threshold gates: keep below 0.55, suggest below 0.80, move at or above', () async {
      h = await Harness.create();
      final m = arrival('stranger@random.example');
      for (final (conf, mode) in [(0.3, SortMode.keep), (0.549, SortMode.keep), (0.55, SortMode.suggestOnly), (0.79, SortMode.suggestOnly), (0.8, SortMode.moveNow), (0.99, SortMode.moveNow)]) {
        h.fake.script = (r) => FakeAiProvider.allTo(r, Corpus.receipts, confidence: conf);
        final out = await h.sorter.classify(Corpus.account, [inp(m)], h.settings.config);
        expect(out.single.mode, mode, reason: 'conf $conf');
        expect(out.single.layer, SortLayer.model);
        expect(out.single.destination, Corpus.receipts, reason: 'keep decisions still log the model guess');
        expect(out.single.isKeep, mode == SortMode.keep);
      }
    });

    test('never-sort and unknown folders resolve to INBOX', () async {
      h = await Harness.create();
      final m = arrival('stranger@random.example');
      for (final bad in ['Trash', 'Sent', 'Junk', 'Sortie', 'INBOX/Nope', 'Work/Invoices/Sub']) {
        h.fake.script = (r) => FakeAiProvider.allTo(r, bad);
        final out = await h.sorter.classify(Corpus.account, [inp(m)], h.settings.config);
        expect(out.single.destination, 'INBOX', reason: bad);
        expect(out.single.mode, SortMode.keep);
        expect(out.single.reason, '[unknown folder]');
      }
      h.fake.script = (r) => FakeAiProvider.allTo(r, 'invoices'); // unique leaf, wrong case
      final out = await h.sorter.classify(Corpus.account, [inp(m)], h.settings.config);
      expect(out.single.destination, Corpus.invoices);
    });

    test('user-excluded folder is not a destination', () async {
      h = await Harness.create(config: const SortConfig(mode: SortingMode.auto, leaveUntilRead: LeaveUntilRead.none, neverSortFolders: {Corpus.receipts}));
      h.fake.script = (r) => FakeAiProvider.allTo(r, Corpus.receipts);
      final out = await h.sorter.classify(Corpus.account, [inp(arrival('stranger@random.example'))], h.settings.config);
      expect(out.single.destination, 'INBOX');
      expect(h.fake.lastRequest.system.first.text, isNot(contains('### ${Corpus.receipts}')));
      expect((h.fake.lastRequest.jsonSchema['properties'] as Map)['results']['items']['properties']['folder']['enum'], isNot(contains(Corpus.receipts)));
    });

    test('new-folder guard: model decisions into a folder with < 5 filings are suggestions', () async {
      h = await Harness.create();
      h.fake.script = (r) => FakeAiProvider.allTo(r, Corpus.apollo, confidence: 0.97);
      final out = await h.sorter.classify(Corpus.account, [inp(arrival('stranger@random.example'))], h.settings.config);
      expect(out.single.destination, Corpus.apollo);
      expect(out.single.mode, SortMode.suggestOnly);
    });

    test('probation: model -> suggestOnly, learned and rule layers unaffected', () async {
      h = await Harness.create(config: SortConfig(mode: SortingMode.auto, leaveUntilRead: LeaveUntilRead.none, enabledAt: Corpus.today.subtract(const Duration(days: 1))));
      await h.sorter.rules.upsert(const SortRule(id: 'r1', accountId: Corpus.account, priority: 1, match: RuleMatch(from: 'stranger@random.example'), action: RuleAction.moveTo, folderPath: Corpus.family), h.clock.now());
      h.fake.script = (r) => FakeAiProvider.allTo(r, Corpus.receipts, confidence: 0.97);
      final out = await h.sorter.classify(Corpus.account, [inp(arrival('billing@acme.com')), inp(arrival('stranger@random.example')), inp(arrival('friend@outlook.com'))], h.settings.config);
      expect(out[0].mode, SortMode.moveNow); // learned
      expect(out[1].mode, SortMode.moveNow); // rule
      expect(out[2].mode, SortMode.suggestOnly); // model
    });

    test('strong learned hint disagreeing with a < 0.9 model answer -> suggestOnly', () async {
      h = await Harness.create();
      final mom = arrival('mom@gmail.com'); // 4 filings in Family: hint, not deterministic
      h.fake.script = (r) => FakeAiProvider.allTo(r, Corpus.receipts, confidence: 0.85);
      var out = await h.sorter.classify(Corpus.account, [inp(mom)], h.settings.config);
      expect(out.single.mode, SortMode.suggestOnly);
      expect(h.fake.lastRequest.user, contains('History: Owner previously filed'));
      h.fake.script = (r) => FakeAiProvider.allTo(r, Corpus.receipts, confidence: 0.95);
      out = await h.sorter.classify(Corpus.account, [inp(mom)], h.settings.config);
      expect(out.single.mode, SortMode.moveNow);
      h.fake.script = (r) => FakeAiProvider.allTo(r, Corpus.family, confidence: 0.85);
      out = await h.sorter.classify(Corpus.account, [inp(mom)], h.settings.config);
      expect(out.single.mode, SortMode.moveNow);
    });

    test('free-mail domains never become a learned key', () async {
      h = await Harness.create();
      final other = Corpus.msg(folder: 'INBOX', from: 'someone-else@gmail.com', subject: 'hey', daysAgo: 0);
      final v = await h.sorter.stats.lookup(Corpus.account, other, allowedFolders: {Corpus.family});
      expect(v, isNull);
    });

    test('backlog run: K=20 and everything is suggestOnly', () async {
      h = await Harness.create();
      final many = [for (var i = 0; i < 45; i++) inp(Corpus.msg(folder: 'INBOX', from: 'bulk$i@many.example', subject: 'msg $i', daysAgo: 0))];
      h.fake.script = (r) => FakeAiProvider.allTo(r, Corpus.receipts, confidence: 0.97);
      final out = await h.sorter.classify(Corpus.account, many, h.settings.config);
      expect(out.every((d) => d.mode == SortMode.suggestOnly), isTrue);
      expect(h.fake.requests.map((r) => FakeAiProvider.messageIds(r).length).toList(), [20, 20, 5]);
    });

    test('normal run batches K=10', () async {
      h = await Harness.create();
      final many = [for (var i = 0; i < 23; i++) inp(Corpus.msg(folder: 'INBOX', from: 'x$i@many.example', subject: 'msg $i', daysAgo: 0))];
      await h.sorter.classify(Corpus.account, many, h.settings.config);
      expect(h.fake.requests.map((r) => FakeAiProvider.messageIds(r).length).toList(), [10, 10, 3]);
    });

    test('system blocks are byte-identical across two different batches', () async {
      h = await Harness.create();
      await h.sorter.classify(Corpus.account, [inp(arrival('stranger@random.example')), inp(arrival('promo@deals.example'))], h.settings.config);
      h.clock.advance(const Duration(hours: 5));
      await h.sorter.classify(Corpus.account, [inp(arrival('friend@outlook.com'))], h.settings.config);
      final a = h.fake.requests[0].system, b = h.fake.requests[1].system;
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].text, b[i].text);
        expect(a[i].cacheable, isTrue);
      }
      expect(a.first.text, startsWith('You are the mail sorter for one person'));
      expect(a.first.text, contains('## Folders\n### Family'));
      expect(a.first.text, isNot(contains('2026-09')));
      expect(h.fake.requests[0].user, startsWith('Today is 2026-09-16. Sort these 2 messages.'));
      expect(h.fake.requests[0].user, contains('<message id="m1">'));
      expect(h.fake.requests[0].user, isNot(contains('Message-ID')));
      expect(h.fake.requests[0].maxOutputTokens, 200 + 80 * 2);
    });
  });

  group('eligibility and model availability', () {
    test('no provider: deterministic layers still run, model candidates keep', () async {
      h = await Harness.create(withProvider: false);
      final out = await h.sorter.classify(Corpus.account, [inp(arrival('billing@acme.com')), inp(arrival('stranger@random.example'))], h.settings.config);
      expect(out[0].layer, SortLayer.learned);
      expect(out[0].mode, SortMode.moveNow);
      expect(out[1].mode, SortMode.keep);
      expect(out[1].reason, '[no AI provider configured]');
    });

    test('paused AI skips the model layer only', () async {
      h = await Harness.create(ai: const AiSettings(usage: AiUsageMode.perMessage, kind: AiProviderKind.openAiCompat, baseUrl: 'http://10.0.0.5/v1', model: 'm', paused: true));
      final out = await h.sorter.classify(Corpus.account, [inp(arrival('billing@acme.com')), inp(arrival('stranger@random.example'))], h.settings.config);
      expect(out[0].layer, SortLayer.learned);
      expect(out[1].reason, '[AI sorting paused]');
      expect(h.fake.callCount, 0);
    });

    test('spend cap at 100% pauses the model layer and announces it', () async {
      h = await Harness.create(ai: const AiSettings(usage: AiUsageMode.perMessage, kind: AiProviderKind.anthropic, model: 'claude-sonnet-5', dailyCapUsd: 0.01));
      final msgs = <String>[];
      final sub = h.sorter.statusMessages.listen(msgs.add);
      await h.sorter.costs.record(kind: 'sort', modelId: 'claude-sonnet-5', usage: const TokenUsage(input: 10000000));
      final out = await h.sorter.classify(Corpus.account, [inp(arrival('billing@acme.com')), inp(arrival('stranger@random.example'))], h.settings.config);
      await Future<void>.delayed(Duration.zero);
      expect(out[0].layer, SortLayer.learned);
      expect(out[1].reason, '[spend cap reached]');
      expect(h.fake.callCount, 0);
      expect(msgs.single, contains('spend cap reached'));
      await sub.cancel();
    });

    test('sorting mode off keeps everything; suggestOnly mode caps moves', () async {
      h = await Harness.create(config: const SortConfig(mode: SortingMode.off));
      var out = await h.sorter.classify(Corpus.account, [inp(arrival('billing@acme.com'))], h.settings.config);
      expect(out.single.mode, SortMode.keep);
      await h.close();
      h = await Harness.create(config: const SortConfig(mode: SortingMode.suggestOnly, leaveUntilRead: LeaveUntilRead.none));
      out = await h.sorter.classify(Corpus.account, [inp(arrival('billing@acme.com'))], h.settings.config);
      expect(out.single.mode, SortMode.suggestOnly);
      expect(out.single.destination, Corpus.invoices);
    });

    test('messages outside INBOX, already sorted, or already decided are kept', () async {
      h = await Harness.create();
      final done = Corpus.msg(folder: 'INBOX', from: 'billing@acme.com', subject: 'Invoice', flags: {SortieKeywords.done}, daysAgo: 0);
      final elsewhere = Corpus.msg(folder: Corpus.family, from: 'billing@acme.com', subject: 'Invoice', daysAgo: 0);
      final decided = arrival('billing@acme.com');
      await h.database.into(h.database.sortDecisions).insert(db.SortDecisionsCompanion.insert(
            id: 'd1', accountId: Corpus.account, messageIdHash: decided.messageIdHash, sourceFolder: 'INBOX', destination: Corpus.invoices,
            layer: 'model', confidence: 0.9, mode: 'moveAfterRead', status: 'pending', createdAt: 0));
      final out = await h.sorter.classify(Corpus.account, [inp(done), inp(elsewhere), inp(decided)], h.settings.config);
      expect(out.map((d) => d.reason).toList(), ['[already sorted once]', '[not in INBOX]', '[already decided]']);
      expect(out.every((d) => d.mode == SortMode.keep), isTrue);
      // dryRun ignores the journal check
      final replay = await h.sorter.classify(Corpus.account, [inp(decided)], h.settings.config, dryRun: true);
      expect(replay.single.layer, SortLayer.learned);
    });
  });

  group('model output handling', () {
    test('malformed reply is retried once with the hint, then kept; 3 in a row -> cool-down', () async {
      h = await Harness.create();
      final m = arrival('stranger@random.example');
      h.fake.queue.addAll(['not json', 'still not json']);
      var out = await h.sorter.classify(Corpus.account, [inp(m)], h.settings.config);
      expect(h.fake.callCount, 2);
      expect(h.fake.requests[0].stricterRetryHint, isNull);
      expect(h.fake.requests[1].stricterRetryHint, contains('was not valid JSON'));
      expect(out.single.reason, '[model reply was not valid JSON]');
      h.fake.queue.addAll(['x', 'x', 'x', 'x']);
      await h.sorter.classify(Corpus.account, [inp(m)], h.settings.config);
      await h.sorter.classify(Corpus.account, [inp(m)], h.settings.config);
      expect(h.sorter.inCooldown, isTrue);
      out = await h.sorter.classify(Corpus.account, [inp(m)], h.settings.config);
      expect(out.single.reason, '[model cooling down after invalid replies]');
      expect(h.fake.callCount, 6);
      h.clock.advance(const Duration(hours: 2));
      expect(h.sorter.inCooldown, isFalse);
    });

    test('missing ids keep and are re-queued once; unknown ids are dropped', () async {
      h = await Harness.create();
      final a = arrival('stranger@random.example'), b = arrival('friend@outlook.com');
      h.fake.script = (r) => {
            'results': [
              {'id': 'm1', 'folder': Corpus.receipts, 'confidence': 0.9, 'reason': 'ok'},
              {'id': 'zzz', 'folder': Corpus.family, 'confidence': 0.9, 'reason': 'bogus'},
            ]
          };
      final out = await h.sorter.classify(Corpus.account, [inp(a), inp(b)], h.settings.config);
      expect(out[0].destination, Corpus.receipts);
      expect(out[1].reason, '[no answer for this message]');
      final q = await h.database.select(h.database.sortQueue).get();
      expect(q.single.messageIdHash, b.messageIdHash);
      await h.sorter.classify(Corpus.account, [inp(a), inp(b)], h.settings.config);
      expect((await h.database.select(h.database.sortQueue).get()).length, 1);
    });

    test('stop_reason max_tokens halves the batch and retries', () async {
      h = await Harness.create();
      var calls = 0;
      h.fake.script = (r) {
        calls++;
        h.fake.finishReason = calls == 1 ? 'max_tokens' : 'end_turn';
        return FakeAiProvider.allTo(r, Corpus.receipts);
      };
      final many = [for (var i = 0; i < 10; i++) inp(Corpus.msg(folder: 'INBOX', from: 'x$i@many.example', subject: 'msg $i', daysAgo: 0))];
      final out = await h.sorter.classify(Corpus.account, many, h.settings.config);
      expect(h.fake.requests.map((r) => FakeAiProvider.messageIds(r).length).toList(), [10, 5, 5]);
      expect(out.every((d) => d.destination == Corpus.receipts), isTrue);
    });

    test('provider failure keeps the batch and announces it', () async {
      h = await Harness.create();
      h.fake.script = (_) => const AiProviderException('boom', statusCode: 500);
      final msgs = <String>[];
      final sub = h.sorter.statusMessages.listen(msgs.add);
      final out = await h.sorter.classify(Corpus.account, [inp(arrival('stranger@random.example'))], h.settings.config);
      await Future<void>.delayed(Duration.zero);
      expect(out.single.reason, '[model unavailable]');
      expect(msgs.single, contains('AI request failed'));
      await sub.cancel();
    });

    test('usage is metered per call', () async {
      h = await Harness.create(ai: const AiSettings(usage: AiUsageMode.perMessage, kind: AiProviderKind.anthropic, model: 'claude-sonnet-5'));
      h.fake.usage = const TokenUsage(input: 1000, output: 100);
      await h.sorter.classify(Corpus.account, [inp(arrival('stranger@random.example'))], h.settings.config);
      final (day, month) = await h.sorter.spend();
      expect(day, closeTo(0.0, 1e-9)); // fake provider isLocal -> $0
      expect(month, closeTo(0.0, 1e-9));
      final rows = await h.database.select(h.database.aiUsage).get();
      expect(rows.single.inputTokens, 1000);
      expect(rows.single.kind, 'sort');
    });
  });

  group('read-policy mode table', () {
    final personal = Corpus.msg(folder: 'INBOX', from: 'p@corp.example', subject: 'hi');
    final bulk = Corpus.msg(folder: 'INBOX', from: 'l@corp.example', subject: 'news', listId: 'l.corp.example');
    final bulkPrecedence = Corpus.msg(folder: 'INBOX', from: 'l@corp.example', subject: 'news', precedence: 'bulk');
    final bulkUnsub = Corpus.msg(folder: 'INBOX', from: 'l@corp.example', subject: 'news', listUnsubscribe: true);
    final bulkAuto = Corpus.msg(folder: 'INBOX', from: 'l@corp.example', subject: 'news', autoSubmitted: 'auto-generated');

    final rows = <(LeaveUntilRead, MessageHeader, SortMode)>[
      (LeaveUntilRead.none, personal, SortMode.moveNow),
      (LeaveUntilRead.none, bulk, SortMode.moveNow),
      (LeaveUntilRead.personalOnly, personal, SortMode.moveAfterRead),
      (LeaveUntilRead.personalOnly, bulk, SortMode.moveNow),
      (LeaveUntilRead.personalOnly, bulkPrecedence, SortMode.moveNow),
      (LeaveUntilRead.personalOnly, bulkUnsub, SortMode.moveNow),
      (LeaveUntilRead.personalOnly, bulkAuto, SortMode.moveNow),
      (LeaveUntilRead.all, personal, SortMode.moveAfterRead),
      (LeaveUntilRead.all, bulk, SortMode.moveAfterRead),
    ];

    for (final layer in SortLayer.values) {
      for (final (policy, msg, expected) in rows) {
        test('${layer.name} / ${policy.name} / ${msg.isBulk ? 'bulk' : 'personal'} -> ${expected.name}', () async {
          h = await Harness.create(bootstrap: false);
          final cfg = SortConfig(mode: SortingMode.auto, leaveUntilRead: policy);
          final mode = DecisionGates.resolve(GateInput(layer: layer, confidence: 0.95, destination: Corpus.receipts, header: msg, config: cfg, userFiledCount: 20));
          expect(mode, expected);
        });
      }
    }

    test('pipeline honours the policy for rule, learned and model layers', () async {
      h = await Harness.create(config: const SortConfig(mode: SortingMode.auto, leaveUntilRead: LeaveUntilRead.personalOnly));
      await h.sorter.rules.upsert(const SortRule(id: 'r1', accountId: Corpus.account, priority: 1, match: RuleMatch(from: 'stranger@random.example'), action: RuleAction.moveTo, folderPath: Corpus.family), h.clock.now());
      h.fake.script = (r) => FakeAiProvider.allTo(r, Corpus.receipts, confidence: 0.95);
      final out = await h.sorter.classify(Corpus.account, [
        inp(arrival('billing@acme.com')), // learned, personal
        inp(arrival('stranger@random.example')), // rule, personal
        inp(arrival('promo@deals.example')), // model, bulk
        inp(arrival('friend@outlook.com')), // model, personal
      ], h.settings.config);
      expect(out.map((d) => d.mode).toList(), [SortMode.moveAfterRead, SortMode.moveAfterRead, SortMode.moveNow, SortMode.moveAfterRead]);
    });
  });
}
