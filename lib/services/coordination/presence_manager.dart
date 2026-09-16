import 'package:logging/logging.dart';

import '../../data/coordination/control_folder.dart';
import '../../domain/entities/entities.dart';
import 'control_messages.dart';
import 'lease_manager.dart';
import 'server_clock.dart';

/// One device's newest presence record.
class PresenceRecord {
  const PresenceRecord({
    required this.uid,
    required this.internalDate,
    required this.info,
    required this.open,
    required this.recentlyClosed,
  });
  final int uid;
  final DateTime internalDate;
  final DeviceInfo info;

  /// messageIdHash of messages open in a reader on that device.
  final Set<String> open;

  /// messageIdHash -> server time the reader closed it.
  final Map<String, DateTime> recentlyClosed;

  String get deviceId => info.deviceId;
  bool isFresh(DateTime serverNow, Duration ttl) => !internalDate.isBefore(serverNow.subtract(ttl));
}

/// Publishes this device's presence (open / recently-closed holds) and
/// reads everyone else's. Holds are carried by presence rather than a
/// keyword so a crashed reader expires with its presence.
class PresenceManager {
  PresenceManager({
    required ControlFolder folder,
    required ServerClock serverClock,
    required DeviceIdentity me,
    required LeaseTimers timers,
    required Future<int> Function() nextSeq,
    bool Function()? mayLead,
  })  : _folder = folder,
        _clock = serverClock,
        _me = me,
        _timers = timers,
        _nextSeq = nextSeq,
        _mayLead = mayLead ?? (() => true);

  static final _log = Logger('sortie.coordination.presence');
  final ControlFolder _folder;
  final ServerClock _clock;
  final DeviceIdentity _me;
  final LeaseTimers _timers;
  final Future<int> Function() _nextSeq;
  final bool Function() _mayLead;

  final Set<String> open = {};
  final Map<String, DateTime> recentlyClosed = {};
  final Map<String, MessageKey> _keys = {};
  int? _lastUid;
  final _bodies = <int, Map<String, dynamic>>{};
  List<PresenceRecord> _others = const [];

  /// Newest fresh-or-not presence per other device, from the last [refresh].
  List<PresenceRecord> get others => _others;

  /// Priority advertised in presence: -1 when this device never claims, so
  /// bounded-cycle devices do not defer to it.
  int get advertisedPriority => _mayLead() ? _me.priority : -1;

  /// Returns true when the hold set changed (caller republishes at once).
  bool onOpen(MessageKey key) {
    _keys[key.messageIdHash] = key;
    recentlyClosed.remove(key.messageIdHash);
    return open.add(key.messageIdHash);
  }

  bool onClose(MessageKey key, {DateTime? serverNow}) {
    _keys[key.messageIdHash] = key;
    final removed = open.remove(key.messageIdHash);
    final now = serverNow ?? _clock.nowOrNull();
    if (now != null) recentlyClosed[key.messageIdHash] = now;
    return removed || now != null;
  }

  void _prune() {
    final now = _clock.nowOrNull();
    if (now == null) return;
    recentlyClosed.removeWhere((_, at) => at.isBefore(now.subtract(_timers.presenceTTL)));
  }

  /// APPEND presence, then delete the previous one. Primes the server clock.
  Future<AppendedControlMessage> publish() async {
    _prune();
    final n = await _nextSeq();
    final r = await _folder.append(ControlMessageDraft(
      type: ControlTypes.presence,
      deviceId: _me.deviceId,
      messageId: ControlMessageIds.presence(_me.deviceId, n),
      seq: n,
      priority: advertisedPriority,
      body: {
        'deviceName': _me.displayName,
        'platform': _me.platform.name,
        'priority': advertisedPriority,
        'open': [for (final mid in open) messageKeyToJson(_keys[mid] ?? MessageKey(accountId: '', messageIdHash: mid))],
        'recentlyClosed': [
          for (final e in recentlyClosed.entries)
            {
              'key': messageKeyToJson(_keys[e.key] ?? MessageKey(accountId: '', messageIdHash: e.key)),
              'at': e.value.toUtc().toIso8601String(),
            }
        ],
      },
    ));
    _clock.observe(r.internalDate);
    final prev = _lastUid;
    _lastUid = r.uid;
    if (prev != null) {
      try {
        await _folder.expunge([prev]);
      } catch (e) {
        _log.fine('could not delete previous presence $prev: $e');
      }
    }
    return r;
  }

  /// Loads bodies of the newest presence per other device (cached by UID).
  Future<void> refresh(List<ControlMessage> headers) async {
    final newest = <String, ControlMessage>{};
    for (final m in headers.where((m) => m.type == ControlTypes.presence)) {
      if (m.deviceId == _me.deviceId) continue;
      final cur = newest[m.deviceId];
      if (cur == null || m.uid > cur.uid) newest[m.deviceId] = m;
    }
    final live = newest.values.map((m) => m.uid).toSet();
    _bodies.removeWhere((uid, _) => !live.contains(uid));
    final out = <PresenceRecord>[];
    for (final m in newest.values) {
      var body = _bodies[m.uid];
      if (body == null) {
        try {
          body = await _folder.fetchBody(m.uid);
        } catch (e) {
          _log.fine('presence body ${m.uid} unavailable: $e');
        }
        if (body == null) continue;
        _bodies[m.uid] = body;
      }
      out.add(_parse(m, body));
    }
    out.sort((a, b) => a.deviceId.compareTo(b.deviceId));
    _others = out;
  }

  static PresenceRecord _parse(ControlMessage m, Map<String, dynamic> body) {
    final open = <String>{};
    for (final k in (body['open'] as List?) ?? const []) {
      if (k is Map && k['mid'] is String) open.add(k['mid'] as String);
    }
    final closed = <String, DateTime>{};
    for (final rc in (body['recentlyClosed'] as List?) ?? const []) {
      if (rc is! Map) continue;
      final key = rc['key'];
      final at = DateTime.tryParse((rc['at'] as String?) ?? '');
      if (key is Map && key['mid'] is String && at != null) closed[key['mid'] as String] = at.toUtc();
    }
    return PresenceRecord(
      uid: m.uid,
      internalDate: m.internalDate,
      info: DeviceInfo.fromBody(m.deviceId, body, headerPriority: m.priority),
      open: open,
      recentlyClosed: closed,
    );
  }

  /// Message hashes held open by a fresh presence of another device.
  Set<String> heldKeys(DateTime serverNow) => {
        for (final p in _others)
          if (p.isFresh(serverNow, _timers.presenceTTL)) ...p.open,
      };

  /// Latest close time per message hash across fresh presences of others.
  Map<String, DateTime> recentlyClosedAt(DateTime serverNow) {
    final out = <String, DateTime>{};
    for (final p in _others) {
      if (!p.isFresh(serverNow, _timers.presenceTTL)) continue;
      for (final e in p.recentlyClosed.entries) {
        final cur = out[e.key];
        if (cur == null || e.value.isAfter(cur)) out[e.key] = e.value;
      }
    }
    return out;
  }

  /// Fresh presences of other devices.
  List<PresenceRecord> fresh(DateTime serverNow) =>
      _others.where((p) => p.isFresh(serverNow, _timers.presenceTTL)).toList();
}
