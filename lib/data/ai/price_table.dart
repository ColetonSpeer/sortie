import 'ai_provider.dart';

/// USD per million tokens for one model family.
class ModelPrice {
  const ModelPrice({
    required this.inputPerMTok,
    required this.outputPerMTok,
    this.cacheReadMultiplier = 0.1,
    this.cacheWriteMultiplier = 1.25,
    this.batchMultiplier = 0.5,
  });
  final double inputPerMTok;
  final double outputPerMTok;
  final double cacheReadMultiplier;
  final double cacheWriteMultiplier;
  final double batchMultiplier;
}

/// Bundled, user-editable price table. Matching is by longest model-id
/// prefix so dated snapshots (`claude-haiku-4-5-2026...`) resolve too.
class PriceTable {
  const PriceTable({required this.prices, required this.verifiedOn, this.fallback});

  /// Prices verified against the claude-api skill on this date.
  static final bundled = PriceTable(
    verifiedOn: DateTime.utc(2026, 9, 16),
    prices: const {
      'claude-haiku-4-5': ModelPrice(inputPerMTok: 1, outputPerMTok: 5),
      'claude-sonnet-5': ModelPrice(inputPerMTok: 2, outputPerMTok: 10),
      'claude-opus-5': ModelPrice(inputPerMTok: 5, outputPerMTok: 25),
    },
    fallback: const ModelPrice(inputPerMTok: 2, outputPerMTok: 10),
  );

  final Map<String, ModelPrice> prices;
  final DateTime verifiedOn;

  /// Used for unknown cloud models so spend is over- rather than under-counted.
  final ModelPrice? fallback;

  ModelPrice? priceFor(String modelId) {
    final id = modelId.toLowerCase();
    String? best;
    for (final k in prices.keys) {
      if (id.startsWith(k.toLowerCase()) && (best == null || k.length > best.length)) best = k;
    }
    return best == null ? fallback : prices[best];
  }

  bool isKnown(String modelId) => prices.keys.any((k) => modelId.toLowerCase().startsWith(k.toLowerCase()));

  /// Cost in USD. Local endpoints are always free.
  double cost(TokenUsage u, String modelId, {bool batch = false, bool local = false}) {
    if (local) return 0;
    final p = priceFor(modelId);
    if (p == null) return 0;
    final input = u.input * p.inputPerMTok +
        u.cacheRead * p.inputPerMTok * p.cacheReadMultiplier +
        u.cacheWrite * p.inputPerMTok * p.cacheWriteMultiplier;
    final output = u.output * p.outputPerMTok;
    final usd = (input + output) / 1e6;
    return batch ? usd * p.batchMultiplier : usd;
  }

  PriceTable copyWith({Map<String, ModelPrice>? prices, DateTime? verifiedOn}) =>
      PriceTable(prices: prices ?? this.prices, verifiedOn: verifiedOn ?? this.verifiedOn, fallback: fallback);
}
