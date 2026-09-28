import 'dart:io';

import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Converts between wall-clock time in a named zone and UTC. Backed by the
/// IANA database in `package:timezone`; unknown ids fall back to a table of
/// Windows display names and finally to a fixed offset taken from VTIMEZONE.
abstract class Zone {
  const Zone();

  /// Wall time given as a UTC-flagged DateTime whose fields are the wall clock.
  DateTime toUtc(DateTime wall);

  /// UTC instant -> UTC-flagged DateTime whose fields are the wall clock.
  DateTime toWall(DateTime utc);

  String get id;
}

bool _tzReady = false;

/// Loads the embedded database once; cheap to call repeatedly.
void ensureTimeZonesLoaded() {
  if (_tzReady) return;
  tzdata.initializeTimeZones();
  _tzReady = true;
}

class IanaZone extends Zone {
  IanaZone._(this.id, this._loc);
  @override
  final String id;
  final tz.Location _loc;

  static IanaZone? tryResolve(String id) {
    ensureTimeZonesLoaded();
    final canonical = windowsToIana[id] ?? _stripMozillaPrefix(id);
    try {
      return IanaZone._(canonical, tz.getLocation(canonical));
    } on tz.LocationNotFoundException {
      return null;
    }
  }

  static String _stripMozillaPrefix(String id) {
    // Thunderbird/Lightning exports "/mozilla.org/20070129_1/Europe/Berlin".
    final i = id.indexOf('/', 1);
    if (id.startsWith('/') && id.contains('mozilla.org') && i > 0) {
      final parts = id.split('/');
      return parts.skip(3).join('/');
    }
    return id;
  }

  @override
  DateTime toUtc(DateTime wall) =>
      tz.TZDateTime(_loc, wall.year, wall.month, wall.day, wall.hour, wall.minute, wall.second).toUtc();

  @override
  DateTime toWall(DateTime utc) {
    final t = tz.TZDateTime.from(utc.toUtc(), _loc);
    return DateTime.utc(t.year, t.month, t.day, t.hour, t.minute, t.second);
  }
}

/// Fixed UTC offset (used for VTIMEZONEs we cannot map to IANA).
class FixedOffsetZone extends Zone {
  const FixedOffsetZone(this.id, this.offset);
  @override
  final String id;
  final Duration offset;

  @override
  DateTime toUtc(DateTime wall) => wall.subtract(offset);
  @override
  DateTime toWall(DateTime utc) => utc.toUtc().add(offset);
}

class UtcZone extends Zone {
  const UtcZone();
  @override
  String get id => 'UTC';
  @override
  DateTime toUtc(DateTime wall) => DateTime.utc(wall.year, wall.month, wall.day, wall.hour, wall.minute, wall.second);
  @override
  DateTime toWall(DateTime utc) => utc.toUtc();
}

/// Device-local zone: wall time is interpreted by Dart's local DateTime.
class LocalZone extends Zone {
  const LocalZone();
  @override
  String get id => 'local';
  @override
  DateTime toUtc(DateTime wall) =>
      DateTime(wall.year, wall.month, wall.day, wall.hour, wall.minute, wall.second).toUtc();
  @override
  DateTime toWall(DateTime utc) {
    final l = utc.toLocal();
    return DateTime.utc(l.year, l.month, l.day, l.hour, l.minute, l.second);
  }
}

/// Resolves a TZID; [fallbackOffsets] maps TZID -> standard offset parsed
/// from VTIMEZONE components in the same file.
Zone resolveZone(String? tzid, {Map<String, Duration> fallbackOffsets = const {}}) {
  if (tzid == null) return const LocalZone();
  final t = tzid.trim();
  if (t.isEmpty) return const LocalZone();
  if (t.toUpperCase() == 'UTC' || t.toUpperCase() == 'Z' || t == 'Etc/UTC' || t == 'GMT') return const UtcZone();
  final iana = IanaZone.tryResolve(t);
  if (iana != null) return iana;
  final off = fallbackOffsets[t];
  if (off != null) return FixedOffsetZone(t, off);
  return const LocalZone();
}

