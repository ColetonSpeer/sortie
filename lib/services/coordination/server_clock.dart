import '../../core/clock.dart';

/// Estimate of the IMAP server's clock, built from INTERNALDATEs of our own
/// appends paired with the local monotonic clock. Wall-clock jumps on the
/// device never move it; only [Clock.monotonic] advances it.
class ServerClock {
  ServerClock(this._clock);
  final Clock _clock;

  DateTime? _lastServer;
  Duration? _lastMono;

  bool get primed => _lastServer != null;

  /// Records the INTERNALDATE the server stamped on something we appended
  /// just now. Estimates never run backwards: an INTERNALDATE that would
  /// move us back by more than the server's 1 s resolution is a stale fetch
  /// and is ignored.
  void observe(DateTime internalDate) {
    final mono = _clock.monotonic();
    final candidate = internalDate.toUtc();
    final current = nowOrNull();
    if (current != null && current.difference(candidate) > const Duration(seconds: 1)) return;
    _lastServer = candidate;
    _lastMono = mono;
  }

  /// Current server time estimate. Throws [StateError] until primed.
  DateTime now() {
    final n = nowOrNull();
    if (n == null) throw StateError('ServerClock not primed');
    return n;
  }

  DateTime? nowOrNull() {
    final s = _lastServer;
    final m = _lastMono;
    if (s == null || m == null) return null;
    return s.add(_clock.monotonic() - m);
  }

  /// `internalDate < now - ttl` (fresh means `internalDate >= now - ttl`).
  bool isExpired(DateTime internalDate, Duration ttl) => internalDate.toUtc().isBefore(now().subtract(ttl));

  /// Time until [internalDate] + [ttl] passes; zero if already expired.
  Duration untilExpiry(DateTime internalDate, Duration ttl) {
    final d = internalDate.toUtc().add(ttl).difference(now());
    return d.isNegative ? Duration.zero : d;
  }
}
