import 'dart:async';

import '../../data/mail/imap_gateway.dart';
import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';
import 'fake_repositories.dart';

/// Fake sync service: applies user actions to the in-memory repository and
/// records every call for widget tests.
class FakeMailSyncService implements MailSyncService {
  FakeMailSyncService(this.messages, {Map<String, AccountSyncStatus> status = const {}})
      : _status = Map.of(status);
  final FakeMessageRepository messages;
  final Map<String, AccountSyncStatus> _status;
  final _statusCtrl = StreamController<Map<String, AccountSyncStatus>>.broadcast();
  final List<String> calls = [];
  final Map<String, MessageBody> bodiesByHash = {};

  /// What a `refresh: true` fetch returns (falls back to [bodiesByHash]).
  final Map<String, MessageBody> refreshedBodiesByHash = {};
  final Map<String, List<int>> attachmentBytes = {};
  final List<(String, String, List<String>, List<int>)> sent = [];
  final List<(String, List<int>, String?)> drafts = [];
  final List<String> discarded = [];
  final List<String?> sentDraftIds = [];

  void setStatus(AccountSyncStatus s) {
    _status[s.accountId] = s;
    _statusCtrl.add(Map.of(_status));
  }

  @override
  Future<void> start() async => calls.add('start');
  @override
  Future<void> stop() async => calls.add('stop');
  @override
  Future<void> startAccount(String accountId) async => calls.add('startAccount:$accountId');
  @override
  Future<void> stopAccount(String accountId) async => calls.add('stopAccount:$accountId');
  @override
  Stream<AccountSyncStatus> watchStatus(String accountId) =>
      watchAllStatus().map((m) => m[accountId]).where((s) => s != null).cast<AccountSyncStatus>();
  @override
  Stream<Map<String, AccountSyncStatus>> watchAllStatus() async* {
    yield Map.of(_status);
    yield* _statusCtrl.stream;
  }

  @override
  Future<void> syncNow(String accountId, {String? folderPath}) async => calls.add('syncNow:$accountId');
  @override
  Future<void> refreshFolders(String accountId) async => calls.add('refreshFolders:$accountId');
  @override
  Future<void> createFolder(String accountId, String path) async => calls.add('createFolder:$path');
  @override
  Stream<List<MessageHeader>> newInboxMessages(String accountId) => const Stream.empty();
  @override
  Stream<FlagsObservation> flagChanges(String accountId) => const Stream.empty();
  @override
  ImapCapabilities? capabilities(String accountId) => null;

  @override
  Future<void> setFlags(String accountId, String folderPath, List<int> uids,
      {Set<String> add = const {}, Set<String> remove = const {}}) async {
    calls.add('setFlags:$folderPath:$uids:+$add:-$remove');
    final byUid = <int, Set<String>>{};
    for (final h in messages.headers) {
      if (h.accountId == accountId && h.folderPath == folderPath && uids.contains(h.uid)) {
        byUid[h.uid] = {...h.flags, ...add}..removeAll(remove);
      }
    }
    await messages.updateFlags(accountId, folderPath, byUid);
  }

  @override
  Future<void> markSeen(String accountId, String folderPath, int uid, {bool seen = true}) async {
    calls.add('markSeen:$folderPath:$uid:$seen');
    await setFlags(accountId, folderPath, [uid], add: seen ? {r'\Seen'} : {}, remove: seen ? {} : {r'\Seen'});
  }

  @override
  Future<void> move(String accountId, String fromFolder, List<int> uids, String toFolder,
      {String cause = 'manual'}) async {
    calls.add('move:$fromFolder:$uids:$toFolder');
    await messages.moveLocally(accountId, fromFolder, uids, toFolder);
  }

  @override
  Future<void> delete(String accountId, String folderPath, List<int> uids, {bool permanent = false}) async {
    calls.add('delete:$folderPath:$uids');
    if (permanent || folderPath == 'Trash') {
      await messages.removeByUids(accountId, folderPath, uids);
    } else {
      await messages.moveLocally(accountId, folderPath, uids, 'Trash');
    }
  }

  @override
  Future<MessageBody> body(String accountId, String folderPath, int uid, {bool refresh = false}) async {
    calls.add('body:$folderPath:$uid${refresh ? ':refresh' : ''}');
    if (refresh) {
      final h = await messages.byUid(accountId, folderPath, uid);
      final fresh = refreshedBodiesByHash[h?.messageIdHash];
      if (fresh != null) return fresh;
    }
    final h = await messages.byUid(accountId, folderPath, uid);
    return bodiesByHash[h?.messageIdHash] ??
        MessageBody(text: h == null ? '' : '${h.snippet}\n\n(demo body — no server connected)');
  }

  @override
  Future<List<int>> attachment(String accountId, String folderPath, int uid, String partId) async =>
      attachmentBytes[partId] ?? List<int>.filled(16, 0);
  @override
  Future<List<int>> rawMessage(String accountId, String folderPath, int uid) async => [];
  @override
  Future<void> saveDraft(String accountId, List<int> raw, {String? supersedesMessageId}) async =>
      drafts.add((accountId, raw, supersedesMessageId));

