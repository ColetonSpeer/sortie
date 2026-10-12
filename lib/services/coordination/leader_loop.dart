import 'dart:async';

import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../../data/mail/imap_gateway.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/services.dart';
import 'lease_manager.dart';
import 'presence_manager.dart';
import 'read_guard.dart';
import 'server_clock.dart';
import 'sort_journal.dart';

/// Thrown by [LeaderLoop] when a fence shows we no longer hold the lease.
class LeaseLostException implements Exception {
  const LeaseLostException(this.epoch);
  final int epoch;
  @override
  String toString() => 'LeaseLostException(epoch $epoch)';
}

/// The leader's INBOX side: classify new mail, journal decisions, execute
/// fenced batches of moves once the read-guard clears.
class LeaderLoop {
  LeaderLoop({
    required this.accountId,
    required this.me,
    required this.epoch,
    required ImapGateway ops,
    required MailSyncService sync,
    required MessageClassifier classifier,
    required MessageRepository messages,
    required SortJournal journal,
    required ReadGuard guard,
    required PresenceManager presence,
    required LeaseManager lease,
    required ServerClock serverClock,
    required LeaseTimers timers,
    required this.customKeywords,
    required Future<void> Function() resync,
    required void Function(Object error) onFatal,
    Future<void> Function(String accountId)? afterClassify,
    this.advisorInterval = const Duration(hours: 24),
  })  : _ops = ops,
        _sync = sync,
        _classifier = classifier,
        _messages = messages,
        _journal = journal,
        _guard = guard,
        _presence = presence,
        _lease = lease,
        _clock = serverClock,
        _timers = timers,
        _resync = resync,
        _onFatal = onFatal,
        _afterClassify = afterClassify;

  static final _log = Logger('sortie.coordination.leader');
  static const inbox = 'INBOX';

  final String accountId;
  final DeviceIdentity me;
  final int epoch;
  final bool customKeywords;
  final ImapGateway _ops;
  final MailSyncService _sync;
  final MessageClassifier _classifier;
  final MessageRepository _messages;
  final SortJournal _journal;
  final ReadGuard _guard;
  final PresenceManager _presence;
  final LeaseManager _lease;
  final ServerClock _clock;
  final LeaseTimers _timers;
  final Future<void> Function() _resync;
  final void Function(Object) _onFatal;

  /// Rule-advisor hook: runs after every classify batch and on a daily timer.
  final Future<void> Function(String accountId)? _afterClassify;
  final Duration advisorInterval;

  final _subs = <StreamSubscription<Object?>>[];
  final _newBuffer = <MessageHeader>[];
  Timer? _classifyTimer;
  Timer? _evalTimer;
  Timer? _retryTimer;
  Timer? _pollTimer;
  Timer? _advisorTimer;
  Future<void> _chain = Future.value();
  bool _stopped = false;
  int moves = 0;

  /// Serializes classify / evaluate so batches never interleave.
  Future<T> _serial<T>(Future<T> Function() fn) {
    final next = _chain.then((_) => _stopped ? Future<T>.error(StateError('leader loop stopped')) : fn());
    _chain = next.then((_) {}, onError: (_) {});
    return next;
  }

  Future<void> start() async {
    _subs.add(_sync.newInboxMessages(accountId).listen((hs) {
      _newBuffer.addAll(hs.where((h) => h.folderPath == inbox));
      _classifyTimer?.cancel();
      _classifyTimer = Timer(const Duration(seconds: 1), () => _serial(_flushNew).then((_) {}, onError: _fatal));
    }));
    _subs.add(_sync.flagChanges(accountId).listen((f) {
      if (f.folderPath != inbox) return;
      if (f.header.isSeen) {
        final now = _clock.nowOrNull();
        if (now != null) _guard.observeSeen(f.header.messageIdHash, now);
      }
      scheduleEvaluate();
    }));
    // Externally moved / deleted pending mail produces no flag event, so
    // re-check on the poll interval as well.
    _pollTimer = Timer.periodic(_timers.pollFallback, (_) => scheduleEvaluate(Duration.zero));
    if (_afterClassify != null) _advisorTimer = Timer.periodic(advisorInterval, (_) => _serial(_runAdvisor).then((_) {}, onError: (_) {}));
    await _serial(reconcile).then((_) {}, onError: _fatal);
  }

  /// Never fatal: a failing advisor must not cost the lease.
  Future<void> _runAdvisor() async {
    final hook = _afterClassify;
    if (hook == null || _stopped) return;
    try {
      await hook(accountId);
    } catch (e, st) {
      _log.warning('rule advisor failed', e, st);
    }
  }

