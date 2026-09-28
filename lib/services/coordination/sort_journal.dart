import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import '../../data/coordination/control_folder.dart';
import '../../data/local/database.dart' as local;
import '../../domain/entities/entities.dart';
import 'control_messages.dart';
import 'journal_store.dart';
import 'server_clock.dart';

class JournalSyncResult {
  const JournalSyncResult({required this.reset, required this.appliedUids, required this.appliedTypes, required this.loadedSnapshotUid});
  final bool reset;
  final List<int> appliedUids;
  final Set<String> appliedTypes;
  final int? loadedSnapshotUid;
  bool get changed => reset || appliedUids.isNotEmpty || loadedSnapshotUid != null;
}

/// Append-only journal on the control folder plus its materialized view
/// (protocol "Sort journal and badges", "Compaction").
class SortJournal {
  SortJournal({
    required ControlFolder folder,
    required JournalStore store,
    required DeviceIdentity me,
    required ServerClock serverClock,
    this.maxJournalMessages = 300,
    this.maxJournalAge = const Duration(days: 14),
  })  : _folder = folder,
        _store = store,
        _me = me,
        _clock = serverClock;

  static final _log = Logger('sortie.coordination.journal');
  final ControlFolder _folder;
  final JournalStore _store;
  final DeviceIdentity _me;
  final ServerClock _clock;
  final int maxJournalMessages;
  final Duration maxJournalAge;
  final _events = StreamController<JournalSyncResult>.broadcast();

  Stream<JournalSyncResult> get events => _events.stream;
  JournalStore get store => _store;
  String get accountId => _store.accountId;

  Future<int> nextSeq() => _store.nextWriterSeq();

  // --------------------------------------------------------------- records

  Future<AppendedControlMessage> _append(String type, Map<String, dynamic> body, {int? epoch}) async {
    final seq = await nextSeq();
    final r = await _folder.append(ControlMessageDraft(
      type: type,
      deviceId: _me.deviceId,
      messageId: ControlMessageIds.journal(_me.deviceId, seq),
      seq: seq,
      epoch: epoch,
      body: body,
    ));
    _clock.observe(r.internalDate);
    return r;
  }

  Future<AppendedControlMessage> recordDecisions(List<SortDecision> decisions, {required int epoch}) =>
      _append(ControlTypes.decision, {'epoch': epoch, 'items': [for (final d in decisions) d.toJson()]}, epoch: epoch);

  Future<AppendedControlMessage> recordMoved(List<MovedItem> items, {int? epoch}) =>
      _append(ControlTypes.moved, {if (epoch != null) 'epoch': epoch, 'items': [for (final i in items) i.toJson()]}, epoch: epoch);

  Future<AppendedControlMessage> recordUndo({required MessageKey key, required String decisionId, required bool executed}) =>
      _append(ControlTypes.undo, {'key': messageKeyToJson(key), 'decisionId': decisionId, 'executed': executed});

  Future<AppendedControlMessage> recordCorrection(Correction c) => _append(ControlTypes.correction, c.toJson());

  Future<AppendedControlMessage> recordResolved({required MessageKey key, required String why, int? epoch}) =>
      _append(ControlTypes.resolved, {'key': messageKeyToJson(key), 'why': why}, epoch: epoch);

  Future<AppendedControlMessage> putConfig(SortConfig c) => _append(ControlTypes.config, c.toJson());

  /// Shared-config section (`identities` | `rules` | `calendars` | `prefs`).
  Future<AppendedControlMessage> putSection(String type, Map<String, dynamic> body) {
    if (!ControlMessage.sharedSectionTypes.contains(type)) throw ArgumentError.value(type, 'type');
    return _append(type, body);
  }

  // ------------------------------------------------------------------ sync

  /// Applies the control folder state to the local view. [headers] is a
  /// full header fetch; [uidValidity] the control folder's current value.
  Future<JournalSyncResult> sync(List<ControlMessage> headers, {required int uidValidity}) async {
    var cursor = await _store.cursor();
    var reset = false;
    var snapshotUid = cursor.snapshotUid;
    var lastApplied = cursor.lastAppliedUid;
    var lastEpoch = cursor.lastEpoch;
    if (cursor.uidValidity != uidValidity) {
      if (cursor.uidValidity != 0) _log.warning('control folder UIDVALIDITY ${cursor.uidValidity} -> $uidValidity: resetting journal cursor');
      await _store.clearEvents();
      reset = true;
      snapshotUid = 0;
      lastApplied = 0;
    }

    int? loadedSnapshot;
    final snaps = headers.where((m) => m.type == ControlTypes.snapshot).toList()..sort((a, b) => a.uid.compareTo(b.uid));
    if (snaps.isNotEmpty && snaps.last.uid > snapshotUid) {
      final s = snaps.last;
      final body = await _folder.fetchBody(s.uid);
      if (body != null) {
        final upto = s.snapshotUpto ?? 0;
        await _store.loadSnapshot(body, missedEvents: upto > lastApplied);
        snapshotUid = s.uid;
        if (upto > lastApplied) lastApplied = upto;
        final le = (body['lastEpoch'] as int?) ?? s.epoch ?? 0;
        if (le > lastEpoch) lastEpoch = le;
        loadedSnapshot = s.uid;
      }
    }

    final seen = <String>{for (final m in headers) if (m.isJournal && m.uid <= lastApplied) m.messageId};
    final applied = <int>[];
    final types = <String>{};
    final todo = headers.where((m) => m.isJournal && m.uid > lastApplied).toList()..sort((a, b) => a.uid.compareTo(b.uid));
    for (final m in todo) {
      if (m.messageId.isNotEmpty && !seen.add(m.messageId)) {
        _log.fine('skipping duplicate journal record ${m.messageId} (uid ${m.uid})');
        lastApplied = m.uid;
        continue;
      }
      final body = await _folder.fetchBody(m.uid);
      if (body == null) {
        lastApplied = m.uid;
        continue;
      }
      final full = m.withBody(body);
      await _store.apply(full);
      await _store.insertEvent(full);
      applied.add(m.uid);
      types.add(m.type);
      lastApplied = m.uid;
      final e = m.epoch;
      if (e != null && e > lastEpoch) lastEpoch = e;
    }

    await _store.saveCursor(local.JournalCursorsCompanion(
      uidValidity: Value(uidValidity),
      snapshotUid: Value(snapshotUid),
      lastAppliedUid: Value(lastApplied),
      lastEpoch: Value(lastEpoch),
    ));
    final result = JournalSyncResult(reset: reset, appliedUids: applied, appliedTypes: types, loadedSnapshotUid: loadedSnapshot);
    if (result.changed) _events.add(result);
    return result;
  }

