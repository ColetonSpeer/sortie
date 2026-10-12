import 'dart:convert';

import 'package:drift/drift.dart';

import '../../data/coordination/control_folder.dart';
import '../../data/local/database.dart' as local;
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import 'control_messages.dart';
import 'shared_config_sync.dart';

/// Drift access for the materialized journal view: `journal_events`,
/// `journal_cursors` and the `sort_decisions` / `corrections` mirrors.
class JournalStore {
  JournalStore({required local.SortieDatabase db, required String accountId, required SettingsRepository settings, SharedConfigSync? shared})
      : _db = db,
        _accountId = accountId,
        _settings = settings,
        _shared = shared;

  final local.SortieDatabase _db;
  final String _accountId;
  final SettingsRepository _settings;

  /// Materialises the shared-config sections; null = sections ignored.
  final SharedConfigSync? _shared;

  local.SortieDatabase get db => _db;
  String get accountId => _accountId;

  // ---------------------------------------------------------------- cursor

  Future<local.JournalCursor> cursor() async {
    final row = await (_db.select(_db.journalCursors)..where((t) => t.accountId.equals(_accountId))).getSingleOrNull();
    if (row != null) return row;
    await _db.into(_db.journalCursors).insertOnConflictUpdate(local.JournalCursorsCompanion.insert(accountId: _accountId));
    return (await (_db.select(_db.journalCursors)..where((t) => t.accountId.equals(_accountId))).getSingle());
  }

  Future<void> saveCursor(local.JournalCursorsCompanion c) async {
    await cursor();
    await (_db.update(_db.journalCursors)..where((t) => t.accountId.equals(_accountId))).write(c);
  }

  Future<int> nextWriterSeq() async {
    final c = await cursor();
    final n = c.writerSeq + 1;
    await saveCursor(local.JournalCursorsCompanion(writerSeq: Value(n)));
    return n;
  }

  // ---------------------------------------------------------------- events

  Future<void> insertEvent(ControlMessage m) => _db.into(_db.journalEvents).insertOnConflictUpdate(
        local.JournalEventsCompanion.insert(
          accountId: _accountId,
          uid: m.uid,
          type: m.type,
          deviceId: m.deviceId,
          epoch: Value(m.epoch),
          internalDate: m.internalDate.toUtc().millisecondsSinceEpoch,
          bodyJson: jsonEncode(m.body ?? const {}),
        ),
      );

  Future<void> insertEventRow(local.JournalEventsCompanion c) => _db.into(_db.journalEvents).insert(c, mode: InsertMode.insertOrIgnore);

  Future<List<local.JournalEvent>> events({int? limit, bool newestFirst = false}) {
    final q = _db.select(_db.journalEvents)
      ..where((t) => t.accountId.equals(_accountId))
      ..orderBy([(t) => newestFirst ? OrderingTerm.desc(t.uid) : OrderingTerm.asc(t.uid)]);
    if (limit != null) q.limit(limit);
    return q.get();
  }

  Stream<List<local.JournalEvent>> watchEvents({int limit = 200}) => (_db.select(_db.journalEvents)
        ..where((t) => t.accountId.equals(_accountId))
        ..orderBy([(t) => OrderingTerm.desc(t.uid)])
        ..limit(limit))
      .watch();

  Future<void> clearEvents() => (_db.delete(_db.journalEvents)..where((t) => t.accountId.equals(_accountId))).go();

  // ------------------------------------------------------------- decisions

  static local.SortDecisionsCompanion decisionCompanion(SortDecision d, {required DateTime createdAt, String? deviceId, int? epoch}) =>
      local.SortDecisionsCompanion.insert(
        id: d.id,
        accountId: d.key.accountId,
        messageIdHash: d.key.messageIdHash,
        uid: Value(d.key.uid),
        uidValidity: Value(d.key.uidValidity),
        sourceFolder: d.sourceFolder,
        destination: d.destination,
        layer: d.layer.name,
        matchedKey: Value(d.matchedKey),
        confidence: d.confidence,
        reason: Value(d.reason),
        mode: d.mode.name,
        status: d.status.name,
        modelId: Value(d.modelId),
        folderProfileVersion: Value(d.folderProfileVersion),
        deviceId: Value(deviceId ?? d.deviceId),
        epoch: Value(epoch ?? d.epoch),
        createdAt: createdAt.toUtc().millisecondsSinceEpoch,
      );

