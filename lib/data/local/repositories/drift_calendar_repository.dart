import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/entities/calendar.dart';
import '../../../domain/repositories/calendar_repository.dart';
import '../database.dart' as d;

class DriftCalendarRepository implements CalendarRepository {
  DriftCalendarRepository(this.db);
  final d.SortieDatabase db;

  // ------------------------------------------------------------- sources

  CalendarSource _source(d.CalendarRow r) => CalendarSource(
        id: r.id,
        name: r.name,
        kind: CalendarKind.values.byName(r.kind),
        url: r.url,
        username: r.username,
        color: r.color,
        enabled: r.enabled,
        readOnly: r.readOnly,
        authKind: CalendarAuthKind.values.byName(r.authKind),
        googleEmail: r.googleEmail,
        syncToken: r.syncToken,
        ctag: r.ctag,
        etag: r.etag,
        lastSyncAt: r.lastSyncAt == null ? null : DateTime.fromMillisecondsSinceEpoch(r.lastSyncAt!, isUtc: true),
        lastError: r.lastError,
        sortOrder: r.sortOrder,
      );

  d.CalendarsCompanion _sourceRow(CalendarSource s) => d.CalendarsCompanion(
        id: Value(s.id),
        name: Value(s.name),
        kind: Value(s.kind.name),
        url: Value(s.url),
        username: Value(s.username),
        color: Value(s.color),
        enabled: Value(s.enabled),
        readOnly: Value(s.readOnly),
        authKind: Value(s.authKind.name),
        googleEmail: Value(s.googleEmail),
        syncToken: Value(s.syncToken),
        ctag: Value(s.ctag),
        etag: Value(s.etag),
        lastSyncAt: Value(s.lastSyncAt?.millisecondsSinceEpoch),
        lastError: Value(s.lastError),
        sortOrder: Value(s.sortOrder),
      );