  @override
  Future<void> discardDraft(String accountId, String messageId) async => discarded.add(messageId);
  @override
  Future<void> send(String accountId, String identityId, List<String> recipients, List<int> raw, {String? draftMessageId}) async {
    sent.add((accountId, identityId, recipients, raw));
    sentDraftIds.add(draftMessageId);
  }
  @override
  ImapGatewayFactory gatewayFactory(String accountId) => throw UnsupportedError('fake');
  @override
  Future<String> password(String accountId) async => 'demo';
}

class FakeMessageClassifier implements MessageClassifier {
  final List<Correction> corrections = [];
  bool bootstrapped = false;
  double replayAccuracy = 0.87;
  (double, double) spendValue = (0.0123, 0.4567);
  final _status = StreamController<String>.broadcast();

  @override
  Future<List<SortDecision>> classify(String accountId, List<ClassificationInput> inputs, SortConfig config,
          {bool dryRun = false}) async =>
      [];
  @override
  Future<void> recordCorrection(Correction c) async => corrections.add(c);
  @override
  Future<void> bootstrap(String accountId, SortConfig config, {void Function(String)? progress}) async {
    for (final step in ['Reading folders…', 'Sampling 200 messages…', 'Building folder profiles…', 'Done']) {
      progress?.call(step);
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    bootstrapped = true;
  }

  @override
  Future<bool> isBootstrapped(String accountId) async => bootstrapped;
  @override
  Future<double> accuracyReplay(String accountId, SortConfig config, {int sample = 200}) async => replayAccuracy;
  @override
  Future<(double, double)> spend() async => spendValue;
  @override
  Stream<String> get statusMessages => _status.stream;
}

/// Fake coordinator: keeps pending badges and a log in memory; `moveNow`
/// really moves the message in the fake repository so the UI can be exercised.
class FakeSortCoordinator implements SortCoordinator {
  FakeSortCoordinator(
    this.accountId, {
    required this.messages,
    this.deviceId = 'this-device',
    Map<MessageKey, PendingBadge> pending = const {},
    List<SortLogEntry> log = const [],
    List<SeenDevice> devices = const [],
    SortConfig config = const SortConfig(),
    CoordinationState state = CoordinationState.leader,
  })  : _pending = Map.of(pending),
        _log = List.of(log),
        _devices = List.of(devices),
        // ignore: prefer_initializing_formals
        _config = config,
        // ignore: prefer_initializing_formals
        _state = state;

  @override
  final String accountId;
  final FakeMessageRepository messages;
  final String deviceId;
  final List<String> calls = [];
  final List<MessageKey> opened = [];
  final List<MessageKey> closed = [];

  Map<MessageKey, PendingBadge> _pending;
  final List<SortLogEntry> _log;
  final List<SeenDevice> _devices;
  SortConfig _config;
  CoordinationState _state;
  final _pendingCtrl = StreamController<Map<MessageKey, PendingBadge>>.broadcast();
  final _logCtrl = StreamController<List<SortLogEntry>>.broadcast();
  final _devicesCtrl = StreamController<List<SeenDevice>>.broadcast();
  final _configCtrl = StreamController<SortConfig>.broadcast();
  final _stateCtrl = StreamController<CoordinationState>.broadcast();
  bool throwOnPutConfig = false;

  void setPending(Map<MessageKey, PendingBadge> p) {
    _pending = Map.of(p);
    _pendingCtrl.add(_pending);
  }

  void setState(CoordinationState s) {
    _state = s;
    _stateCtrl.add(s);
  }

  void _removeBadge(MessageKey key) {
    _pending = Map.of(_pending)..remove(key);
    _pendingCtrl.add(_pending);
  }

  void _addLog(SortLogEntry e) {
    _log.insert(0, e);
    _logCtrl.add(List.of(_log));
  }

  @override
  Future<void> start() async => calls.add('start');
  @override
  Future<void> stop({bool graceful = true}) async => calls.add('stop');
  @override
  Stream<CoordinationState> get state async* {
    yield _state;
    yield* _stateCtrl.stream;
  }

  @override
  CoordinationState get currentState => _state;
  @override
  int? get epoch => 7;
  @override
  Stream<Map<MessageKey, PendingBadge>> watchPending() async* {
    yield _pending;
    yield* _pendingCtrl.stream;
  }

  @override
  Stream<List<SortLogEntry>> watchLog({int limit = 200}) async* {
    yield List.of(_log);
    yield* _logCtrl.stream;
  }

  @override
  Stream<List<SeenDevice>> watchDevices() async* {
    yield List.of(_devices);
    yield* _devicesCtrl.stream;
  }

  @override
  Stream<SortConfig> watchConfig() async* {
    yield _config;
    yield* _configCtrl.stream;
  }

