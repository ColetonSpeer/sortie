import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

/// Supplies OAuth bearer tokens; `forceRefresh` after a 401.
abstract class TokenProvider {
  Future<String> accessToken({bool forceRefresh = false});
}

sealed class CalDavAuth {
  const CalDavAuth();
}

class NoAuth extends CalDavAuth {
  const NoAuth();
}

class BasicAuth extends CalDavAuth {
  const BasicAuth(this.username, this.password);
  final String username;
  final String password;
}

class BearerAuth extends CalDavAuth {
  const BearerAuth(this.tokens);
  final TokenProvider tokens;
}

class CalDavException implements Exception {
  const CalDavException(this.status, this.message);
  final int status;
  final String message;
  @override
  String toString() => 'CalDAV $status: $message';
}

/// 412 Precondition Failed: the server copy changed under us.
class CalDavConflictException extends CalDavException {
  const CalDavConflictException(String href) : super(412, 'conflict on $href');
}

class CalDavAuthException extends CalDavException {
  const CalDavAuthException(super.status, super.message);
}

class DavCalendar {
  const DavCalendar({required this.href, required this.displayName, this.color, this.ctag, this.syncToken});
  final Uri href;
  final String displayName;

  /// ARGB, from `apple:calendar-color` (#RRGGBB or #RRGGBBAA).
  final int? color;
  final String? ctag;
  final String? syncToken;
}

class DavItem {
  const DavItem({required this.href, this.etag, this.data});
  final String href;
  final String? etag;
  final String? data;
}

class SyncCollectionResult {
  const SyncCollectionResult({required this.changed, required this.deleted, this.token});
  final List<DavItem> changed;
  final List<String> deleted;
  final String? token;
}

const _davNs = 'DAV:';
const _calNs = 'urn:ietf:params:xml:ns:caldav';
const _csNs = 'http://calendarserver.org/ns/';
const _appleNs = 'http://apple.com/ns/ical/';

const _propfindCalendar = '<?xml version="1.0" encoding="utf-8"?>'
    '<d:propfind xmlns:d="$_davNs" xmlns:c="$_calNs" xmlns:cs="$_csNs" xmlns:a="$_appleNs">'
    '<d:prop><d:resourcetype/><d:displayname/><a:calendar-color/><cs:getctag/><d:sync-token/>'
    '<c:supported-calendar-component-set/><d:current-user-principal/><c:calendar-home-set/></d:prop>'
    '</d:propfind>';

/// Minimal CalDAV (RFC 4791 / 6578) client over Dio.
class CalDavClient {
  CalDavClient({required Dio dio, required CalDavAuth auth}) : _dio = dio, _auth = auth;
  final Dio _dio;
  final CalDavAuth _auth;

  /// Time window used by [calendarQuery] when the caller passes none.
  static Duration pastWindow = const Duration(days: 183);
  static Duration futureWindow = const Duration(days: 548);

  Future<Response<String>> _request(
    String method,
    Uri url, {
    String? body,
    Map<String, String> headers = const {},
    String? contentType,
    bool retryAuth = true,
  }) async {
    final h = <String, String>{...headers};
    switch (_auth) {
      case NoAuth():
        break;
      case BasicAuth(username: final u, password: final p):
        h['Authorization'] = 'Basic ${base64Encode(utf8.encode('$u:$p'))}';
      case BearerAuth(tokens: final t):
        h['Authorization'] = 'Bearer ${await t.accessToken()}';
    }
    final r = await _dio.requestUri<String>(
      url,
      data: body,
      options: Options(
        method: method,
        headers: h,
        contentType: contentType ?? (body == null ? null : 'application/xml; charset=utf-8'),
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
        followRedirects: false,
      ),
    );
    final status = r.statusCode ?? 0;
    if (status == 401 && _auth is BearerAuth && retryAuth) {
      await _auth.tokens.accessToken(forceRefresh: true);
      return _request(method, url, body: body, headers: headers, contentType: contentType, retryAuth: false);
    }
    if (status == 401 || status == 403) throw CalDavAuthException(status, 'authentication failed for $url');
    if (status == 412) throw CalDavConflictException(url.toString());
    if (status >= 400 && status != 404) throw CalDavException(status, _errorText(r.data) ?? url.toString());
    return r;
  }

  static String? _errorText(String? body) {
    if (body == null || body.isEmpty) return null;
    final t = body.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.isEmpty ? null : (t.length > 200 ? t.substring(0, 200) : t);
  }

  Future<List<DavResponse>> _propfind(Uri url, {int depth = 0, String body = _propfindCalendar}) async {
    final r = await _request('PROPFIND', url, body: body, headers: {'Depth': '$depth'});
    if (r.statusCode == 404) throw CalDavException(404, 'not found: $url');
    if (r.statusCode! >= 300) throw CalDavException(r.statusCode!, 'PROPFIND $url');
    return parseMultistatus(r.data ?? '');
  }

