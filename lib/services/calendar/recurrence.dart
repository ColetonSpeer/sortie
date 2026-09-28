import 'package:rrule/rrule.dart';

import '../../domain/entities/calendar.dart';
import 'tz.dart';

/// Expands [events] into occurrences overlapping `[from, to)` (UTC).
/// Recurrence is evaluated on wall-clock time in the event's zone and each
/// instance converted back, so a 9:00 weekly meeting stays 9:00 across DST.
/// EXDATEs remove instances; detached RECURRENCE-ID overrides replace them.
List<EventOccurrence> occurrences(Iterable<CalendarEvent> events, DateTime from, DateTime to) {
  final fromU = from.toUtc();
  final toU = to.toUtc();
  final overridden = <String, Set<int>>{};
  for (final e in events) {
    if (e.recurrenceId != null) {
      overridden.putIfAbsent('${e.calendarId}|${e.uid}', () => {}).add(e.recurrenceId!.millisecondsSinceEpoch);
    }
  }
  final out = <EventOccurrence>[];
  for (final e in events) {
    if (e.deleted) continue;
    if (!e.isRecurring || e.isOverride) {
      if (e.start.isBefore(toU) && (e.end.isAfter(fromU) || (e.end == e.start && !e.start.isBefore(fromU)))) {
        out.add(EventOccurrence(event: e, start: e.start, end: e.end));
      }
      continue;
    }
    final skip = overridden['${e.calendarId}|${e.uid}'] ?? const <int>{};
    out.addAll(expandRecurring(e, fromU, toU, skip: skip));
  }
  out.sort((a, b) {
    final c = a.start.compareTo(b.start);
    return c != 0 ? c : a.event.summary.compareTo(b.event.summary);
  });
  return out;
}

RecurrenceRule? parseRrule(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final s = raw.trim();
  try {
    return RecurrenceRule.fromString(
      s.toUpperCase().startsWith('RRULE:') ? s : 'RRULE:$s',
      options: const RecurrenceRuleFromStringOptions.lenient(),
    );
  } on FormatException {
    return null;
  }
}

Zone _zoneOf(CalendarEvent e) {
  if (e.isAllDay) return const UtcZone();
  if (e.tzid != null) return resolveZone(e.tzid);
  if (e.floating) return const LocalZone();
  return const UtcZone();
}

List<EventOccurrence> expandRecurring(CalendarEvent e, DateTime from, DateTime to, {Set<int> skip = const {}}) {
  final rule = parseRrule(e.rrule);
  if (rule == null) {
    return e.start.isBefore(to) && e.end.isAfter(from) ? [EventOccurrence(event: e, start: e.start, end: e.end)] : const [];
  }
  final zone = _zoneOf(e);
  final startWall = zone.toWall(e.start);
  final endWall = zone.toWall(e.end);
  final wallDuration = endWall.difference(startWall);
  final exdates = e.exdates.map((d) => d.millisecondsSinceEpoch).toSet();

  // Wall-clock window, widened by the duration so long events that started
  // before `from` still show, and by a day for zone offset slack.
  var afterWall = zone.toWall(from).subtract(wallDuration + const Duration(days: 1));
  final beforeWall = zone.toWall(to).add(const Duration(days: 1));
  final out = <EventOccurrence>[];
  // rrule requires start <= after/before.
  if (beforeWall.isBefore(startWall)) return out;
  if (afterWall.isBefore(startWall)) afterWall = startWall;
  Iterable<DateTime> instances;
  try {
    instances = rule.getInstances(start: startWall, after: afterWall, includeAfter: true, before: beforeWall);
  } catch (_) {
    return out;
  }
  for (final wall in instances) {
    final s = zone.toUtc(wall);
    final en = zone.toUtc(wall.add(wallDuration));
    if (!s.isBefore(to)) break;
    if (!en.isAfter(from) && !(en == s && !s.isBefore(from))) continue;
    final key = s.millisecondsSinceEpoch;
    if (exdates.contains(key) || skip.contains(key)) continue;
    // All-day EXDATEs may have been given as dates or as date-times: also
    // match on the calendar date.
    if (e.isAllDay && e.exdates.any((x) => x.year == s.year && x.month == s.month && x.day == s.day)) continue;
    out.add(EventOccurrence(event: e, start: s, end: en));
  }
  return out;
}

/// Simple presets used by the editor's "Repeat" menu.
enum RepeatPreset { none, daily, weekly, monthly, yearly, custom }

RepeatPreset presetOf(String? rrule) {
  if (rrule == null || rrule.isEmpty) return RepeatPreset.none;
  final u = rrule.toUpperCase().replaceFirst('RRULE:', '');
  return switch (u) {
    'FREQ=DAILY' => RepeatPreset.daily,
    'FREQ=WEEKLY' => RepeatPreset.weekly,
    'FREQ=MONTHLY' => RepeatPreset.monthly,
    'FREQ=YEARLY' => RepeatPreset.yearly,
    _ => RepeatPreset.custom,
  };
}

String? rruleOf(RepeatPreset p, {String? custom}) => switch (p) {
      RepeatPreset.none => null,
      RepeatPreset.daily => 'FREQ=DAILY',
      RepeatPreset.weekly => 'FREQ=WEEKLY',
      RepeatPreset.monthly => 'FREQ=MONTHLY',
      RepeatPreset.yearly => 'FREQ=YEARLY',
      RepeatPreset.custom => custom?.trim().isEmpty ?? true ? null : custom!.trim().replaceFirst(RegExp('^RRULE:', caseSensitive: false), ''),
    };
