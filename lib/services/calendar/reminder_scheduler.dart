import 'dart:async';

import '../../core/clock.dart';
import '../../domain/entities/calendar.dart';

/// Fires a callback `alarm` minutes before each occurrence while the app runs.
/// Timers are rebuilt from the current occurrence list on every [reschedule].
class ReminderScheduler {
  ReminderScheduler({required this.clock, required this.onReminder, this.horizon = const Duration(hours: 36)});

  final Clock clock;
  final Future<void> Function(EventOccurrence occurrence, int minutesBefore) onReminder;
  final Duration horizon;
  final _timers = <String, Timer>{};
  final _fired = <String>{};

  int get pending => _timers.length;

  void reschedule(Iterable<EventOccurrence> upcoming) {
    final now = clock.now().toUtc();
    final wanted = <String, (EventOccurrence, int, DateTime)>{};
    for (final o in upcoming) {
      for (final m in o.event.alarms) {
        final at = o.start.subtract(Duration(minutes: m));
        if (at.isBefore(now.subtract(const Duration(minutes: 1))) || at.isAfter(now.add(horizon))) continue;
        wanted['${o.key}:$m'] = (o, m, at);
      }
    }
    for (final k in _timers.keys.toList()) {
      if (!wanted.containsKey(k)) _timers.remove(k)?.cancel();
    }
    for (final e in wanted.entries) {
      if (_timers.containsKey(e.key) || _fired.contains(e.key)) continue;
      final (o, m, at) = e.value;
      final delay = at.difference(now);
      _timers[e.key] = Timer(delay.isNegative ? Duration.zero : delay, () {
        _timers.remove(e.key);
        _fired.add(e.key);
        unawaited(onReminder(o, m));
      });
    }
  }

  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }
}
