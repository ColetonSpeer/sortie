import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/data/ai/fake_ai_provider.dart';
import 'package:sortie/data/local/database.dart' as db;
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/domain/services/services.dart';
import 'package:sortie/services/sorter/sender_stats.dart';
import 'package:sortie/services/sorter/user_rules.dart';

import '../../fixtures/corpus.dart';
import 'test_support.dart';

void main() {
  late Harness h;
  tearDown(() => h.close());

  var n = 0;
  Correction corr(MessageHeader m, CorrectionKind kind, String actual, {String? predicted, double? weight, DateTime? at}) => Correction(
        id: 'c${n++}',
        key: m.key,
        kind: kind,
        weight: weight ?? (kind == CorrectionKind.badgeDismiss || kind == CorrectionKind.badgeRight ? 0.5 : 1.0),
        actualFolder: actual,
        predictedFolder: predicted,
        at: at ?? h.clock.now(),
      );

  Future<List<db.SenderStat>> statsRows() => h.database.select(h.database.senderStats).get();
  String snapshot(List<db.SenderStat> rows) => (rows.map((r) => '${r.keyKind}|${r.key}|${r.folderPath}|${r.count}|${r.weightedCount}|${r.countAgainst}').toList()..sort()).join('\n');

  test("the sorter's own decisions never touch sender stats", () async {
    h = await Harness.create();
    final before = snapshot(await statsRows());
    h.fake.script = (r) => FakeAiProvider.allTo(r, Corpus.receipts, confidence: 0.99);
    final inputs = [for (final (m, _) in Corpus.arrivals()) ClassificationInput(header: m)];
    final out = await h.sorter.classify(Corpus.account, inputs, h.settings.config);
    expect(out.where((d) => d.mode == SortMode.moveNow), isNotEmpty);
    expect(snapshot(await statsRows()), before);
    expect(await h.database.select(h.database.corrections).get(), isEmpty);
  });

  test('corrections crossing the threshold make the next classify deterministic and supersede few-shot', () async {
    h = await Harness.create();
    h.fake.script = (r) => FakeAiProvider.allTo(r, 'INBOX', confidence: 0);
    final msgs = [for (var i = 0; i < 5; i++) Corpus.msg(folder: 'INBOX', from: 'vendor@newco.example', subject: 'Statement $i', daysAgo: i)];
    h.messages.headers.addAll(msgs);
    for (var i = 0; i < 4; i++) {
      await h.sorter.recordCorrection(corr(msgs[i], CorrectionKind.manualFile, Corpus.receipts, predicted: 'INBOX'));
    }
    var out = await h.sorter.classify(Corpus.account, [ClassificationInput(header: msgs[4])], h.settings.config);
    expect(out.single.layer, SortLayer.model);
    expect(h.fake.lastRequest.user, contains('History: Owner previously filed ~4 messages from this list'.replaceAll('this list', 'this sender')));
    expect(h.fake.lastRequest.user, contains('Relevant past corrections'));
    expect(h.fake.lastRequest.system.length, 2);
    expect(h.fake.lastRequest.system[1].text, contains('owner filed in Receipts'));
    expect(h.fake.lastRequest.system[1].text, isNot(contains('2026')));

    await h.sorter.recordCorrection(corr(msgs[4], CorrectionKind.manualFile, Corpus.receipts, predicted: 'INBOX'));
    final fresh = Corpus.msg(folder: 'INBOX', from: 'vendor@newco.example', subject: 'Statement 9', daysAgo: 0);
    out = await h.sorter.classify(Corpus.account, [ClassificationInput(header: fresh)], h.settings.config);
    expect(out.single.layer, SortLayer.learned);
    expect(out.single.destination, Corpus.receipts);
    expect(out.single.confidence, closeTo(1 - 1 / 6, 0.02));
    final rows = await h.database.select(h.database.corrections).get();
    expect(rows.every((r) => r.superseded), isTrue);
    // the domain key learned too (newco.example is not free-mail), Receipts count went up
    expect((await statsRows()).where((r) => r.keyKind == 'from_domain' && r.key == 'newco.example'), isNotEmpty);
    final profile = (await h.sorter.profiles.byPath(Corpus.account))[Corpus.receipts]!;
    expect(profile.userFiledCount, 7 + 5);
  });

  test('a veto blocks the deterministic path until three later filings outnumber it', () async {
    h = await Harness.create();
    final inv = Corpus.arrivals().first.$1; // billing@acme.com, deterministic
    h.messages.headers.add(inv);
    var out = await h.sorter.classify(Corpus.account, [ClassificationInput(header: inv)], h.settings.config);
    expect(out.single.layer, SortLayer.learned);

    await h.sorter.recordCorrection(corr(inv, CorrectionKind.undo, 'INBOX', predicted: Corpus.invoices));
    out = await h.sorter.classify(Corpus.account, [ClassificationInput(header: inv)], h.settings.config);
    expect(out.single.layer, SortLayer.model, reason: 'veto forces the model layer');
    final row = (await statsRows()).firstWhere((r) => r.key == 'billing@acme.com' && r.folderPath == Corpus.invoices);
    expect(row.countAgainst, 1);
    expect(row.count, 6, reason: 'undo to INBOX adds no positive evidence');

    for (var i = 0; i < 3; i++) {
      h.clock.advance(const Duration(minutes: 1));
      final m = Corpus.msg(folder: 'INBOX', from: 'billing@acme.com', subject: 'Invoice again $i', daysAgo: 0);
      h.messages.headers.add(m);
      await h.sorter.recordCorrection(corr(m, CorrectionKind.manualFile, Corpus.invoices));
      out = await h.sorter.classify(Corpus.account, [ClassificationInput(header: inv)], h.settings.config);
      expect(out.single.layer, i < 2 ? SortLayer.model : SortLayer.learned, reason: 'after ${i + 1} filings');
    }
  });

  test('badgeDismiss only vetoes; badgeRight adds half weight; disposal teaches nothing; rules win', () async {
    h = await Harness.create();
    final m = Corpus.msg(folder: 'INBOX', from: 'shop@store.example', subject: 'Order');
    h.messages.headers.add(m);
    await h.sorter.recordCorrection(corr(m, CorrectionKind.badgeDismiss, 'INBOX', predicted: Corpus.receipts));
    var rows = (await statsRows()).where((r) => r.key == 'shop@store.example').toList();
    expect(rows.single.countAgainst, 1);
    expect(rows.single.count, 0);

    await h.sorter.recordCorrection(corr(m, CorrectionKind.badgeRight, Corpus.receipts, predicted: Corpus.receipts));
    rows = (await statsRows()).where((r) => r.key == 'shop@store.example').toList();
    expect(rows.single.count, 0.5);

    await h.sorter.recordCorrection(corr(m, CorrectionKind.manualFile, Corpus.trash));
    rows = (await statsRows()).where((r) => r.key == 'shop@store.example').toList();
    expect(rows.single.count, 0.5);
    expect((await h.database.select(h.database.corrections).get()).length, 2);

    await h.sorter.rules.upsert(const SortRule(id: 'r1', accountId: Corpus.account, priority: 1, match: RuleMatch(from: 'shop@store.example'), action: RuleAction.moveTo, folderPath: Corpus.family), h.clock.now());
    await h.sorter.recordCorrection(corr(m, CorrectionKind.manualFile, Corpus.receipts));
    rows = (await statsRows()).where((r) => r.key == 'shop@store.example').toList();
    expect(rows.single.count, 0.5, reason: 'rule contradiction: no learning');
    final last = (await h.database.select(h.database.corrections).get()).last;
    expect(last.superseded, isTrue);
  });

  test('decay math: half-life 180 days, applied on read and when adding evidence', () async {
    h = await Harness.create(bootstrap: false);
    expect(SenderStatsService.decayFactor(const Duration(days: 180)), closeTo(0.5, 1e-9));
    expect(SenderStatsService.decayFactor(const Duration(days: 360)), closeTo(0.25, 1e-9));
    expect(SenderStatsService.decayFactor(Duration.zero), 1.0);
    final s = h.sorter.stats;
    final t0 = h.clock.now();
    await s.addEvidence(Corpus.account, StatKeyKind.fromAddr, 'a@b.example', 'F', 4.0, t0);
    var row = (await statsRows()).single;
    expect(s.effectiveWeight(row, t0), 4.0);
    expect(s.effectiveWeight(row, t0.add(const Duration(days: 180))), closeTo(2.0, 1e-9));
    await s.addEvidence(Corpus.account, StatKeyKind.fromAddr, 'a@b.example', 'F', 1.0, t0.add(const Duration(days: 180)));
    row = (await statsRows()).single;
    expect(row.weightedCount, closeTo(3.0, 1e-9));
    expect(row.count, 5.0);
    expect(row.lastUserAt, t0.add(const Duration(days: 180)).millisecondsSinceEpoch);
    // an out-of-order older event is discounted relative to the stored reference
    await s.addEvidence(Corpus.account, StatKeyKind.fromAddr, 'a@b.example', 'F', 1.0, t0);
    row = (await statsRows()).single;
    expect(row.weightedCount, closeTo(3.5, 1e-9));
    // bootstrap seeding decays by message age relative to the newest one
    final msgs = [
      Corpus.msg(folder: 'F', from: 'c@d.example', subject: 'x', date: t0),
      Corpus.msg(folder: 'F', from: 'c@d.example', subject: 'y', date: t0.subtract(const Duration(days: 180))),
    ];
    await s.seedBootstrap(Corpus.account, msgs, {'F'});
    final seeded = (await statsRows()).firstWhere((r) => r.key == 'c@d.example');
    expect(seeded.weightedCount, closeTo(1.5, 1e-9));
    expect(seeded.count, 2);
    expect(seeded.lastUserAt, t0.millisecondsSinceEpoch);
  });

  test('eviction: cap 500, superseded first, then stale, never the newest 2 per folder', () async {
    h = await Harness.create(bootstrap: false);
    final now = h.clock.now();
    Future<void> insert(String id, String folder, {bool superseded = false, int ageDays = 0}) => h.database.into(h.database.corrections).insert(db.CorrectionsCompanion.insert(
          id: id, accountId: Corpus.account, messageIdHash: 'h$id', kind: 'manualFile', weight: 1, actualFolder: folder,
          superseded: Value(superseded), createdAt: now.subtract(Duration(days: ageDays)).millisecondsSinceEpoch));
    for (var i = 0; i < 490; i++) {
      await insert('fresh$i', 'A', ageDays: i % 30);
    }
    for (var i = 0; i < 8; i++) {
      await insert('sup$i', 'A', superseded: true, ageDays: 400 - i);
    }
    for (var i = 0; i < 10; i++) {
      await insert('stale$i', 'B', ageDays: 200 + i);
    }
    await insert('rare0', 'Rare', superseded: true, ageDays: 500);
    await insert('rare1', 'Rare', superseded: true, ageDays: 500);
    final removed = await h.sorter.learning.evict(Corpus.account);
    expect(removed, 10);
    final left = await h.database.select(h.database.corrections).get();
    expect(left.length, 500);
    final ids = left.map((c) => c.id).toSet();
    expect(ids.where((i) => i.startsWith('sup')), isEmpty, reason: 'superseded (non-protected) go first');
    expect(ids, containsAll(['rare0', 'rare1']), reason: 'last 2 per folder survive');
    expect(ids.where((i) => i.startsWith('fresh')).length, 490);
    expect(ids.where((i) => i.startsWith('stale')).length, 8, reason: 'then the oldest stale ones');
    expect(ids, containsAll(['stale0', 'stale1']));
  });

  test('few-shot picks at most 3 per folder, 12 total, preferring vetoes, sorted deterministically', () async {
    h = await Harness.create(bootstrap: false);
    final now = h.clock.now();
    var i = 0;
    Future<void> insert(String folder, String kind, {String? pred}) => h.database.into(h.database.corrections).insert(db.CorrectionsCompanion.insert(
          id: 'c${i++}', accountId: Corpus.account, messageIdHash: 'h$i', kind: kind, weight: 1, actualFolder: folder,
          predictedFolder: Value(pred), fromAddress: Value('s$i@x.example'), subjectNorm: const Value('Subject #'),
          createdAt: now.subtract(Duration(minutes: i)).millisecondsSinceEpoch));
    for (var k = 0; k < 6; k++) {
      await insert('A', 'manualFile');
    }
    for (var k = 0; k < 6; k++) {
      await insert('B', 'manualFile');
    }
    for (var k = 0; k < 6; k++) {
      await insert('C', 'manualFile');
    }
    await insert('D', 'badgeWrong', pred: 'A');
    await insert('D', 'badgeDismiss', pred: 'A');
    await insert('E', 'undo', pred: 'B');
    final text = await h.sorter.learning.fewShotText(Corpus.account);
    final lines = text.split('\n');
    expect(lines.length, 11, reason: '3+3+3 filings, badgeWrong and undo; badgeDismiss never shown');
    for (final f in ['A', 'B', 'C']) {
      expect(lines.where((l) => l.contains('filed in $f')).length, 3);
    }
    expect(lines.where((l) => l.contains('filed in D (sorter had chosen A)')).length, 1);
    expect(lines.where((l) => l.contains('moved back to E')).length, 1);
    expect(text, isNot(contains('badgeDismiss')));
    final folders = lines.map((l) => RegExp(r'(?:filed in|moved back to|confirmed) (\w+)').firstMatch(l)!.group(1)!).toList();
    expect(folders, equals(folders.toList()..sort()), reason: 'grouped by folder for cache stability');
    expect(await h.sorter.learning.fewShotText(Corpus.account), text, reason: 'deterministic');
  });
}
