import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/router/app_router.dart';

void main() {
  test('a message from another folder keeps the list folder in the path', () {
    expect(Routes.messageIn('a', 'INBOX', 'INBOX', 5), Routes.message('a', 'INBOX', 5));
    final r = Routes.messageIn('a', 'INBOX', 'Sent', 7);
    expect(r, startsWith(Routes.message('a', 'INBOX', 7)));
    expect(Uri.parse(r).queryParameters['in'], 'Sent');
  });

  test('the compose route carries blabber=1 only when asked', () {
    expect(Uri.parse(Routes.composeWith(accountId: 'a')).queryParameters.containsKey('blabber'), isFalse);
    expect(Uri.parse(Routes.composeWith(accountId: 'a', blabber: true)).queryParameters['blabber'], '1');
    expect(Uri.parse(Routes.composeWith(accountId: 'a', reply: '4', folder: 'INBOX', blabber: true)).queryParameters, {'accountId': 'a', 'reply': '4', 'folder': 'INBOX', 'blabber': '1'});
  });
}
