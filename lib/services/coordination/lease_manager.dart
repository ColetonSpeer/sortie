import 'dart:math';

import 'package:logging/logging.dart';

import '../../data/coordination/control_folder.dart';
import '../../domain/entities/entities.dart';
import 'control_messages.dart';
import 'server_clock.dart';

/// Protocol timers (docs/coordination-protocol.md, "Leader election").
class LeaseTimers {
  const LeaseTimers({
    this.heartbeat = const Duration(seconds: 60),
    this.leaseTTL = const Duration(seconds: 180),
    this.claimConfirmWindow = const Duration(seconds: 10),
    this.claimBackoffCap = const Duration(seconds: 15),
    this.claimBackoffJitter = const Duration(seconds: 3),
    this.handoffWait = const Duration(seconds: 15),
    this.presenceInterval = const Duration(seconds: 60),
    this.presenceTTL = const Duration(seconds: 180),
    this.pollFallback = const Duration(minutes: 5),
    this.reopenSettle = const Duration(seconds: 30),
    this.staleCleanup = const Duration(hours: 24),
    this.compactionCheck = const Duration(hours: 1),
    this.reconnectDelay = const Duration(seconds: 5),
    this.reconnectDelayMax = const Duration(minutes: 5),
    this.yieldBatchLimit = const Duration(seconds: 5),
    this.batchSize = 25,
  });

  final Duration heartbeat;
  final Duration leaseTTL;
  final Duration claimConfirmWindow;
  final Duration claimBackoffCap;
  final Duration claimBackoffJitter;
  final Duration handoffWait;
  final Duration presenceInterval;
  final Duration presenceTTL;
  final Duration pollFallback;
  final Duration reopenSettle;
  final Duration staleCleanup;
  final Duration compactionCheck;
  final Duration reconnectDelay;
  final Duration reconnectDelayMax;
  final Duration yieldBatchLimit;

  /// Max MOVEs per fenced batch.
  final int batchSize;

  /// `rand(0..jitter) + (100 - min(p,100)) * 0.1 s`, capped.
  Duration claimBackoff(int priority, double rand) {
    final jitter = Duration(microseconds: (claimBackoffJitter.inMicroseconds * rand).round());
    final byPriority = Duration(milliseconds: (100 - min(priority, 100)) * 100);
    final total = jitter + byPriority;
    return total > claimBackoffCap ? claimBackoffCap : total;
  }

  /// Compressed timers for a bounded BGAppRefresh / WorkManager cycle.
  LeaseTimers forBoundedCycle(Duration budget) => LeaseTimers(
        heartbeat: heartbeat,
        leaseTTL: leaseTTL,
        claimConfirmWindow: claimConfirmWindow < budget ~/ 5 ? claimConfirmWindow : budget ~/ 5,
        claimBackoffCap: Duration.zero,
        claimBackoffJitter: Duration.zero,
        handoffWait: Duration.zero,
        presenceInterval: presenceInterval,
        presenceTTL: presenceTTL,
        pollFallback: pollFallback,
        reopenSettle: reopenSettle,
        staleCleanup: staleCleanup,
        compactionCheck: compactionCheck,
        reconnectDelay: reconnectDelay,
        reconnectDelayMax: reconnectDelayMax,
        yieldBatchLimit: yieldBatchLimit,
        batchSize: batchSize,
      );
}

/// One (device, epoch) lease as reconstructed from the control folder.
class LeaseInfo {
  const LeaseInfo({
    required this.deviceId,
    required this.epoch,
    required this.priority,
    required this.claimUid,
    required this.claimedAt,
    required this.lastBeatAt,
    required this.beatUids,
    this.releasedAt,
  });
  final String deviceId;
  final int epoch;
  final int priority;
  final int claimUid;
  final DateTime claimedAt;

  /// INTERNALDATE of the newest beat, or of the claim itself.
  final DateTime lastBeatAt;
  final List<int> beatUids;
  final DateTime? releasedAt;

