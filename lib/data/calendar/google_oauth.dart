import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/repositories/repositories.dart';
import 'caldav_client.dart';

class GoogleTokens {
  const GoogleTokens({required this.accessToken, this.refreshToken, required this.expiresAt, this.email});
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final String? email;
}

class GoogleOAuthException implements Exception {
  const GoogleOAuthException(this.message, {this.invalidGrant = false});
  final String message;

  /// Refresh token revoked / expired: the user must sign in again.
  final bool invalidGrant;
  @override
  String toString() => 'GoogleOAuthException: $message';
}

/// OAuth 2.0 installed-app flow with a loopback redirect (works on desktop
/// and mobile: the system browser redirects to `http://127.0.0.1:<port>`).
class GoogleOAuthClient {
  GoogleOAuthClient({
    required this.clientId,
    required this.clientSecret,
    Dio? dio,
    Future<void> Function(Uri url)? openBrowser,
    Random? random,
  })  : _dio = dio ?? Dio(),
        _openBrowser = openBrowser ?? _launch,
        _random = random ?? Random.secure();

  /// Thunderbird's public installed-app credentials (not secret by design).
  static const defaultClientId = '406964657835-aq8lmia8j95dhl1a2bvharmfk3t1hgqj.apps.googleusercontent.com';
  static const defaultClientSecret = 'kSmqreRr0qwBWJgbf5Y-PjSU';
  static const scope = 'https://www.googleapis.com/auth/calendar openid email';
  static const authEndpoint = 'https://accounts.google.com/o/oauth2/auth';
  static const tokenEndpoint = 'https://oauth2.googleapis.com/token';

  static final _log = Logger('google.oauth');
  final String clientId;
  final String clientSecret;
  final Dio _dio;
  final Future<void> Function(Uri url) _openBrowser;
  final Random _random;

  static Future<void> _launch(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw GoogleOAuthException('could not open the browser for $url');
    }
  }

  String _randomString(int bytes) {
    final b = List<int>.generate(bytes, (_) => _random.nextInt(256));
    return base64UrlEncode(b).replaceAll('=', '');
  }

  /// Runs the browser flow and returns tokens (refresh token included thanks
  /// to `access_type=offline&prompt=consent`).
  Future<GoogleTokens> signIn({Duration timeout = const Duration(minutes: 5), String? loginHint}) async {
    final verifier = _randomString(48);
    final challenge = base64UrlEncode(sha256.convert(ascii.encode(verifier)).bytes).replaceAll('=', '');
    final state = _randomString(16);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirect = 'http://127.0.0.1:${server.port}';
    final code = Completer<String>();
    final sub = server.listen((req) async {
      final q = req.uri.queryParameters;
      final ok = q['state'] == state && q['code'] != null;
      req.response.headers.contentType = ContentType.html;
      req.response.write(ok
          ? '<html><body><h2>Signed in to Sortie.</h2>You can close this window.</body></html>'
          : '<html><body><h2>Sign-in failed.</h2>${q['error'] ?? 'missing code'}</body></html>');
      await req.response.close();
      if (!code.isCompleted) {
        if (ok) {
          code.complete(q['code']);
        } else {
          code.completeError(GoogleOAuthException(q['error'] ?? 'no authorization code returned'));
        }
      }
    });
    try {
      final url = Uri.parse(authEndpoint).replace(queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirect,
        'response_type': 'code',
        'scope': scope,
        'access_type': 'offline',
        'prompt': 'consent',
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'state': state,
        'login_hint': ?loginHint,
      });
      await _openBrowser(url);
      final c = await code.future.timeout(timeout, onTimeout: () => throw const GoogleOAuthException('sign-in timed out'));
      return await exchangeCode(c, verifier: verifier, redirectUri: redirect);
    } finally {
      await sub.cancel();
      await server.close(force: true);
    }
  }

  Future<GoogleTokens> exchangeCode(String code, {required String verifier, required String redirectUri}) => _token({
        'code': code,
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
        'code_verifier': verifier,
      });

  Future<GoogleTokens> refresh(String refreshToken) async {
    final t = await _token({
      'refresh_token': refreshToken,
      'client_id': clientId,
      'client_secret': clientSecret,
      'grant_type': 'refresh_token',
    });
    return GoogleTokens(accessToken: t.accessToken, refreshToken: t.refreshToken ?? refreshToken, expiresAt: t.expiresAt, email: t.email);
  }

  Future<GoogleTokens> _token(Map<String, String> form) async {
    Response<String> r;
    try {
      r = await _dio.post<String>(tokenEndpoint,
          data: form,
          options: Options(contentType: Headers.formUrlEncodedContentType, responseType: ResponseType.plain, validateStatus: (_) => true));
    } on DioException catch (e) {
      throw GoogleOAuthException('token request failed: ${e.message}');
    }
    Map<String, dynamic> j;
    try {
      j = jsonDecode(r.data ?? '{}') as Map<String, dynamic>;
    } catch (_) {
      throw GoogleOAuthException('token endpoint returned ${r.statusCode}');
    }
    if (r.statusCode != 200 || j['access_token'] == null) {
      final err = (j['error'] as String?) ?? 'HTTP ${r.statusCode}';
      _log.warning('token error: $err');
      throw GoogleOAuthException('${j['error_description'] ?? err}', invalidGrant: err == 'invalid_grant');
    }
    final idToken = j['id_token'] as String?;
    return GoogleTokens(
      accessToken: j['access_token'] as String,
      refreshToken: j['refresh_token'] as String?,
      expiresAt: DateTime.now().toUtc().add(Duration(seconds: ((j['expires_in'] as num?) ?? 3600).toInt() - 60)),
      email: idToken == null ? null : emailFromIdToken(idToken),
    );
  }
}

