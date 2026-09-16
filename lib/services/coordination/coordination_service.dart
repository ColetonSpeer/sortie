import 'dart:async';

import 'package:logging/logging.dart';

import '../../core/clock.dart';
import '../../data/coordination/imap_control_folder.dart';
import '../../data/local/database.dart' show SortieDatabase;
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/services.dart';
import 'journal_store.dart';
import 'leader_loop.dart';
import 'lease_manager.dart';
import 'presence_manager.dart';
import 'read_guard.dart';
import 'server_clock.dart';
import 'sort_journal.dart';
import 'sort_log.dart';
import 'user_actions.dart';

export 'lease_manager.dart' show LeaseTimers;

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
        _serverClock = ServerClock(clock),
        _store = JournalStore(db: db, accountId: accountId, settings: settings),
        _guard = ReadGuard(timers: timers) {
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
  final ServerClock _serverClock;
  final JournalStore _store;
  final ReadGuard _guard;
  late final SortLogMapper _log;

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
  LeaseEvaluation? _lastEval;

  /// Set when the control folder came back empty (deleted / UIDVALIDITY
  /// reset); the next leader re-seeds a snapshot from its local view.
  bool _needsReseed = false;

  StreamSubscription<void>? _changesSub;
  Timer? _changeDebounce;
  Timer? _heartbeat;
  Timer? _presenceTimer;
  Timer? _compactionTimer;
  Timer? _expiryTimer;

  ServerClock get serverClock => _serverClock;
  LeaseEvaluation? get lastEvaluation => _lastEval;
  ReadGuard get readGuard => _guard;

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

  Future<void> _connectLoop(int gen) async {
    while (_running && gen == _generation) {
      try {
        await _connectAndSync(gen);
        _reconnectDelay = Duration.zero;
        return;
      } catch (e, st) {
        _logger.warning('${_me.shortId}: connect failed: $e', e, st);
        await _teardown(release: false);
        if (!_running || gen != _generation) return;
        _setState(CoordinationState.connecting);
        _reconnectDelay = _reconnectDelay == Duration.zero ? timers.reconnectDelay : _reconnectDelay * 2;
        if (_reconnectDelay > timers.reconnectDelayMax) _reconnectDelay = timers.reconnectDelayMax;
        await Future<void>.delayed(_reconnectDelay);
      }
    }
  }

  Future<void> _connectAndSync(int gen) async {
    _setState(CoordinationState.connecting);
    final control = ImapControlFolder(gateway: _factory(), account: _account(), password: await _password(), clock: _clock, pollFallback: timers.pollFallback);
    _control = control;
    await control.ensureExists();
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
    final first = await control.fetchHeaders();
    final synced = await journal.sync(first, uidValidity: control.lastKnownUidValidity!);
    if (synced.reset && !first.any((m) => m.type == 'snapshot')) _needsReseed = true;
    await presence.publish();
    _changesSub = control.changes().listen((_) => _onControlChange(gen), onError: (Object e) => _onConnectionError(gen, e));
    _presenceTimer = Timer.periodic(timers.presenceInterval, (_) => _guarded(gen, () => presence.publish()));
    _compactionTimer = Timer.periodic(timers.compactionCheck, (_) => _guarded(gen, () => _maintenance(gen)));
    await _evaluate(gen);
  }

  Future<void> _teardown({required bool release}) async {
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
    unawaited(_teardown(release: false).then((_) => _connectLoop(next)));
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

  void _onControlChange(int gen) {
    _changeDebounce?.cancel();
    _changeDebounce = Timer(const Duration(milliseconds: 200), () => _guarded(gen, () => _evaluate(gen)));
  }

  /// Sync journal, refresh presences, evaluate the lease and act on it.
  Future<void> _evaluate(int gen) {
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
    final uv = await control.uidValidity();
    final headers = await control.fetchHeaders();
    final result = await journal.sync(headers, uidValidity: uv);
    if (result.reset && !headers.any((m) => m.type == 'snapshot')) _needsReseed = true;
    await presence.refresh(headers);
    final eval = lease.evaluate(headers);
    _lastEval = eval;
    _publishDevices(eval, presence);
    // Void claims of our own are deleted on the next evaluation (spec).
    final ownVoid = eval.voidClaims.where((c) => c.deviceId == _me.deviceId).map((c) => c.uid).toList();
    if (ownVoid.isNotEmpty) await control.expunge(ownVoid);
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
      _setState(CoordinationState.candidate);
      unawaited(_becomeCandidate(gen));
      return;
    }
    _setState(CoordinationState.follower);
    _expiryTimer?.cancel();
    if (active != null) {
      final wait = _serverClock.untilExpiry(active.lastBeatAt, timers.leaseTTL) + const Duration(seconds: 1);
      _expiryTimer = Timer(wait, () => _guarded(gen, () => _evaluate(gen)));
    }
  }

  Future<void> _becomeCandidate(int gen, {bool skipBackoff = false}) async {
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
        await _becomeLeader(gen, r.epoch!);
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
      resync: () => _evaluate(gen),
      onFatal: (e) => e is LeaseLostException ? _guarded(gen, () => _evaluate(gen)) : _onConnectionError(gen, e),
    );
    _leader = loop;
    _heartbeat = Timer.periodic(timers.heartbeat, (_) => _guarded(gen, () => lease.heartbeat(epoch)));
    await loop.start();
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
  Future<void> putConfig(SortConfig c) async {
    await _settings.saveSortConfig(accountId, c);
    final j = _journal;
    if (j == null) return;
    await j.putConfig(c);
    await _evaluate(_generation);
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
