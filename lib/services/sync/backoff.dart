import 'dart:math';

/// Exponential backoff 1..300 s (doubling) with ±20 % jitter.
class Backoff {
  Backoff({
    this.min = const Duration(seconds: 1),
    this.max = const Duration(seconds: 300),
    this.jitter = 0.2,
    Random? random,
  }) : _random = random ?? Random();

  final Duration min;
  final Duration max;
  final double jitter;
  final Random _random;
  int _attempt = 0;

  int get attempt => _attempt;

  /// Base delay for attempt [n] (1-based) without jitter.
  Duration baseFor(int n) {
    if (n <= 1) return min;
    final ms = min.inMilliseconds * pow(2, n - 1);
    return ms >= max.inMilliseconds ? max : Duration(milliseconds: ms.toInt());
  }

  /// Registers a failure and returns how long to wait before the next try.
  Duration next() {
    _attempt++;
    final base = baseFor(_attempt);
    final f = 1 + (_random.nextDouble() * 2 - 1) * jitter;
    var d = Duration(milliseconds: (base.inMilliseconds * f).round());
    if (d > max) d = max;
    if (d < min) d = min;
    return d;
  }

  void reset() => _attempt = 0;
}
