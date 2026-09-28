import 'dart:io';

import 'package:path/path.dart' as p;

/// One entry of `profiles.ini`.
class TbProfile {
  const TbProfile({required this.name, required this.path, this.isDefault = false});
  final String name;

  /// Absolute directory path.
  final String path;
  final bool isDefault;

  @override
  String toString() => '$name ($path)${isDefault ? ' [default]' : ''}';
}

/// Parses `profiles.ini` text. Relative paths are resolved against [baseDir]
/// (the directory containing profiles.ini). `[InstallXXXX] Default=<path>`
/// marks the profile Thunderbird actually starts; `Default=1` inside a
/// `[ProfileN]` section is the older marker.
List<TbProfile> parseProfilesIni(String text, String baseDir) {
  final sections = <String, Map<String, String>>{};
  String? current;
  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith(';') || line.startsWith('#')) continue;
    if (line.startsWith('[') && line.endsWith(']')) {
      current = line.substring(1, line.length - 1);
      sections.putIfAbsent(current, () => {});
      continue;
    }
    final eq = line.indexOf('=');
    if (eq < 0 || current == null) continue;
    sections[current]![line.substring(0, eq).trim()] = line.substring(eq + 1).trim();
  }

  final installDefaults = <String>{};
  for (final e in sections.entries) {
    if (e.key.startsWith('Install') && e.value['Default'] != null) installDefaults.add(_norm(e.value['Default']!));
  }

  // rank 0: the profile an [Install] section starts, 1: Default=1, 2: rest.
  final ranked = <(int, int, TbProfile)>[];
  for (final e in sections.entries) {
    if (!RegExp(r'^Profile\d+$').hasMatch(e.key)) continue;
    final rel = e.value['Path'];
    if (rel == null || rel.isEmpty) continue;
    final isRelative = e.value['IsRelative'] != '0';
    final abs = isRelative ? p.normalize(p.join(baseDir, rel)) : p.normalize(rel);
    final installDefault = installDefaults.contains(_norm(rel)) || installDefaults.contains(_norm(abs));
    final rank = installDefault ? 0 : (e.value['Default'] == '1' ? 1 : 2);
    ranked.add((rank, ranked.length, TbProfile(name: e.value['Name'] ?? p.basename(abs), path: abs, isDefault: rank < 2)));
  }
  ranked.sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
  return [for (final r in ranked) r.$3];
}

String _norm(String s) => s.replaceAll(r'\', '/').replaceAll(RegExp(r'/+$'), '');

/// Finds Thunderbird profiles on this machine.
abstract class ProfileLocator {
  Future<List<TbProfile>> discover();
}

/// Looks in the platform's standard Thunderbird data directory.
class PlatformProfileLocator implements ProfileLocator {
  PlatformProfileLocator({Map<String, String>? environment, String? operatingSystem})
      : _env = environment ?? Platform.environment,
        _os = operatingSystem ?? Platform.operatingSystem;
  final Map<String, String> _env;
  final String _os;

  /// Candidate directories that may contain `profiles.ini`, best first.
  List<String> iniDirectories() {
    final home = _env['HOME'] ?? _env['USERPROFILE'] ?? '';
    switch (_os) {
      case 'windows':
        final appData = _env['APPDATA'] ?? (home.isEmpty ? '' : p.join(home, 'AppData', 'Roaming'));
        return [if (appData.isNotEmpty) p.join(appData, 'Thunderbird')];
      case 'macos':
        return [if (home.isNotEmpty) p.join(home, 'Library', 'Thunderbird')];
      default:
        return [
          if (home.isNotEmpty) p.join(home, '.thunderbird'),
          if (home.isNotEmpty) p.join(home, 'snap', 'thunderbird', 'common', '.thunderbird'),
          if (home.isNotEmpty) p.join(home, '.var', 'app', 'org.mozilla.Thunderbird', '.thunderbird'),
        ];
    }
  }

  @override
  Future<List<TbProfile>> discover() async {
    final out = <TbProfile>[];
    for (final dir in iniDirectories()) {
      final ini = File(p.join(dir, 'profiles.ini'));
      if (!await ini.exists()) continue;
      try {
        for (final prof in parseProfilesIni(await ini.readAsString(), dir)) {
          if (await Directory(prof.path).exists()) out.add(prof);
        }
      } catch (_) {
        // Unreadable ini: skip this location.
      }
    }
    return out;
  }
}

/// Returns fixed profiles (tests, mobile).
class FixedProfileLocator implements ProfileLocator {
  const FixedProfileLocator(this.profiles);
  final List<TbProfile> profiles;
  @override
  Future<List<TbProfile>> discover() async => profiles;
}

/// True when [dir] looks like a Thunderbird profile.
Future<bool> looksLikeProfile(Directory dir) => File(p.join(dir.path, 'prefs.js')).exists();
