import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import '../../core/clock.dart';
import '../../core/hashing.dart' show sha256Hex;
import '../../data/coordination/imap_control_folder.dart';
import '../../data/mail/imap_gateway.dart' show ImapGatewayException;
import '../../data/local/database.dart' show SortieDatabase;
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/services.dart';
import '../sorter/user_rules.dart' show SortRule;
import 'journal_store.dart';
import 'leader_loop.dart';
import 'lease_manager.dart';
import 'presence_manager.dart';
import 'read_guard.dart';
import 'server_clock.dart';
import 'shared_config_sync.dart';
import 'sort_journal.dart';
import 'sort_log.dart';
import 'user_actions.dart';

export 'lease_manager.dart' show LeaseTimers;
export 'shared_config_sync.dart' show SharedConfigDeps, SharedConfigSyncEvent;

/// One per account. Implements docs/coordination-protocol.md:
/// Connecting -> Syncing -> Follower | Candidate -> Leader -> Yielding.
class CoordinationService implements SortCoordinator {
  CoordinationService({
    required this.accountId,
    required DeviceIdentity me,
    required ImapGatewayFactory gatewayFactory,
    required Future<String> Function() password,
    required Account Function() account,
    required MailSyncService sync,
    required MessageClassifier classifier,
    required MessageRepository messages,
    required SettingsRepository settings,
    required SortieDatabase db,
    required Clock clock,
    this.timers = const LeaseTimers(),
    bool Function()? mayLead,
    SharedConfigDeps? sharedConfig,
    Future<void> Function(String accountId)? advisor,
  })  : _me = me,
        _factory = gatewayFactory,
        _password = password,
        _account = account,
        _sync = sync,
        _classifier = classifier,
        _messages = messages,
        _settings = settings,
        _clock = clock,
        _mayLead = mayLead ?? (() => true),
        _advisorHook = advisor,
        _sharedDeps = sharedConfig,
        _serverClock = ServerClock(clock),
        _guard = ReadGuard(timers: timers) {
    _shared = sharedConfig == null ? null : SharedConfigSync(accountId: accountId, deps: sharedConfig, clock: clock);
    _store = JournalStore(db: db, accountId: accountId, settings: settings, shared: _shared);
    _log = SortLogMapper(accountId: accountId, messages: messages, store: _store);
  }

  static final _logger = Logger('sortie.coordination');

  @override
  final String accountId;
  final LeaseTimers timers;
  final DeviceIdentity _me;
  final ImapGatewayFactory _factory;
  final Future<String> Function() _password;
  final Account Function() _account;
  final MailSyncService _sync;
  final MessageClassifier _classifier;
  final MessageRepository _messages;
  final SettingsRepository _settings;
  final Clock _clock;
  final bool Function() _mayLead;

  /// Rule advisor `maybeRun`, called by the leader loop after each batch.
  final Future<void> Function(String accountId)? _advisorHook;
  final SharedConfigDeps? _sharedDeps;
  final ServerClock _serverClock;
  final ReadGuard _guard;
  late final JournalStore _store;
  late final SortLogMapper _log;

  /// Cross-device config sections; null when built without [SharedConfigDeps].
  late final SharedConfigSync? _shared;

  // Per-connection components (null while disconnected).
  ImapControlFolder? _control;
  LeaseManager? _lease;
  PresenceManager? _presence;
  SortJournal? _journal;
  UserActions? _actions;
  LeaderLoop? _leader;
  bool _customKeywords = true;

  var _state = CoordinationState.stopped;
  final _stateCtrl = StreamController<CoordinationState>.broadcast();
  final _devicesCtrl = StreamController<List<SeenDevice>>.broadcast();
  List<SeenDevice> _devices = const [];
  int? _epoch;
  bool _running = false;
  int _generation = 0;
  Duration _reconnectDelay = Duration.zero;
  Future<void> _evalChain = Future.value();
  int _evalChainGen = -1;
  LeaseEvaluation? _lastEval;

