import '../../domain/entities/entities.dart';
import 'lease_manager.dart';

class ReadGuardVerdict {
  const ReadGuardVerdict.allow(this.reason)
      : allowed = true,
        retryAfter = null;
  const ReadGuardVerdict.block(this.reason, {this.retryAfter}) : allowed = false;
  final bool allowed;

  /// `suggest-only | open-here | open-elsewhere | settling | unseen |
  /// closed-here | closed-elsewhere | grace | grace-done | move-now`.
  final String reason;

  /// When a timer (not an event) will unblock the message; null when only
  /// an external event (flag change, presence change) can.
  final Duration? retryAfter;

  @override
  String toString() => '${allowed ? 'allow' : 'block'}($reason${retryAfter != null ? ', retry $retryAfter' : ''})';
}

/// Decides whether a pending message may move (protocol "Read-guard").
/// All times are server time; the guard is leader-scoped state.
class ReadGuard {
  ReadGuard({required LeaseTimers timers}) : _timers = timers;
  final LeaseTimers _timers;

  final Set<String> _localOpen = {};
  final Map<String, DateTime> _localClosedAt = {};
  final Map<String, DateTime> _seenObservedAt = {};

  Set<String> get localOpen => _localOpen;

  void onLocalOpen(String mid) {
    _localOpen.add(mid);
    _localClosedAt.remove(mid);
  }

  void onLocalClose(String mid, DateTime serverNow) {
    _localOpen.remove(mid);
    _localClosedAt[mid] = serverNow;
  }

  /// First time the leader saw `\Seen` on [mid]; later calls are no-ops.
  /// Records when [mid] was first seen read; true when this is the first
  /// observation (callers persist it so the grace survives a restart).
  bool observeSeen(String mid, DateTime serverNow) {
    if (_seenObservedAt.containsKey(mid)) return false;
    _seenObservedAt[mid] = serverNow;
    return true;
  }

  /// Restores first-seen times persisted by an earlier run; existing
  /// in-memory entries win.
  void seed(Map<String, DateTime> seenAt) {
    for (final e in seenAt.entries) {
      _seenObservedAt.putIfAbsent(e.key, () => e.value);
    }
  }
  void forget(String mid) {
    _seenObservedAt.remove(mid);
    _localClosedAt.remove(mid);
    _localOpen.remove(mid);
  }

  DateTime? seenObservedAt(String mid) => _seenObservedAt[mid];

  static bool requiresSeen(SortConfig config, {required bool isBulk}) => switch (config.leaveUntilRead) {
        LeaveUntilRead.none => false,
        LeaveUntilRead.all => true,
        LeaveUntilRead.personalOnly => !isBulk,
      };

  ReadGuardVerdict evaluate({
    required String mid,
    required SortMode mode,
    required bool isSeen,
    required bool isBulk,
    required Set<String> heldMids,
    required Map<String, DateTime> recentlyClosedAt,
    required DateTime serverNow,
    required SortConfig config,
  }) {
    if (mode == SortMode.suggestOnly || mode == SortMode.keep) return const ReadGuardVerdict.block('suggest-only');
    if (_localOpen.contains(mid)) return const ReadGuardVerdict.block('open-here');
    if (heldMids.contains(mid)) return ReadGuardVerdict.block('open-elsewhere', retryAfter: _timers.presenceTTL);
    final remoteClosed = recentlyClosedAt[mid];
    if (remoteClosed != null) {
      final since = serverNow.difference(remoteClosed);
      if (since < _timers.reopenSettle) {
        return ReadGuardVerdict.block('settling', retryAfter: _timers.reopenSettle - since);
      }
    }
    if (mode == SortMode.moveNow || !requiresSeen(config, isBulk: isBulk)) return const ReadGuardVerdict.allow('move-now');
    if (!isSeen) return const ReadGuardVerdict.block('unseen');
    if (_localClosedAt.containsKey(mid)) return const ReadGuardVerdict.allow('closed-here');
    if (remoteClosed != null) return const ReadGuardVerdict.allow('closed-elsewhere');
    final seenAt = _seenObservedAt.putIfAbsent(mid, () => serverNow);
    final elapsed = serverNow.difference(seenAt);
    if (elapsed >= config.grace) return const ReadGuardVerdict.allow('grace-done');
    return ReadGuardVerdict.block('grace', retryAfter: config.grace - elapsed);
  }
}
