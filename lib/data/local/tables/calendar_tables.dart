import 'package:drift/drift.dart';

/// Calendar sources (CalDAV collections, ICS feeds, local calendars).
@DataClassName('CalendarRow')
class Calendars extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// caldav | ics | local
  TextColumn get kind => text()();
  TextColumn get url => text().withDefault(const Constant(''))();
  TextColumn get username => text().nullable()();
  IntColumn get color => integer()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  BoolColumn get readOnly => boolean().withDefault(const Constant(false))();

  /// none | basic | googleOAuth
  TextColumn get authKind => text().withDefault(const Constant('none'))();
  TextColumn get googleEmail => text().nullable()();
  TextColumn get syncToken => text().nullable()();
  TextColumn get ctag => text().nullable()();
  TextColumn get etag => text().nullable()();
  IntColumn get lastSyncAt => integer().nullable()();
  TextColumn get lastError => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

/// One row per VEVENT (masters and RECURRENCE-ID overrides). Times are epoch ms UTC.
@DataClassName('CalendarEventRow')
class CalendarEvents extends Table {
  TextColumn get id => text()();
  TextColumn get calendarId => text().references(Calendars, #id, onDelete: KeyAction.cascade)();
  TextColumn get uid => text()();
  TextColumn get href => text().nullable()();
  TextColumn get etag => text().nullable()();
  TextColumn get summary => text().withDefault(const Constant(''))();
  TextColumn get description => text().nullable()();
  TextColumn get location => text().nullable()();
  IntColumn get startAt => integer()();
  IntColumn get endAt => integer()();
  BoolColumn get isAllDay => boolean().withDefault(const Constant(false))();
  BoolColumn get floating => boolean().withDefault(const Constant(false))();
  TextColumn get tzid => text().nullable()();
  TextColumn get rrule => text().nullable()();
  TextColumn get exdatesJson => text().withDefault(const Constant('[]'))();
  IntColumn get recurrenceId => integer().nullable()();
  TextColumn get status => text().nullable()();
  TextColumn get organizer => text().nullable()();
  TextColumn get attendeesJson => text().withDefault(const Constant('[]'))();
  TextColumn get alarmsJson => text().withDefault(const Constant('[]'))();
  TextColumn get rawIcs => text().nullable()();
  IntColumn get updatedAt => integer()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  BoolColumn get conflicted => boolean().withDefault(const Constant(false))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

/// Local edits waiting for PUT / DELETE on the server.
@DataClassName('CalendarSyncQueueRow')
class CalendarSyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get calendarId => text().references(Calendars, #id, onDelete: KeyAction.cascade)();
  TextColumn get uid => text()();

  /// create | update | delete
  TextColumn get kind => text()();
  TextColumn get href => text().nullable()();
  TextColumn get etag => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}