  /// Set when the control folder came back empty (deleted / UIDVALIDITY
  /// reset); the next leader re-seeds a snapshot from its local view.
  bool _needsReseed = false;

  StreamSubscription<void>? _changesSub;
  StreamSubscription<List<SortRule>>? _rulesSub;
  Timer? _rulesDebounce;
  Timer? _changeDebounce;
  Timer? _heartbeat;
  Timer? _presenceTimer;
  Timer? _compactionTimer;
  Timer? _expiryTimer;

  ServerClock get serverClock => _serverClock;
  LeaseEvaluation? get lastEvaluation => _lastEval;
  ReadGuard get readGuard => _guard;
  SharedConfigSync? get sharedConfig => _shared;

  /// When a shared-config section was last applied here (null = never).
  Stream<DateTime?> get lastConfigSyncAt => configSyncEvents.map((e) => e?.at);
  Stream<SharedConfigSyncEvent?> get configSyncEvents => _shared?.events ?? Stream.value(null);

  // ------------------------------------------------------------- lifecycle

  @override
  CoordinationState get currentState => _state;
  @override
  Stream<CoordinationState> get state => _stateCtrl.stream;
  @override
  int? get epoch => _epoch;

  void _setState(CoordinationState s) {
    if (_state == s) return;
    _state = s;
    _logger.fine('${_me.shortId}: -> ${s.name}${_epoch != null ? ' (epoch $_epoch)' : ''}');
    if (!_stateCtrl.isClosed) _stateCtrl.add(s);
  }

  @override
  Future<void> start() async {
    if (_running) return;
    _running = true;
    unawaited(_connectLoop(++_generation));
  }

  @override
  Future<void> stop({bool graceful = true}) async {
    if (!_running) return;
    _running = false;
    final gen = ++_generation;
    await _teardown(release: graceful);
    if (gen == _generation) _setState(CoordinationState.stopped);
  }

  /// Upper bound for one connect + journal sync; a hang here used to leave
  /// the account silently unsorted until restart.
  static const connectBudget = Duration(minutes: 3);
  static const teardownBudget = Duration(seconds: 30);

  Future<void> _connectLoop(int gen) async {
    while (_running && gen == _generation) {
      try {
        await _connectAndSync(gen).timeout(connectBudget);
        _reconnectDelay = Duration.zero;
        _logger.info('${_me.shortId}: control connection up');
        return;
      } catch (e, st) {
        _logger.warning('${_me.shortId}: connect failed: $e', e, st);
        await _boundedTeardown(release: false);
        if (!_running || gen != _generation) return;
        _setState(CoordinationState.connecting);
        _reconnectDelay = _reconnectDelay == Duration.zero ? timers.reconnectDelay : _reconnectDelay * 2;
        if (_reconnectDelay > timers.reconnectDelayMax) _reconnectDelay = timers.reconnectDelayMax;
        await Future<void>.delayed(_reconnectDelay);
      }
    }
  }

  /// Runs one setup step, logging slow ones so a stall is attributable.
  Future<T> _step<T>(String name, Future<T> Function() fn) async {
    final sw = Stopwatch()..start();
    _logger.fine('${_me.shortId}: $name…');
    try {
      return await fn();
    } finally {
      if (sw.elapsed > const Duration(seconds: 5)) _logger.info('${_me.shortId}: $name took ${sw.elapsed.inSeconds}s');
    }
  }

