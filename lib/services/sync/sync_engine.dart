import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/clock.dart';
import '../../data/mail/imap_gateway.dart';
import '../../data/mail/smtp_gateway.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/services.dart';
import 'account_sync_session.dart';
import 'folder_synchronizer.dart';
import 'pending_op_executor.dart';

/// App-wide [MailSyncService]: one [AccountSyncSession] per enabled account,
/// optimistic local mutations queued as [PendingOp]s, on-demand bodies with an
/// LRU-capped cache.
class SyncEngine implements MailSyncService {
  SyncEngine({
    required this.accounts,
    required this.folders,
    required this.messages,
    required this.pendingOps,
    required this.credentials,
    required ImapGatewayFactory Function(Account account) gatewayFactory,
    required this.smtp,
    required this.clock,
    required this.spoolDir,
    this.tuning = const SyncTuning(),
    Future<void> Function(int maxBytes)? pruneBodyCache,
    this.bodyCacheMaxBytes = 500 * 1024 * 1024,
    Logger? log,
  })  : _gatewayFactory = gatewayFactory,
        _prune = pruneBodyCache,
        _log = log ?? Logger('sortie.sync');

  final AccountRepository accounts;
  final FolderRepository folders;
  final MessageRepository messages;
  final PendingOpRepository pendingOps;
  final CredentialStore credentials;
  final SmtpGateway smtp;
  final Clock clock;

  /// Where raw messages of queued Send/Append ops are spooled.
  final Directory spoolDir;
  final SyncTuning tuning;
  final int bodyCacheMaxBytes;
  final ImapGatewayFactory Function(Account) _gatewayFactory;
  final Future<void> Function(int maxBytes)? _prune;
  final Logger _log;
  final _uuid = const Uuid();

  final _sessions = <String, AccountSyncSession>{};
  final _accounts = <String, Account>{};
  final _statuses = <String, AccountSyncStatus>{};
  final _statusCtrl = StreamController<Map<String, AccountSyncStatus>>.broadcast();
  final _newInbox = <String, StreamController<List<MessageHeader>>>{};
  final _arrivals = <String, StreamController<List<MessageHeader>>>{};
  final _flags = <String, StreamController<FlagsObservation>>{};
  final _forwards = <String, List<StreamSubscription<dynamic>>>{};
  StreamSubscription<List<Account>>? _accountsSub;
  bool _started = false;

  StreamController<List<MessageHeader>> _inboxCtrl(String id) => _newInbox.putIfAbsent(id, StreamController<List<MessageHeader>>.broadcast);
  StreamController<List<MessageHeader>> _arrivalCtrl(String id) => _arrivals.putIfAbsent(id, StreamController<List<MessageHeader>>.broadcast);
  StreamController<FlagsObservation> _flagCtrl(String id) => _flags.putIfAbsent(id, StreamController<FlagsObservation>.broadcast);

