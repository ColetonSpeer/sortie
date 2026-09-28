import '../entities/calendar.dart';

/// Local store for calendar sources, events and the upload queue.
abstract class CalendarRepository {
  Stream<List<CalendarSource>> watchSources();
  Future<List<CalendarSource>> sources();
  Future<CalendarSource?> source(String id);
  Future<void> upsertSource(CalendarSource s);

  /// Merge shared descriptions (e.g. received from another device): for ids
  /// that already exist, device-local fields (sync tokens, ctag, etag, last
  /// sync / error) are preserved and only the shareable fields are updated.
  Future<void> upsertSources(List<CalendarSource> list);
  Future<void> deleteSource(String id);

  /// Events of enabled calendars that may produce occurrences in the window
  /// (recurring events are always included; the caller expands them).
  Stream<List<CalendarEvent>> watchEvents({DateTime? from, DateTime? to});
  Future<List<CalendarEvent>> events(String calendarId, {bool includeDeleted = false});
  Future<List<CalendarEvent>> eventsByUid(String calendarId, String uid);
  Future<CalendarEvent?> event(String id);
  Future<void> upsertEvents(List<CalendarEvent> events);
  Future<void> deleteEvents(List<String> ids);
  Future<void> deleteByHrefs(String calendarId, List<String> hrefs);

  /// Known hrefs of a calendar (excluding tombstones).
  Future<Map<String, String?>> etagsByHref(String calendarId);

  /// Replace every event of a calendar (ICS feeds have no per-item sync).
  Future<void> replaceEvents(String calendarId, List<CalendarEvent> events);

  Future<void> enqueue(CalendarSyncOp op);
  Future<List<CalendarSyncOp>> pendingOps({String? calendarId});
  Future<void> completeOp(String id);
  Future<void> failOp(String id, String error);
}