  @override
  Future<void> putConfig(SortConfig c) async {
    calls.add('putConfig');
    if (throwOnPutConfig) throw StateError('coordinator offline');
    _config = c;
    _configCtrl.add(c);
  }

  @override
  Future<void> undo(String decisionId) async {
    calls.add('undo:$decisionId');
    final entry = _log.where((e) => e.decisionId == decisionId && e.type == 'moved').firstOrNull;
    if (entry != null && entry.toFolder != null) {
      final h = await messages.byMessageIdHash(accountId, entry.key.messageIdHash);
      if (h != null) await messages.moveLocally(accountId, h.folderPath, [h.uid], entry.fromFolder ?? 'INBOX');
      _addLog(SortLogEntry(
          id: 'undo-$decisionId',
          at: DateTime.now(),
          type: 'undo',
          key: entry.key,
          subject: entry.subject,
          from: entry.from,
          fromFolder: entry.toFolder,
          toFolder: entry.fromFolder,
          deviceId: deviceId,
          decisionId: decisionId));
    }
  }

  @override
  Future<void> moveNow(MessageKey key) async {
    calls.add('moveNow:$key');
    final badge = _pending[key];
    final h = await messages.byMessageIdHash(accountId, key.messageIdHash);
    if (badge == null || h == null) return;
    await messages.moveLocally(accountId, h.folderPath, [h.uid], badge.destination);
    _removeBadge(key);
    _addLog(SortLogEntry(
        id: 'moved-${badge.decisionId}',
        at: DateTime.now(),
        type: 'moved',
        key: key,
        subject: h.subject,
        from: h.from?.toString() ?? '',
        fromFolder: h.folderPath,
        toFolder: badge.destination,
        reason: badge.reason,
        confidence: badge.confidence,
        deviceId: deviceId,
        cause: 'manual',
        undoable: true,
        decisionId: badge.decisionId));
  }

  @override
  Future<void> keepInInbox(MessageKey key) async {
    calls.add('keepInInbox:$key');
    _removeBadge(key);
  }

  @override
  Future<void> changeDestination(MessageKey key, String folderPath) async {
    calls.add('changeDestination:$key:$folderPath');
    final b = _pending[key];
    if (b == null) return;
    _pending = Map.of(_pending)
      ..[key] = PendingBadge(
          key: key,
          destination: folderPath,
          confidence: 1.0,
          reason: 'You chose this folder',
          mode: b.mode,
          decisionId: b.decisionId,
          layer: SortLayer.rule);
    _pendingCtrl.add(_pending);
  }

  @override
  Future<void> markRight(MessageKey key) async => calls.add('markRight:$key');
  @override
  void onMessageOpened(MessageKey key) => opened.add(key);
  @override
  void onMessageClosed(MessageKey key) => closed.add(key);
  @override
  Future<void> runForegroundCycle({Duration budget = const Duration(seconds: 25)}) async =>
      calls.add('runForegroundCycle');

  /// Messages the fake "applies" a rule to (returned as the count).
  int applyRuleCount = 0;
  @override
  Future<int> applyRuleToInbox(String ruleId) async {
    calls.add('applyRuleToInbox:$ruleId');
    return applyRuleCount;
  }

  @override
  Future<int> applyRulesToInbox() async {
    calls.add('applyRulesToInbox');
    return applyRuleCount;
  }
}

/// In-memory rule advisor: pending suggestions live in a list; accept /
/// dismiss just move them out and record the call.
class FakeRuleAdvisor implements RuleAdvisorApi {
  FakeRuleAdvisor({List<RuleSuggestion> pending = const [], this.runResult = const AdvisorRun(patternSuggestions: 1, modelSuggestions: 1, costUsd: 0.004, modelRan: true)})
      : _pending = List.of(pending);

  List<RuleSuggestion> _pending;
  AdvisorRun runResult;
  final calls = <String>[];
  final accepted = <(String, Map<String, dynamic>?, String?)>[];
  final _ctrl = StreamController<List<RuleSuggestion>>.broadcast();

  List<RuleSuggestion> get pendingList => List.unmodifiable(_pending);

  void setPending(List<RuleSuggestion> list) {
    _pending = List.of(list);
    _ctrl.add(List.of(_pending));
  }

  @override
  Stream<List<RuleSuggestion>> watchPending(String accountId) async* {
    yield List.of(_pending);
    yield* _ctrl.stream;
  }

  @override
  Future<AdvisorRun> runNow(String accountId, {bool force = true}) async {
    calls.add('runNow:$accountId:$force');
    return runResult;
  }

  @override
  Future<String> accept(String suggestionId, {Map<String, dynamic>? match, String? folderPath}) async {
    calls.add('accept:$suggestionId');
    accepted.add((suggestionId, match, folderPath));
    setPending(_pending.where((s) => s.id != suggestionId).toList());
    return 'rule-$suggestionId';
  }

  @override
  Future<void> dismiss(String suggestionId) async {
    calls.add('dismiss:$suggestionId');
    setPending(_pending.where((s) => s.id != suggestionId).toList());
  }
}