  /// Finds every event calendar reachable from [base]: a calendar URL itself,
  /// a principal URL, a calendar-home, or a bare host (via `.well-known/caldav`).
  Future<List<DavCalendar>> discover(Uri base) async {
    var url = base;
    List<DavResponse> rs;
    try {
      rs = await _propfind(url);
    } on CalDavException catch (e) {
      if (e.status != 404 || url.path.length > 1) rethrow;
      url = await _wellKnown(base);
      rs = await _propfind(url);
    }
    final self = rs.firstOrNull;
    if (self != null && self.isCalendar) return [_calendar(url, self)];

    var principal = self?.props['current-user-principal'];
    var home = self?.props['calendar-home-set'];
    if (home == null) {
      if (principal == null) {
        // Bare host: try the well-known redirect target for the principal.
        final wk = await _wellKnown(url);
        final r2 = await _propfind(wk);
        principal = r2.firstOrNull?.props['current-user-principal'];
        home = r2.firstOrNull?.props['calendar-home-set'];
        if (r2.firstOrNull?.isCalendar ?? false) return [_calendar(wk, r2.first)];
      }
      if (home == null && principal != null) {
        final pr = await _propfind(url.resolve(principal));
        home = pr.firstOrNull?.props['calendar-home-set'];
      }
    }
    if (home == null) throw const CalDavException(0, 'no calendar-home-set found');
    final homeUrl = url.resolve(home);
    final list = await _propfind(homeUrl, depth: 1);
    return [for (final r in list) if (r.isCalendar && r.supportsEvents) _calendar(homeUrl.resolve(r.href), r)];
  }

  Future<Uri> _wellKnown(Uri base) async {
    final wk = base.replace(path: '/.well-known/caldav');
    final r = await _dio.requestUri<String>(wk,
        options: Options(method: 'PROPFIND', followRedirects: false, validateStatus: (_) => true, responseType: ResponseType.plain));
    final loc = r.headers.value('location');
    return loc == null ? base : wk.resolve(loc);
  }

  DavCalendar _calendar(Uri href, DavResponse r) => DavCalendar(
        href: href,
        displayName: r.props['displayname'] ?? href.pathSegments.where((s) => s.isNotEmpty).lastOrNull ?? 'Calendar',
        color: parseCalendarColor(r.props['calendar-color']),
        ctag: r.props['getctag'],
        syncToken: r.props['sync-token'],
      );

  Future<DavCalendar> calendarProps(Uri calendar) async {
    final rs = await _propfind(calendar);
    if (rs.isEmpty) throw CalDavException(0, 'empty PROPFIND for $calendar');
    return _calendar(calendar, rs.first);
  }

  /// REPORT calendar-query with a VEVENT time-range; includes calendar-data.
  Future<List<DavItem>> calendarQuery(Uri calendar, {DateTime? from, DateTime? to, DateTime? now}) async {
    final n = (now ?? DateTime.now()).toUtc();
    final f = _stamp((from ?? n.subtract(pastWindow)).toUtc());
    final t = _stamp((to ?? n.add(futureWindow)).toUtc());
    final body = '<?xml version="1.0" encoding="utf-8"?>'
        '<c:calendar-query xmlns:d="$_davNs" xmlns:c="$_calNs">'
        '<d:prop><d:getetag/><c:calendar-data/></d:prop>'
        '<c:filter><c:comp-filter name="VCALENDAR"><c:comp-filter name="VEVENT">'
        '<c:time-range start="$f" end="$t"/></c:comp-filter></c:comp-filter></c:filter>'
        '</c:calendar-query>';
    final r = await _request('REPORT', calendar, body: body, headers: {'Depth': '1'});
    return _items(parseMultistatus(r.data ?? ''));
  }

  Future<List<DavItem>> multiget(Uri calendar, List<String> hrefs) async {
    if (hrefs.isEmpty) return const [];
    final b = StringBuffer('<?xml version="1.0" encoding="utf-8"?>'
        '<c:calendar-multiget xmlns:d="$_davNs" xmlns:c="$_calNs"><d:prop><d:getetag/><c:calendar-data/></d:prop>');
    for (final h in hrefs) {
      b.write('<d:href>${_xmlEscape(h)}</d:href>');
    }
    b.write('</c:calendar-multiget>');
    final r = await _request('REPORT', calendar, body: b.toString(), headers: {'Depth': '1'});
    return _items(parseMultistatus(r.data ?? ''));
  }

  /// RFC 6578 sync-collection. Throws [CalDavException] 403/410 when the
  /// token is no longer valid (caller falls back to a full query).
  Future<SyncCollectionResult> syncCollection(Uri calendar, String token) async {
    final body = '<?xml version="1.0" encoding="utf-8"?>'
        '<d:sync-collection xmlns:d="$_davNs" xmlns:c="$_calNs">'
        '<d:sync-token>${_xmlEscape(token)}</d:sync-token><d:sync-level>1</d:sync-level>'
        '<d:prop><d:getetag/><c:calendar-data/></d:prop></d:sync-collection>';
    final r = await _request('REPORT', calendar, body: body, headers: {'Depth': '1'});
    if (r.statusCode == 404) throw const CalDavException(404, 'calendar not found');
    final doc = XmlDocument.parse(r.data ?? '');
    final rs = parseMultistatus(r.data ?? '');
    final changed = <DavItem>[];
    final deleted = <String>[];
    for (final x in rs) {
      if (x.status == 404 || x.status == 410) {
        deleted.add(x.href);
      } else if (!x.isCollection) {
        changed.add(DavItem(href: x.href, etag: x.props['getetag'], data: x.props['calendar-data']));
      }
    }
    final newToken = doc.rootElement.childElements.where((e) => e.name.local == 'sync-token').firstOrNull?.innerText.trim();
    return SyncCollectionResult(changed: changed, deleted: deleted, token: newToken);
  }

