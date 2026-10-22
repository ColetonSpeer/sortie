/// VEVENT <-> [CalendarEvent] mapping and the VCALENDAR serializer.
library;

import '../../domain/entities/calendar.dart';
import 'ics.dart';
import 'tz.dart';

const icsProdId = '-//Sortie//Calendar//EN';

/// Deterministic event id so re-syncing the same resource updates in place.
String calendarEventId(String calendarId, String uid, DateTime? recurrenceId) =>
    '$calendarId|$uid${recurrenceId == null ? '' : '|${recurrenceId.millisecondsSinceEpoch}'}';

/// Standard offsets from every VTIMEZONE in [components], by TZID.
Map<String, Duration> vtimezoneOffsets(Iterable<IcsComponent> components) {
  final out = <String, Duration>{};
  for (final cal in components) {
    for (final tz in cal.childrenNamed('VTIMEZONE')) {
      final id = tz.prop('TZID')?.value;
      if (id == null) continue;
      final std = tz.childrenNamed('STANDARD').firstOrNull ?? tz.children.firstOrNull;
      final off = std?.prop('TZOFFSETTO')?.value;
      final d = off == null ? null : _parseOffset(off);
      if (d != null) out[id] = d;
    }
  }
  return out;
}

Duration? _parseOffset(String s) {
  final m = RegExp(r'^([+-])(\d{2})(\d{2})(\d{2})?$').firstMatch(s.trim());
  if (m == null) return null;
  final d = Duration(hours: int.parse(m[2]!), minutes: int.parse(m[3]!), seconds: int.parse(m[4] ?? '0'));
  return m[1] == '-' ? -d : d;
}

/// Parses every VEVENT of an iCalendar text into events of [calendarId].
List<CalendarEvent> eventsFromIcs(
  String ics, {
  required String calendarId,
  String? href,
  String? etag,
  DateTime? now,
}) {
  final comps = parseIcs(ics);
  final offsets = vtimezoneOffsets(comps);
  final out = <CalendarEvent>[];
  final vevents = <IcsComponent>[];
  for (final c in comps) {
    if (c.name == 'VEVENT') vevents.add(c);
    vevents.addAll(c.childrenNamed('VEVENT'));
  }
  for (final v in vevents) {
    final e = eventFromComponent(v, calendarId: calendarId, href: href, etag: etag, offsets: offsets, now: now);
    if (e != null) out.add(e.copyWith(rawIcs: vevents.length == 1 ? ics : null));
  }
  return out;
}

DateTime _toUtc(IcsTime t, Map<String, Duration> offsets) {
  if (t.isDate) return t.wall;
  if (t.isUtc) return t.wall;
  return resolveZone(t.tzid, fallbackOffsets: offsets).toUtc(t.wall);
}

CalendarEvent? eventFromComponent(
  IcsComponent v, {
  required String calendarId,
  String? href,
  String? etag,
  Map<String, Duration> offsets = const {},
  DateTime? now,
}) {
  final uid = v.prop('UID')?.value ?? '';
  final dtstartP = v.prop('DTSTART');
  if (uid.isEmpty || dtstartP == null) return null;
  final dtstart = timeOf(dtstartP);
  if (dtstart == null) return null;
  final start = _toUtc(dtstart, offsets);

  DateTime end;
  final dtendP = v.prop('DTEND');
  final durP = v.prop('DURATION');
  if (dtendP != null && timeOf(dtendP) != null) {
    end = _toUtc(timeOf(dtendP)!, offsets);
  } else if (durP != null && parseIcsDuration(durP.value) != null) {
    end = start.add(parseIcsDuration(durP.value)!);
  } else {
    end = dtstart.isDate ? start.add(const Duration(days: 1)) : start;
  }

  final exdates = <DateTime>[];
  for (final p in v.props('EXDATE')) {
    for (final raw in p.value.split(',')) {
      final t = parseIcsTime(raw, tzid: p.param('TZID') ?? dtstart.tzid, forceDate: p.param('VALUE') == 'DATE');
      if (t != null) exdates.add(_toUtc(t, offsets));
    }
  }
  final ridP = v.prop('RECURRENCE-ID');
  final rid = ridP == null ? null : timeOf(ridP);

  final attendees = <Attendee>[];
  for (final p in v.props('ATTENDEE')) {
    attendees.add(Attendee(
      email: _mailto(p.value),
      name: p.param('CN'),
      status: _partstat(p.param('PARTSTAT')),
    ));
  }
  final alarms = <int>[];
  for (final a in v.childrenNamed('VALARM')) {
    final trig = a.prop('TRIGGER');
    if (trig == null) continue;
    if (trig.param('VALUE')?.toUpperCase() == 'DATE-TIME') {
      final t = parseIcsTime(trig.value);
      if (t != null) alarms.add(start.difference(_toUtc(t, offsets)).inMinutes);
      continue;
    }
    final d = parseIcsDuration(trig.value);
    if (d != null) alarms.add(-d.inMinutes);
  }
  final rruleP = v.prop('RRULE');
  final modified = v.prop('LAST-MODIFIED') ?? v.prop('DTSTAMP');
  final modT = modified == null ? null : timeOf(modified);

  return CalendarEvent(
    id: calendarEventId(calendarId, uid, rid == null ? null : _toUtc(rid, offsets)),
    calendarId: calendarId,
    uid: uid,
    href: href,
    etag: etag,
    summary: unescapeText(v.prop('SUMMARY')?.value ?? ''),
    description: _textOrNull(v.prop('DESCRIPTION')),
    location: _textOrNull(v.prop('LOCATION')),
    start: start,
    end: end,
    isAllDay: dtstart.isDate,
    floating: dtstart.isFloating,
    tzid: dtstart.isDate || dtstart.isUtc ? null : dtstart.tzid,
    rrule: rruleP == null ? null : _stripRrulePrefix(rruleP.value),
    exdates: exdates,
    recurrenceId: rid == null ? null : _toUtc(rid, offsets),
    status: v.prop('STATUS')?.value.toUpperCase(),
    organizer: v.prop('ORGANIZER') == null ? null : _mailto(v.prop('ORGANIZER')!.value),
    attendees: attendees,
    alarms: alarms,
    updatedAt: modT != null ? _toUtc(modT, offsets) : (now ?? DateTime.now().toUtc()),
  );
}