  Future<void> _connectAndSync(int gen) async {
    _setState(CoordinationState.connecting);
    final sw = Stopwatch()..start();
    final password = await _step('password', () => _password().timeout(const Duration(seconds: 30)));
    final control = ImapControlFolder(gateway: _factory(), account: _account(), password: password, clock: _clock, pollFallback: timers.pollFallback);
    _control = control;
    await _step('connect', control.ensureExists);
    final caps = control.capabilities;
    _customKeywords = (caps?.customKeywords ?? true) && (_sync.capabilities(accountId)?.customKeywords ?? true);
    _lease = LeaseManager(folder: control, serverClock: _serverClock, me: _me, timers: timers);
    final journal = _journal = SortJournal(folder: control, store: _store, me: _me, serverClock: _serverClock, maxJournalMessages: timers.compactionMaxJournal, maxJournalAge: timers.compactionMaxAge);
    final presence = _presence = PresenceManager(folder: control, serverClock: _serverClock, me: _me, timers: timers, nextSeq: journal.nextSeq, mayLead: _mayLead);
    _actions = UserActions(
      accountId: accountId,
      me: _me,
      gatewayFactory: _factory,
      password: _password,
      account: _account,
      journal: journal,
      classifier: _classifier,
      messages: _messages,
      serverClock: _serverClock,
      customKeywords: () => _customKeywords,
    );
    _setState(CoordinationState.syncing);
    final first = await _step('fetch journal', control.fetchHeaders);
    final synced = await _step('sync journal (${first.length})', () => journal.sync(first, uidValidity: control.lastKnownUidValidity!));
    if (synced.reset && !first.any((m) => m.type == 'snapshot')) _needsReseed = true;
    await _step('presence', presence.publish);
    await _step('shared config', () async => _shared?.attach(_sectionAppender(gen, journal)));
    unawaited(_publishPendingConfig());
    _changesSub = control.changes().listen((_) => _onControlChange(gen), onError: (Object e) => _onConnectionError(gen, e));
    _presenceTimer = Timer.periodic(timers.presenceInterval, (_) => _guarded(gen, () => presence.publish()));
    _compactionTimer = Timer.periodic(timers.compactionCheck, (_) => _guarded(gen, () => _maintenance(gen)));
    await _step('evaluate', () => _evaluate(gen));
    _logger.info('${_me.shortId}: control setup done in ${sw.elapsed.inSeconds}s');
  }

  /// Appends a shared-config record, then folds it into the local view
  /// (own records are applied through the normal journal path).
  SectionAppender _sectionAppender(int gen, SortJournal journal) => (type, body) async {
        await journal.putSection(type, body);
        unawaited(_guarded(gen, () => _evaluate(gen)));
      };

  Future<void> _teardown({required bool release}) async {
    _shared?.detach();
    unawaited(_rulesSub?.cancel());
    _rulesSub = null;
    _rulesDebounce?.cancel();
    _changeDebounce?.cancel();
    _heartbeat?.cancel();
    _presenceTimer?.cancel();
    _compactionTimer?.cancel();
    _expiryTimer?.cancel();
    unawaited(_changesSub?.cancel());
    _changesSub = null;
    final leader = _leader;
    _leader = null;
    final epoch = _epoch;
    if (leader != null) {
      _setState(CoordinationState.yielding);
      await leader.stop();
      if (release && epoch != null) {
        try {
          await _lease?.release(epoch);
        } catch (e) {
          _logger.fine('release failed: $e');
        }
      }
    }
    _epoch = null;
    final control = _control;
    _control = null;
    _lease = null;
    _presence = null;
    _actions = null;
    _journal?.dispose();
    _journal = null;
    if (control != null) await control.dispose();
  }

  void _onConnectionError(int gen, Object e) {
    if (!_running || gen != _generation) return;
    _logger.warning('${_me.shortId}: control connection error: $e');
    final next = ++_generation;
    unawaited(_boundedTeardown(release: false).then((_) {
      _logger.info('${_me.shortId}: reconnecting control connection');
      return _connectLoop(next);
    }));
  }

  /// Teardown that cannot wedge the reconnect: a dead socket's logout or a
  /// stuck leader batch is abandoned after [teardownBudget].
  Future<void> _boundedTeardown({required bool release}) async {
    try {
      await _teardown(release: release).timeout(teardownBudget);
    } catch (e) {
      _logger.warning('${_me.shortId}: teardown incomplete: $e');
    }
  }

