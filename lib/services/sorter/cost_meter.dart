import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../data/ai/ai_provider.dart';
import '../../data/ai/price_table.dart';
import '../../data/local/database.dart' as db;
import '../../domain/entities/entities.dart';

enum CapState { ok, warning, exceeded }

/// Records token usage as `ai_usage` rows priced by [PriceTable] and answers
/// the spend-cap questions. Local endpoints cost $0 but are still counted.
class CostMeter {
  CostMeter(this._db, this._clock, {PriceTable? prices}) : prices = prices ?? PriceTable.bundled;
  final db.SortieDatabase _db;
  final Clock _clock;
  final PriceTable prices;

  static const warnFraction = 0.8;

  Future<double> record({
    required String kind,
    required String modelId,
    required TokenUsage usage,
    String? provider,
    bool batch = false,
    bool local = false,
    String? batchId,
  }) async {
    final usd = prices.cost(usage, modelId, batch: batch, local: local);
    await _db.into(_db.aiUsage).insert(db.AiUsageCompanion.insert(
          ts: _clock.now().millisecondsSinceEpoch,
          provider: Value(provider),
          modelId: Value(modelId),
          kind: kind,
          inputTokens: Value(usage.input),
          cacheReadTokens: Value(usage.cacheRead),
          cacheWriteTokens: Value(usage.cacheWrite),
          outputTokens: Value(usage.output),
          costUsd: usd,
          batchId: Value(batchId),
        ));
    return usd;
  }

  /// (today, this month) in USD, local calendar boundaries.
  Future<(double, double)> spend() async {
    final now = _clock.now();
    final dayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final monthStart = DateTime(now.year, now.month).millisecondsSinceEpoch;
    return (await _sumSince(dayStart), await _sumSince(monthStart));
  }

  Future<double> _sumSince(int ts) async {
    final sum = _db.aiUsage.costUsd.sum();
    final q = _db.selectOnly(_db.aiUsage)
      ..addColumns([sum])
      ..where(_db.aiUsage.ts.isBiggerOrEqualValue(ts));
    final row = await q.getSingle();
    return row.read(sum) ?? 0;
  }

  /// Highest of the daily / monthly fractions used.
  Future<double> fractionUsed(AiSettings s) async {
    final (day, month) = await spend();
    final d = s.dailyCapUsd <= 0 ? 0.0 : day / s.dailyCapUsd;
    final m = s.monthlyCapUsd <= 0 ? 0.0 : month / s.monthlyCapUsd;
    return d > m ? d : m;
  }

  Future<CapState> capState(AiSettings s) async {
    final f = await fractionUsed(s);
    if (f >= 1.0) return CapState.exceeded;
    if (f >= warnFraction) return CapState.warning;
    return CapState.ok;
  }

  Future<TokenUsage> totalsSince(DateTime since) async {
    final rows = await (_db.select(_db.aiUsage)..where((u) => u.ts.isBiggerOrEqualValue(since.millisecondsSinceEpoch))).get();
    var total = const TokenUsage();
    for (final r in rows) {
      total = total + TokenUsage(input: r.inputTokens, cacheRead: r.cacheReadTokens, cacheWrite: r.cacheWriteTokens, output: r.outputTokens);
    }
    return total;
  }
}
