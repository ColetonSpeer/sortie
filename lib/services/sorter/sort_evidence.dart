import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/clock.dart';
import '../../data/local/database.dart' as db;
import '../../domain/entities/entities.dart';
import 'folder_profiles.dart';
import 'sender_stats.dart';

/// Why an evidence row exists.
enum EvidenceKind { unsorted, manualMove, undo }

/// Records what the deterministic layers could not place and what the owner
/// files by hand, so the rule advisor can look for patterns without the
/// model ever seeing individual messages.
///
/// Rows are de-duplicated per `(kind, list_id ?? from_addr, folder)`:
/// repeats bump `seen_count`, refresh `last_at` and collect up to three
/// distinct normalised subjects. The table is bounded per account.
class SortEvidenceStore {
  SortEvidenceStore(this._db, this._clock, {required SenderStatsService stats, this.maxRows = maxRowsPerAccount}) : _stats = stats;
  final db.SortieDatabase _db;
  final Clock _clock;
  final SenderStatsService _stats;
  static const _uuid = Uuid();

  static const maxRowsPerAccount = 2000;

  /// Per-account cap (tests lower it).
  final int maxRows;
  static const maxExamples = 3;

  /// A message the rules and learned stats left in INBOX.
  Future<void> recordUnsorted(String accountId, MessageHeader h) => _record(accountId, EvidenceKind.unsorted, h.messageIdHash,
      from: h.from?.email, domain: h.from?.domain, listId: h.listId, subject: h.subject, folder: null, at: _clock.now());

  /// A user-origin move (manualFile / lateMove / badgeWrong) or an undo.
  Future<void> recordCorrection(Correction c, {String? fromAddress, String? fromDomain, String? listId, String? subjectNorm}) async {
    final kind = switch (c.kind) {
      CorrectionKind.undo => EvidenceKind.undo,
      CorrectionKind.manualFile || CorrectionKind.lateMove || CorrectionKind.badgeWrong => EvidenceKind.manualMove,
      _ => null,
    };
    if (kind == null) return;
    await _record(c.key.accountId, kind, c.key.messageIdHash,
        from: fromAddress ?? c.fromAddress,
        domain: fromDomain ?? c.fromDomain,
        listId: listId ?? c.listId,
        subject: subjectNorm ?? c.subjectNorm,
        folder: kind == EvidenceKind.undo ? 'INBOX' : c.actualFolder,
        at: c.at);
  }

  Future<void> _record(String accountId, EvidenceKind kind, String messageIdHash,
      {required String? from, required String? domain, required String? listId, required String? subject, required String? folder, required DateTime at}) async {
    final f = from?.trim().toLowerCase();
    final l = listId?.trim().toLowerCase();
    if ((f == null || f.isEmpty) && (l == null || l.isEmpty)) return;
    final d = (domain ?? '').toLowerCase();
    final subj = subject == null ? null : ProfileStats.normalizeSubject(subject);
    final ts = at.millisecondsSinceEpoch;
    final q = _db.select(_db.sortEvidence)..where((e) => e.accountId.equals(accountId) & e.kind.equals(kind.name));
    if (l != null && l.isNotEmpty) {
      q.where((e) => e.listId.equals(l));
    } else {
      q.where((e) => e.listId.isNull() & e.fromAddr.equals(f!));
    }
    q.where((e) => folder == null ? e.folder.isNull() : e.folder.equals(folder));
    final existing = (await q.get()).firstOrNull;
    if (existing == null) {
      await _db.into(_db.sortEvidence).insert(db.SortEvidenceCompanion.insert(
            id: _uuid.v4(),
            accountId: accountId,
            kind: kind.name,
            messageIdHash: messageIdHash,
            fromAddr: Value(f == null || f.isEmpty ? null : f),
            fromDomain: Value(d.isEmpty || _stats.isFreeMail(d) ? null : d),
            listId: Value(l == null || l.isEmpty ? null : l),
            subjectNorm: Value(subj),
            examplesJson: Value(jsonEncode([if (subj != null && subj.isNotEmpty) subj])),
            folder: Value(folder),
            firstAt: ts,
            lastAt: ts,
          ));
      await _bound(accountId);
      return;
    }
    final examples = examplesOf(existing);
    if (subj != null && subj.isNotEmpty && !examples.contains(subj) && examples.length < maxExamples) examples.add(subj);
    await (_db.update(_db.sortEvidence)..where((e) => e.id.equals(existing.id))).write(db.SortEvidenceCompanion(
      messageIdHash: Value(messageIdHash),
      subjectNorm: Value(subj ?? existing.subjectNorm),
      examplesJson: Value(jsonEncode(examples)),
      seenCount: Value(existing.seenCount + 1),
      lastAt: Value(ts > existing.lastAt ? ts : existing.lastAt),
      // New evidence re-opens a consumed group so a later suggestion can form.
      consumedAt: existing.consumedAt == null ? const Value.absent() : const Value(null),
      sentAt: const Value(null),
    ));
  }