  bool get released => releasedAt != null;
  bool isDevice(String id) => deviceId == id;
  bool isFresh(DateTime serverNow, Duration ttl) => !released && !lastBeatAt.isBefore(serverNow.subtract(ttl));
  DateTime expiresAt(Duration ttl) => lastBeatAt.add(ttl);

  @override
  String toString() => 'Lease($deviceId e$epoch p$priority beat=$lastBeatAt${released ? ' released' : ''})';
}

class LeaseEvaluation {
  const LeaseEvaluation({
    required this.serverNow,
    required this.activeLease,
    required this.epochMax,
    required this.holders,
    required this.voidClaims,
    required this.allClaims,
  });
  final DateTime serverNow;
  final LeaseInfo? activeLease;
  final int epochMax;

  /// Legitimate winner per epoch (fresh or not).
  final Map<int, LeaseInfo> holders;

  /// Claims that lost their epoch or were illegitimate.
  final List<ControlMessage> voidClaims;
  final List<ControlMessage> allClaims;

  bool isHeldBy(String deviceId, int epoch) {
    final a = activeLease;
    return a != null && a.deviceId == deviceId && a.epoch == epoch;
  }
}

class ClaimResult {
  const ClaimResult._(this.epoch, this.evaluation, this.refused);
  const ClaimResult.won(int epoch, LeaseEvaluation e) : this._(epoch, e, false);
  const ClaimResult.lost(LeaseEvaluation? e) : this._(null, e, false);
  const ClaimResult.refused() : this._(null, null, true);
  final int? epoch;
  final LeaseEvaluation? evaluation;

  /// Not primed / not allowed to lead; nothing was appended.
  final bool refused;
  bool get won => epoch != null;
}

/// Leader election over the control folder. [evaluate] is pure and
/// deterministic given the same header list and server time.
class LeaseManager {
  LeaseManager({
    required ControlFolder folder,
    required ServerClock serverClock,
    required DeviceIdentity me,
    required LeaseTimers timers,
    Random? random,
  })  : _folder = folder,
        _clock = serverClock,
        _me = me,
        _timers = timers,
        _random = random ?? Random();

  static final _log = Logger('sortie.coordination.lease');
  final ControlFolder _folder;
  final ServerClock _clock;
  final DeviceIdentity _me;
  final LeaseTimers _timers;
  final Random _random;
  int _beatN = 0;
  int? _lastBeatUid;

  DeviceIdentity get me => _me;

  // ------------------------------------------------------------- evaluate

