import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';
import '../database.dart' as d;

/// Key/value JSON settings. Keys: `ai`, `device`, `sortConfig.<accountId>`.
class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this.db);
  final d.SortieDatabase db;

  static const keyAi = 'ai';
  static const keyDevice = 'device';
  static String keySortConfig(String accountId) => 'sortConfig.$accountId';

  Stream<String?> _watch(String key) =>
      (db.select(db.settings)..where((t) => t.key.equals(key))).watchSingleOrNull().map((r) => r?.value);

  Map<String, dynamic>? _json(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<AiSettings> watchAi() => _watch(keyAi).map((v) => _ai(v)).distinct((a, b) => jsonEncode(a.toJson()) == jsonEncode(b.toJson()));

  AiSettings _ai(String? raw) {
    final j = _json(raw);
    if (j == null) return const AiSettings();
    try {
      return AiSettings.fromJson(j);
    } catch (_) {
      return const AiSettings();
    }
  }

  @override
  Future<AiSettings> ai() async => _ai(await getString(keyAi));

  @override
  Future<void> saveAi(AiSettings s) => setString(keyAi, jsonEncode(s.toJson()));

  @override
  Stream<DeviceSettings> watchDevice() => _watch(keyDevice).map(_device).distinct((a, b) => jsonEncode(a.toJson()) == jsonEncode(b.toJson()));

  DeviceSettings _device(String? raw) {
    final j = _json(raw);
    if (j == null) return const DeviceSettings();
    try {
      return DeviceSettings.fromJson(j);
    } catch (_) {
      return const DeviceSettings();
    }
  }

  @override
  Future<DeviceSettings> device() async => _device(await getString(keyDevice));

  @override
  Future<void> saveDevice(DeviceSettings s) => setString(keyDevice, jsonEncode(s.toJson()));

  @override
  Stream<SortConfig> watchSortConfig(String accountId) =>
      _watch(keySortConfig(accountId)).map(_sort).distinct((a, b) => jsonEncode(a.toJson()) == jsonEncode(b.toJson()));

  SortConfig _sort(String? raw) {
    final j = _json(raw);
    if (j == null) return const SortConfig();
    try {
      return SortConfig.fromJson(j);
    } catch (_) {
      return const SortConfig();
    }
  }

  @override
  Future<SortConfig> sortConfig(String accountId) async => _sort(await getString(keySortConfig(accountId)));

  @override
  Future<void> saveSortConfig(String accountId, SortConfig c) => setString(keySortConfig(accountId), jsonEncode(c.toJson()));

  @override
  Future<String?> getString(String key) async {
    final r = await (db.select(db.settings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return r?.value;
  }

  @override
  Future<void> setString(String key, String? value) async {
    if (value == null) {
      await (db.delete(db.settings)..where((t) => t.key.equals(key))).go();
      return;
    }
    await db.into(db.settings).insertOnConflictUpdate(d.SettingsCompanion(key: Value(key), value: Value(value)));
  }
}
