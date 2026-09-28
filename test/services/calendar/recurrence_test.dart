import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/calendar.dart';
import 'package:sortie/services/calendar/recurrence.dart';
import 'package:sortie/services/calendar/tz.dart';

CalendarEvent _ev({
  String uid = 'u',
  required DateTime start,
  required DateTime end,
  String? tzid,
  String? rrule,
  bool allDay = false,
  List<DateTime> exdates = const [],
  DateTime? recurrenceId,
  String summary = '',
}) =>
    CalendarEvent(
      id: 'c|$uid${recurrenceId == null ? '' : '|${recurrenceId.millisecondsSinceEpoch}'}',
      calendarId: 'c',
      uid: uid,
      start: start,
      end: end,
      tzid: tzid,
      rrule: rrule,
      isAllDay: allDay,
      exdates: exdates,
      recurrenceId: recurrenceId,
      summary: summary,
      updatedAt: DateTime.utc(2026),
    );

void main() {
  setUpAll(ensureTimeZonesLoaded);

  test('weekly 9:00 New York meeting keeps wall time across the March DST change', () {
    // 2026-03-02 09:00 EST = 14:00Z; DST starts 2026-03-08 so 03-09 09:00 EDT = 13:00Z.
    final e = _ev(start: DateTime.utc(2026, 3, 2, 14), end: DateTime.utc(2026, 3, 2, 15), tzid: 'America/New_York', rrule: 'FREQ=WEEKLY;BYDAY=MO');
    final occ = occurrences([e], DateTime.utc(2026, 3, 1), DateTime.utc(2026, 3, 20));
    expect(occ.map((o) => o.start), [DateTime.utc(2026, 3, 2, 14), DateTime.utc(2026, 3, 9, 13), DateTime.utc(2026, 3, 16, 13)]);
    expect(occ.every((o) => o.end.difference(o.start) == const Duration(hours: 1)), isTrue);
  });

  test('EXDATE removes instances and RECURRENCE-ID overrides replace them', () {
    final master = _ev(
      start: DateTime.utc(2026, 1, 1, 10),
      end: DateTime.utc(2026, 1, 1, 11),
      rrule: 'FREQ=DAILY;COUNT=5',
      exdates: [DateTime.utc(2026, 1, 2, 10)],
      summary: 'master',
    );
    final override = _ev(
      start: DateTime.utc(2026, 1, 3, 15),
      end: DateTime.utc(2026, 1, 3, 16),
      recurrenceId: DateTime.utc(2026, 1, 3, 10),
      summary: 'moved',
    );
    final occ = occurrences([master, override], DateTime.utc(2026, 1, 1), DateTime.utc(2026, 1, 10));
    expect(occ.map((o) => '${o.event.summary}@${o.start.day}T${o.start.hour}'), ['master@1T10', 'moved@3T15', 'master@4T10', 'master@5T10']);
  });

  test('all-day yearly event expands by date and respects the window', () {
    final e = _ev(start: DateTime.utc(2000, 6, 15), end: DateTime.utc(2000, 6, 16), allDay: true, rrule: 'FREQ=YEARLY');
    final occ = occurrences([e], DateTime.utc(2026, 1, 1), DateTime.utc(2027, 12, 31));
    expect(occ.map((o) => o.start), [DateTime.utc(2026, 6, 15), DateTime.utc(2027, 6, 15)]);
    expect(occ.first.end, DateTime.utc(2026, 6, 16));
  });

  test('non-recurring events overlapping the window are included once', () {
    final e = _ev(start: DateTime.utc(2026, 5, 1, 23), end: DateTime.utc(2026, 5, 2, 1));
    expect(occurrences([e], DateTime.utc(2026, 5, 2), DateTime.utc(2026, 5, 3)), hasLength(1));
    expect(occurrences([e], DateTime.utc(2026, 5, 3), DateTime.utc(2026, 5, 4)), isEmpty);
  });

  test('long-running recurring events that started before the window still show', () {
    final e = _ev(start: DateTime.utc(2026, 1, 1, 22), end: DateTime.utc(2026, 1, 2, 2), rrule: 'FREQ=DAILY');
    final occ = occurrences([e], DateTime.utc(2026, 2, 10), DateTime.utc(2026, 2, 11));
    expect(occ.map((o) => o.start), [DateTime.utc(2026, 2, 9, 22), DateTime.utc(2026, 2, 10, 22)]);
  });

  test('invalid RRULE degrades to a single occurrence; presets map both ways', () {
    final e = _ev(start: DateTime.utc(2026, 1, 1, 10), end: DateTime.utc(2026, 1, 1, 11), rrule: 'FREQ=BOGUS');
    expect(occurrences([e], DateTime.utc(2026, 1, 1), DateTime.utc(2026, 2, 1)), hasLength(1));
    expect(parseRrule('RRULE:FREQ=WEEKLY')?.toString(), 'RRULE:FREQ=WEEKLY');
    expect(presetOf('FREQ=MONTHLY'), RepeatPreset.monthly);
    expect(presetOf('FREQ=WEEKLY;BYDAY=MO'), RepeatPreset.custom);
    expect(rruleOf(RepeatPreset.custom, custom: 'RRULE:FREQ=DAILY;COUNT=3'), 'FREQ=DAILY;COUNT=3');
    expect(rruleOf(RepeatPreset.none), isNull);
  });
}
