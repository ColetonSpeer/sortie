import 'dart:async';

import '../../domain/entities/calendar.dart';
import '../../domain/repositories/calendar_repository.dart';

/// In-memory calendar store for the demo build and widget tests.
class FakeCalendarRepository implements CalendarRepository {
  FakeCalendarRepository({List<CalendarSource> sources = const [], List<CalendarEvent> events = const []}) {
    for (final s in sources) {
      _sources[s.id] = s;
    }
    for (final e in events) {
      _events[e.id] = e;
    }
  }

  final _sources = <String, CalendarSource>{};
  final _events = <String, CalendarEvent>{};
  final _ops = <String, CalendarSyncOp>{};
  final _sourcesCtrl = StreamController<List<CalendarSource>>.broadcast();
  final _eventsCtrl = StreamController<List<CalendarEvent>>.broadcast();

  List<CalendarSource> get sourceList => _sources.values.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  List<CalendarEvent> get eventList => _events.values.toList();
  List<CalendarSyncOp> get ops => _ops.values.toList();

  void _emit() {
    _sourcesCtrl.add(sourceList);
    _eventsCtrl.add(_visible());
  }

  List<CalendarEvent> _visible() =>
      [for (final e in _events.values) if (!e.deleted && (_sources[e.calendarId]?.enabled ?? false)) e];

  @override
  Stream<List<CalendarSource>> watchSources() async* {
    yield sourceList;
    yield* _sourcesCtrl.stream;
  }

  @override
  Future<List<CalendarSource>> sources() async => sourceList;
  @override
  Future<CalendarSource?> source(String id) async => _sources[id];
  @override
  Future<void> upsertSource(CalendarSource s) async {
    _sources[s.id] = s;
    _emit();
  }

  @override
  Future<void> upsertSources(List<CalendarSource> list) async {
    for (final s in list) {
      final old = _sources[s.id];
      _sources[s.id] = old == null
          ? s
          : old.copyWith(
              name: s.name, kind: s.kind, url: s.url, username: s.username, color: s.color, enabled: s.enabled,
              readOnly: s.readOnly, authKind: s.authKind, googleEmail: s.googleEmail, sortOrder: s.sortOrder);
    }
    _emit();
  }

  @override
  Future<void> deleteSource(String id) async {
    _sources.remove(id);
    _events.removeWhere((_, e) => e.calendarId == id);
    _ops.removeWhere((_, o) => o.calendarId == id);
    _emit();
  }

  @override
  Stream<List<CalendarEvent>> watchEvents({DateTime? from, DateTime? to}) async* {
    List<CalendarEvent> filter(List<CalendarEvent> l) => from == null || to == null
        ? l
        : [for (final e in l) if (e.isRecurring || (e.end.isAfter(from) && e.start.isBefore(to))) e];
    yield filter(_visible());
    yield* _eventsCtrl.stream.map(filter);
  }

  @override
  Future<List<CalendarEvent>> events(String calendarId, {bool includeDeleted = false}) async =>
      [for (final e in _events.values) if (e.calendarId == calendarId && (includeDeleted || !e.deleted)) e];
  @override
  Future<List<CalendarEvent>> eventsByUid(String calendarId, String uid) async =>
      [for (final e in _events.values) if (e.calendarId == calendarId && e.uid == uid && !e.deleted) e];
  @override
  Future<CalendarEvent?> event(String id) async => _events[id];
  @override
  Future<void> upsertEvents(List<CalendarEvent> events) async {
    for (final e in events) {
      _events[e.id] = e;
    }
    _emit();
  }

  @override
  Future<void> deleteEvents(List<String> ids) async {
    for (final id in ids) {
      _events.remove(id);
    }
    _emit();
  }

  @override
  Future<void> deleteByHrefs(String calendarId, List<String> hrefs) async {
    _events.removeWhere((_, e) => e.calendarId == calendarId && hrefs.contains(e.href));
    _emit();
  }

  @override
  Future<Map<String, String?>> etagsByHref(String calendarId) async =>
      {for (final e in _events.values) if (e.calendarId == calendarId && e.href != null && !e.deleted) e.href!: e.etag};