/// Common Windows / Outlook time zone display names -> IANA ids.
const windowsToIana = <String, String>{
  'Dateline Standard Time': 'Etc/GMT+12',
  'Hawaiian Standard Time': 'Pacific/Honolulu',
  'Alaskan Standard Time': 'America/Anchorage',
  'Pacific Standard Time': 'America/Los_Angeles',
  'Pacific Standard Time (Mexico)': 'America/Tijuana',
  'Mountain Standard Time': 'America/Denver',
  'US Mountain Standard Time': 'America/Phoenix',
  'Mountain Standard Time (Mexico)': 'America/Chihuahua',
  'Central Standard Time': 'America/Chicago',
  'Central Standard Time (Mexico)': 'America/Mexico_City',
  'Canada Central Standard Time': 'America/Regina',
  'Central America Standard Time': 'America/Guatemala',
  'Eastern Standard Time': 'America/New_York',
  'US Eastern Standard Time': 'America/Indiana/Indianapolis',
  'SA Pacific Standard Time': 'America/Bogota',
  'Atlantic Standard Time': 'America/Halifax',
  'Venezuela Standard Time': 'America/Caracas',
  'SA Western Standard Time': 'America/La_Paz',
  'Newfoundland Standard Time': 'America/St_Johns',
  'E. South America Standard Time': 'America/Sao_Paulo',
  'Argentina Standard Time': 'America/Argentina/Buenos_Aires',
  'SA Eastern Standard Time': 'America/Cayenne',
  'Greenland Standard Time': 'America/Godthab',
  'Azores Standard Time': 'Atlantic/Azores',
  'Cape Verde Standard Time': 'Atlantic/Cape_Verde',
  'UTC': 'UTC',
  'GMT Standard Time': 'Europe/London',
  'Greenwich Standard Time': 'Atlantic/Reykjavik',
  'W. Europe Standard Time': 'Europe/Berlin',
  'Central Europe Standard Time': 'Europe/Budapest',
  'Romance Standard Time': 'Europe/Paris',
  'Central European Standard Time': 'Europe/Warsaw',
  'W. Central Africa Standard Time': 'Africa/Lagos',
  'GTB Standard Time': 'Europe/Bucharest',
  'Middle East Standard Time': 'Asia/Beirut',
  'Egypt Standard Time': 'Africa/Cairo',
  'South Africa Standard Time': 'Africa/Johannesburg',
  'FLE Standard Time': 'Europe/Kiev',
  'Israel Standard Time': 'Asia/Jerusalem',
  'Turkey Standard Time': 'Europe/Istanbul',
  'E. Europe Standard Time': 'Europe/Chisinau',
  'Arabic Standard Time': 'Asia/Baghdad',
  'Arab Standard Time': 'Asia/Riyadh',
  'Russian Standard Time': 'Europe/Moscow',
  'E. Africa Standard Time': 'Africa/Nairobi',
  'Iran Standard Time': 'Asia/Tehran',
  'Arabian Standard Time': 'Asia/Dubai',
  'Azerbaijan Standard Time': 'Asia/Baku',
  'Caucasus Standard Time': 'Asia/Yerevan',
  'Georgian Standard Time': 'Asia/Tbilisi',
  'Afghanistan Standard Time': 'Asia/Kabul',
  'Pakistan Standard Time': 'Asia/Karachi',
  'West Asia Standard Time': 'Asia/Tashkent',
  'India Standard Time': 'Asia/Kolkata',
  'Sri Lanka Standard Time': 'Asia/Colombo',
  'Nepal Standard Time': 'Asia/Kathmandu',
  'Central Asia Standard Time': 'Asia/Almaty',
  'Bangladesh Standard Time': 'Asia/Dhaka',
  'Myanmar Standard Time': 'Asia/Yangon',
  'SE Asia Standard Time': 'Asia/Bangkok',
  'China Standard Time': 'Asia/Shanghai',
  'Singapore Standard Time': 'Asia/Singapore',
  'Taipei Standard Time': 'Asia/Taipei',
  'W. Australia Standard Time': 'Australia/Perth',
  'Korea Standard Time': 'Asia/Seoul',
  'Tokyo Standard Time': 'Asia/Tokyo',
  'Cen. Australia Standard Time': 'Australia/Adelaide',
  'AUS Central Standard Time': 'Australia/Darwin',
  'E. Australia Standard Time': 'Australia/Brisbane',
  'AUS Eastern Standard Time': 'Australia/Sydney',
  'Tasmania Standard Time': 'Australia/Hobart',
  'West Pacific Standard Time': 'Pacific/Port_Moresby',
  'New Zealand Standard Time': 'Pacific/Auckland',
  'Fiji Standard Time': 'Pacific/Fiji',
  'Tonga Standard Time': 'Pacific/Tongatapu',
};

/// Best-effort IANA id of the device zone (TZ env, /etc/timezone or the
/// /etc/localtime symlink). Null where unknown; callers then use floating time.
String? localTimeZoneId() {
  try {
    final env = Platform.environment['TZ'];
    if (env != null && env.isNotEmpty && IanaZone.tryResolve(env.replaceFirst(':', '')) != null) return env.replaceFirst(':', '');
    if (Platform.isLinux || Platform.isMacOS) {
      final f = File('/etc/timezone');
      if (f.existsSync()) {
        final id = f.readAsStringSync().trim();
        if (id.isNotEmpty && IanaZone.tryResolve(id) != null) return id;
      }
      final link = Link('/etc/localtime');
      if (link.existsSync()) {
        final target = link.resolveSymbolicLinksSync();
        final i = target.indexOf('zoneinfo/');
        if (i >= 0) {
          final id = target.substring(i + 'zoneinfo/'.length);
          if (IanaZone.tryResolve(id) != null) return id;
        }
      }
    }
  } catch (_) {
    // Fall through: unknown zone.
  }
  return null;
}
