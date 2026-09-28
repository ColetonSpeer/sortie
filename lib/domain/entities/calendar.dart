/// Calendar domain entities. [CalendarSource] JSON is shared between devices
/// through the control-folder journal, so its keys are stable and it never
/// contains secrets (tokens, passwords) or per-device sync state.
library;

enum CalendarKind { caldav, ics, local }

enum CalendarAuthKind { none, basic, googleOAuth }

/// A calendar the user subscribed to: a CalDAV collection, an ICS feed or a
/// device-only local calendar.
class CalendarSource {
  const CalendarSource({
    required this.id,
    required this.name,
    required this.kind,
    this.url = '',
    this.username,
    this.color = 0xFF3F51B5,
    this.enabled = true,
    this.readOnly = false,
    this.authKind = CalendarAuthKind.none,
    this.googleEmail,
    this.syncToken,
    this.ctag,
    this.etag,
    this.lastSyncAt,
    this.lastError,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final CalendarKind kind;

  /// Collection URL (caldav), feed URL (ics) or empty (local).
  final String url;
  final String? username;

  /// ARGB.
  final int color;
  final bool enabled;
  final bool readOnly;
  final CalendarAuthKind authKind;

  /// Google account that owns this calendar; key of the shared refresh token.
  final String? googleEmail;

  // ----- device-local sync state (never shared) -----
  final String? syncToken;
  final String? ctag;

  /// ETag of the last ICS feed fetch.
  final String? etag;
  final DateTime? lastSyncAt;
  final String? lastError;
  final int sortOrder;

  bool get isWritable => !readOnly && kind != CalendarKind.ics;
  bool get needsGoogleSignIn => authKind == CalendarAuthKind.googleOAuth;

  CalendarSource copyWith({
    String? name,
    CalendarKind? kind,
    String? url,
    String? username,
    int? color,
    bool? enabled,
    bool? readOnly,
    CalendarAuthKind? authKind,
    String? googleEmail,
    String? syncToken,
    bool clearSyncToken = false,
    String? ctag,
    String? etag,
    DateTime? lastSyncAt,
    String? lastError,
    bool clearError = false,
    int? sortOrder,
  }) =>
      CalendarSource(
        id: id,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        url: url ?? this.url,
        username: username ?? this.username,
        color: color ?? this.color,
        enabled: enabled ?? this.enabled,
        readOnly: readOnly ?? this.readOnly,
        authKind: authKind ?? this.authKind,
        googleEmail: googleEmail ?? this.googleEmail,
        syncToken: clearSyncToken ? null : (syncToken ?? this.syncToken),
        ctag: ctag ?? this.ctag,
        etag: etag ?? this.etag,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        lastError: clearError ? null : (lastError ?? this.lastError),
        sortOrder: sortOrder ?? this.sortOrder,
      );

  /// Shareable description: no secrets, no sync tokens.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'url': url,
        'username': username,
        'color': color,
        'enabled': enabled,
        'readOnly': readOnly,
        'auth': authKind.name,
        'googleEmail': googleEmail,
        'sortOrder': sortOrder,
      };

  static CalendarSource fromJson(Map<String, dynamic> j) => CalendarSource(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        kind: CalendarKind.values.byName((j['kind'] as String?) ?? 'local'),
        url: (j['url'] as String?) ?? '',
        username: j['username'] as String?,
        color: (j['color'] as int?) ?? 0xFF3F51B5,
        enabled: (j['enabled'] as bool?) ?? true,
        readOnly: (j['readOnly'] as bool?) ?? false,
        authKind: CalendarAuthKind.values.byName((j['auth'] as String?) ?? 'none'),
        googleEmail: j['googleEmail'] as String?,
        sortOrder: (j['sortOrder'] as int?) ?? 0,
      );
}

enum AttendeeStatus { needsAction, accepted, declined, tentative, delegated }

class Attendee {
  const Attendee({required this.email, this.name, this.status = AttendeeStatus.needsAction});
  final String email;
  final String? name;
  final AttendeeStatus status;