  /// Like [_guarded] but a failure is logged, never treated as a lost
  /// connection (used for best-effort work such as rule re-runs).
  Future<void> _guardedSoft(int gen, Future<void> Function() fn) async {
    if (!_running || gen != _generation) return;
    try {
      await fn();
    } catch (e) {
      if (e is ImapGatewayException && e.isConnectionLost) return _onConnectionError(gen, e);
      _logger.warning('${_me.shortId}: $e');
    }
  }

  Future<void> _guarded(int gen, Future<void> Function() fn) async {
    if (!_running || gen != _generation) return;
    try {
      await fn();
    } catch (e) {
      _onConnectionError(gen, e);
    }
  }

  // ------------------------------------------------------------ evaluation

  /// After the machine wakes from sleep: re-evaluate the lease (it may have
  /// expired) and, when leading, catch up on inbox mail that arrived
  /// meanwhile. A dead control socket surfaces here and reconnects.
  void onResume(Duration asleep) {
    if (!_running) return;
    final gen = _generation;
    _logger.info('${_me.shortId}: resumed after ${asleep.inMinutes}m asleep');
    unawaited(_guarded(gen, () => _evaluate(gen)));
    unawaited(_leader?.resume());
  }

  void _onControlChange(int gen) {
    _changeDebounce?.cancel();
    _changeDebounce = Timer(const Duration(milliseconds: 200), () => _guarded(gen, () => _evaluate(gen)));
  }

  /// Sync journal, refresh presences, evaluate the lease and act on it.
  Future<void> _evaluate(int gen) {
    if (gen != _evalChainGen) {
      // New connection: never queue behind an evaluation of a dead one.
      _evalChain = Future.value();
      _evalChainGen = gen;
    }
    final next = _evalChain.then((_) => _evaluateNow(gen));
    _evalChain = next.then((_) {}, onError: (_) {});
    return next;
  }

  Future<void> _evaluateNow(int gen) async {
    final control = _control;
    final lease = _lease;
    final journal = _journal;
    final presence = _presence;
    if (control == null || lease == null || journal == null || presence == null || gen != _generation) return;
    final uv = await _step('uidvalidity', control.uidValidity);
    final headers = await _step('fetch journal', control.fetchHeaders);
    final result = await _step('sync journal (${headers.length})', () => journal.sync(headers, uidValidity: uv));
    if (result.reset && !headers.any((m) => m.type == 'snapshot')) _needsReseed = true;
    await _step('presence refresh', () => presence.refresh(headers));
    final eval = lease.evaluate(headers);
    _lastEval = eval;
    _publishDevices(eval, presence);
    // Void claims of our own are deleted on the next evaluation (spec).
    final ownVoid = eval.voidClaims.where((c) => c.deviceId == _me.deviceId).map((c) => c.uid).toList();
    if (ownVoid.isNotEmpty) await _step('expunge void claims', () => control.expunge(ownVoid));
    final myEpoch = _epoch;
    if (myEpoch != null) {
      // Leading (possibly still in the handoff wait before the loop starts).
      if (!eval.isHeldBy(_me.deviceId, myEpoch)) {
        _logger.warning('${_me.shortId}: lost lease for epoch $myEpoch to ${eval.activeLease}');
        await _demote(gen);
        await _decide(gen, eval);
      } else {
        _leader?.scheduleEvaluate();
      }
      return;
    }
    if (_state == CoordinationState.candidate || _state == CoordinationState.yielding) return;
    await _decide(gen, eval);
  }

  Future<void> _decide(int gen, LeaseEvaluation eval) async {
    final lease = _lease;
    if (lease == null || gen != _generation) return;
    final active = eval.activeLease;
    final wantLead = _mayLead() && _serverClock.primed && (active == null || lease.shouldPreempt(eval));
    if (wantLead) {
      // Runs outside the evaluation chain: claiming and leading re-enter
      // _evaluate themselves and must not wait on this evaluation.
      final fast = active == null && _nobodyHome(eval);
      _setState(CoordinationState.candidate);
      unawaited(_becomeCandidate(gen, skipBackoff: fast, handoff: !fast));
      return;
    }
    _setState(CoordinationState.follower);
    _expiryTimer?.cancel();
    if (active != null) {
      final wait = _serverClock.untilExpiry(active.lastBeatAt, timers.leaseTTL) + const Duration(seconds: 1);
      _expiryTimer = Timer(wait, () => _guarded(gen, () => _evaluate(gen)));
    }
  }

