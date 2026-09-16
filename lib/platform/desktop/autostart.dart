import 'dart:io';

import 'package:logging/logging.dart';

/// Launch-at-login without a plugin. Linux: XDG autostart entry.
/// Windows: `HKCU\...\Run` via `reg.exe`. macOS: not supported here.
class Autostart {
  static final _log = Logger('autostart');
  static const _name = 'sortie';

  static Future<void> set({required bool enabled, String appName = 'Sortie'}) async {
    final exe = Platform.resolvedExecutable;
    try {
      if (Platform.isLinux) {
        final home = Platform.environment['HOME'] ?? '';
        final dir = Directory('$home/.config/autostart');
        final file = File('${dir.path}/$_name.desktop');
        if (!enabled) {
          if (await file.exists()) await file.delete();
          return;
        }
        await dir.create(recursive: true);
        await file.writeAsString('[Desktop Entry]\nType=Application\nName=$appName\nExec="$exe"\n'
            'X-GNOME-Autostart-enabled=true\nComment=Start $appName at login\n');
      } else if (Platform.isWindows) {
        const key = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
        final args = enabled ? ['add', key, '/v', appName, '/t', 'REG_SZ', '/d', '"$exe"', '/f'] : ['delete', key, '/v', appName, '/f'];
        final r = await Process.run('reg', args);
        if (r.exitCode != 0 && enabled) _log.warning('reg.exe failed: ${r.stderr}');
      } else {
        _log.info('autostart not supported on this platform');
      }
    } catch (e) {
      _log.warning('autostart update failed', e);
    }
  }
}
