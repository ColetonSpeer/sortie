/// Result of Settings > AI > "Test connection".
class ConnectionTestSummary {
  const ConnectionTestSummary({required this.ok, required this.message, this.estUsdPer1000});
  final bool ok;
  final String message;

  /// Estimated cost per 1000 classified messages, when the price is known.
  final double? estUsdPer1000;
}