  Future<void> stop() async {
    _stopped = true;
    _classifyTimer?.cancel();
    _evalTimer?.cancel();
    _retryTimer?.cancel();
    _pollTimer?.cancel();
    _advisorTimer?.cancel();
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
    try {
      await _chain.timeout(_timers.yieldBatchLimit);
    } catch (_) {}
    try {
      if (_ops.isConnected) await _ops.disconnect();
    } catch (_) {}
  }

  void _fatal(Object e) {
    if (_stopped) return;
    _log.warning('leader loop error: $e');
    _onFatal(e);
  }

  void scheduleEvaluate([Duration delay = const Duration(milliseconds: 300)]) {
    if (_stopped) return;
    _evalTimer?.cancel();
    _evalTimer = Timer(delay, () => _serial(evaluatePending).then((_) {}, onError: _fatal));
  }

  /// Runs one classify + evaluate pass to completion (bounded cycles).
  Future<int> runOnce() => _serial(() async {
        await _flushNew();
        return evaluatePending();
      });

  // ------------------------------------------------------------- reconcile

  /// Takeover: `$SortiePending` messages are the second source of truth,
  /// `$SortieDone` back in INBOX is a weak correction, and already-seen
  /// pending mail starts its grace period now.
  Future<void> reconcile() async {
    await _ops.select(inbox);
    final now = _clock.now();
    final open = await _journal.store.openDecisions();
    if (customKeywords) {
      final pendingUids = await _ops.searchKeyword(SortieKeywords.pending);
      final headers = pendingUids.isEmpty ? <MessageHeader>[] : await _ops.fetchHeadersByUids(pendingUids);
      final unknown = <MessageHeader>[];
      for (final h in headers) {
        if (h.isSeen) _guard.observeSeen(h.messageIdHash, now);
        if (!await _journal.store.hasAnyDecision(h.messageIdHash)) unknown.add(h);
      }
      if (unknown.isNotEmpty) await _classify(unknown);
      final doneUids = await _ops.searchKeyword(SortieKeywords.done);
      for (final h in doneUids.isEmpty ? <MessageHeader>[] : await _ops.fetchHeadersByUids(doneUids)) {
        final d = await _journal.store.decisionForMid(h.messageIdHash);
        if (d == null || (d.status != DecisionStatus.applied && d.status != DecisionStatus.accepted)) continue;
        final c = _correction(CorrectionKind.externalMove, h, predicted: d.destination, actual: inbox, decisionId: d.id, weight: 0.5);
        await _journal.recordCorrection(c);
        await _classifier.recordCorrection(c);
      }
    }
    for (final d in open) {
      final uid = d.key.uid;
      if (uid == null) continue;
      final hs = await _ops.fetchHeadersByUids([uid]);
      if (hs.isNotEmpty && hs.first.messageIdHash == d.key.messageIdHash && hs.first.isSeen) _guard.observeSeen(d.key.messageIdHash, now);
    }
    final config = await _journal.store.config();
    final enabledAt = config.enabledAt;
    if (enabledAt != null && config.mode != SortingMode.off) {
      final recent = await _messages.list(MessageQuery(accountId: accountId, folderPath: inbox, limit: 200));
      final fresh = <MessageHeader>[];
      for (final h in recent) {
        if (h.date.isBefore(enabledAt) || h.hasSortieDone || h.hasSortiePending) continue;
        if (await _journal.store.hasAnyDecision(h.messageIdHash)) continue;
        fresh.add(h);
      }
      if (fresh.isNotEmpty) await _classify(fresh);
    }
    await _resync();
    scheduleEvaluate(Duration.zero);
  }

  // -------------------------------------------------------------- classify

  Future<void> _flushNew() async {
    if (_newBuffer.isEmpty) return;
    final batch = _newBuffer.toList();
    _newBuffer.clear();
    await _classify(batch);
    await _resync();
    scheduleEvaluate(Duration.zero);
  }

  /// Body text for rules (`body contains …`) and the model layer. Uses the
  /// local cache and fetches small messages once; failures just mean no body.
  Future<String?> _bodyTextFor(MessageHeader h) async {
    try {
      final cached = await _messages.cachedBody(accountId, h.messageIdHash);
      if (cached != null) return cached.text;
      if (h.size > 512 * 1024) return null;
      final body = await _sync.body(accountId, h.folderPath, h.uid).timeout(const Duration(seconds: 20));
      return body.text;
    } catch (_) {
      return null;
    }
  }