  /// Offline undos (`undo{executed:false}`) not yet executed by a leader.
  Future<List<PendingUndo>> pendingUndos() async {
    final rows = await _store.events();
    final executed = <String>{};
    final out = <PendingUndo>[];
    for (final r in rows) {
      final body = jsonDecode(r.bodyJson) as Map<String, dynamic>;
      if (r.type == ControlTypes.moved) {
        for (final i in (body['items'] as List?) ?? const []) {
          if (i is Map && i['cause'] == 'undo' && i['decisionId'] is String) executed.add(i['decisionId'] as String);
        }
      } else if (r.type == ControlTypes.undo) {
        final id = body['decisionId'] as String?;
        if (id == null) continue;
        if (body['executed'] == true) {
          executed.add(id);
        } else {
          out.add(PendingUndo(decisionId: id, key: messageKeyFromJson(accountId, (body['key'] as Map).cast<String, dynamic>())));
        }
      }
    }
    return out.where((u) => !executed.contains(u.decisionId)).toList();
  }

  // ------------------------------------------------------------ compaction

  bool needsCompaction(List<ControlMessage> headers, DateTime serverNow) {
    final journal = headers.where((m) => m.isJournal).toList();
    if (journal.length > maxJournalMessages) return true;
    if (journal.isEmpty) return false;
    final oldest = journal.map((m) => m.internalDate).reduce((a, b) => a.isBefore(b) ? a : b);
    return oldest.isBefore(serverNow.subtract(maxJournalAge));
  }

  /// Leader only, after fencing: snapshot then expunge journal UIDs <= U.
  /// With [force] a snapshot is appended even when nothing was applied
  /// (re-seeding a recreated control folder from the local view).
  Future<int?> compact(List<ControlMessage> headers, {required int lastEpoch, int? inboxUidValidity, bool force = false}) async {
    final cursor = await _store.cursor();
    final journalUids = headers.where((m) => m.isJournal && m.uid <= cursor.lastAppliedUid).map((m) => m.uid).toList()..sort();
    final upto = journalUids.isEmpty ? 0 : journalUids.last;
    if (upto == 0 && !force) return null;
    final body = await _store.buildSnapshot(lastEpoch: lastEpoch, inboxUidValidity: inboxUidValidity);
    final seq = await nextSeq();
    final r = await _folder.append(ControlMessageDraft(
      type: ControlTypes.snapshot,
      deviceId: _me.deviceId,
      messageId: ControlMessageIds.snapshot(_me.deviceId, upto, seq),
      seq: seq,
      epoch: lastEpoch,
      snapshotUpto: upto,
      body: body,
    ));
    _clock.observe(r.internalDate);
    if (await _folder.findByMessageId(ControlMessageIds.snapshot(_me.deviceId, upto, seq)) == null) {
      throw const ControlFolderException('snapshot not confirmed');
    }
    final doomed = <int>{
      ...journalUids,
      ...headers.where((m) => m.type == ControlTypes.snapshot && m.uid < r.uid).map((m) => m.uid),
    };
    await _folder.expunge(doomed);
    await _store.saveCursor(local.JournalCursorsCompanion(snapshotUid: Value(r.uid), lastEpoch: Value(lastEpoch)));
    _log.info('compacted ${journalUids.length} journal records into snapshot uid ${r.uid}');
    return r.uid;
  }

  void dispose() => _events.close();
}

class PendingUndo {
  const PendingUndo({required this.decisionId, required this.key});
  final String decisionId;
  final MessageKey key;
}

class MovedItem {
  const MovedItem({required this.key, required this.from, required this.to, required this.cause, this.decisionId, this.subject, this.fromAddress});
  final MessageKey key;
  final String from;
  final String to;

  /// auto | undo | correction | manual
  final String cause;
  final String? decisionId;
  final String? subject;
  final String? fromAddress;

  Map<String, dynamic> toJson() => {
        'key': messageKeyToJson(key, subject: subject, from: fromAddress),
        'from': from,
        'to': to,
        'cause': cause,
        if (decisionId != null) 'decisionId': decisionId,
      };
}

/// Thrown when the control folder disagrees with what we just wrote.
class ControlFolderException implements Exception {
  const ControlFolderException(this.message);
  final String message;
  @override
  String toString() => 'ControlFolderException: $message';
}
