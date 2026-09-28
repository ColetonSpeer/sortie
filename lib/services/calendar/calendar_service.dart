import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../../core/clock.dart';
import '../../data/calendar/caldav_client.dart';
import '../../data/calendar/google_oauth.dart';
import '../../domain/entities/calendar.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../import/calendar_import_sink.dart';
import 'calendar_sync.dart';
import 'ics_events.dart';
import 'recurrence.dart';
import 'reminder_scheduler.dart';

export 'calendar_sync.dart' show NeedsSignInException;

/// Owns calendar sources: periodic + manual sync, the local edit queue,
/// reminders, occurrence streams for the UI and the Thunderbird import sink.
class CalendarService implements CalendarImportSink {
  CalendarService({
    required CalendarRepository repo,
    required CredentialStore credentials,
    required SettingsRepository settings,
    required Clock clock,
    required this.google,
    Dio Function()? dio,
    Future<void> Function(EventOccurrence occurrence, int minutesBefore)? onReminder,
    this.startupDelay = const Duration(seconds: 3),
  })  : _repo = repo,
        _credentials = credentials,
        _settingsRepo = settings,
        _clock = clock,
        _dio = dio ?? Dio.new {
    _syncer = CalendarSyncer(repo: repo, clock: clock, dio: _dio, authFor: _authFor);
    _reminders = ReminderScheduler(clock: clock, onReminder: onReminder ?? (_, _) async {});
  }

  static final _log = Logger('calendar');
  static const settingsKey = 'calendar';
  static String passwordKey(String calendarId) => 'calendar.$calendarId.password';

  final CalendarRepository _repo;
  final CredentialStore _credentials;
  final SettingsRepository _settingsRepo;
  final Clock _clock;
  final GoogleAccountLinks google;
  final Dio Function() _dio;
  final Duration startupDelay;
  late final CalendarSyncer _syncer;
  late final ReminderScheduler _reminders;

  CalendarSettings _settings = const CalendarSettings();
  final _settingsCtrl = StreamController<CalendarSettings>.broadcast();
  final _status = <String, CalendarSyncStatus>{};
  final _statusCtrl = StreamController<Map<String, CalendarSyncStatus>>.broadcast();
  final _syncing = <String>{};
  final _inflight = <Future<void>>{};
  Timer? _timer;
  Timer? _startup;
  StreamSubscription<List<CalendarEvent>>? _eventsSub;
  List<CalendarEvent> _events = const [];
  bool _running = false;

  CalendarRepository get repo => _repo;
  CalendarSyncer get syncer => _syncer;

  // ------------------------------------------------------------ lifecycle

  Future<void> start() async {
    if (_running) return;
    _running = true;
    _settings = await loadSettings();
    _eventsSub = _repo.watchEvents().listen((list) {
      _events = list;
      _rescheduleReminders();
    });
    _startup = Timer(startupDelay, () async {
      await consumePendingImports();
      await syncAll();
    });
    _restartTimer();
  }