  /// Re-runs the classifier over the INBOX messages [test] selects (a newly
  /// accepted rule). Earlier `kept` / `suggested` decisions are resolved
  /// first so the normal path takes them again; pending ones are left alone.
  Future<int> classifyMatching(bool Function(MessageHeader) test) => _serial(() async {
        final recent = await _messages.list(MessageQuery(accountId: accountId, folderPath: inbox, limit: 500));
        final hits = <MessageHeader>[];
        for (final h in recent) {
          if (h.hasSortieDone || !test(h)) continue;
          final d = await _journal.store.decisionForMid(h.messageIdHash);
          if (d != null && (d.status == DecisionStatus.pending || d.status == DecisionStatus.applied || d.status == DecisionStatus.accepted)) continue;
          if (d != null) await _journal.store.setDecisionStatus(d.id, DecisionStatus.resolved);
          hits.add(h);
        }
        if (hits.isEmpty) return 0;
        await _classify(hits, reclassify: true);
        await _resync();
        scheduleEvaluate(Duration.zero);
        return hits.length;
      });

  Future<void> _classify(List<MessageHeader> headers, {bool reclassify = false}) async {
    final config = await _journal.store.config();
    if (config.mode == SortingMode.off) return;
    final inputs = <ClassificationInput>[];
    final seen = <String>{};
    for (final h in headers) {
      if (h.hasSortieDone || !seen.add(h.messageIdHash)) continue;
      if (!reclassify && await _journal.store.hasAnyDecision(h.messageIdHash)) continue;
      inputs.add(ClassificationInput(header: h, bodyText: await _bodyTextFor(h)));
    }
    if (inputs.isEmpty) return;
    final raw = await _classifier.classify(accountId, inputs, config);
    final decisions = <SortDecision>[];
    for (final d in raw) {
      DecisionStatus status;
      var mode = d.mode;
      if (d.isKeep) {
        status = DecisionStatus.kept;
        mode = SortMode.keep;
      } else if ((config.mode == SortingMode.suggestOnly && d.layer != SortLayer.rule) || d.mode == SortMode.suggestOnly) {
        status = DecisionStatus.suggested;
        mode = SortMode.suggestOnly;
      } else {
        status = DecisionStatus.pending;
      }
      decisions.add(d.copyWith(status: status, mode: mode, deviceId: me.deviceId, epoch: epoch));
    }
    await _journal.recordDecisions(decisions, epoch: epoch);
    if (customKeywords) {
      final uids = [for (final d in decisions) if (!d.isKeep && d.key.uid != null) d.key.uid!];
      if (uids.isNotEmpty) await _ops.store(uids, add: {SortieKeywords.pending});
    }
    _log.info('epoch $epoch: ${decisions.length} decisions journaled');
    await _runAdvisor();
  }

  // -------------------------------------------------------------- evaluate

  /// Evaluates every open decision against the read-guard and executes the
  /// allowed ones in fenced batches. Returns the number of moves made.
  Future<int> evaluatePending() async {
    _retryTimer?.cancel();
    final config = await _journal.store.config();
    await _executePendingUndos();
    final open = (await _journal.store.openDecisions()).where((d) => d.status == DecisionStatus.pending).toList();
    if (open.isEmpty) return 0;
    await _ops.select(inbox);
    final uids = [for (final d in open) if (d.key.uid != null) d.key.uid!];
    final byUid = {for (final h in uids.isEmpty ? <MessageHeader>[] : await _ops.fetchHeadersByUids(uids)) h.uid: h};
    final now = _clock.now();
    final held = _presence.heldKeys(now);
    final closed = _presence.recentlyClosedAt(now);
    final movers = <(SortDecision, MessageHeader)>[];
    Duration? retry;
    for (final d in open) {
      var h = byUid[d.key.uid];
      if (h == null || h.messageIdHash != d.key.messageIdHash) {
        h = await _relocate(d);
        if (h == null) {
          await _resolveMissing(d);
          continue;
        }
      }
      if (h.hasSortieDone) {
        await _journal.recordResolved(key: d.key, why: 'external-move', epoch: epoch);
        continue;
      }
      if (h.isSeen) _guard.observeSeen(d.key.messageIdHash, now);
      final v = _guard.evaluate(
        mid: d.key.messageIdHash,
        mode: d.mode,
        isSeen: h.isSeen,
        isBulk: h.isBulk,
        heldMids: held,
        recentlyClosedAt: closed,
        serverNow: now,
        config: config,
      );
      if (v.allowed) {
        movers.add((d, h));
      } else if (v.retryAfter != null && (retry == null || v.retryAfter! < retry)) {
        retry = v.retryAfter;
      }
    }
    var moved = 0;
    for (var i = 0; i < movers.length; i += _timers.batchSize) {
      if (_stopped) break;
      final batch = movers.sublist(i, i + _timers.batchSize > movers.length ? movers.length : i + _timers.batchSize);
      if (!await _lease.fence(epoch)) throw LeaseLostException(epoch);
      for (final (d, h) in batch) {
        if (await _execute(d, h)) moved++;
      }
    }
    if (moved > 0) await _resync();
    if (retry != null && !_stopped) {
      _retryTimer?.cancel();
      _retryTimer = Timer(retry + const Duration(milliseconds: 500), () => _serial(evaluatePending).then((_) {}, onError: _fatal));
    }
    return moved;
  }