  LeaseEvaluation evaluate(List<ControlMessage> msgs, {DateTime? serverNow}) {
    final now = serverNow ?? _clock.now();
    final ttl = _timers.leaseTTL;
    final claims = msgs.where((m) => m.type == ControlTypes.leaseClaim && m.epoch != null).toList()
      ..sort((a, b) => a.uid.compareTo(b.uid));
    final beats = <String, List<ControlMessage>>{};
    final releases = <String, DateTime>{};
    var epochMax = 0;
    for (final m in msgs) {
      final e = m.epoch;
      if (e == null) continue;
      final k = '${m.deviceId}#$e';
      switch (m.type) {
        case ControlTypes.leaseBeat:
          beats.putIfAbsent(k, () => []).add(m);
        case ControlTypes.leaseRelease:
          final prev = releases[k];
          if (prev == null || m.internalDate.isBefore(prev)) releases[k] = m.internalDate;
        case ControlTypes.snapshot || ControlTypes.leaseClaim:
          if (e > epochMax) epochMax = e;
      }
    }

    LeaseInfo info(ControlMessage c) {
      final k = '${c.deviceId}#${c.epoch}';
      final bs = beats[k] ?? const <ControlMessage>[];
      var last = c.internalDate;
      for (final b in bs) {
        if (b.internalDate.isAfter(last)) last = b.internalDate;
      }
      return LeaseInfo(
        deviceId: c.deviceId,
        epoch: c.epoch!,
        priority: c.priority ?? 0,
        claimUid: c.uid,
        claimedAt: c.internalDate,
        lastBeatAt: last,
        beatUids: bs.map((b) => b.uid).toList(),
        releasedAt: releases[k],
      );
    }

    /// Newest beat of [prev] that existed when [at] was appended.
    DateTime lastBeatBefore(LeaseInfo prev, DateTime at) {
      var last = prev.claimedAt;
      for (final b in beats['${prev.deviceId}#${prev.epoch}'] ?? const <ControlMessage>[]) {
        if (!b.internalDate.isAfter(at) && b.internalDate.isAfter(last)) last = b.internalDate;
      }
      return last;
    }

    final byEpoch = <int, List<ControlMessage>>{};
    for (final c in claims) {
      byEpoch.putIfAbsent(c.epoch!, () => []).add(c);
    }
    final holders = <int, LeaseInfo>{};
    final voids = <ControlMessage>[];
    for (final e in byEpoch.keys.toList()..sort()) {
      final prev = holders[e - 1];
      final legit = <ControlMessage>[];
      for (final c in byEpoch[e]!) {
        var ok = true;
        if (prev != null && prev.deviceId != c.deviceId) {
          final expiredBefore = c.internalDate.isAfter(lastBeatBefore(prev, c.internalDate).add(ttl));
          final rel = prev.releasedAt;
          // `<=`: INTERNALDATE has 1 s resolution, so a claim stamped in the
          // same second as the release it reacted to still counts.
          final releasedBefore = rel != null && !rel.isAfter(c.internalDate);
          final preempts = (c.priority ?? 0) > prev.priority;
          ok = expiredBefore || releasedBefore || preempts;
        }
        (ok ? legit : voids).add(c);
      }
      if (legit.isEmpty) continue;
      legit.sort((a, b) {
        final t = a.internalDate.compareTo(b.internalDate);
        if (t != 0) return t;
        final p = (b.priority ?? 0).compareTo(a.priority ?? 0);
        if (p != 0) return p;
        return a.deviceId.compareTo(b.deviceId);
      });
      holders[e] = info(legit.first);
      voids.addAll(legit.skip(1));
    }

    LeaseInfo? active;
    for (final e in holders.keys.toList()..sort((a, b) => b.compareTo(a))) {
      final h = holders[e]!;
      if (h.isFresh(now, ttl)) {
        active = h;
        break;
      }
    }
    return LeaseEvaluation(
      serverNow: now,
      activeLease: active,
      epochMax: epochMax,
      holders: holders,
      voidClaims: voids,
      allClaims: claims,
    );
  }

  bool shouldPreempt(LeaseEvaluation e) {
    final a = e.activeLease;
    return a != null && !a.isDevice(_me.deviceId) && _me.priority > a.priority;
  }

  // ---------------------------------------------------------------- claim

  Future<AppendedControlMessage> appendAndObserve(ControlMessageDraft d) async {
    final r = await _folder.append(d);
    _clock.observe(r.internalDate);
    return r;
  }

  Duration nextBackoff() => _timers.claimBackoff(_me.priority, _random.nextDouble());

