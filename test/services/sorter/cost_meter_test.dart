import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/core/clock.dart';
import 'package:sortie/data/ai/ai_provider.dart';
import 'package:sortie/data/local/database.dart' as db;
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/services/sorter/cost_meter.dart';

import 'test_support.dart';

void main() {
  late db.SortieDatabase database;
  late FakeClock clock;
  late CostMeter meter;
  setUp(() {
    database = openTestDb();
    clock = FakeClock(DateTime(2026, 9, 16, 12));
    meter = CostMeter(database, clock);
  });
  tearDown(() => database.close());

  test('prices usage and stores a row; local endpoints are free', () async {
    final usd = await meter.record(kind: 'sort', modelId: 'claude-sonnet-5', usage: const TokenUsage(input: 1000, cacheRead: 10000, cacheWrite: 1000, output: 100));
    // 1000*2 + 10000*0.2 + 1000*2.5 + 100*10 = 2000+2000+2500+1000 = 7500 per 1e6
    expect(usd, closeTo(0.0075, 1e-9));
    expect(await meter.record(kind: 'sort', modelId: 'llama3', usage: const TokenUsage(input: 1000000), local: true), 0);
    expect(await meter.record(kind: 'batch', modelId: 'claude-haiku-4-5', usage: const TokenUsage(input: 1000000), batch: true), closeTo(0.5, 1e-9));
    final rows = await database.select(database.aiUsage).get();
    expect(rows.length, 3);
    expect(rows.first.cacheReadTokens, 10000);
  });

  test('spend windows follow local day and month boundaries', () async {
    clock = FakeClock(DateTime(2026, 9, 1, 0, 30));
    meter = CostMeter(database, clock);
    await meter.record(kind: 'sort', modelId: 'claude-sonnet-5', usage: const TokenUsage(input: 500000)); // $1
    clock.advance(const Duration(days: 10));
    await meter.record(kind: 'sort', modelId: 'claude-sonnet-5', usage: const TokenUsage(input: 250000)); // $0.5
    var (day, month) = await meter.spend();
    expect(day, closeTo(0.5, 1e-9));
    expect(month, closeTo(1.5, 1e-9));
    clock.advance(const Duration(days: 25));
    (day, month) = await meter.spend();
    expect(day, 0);
    expect(month, 0);
  });

  test('cap state transitions ok -> warning at 80% -> exceeded at 100%', () async {
    const s = AiSettings(dailyCapUsd: 1.0, monthlyCapUsd: 100);
    expect(await meter.capState(s), CapState.ok);
    await meter.record(kind: 'sort', modelId: 'claude-sonnet-5', usage: const TokenUsage(input: 395000)); // 0.79
    expect(await meter.capState(s), CapState.ok);
    await meter.record(kind: 'sort', modelId: 'claude-sonnet-5', usage: const TokenUsage(input: 5000)); // 0.80
    expect(await meter.capState(s), CapState.warning);
    await meter.record(kind: 'sort', modelId: 'claude-sonnet-5', usage: const TokenUsage(input: 100000)); // 1.00
    expect(await meter.capState(s), CapState.exceeded);
    // monthly cap alone can trigger too
    const tight = AiSettings(dailyCapUsd: 100, monthlyCapUsd: 0.9);
    expect(await meter.capState(tight), CapState.exceeded);
    const off = AiSettings(dailyCapUsd: 0, monthlyCapUsd: 0);
    expect(await meter.capState(off), CapState.ok, reason: 'zero cap = unlimited');
  });
}