  /// The previous leader is gone for good: its lease was released, or it
  /// stopped beating more than two TTLs ago, and no higher-priority device
  /// is present. Then the claim backoff and the handoff wait only delay the
  /// takeover; a phone opened for half a minute never got to sort at all.
  /// A cold start with no lease history keeps the backoff (simultaneous
  /// starts still need it to spread their claims).
  bool _nobodyHome(LeaseEvaluation eval) {
    final newest = eval.holders[eval.epochMax];
    if (newest == null) return false;
    final presence = _presence;
    if (presence != null && presence.fresh(eval.serverNow).any((p) => p.info.priority > _me.priority)) return false;
    if (newest.released) return true;
    return newest.lastBeatAt.isBefore(eval.serverNow.subtract(timers.leaseTTL * 2));
  }

  Future<void> _becomeCandidate(int gen, {bool skipBackoff = false, bool handoff = true}) async {
    final lease = _lease;
    if (lease == null) return;
    _setState(CoordinationState.candidate);
    ClaimResult r;
    try {
      r = await lease.tryClaim(skipBackoff: skipBackoff);
    } catch (e) {
      _onConnectionError(gen, e);
      return;
    }
    if (gen != _generation || !_running) return;
    if (r.won) {
      try {
        await _becomeLeader(gen, r.epoch!, handoff: handoff);
      } catch (e) {
        _onConnectionError(gen, e);
      }
    } else {
      _setState(CoordinationState.follower);
      final e = r.evaluation;
      if (e != null) await _decide(gen, e);
    }
  }

  Future<void> _becomeLeader(int gen, int epoch, {bool handoff = true}) async {
    _epoch = epoch;
    _setState(CoordinationState.leader);
    if (handoff && timers.handoffWait > Duration.zero) await Future<void>.delayed(timers.handoffWait);
    if (gen != _generation || !_running || _epoch != epoch) return;
    final lease = _lease!;
    final journal = _journal!;
    final presence = _presence!;
    final ops = _factory();
    await ops.connect(_account(), await _password());
    final loop = LeaderLoop(
      accountId: accountId,
      me: _me,
      epoch: epoch,
      ops: ops,
      sync: _sync,
      classifier: _classifier,
      messages: _messages,
      journal: journal,
      guard: _guard,
      presence: presence,
      lease: lease,
      serverClock: _serverClock,
      timers: timers,
      customKeywords: _customKeywords,
      afterClassify: _advisorHook,
      resync: () => _evaluate(gen),
      onFatal: (e) => e is LeaseLostException ? _guarded(gen, () => _evaluate(gen)) : _onConnectionError(gen, e),
    );
    _leader = loop;
    _heartbeat = Timer.periodic(timers.heartbeat, (_) => _guarded(gen, () => lease.heartbeat(epoch)));
    await loop.start();
    // Local edits, imports and journal-applied rule sets all surface on the
    // store's watch (own journal records are echo-suppressed, so events
    // alone would miss local changes).
    unawaited(_rulesSub?.cancel());
    _rulesSub = _sharedDeps?.rules.watch(accountId).listen((_) {
      _rulesDebounce?.cancel();
      _rulesDebounce = Timer(const Duration(seconds: 1), () => unawaited(_guardedSoft(gen, () => _applyRulesIfChanged(gen))));
    }, onError: (Object e) => _logger.fine('rules watch: $e'));
    unawaited(_guardedSoft(gen, () => _applyRulesIfChanged(gen)));
    if (_needsReseed && gen == _generation) {
      _needsReseed = false;
      final control = _control!;
      if ((await _store.openDecisions()).isNotEmpty || (await _store.events()).isNotEmpty) {
        if (await lease.fence(epoch)) await journal.compact(await control.fetchHeaders(), lastEpoch: epoch, force: true);
      }
    }
  }

