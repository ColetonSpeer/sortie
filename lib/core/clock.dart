/// Injectable time source so services can be tested with fake time.
abstract class Clock {
  const Clock();

  /// Wall-clock time. Display only; never compare across devices.
  DateTime now();

  /// Monotonic elapsed time since an arbitrary origin.
  Duration monotonic();
}

class SystemClock extends Clock {
  SystemClock() : _sw = Stopwatch()..start();
  final Stopwatch _sw;

  @override
  DateTime now() => DateTime.now();

  @override
  Duration monotonic() => _sw.elapsed;
}

/// Manually advanced clock for tests.
class FakeClock extends Clock {
  FakeClock([DateTime? start]) : _now = start ?? DateTime.utc(2026, 1, 1);
  DateTime _now;
  Duration _mono = Duration.zero;

  @override
  DateTime now() => _now;

  @override
  Duration monotonic() => _mono;

  void advance(Duration d) {
    _now = _now.add(d);
    _mono += d;
  }

  /// Jump the wall clock without touching the monotonic clock (clock skew).
  void skew(Duration d) => _now = _now.add(d);
}
