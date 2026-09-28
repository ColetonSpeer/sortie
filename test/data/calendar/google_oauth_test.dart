import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/data/calendar/google_oauth.dart';

import '../ai/fake_http_adapter.dart';
import '../test_support.dart';

String _idToken(String email) {
  String b64(Map<String, dynamic> j) => base64Url.encode(utf8.encode(jsonEncode(j))).replaceAll('=', '');
  return '${b64({'alg': 'none'})}.${b64({'email': email, 'sub': '1'})}.sig';
}

void main() {
  late FakeHttpAdapter http;
  late GoogleOAuthClient client;

  setUp(() {
    http = FakeHttpAdapter();
    client = GoogleOAuthClient(clientId: 'cid', clientSecret: 'sec', dio: fakeDio(http), openBrowser: (_) async {});
  });

  Map<String, dynamic> form(int i) => (http.requests[i].data as Map).cast<String, dynamic>();

  test('exchangeCode posts the PKCE verifier and reads tokens + email from the id_token', () async {
    http.queue.add(FakeResponse.json(200, {
      'access_token': 'at1',
      'refresh_token': 'rt1',
      'expires_in': 3600,
      'id_token': _idToken('coletonspeer@hky.com'),
    }));
    final t = await client.exchangeCode('code123', verifier: 'ver', redirectUri: 'http://127.0.0.1:4242');
    expect(http.requests.single.uri.toString(), GoogleOAuthClient.tokenEndpoint);
    expect(http.requests.single.headers['content-type'], contains('application/x-www-form-urlencoded'));
    expect(form(0), {
      'code': 'code123',
      'client_id': 'cid',
      'client_secret': 'sec',
      'redirect_uri': 'http://127.0.0.1:4242',
      'grant_type': 'authorization_code',
      'code_verifier': 'ver',
    });
    expect(t.accessToken, 'at1');
    expect(t.refreshToken, 'rt1');
    expect(t.email, 'coletonspeer@hky.com');
    expect(t.expiresAt.isAfter(DateTime.now().toUtc().add(const Duration(minutes: 50))), isTrue);
  });

  test('refresh keeps the old refresh token unless Google rotates it; invalid_grant is flagged', () async {
    http.queue.add(FakeResponse.json(200, {'access_token': 'at2', 'expires_in': 1800}));
    final t = await client.refresh('rt1');
    expect(form(0)['grant_type'], 'refresh_token');
    expect(form(0)['refresh_token'], 'rt1');
    expect(t.accessToken, 'at2');
    expect(t.refreshToken, 'rt1');

    http.queue.add(FakeResponse.json(400, {'error': 'invalid_grant', 'error_description': 'Token has been revoked.'}));
    await expectLater(
      client.refresh('rt1'),
      throwsA(isA<GoogleOAuthException>().having((e) => e.invalidGrant, 'invalidGrant', isTrue)),
    );
  });

  test('GoogleAccountLink caches the access token, refreshes on expiry/force and persists rotation', () async {
    final creds = MemoryCredentialStore();
    final links = GoogleAccountLinks(credentials: creds, client: () => client);
    expect(await links.link('someone@example.com'), isNull);

    creds.map[GoogleAccountLinks.credentialKey('Coletonspeer@hky.com')] = 'rt1';
    final link = (await links.link('Coletonspeer@hky.com'))!;
    expect(link.email, 'coletonspeer@hky.com');

    http.queue.add(FakeResponse.json(200, {'access_token': 'a1', 'expires_in': 3600}));
    expect(await link.accessToken(), 'a1');
    expect(await link.accessToken(), 'a1'); // cached, no request
    expect(http.requests, hasLength(1));

    http.queue.add(FakeResponse.json(200, {'access_token': 'a2', 'expires_in': 3600, 'refresh_token': 'rt2'}));
    expect(await link.accessToken(forceRefresh: true), 'a2');
    expect(link.refreshToken, 'rt2');
    expect(creds.map[GoogleAccountLinks.credentialKey('coletonspeer@hky.com')], 'rt2');

    await links.forget('coletonspeer@hky.com');
    expect(creds.map.containsKey(GoogleAccountLinks.credentialKey('coletonspeer@hky.com')), isFalse);
    expect(await links.link('coletonspeer@hky.com'), isNull);
  });

  test('emailFromIdToken tolerates garbage', () {
    expect(emailFromIdToken('nope'), isNull);
    expect(emailFromIdToken(_idToken('a@b.c')), 'a@b.c');
  });

  test('Google principal URL and discovery target', () {
    expect(GoogleCalendarDiscovery.principalUrl('coletonspeer@hky.com').toString(),
        'https://apidata.googleusercontent.com/caldav/v2/coletonspeer%40hky.com/user');
  });
}