  static List<String> examplesOf(db.SortEvidenceData r) {
    try {
      return (jsonDecode(r.examplesJson) as List).map((e) => e.toString()).toList();
    } on FormatException {
      return [];
    }
  }

  /// Unconsumed rows, most frequent first.
  Future<List<db.SortEvidenceData>> unconsumed(String accountId) => (_db.select(_db.sortEvidence)
        ..where((e) => e.accountId.equals(accountId) & e.consumedAt.isNull())
        ..orderBy([(e) => OrderingTerm.desc(e.seenCount), (e) => OrderingTerm.desc(e.lastAt)]))
      .get();

  Future<int> countUnsent(String accountId) async {
    final c = countAll();
    final q = _db.selectOnly(_db.sortEvidence)
      ..addColumns([c])
      ..where(_db.sortEvidence.accountId.equals(accountId) & _db.sortEvidence.consumedAt.isNull() & _db.sortEvidence.sentAt.isNull());
    return (await q.getSingle()).read(c) ?? 0;
  }

  Future<void> markSent(Iterable<String> ids, DateTime at) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    await (_db.update(_db.sortEvidence)..where((e) => e.id.isIn(list))).write(db.SortEvidenceCompanion(sentAt: Value(at.millisecondsSinceEpoch)));
  }

  Future<void> consume(Iterable<String> ids, DateTime at) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    await (_db.update(_db.sortEvidence)..where((e) => e.id.isIn(list))).write(db.SortEvidenceCompanion(consumedAt: Value(at.millisecondsSinceEpoch)));
  }

  /// Consumes every unconsumed row a (new) rule's criterion covers.
  Future<int> consumeMatching(String accountId, Map<String, dynamic> match, DateTime at) async {
    final rows = await unconsumed(accountId);
    final ids = [for (final r in rows) if (covers(match, r)) r.id];
    await consume(ids, at);
    return ids.length;
  }

  /// True when a single-criterion match (`from` / `fromDomain` / `listId` /
  /// `subjectContains`) covers an evidence row.
  static bool covers(Map<String, dynamic> match, db.SortEvidenceData r) {
    final from = (match['from'] as String?)?.toLowerCase();
    if (from != null && r.fromAddr == from) return true;
    final domain = (match['fromDomain'] as String?)?.toLowerCase();
    if (domain != null && (r.fromDomain == domain || (r.fromAddr?.endsWith('@$domain') ?? false))) return true;
    final list = (match['listId'] as String?)?.toLowerCase();
    if (list != null && r.listId == list) return true;
    final subj = (match['subjectContains'] as String?)?.toLowerCase();
    if (subj != null && subj.isNotEmpty) {
      for (final s in examplesOf(r)) {
        if (s.toLowerCase().contains(subj)) return true;
      }
    }
    return false;
  }

  /// Cap per account: evict consumed rows first (oldest `last_at`), then the
  /// oldest unconsumed ones.
  Future<int> _bound(String accountId) async {
    final c = countAll();
    final q = _db.selectOnly(_db.sortEvidence)
      ..addColumns([c])
      ..where(_db.sortEvidence.accountId.equals(accountId));
    final n = (await q.getSingle()).read(c) ?? 0;
    if (n <= maxRows) return 0;
    var excess = n - maxRows;
    var removed = 0;
    for (final consumedFirst in [true, false]) {
      if (excess <= 0) break;
      final victims = await (_db.select(_db.sortEvidence)
            ..where((e) => e.accountId.equals(accountId) & (consumedFirst ? e.consumedAt.isNotNull() : e.consumedAt.isNull()))
            ..orderBy([(e) => OrderingTerm.asc(e.lastAt)])
            ..limit(excess))
          .get();
      if (victims.isEmpty) continue;
      await (_db.delete(_db.sortEvidence)..where((e) => e.id.isIn(victims.map((v) => v.id).toList()))).go();
      removed += victims.length;
      excess -= victims.length;
    }
    return removed;
  }

  /// Visible for tests.
  Future<int> enforceBound(String accountId) => _bound(accountId);
}