  /// Lost the lease (preempted or expired under us): stop moving, release
  /// the old epoch so followers need not wait for it to age out.
  Future<void> _demote(int gen) async {
    _heartbeat?.cancel();
    final leader = _leader;
    final epoch = _epoch;
    _leader = null;
    _epoch = null;
    _setState(CoordinationState.yielding);
    if (leader != null) await leader.stop();
    if (epoch != null) {
      try {
        await _lease?.release(epoch);
      } catch (e) {
        _logger.fine('release after demotion failed: $e');
      }
    }
    _setState(CoordinationState.follower);
  }

  /// Hourly: compaction (leader) and stale-record cleanup.
  Future<void> _maintenance(int gen) async {
    final control = _control;
    final lease = _lease;
    final journal = _journal;
    if (control == null || lease == null || journal == null) return;
    final headers = await control.fetchHeaders();
    final eval = lease.evaluate(headers);
    await lease.cleanupStale(headers, eval);
    final epoch = _epoch;
    if (_leader != null && epoch != null && journal.needsCompaction(headers, eval.serverNow)) {
      if (await lease.fence(epoch)) await journal.compact(headers, lastEpoch: epoch);
    }
  }

  /// Forces the hourly maintenance pass now (tests, diagnostics).
  Future<void> runMaintenance() => _maintenance(_generation);

  void _publishDevices(LeaseEvaluation eval, PresenceManager presence) {
    final now = eval.serverNow;
    final leaderId = eval.activeLease?.deviceId;
    final list = <SeenDevice>[
      SeenDevice(deviceId: _me.deviceId, displayName: _me.displayName, platform: _me.platform.name, priority: _me.priority, lastSeen: now, isLeader: leaderId == _me.deviceId, isThisDevice: true),
      for (final p in presence.fresh(now))
        SeenDevice(deviceId: p.deviceId, displayName: p.info.name, platform: p.info.platform, priority: p.info.priority, lastSeen: p.internalDate, isLeader: leaderId == p.deviceId, isThisDevice: false),
    ];
    final a = eval.activeLease;
    if (a != null && !list.any((d) => d.deviceId == a.deviceId)) {
      list.add(SeenDevice(deviceId: a.deviceId, displayName: a.deviceId, platform: 'other', priority: a.priority, lastSeen: a.lastBeatAt, isLeader: true, isThisDevice: false));
    }
    _devices = list;
    if (!_devicesCtrl.isClosed) _devicesCtrl.add(list);
  }

  // --------------------------------------------------------------- streams

  @override
  Stream<Map<MessageKey, PendingBadge>> watchPending() => _store.watchOpenDecisions().map((ds) => {
        for (final d in ds)
          d.key: PendingBadge(key: d.key, destination: d.destination, confidence: d.confidence, reason: d.reason, mode: d.mode, decisionId: d.id, layer: d.layer),
      });

  @override
  Stream<List<SortLogEntry>> watchLog({int limit = 200}) => _store.watchEvents(limit: limit).asyncMap(_log.map);

  @override
  Stream<List<SeenDevice>> watchDevices() async* {
    yield _devices;
    yield* _devicesCtrl.stream;
  }

  @override
  Stream<SortConfig> watchConfig() => _settings.watchSortConfig(accountId);

  @override
  /// Saves locally right away. Publishing goes through a serial queue with a
  /// timeout; when the control folder is not connected (or the append fails)
  /// the latest config is kept pending and published on the next connect.
  Future<void> putConfig(SortConfig c) async {
    await _settings.saveSortConfig(accountId, c);
    _pendingConfig = c;
    if (_journal == null) return;
    final run = _configChain = _configChain.then((_) => _publishConfig(c));
    try {
      await run.timeout(const Duration(seconds: 25));
    } catch (e) {
      _logger.fine('config publish still pending: $e');
    }
  }

