import 'dart:async';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

/// In-memory fakes used by widget tests and by `--dart-define=SORTIE_DEMO=true`.
/// They are deliberately simple: every mutation re-emits the full list.

class _Emitter<T> {
  _Emitter(this._value);
  T _value;
  final _ctrl = StreamController<T>.broadcast();
  T get value => _value;
  set value(T v) {
    _value = v;
    _ctrl.add(v);
  }

  Stream<T> get stream async* {
    yield _value;
    yield* _ctrl.stream;
  }
}

class FakeCredentialStore implements CredentialStore {
  final Map<String, String> values = {};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository({List<Account> accounts = const [], List<Identity> identities = const []})
      : _accounts = _Emitter(List.of(accounts)),
        _identities = _Emitter(List.of(identities));
  final _Emitter<List<Account>> _accounts;
  final _Emitter<List<Identity>> _identities;

  @override
  Stream<List<Account>> watchAll() => _accounts.stream;
  @override
  Future<List<Account>> all() async => _accounts.value;
  @override
  Future<Account?> byId(String id) async => _accounts.value.where((a) => a.id == id).firstOrNull;
  @override
  Future<void> upsert(Account a) async =>
      _accounts.value = [..._accounts.value.where((x) => x.id != a.id), a];
  @override
  Future<void> delete(String id) async {
    _accounts.value = _accounts.value.where((x) => x.id != id).toList();
    _identities.value = _identities.value.where((x) => x.accountId != id).toList();
  }

  @override
  Stream<List<Identity>> watchIdentities(String accountId) =>
      _identities.stream.map((l) => l.where((i) => i.accountId == accountId).toList());
  @override
  Future<List<Identity>> identities(String accountId) async =>
      _identities.value.where((i) => i.accountId == accountId).toList();
  @override
  Future<void> upsertIdentity(Identity i) async {
    var list = _identities.value.where((x) => x.id != i.id).toList();
    if (i.isDefault) {
      list = list
          .map((x) => x.accountId == i.accountId && x.isDefault
              ? Identity(id: x.id, accountId: x.accountId, name: x.name, email: x.email, replyTo: x.replyTo, signature: x.signature)
              : x)
          .toList();
    }
    _identities.value = [...list, i];
  }

  @override
  Future<void> deleteIdentity(String id) async =>
      _identities.value = _identities.value.where((x) => x.id != id).toList();
}

class FakeFolderRepository implements FolderRepository {
  FakeFolderRepository([List<Folder> folders = const []]) : _folders = _Emitter(List.of(folders));
  final _Emitter<List<Folder>> _folders;

  @override
  Stream<List<Folder>> watch(String accountId) =>
      _folders.stream.map((l) => l.where((f) => f.accountId == accountId).toList());
  @override
  Future<List<Folder>> all(String accountId) async => _folders.value.where((f) => f.accountId == accountId).toList();
  @override
  Future<Folder?> byPath(String accountId, String path) async =>
      _folders.value.where((f) => f.accountId == accountId && f.path == path).firstOrNull;
  @override
  Future<void> replaceAll(String accountId, List<Folder> folders) async =>
      _folders.value = [..._folders.value.where((f) => f.accountId != accountId), ...folders];
  @override
  Future<void> update(Folder f) async =>
      _folders.value = [..._folders.value.where((x) => !(x.accountId == f.accountId && x.path == f.path)), f];
}

class FakeMessageRepository implements MessageRepository {
  FakeMessageRepository([List<MessageHeader> headers = const []]) : _headers = _Emitter(List.of(headers));
  final _Emitter<List<MessageHeader>> _headers;
  final Map<String, MessageBody> bodies = {};

  List<MessageHeader> get headers => _headers.value;
  void _set(List<MessageHeader> l) => _headers.value = l;

  List<MessageHeader> _apply(MessageQuery q, List<MessageHeader> all) {
    var out = all.where((h) => h.accountId == q.accountId);
    if (q.folderPath != null) out = out.where((h) => h.folderPath == q.folderPath);
    if (q.search != null && q.search!.isNotEmpty) {
      final s = q.search!.toLowerCase();
      out = out.where((h) =>
          h.subject.toLowerCase().contains(s) ||
          (h.from?.email.toLowerCase().contains(s) ?? false) ||
          h.snippet.toLowerCase().contains(s));
    }
    final list = out.toList()..sort((a, b) => b.date.compareTo(a.date));
    return list.skip(q.offset).take(q.limit).toList();
  }

