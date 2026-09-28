import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/data/calendar/caldav_client.dart';

import '../ai/fake_http_adapter.dart';

const _principal = '''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
 <d:response><d:href>/principals/users/me/</d:href>
  <d:propstat><d:prop>
   <d:resourcetype><d:principal/></d:resourcetype>
   <d:current-user-principal><d:href>/principals/users/me/</d:href></d:current-user-principal>
   <c:calendar-home-set><d:href>/calendars/me/</d:href></c:calendar-home-set>
  </d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
 </d:response>
</d:multistatus>''';

const _home = '''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav" xmlns:cs="http://calendarserver.org/ns/" xmlns:a="http://apple.com/ns/ical/">
 <d:response><d:href>/calendars/me/</d:href>
  <d:propstat><d:prop><d:resourcetype><d:collection/></d:resourcetype><d:displayname>me</d:displayname></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
 </d:response>
 <d:response><d:href>/calendars/me/work/</d:href>
  <d:propstat><d:prop>
   <d:resourcetype><d:collection/><c:calendar/></d:resourcetype>
   <d:displayname>Work</d:displayname>
   <a:calendar-color>#FF5733FF</a:calendar-color>
   <cs:getctag>ctag-1</cs:getctag>
   <d:sync-token>http://example.com/sync/5</d:sync-token>
   <c:supported-calendar-component-set><c:comp name="VEVENT"/></c:supported-calendar-component-set>
  </d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
 </d:response>
 <d:response><d:href>/calendars/me/tasks/</d:href>
  <d:propstat><d:prop>
   <d:resourcetype><d:collection/><c:calendar/></d:resourcetype>
   <d:displayname>Tasks</d:displayname>
   <c:supported-calendar-component-set><c:comp name="VTODO"/></c:supported-calendar-component-set>
  </d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
 </d:response>
</d:multistatus>''';

const _query = '''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
 <d:response><d:href>/calendars/me/work/a.ics</d:href>
  <d:propstat><d:prop><d:getetag>"e1"</d:getetag>
   <c:calendar-data>BEGIN:VCALENDAR
BEGIN:VEVENT
UID:a
DTSTART:20260101T100000Z
DTEND:20260101T110000Z
SUMMARY:A &amp; B
END:VEVENT
END:VCALENDAR</c:calendar-data></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
 </d:response>
 <d:response><d:href>/calendars/me/work/b.ics</d:href>
  <d:propstat><d:prop><d:getetag>"e2"</d:getetag></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
 </d:response>
</d:multistatus>''';

const _sync = '''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
 <d:response><d:href>/calendars/me/work/a.ics</d:href>
  <d:propstat><d:prop><d:getetag>"e9"</d:getetag><c:calendar-data>BEGIN:VCALENDAR
BEGIN:VEVENT
UID:a
DTSTART:20260101T100000Z
DTEND:20260101T110000Z
END:VEVENT
END:VCALENDAR</c:calendar-data></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
 </d:response>
 <d:response><d:href>/calendars/me/work/gone.ics</d:href><d:status>HTTP/1.1 404 Not Found</d:status></d:response>
 <d:sync-token>http://example.com/sync/6</d:sync-token>
</d:multistatus>''';