  SortConfig? _pendingConfig;
  Future<void> _configChain = Future.value();

  Future<void> _publishConfig(SortConfig c) async {
    final j = _journal;
    if (j == null) return;
    try {
      await j.putConfig(c).timeout(const Duration(seconds: 20));
      if (identical(_pendingConfig, c)) _pendingConfig = null;
      await _evaluate(_generation);
    } catch (e) {
      _logger.fine('config publish deferred until the control folder reconnects: $e');
    }
  }

  /// Called after each successful connect+sync.
  Future<void> _publishPendingConfig() async {
    final c = _pendingConfig;
    if (c == null) return;
    _configChain = _configChain.then((_) => _publishConfig(c));
    await _configChain;
  }

  // ---------------------------------------------------------- user actions

  /// Runs a user action over a fresh ops connection, then applies our own
  /// journal records right away and lets the leader loop re-evaluate.
  Future<void> _act(Future<void> Function(UserActions a) f) async {
    final actions = _actions ?? (throw StateError('coordinator not connected'));
    await f(actions);
    if (_control != null) await _evaluate(_generation);
    _leader?.scheduleEvaluate(Duration.zero);
  }

  @override
  Future<void> undo(String decisionId) => _act((a) => a.undo(decisionId));
  @override
  Future<void> moveNow(MessageKey key) => _act((a) => a.moveNow(key));
  @override
  Future<void> keepInInbox(MessageKey key) => _act((a) => a.keepInInbox(key));
  @override
  Future<void> changeDestination(MessageKey key, String folderPath) => _act((a) => a.changeDestination(key, folderPath));
  @override
  Future<void> markRight(MessageKey key) => _act((a) => a.markRight(key));

  @override
  Future<int> applyRuleToInbox(String ruleId) async {
    final leader = _leader;
    final deps = _sharedDeps;
    if (leader == null || deps == null) return 0;
    final rule = (await deps.rules.load(accountId)).where((r) => r.id == ruleId).firstOrNull;
    if (rule == null || !rule.enabled) return 0;
    return leader.classifyMatching([rule]);
  }

  @override
  Future<int> applyRulesToInbox() async {
    final leader = _leader;
    final deps = _sharedDeps;
    if (leader == null || deps == null) return 0;
    final rules = (await deps.rules.load(accountId)).where((r) => r.enabled).toList();
    if (rules.isEmpty) return 0;
    final n = await leader.classifyMatching(rules);
    await _settings.setString(_rulesAppliedKey, _rulesFingerprint(rules));
    return n;
  }

  String get _rulesAppliedKey => 'rulesApplied.$accountId';

  /// Enabled rules only, in evaluation order; `hits` is excluded by toJson.
  static String _rulesFingerprint(List<SortRule> rules) =>
      sha256Hex(jsonEncode([for (final r in rules) r.toJson()]));

  /// Re-runs the rules over the inbox when the enabled set differs from the
  /// one last applied on this device (import, edit, or a change that arrived
  /// through the journal). Rule matching is local, so this costs no AI calls.
  Future<void> _applyRulesIfChanged(int gen) async {
    final deps = _sharedDeps;
    if (deps == null || _leader == null) return;
    final rules = (await deps.rules.load(accountId)).where((r) => r.enabled).toList();
    final fp = _rulesFingerprint(rules);
    if (await _settings.getString(_rulesAppliedKey) == fp) return;
    if (gen != _generation || _leader == null) return;
    final n = rules.isEmpty ? 0 : await _leader!.classifyMatching(rules);
    await _settings.setString(_rulesAppliedKey, fp);
    _logger.info('${_me.shortId}: rule set changed, $n inbox message(s) re-queued');
  }

  @override
  void onMessageOpened(MessageKey key) {
    _guard.onLocalOpen(key.messageIdHash);
    final p = _presence;
    if (p != null && p.onOpen(key)) unawaited(_guarded(_generation, p.publish));
  }

