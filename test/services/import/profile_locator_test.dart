import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sortie/services/import/thunderbird/profile_locator.dart';

import 'fixtures.dart';

void main() {
  test('parses profiles.ini with Install default, relative and absolute paths', () {
    final list = parseProfilesIni(profilesIni, '/home/u/.thunderbird');
    expect(list.map((x) => x.name), ['default-release', 'default', 'absolute']);
    expect(list.first.path, '/home/u/.thunderbird/abcd1234.default-release');
    expect(list.first.isDefault, isTrue);
    expect(list[1].isDefault, isTrue, reason: 'Default=1 inside the section');
    expect(list[2].path, '/opt/tb/profile');
    expect(list[2].isDefault, isFalse);
  });

  test('platform locator reads profiles.ini from an injected HOME', () async {
    final home = await Directory.systemTemp.createTemp('tbhome');
    addTearDown(() => home.delete(recursive: true));
    final tb = Directory(p.join(home.path, '.thunderbird'))..createSync();
    Directory(p.join(tb.path, 'abcd1234.default-release')).createSync();
    File(p.join(tb.path, 'profiles.ini')).writeAsStringSync(profilesIni);

    final found = await PlatformProfileLocator(environment: {'HOME': home.path}, operatingSystem: 'linux').discover();
    expect(found.map((x) => x.name), ['default-release'], reason: 'only existing directories are listed');

    final win = PlatformProfileLocator(environment: {'APPDATA': r'C:\Users\u\AppData\Roaming'}, operatingSystem: 'windows');
    expect(win.iniDirectories().single, endsWith('Thunderbird'));
    final mac = PlatformProfileLocator(environment: {'HOME': '/Users/u'}, operatingSystem: 'macos');
    expect(mac.iniDirectories().single, '/Users/u/Library/Thunderbird');
  });
}
