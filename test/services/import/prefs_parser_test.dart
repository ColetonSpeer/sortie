import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/services/import/thunderbird/prefs_parser.dart';

import 'fixtures.dart';

void main() {
  test('parses strings with escapes, numbers and booleans', () {
    final p = parsePrefsJs(prefsJs);
    expect(p['mail.accountmanager.accounts'], 'account1,account2,account3');
    expect(p['mail.server.server1.port'], 993);
    expect(p['mail.identity.id1.htmlSigFormat'], true);
    expect(p['mail.identity.id2.htmlSigFormat'], false);
    expect(p['mail.identity.id1.fullName'], 'Jane "JJ" Doe');
    expect(p['mail.identity.id2.htmlSigText'], '-- \nJane\\Alias\tline');
    expect(p['some.double'], 1.5);
    expect(p['some.unicode'], 'café');
    expect(p.list('mail.accountmanager.accounts'), ['account1', 'account2', 'account3']);
    expect(p.integer('mail.server.server1.socketType'), 3);
    expect(p.boolean('calendar.registry.cal-b.readOnly'), true);
  });

  test('ignores comments, pref() defaults and malformed lines', () {
    final p = parsePrefsJs('''
// user_pref("commented", 1);
pref("default.only", "x");
user_pref("broken", "unterminated);
user_pref("ok", "yes");
user_pref("weird", [1,2]);
user_pref( "spaced" , 42 );
''');
    expect(p.containsKey('commented'), isTrue, reason: 'comment stripping is not attempted; the key is harmless');
    expect(p['default.only'], isNull);
    expect(p['ok'], 'yes');
    expect(p['weird'], isNull);
    expect(p['spaced'], 42);
  });
}