void main() {
  late FakeHttpAdapter http;
  late CalDavClient client;

  setUp(() {
    http = FakeHttpAdapter();
    client = CalDavClient(dio: fakeDio(http), auth: const BasicAuth('me', 'pw'));
  });

  test('discover: principal -> calendar-home-set -> event calendars with colour/ctag/sync-token', () async {
    http.handler = (o) {
      expect(o.method, 'PROPFIND');
      expect(o.headers['Authorization'], startsWith('Basic '));
      if (o.uri.path == '/principals/users/me/') return const FakeResponse(207, _principal);
      if (o.uri.path == '/calendars/me/') {
        expect(o.headers['Depth'], '1');
        return const FakeResponse(207, _home);
      }
      throw StateError('unexpected ${o.uri}');
    };
    final cals = await client.discover(Uri.parse('https://dav.example.com/principals/users/me/'));
    expect(cals, hasLength(1)); // VTODO-only calendar filtered out
    final c = cals.single;
    expect(c.href.toString(), 'https://dav.example.com/calendars/me/work/');
    expect(c.displayName, 'Work');
    expect(c.color, 0xFFFF5733);
    expect(c.ctag, 'ctag-1');
    expect(c.syncToken, 'http://example.com/sync/5');
  });

  test('calendar-query parses items with and without calendar-data; multiget fills the rest', () async {
    http.handler = (o) {
      expect(o.method, 'REPORT');
      final body = o.data as String;
      if (body.contains('calendar-multiget')) {
        expect(body, contains('<d:href>/calendars/me/work/b.ics</d:href>'));
        return const FakeResponse(207, _query);
      }
      expect(body, contains('time-range start="2025'));
      expect(body, contains('<c:comp-filter name="VEVENT">'));
      return const FakeResponse(207, _query);
    };
    final items = await client.calendarQuery(Uri.parse('https://dav.example.com/calendars/me/work/'), now: DateTime.utc(2026, 1, 1));
    expect(items.map((i) => i.href), ['/calendars/me/work/a.ics', '/calendars/me/work/b.ics']);
    expect(items[0].etag, '"e1"');
    expect(items[0].data, contains('SUMMARY:A & B'));
    expect(items[1].data, isNull);
    final got = await client.multiget(Uri.parse('https://dav.example.com/calendars/me/work/'), ['/calendars/me/work/b.ics']);
    expect(got, hasLength(2));
  });

  test('sync-collection returns changed, deleted and the new token', () async {
    http.handler = (o) {
      expect(o.data as String, contains('<d:sync-token>http://example.com/sync/5</d:sync-token>'));
      return const FakeResponse(207, _sync);
    };
    final r = await client.syncCollection(Uri.parse('https://dav.example.com/calendars/me/work/'), 'http://example.com/sync/5');
    expect(r.changed.single.etag, '"e9"');
    expect(r.deleted, ['/calendars/me/work/gone.ics']);
    expect(r.token, 'http://example.com/sync/6');
  });

  test('PUT sends If-Match / If-None-Match and returns the ETag; 412 raises a conflict', () async {
    http.queue.add(const FakeResponse(201, '', headers: {'etag': '"new"'}));
    final etag = await client.put(Uri.parse('https://dav.example.com/calendars/me/work/x.ics'), 'BEGIN:VCALENDAR\r\nEND:VCALENDAR\r\n');
    expect(etag, '"new"');
    expect(http.requests.last.method, 'PUT');
    expect(http.requests.last.headers['If-None-Match'], '*');
    expect(http.requests.last.headers['content-type'], contains('text/calendar'));

    http.queue.add(const FakeResponse(412, ''));
    await expectLater(
      client.put(Uri.parse('https://dav.example.com/calendars/me/work/x.ics'), 'x', etag: '"old"'),
      throwsA(isA<CalDavConflictException>()),
    );
    expect(http.requests.last.headers['If-Match'], '"old"');

    http.queue.add(const FakeResponse(204, ''));
    await client.delete(Uri.parse('https://dav.example.com/calendars/me/work/x.ics'), etag: '"new"');
    expect(http.requests.last.method, 'DELETE');
    expect(http.requests.last.headers['If-Match'], '"new"');
  });

  test('bearer auth retries once with a refreshed token after 401', () async {
    final tokens = _Tokens();
    final c = CalDavClient(dio: fakeDio(http), auth: BearerAuth(tokens));
    http.queue.add(const FakeResponse(401, ''));
    http.queue.add(const FakeResponse(207, _principal));
    await c.calendarProps(Uri.parse('https://dav.example.com/principals/users/me/'));
    expect(http.requests[0].headers['Authorization'], 'Bearer t1');
    expect(http.requests[1].headers['Authorization'], 'Bearer t2');
    expect(tokens.refreshes, 1);

    http.queue.add(const FakeResponse(403, ''));
    await expectLater(c.calendarProps(Uri.parse('https://dav.example.com/x/')), throwsA(isA<CalDavAuthException>()));
  });

  test('parseCalendarColor handles #RRGGBB and #RRGGBBAA', () {
    expect(parseCalendarColor('#3F51B5'), 0xFF3F51B5);
    expect(parseCalendarColor('#3F51B580'), 0x803F51B5);
    expect(parseCalendarColor('nope'), isNull);
  });
}

class _Tokens implements TokenProvider {
  int refreshes = 0;
  @override
  Future<String> accessToken({bool forceRefresh = false}) async {
    if (forceRefresh) refreshes++;
    return refreshes == 0 ? 't1' : 't2';
  }
}