  static SortDecision decisionFromRow(local.SortDecision r) => SortDecision(
        id: r.id,
        key: MessageKey(accountId: r.accountId, messageIdHash: r.messageIdHash, uid: r.uid, uidValidity: r.uidValidity),
        sourceFolder: r.sourceFolder,
        destination: r.destination,
        confidence: r.confidence,
        reason: r.reason,
        mode: SortMode.values.byName(r.mode),
        layer: SortLayer.values.byName(r.layer),
        decidedAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt, isUtc: true),
        matchedKey: r.matchedKey,
        modelId: r.modelId,
        folderProfileVersion: r.folderProfileVersion,
        status: DecisionStatus.values.byName(r.status),
        deviceId: r.deviceId,
        epoch: r.epoch,
      );

  Future<void> upsertDecision(SortDecision d, {required DateTime createdAt, String? deviceId, int? epoch}) async {
    // A fresh decision supersedes earlier open ones for the same message.
    await (_db.update(_db.sortDecisions)
          ..where((t) =>
              t.accountId.equals(_accountId) &
              t.messageIdHash.equals(d.key.messageIdHash) &
              t.id.equals(d.id).not() &
              t.status.isIn([DecisionStatus.pending.name, DecisionStatus.suggested.name])))
        .write(local.SortDecisionsCompanion(status: Value(DecisionStatus.resolved.name)));
    await _db.into(_db.sortDecisions).insertOnConflictUpdate(decisionCompanion(d, createdAt: createdAt, deviceId: deviceId, epoch: epoch));
  }

  Future<SortDecision?> decisionById(String id) async {
    final r = await (_db.select(_db.sortDecisions)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : decisionFromRow(r);
  }

  /// Newest decision for a message, optionally only open ones.
  Future<SortDecision?> decisionForMid(String mid, {bool openOnly = false}) async {
    final q = _db.select(_db.sortDecisions)
      ..where((t) => t.accountId.equals(_accountId) & t.messageIdHash.equals(mid))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);
    if (openOnly) q.where((t) => t.status.isIn([DecisionStatus.pending.name, DecisionStatus.suggested.name]));
    final r = await q.getSingleOrNull();
    return r == null ? null : decisionFromRow(r);
  }

  Future<bool> hasAnyDecision(String mid) async =>
      (await (_db.select(_db.sortDecisions)..where((t) => t.accountId.equals(_accountId) & t.messageIdHash.equals(mid))..limit(1)).get()).isNotEmpty;

  /// When sorting first produced a decision on this account; the lower
  /// bound for catching up mail that arrived while no leader was running.
  Future<DateTime?> firstDecisionAt() async {
    final r = await (_db.select(_db.sortDecisions)
          ..where((t) => t.accountId.equals(_accountId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    return r == null ? null : DateTime.fromMillisecondsSinceEpoch(r.createdAt, isUtc: true);
  }

  Future<List<SortDecision>> openDecisions() async {
    final rows = await (_db.select(_db.sortDecisions)
          ..where((t) => t.accountId.equals(_accountId) & t.status.isIn([DecisionStatus.pending.name, DecisionStatus.suggested.name]))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows.map(decisionFromRow).toList();
  }

  Stream<List<SortDecision>> watchOpenDecisions() => (_db.select(_db.sortDecisions)
        ..where((t) => t.accountId.equals(_accountId) & t.status.isIn([DecisionStatus.pending.name, DecisionStatus.suggested.name])))
      .watch()
      .map((rows) => rows.map(decisionFromRow).toList());

  Future<void> setDecisionStatus(String id, DecisionStatus status, {String? finalFolder, DateTime? appliedAt}) =>
      (_db.update(_db.sortDecisions)..where((t) => t.id.equals(id))).write(local.SortDecisionsCompanion(
        status: Value(status.name),
        finalFolder: finalFolder == null ? const Value.absent() : Value(finalFolder),
        appliedAt: appliedAt == null ? const Value.absent() : Value(appliedAt.toUtc().millisecondsSinceEpoch),
      ));

  /// First time the leader saw an open decision's message as read, for the
  /// read-guard grace period; persisted so a restart does not reset it.
  Future<void> setSeenObservedAt(String mid, DateTime at) => (_db.update(_db.sortDecisions)
        ..where((t) => t.accountId.equals(_accountId) & t.messageIdHash.equals(mid) & t.status.equals(DecisionStatus.pending.name) & t.seenObservedAt.isNull()))
      .write(local.SortDecisionsCompanion(seenObservedAt: Value(at.toUtc().millisecondsSinceEpoch)));

  Future<Map<String, DateTime>> seenObservedAtByMid() async {
    final rows = await (_db.select(_db.sortDecisions)
          ..where((t) => t.accountId.equals(_accountId) & t.status.equals(DecisionStatus.pending.name) & t.seenObservedAt.isNotNull()))
        .get();
    return {for (final r in rows) r.messageIdHash: DateTime.fromMillisecondsSinceEpoch(r.seenObservedAt!, isUtc: true)};
  }

  Future<void> resolveOpenForMid(String mid, DecisionStatus status) => (_db.update(_db.sortDecisions)
        ..where((t) =>
            t.accountId.equals(_accountId) &
            t.messageIdHash.equals(mid) &
            t.status.isIn([DecisionStatus.pending.name, DecisionStatus.suggested.name])))
      .write(local.SortDecisionsCompanion(status: Value(status.name)));

  Future<void> resolveOpenExcept(Set<String> keepIds, DecisionStatus status) => (_db.update(_db.sortDecisions)
        ..where((t) =>
            t.accountId.equals(_accountId) &
            t.status.isIn([DecisionStatus.pending.name, DecisionStatus.suggested.name]) &
            t.id.isNotIn(keepIds.toList())))
      .write(local.SortDecisionsCompanion(status: Value(status.name)));

  // ----------------------------------------------------------- corrections

  Future<void> upsertCorrection(Correction c, {String? deviceId}) => _db.into(_db.corrections).insertOnConflictUpdate(
        local.CorrectionsCompanion.insert(
          id: c.id,
          accountId: _accountId,
          messageIdHash: c.key.messageIdHash,
          decisionId: Value(c.decisionId),
          kind: c.kind.name,
          weight: c.weight,
          predictedFolder: Value(c.predictedFolder),
          actualFolder: c.actualFolder,
          fromAddress: Value(c.fromAddress),
          fromDomain: Value(c.fromDomain),
          listId: Value(c.listId),
          subjectNorm: Value(c.subjectNorm),
          deviceId: Value(deviceId ?? c.deviceId),
          createdAt: c.at.toUtc().millisecondsSinceEpoch,
        ),
      );

  Future<List<Correction>> activeCorrections() async {
    final rows = await (_db.select(_db.corrections)
          ..where((t) => t.accountId.equals(_accountId) & t.superseded.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows
        .map((r) => Correction(
              id: r.id,
              key: MessageKey(accountId: _accountId, messageIdHash: r.messageIdHash),
              kind: CorrectionKind.values.byName(r.kind),
              weight: r.weight,
              actualFolder: r.actualFolder,
              at: DateTime.fromMillisecondsSinceEpoch(r.createdAt, isUtc: true),
              predictedFolder: r.predictedFolder,
              decisionId: r.decisionId,
              fromAddress: r.fromAddress,
              fromDomain: r.fromDomain,
              listId: r.listId,
              subjectNorm: r.subjectNorm,
              deviceId: r.deviceId,
            ))
        .toList();
  }

  // ---------------------------------------------------------------- config

  Future<SortConfig> config() => _settings.sortConfig(_accountId);
  Future<void> saveConfig(SortConfig c) => _settings.saveSortConfig(_accountId, c);
  Stream<SortConfig> watchConfig() => _settings.watchSortConfig(_accountId);

  // -------------------------------------------------------------- snapshot

  /// `{version, lastEpoch, config, identities?, rules?, calendars?, prefs?,
  /// pending[], corrections[], log[], inboxUidValidity}`. Shared sections are
  /// present only when the journal has carried them.
  Future<Map<String, dynamic>> buildSnapshot({required int lastEpoch, int? inboxUidValidity, int maxBytes = 2 * 1024 * 1024}) async {
    final pending = await openDecisions();
    final corrections = await activeCorrections();
    final cfg = await config();
    final shared = await _shared?.snapshotSections() ?? const {};
    var logRows = await events();
    var corr = corrections;
    Map<String, dynamic> build() => {
          'version': 1,
          'lastEpoch': lastEpoch,
          'config': cfg.toJson(),
          ...shared,
          'pending': [
            for (final d in pending)
              d.toJson()
                ..['device'] = d.deviceId
                ..['epoch'] = d.epoch
          ],
          'corrections': [for (final c in corr) c.toJson()..['device'] = c.deviceId],
          'log': [
            for (final e in logRows)
              {
                'uid': e.uid,
                'type': e.type,
                'device': e.deviceId,
                'epoch': e.epoch,
                'at': DateTime.fromMillisecondsSinceEpoch(e.internalDate, isUtc: true).toIso8601String(),
                'body': jsonDecode(e.bodyJson),
              }
          ],
          if (inboxUidValidity != null) 'inboxUidValidity': inboxUidValidity,
        };
    var body = build();
    // Over the size cap: drop the oldest half of the log, then corrections.
    while (jsonEncode(body).length > maxBytes) {
      if (logRows.isNotEmpty) {
        logRows = logRows.sublist(logRows.length ~/ 2 + 1);
      } else if (corr.isNotEmpty) {
        corr = corr.sublist(corr.length ~/ 2 + 1);
      } else {
        break;
      }
      body = build();
    }
    return body;
  }

  /// Applies a snapshot body. [missedEvents] is true when journal UIDs this
  /// device never applied were folded into it, in which case open decisions
  /// absent from the snapshot were resolved in the meantime.
  Future<void> loadSnapshot(Map<String, dynamic> body, {required bool missedEvents}) async {
    final cfg = body['config'];
    if (cfg is Map<String, dynamic>) await saveConfig(SortConfig.fromJson(cfg));
    final shared = _shared;
    if (shared != null) {
      for (final s in SharedConfigSync.sections) {
        final sec = body[s];
        if (sec is Map) await shared.applyRecord(s, sec.cast<String, dynamic>());
      }
    }
    final keep = <String>{};
    for (final p in (body['pending'] as List?) ?? const []) {
      if (p is! Map<String, dynamic>) continue;
      final d = SortDecision.fromJson(_accountId, p);
      keep.add(d.id);
      await upsertDecision(d, createdAt: d.decidedAt, deviceId: p['device'] as String?, epoch: p['epoch'] as int?);
    }
    if (missedEvents) await resolveOpenExcept(keep, DecisionStatus.resolved);
    for (final c in (body['corrections'] as List?) ?? const []) {
      if (c is! Map<String, dynamic>) continue;
      await upsertCorrection(Correction.fromJson(_accountId, c), deviceId: c['device'] as String?);
    }
    for (final e in (body['log'] as List?) ?? const []) {
      if (e is! Map<String, dynamic>) continue;
      final at = DateTime.tryParse((e['at'] as String?) ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      await insertEventRow(local.JournalEventsCompanion.insert(
        accountId: _accountId,
        uid: e['uid'] as int,
        type: e['type'] as String,
        deviceId: (e['device'] as String?) ?? '',
        epoch: Value(e['epoch'] as int?),
        internalDate: at.toUtc().millisecondsSinceEpoch,
        bodyJson: jsonEncode(e['body'] ?? const {}),
      ));
    }
  }

  // ----------------------------------------------------------------- apply

  /// Materializes one journal event into the mirrors.
  Future<void> apply(ControlMessage m) async {
    final body = m.body ?? const <String, dynamic>{};
    switch (m.type) {
      case ControlTypes.decision:
        for (final item in (body['items'] as List?) ?? const []) {
          if (item is! Map<String, dynamic>) continue;
          final d = SortDecision.fromJson(_accountId, item);
          await upsertDecision(d, createdAt: m.internalDate, deviceId: m.deviceId, epoch: m.epoch ?? body['epoch'] as int?);
        }
      case ControlTypes.moved:
        for (final item in (body['items'] as List?) ?? const []) {
          if (item is! Map<String, dynamic>) continue;
          final cause = (item['cause'] as String?) ?? 'manual';
          final status = switch (cause) {
            'undo' => DecisionStatus.undone,
            'correction' => DecisionStatus.corrected,
            'manual' => DecisionStatus.accepted,
            _ => DecisionStatus.applied,
          };
          final id = item['decisionId'] as String?;
          final mid = (item['key'] as Map?)?['mid'] as String?;
          final d = id != null ? await decisionById(id) : (mid != null ? await decisionForMid(mid) : null);
          if (d != null) await setDecisionStatus(d.id, status, finalFolder: item['to'] as String?, appliedAt: m.internalDate);
        }
      case ControlTypes.undo:
        if (body['executed'] == true) {
          final id = body['decisionId'] as String?;
          if (id != null) await setDecisionStatus(id, DecisionStatus.undone, finalFolder: 'INBOX', appliedAt: m.internalDate);
        }
      case ControlTypes.correction:
        final c = Correction.fromJson(_accountId, body);
        await upsertCorrection(c, deviceId: m.deviceId);
        final id = c.decisionId;
        if (id != null && const {CorrectionKind.badgeWrong, CorrectionKind.lateMove, CorrectionKind.externalMove, CorrectionKind.manualFile, CorrectionKind.undo}.contains(c.kind)) {
          await setDecisionStatus(id, c.kind == CorrectionKind.undo ? DecisionStatus.undone : DecisionStatus.corrected, finalFolder: c.actualFolder, appliedAt: m.internalDate);
        }
      case ControlTypes.resolved:
        final mid = (body['key'] as Map?)?['mid'] as String?;
        if (mid == null) return;
        final why = (body['why'] as String?) ?? '';
        final status = switch (why) {
          'keep' => DecisionStatus.kept,
          'expired' => DecisionStatus.skipped,
          _ => DecisionStatus.resolved,
        };
        await resolveOpenForMid(mid, status);
      case ControlTypes.config:
        await saveConfig(SortConfig.fromJson(body));
      case ControlTypes.identities || ControlTypes.rules || ControlTypes.calendars || ControlTypes.prefs:
        await _shared?.applyRecord(m.type, body, deviceId: m.deviceId, at: m.internalDate);
    }
  }
}
