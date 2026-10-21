import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/router/app_router.dart';

void main() {
  test('a message from another folder keeps the list folder in the path', () {
    expect(Routes.messageIn('a', 'INBOX', 'INBOX', 5), Routes.message('a', 'INBOX', 5));
    final r = Routes.messageIn('a', 'INBOX', 'Sent', 7);
    expect(r, startsWith(Routes.message('a', 'INBOX', 7)));
    expect(Uri.parse(r).queryParameters['in'], 'Sent');
  });
}