  /// Candidate flow: backoff, re-evaluate, append claim with epochMax + 1,
  /// confirm window, re-evaluate; on loss delete own claim.
  Future<ClaimResult> tryClaim({bool skipBackoff = false, Future<void> Function(Duration)? wait}) async {
    if (!_clock.primed) return const ClaimResult.refused();
    final delay = wait ?? ((d) => Future<void>.delayed(d));
    if (!skipBackoff) await delay(nextBackoff());
    var eval = evaluate(await _folder.fetchHeaders());
    final a = eval.activeLease;
    if (a != null && !a.isDevice(_me.deviceId) && !shouldPreempt(eval)) return ClaimResult.lost(eval);
    final epoch = eval.epochMax + 1;
    final mid = ControlMessageIds.leaseClaim(_me.deviceId, epoch);
    if (await _folder.findByMessageId(mid) == null) {
      await appendAndObserve(ControlMessageDraft(
        type: ControlTypes.leaseClaim,
        deviceId: _me.deviceId,
        messageId: mid,
        seq: epoch,
        epoch: epoch,
        priority: _me.priority,
        body: {'deviceName': _me.displayName, 'platform': _me.platform.name, 'priority': _me.priority, 'epoch': epoch},
      ));
    }
    await delay(_timers.claimConfirmWindow);
    final msgs = await _folder.fetchHeaders();
    eval = evaluate(msgs);
    if (eval.isHeldBy(_me.deviceId, epoch)) {
      _beatN = 0;
      _lastBeatUid = null;
      _log.info('${_me.shortId} leads epoch $epoch');
      return ClaimResult.won(epoch, eval);
    }
    final own = msgs.where((m) => m.type == ControlTypes.leaseClaim && m.deviceId == _me.deviceId && m.epoch == epoch);
    _log.info('${_me.shortId} lost claim for epoch $epoch to ${eval.activeLease}');
    await _folder.expunge(own.map((m) => m.uid));
    return ClaimResult.lost(eval);
  }

  Future<void> heartbeat(int epoch) async {
    final n = ++_beatN;
    final r = await appendAndObserve(ControlMessageDraft(
      type: ControlTypes.leaseBeat,
      deviceId: _me.deviceId,
      messageId: ControlMessageIds.leaseBeat(_me.deviceId, epoch, n),
      seq: n,
      epoch: epoch,
      body: const {},
    ));
    final prev = _lastBeatUid;
    _lastBeatUid = r.uid;
    if (prev != null) await _folder.expunge([prev]);
  }

  /// NOOP + refetch + confirm we still hold the lease. Throws on connection
  /// errors so the caller stops moving and reconnects.
  Future<bool> fence(int epoch) async {
    await _folder.noop();
    final eval = evaluate(await _folder.fetchHeaders());
    final ok = eval.isHeldBy(_me.deviceId, epoch);
    if (!ok) _log.warning('${_me.shortId} fence failed for epoch $epoch: active=${eval.activeLease}');
    return ok;
  }

  Future<void> release(int epoch) async {
    await appendAndObserve(ControlMessageDraft(
      type: ControlTypes.leaseRelease,
      deviceId: _me.deviceId,
      messageId: ControlMessageIds.leaseRelease(_me.deviceId, epoch),
      seq: epoch,
      epoch: epoch,
      body: const {},
    ));
    final msgs = await _folder.fetchHeaders();
    final beats = msgs.where((m) => m.type == ControlTypes.leaseBeat && m.deviceId == _me.deviceId && m.epoch == epoch);
    await _folder.expunge(beats.map((m) => m.uid));
    _lastBeatUid = null;
  }

  /// Deletes own void claims now, others' after 10 x TTL, and lease/presence
  /// records of superseded epochs older than [LeaseTimers.staleCleanup].
  Future<List<int>> cleanupStale(List<ControlMessage> msgs, LeaseEvaluation eval) async {
    final now = eval.serverNow;
    final doomed = <int>{};
    for (final c in eval.voidClaims) {
      if (c.deviceId == _me.deviceId || c.internalDate.isBefore(now.subtract(_timers.leaseTTL * 10))) doomed.add(c.uid);
    }
    final activeEpoch = eval.activeLease?.epoch ?? eval.epochMax;
    final cutoff = now.subtract(_timers.staleCleanup);
    for (final m in msgs) {
      final old = m.internalDate.isBefore(cutoff);
      if (!old) continue;
      switch (m.type) {
        case ControlTypes.leaseClaim || ControlTypes.leaseBeat || ControlTypes.leaseRelease:
          if ((m.epoch ?? 0) < activeEpoch) doomed.add(m.uid);
        case ControlTypes.presence:
          doomed.add(m.uid);
      }
    }
    if (doomed.isNotEmpty) await _folder.expunge(doomed);
    return doomed.toList()..sort();
  }
}