String _stripRrulePrefix(String s) => s.toUpperCase().startsWith('RRULE:') ? s.substring(6) : s;
String? _textOrNull(IcsProperty? p) => p == null || p.value.isEmpty ? null : unescapeText(p.value);
String _mailto(String v) => v.toLowerCase().startsWith('mailto:') ? v.substring(7) : v;

AttendeeStatus _partstat(String? s) => switch (s?.toUpperCase()) {
      'ACCEPTED' => AttendeeStatus.accepted,
      'DECLINED' => AttendeeStatus.declined,
      'TENTATIVE' => AttendeeStatus.tentative,
      'DELEGATED' => AttendeeStatus.delegated,
      _ => AttendeeStatus.needsAction,
    };

String _partstatName(AttendeeStatus s) => switch (s) {
      AttendeeStatus.accepted => 'ACCEPTED',
      AttendeeStatus.declined => 'DECLINED',
      AttendeeStatus.tentative => 'TENTATIVE',
      AttendeeStatus.delegated => 'DELEGATED',
      AttendeeStatus.needsAction => 'NEEDS-ACTION',
    };

/// Serializes one UID's events (master plus detached overrides) as a
/// VCALENDAR resource suitable for a CalDAV PUT.
String icsFromEvents(Iterable<CalendarEvent> events, {DateTime? now}) {
  final w = IcsWriter();
  w.begin('VCALENDAR');
  w.prop('VERSION', '2.0');
  w.prop('PRODID', icsProdId);
  for (final e in events) {
    writeEvent(w, e, now: now);
  }
  w.end('VCALENDAR');
  return w.toString();
}

void _writeTime(IcsWriter w, String name, DateTime utc, CalendarEvent e) {
  if (e.isAllDay) {
    w.prop(name, formatIcsDate(utc), params: const {'VALUE': 'DATE'});
  } else if (e.tzid != null) {
    // Only an IANA id travels as TZID: Google and other servers read a
    // Windows name like "Central Standard Time" as UTC and shift the event.
    final zone = resolveZone(e.tzid);
    if (zone is IanaZone) {
      w.prop(name, formatIcsDateTime(zone.toWall(utc)), params: {'TZID': zone.id});
    } else {
      w.prop(name, formatIcsDateTime(utc.toUtc(), utc: true));
    }
  } else if (e.floating) {
    w.prop(name, formatIcsDateTime(const LocalZone().toWall(utc)));
  } else {
    w.prop(name, formatIcsDateTime(utc.toUtc(), utc: true));
  }
}

void writeEvent(IcsWriter w, CalendarEvent e, {DateTime? now}) {
  final stamp = (now ?? DateTime.now()).toUtc();
  w.begin('VEVENT');
  w.prop('UID', e.uid);
  w.prop('DTSTAMP', formatIcsDateTime(stamp, utc: true));
  w.prop('LAST-MODIFIED', formatIcsDateTime(e.updatedAt.toUtc(), utc: true));
  _writeTime(w, 'DTSTART', e.start, e);
  _writeTime(w, 'DTEND', e.end, e);
  if (e.recurrenceId != null) _writeTime(w, 'RECURRENCE-ID', e.recurrenceId!, e);
  w.text('SUMMARY', e.summary);
  w.text('DESCRIPTION', e.description);
  w.text('LOCATION', e.location);
  if (e.status != null) w.prop('STATUS', e.status!);
  if (e.isRecurring) w.prop('RRULE', e.rrule!);
  for (final x in e.exdates) {
    _writeTime(w, 'EXDATE', x, e);
  }
  if (e.organizer != null) w.prop('ORGANIZER', 'mailto:${e.organizer}');
  for (final a in e.attendees) {
    w.prop('ATTENDEE', 'mailto:${a.email}', params: {
      if (a.name != null) 'CN': a.name!,
      'PARTSTAT': _partstatName(a.status),
    });
  }
  for (final m in e.alarms) {
    w.begin('VALARM');
    w.prop('ACTION', 'DISPLAY');
    w.prop('TRIGGER', formatIcsDuration(Duration(minutes: -m)));
    w.text('DESCRIPTION', e.summary.isEmpty ? 'Reminder' : e.summary);
    w.end('VALARM');
  }
  w.end('VEVENT');
}