  Map<String, dynamic> toJson() => {'email': email, 'name': name, 'status': status.name};
  static Attendee fromJson(Map<String, dynamic> j) => Attendee(
        email: j['email'] as String,
        name: j['name'] as String?,
        status: AttendeeStatus.values.byName((j['status'] as String?) ?? 'needsAction'),
      );
}

/// One VEVENT (master or a detached RECURRENCE-ID override). Times are UTC;
/// [tzid] remembers the wall-clock zone for recurrence expansion and export.
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.calendarId,
    required this.uid,
    required this.start,
    required this.end,
    this.href,
    this.etag,
    this.summary = '',
    this.description,
    this.location,
    this.isAllDay = false,
    this.floating = false,
    this.tzid,
    this.rrule,
    this.exdates = const [],
    this.recurrenceId,
    this.status,
    this.organizer,
    this.attendees = const [],
    this.alarms = const [],
    this.rawIcs,
    required this.updatedAt,
    this.dirty = false,
    this.conflicted = false,
    this.deleted = false,
  });

  final String id;
  final String calendarId;
  final String uid;
  final String? href;
  final String? etag;
  final String summary;
  final String? description;
  final String? location;

  /// UTC instant (for all-day events: 00:00 UTC of the date).
  final DateTime start;
  final DateTime end;
  final bool isAllDay;

  /// DTSTART had neither TZID nor Z; wall time was taken as device local.
  final bool floating;
  final String? tzid;

  /// Raw RRULE value (without the `RRULE:` prefix), null when not recurring.
  final String? rrule;
  final List<DateTime> exdates;

  /// Set on detached overrides: the UTC start of the occurrence replaced.
  final DateTime? recurrenceId;
  final String? status;
  final String? organizer;
  final List<Attendee> attendees;

  /// Reminder offsets in minutes before start.
  final List<int> alarms;
  final String? rawIcs;
  final DateTime updatedAt;

  /// Local edit not yet uploaded.
  final bool dirty;

  /// A local edit lost against a newer server version.
  final bool conflicted;

  /// Locally deleted, DELETE not yet confirmed by the server.
  final bool deleted;

  bool get isRecurring => rrule != null && rrule!.isNotEmpty;
  bool get isOverride => recurrenceId != null;
  Duration get duration => end.difference(start);

  CalendarEvent copyWith({
    String? calendarId,
    String? uid,
    String? href,
    bool clearHref = false,
    String? etag,
    bool clearEtag = false,
    String? summary,
    String? description,
    String? location,
    DateTime? start,
    DateTime? end,
    bool? isAllDay,
    bool? floating,
    String? tzid,
    bool clearTzid = false,
    String? rrule,
    bool clearRrule = false,
    List<DateTime>? exdates,
    DateTime? recurrenceId,
    String? status,
    String? organizer,
    List<Attendee>? attendees,
    List<int>? alarms,
    String? rawIcs,
    DateTime? updatedAt,
    bool? dirty,
    bool? conflicted,
    bool? deleted,
    String? id,
  }) =>
      CalendarEvent(
        id: id ?? this.id,
        calendarId: calendarId ?? this.calendarId,
        uid: uid ?? this.uid,
        href: clearHref ? null : (href ?? this.href),
        etag: clearEtag ? null : (etag ?? this.etag),
        summary: summary ?? this.summary,
        description: description ?? this.description,
        location: location ?? this.location,
        start: start ?? this.start,
        end: end ?? this.end,
        isAllDay: isAllDay ?? this.isAllDay,
        floating: floating ?? this.floating,
        tzid: clearTzid ? null : (tzid ?? this.tzid),
        rrule: clearRrule ? null : (rrule ?? this.rrule),
        exdates: exdates ?? this.exdates,
        recurrenceId: recurrenceId ?? this.recurrenceId,
        status: status ?? this.status,
        organizer: organizer ?? this.organizer,
        attendees: attendees ?? this.attendees,
        alarms: alarms ?? this.alarms,
        rawIcs: rawIcs ?? this.rawIcs,
        updatedAt: updatedAt ?? this.updatedAt,
        dirty: dirty ?? this.dirty,
        conflicted: conflicted ?? this.conflicted,
        deleted: deleted ?? this.deleted,
      );
}

/// One expanded instance of an event, for display.
class EventOccurrence {
  const EventOccurrence({required this.event, required this.start, required this.end});
  final CalendarEvent event;

  /// UTC.
  final DateTime start;
  final DateTime end;

  bool get isAllDay => event.isAllDay;

  /// Stable key: event id + occurrence start.
  String get key => '${event.id}@${start.millisecondsSinceEpoch}';
}

enum CalendarSyncOpKind { create, update, delete }

/// Local change waiting to be pushed to a CalDAV server.
class CalendarSyncOp {
  const CalendarSyncOp({
    required this.id,
    required this.calendarId,
    required this.uid,
    required this.kind,
    this.href,
    this.etag,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
  });
  final String id;
  final String calendarId;
  final String uid;
  final CalendarSyncOpKind kind;
  final String? href;
  final String? etag;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;
}

enum CalendarSyncState { idle, syncing, error, needsSignIn, disabled }

class CalendarSyncStatus {
  const CalendarSyncStatus({required this.calendarId, required this.state, this.error, this.lastSyncAt});
  final String calendarId;
  final CalendarSyncState state;
  final String? error;
  final DateTime? lastSyncAt;
}

/// Device-local calendar preferences (settings key `calendar`).
class CalendarSettings {
  const CalendarSettings({
    this.defaultReminderMinutes = 10,
    this.weekStart = DateTime.monday,
    this.syncIntervalMinutes = 15,
    this.googleClientId = '',
    this.googleClientSecret = '',
  });

  final int defaultReminderMinutes;

  /// 1 = Monday … 7 = Sunday (DateTime constants).
  final int weekStart;
  final int syncIntervalMinutes;

  /// Empty = use the built-in public installed-app credentials.
  final String googleClientId;
  final String googleClientSecret;

  Duration get syncInterval => Duration(minutes: syncIntervalMinutes < 1 ? 1 : syncIntervalMinutes);

  CalendarSettings copyWith({
    int? defaultReminderMinutes,
    int? weekStart,
    int? syncIntervalMinutes,
    String? googleClientId,
    String? googleClientSecret,
  }) =>
      CalendarSettings(
        defaultReminderMinutes: defaultReminderMinutes ?? this.defaultReminderMinutes,
        weekStart: weekStart ?? this.weekStart,
        syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
        googleClientId: googleClientId ?? this.googleClientId,
        googleClientSecret: googleClientSecret ?? this.googleClientSecret,
      );

  Map<String, dynamic> toJson() => {
        'reminder': defaultReminderMinutes,
        'weekStart': weekStart,
        'syncMinutes': syncIntervalMinutes,
        'googleClientId': googleClientId,
        'googleClientSecret': googleClientSecret,
      };

  static CalendarSettings fromJson(Map<String, dynamic> j) => CalendarSettings(
        defaultReminderMinutes: (j['reminder'] as int?) ?? 10,
        weekStart: (j['weekStart'] as int?) ?? DateTime.monday,
        syncIntervalMinutes: (j['syncMinutes'] as int?) ?? 15,
        googleClientId: (j['googleClientId'] as String?) ?? '',
        googleClientSecret: (j['googleClientSecret'] as String?) ?? '',
      );
}