/// Reads `email` from an OpenID id_token payload (no signature check: the
/// token came straight from Google's token endpoint over TLS).
String? emailFromIdToken(String idToken) {
  final parts = idToken.split('.');
  if (parts.length < 2) return null;
  try {
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    return (jsonDecode(payload) as Map<String, dynamic>)['email'] as String?;
  } catch (_) {
    return null;
  }
}

/// One signed-in Google account, shared by every calendar it owns. Caches
/// the access token in memory and refreshes it on demand.
class GoogleAccountLink implements TokenProvider {
  GoogleAccountLink({
    required this.email,
    required String refreshToken,
    required GoogleOAuthClient Function() client,
    Future<void> Function(String refreshToken)? onRotated,
    GoogleTokens? initial,
  })  : _refreshToken = refreshToken,
        _client = client,
        _onRotated = onRotated,
        _access = initial?.accessToken,
        _expiresAt = initial?.expiresAt;

  final String email;
  String _refreshToken;
  final GoogleOAuthClient Function() _client;
  final Future<void> Function(String refreshToken)? _onRotated;
  String? _access;
  DateTime? _expiresAt;
  Future<String>? _inflight;

  String get refreshToken => _refreshToken;

  @override
  Future<String> accessToken({bool forceRefresh = false}) {
    final valid = _access != null && _expiresAt != null && DateTime.now().toUtc().isBefore(_expiresAt!);
    if (valid && !forceRefresh) return Future.value(_access);
    return _inflight ??= _refresh().whenComplete(() => _inflight = null);
  }

  Future<String> _refresh() async {
    final t = await _client().refresh(_refreshToken);
    _access = t.accessToken;
    _expiresAt = t.expiresAt;
    if (t.refreshToken != null && t.refreshToken != _refreshToken) {
      _refreshToken = t.refreshToken!;
      await _onRotated?.call(_refreshToken);
    }
    return _access!;
  }
}

/// Registry of Google links keyed by account email; refresh tokens live in
/// the [CredentialStore] under `calendar.google.<email>.refresh`.
class GoogleAccountLinks {
  GoogleAccountLinks({required CredentialStore credentials, required GoogleOAuthClient Function() client})
      : _credentials = credentials,
        _client = client;

  final CredentialStore _credentials;
  final GoogleOAuthClient Function() _client;
  final _links = <String, GoogleAccountLink>{};

  static String credentialKey(String email) => 'calendar.google.${email.toLowerCase()}.refresh';

  /// The link for [email] if this device has signed in to it.
  Future<GoogleAccountLink?> link(String email) async {
    final key = email.toLowerCase();
    final cached = _links[key];
    if (cached != null) return cached;
    final rt = await _credentials.read(credentialKey(key));
    if (rt == null || rt.isEmpty) return null;
    return _links[key] = _make(key, rt);
  }

  GoogleAccountLink _make(String email, String rt, {GoogleTokens? initial}) => GoogleAccountLink(
        email: email,
        refreshToken: rt,
        client: _client,
        initial: initial,
        onRotated: (t) => _credentials.write(credentialKey(email), t),
      );

  /// Runs the browser sign-in and stores the refresh token.
  Future<GoogleAccountLink> signIn({String? loginHint}) async {
    final t = await _client().signIn(loginHint: loginHint);
    final email = (t.email ?? loginHint ?? '').toLowerCase();
    if (email.isEmpty) throw const GoogleOAuthException('Google did not return an email address');
    if (t.refreshToken == null) throw const GoogleOAuthException('Google did not return a refresh token');
    await _credentials.write(credentialKey(email), t.refreshToken!);
    return _links[email] = _make(email, t.refreshToken!, initial: t);
  }

  Future<void> forget(String email) async {
    _links.remove(email.toLowerCase());
    await _credentials.delete(credentialKey(email));
  }
}

/// Lists the calendars of a Google account through CalDAV discovery.
abstract final class GoogleCalendarDiscovery {
  static const host = 'apidata.googleusercontent.com';

  static Uri principalUrl(String email) => Uri.parse('https://$host/caldav/v2/${Uri.encodeComponent(email)}/user');

  static Future<List<DavCalendar>> listCalendars(Dio dio, TokenProvider token, String email) =>
      CalDavClient(dio: dio, auth: BearerAuth(token)).discover(principalUrl(email));
}
