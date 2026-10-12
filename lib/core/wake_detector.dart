import 'dart:async';

/// Notices the machine waking from sleep: a periodic tick whose wall-clock
/// gap is far longer than its interval means the process was frozen. The
/// gap is reported so listeners can decide how stale their connections are.
class WakeDetector {
  WakeDetector({
    this.interval = const Duration(seconds: 20),
    this.threshold = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Duration interval;

  /// Extra wall-clock time beyond [interval] that counts as a wake.
  final Duration threshold;
  final DateTime Function() _now;
  final _ctrl = StreamController<Duration>.broadcast();
  Timer? _timer;
  DateTime? _last;

  Stream<Duration> get wakes => _ctrl.stream;

  void start() {
    if (_timer != null) return;
    _last = _now();
    _timer = Timer.periodic(interval, (_) {
      final n = _now();
      final gap = n.difference(_last!);
      _last = n;
      if (gap - interval > threshold && !_ctrl.isClosed) _ctrl.add(gap);
    });
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    await _ctrl.close();
  }
}