  @override
  Future<void> replaceEvents(String calendarId, List<CalendarEvent> events) async {
    _events.removeWhere((_, e) => e.calendarId == calendarId);
    await upsertEvents(events);
  }

  @override
  Future<void> enqueue(CalendarSyncOp op) async => _ops[op.id] = op;
  @override
  Future<List<CalendarSyncOp>> pendingOps({String? calendarId}) async =>
      [for (final o in _ops.values) if (calendarId == null || o.calendarId == calendarId) o]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  @override
  Future<void> completeOp(String id) async => _ops.remove(id);
  @override
  Future<void> failOp(String id, String error) async {
    final o = _ops[id];
    if (o == null) return;
    _ops[id] = CalendarSyncOp(
        id: o.id, calendarId: o.calendarId, uid: o.uid, kind: o.kind, href: o.href, etag: o.etag,
        createdAt: o.createdAt, attempts: o.attempts + 1, lastError: error);
  }
}

/// Obviously fake calendars and events around [now] for the demo build.
abstract final class DemoCalendarData {
  static const workId = 'demo-cal-work';
  static const homeId = 'demo-cal-home';
  static const holidaysId = 'demo-cal-holidays';

  static const sources = [
    CalendarSource(id: workId, name: 'Work (demo)', kind: CalendarKind.local, color: 0xFF3F51B5),
    CalendarSource(id: homeId, name: 'Home (demo)', kind: CalendarKind.local, color: 0xFF43A047),
    CalendarSource(id: holidaysId, name: 'Holidays (demo feed)', kind: CalendarKind.ics, url: 'https://example.invalid/holidays.ics', color: 0xFFE53935, readOnly: true),
  ];

  static List<CalendarEvent> events(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    DateTime at(int dayOffset, int hour, [int minute = 0]) => today.add(Duration(days: dayOffset, hours: hour, minutes: minute)).toUtc();
    CalendarEvent ev(String cal, String uid, String title, DateTime s, DateTime e,
            {String? loc, String? desc, String? rrule, bool allDay = false, List<int> alarms = const [10], List<Attendee> att = const []}) =>
        CalendarEvent(
          id: '$cal|$uid',
          calendarId: cal,
          uid: uid,
          summary: title,
          start: s,
          end: e,
          location: loc,
          description: desc,
          rrule: rrule,
          isAllDay: allDay,
          tzid: allDay ? null : 'America/Chicago',
          alarms: alarms,
          attendees: att,
          updatedAt: now.toUtc(),
        );
    return [
      ev(workId, 'demo-standup', 'Team standup (demo)', at(0, 9), at(0, 9, 15), rrule: 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
          loc: 'Room 2', desc: 'Daily sync. Notes: https://example.invalid/standup',
          att: const [Attendee(email: 'pat@example.invalid', name: 'Pat Example', status: AttendeeStatus.accepted)]),
      ev(workId, 'demo-planning', 'Q3 planning review (demo)', at(1, 14), at(1, 15, 30), loc: 'Main conference room'),
      ev(workId, 'demo-1on1', '1:1 with Sam (demo)', at(2, 11), at(2, 11, 30), rrule: 'FREQ=WEEKLY'),
      ev(homeId, 'demo-dentist', 'Dentist (demo)', at(3, 16, 30), at(3, 17, 15), loc: '12 Example St'),
      ev(homeId, 'demo-birthday', "Mom's birthday (demo)", DateTime.utc(today.year, today.month, today.day + 5),
          DateTime.utc(today.year, today.month, today.day + 6), allDay: true, rrule: 'FREQ=YEARLY', alarms: const [1440]),
      ev(homeId, 'demo-dinner', 'Dinner with friends (demo)', at(-2, 19), at(-2, 22)),
      ev(holidaysId, 'demo-holiday', 'Public holiday (demo)', DateTime.utc(today.year, today.month, today.day + 12),
          DateTime.utc(today.year, today.month, today.day + 13), allDay: true, alarms: const []),
    ];
  }
}
