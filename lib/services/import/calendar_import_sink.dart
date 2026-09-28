import 'dart:convert';

import '../../domain/repositories/repositories.dart';

/// A calendar found in an external profile (Thunderbird `calendar.registry.*`).
class ImportedCalendar {
  const ImportedCalendar({
    required this.id,
    required this.name,
    required this.type,
    required this.uri,
    this.username,
    this.color,
    this.disabled = false,
    this.readOnly = false,
  });

  final String id;
  final String name;

  /// `caldav`, `ics` or `storage` (local).
  final String type;
  final String uri;
  final String? username;
  final String? color;
  final bool disabled;
  final bool readOnly;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'uri': uri,
        if (username != null) 'username': username,
        if (color != null) 'color': color,
        'disabled': disabled,
        'readOnly': readOnly,
      };

  static ImportedCalendar fromJson(Map<String, dynamic> j) => ImportedCalendar(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        type: (j['type'] as String?) ?? 'storage',
        uri: (j['uri'] as String?) ?? '',
        username: j['username'] as String?,
        color: j['color'] as String?,
        disabled: (j['disabled'] as bool?) ?? false,
        readOnly: (j['readOnly'] as bool?) ?? false,
      );
}

/// Receives calendars found by an importer. The calendar module implements
/// this; until it exists [PendingCalendarImportSink] parks the list.
abstract class CalendarImportSink {
  Future<void> importCalendars(List<ImportedCalendar> calendars);
}

/// Default sink: stores the calendars as JSON under [settingsKey] so the
/// calendar module can pick them up later (merged by id with earlier imports).
class PendingCalendarImportSink implements CalendarImportSink {
  PendingCalendarImportSink(this._settings);
  final SettingsRepository _settings;

  static const settingsKey = 'import.calendars.pending';

  @override
  Future<void> importCalendars(List<ImportedCalendar> calendars) async {
    final existing = await pending();
    final byId = {for (final c in existing) c.id: c, for (final c in calendars) c.id: c};
    await _settings.setString(settingsKey, jsonEncode([for (final c in byId.values) c.toJson()]));
  }

  Future<List<ImportedCalendar>> pending() async {
    final raw = await _settings.getString(settingsKey);
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw);
    if (list is! List) return const [];
    return [for (final e in list) if (e is Map) ImportedCalendar.fromJson(e.cast<String, dynamic>())];
  }
}
