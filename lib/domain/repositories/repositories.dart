import '../entities/entities.dart';

/// Secrets: account passwords and AI API keys. Never stored in the DB.
abstract class CredentialStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);

  static String accountPassword(String accountId) => 'account.$accountId.password';
  static String aiApiKey(AiProviderKind kind) => 'ai.${kind.name}.apiKey';
  static const deviceId = 'device.id';
}

abstract class AccountRepository {
  Stream<List<Account>> watchAll();
  Future<List<Account>> all();
  Future<Account?> byId(String id);
  Future<void> upsert(Account a);
  Future<void> delete(String id);

  Stream<List<Identity>> watchIdentities(String accountId);
  Future<List<Identity>> identities(String accountId);
  Future<void> upsertIdentity(Identity i);
  Future<void> deleteIdentity(String id);
}

abstract class FolderRepository {
  Stream<List<Folder>> watch(String accountId);
  Future<List<Folder>> all(String accountId);
  Future<Folder?> byPath(String accountId, String path);
  Future<void> replaceAll(String accountId, List<Folder> folders);
  Future<void> update(Folder f);
}

class MessageQuery {
  const MessageQuery({required this.accountId, this.folderPath, this.unifiedInbox = false, this.search, this.limit = 200, this.offset = 0});
  final String accountId;
  final String? folderPath;
  final bool unifiedInbox;
  final String? search;
  final int limit;
  final int offset;
}

abstract class MessageRepository {
  Stream<List<MessageHeader>> watch(MessageQuery q);
  Future<List<MessageHeader>> list(MessageQuery q);
  Future<MessageHeader?> byUid(String accountId, String folderPath, int uid);
  Future<MessageHeader?> byMessageIdHash(String accountId, String messageIdHash);
  Stream<MessageHeader?> watchByMessageIdHash(String accountId, String messageIdHash);
  Future<void> upsertHeaders(List<MessageHeader> headers);
  Future<void> updateFlags(String accountId, String folderPath, Map<int, Set<String>> flagsByUid);
  Future<void> removeByUids(String accountId, String folderPath, List<int> uids);
  Future<void> moveLocally(String accountId, String fromFolder, List<int> uids, String toFolder, {Map<int, int> newUids = const {}});
  Future<List<int>> knownUids(String accountId, String folderPath);
  Future<int?> maxUid(String accountId, String folderPath);

  /// Full-text search over subject, from and cached body text.
  Future<List<MessageHeader>> search(String accountId, String query, {int limit = 100});

  Future<MessageBody?> cachedBody(String accountId, String messageIdHash);
  Future<void> cacheBody(String accountId, String messageIdHash, MessageBody body);
  Future<void> cacheBodyText(String accountId, String messageIdHash, String text);

  /// For UIDVALIDITY changes: forget UIDs but keep rows keyed by Message-ID.
  Future<void> invalidateUids(String accountId, String folderPath);
  Future<void> relinkUid(String accountId, String folderPath, String messageIdHash, int uid, int uidValidity);
  Future<void> deleteOrphans(String accountId, String folderPath);

  /// Folder -> count of user-filed messages, used by folder profiles.
  Future<List<MessageHeader>> sample(String accountId, String folderPath, {int limit = 200});
}

abstract class PendingOpRepository {
  Future<void> enqueue(PendingOp op);
  Future<List<PendingOp>> pending(String accountId);
  Future<void> markDone(String id);
  Future<void> markFailed(String id, String error, {DateTime? nextAttemptAt});
  Future<void> markSmtpAccepted(String id);
  Stream<int> watchCount(String accountId);
}

abstract class SettingsRepository {
  Stream<AiSettings> watchAi();
  Future<AiSettings> ai();
  Future<void> saveAi(AiSettings s);

  Stream<DeviceSettings> watchDevice();
  Future<DeviceSettings> device();
  Future<void> saveDevice(DeviceSettings s);

  /// Local mirror of the per-account SortConfig (authoritative copy lives in
  /// the journal; the coordinator writes here after sync).
  Stream<SortConfig> watchSortConfig(String accountId);
  Future<SortConfig> sortConfig(String accountId);
  Future<void> saveSortConfig(String accountId, SortConfig c);

  Future<String?> getString(String key);
  Future<void> setString(String key, String? value);
}
