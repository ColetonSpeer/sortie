import 'dart:async';

import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/domain/repositories/repositories.dart';

/// Map-backed [MessageRepository] keyed by (folder, messageIdHash).
class MemoryMessageRepository implements MessageRepository {
  final Map<String, MessageHeader> _rows = {};
  final _changes = StreamController<void>.broadcast();

  static String _k(String folder, String mid) => '$folder|$mid';

  List<MessageHeader> get all => _rows.values.toList();

  MessageHeader? inFolder(String folder, String mid) => _rows[_k(folder, mid)];

  void _touch() {
    if (!_changes.isClosed) _changes.add(null);
  }

  @override
  Future<void> upsertHeaders(List<MessageHeader> headers) async {
    for (final h in headers) {
      _rows[_k(h.folderPath, h.messageIdHash)] = h;
    }
    _touch();
  }

  @override
  Future<MessageHeader?> byUid(String accountId, String folderPath, int uid) async =>
      _rows.values.where((h) => h.accountId == accountId && h.folderPath == folderPath && h.uid == uid).firstOrNull;

  @override
  Future<MessageHeader?> byMessageIdHash(String accountId, String messageIdHash) async {
    final hits = _rows.values.where((h) => h.accountId == accountId && h.messageIdHash == messageIdHash).toList();
    if (hits.isEmpty) return null;
    // Prefer the non-INBOX copy: after a move that is where it lives.
    return hits.firstWhere((h) => h.folderPath != 'INBOX', orElse: () => hits.first);
  }

  @override
  Stream<MessageHeader?> watchByMessageIdHash(String accountId, String messageIdHash) async* {
    yield await byMessageIdHash(accountId, messageIdHash);
    yield* _changes.stream.asyncMap((_) => byMessageIdHash(accountId, messageIdHash));
  }

  @override
  Future<List<MessageHeader>> list(MessageQuery q) async => _rows.values
      .where((h) => h.accountId == q.accountId && (q.folderPath == null || h.folderPath == q.folderPath))
      .skip(q.offset)
      .take(q.limit)
      .toList();

  @override
  Stream<List<MessageHeader>> watch(MessageQuery q) async* {
    yield await list(q);
    yield* _changes.stream.asyncMap((_) => list(q));
  }

  @override
  Future<void> updateFlags(String accountId, String folderPath, Map<int, Set<String>> flagsByUid) async {
    for (final e in flagsByUid.entries) {
      final h = await byUid(accountId, folderPath, e.key);
      if (h != null) _rows[_k(folderPath, h.messageIdHash)] = h.copyWith(flags: e.value);
    }
    _touch();
  }

  @override
  Future<void> removeByUids(String accountId, String folderPath, List<int> uids) async {
    _rows.removeWhere((_, h) => h.accountId == accountId && h.folderPath == folderPath && uids.contains(h.uid));
    _touch();
  }

  @override
  Future<void> moveLocally(String accountId, String fromFolder, List<int> uids, String toFolder, {Map<int, int> newUids = const {}}) async {
    for (final uid in uids) {
      final h = await byUid(accountId, fromFolder, uid);
      if (h == null) continue;
      _rows.remove(_k(fromFolder, h.messageIdHash));
      _rows[_k(toFolder, h.messageIdHash)] = h.copyWith(folderPath: toFolder, uid: newUids[uid] ?? uid);
    }
    _touch();
  }

  @override
  Future<List<int>> knownUids(String accountId, String folderPath) async =>
      _rows.values.where((h) => h.accountId == accountId && h.folderPath == folderPath).map((h) => h.uid).toList();

  @override
  Future<int?> maxUid(String accountId, String folderPath) async {
    final u = await knownUids(accountId, folderPath);
    return u.isEmpty ? null : u.reduce((a, b) => a > b ? a : b);
  }

  @override
  Future<List<MessageHeader>> search(String accountId, String query, {int limit = 100}) async => const [];
  @override
  Future<MessageBody?> cachedBody(String accountId, String messageIdHash) async => null;
  @override
  Future<void> cacheBody(String accountId, String messageIdHash, MessageBody body) async {}
  @override
  Future<void> cacheBodyText(String accountId, String messageIdHash, String text) async {}
  @override
  Future<void> invalidateUids(String accountId, String folderPath) async {}
  @override
  Future<void> relinkUid(String accountId, String folderPath, String messageIdHash, int uid, int uidValidity) async {}
  @override
  Future<void> deleteOrphans(String accountId, String folderPath) async {}
  @override
  Future<List<MessageHeader>> sample(String accountId, String folderPath, {int limit = 200}) async =>
      list(MessageQuery(accountId: accountId, folderPath: folderPath, limit: limit));
}

/// In-memory [SettingsRepository]; only sort config matters here.
class MemorySettingsRepository implements SettingsRepository {
  MemorySettingsRepository({SortConfig? sortConfig, DeviceSettings? device})
      : _sortConfig = sortConfig ?? const SortConfig(),
        _device = device ?? const DeviceSettings();

  SortConfig _sortConfig;
  DeviceSettings _device;
  AiSettings _ai = const AiSettings();
  final Map<String, String?> _kv = {};
  final _sortCtrl = StreamController<SortConfig>.broadcast();
  final _deviceCtrl = StreamController<DeviceSettings>.broadcast();
  final _aiCtrl = StreamController<AiSettings>.broadcast();
  final saved = <SortConfig>[];

  @override
  Stream<AiSettings> watchAi() async* {
    yield _ai;
    yield* _aiCtrl.stream;
  }

  @override
  Future<AiSettings> ai() async => _ai;
  @override
  Future<void> saveAi(AiSettings s) async {
    _ai = s;
    _aiCtrl.add(s);
  }

  @override
  Stream<DeviceSettings> watchDevice() async* {
    yield _device;
    yield* _deviceCtrl.stream;
  }

  @override
  Future<DeviceSettings> device() async => _device;
  @override
  Future<void> saveDevice(DeviceSettings s) async {
    _device = s;
    _deviceCtrl.add(s);
  }

  @override
  Stream<SortConfig> watchSortConfig(String accountId) async* {
    yield _sortConfig;
    yield* _sortCtrl.stream;
  }

  @override
  Future<SortConfig> sortConfig(String accountId) async => _sortConfig;
  @override
  Future<void> saveSortConfig(String accountId, SortConfig c) async {
    _sortConfig = c;
    saved.add(c);
    _sortCtrl.add(c);
  }

  @override
  Future<String?> getString(String key) async => _kv[key];
  @override
  Future<void> setString(String key, String? value) async => _kv[key] = value;
}