  SimpleSelectStatement<d.$CalendarsTable, d.CalendarRow> get _orderedSources =>
      db.select(db.calendars)..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.name)]);

  @override
  Stream<List<CalendarSource>> watchSources() => _orderedSources.watch().map((rows) => rows.map(_source).toList());

  @override
  Future<List<CalendarSource>> sources() async => (await _orderedSources.get()).map(_source).toList();

  @override
  Future<CalendarSource?> source(String id) async {
    final r = await (db.select(db.calendars)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _source(r);
  }

  @override
  Future<void> upsertSource(CalendarSource s) => db.into(db.calendars).insertOnConflictUpdate(_sourceRow(s));

  @override
  Future<void> upsertSources(List<CalendarSource> list) async {
    await db.transaction(() async {
      for (final s in list) {
        final existing = await source(s.id);
        final merged = existing == null
            ? s
            : existing.copyWith(
                name: s.name,
                kind: s.kind,
                url: s.url,
                username: s.username,
                color: s.color,
                enabled: s.enabled,
                readOnly: s.readOnly,
                authKind: s.authKind,
                googleEmail: s.googleEmail,
                sortOrder: s.sortOrder,
              );
        await upsertSource(merged);
      }
    });
  }

  @override
  Future<void> deleteSource(String id) => (db.delete(db.calendars)..where((t) => t.id.equals(id))).go();

  // -------------------------------------------------------------- events

  static List<DateTime> _dates(String json) =>
      [for (final v in (jsonDecode(json) as List)) DateTime.fromMillisecondsSinceEpoch(v as int, isUtc: true)];

  CalendarEvent _event(d.CalendarEventRow r) => CalendarEvent(
        id: r.id,
        calendarId: r.calendarId,
        uid: r.uid,
        href: r.href,
        etag: r.etag,
        summary: r.summary,
        description: r.description,
        location: r.location,
        start: DateTime.fromMillisecondsSinceEpoch(r.startAt, isUtc: true),
        end: DateTime.fromMillisecondsSinceEpoch(r.endAt, isUtc: true),
        isAllDay: r.isAllDay,
        floating: r.floating,
        tzid: r.tzid,
        rrule: r.rrule,
        exdates: _dates(r.exdatesJson),
        recurrenceId: r.recurrenceId == null ? null : DateTime.fromMillisecondsSinceEpoch(r.recurrenceId!, isUtc: true),
        status: r.status,
        organizer: r.organizer,
        attendees: [for (final a in (jsonDecode(r.attendeesJson) as List)) Attendee.fromJson((a as Map).cast<String, dynamic>())],
        alarms: (jsonDecode(r.alarmsJson) as List).cast<int>(),
        rawIcs: r.rawIcs,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt, isUtc: true),
        dirty: r.dirty,
        conflicted: r.conflicted,
        deleted: r.deleted,
      );

  d.CalendarEventsCompanion _eventRow(CalendarEvent e) => d.CalendarEventsCompanion(
        id: Value(e.id),
        calendarId: Value(e.calendarId),
        uid: Value(e.uid),
        href: Value(e.href),
        etag: Value(e.etag),
        summary: Value(e.summary),
        description: Value(e.description),
        location: Value(e.location),
        startAt: Value(e.start.toUtc().millisecondsSinceEpoch),
        endAt: Value(e.end.toUtc().millisecondsSinceEpoch),
        isAllDay: Value(e.isAllDay),
        floating: Value(e.floating),
        tzid: Value(e.tzid),
        rrule: Value(e.rrule),
        exdatesJson: Value(jsonEncode([for (final x in e.exdates) x.toUtc().millisecondsSinceEpoch])),
        recurrenceId: Value(e.recurrenceId?.toUtc().millisecondsSinceEpoch),
        status: Value(e.status),
        organizer: Value(e.organizer),
        attendeesJson: Value(jsonEncode([for (final a in e.attendees) a.toJson()])),
        alarmsJson: Value(jsonEncode(e.alarms)),
        rawIcs: Value(e.rawIcs),
        updatedAt: Value(e.updatedAt.toUtc().millisecondsSinceEpoch),
        dirty: Value(e.dirty),
        conflicted: Value(e.conflicted),
        deleted: Value(e.deleted),
      );

  @override
  Stream<List<CalendarEvent>> watchEvents({DateTime? from, DateTime? to}) {
    final q = db.select(db.calendarEvents).join([
      innerJoin(db.calendars, db.calendars.id.equalsExp(db.calendarEvents.calendarId)),
    ])
      ..where(db.calendars.enabled.equals(true) & db.calendarEvents.deleted.equals(false));
    if (from != null && to != null) {
      q.where(db.calendarEvents.rrule.isNotNull() |
          (db.calendarEvents.endAt.isBiggerOrEqualValue(from.toUtc().millisecondsSinceEpoch) &
              db.calendarEvents.startAt.isSmallerThanValue(to.toUtc().millisecondsSinceEpoch)));
    }
    return q.watch().map((rows) => rows.map((r) => _event(r.readTable(db.calendarEvents))).toList());
  }

  @override
  Future<List<CalendarEvent>> events(String calendarId, {bool includeDeleted = false}) async {
    final q = db.select(db.calendarEvents)..where((t) => t.calendarId.equals(calendarId));
    if (!includeDeleted) q.where((t) => t.deleted.equals(false));
    return (await q.get()).map(_event).toList();
  }

  @override
  Future<List<CalendarEvent>> eventsByUid(String calendarId, String uid) async {
    final rows = await (db.select(db.calendarEvents)
          ..where((t) => t.calendarId.equals(calendarId) & t.uid.equals(uid) & t.deleted.equals(false)))
        .get();
    return rows.map(_event).toList();
  }

  @override
  Future<CalendarEvent?> event(String id) async {
    final r = await (db.select(db.calendarEvents)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _event(r);
  }

  @override
  Future<void> upsertEvents(List<CalendarEvent> events) => db.batch((b) {
        for (final e in events) {
          b.insert(db.calendarEvents, _eventRow(e), onConflict: DoUpdate((_) => _eventRow(e)));
        }
      });

  @override
  Future<void> deleteEvents(List<String> ids) =>
      (db.delete(db.calendarEvents)..where((t) => t.id.isIn(ids))).go();

  @override
  Future<void> deleteByHrefs(String calendarId, List<String> hrefs) =>
      (db.delete(db.calendarEvents)..where((t) => t.calendarId.equals(calendarId) & t.href.isIn(hrefs))).go();

  @override
  Future<Map<String, String?>> etagsByHref(String calendarId) async {
    final rows = await (db.select(db.calendarEvents)
          ..where((t) => t.calendarId.equals(calendarId) & t.href.isNotNull() & t.deleted.equals(false)))
        .get();
    return {for (final r in rows) r.href!: r.etag};
  }

  @override
  Future<void> replaceEvents(String calendarId, List<CalendarEvent> events) => db.transaction(() async {
        await (db.delete(db.calendarEvents)..where((t) => t.calendarId.equals(calendarId))).go();
        await upsertEvents(events);
      });

  // --------------------------------------------------------------- queue

  CalendarSyncOp _op(d.CalendarSyncQueueRow r) => CalendarSyncOp(
        id: r.id,
        calendarId: r.calendarId,
        uid: r.uid,
        kind: CalendarSyncOpKind.values.byName(r.kind),
        href: r.href,
        etag: r.etag,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt, isUtc: true),
        attempts: r.attempts,
        lastError: r.lastError,
      );

  @override
  Future<void> enqueue(CalendarSyncOp op) => db.into(db.calendarSyncQueue).insertOnConflictUpdate(d.CalendarSyncQueueCompanion(
        id: Value(op.id),
        calendarId: Value(op.calendarId),
        uid: Value(op.uid),
        kind: Value(op.kind.name),
        href: Value(op.href),
        etag: Value(op.etag),
        createdAt: Value(op.createdAt.toUtc().millisecondsSinceEpoch),
        attempts: Value(op.attempts),
        lastError: Value(op.lastError),
      ));

  @override
  Future<List<CalendarSyncOp>> pendingOps({String? calendarId}) async {
    final q = db.select(db.calendarSyncQueue)..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    if (calendarId != null) q.where((t) => t.calendarId.equals(calendarId));
    return (await q.get()).map(_op).toList();
  }

  @override
  Future<void> completeOp(String id) => (db.delete(db.calendarSyncQueue)..where((t) => t.id.equals(id))).go();

  @override
  Future<void> failOp(String id, String error) async {
    final r = await (db.select(db.calendarSyncQueue)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (r == null) return;
    await (db.update(db.calendarSyncQueue)..where((t) => t.id.equals(id)))
        .write(d.CalendarSyncQueueCompanion(attempts: Value(r.attempts + 1), lastError: Value(error)));
  }
}