  // ---------------------------------------------------------------- lifecycle

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await spoolDir.create(recursive: true);
    for (final a in await accounts.all()) {
      _accounts[a.id] = a;
      if (a.enabled) await startAccount(a.id);
    }
    _accountsSub = accounts.watchAll().listen((list) async {
      final ids = list.map((a) => a.id).toSet();
      for (final a in list) {
        final prev = _accounts[a.id];
        _accounts[a.id] = a;
        if (a.enabled && !_sessions.containsKey(a.id)) {
          await startAccount(a.id);
        } else if (!a.enabled && _sessions.containsKey(a.id)) {
          await stopAccount(a.id);
        } else if (prev != null && a.enabled && _endpointChanged(prev, a)) {
          await stopAccount(a.id);
          await startAccount(a.id);
        }
      }
      for (final gone in _sessions.keys.where((id) => !ids.contains(id)).toList()) {
        await stopAccount(gone);
        _accounts.remove(gone);
      }
    });
  }

  static bool _endpointChanged(Account a, Account b) =>
      a.username != b.username ||
      a.imap.host != b.imap.host ||
      a.imap.port != b.imap.port ||
      a.imap.security != b.imap.security ||
      a.smtp.host != b.smtp.host ||
      a.smtp.port != b.smtp.port;

  @override
  Future<void> stop() async {
    await _accountsSub?.cancel();
    _accountsSub = null;
    for (final id in _sessions.keys.toList()) {
      await stopAccount(id);
    }
    _started = false;
  }

  @override
  Future<void> startAccount(String accountId) async {
    if (_sessions.containsKey(accountId)) return;
    final account = await accounts.byId(accountId);
    if (account == null) throw StateError('unknown account $accountId');
    _accounts[accountId] = account;
    if (!account.enabled) {
      _publish(AccountSyncStatus(accountId: accountId, state: AccountSyncState.disabled));
      return;
    }
    final session = AccountSyncSession(
      account: account,
      password: () => password(accountId),
      gatewayFactory: () => _gatewayFactory(account)(),
      folderSync: FolderSynchronizer(accountId: accountId, messages: messages, folders: folders, clock: clock),
      executor: PendingOpExecutor(ops: pendingOps, messages: messages, folders: folders, accounts: accounts, credentials: credentials, smtp: smtp, clock: clock),
      folders: folders,
      messages: messages,
      clock: clock,
      tuning: tuning,
    );
    _sessions[accountId] = session;
    _forwards[accountId] = [
      session.status.listen(_publish),
      session.newInbox.listen(_inboxCtrl(accountId).add),
      session.arrivals.listen(_arrivalCtrl(accountId).add),
      session.flagChanges.listen(_flagCtrl(accountId).add),
    ];
    _publish(session.currentStatus);
    await session.start();
  }

  @override
  Future<void> stopAccount(String accountId) async {
    final s = _sessions.remove(accountId);
    if (s == null) return;
    await s.stop();
    for (final sub in _forwards.remove(accountId) ?? const <StreamSubscription<dynamic>>[]) {
      await sub.cancel();
    }
    await s.dispose();
    _publish(AccountSyncStatus(accountId: accountId, state: AccountSyncState.idle));
  }

  void _publish(AccountSyncStatus s) {
    _statuses[s.accountId] = s;
    if (!_statusCtrl.isClosed) _statusCtrl.add(Map.unmodifiable(_statuses));
  }

  AccountSyncSession _session(String accountId) {
    final s = _sessions[accountId];
    if (s == null) throw StateError('account $accountId is not running');
    return s;
  }

  // ---------------------------------------------------------------- observation

  @override
  Stream<AccountSyncStatus> watchStatus(String accountId) async* {
    yield _statuses[accountId] ?? AccountSyncStatus(accountId: accountId, state: AccountSyncState.idle);
    yield* _statusCtrl.stream.map((m) => m[accountId]).where((s) => s != null).cast<AccountSyncStatus>();
  }

  @override
  Stream<Map<String, AccountSyncStatus>> watchAllStatus() async* {
    yield Map.unmodifiable(_statuses);
    yield* _statusCtrl.stream;
  }

  @override
  Future<void> syncNow(String accountId, {String? folderPath}) => _session(accountId).syncNow(folderPath: folderPath);

  /// After the machine wakes from sleep: sync every account's INBOX now. A
  /// socket that died while asleep fails fast here and reconnects instead of
  /// waiting for the next keepalive to notice.
  void onResume() {
    for (final s in _sessions.values) {
      unawaited(s.syncNow().catchError((Object e) => _log.fine('resume sync: $e')));
    }
  }

  @override
  Future<void> refreshFolders(String accountId) => _session(accountId).refreshFolders();

  @override
  Stream<List<MessageHeader>> newInboxMessages(String accountId) => _inboxCtrl(accountId).stream;

  /// INBOX mail that arrived after the account was caught up (no initial
  /// window, no UIDVALIDITY resync). See [AccountSyncSession.arrivals].
  Stream<List<MessageHeader>> inboxArrivals(String accountId) => _arrivalCtrl(accountId).stream;

  @override
  Stream<FlagsObservation> flagChanges(String accountId) => _flagCtrl(accountId).stream;

  @override
  ImapCapabilities? capabilities(String accountId) => _sessions[accountId]?.capabilities;

  // ---------------------------------------------------------------- user actions

  Future<List<MessageHeader>> _headers(String accountId, String folderPath, List<int> uids) async {
    final out = <MessageHeader>[];
    for (final u in uids) {
      final h = await messages.byUid(accountId, folderPath, u);
      if (h != null) out.add(h);
    }
    return out;
  }

  Future<int> _uidValidity(String accountId, String folderPath, List<MessageHeader> hs) async =>
      (await folders.byPath(accountId, folderPath))?.uidValidity ?? (hs.isEmpty ? 0 : hs.first.uidValidity);

  void _kick(String accountId) => _sessions[accountId]?.requestDrain();

  @override
  Future<void> setFlags(String accountId, String folderPath, List<int> uids, {Set<String> add = const {}, Set<String> remove = const {}}) async {
    if (uids.isEmpty || (add.isEmpty && remove.isEmpty)) return;
    final hs = await _headers(accountId, folderPath, uids);
    await messages.updateFlags(accountId, folderPath, {
      for (final h in hs) h.uid: ({...h.flags}..addAll(add)).difference(remove),
    });
    await pendingOps.enqueue(SetFlagsOp(
      id: _uuid.v4(),
      accountId: accountId,
      createdAt: clock.now().toUtc(),
      folderPath: folderPath,
      uidValidity: await _uidValidity(accountId, folderPath, hs),
      messageIdHashes: hs.map((h) => h.messageIdHash).toList(),
      uids: hs.map((h) => h.uid).toList(),
      add: add,
      remove: remove,
    ));
    _kick(accountId);
  }

  @override
  Future<void> markSeen(String accountId, String folderPath, int uid, {bool seen = true}) =>
      setFlags(accountId, folderPath, [uid], add: seen ? {r'\Seen'} : const {}, remove: seen ? const {} : {r'\Seen'});

  @override
  Future<void> move(String accountId, String fromFolder, List<int> uids, String toFolder, {String cause = 'manual'}) async {
    if (uids.isEmpty || fromFolder == toFolder) return;
    final hs = await _headers(accountId, fromFolder, uids);
    if (hs.isEmpty) return;
    final uv = await _uidValidity(accountId, fromFolder, hs);
    await messages.moveLocally(accountId, fromFolder, hs.map((h) => h.uid).toList(), toFolder);
    await pendingOps.enqueue(MoveOp(
      id: _uuid.v4(),
      accountId: accountId,
      createdAt: clock.now().toUtc(),
      fromFolder: fromFolder,
      toFolder: toFolder,
      uidValidity: uv,
      messageIdHashes: hs.map((h) => h.messageIdHash).toList(),
      uids: hs.map((h) => h.uid).toList(),
      cause: cause,
    ));
    _kick(accountId);
  }

  @override
  Future<void> delete(String accountId, String folderPath, List<int> uids, {bool permanent = false}) async {
    if (uids.isEmpty) return;
    final hs = await _headers(accountId, folderPath, uids);
    if (hs.isEmpty) return;
    final uv = await _uidValidity(accountId, folderPath, hs);
    final trash = (await folders.all(accountId)).where((f) => f.specialUse == SpecialUse.trash).firstOrNull;
    final ids = hs.map((h) => h.uid).toList();
    if (!permanent && trash != null && trash.path != folderPath) {
      await messages.moveLocally(accountId, folderPath, ids, trash.path);
    } else {
      await messages.removeByUids(accountId, folderPath, ids);
    }
    await pendingOps.enqueue(DeleteOp(
      id: _uuid.v4(),
      accountId: accountId,
      createdAt: clock.now().toUtc(),
      folderPath: folderPath,
      uidValidity: uv,
      messageIdHashes: hs.map((h) => h.messageIdHash).toList(),
      uids: ids,
      permanent: permanent,
    ));
    _kick(accountId);
  }

  @override
  Future<MessageBody> body(String accountId, String folderPath, int uid) async {
    final h = await messages.byUid(accountId, folderPath, uid);
    if (h != null) {
      final cached = await messages.cachedBody(accountId, h.messageIdHash);
      if (cached != null) return cached;
    }
    final body = await _session(accountId).withCommand((gw) async {
      if (gw.selectedPath != folderPath) await gw.select(folderPath);
      return gw.fetchBody(uid);
    });
    if (h != null) {
      await messages.cacheBody(accountId, h.messageIdHash, body);
      final prune = _prune;
      if (prune != null) {
        unawaited(prune(bodyCacheMaxBytes).catchError((Object e) => _log.fine('body cache prune failed: $e')));
      }
    }
    return body;
  }

  @override
  Future<List<int>> attachment(String accountId, String folderPath, int uid, String partId) => _session(accountId).withCommand((gw) async {
        if (gw.selectedPath != folderPath) await gw.select(folderPath);
        return gw.fetchAttachment(uid, partId);
      });

  @override
  Future<List<int>> rawMessage(String accountId, String folderPath, int uid) => _session(accountId).withCommand((gw) async {
        if (gw.selectedPath != folderPath) await gw.select(folderPath);
        return gw.fetchRaw(uid);
      });

  Future<String> _spool(String accountId, List<int> raw) async {
    await spoolDir.create(recursive: true);
    final f = File(p.join(spoolDir.path, '$accountId-${_uuid.v4()}.eml'));
    await f.writeAsBytes(raw, flush: true);
    return f.path;
  }

  @override
  Future<void> saveDraft(String accountId, List<int> raw, {String? supersedesMessageId}) async {
    final path = await _spool(accountId, raw);
    await pendingOps.enqueue(AppendOp(
      id: _uuid.v4(),
      accountId: accountId,
      createdAt: clock.now().toUtc(),
      folderPath: await _draftsPath(accountId),
      rawMessagePath: path,
      flags: {r'\Draft', r'\Seen'},
      supersedesMessageId: supersedesMessageId,
    ));
    _kick(accountId);
  }

  @override
  Future<void> discardDraft(String accountId, String messageId) async {
    await pendingOps.enqueue(DeleteOp(
      id: _uuid.v4(),
      accountId: accountId,
      createdAt: clock.now().toUtc(),
      folderPath: await _draftsPath(accountId),
      uidValidity: 0,
      messageIdHashes: const [],
      uids: const [],
      permanent: true,
      messageIds: [messageId],
    ));
    _kick(accountId);
  }

  Future<String> _draftsPath(String accountId) async =>
      (await folders.all(accountId)).where((f) => f.specialUse == SpecialUse.drafts).firstOrNull?.path ?? 'Drafts';

  @override
  Future<void> send(String accountId, String identityId, List<String> recipients, List<int> raw, {String? draftMessageId}) async {
    if (recipients.isEmpty) throw ArgumentError('no recipients');
    final path = await _spool(accountId, raw);
    await pendingOps.enqueue(SendOp(
      id: _uuid.v4(),
      accountId: accountId,
      createdAt: clock.now().toUtc(),
      identityId: identityId,
      rawMessagePath: path,
      recipients: recipients,
      draftMessageId: draftMessageId,
    ));
    _kick(accountId);
  }

  // ---------------------------------------------------------------- coordinator hooks

  @override
  ImapGatewayFactory gatewayFactory(String accountId) => () {
        // Resolved per call: the coordinator is built from the accounts watch,
        // which can fire before start() has loaded the account.
        final a = _accounts[accountId];
        if (a == null) throw StateError('account $accountId not loaded; call startAccount first');
        return _gatewayFactory(a)();
      };

  @override
  Future<String> password(String accountId) async {
    final String? pw;
    try {
      pw = await credentials.read(CredentialStore.accountPassword(accountId));
    } catch (e) {
      // Keychain locked or store busy: retry with backoff, not an auth failure.
      throw ImapGatewayException('credential store unavailable: $e', cause: e);
    }
    if (pw == null) throw ImapGatewayException('no password stored for account $accountId', isAuthFailure: true);
    return pw;
  }
}
