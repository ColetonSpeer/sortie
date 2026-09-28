import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/core/clock.dart';
import 'package:sortie/data/calendar/google_oauth.dart';
import 'package:sortie/data/local/database.dart' show SortieDatabase;
import 'package:sortie/data/local/repositories/drift_calendar_repository.dart';
import 'package:sortie/data/local/repositories/drift_settings_repository.dart';
import 'package:sortie/domain/entities/calendar.dart';
import 'package:sortie/services/calendar/calendar_service.dart';
import 'package:sortie/services/calendar/tz.dart';
import 'package:sortie/services/import/calendar_import_sink.dart';

import '../../data/ai/fake_http_adapter.dart';
import '../../data/test_support.dart';

const _calUrl = 'https://dav.example.com/calendars/me/work/';

const _props = '''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav" xmlns:cs="http://calendarserver.org/ns/">
 <d:response><d:href>/calendars/me/work/</d:href><d:propstat><d:prop>
  <d:resourcetype><d:collection/><c:calendar/></d:resourcetype><d:displayname>Work</d:displayname><cs:getctag>CTAG</cs:getctag>
 </d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response>
</d:multistatus>''';

String _serverIcs(String uid, String summary) =>
    'BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nUID:$uid\r\nDTSTART:20260201T100000Z\r\nDTEND:20260201T110000Z\r\nSUMMARY:$summary\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n';

String _multistatus(String href, String etag, String ics) => '''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
 <d:response><d:href>$href</d:href><d:propstat><d:prop><d:getetag>$etag</d:getetag>
 <c:calendar-data>${ics.replaceAll('&', '&amp;').replaceAll('<', '&lt;')}</c:calendar-data></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response>
</d:multistatus>''';