  @override
  Stream<List<MessageHeader>> watch(MessageQuery q) => _headers.stream.map((l) => _apply(q, l));
  @override
  Future<List<MessageHeader>> list(MessageQuery q) async => _apply(q, _headers.value);
  @override
  Future<MessageHeader?> byUid(String accountId, String folderPath, int uid) async => _headers.value
      .where((h) => h.accountId == accountId && h.folderPath == folderPath && h.uid == uid)
      .firstOrNull;
  @override
  Future<MessageHeader?> byMessageIdHash(String accountId, String messageIdHash) async =>
      _headers.value.where((h) => h.accountId == accountId && h.messageIdHash == messageIdHash).firstOrNull;
  @override
  Stream<MessageHeader?> watchByMessageIdHash(String accountId, String messageIdHash) => _headers.stream
      .map((l) => l.where((h) => h.accountId == accountId && h.messageIdHash == messageIdHash).firstOrNull);
  @override
  Future<void> upsertHeaders(List<MessageHeader> headers) async {
    final byHash = {for (final h in headers) h.messageIdHash: h};
    _set([..._headers.value.where((h) => !byHash.containsKey(h.messageIdHash)), ...headers]);
  }

  @override
  Future<void> updateFlags(String accountId, String folderPath, Map<int, Set<String>> flagsByUid) async => _set([
        for (final h in _headers.value)
          if (h.accountId == accountId && h.folderPath == folderPath && flagsByUid.containsKey(h.uid))
            h.copyWith(flags: flagsByUid[h.uid])
          else
            h,
      ]);
  @override
  Future<void> removeByUids(String accountId, String folderPath, List<int> uids) async => _set(_headers.value
      .where((h) => !(h.accountId == accountId && h.folderPath == folderPath && uids.contains(h.uid)))
      .toList());
  @override
  Future<void> moveLocally(String accountId, String fromFolder, List<int> uids, String toFolder,
      {Map<int, int> newUids = const {}}) async {
    var next = 100000 + _headers.value.length;
    _set([
      for (final h in _headers.value)
        if (h.accountId == accountId && h.folderPath == fromFolder && uids.contains(h.uid))
          h.copyWith(folderPath: toFolder, uid: newUids[h.uid] ?? next++)
        else
          h,
    ]);
  }

  @override
  Future<List<int>> knownUids(String accountId, String folderPath) async => _headers.value
      .where((h) => h.accountId == accountId && h.folderPath == folderPath)
      .map((h) => h.uid)
      .toList();
  @override
  Future<int?> maxUid(String accountId, String folderPath) async {
    final uids = await knownUids(accountId, folderPath);
    return uids.isEmpty ? null : uids.reduce((a, b) => a > b ? a : b);
  }

  @override
  Future<List<MessageHeader>> search(String accountId, String query, {int limit = 100}) async =>
      _apply(MessageQuery(accountId: accountId, search: query, limit: limit), _headers.value);
  @override
  Future<MessageBody?> cachedBody(String accountId, String messageIdHash) async => bodies['$accountId/$messageIdHash'];
  @override
  Future<void> cacheBody(String accountId, String messageIdHash, MessageBody body) async =>
      bodies['$accountId/$messageIdHash'] = body;
  @override
  Future<void> cacheBodyText(String accountId, String messageIdHash, String text) async =>
      bodies['$accountId/$messageIdHash'] = MessageBody(text: text);
  @override
  Future<void> invalidateUids(String accountId, String folderPath) async {}
  @override
  Future<void> relinkUid(String accountId, String folderPath, String messageIdHash, int uid, int uidValidity) async {}
  @override
  Future<void> deleteOrphans(String accountId, String folderPath) async {}
  @override
  Future<List<MessageHeader>> sample(String accountId, String folderPath, {int limit = 200}) async =>
      _apply(MessageQuery(accountId: accountId, folderPath: folderPath, limit: limit), _headers.value);
}

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({AiSettings? ai, DeviceSettings? device, Map<String, SortConfig> sortConfigs = const {}})
      : _ai = _Emitter(ai ?? const AiSettings()),
        _device = _Emitter(device ?? const DeviceSettings()),
        _sort = _Emitter(Map.of(sortConfigs));
  final _Emitter<AiSettings> _ai;
  final _Emitter<DeviceSettings> _device;
  final _Emitter<Map<String, SortConfig>> _sort;
  final Map<String, String?> strings = {};

  @override
  Stream<AiSettings> watchAi() => _ai.stream;
  @override
  Future<AiSettings> ai() async => _ai.value;
  @override
  Future<void> saveAi(AiSettings s) async => _ai.value = s;
  @override
  Stream<DeviceSettings> watchDevice() => _device.stream;
  @override
  Future<DeviceSettings> device() async => _device.value;
  @override
  Future<void> saveDevice(DeviceSettings s) async => _device.value = s;
  @override
  Stream<SortConfig> watchSortConfig(String accountId) => _sort.stream.map((m) => m[accountId] ?? const SortConfig());
  @override
  Future<SortConfig> sortConfig(String accountId) async => _sort.value[accountId] ?? const SortConfig();
  @override
  Future<void> saveSortConfig(String accountId, SortConfig c) async => _sort.value = {..._sort.value, accountId: c};
  @override
  Future<String?> getString(String key) async => strings[key];
  @override
  Future<void> setString(String key, String? value) async => strings[key] = value;
}