  Future<DavItem> get(Uri href) async {
    final r = await _request('GET', href);
    if (r.statusCode == 404) throw const CalDavException(404, 'not found');
    return DavItem(href: href.path, etag: r.headers.value('etag'), data: r.data);
  }

  /// PUT with `If-Match` (update) or `If-None-Match: *` (create). Returns the
  /// new ETag when the server sends one.
  Future<String?> put(Uri href, String ics, {String? etag}) async {
    final r = await _request('PUT', href,
        body: ics,
        contentType: 'text/calendar; charset=utf-8',
        headers: etag == null ? {'If-None-Match': '*'} : {'If-Match': etag});
    if (r.statusCode == 404) throw CalDavException(404, 'not found: $href');
    return r.headers.value('etag');
  }

  Future<void> delete(Uri href, {String? etag}) async {
    await _request('DELETE', href, headers: etag == null ? const {} : {'If-Match': etag});
  }

  static List<DavItem> _items(List<DavResponse> rs) => [
        for (final r in rs)
          if (!r.isCollection && (r.status == null || r.status! < 300))
            DavItem(href: r.href, etag: r.props['getetag'], data: r.props['calendar-data'])
      ];

  static String _stamp(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}${_two(d.month)}${_two(d.day)}T${_two(d.hour)}${_two(d.minute)}${_two(d.second)}Z';
  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _xmlEscape(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
}

/// `#RRGGBB` / `#RRGGBBAA` -> ARGB.
int? parseCalendarColor(String? s) {
  if (s == null) return null;
  final h = s.trim().replaceFirst('#', '');
  if (h.length != 6 && h.length != 8) return null;
  final v = int.tryParse(h, radix: 16);
  if (v == null) return null;
  if (h.length == 6) return 0xFF000000 | v;
  return ((v & 0xFF) << 24) | (v >> 8);
}

/// One `<response>` of a multistatus body.
class DavResponse {
  DavResponse(this.href, this.status, this.props, {required this.isCalendar, required this.isCollection, required this.supportsEvents});
  final String href;
  final int? status;
  final Map<String, String> props;
  final bool isCalendar;
  final bool isCollection;
  final bool supportsEvents;
}

/// Parses a WebDAV multistatus body into per-href property maps (local
/// names, namespace-agnostic). Nested hrefs (principal, home-set) are
/// flattened to their text.
List<DavResponse> parseMultistatus(String xml) {
  if (xml.trim().isEmpty) return const [];
  final doc = XmlDocument.parse(xml);
  final out = <DavResponse>[];
  for (final resp in doc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'response')) {
    final href = resp.childElements.where((e) => e.name.local == 'href').firstOrNull?.innerText.trim() ?? '';
    int? status;
    final props = <String, String>{};
    var isCalendar = false;
    var isCollection = false;
    var supportsEvents = true;
    final topStatus = resp.childElements.where((e) => e.name.local == 'status').firstOrNull;
    if (topStatus != null) status = _statusCode(topStatus.innerText);
    for (final ps in resp.childElements.where((e) => e.name.local == 'propstat')) {
      final st = ps.childElements.where((e) => e.name.local == 'status').firstOrNull;
      final code = st == null ? 200 : _statusCode(st.innerText);
      if (code != null && code >= 300) continue;
      for (final prop in ps.childElements.where((e) => e.name.local == 'prop')) {
        for (final p in prop.childElements) {
          final name = p.name.local;
          if (name == 'resourcetype') {
            for (final t in p.childElements) {
              if (t.name.local == 'calendar') isCalendar = true;
              if (t.name.local == 'collection') isCollection = true;
            }
          } else if (name == 'supported-calendar-component-set') {
            final comps = p.childElements.map((c) => c.getAttribute('name')).whereType<String>().toList();
            supportsEvents = comps.isEmpty || comps.contains('VEVENT');
          } else if (name == 'current-user-principal' || name == 'calendar-home-set') {
            final h = p.childElements.where((e) => e.name.local == 'href').firstOrNull;
            if (h != null) props[name] = h.innerText.trim();
          } else {
            props[name] = p.innerText.trim();
          }
        }
      }
    }
    out.add(DavResponse(href, status, props, isCalendar: isCalendar, isCollection: isCollection, supportsEvents: supportsEvents));
  }
  return out;
}

int? _statusCode(String s) {
  final m = RegExp(r'\b(\d{3})\b').firstMatch(s);
  return m == null ? null : int.parse(m[1]!);
}