void main() {
  late SortieDatabase db;
  late DriftCalendarRepository repo;
  late DriftSettingsRepository settings;
  late MemoryCredentialStore creds;
  late FakeHttpAdapter http;
  late CalendarService service;
  final clock = FakeClock(DateTime.utc(2026, 1, 15, 12));

  setUpAll(ensureTimeZonesLoaded);

  setUp(() async {
    db = SortieDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    repo = DriftCalendarRepository(db);
    settings = DriftSettingsRepository(db);
    creds = MemoryCredentialStore();
    http = FakeHttpAdapter();
    final links = GoogleAccountLinks(credentials: creds, client: () => service.googleClient());
    service = CalendarService(
      repo: repo,
      credentials: creds,
      settings: settings,
      clock: clock,
      google: links,
      dio: () => fakeDio(http),
      startupDelay: const Duration(days: 1),
    );
  });

  tearDown(() async {
    await service.drain();
    await service.stop();
    await db.close();
  });

  Future<CalendarSource> caldav() async {
    const s = CalendarSource(id: 'work', name: 'Work', kind: CalendarKind.caldav, url: _calUrl, username: 'me', authKind: CalendarAuthKind.basic);
    await repo.upsertSource(s);
    await creds.write(CalendarService.passwordKey('work'), 'pw');
    return s;
  }

  CalendarEvent draft(String cal, {String summary = 'Draft', String? rrule}) => CalendarEvent(
        id: '',
        calendarId: cal,
        uid: '',
        start: DateTime.utc(2026, 2, 1, 10),
        end: DateTime.utc(2026, 2, 1, 11),
        summary: summary,
        rrule: rrule,
        updatedAt: clock.now(),
      );

  test('createEvent on a CalDAV calendar PUTs the ICS and clears dirty with the server ETag', () async {
    await caldav();
    var putPath = '';
    var putBody = '';
    http.handler = (o) {
      switch (o.method) {
        case 'PUT':
          putPath = o.uri.path;
          putBody = o.data as String;
          return const FakeResponse(201, '', headers: {'etag': '"srv1"'});
        case 'PROPFIND':
          return const FakeResponse(207, _props);
        case 'REPORT':
          return FakeResponse(207, _multistatus(putPath, '"srv1"', putBody));
        default:
          throw StateError('unexpected ${o.method} ${o.uri}');
      }
    };
    final e = await service.createEvent(draft('work'));
    expect(e.uid, isNotEmpty);
    expect(e.dirty, isTrue);
    await service.drain();
    final stored = (await repo.event(e.id))!;
    expect(stored.etag, '"srv1"');
    expect(stored.href, '/calendars/me/work/${e.uid}.ics');
    expect(await repo.pendingOps(), isEmpty);
    final put = http.requests.firstWhere((r) => r.method == 'PUT');
    expect(put.headers['If-None-Match'], '*');
    expect(put.data as String, contains('UID:${e.uid}'));
    expect(put.data as String, contains('SUMMARY:Draft'));
  });

  test('412 on update keeps the server version and marks it conflicted', () async {
    await caldav();
    final existing = CalendarEvent(
      id: 'work|u1',
      calendarId: 'work',
      uid: 'u1',
      href: '/calendars/me/work/u1.ics',
      etag: '"old"',
      start: DateTime.utc(2026, 2, 1, 10),
      end: DateTime.utc(2026, 2, 1, 11),
      summary: 'Server v1',
      updatedAt: clock.now(),
    );
    await repo.upsertEvents([existing]);
    http.handler = (o) => switch (o.method) {
          'PUT' => const FakeResponse(412, ''),
          'GET' => FakeResponse(200, _serverIcs('u1', 'Server v2'), headers: {'etag': '"v2"'}),
          'PROPFIND' => const FakeResponse(207, _props),
          'REPORT' => FakeResponse(207, _multistatus('/calendars/me/work/u1.ics', '"v2"', _serverIcs('u1', 'Server v2'))),
          _ => throw StateError('unexpected ${o.method}'),
        };
    await service.updateEvent(existing.copyWith(summary: 'Local edit'));
    await service.drain();
    expect(await repo.pendingOps(), isEmpty);
    final stored = (await repo.eventsByUid('work', 'u1')).single;
    expect(stored.summary, 'Server v2');
    expect(stored.conflicted, isTrue);
    expect(stored.etag, '"v2"');
    expect(stored.dirty, isFalse);
    expect(http.requests.firstWhere((r) => r.method == 'PUT').headers['If-Match'], '"old"');
  });

  test('pull: calendar-query replaces stale items and removes hrefs no longer on the server', () async {
    final src = await caldav();
    await repo.upsertEvents([
      CalendarEvent(id: 'work|gone', calendarId: 'work', uid: 'gone', href: '/calendars/me/work/gone.ics', etag: '"g"',
          start: DateTime.utc(2026, 2, 1), end: DateTime.utc(2026, 2, 2), updatedAt: clock.now()),
    ]);
    http.handler = (o) => switch (o.method) {
          'PROPFIND' => const FakeResponse(207, _props),
          'REPORT' => FakeResponse(207, _multistatus('/calendars/me/work/n.ics', '"n1"', _serverIcs('n', 'New from server'))),
          _ => throw StateError('unexpected ${o.method}'),
        };
    await service.syncNow(calendarId: src.id);
    final events = await repo.events('work');
    expect(events.map((e) => e.summary), ['New from server']);
    final updated = (await repo.source('work'))!;
    expect(updated.ctag, 'CTAG');
    expect(updated.lastSyncAt, isNotNull);
    // Second sync with the same ctag makes no REPORT.
    final before = http.requests.length;
    await service.syncNow(calendarId: src.id);
    expect(http.requests.skip(before).map((r) => r.method), ['PROPFIND']);
  });

  test('local calendars: deleteOccurrence adds an EXDATE, updateOccurrence detaches a RECURRENCE-ID copy', () async {
    await repo.upsertSource(const CalendarSource(id: 'loc', name: 'Local', kind: CalendarKind.local));
    final e = await service.createEvent(draft('loc', summary: 'Standup', rrule: 'FREQ=DAILY;COUNT=5'));
    expect(e.dirty, isFalse);
    final occ = await service.watchOccurrences(DateTime.utc(2026, 2, 1), DateTime.utc(2026, 2, 10)).first;
    expect(occ, hasLength(5));

    await service.deleteOccurrence(occ[1]);
    final master = (await repo.eventsByUid('loc', e.uid)).single;
    expect(master.exdates, [DateTime.utc(2026, 2, 2, 10)]);

    final moved = await service.updateOccurrence(occ[2], master.copyWith(summary: 'Moved', start: DateTime.utc(2026, 2, 3, 15), end: DateTime.utc(2026, 2, 3, 16)));
    expect(moved.recurrenceId, DateTime.utc(2026, 2, 3, 10));
    expect(moved.rrule, isNull);
    final all = await repo.eventsByUid('loc', e.uid);
    expect(all, hasLength(2));
    final after = await service.watchOccurrences(DateTime.utc(2026, 2, 1), DateTime.utc(2026, 2, 10)).first;
    expect(after.map((o) => '${o.event.summary}@${o.start.day}T${o.start.hour}'), ['Standup@1T10', 'Moved@3T15', 'Standup@4T10', 'Standup@5T10']);
    expect(await repo.pendingOps(), isEmpty);

    await service.deleteEvent(master);
    expect(await repo.eventsByUid('loc', e.uid), isEmpty);
  });

  test('import sink maps Thunderbird caldav (Google + generic), ics and storage entries', () async {
    const entries = [
      ImportedCalendar(id: 'g1', name: 'Google main', type: 'caldav', uri: 'https://apidata.googleusercontent.com/caldav/v2/abc%40group.calendar.google.com/events/', username: 'coletonspeer@hky.com', color: '#33AA55'),
      ImportedCalendar(id: 'nc', name: 'Nextcloud', type: 'caldav', uri: 'https://cloud.example.com/remote.php/dav/calendars/me/personal/', username: 'me'),
      ImportedCalendar(id: 'feed', name: 'Holidays', type: 'ics', uri: 'https://example.com/h.ics', disabled: true),
      ImportedCalendar(id: 'home', name: 'Home', type: 'storage', uri: 'moz-storage-calendar://', color: '#FF0000'),
    ];
    await service.importCalendars(entries);
    await service.drain();
    final by = {for (final s in await repo.sources()) s.id: s};
    expect(by['g1']!.authKind, CalendarAuthKind.googleOAuth);
    expect(by['g1']!.googleEmail, 'coletonspeer@hky.com');
    expect(by['g1']!.enabled, isFalse, reason: 'disabled until the Google account is linked');
    expect(by['g1']!.color, 0xFF33AA55);
    expect(by['nc']!.authKind, CalendarAuthKind.basic);
    expect(by['nc']!.enabled, isTrue);
    expect(by['feed']!.kind, CalendarKind.ics);
    expect(by['feed']!.readOnly, isTrue);
    expect(by['feed']!.enabled, isFalse);
    expect(by['home']!.kind, CalendarKind.local);
    expect(by['home']!.color, 0xFFFF0000);

    // Signing in re-enables the Google calendar (link keyed by email).
    await creds.write(GoogleAccountLinks.credentialKey('coletonspeer@hky.com'), 'rt');
    await service.importCalendars([entries.first]);
    await service.drain();
    expect((await repo.source('g1'))!.enabled, isTrue);
  });

  test('pending imports parked by the default sink are consumed at start', () async {
    await PendingCalendarImportSink(settings).importCalendars(const [
      ImportedCalendar(id: 'p1', name: 'Parked', type: 'storage', uri: ''),
    ]);
    await service.consumePendingImports();
    await service.drain();
    expect((await repo.source('p1'))?.name, 'Parked');
    expect(await settings.getString(PendingCalendarImportSink.settingsKey), isNull);
  });

  test('CalendarSource JSON is stable and secret-free; upsertSources keeps local sync state', () async {
    const s = CalendarSource(
      id: 'x', name: 'X', kind: CalendarKind.caldav, url: _calUrl, username: 'me', color: 0xFF112233,
      authKind: CalendarAuthKind.googleOAuth, googleEmail: 'coletonspeer@hky.com', syncToken: 'tok', ctag: 'c', lastError: 'boom',
    );
    final j = s.toJson();
    expect(j.keys, isNot(contains('syncToken')));
    expect(j.keys, isNot(contains('ctag')));
    expect(j.keys, isNot(contains('lastError')));
    expect(jsonEncode(j), '{"id":"x","name":"X","kind":"caldav","url":"$_calUrl","username":"me","color":${0xFF112233},"enabled":true,"readOnly":false,"auth":"googleOAuth","googleEmail":"coletonspeer@hky.com","sortOrder":0}');
    final back = CalendarSource.fromJson(jsonDecode(jsonEncode(j)) as Map<String, dynamic>);
    expect(back.syncToken, isNull);

    await repo.upsertSource(s);
    await repo.upsertSources([back.copyWith(name: 'Renamed elsewhere', enabled: false)]);
    final merged = (await repo.source('x'))!;
    expect(merged.name, 'Renamed elsewhere');
    expect(merged.enabled, isFalse);
    expect(merged.syncToken, 'tok');
    expect(merged.ctag, 'c');
    expect(merged.lastError, 'boom');
  });

  test('Google calendars without a link report needsSignIn', () async {
    await repo.upsertSource(const CalendarSource(
        id: 'g', name: 'G', kind: CalendarKind.caldav, url: 'https://apidata.googleusercontent.com/caldav/v2/x/events/',
        authKind: CalendarAuthKind.googleOAuth, googleEmail: 'coletonspeer@hky.com'));
    await service.syncNow(calendarId: 'g');
    final status = await service.watchStatus().first;
    expect(status['g']!.state, CalendarSyncState.needsSignIn);
    expect(status['g']!.error, contains('coletonspeer@hky.com'));
    expect(http.requests, isEmpty);
  });
}