  Future<void> stop() async {
    _running = false;
    _timer?.cancel();
    _startup?.cancel();
    await drain();
    await _eventsSub?.cancel();
    _reminders.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!_running) return;
    _timer = Timer.periodic(_settings.syncInterval, (_) {
      unawaited(syncAll());
      _rescheduleReminders();
    });
  }

  // ------------------------------------------------------------- settings

  CalendarSettings get settings => _settings;

  Stream<CalendarSettings> watchSettings() async* {
    yield _settings;
    yield* _settingsCtrl.stream;
  }

  Future<CalendarSettings> loadSettings() async {
    final raw = await _settingsRepo.getString(settingsKey);
    if (raw == null || raw.isEmpty) return const CalendarSettings();
    try {
      return CalendarSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const CalendarSettings();
    }
  }

  Future<void> saveSettings(CalendarSettings s) async {
    _settings = s;
    await _settingsRepo.setString(settingsKey, jsonEncode(s.toJson()));
    _settingsCtrl.add(s);
    _restartTimer();
  }

  /// Google OAuth client with the user's override or the built-in credentials.
  GoogleOAuthClient googleClient() => GoogleOAuthClient(
        clientId: _settings.googleClientId.trim().isEmpty ? GoogleOAuthClient.defaultClientId : _settings.googleClientId.trim(),
        clientSecret: _settings.googleClientSecret.trim().isEmpty ? GoogleOAuthClient.defaultClientSecret : _settings.googleClientSecret.trim(),
        dio: _dio(),
      );

  // --------------------------------------------------------------- status

  Stream<Map<String, CalendarSyncStatus>> watchStatus() async* {
    yield Map.of(_status);
    yield* _statusCtrl.stream;
  }

  void _setStatus(String id, CalendarSyncState state, {String? error, DateTime? lastSyncAt}) {
    _status[id] = CalendarSyncStatus(calendarId: id, state: state, error: error, lastSyncAt: lastSyncAt ?? _status[id]?.lastSyncAt);
    _statusCtrl.add(Map.of(_status));
  }

  // ----------------------------------------------------------------- sync

  Future<CalDavAuth> _authFor(CalendarSource s) async {
    switch (s.authKind) {
      case CalendarAuthKind.none:
        return const NoAuth();
      case CalendarAuthKind.basic:
        final pw = await _credentials.read(passwordKey(s.id));
        if (pw == null) throw StateError('Password missing for ${s.name}');
        return BasicAuth(s.username ?? '', pw);
      case CalendarAuthKind.googleOAuth:
        final email = s.googleEmail ?? s.username;
        final link = email == null ? null : await google.link(email);
        if (link == null) throw NeedsSignInException(email);
        return BearerAuth(link);
    }
  }

  Future<void> syncAll() async {
    for (final s in await _repo.sources()) {
      if (s.enabled) await syncNow(calendarId: s.id);
    }
  }

  Future<void> syncNow({String? calendarId}) {
    if (calendarId == null) return syncAll();
    if (!_syncing.add(calendarId)) return Future.value();
    final f = _syncOne(calendarId);
    _inflight.add(f);
    f.whenComplete(() => _inflight.remove(f));
    return f;
  }

  /// Completes once no sync is running (used by tests and shutdown).
  Future<void> drain() async {
    while (_inflight.isNotEmpty) {
      await Future.wait(_inflight.toList());
    }
  }

  Future<void> _syncOne(String calendarId) async {
    try {
      final src = await _repo.source(calendarId);
      if (src == null) return;
      if (!src.enabled) {
        _setStatus(src.id, CalendarSyncState.disabled);
        return;
      }
      _setStatus(src.id, CalendarSyncState.syncing);
      try {
        final updated = await _syncer.sync(src);
        await _repo.upsertSource(updated);
        _setStatus(src.id, CalendarSyncState.idle, lastSyncAt: updated.lastSyncAt);
      } on NeedsSignInException catch (e) {
        _setStatus(src.id, CalendarSyncState.needsSignIn, error: e.toString());
      } on GoogleOAuthException catch (e) {
        _setStatus(src.id, e.invalidGrant ? CalendarSyncState.needsSignIn : CalendarSyncState.error, error: e.message);
        await _repo.upsertSource(src.copyWith(lastError: e.message));
      } catch (e) {
        _log.warning('sync failed for ${src.name}', e);
        final msg = e is CalDavException ? e.message : e.toString();
        await _repo.upsertSource(src.copyWith(lastError: msg));
        _setStatus(src.id, CalendarSyncState.error, error: msg);
      }
    } finally {
      _syncing.remove(calendarId);
    }
  }

  // ------------------------------------------------------------- sources

  Future<CalendarSource> addSource(CalendarSource s, {String? password}) async {
    if (password != null) await _credentials.write(passwordKey(s.id), password);
    await _repo.upsertSource(s);
    unawaited(syncNow(calendarId: s.id));
    return s;
  }

  Future<void> updateSource(CalendarSource s) async {
    await _repo.upsertSource(s);
    if (!s.enabled) _setStatus(s.id, CalendarSyncState.disabled);
  }

  Future<void> removeSource(String id) async {
    await _repo.deleteSource(id);
    await _credentials.delete(passwordKey(id));
    _status.remove(id);
    _statusCtrl.add(Map.of(_status));
  }

  /// Lists calendars behind a CalDAV URL for the "Add calendar" flow.
  Future<List<DavCalendar>> discoverCalDav(String url, {String? username, String? password}) {
    final auth = username == null || username.isEmpty ? const NoAuth() : BasicAuth(username, password ?? '');
    return CalDavClient(dio: _dio(), auth: auth).discover(Uri.parse(url.trim()));
  }

  /// Browser sign-in; re-enables calendars of that account that were waiting.
  Future<GoogleAccountLink> signInGoogle({String? loginHint}) async {
    final link = await google.signIn(loginHint: loginHint);
    for (final s in await _repo.sources()) {
      if (s.authKind == CalendarAuthKind.googleOAuth && (s.googleEmail ?? '').toLowerCase() == link.email) {
        await _repo.upsertSource(s.copyWith(enabled: true, clearError: true));
        unawaited(syncNow(calendarId: s.id));
      }
    }
    return link;
  }

  Future<List<DavCalendar>> listGoogleCalendars(GoogleAccountLink link) =>
      GoogleCalendarDiscovery.listCalendars(_dio(), link, link.email);

  Future<void> addGoogleCalendars(GoogleAccountLink link, Iterable<DavCalendar> picked) async {
    final existing = (await _repo.sources()).map((s) => s.url).toSet();
    for (final c in picked) {
      if (existing.contains(c.href.toString())) continue;
      await addSource(CalendarSource(
        id: const Uuid().v4(),
        name: c.displayName,
        kind: CalendarKind.caldav,
        url: c.href.toString(),
        username: link.email,
        googleEmail: link.email,
        authKind: CalendarAuthKind.googleOAuth,
        color: c.color ?? 0xFF3F51B5,
      ));
    }
  }

  // --------------------------------------------------------------- events

  Stream<List<EventOccurrence>> watchOccurrences(DateTime from, DateTime to) =>
      _repo.watchEvents(from: from, to: to).map((evs) => occurrences(evs, from, to));

  Future<CalendarEvent> createEvent(CalendarEvent draft) async {
    final src = await _repo.source(draft.calendarId);
    if (src == null || !src.isWritable) throw StateError('Calendar is read-only');
    final uid = draft.uid.isEmpty ? const Uuid().v4() : draft.uid;
    final e = draft.copyWith(
      id: calendarEventId(draft.calendarId, uid, null),
      uid: uid,
      updatedAt: _clock.now().toUtc(),
      dirty: src.kind == CalendarKind.caldav,
      clearHref: true,
      clearEtag: true,
    );
    await _repo.upsertEvents([e]);
    await _queue(src, e.uid, CalendarSyncOpKind.create);
    return e;
  }

  Future<void> updateEvent(CalendarEvent e) async {
    final src = await _repo.source(e.calendarId);
    if (src == null || !src.isWritable) throw StateError('Calendar is read-only');
    final u = e.copyWith(updatedAt: _clock.now().toUtc(), dirty: src.kind == CalendarKind.caldav, conflicted: false);
    await _repo.upsertEvents([u]);
    await _queue(src, u.uid, u.href == null ? CalendarSyncOpKind.create : CalendarSyncOpKind.update, href: u.href, etag: u.etag);
  }

  /// Deletes the whole series (or a single non-recurring event).
  Future<void> deleteEvent(CalendarEvent e) async {
    final src = await _repo.source(e.calendarId);
    if (src == null || !src.isWritable) throw StateError('Calendar is read-only');
    final all = await _repo.eventsByUid(e.calendarId, e.uid);
    if (src.kind != CalendarKind.caldav || e.href == null) {
      await _repo.deleteEvents(all.map((x) => x.id).toList());
      return;
    }
    await _repo.upsertEvents([for (final x in all) x.copyWith(deleted: true, updatedAt: _clock.now().toUtc())]);
    await _queue(src, e.uid, CalendarSyncOpKind.delete, href: e.href, etag: e.etag);
  }

  /// Removes one occurrence: EXDATE on the master (and drops an override).
  Future<void> deleteOccurrence(EventOccurrence o) async {
    final e = o.event;
    if (!e.isRecurring && !e.isOverride) return deleteEvent(e);
    final all = await _repo.eventsByUid(e.calendarId, e.uid);
    final master = all.where((x) => !x.isOverride).firstOrNull;
    final instance = e.isOverride ? e.recurrenceId! : o.start;
    if (e.isOverride) await _repo.deleteEvents([e.id]);
    if (master == null) return;
    await updateEvent(master.copyWith(exdates: [...master.exdates, instance]));
  }

  /// Edits one occurrence: EXDATE on the master + detached RECURRENCE-ID copy.
  Future<CalendarEvent> updateOccurrence(EventOccurrence o, CalendarEvent edited) async {
    final e = o.event;
    if (e.isOverride) {
      final u = edited.copyWith(id: e.id, uid: e.uid, recurrenceId: e.recurrenceId, clearRrule: true, href: e.href, etag: e.etag);
      await updateEvent(u);
      return u;
    }
    if (!e.isRecurring) {
      await updateEvent(edited);
      return edited;
    }
    // Re-read: the occurrence may carry a stale snapshot of the master.
    final current = (await _repo.eventsByUid(e.calendarId, e.uid)).where((x) => !x.isOverride).firstOrNull ?? e;
    final master = current.copyWith(exdates: [...current.exdates, o.start]);
    final override = edited.copyWith(
      id: calendarEventId(e.calendarId, e.uid, o.start),
      uid: e.uid,
      recurrenceId: o.start,
      clearRrule: true,
      exdates: const [],
      href: e.href,
      etag: e.etag,
      updatedAt: _clock.now().toUtc(),
      dirty: true,
    );
    await _repo.upsertEvents([override]);
    await updateEvent(master);
    return override;
  }

  Future<void> _queue(CalendarSource src, String uid, CalendarSyncOpKind kind, {String? href, String? etag}) async {
    if (src.kind != CalendarKind.caldav) return;
    await _repo.enqueue(CalendarSyncOp(
      id: '${src.id}|$uid|${kind.name}',
      calendarId: src.id,
      uid: uid,
      kind: kind,
      href: href,
      etag: etag,
      createdAt: _clock.now().toUtc(),
    ));
    unawaited(syncNow(calendarId: src.id));
  }

  // ------------------------------------------------------------ reminders

  void _rescheduleReminders() {
    final now = _clock.now().toUtc();
    _reminders.reschedule(occurrences(_events, now.subtract(const Duration(hours: 1)), now.add(_reminders.horizon)));
  }

  // --------------------------------------------------------------- import

  @override
  Future<void> importCalendars(List<ImportedCalendar> calendars) async {
    final sources = <CalendarSource>[];
    for (final c in calendars) {
      final s = await sourceFromImport(c);
      if (s != null) sources.add(s);
    }
    await _repo.upsertSources(sources);
    for (final s in sources) {
      if (s.enabled) unawaited(syncNow(calendarId: s.id));
    }
  }

  /// Thunderbird entry -> source. Google CalDAV entries need a sign-in and
  /// stay disabled until the matching account is linked on this device.
  Future<CalendarSource?> sourceFromImport(ImportedCalendar c) async {
    final color = parseCalendarColor(c.color) ?? 0xFF3F51B5;
    switch (c.type) {
      case 'caldav':
        final uri = Uri.tryParse(c.uri);
        if (uri == null) return null;
        final isGoogle = uri.host == GoogleCalendarDiscovery.host;
        final email = isGoogle ? c.username?.toLowerCase() : null;
        final linked = email != null && await google.link(email) != null;
        return CalendarSource(
          id: c.id,
          name: c.name,
          kind: CalendarKind.caldav,
          url: c.uri,
          username: c.username,
          color: color,
          enabled: !c.disabled && (!isGoogle || linked),
          readOnly: c.readOnly,
          authKind: isGoogle ? CalendarAuthKind.googleOAuth : CalendarAuthKind.basic,
          googleEmail: email,
        );
      case 'ics':
        return CalendarSource(id: c.id, name: c.name, kind: CalendarKind.ics, url: c.uri, color: color, enabled: !c.disabled, readOnly: true);
      default:
        return CalendarSource(id: c.id, name: c.name, kind: CalendarKind.local, color: color, enabled: !c.disabled, readOnly: c.readOnly);
    }
  }

  /// Picks up calendars parked by [PendingCalendarImportSink] before we existed.
  Future<void> consumePendingImports() async {
    final pending = await PendingCalendarImportSink(_settingsRepo).pending();
    if (pending.isEmpty) return;
    await importCalendars(pending);
    await _settingsRepo.setString(PendingCalendarImportSink.settingsKey, null);
    _log.info('imported ${pending.length} pending calendars');
  }
}