  Future<bool> _execute(SortDecision d, MessageHeader h) async {
    var marked = false;
    try {
      if (customKeywords) {
        await _ops.store([h.uid], add: {SortieKeywords.done}, remove: {SortieKeywords.pending});
        marked = true;
      }
      final r = await _ops.move([h.uid], d.destination);
      await _journal.recordMoved([
        MovedItem(key: d.key, from: inbox, to: d.destination, cause: 'auto', decisionId: d.id, subject: h.subject, fromAddress: h.from?.email),
      ], epoch: epoch);
      await _messages.moveLocally(accountId, inbox, [h.uid], d.destination, newUids: r.uidMapping);
      _guard.forget(d.key.messageIdHash);
      moves++;
      return true;
    } on ImapGatewayException catch (e) {
      if (e.isConnectionLost) rethrow;
      _log.warning('move of ${d.key} to ${d.destination} failed: $e');
      if (marked) {
        // Leave the message exactly as it was so it is not mistaken for done.
        try {
          await _ops.store([h.uid], add: {SortieKeywords.pending}, remove: {SortieKeywords.done});
        } on ImapGatewayException catch (e2) {
          if (e2.isConnectionLost) rethrow;
        }
      }
      await _journal.store.setDecisionStatus(d.id, DecisionStatus.failed, finalFolder: null);
      return false;
    }
  }

  Future<MessageHeader?> _relocate(SortDecision d) async {
    final local = await _messages.byMessageIdHash(accountId, d.key.messageIdHash);
    final mid = local?.messageId;
    if (mid == null) return null;
    final uids = await _ops.searchByMessageId(mid);
    if (uids.isEmpty) return null;
    for (final h in await _ops.fetchHeadersByUids(uids)) {
      if (h.messageIdHash == d.key.messageIdHash) return h;
    }
    return null;
  }

  /// Pending message gone from INBOX: external move (correction when found
  /// in a folder) or deletion.
  Future<void> _resolveMissing(SortDecision d) async {
    final local = await _messages.byMessageIdHash(accountId, d.key.messageIdHash);
    String? actual;
    if (local != null && local.folderPath != inbox) actual = local.folderPath;
    if (actual == null && local?.messageId != null) {
      try {
        await _ops.select(d.destination);
        if ((await _ops.searchByMessageId(local!.messageId!)).isNotEmpty) actual = d.destination;
      } on ImapGatewayException catch (e) {
        if (e.isConnectionLost) rethrow;
      } finally {
        await _ops.select(inbox);
      }
    }
    if (actual != null) {
      final c = _correction(CorrectionKind.externalMove, local, predicted: d.destination, actual: actual, decisionId: d.id, weight: 1.0, key: d.key);
      await _journal.recordCorrection(c);
      await _classifier.recordCorrection(c);
      await _journal.recordResolved(key: d.key, why: 'external-move', epoch: epoch);
    } else {
      await _journal.recordResolved(key: d.key, why: 'deleted', epoch: epoch);
    }
    _guard.forget(d.key.messageIdHash);
    await _resync();
  }

  Future<void> _executePendingUndos() async {
    for (final u in await _journal.pendingUndos()) {
      final d = await _journal.store.decisionById(u.decisionId);
      if (d == null) continue;
      final local = await _messages.byMessageIdHash(accountId, u.key.messageIdHash);
      final mid = local?.messageId;
      if (mid == null) continue;
      try {
        await _ops.select(d.destination);
        final uids = await _ops.searchByMessageId(mid);
        if (uids.isEmpty) continue;
        final r = await _ops.move(uids, inbox);
        await _journal.recordMoved([MovedItem(key: u.key, from: d.destination, to: inbox, cause: 'undo', decisionId: d.id)], epoch: epoch);
        await _messages.moveLocally(accountId, d.destination, uids, inbox, newUids: r.uidMapping);
      } finally {
        await _ops.select(inbox);
      }
    }
  }

  Correction _correction(CorrectionKind kind, MessageHeader? h,
      {required String predicted, required String actual, String? decisionId, required double weight, MessageKey? key}) =>
      Correction(
        id: const Uuid().v4(),
        key: key ?? h!.key,
        kind: kind,
        weight: weight,
        predictedFolder: predicted,
        actualFolder: actual,
        at: _clock.now(),
        decisionId: decisionId,
        fromAddress: h?.from?.email,
        fromDomain: h?.from?.domain,
        listId: h?.listId,
        subjectNorm: h?.subject,
        deviceId: me.deviceId,
      );
}