  @override
  void onMessageClosed(MessageKey key) {
    final now = _serverClock.nowOrNull();
    if (now != null) _guard.onLocalClose(key.messageIdHash, now);
    final p = _presence;
    if (p != null && p.onClose(key)) unawaited(_guarded(_generation, p.publish));
    _leader?.scheduleEvaluate(Duration.zero);
  }

  // ------------------------------------------------------- bounded cycle

  /// iOS BGAppRefresh / WorkManager: connect, sync, evaluate, claim if
  /// allowed and no higher-priority device is present, sort one batch,
  /// release. Never runs while [start] is active.
  @override
  Future<void> runForegroundCycle({Duration budget = const Duration(seconds: 25)}) async {
    if (_running) return;
    final cycle = _CycleRunner(this, timers.forBoundedCycle(budget));
    try {
      await cycle.run().timeout(budget);
    } on TimeoutException {
      _logger.warning('${_me.shortId}: bounded cycle hit its budget');
    } finally {
      await cycle.finish();
    }
  }

  Future<void> dispose() async {
    await stop();
    await _shared?.dispose();
    await _stateCtrl.close();
    await _devicesCtrl.close();
  }
}

class _CycleRunner {
  _CycleRunner(this.s, this.t);
  final CoordinationService s;
  final LeaseTimers t;
  int? epoch;

  Future<void> run() async {
    s._running = true;
    final gen = ++s._generation;
    s._setState(CoordinationState.connecting);
    final control = ImapControlFolder(gateway: s._factory(), account: s._account(), password: await s._password(), clock: s._clock);
    s._control = control;
    await control.ensureExists();
    s._customKeywords = control.capabilities?.customKeywords ?? true;
    final lease = s._lease = LeaseManager(folder: control, serverClock: s._serverClock, me: s._me, timers: t);
    final journal = s._journal = SortJournal(folder: control, store: s._store, me: s._me, serverClock: s._serverClock);
    final presence = s._presence = PresenceManager(folder: control, serverClock: s._serverClock, me: s._me, timers: t, nextSeq: journal.nextSeq, mayLead: s._mayLead);
    s._setState(CoordinationState.syncing);
    var headers = await control.fetchHeaders();
    await journal.sync(headers, uidValidity: control.lastKnownUidValidity!);
    await presence.publish();
    await s._shared?.attach(s._sectionAppender(gen, journal));
    headers = await control.fetchHeaders();
    await presence.refresh(headers);
    final eval = lease.evaluate(headers);
    s._lastEval = eval;
    s._publishDevices(eval, presence);
    final higherPresent = presence.fresh(eval.serverNow).any((p) => p.info.priority > s._me.priority);
    final active = eval.activeLease;
    if (!s._mayLead() || higherPresent || (active != null && !lease.shouldPreempt(eval))) {
      s._setState(CoordinationState.follower);
      return;
    }
    s._setState(CoordinationState.candidate);
    final r = await lease.tryClaim(skipBackoff: true);
    if (!r.won) {
      s._setState(CoordinationState.follower);
      return;
    }
    epoch = r.epoch;
    await s._becomeLeader(gen, r.epoch!, handoff: false);
    await s._leader!.runOnce();
  }

  Future<void> finish() async {
    final leader = s._leader;
    s._leader = null;
    s._heartbeat?.cancel();
    if (leader != null) {
      s._setState(CoordinationState.yielding);
      await leader.stop();
      final e = epoch;
      if (e != null) {
        try {
          await s._lease?.release(e);
        } catch (_) {}
      }
    }
    s._epoch = null;
    s._running = false;
    s._shared?.detach();
    final control = s._control;
    s._control = null;
    s._lease = null;
    s._presence = null;
    s._journal?.dispose();
    s._journal = null;
    if (control != null) await control.dispose();
    s._setState(CoordinationState.stopped);
  }
}
