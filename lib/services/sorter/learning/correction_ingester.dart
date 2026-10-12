import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

import '../../../core/clock.dart';
import '../../../data/local/database.dart' as db;
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';
import '../folder_profiles.dart';
import '../sender_stats.dart';
import '../sort_evidence.dart';
import '../user_rules.dart';

/// Turns user actions into `corrections` rows and sender-stat evidence.
/// This is the ONLY writer of learned statistics after bootstrap; the
/// sorter's own moves never reach it.
class CorrectionIngester {
  CorrectionIngester(this._db, this._clock,
      {required SenderStatsService stats, required FolderProfileService profiles, required UserRulesService rules, required MessageRepository messages, this.deviceId, SortEvidenceStore? evidence})
      : _stats = stats,
        _profiles = profiles,
        _rules = rules,
        _messages = messages,
        _evidence = evidence;
  final db.SortieDatabase _db;
  final Clock _clock;
  final SenderStatsService _stats;
  final FolderProfileService _profiles;
  final UserRulesService _rules;
  final MessageRepository _messages;

  /// Rule-advisor evidence sink (user-origin moves and undos). Optional so
  /// older call sites keep working.
  final SortEvidenceStore? _evidence;
  final String? deviceId;
  static final _log = Logger('sortie.sorter.learning');

  static const maxCorrections = 500;
  static const staleDays = 180;
  static const keepPerFolder = 2;
  static const fewShotCount = 12;
  static const fewShotPerFolder = 3;
  static const vetoKinds = {CorrectionKind.undo, CorrectionKind.lateMove, CorrectionKind.badgeWrong, CorrectionKind.badgeDismiss};
  static const preferredKinds = {CorrectionKind.undo, CorrectionKind.lateMove, CorrectionKind.badgeWrong};

  Future<void> ingest(Correction c, SortConfig config) async {
    if (c.kind == CorrectionKind.bootstrap) return;
    final header = await _messages.byMessageIdHash(c.key.accountId, c.key.messageIdHash);
    final from = c.fromAddress?.toLowerCase() ?? header?.from?.email.toLowerCase();
    final domain = c.fromDomain?.toLowerCase() ?? header?.from?.domain;
    final listId = c.listId?.toLowerCase() ?? header?.listId?.toLowerCase();
    final subjectNorm = c.subjectNorm ?? (header == null ? null : ProfileStats.normalizeSubject(header.subject));
    final profiles = await _profiles.byPath(c.key.accountId);
    final allowed = {for (final p in profiles.values) if (_profiles.isSortable(p, config)) p.path};
    final actualProfile = profiles[c.actualFolder];
    final actualIsInbox = c.actualFolder.toUpperCase() == 'INBOX';
    final isVeto = vetoKinds.contains(c.kind);

    // Disposal into Trash/Junk/Archive teaches nothing.
    if (!actualIsInbox && actualProfile != null && !allowed.contains(c.actualFolder) && !isVeto) return;

    // Manual filings and undos are evidence for the rule advisor (only into
    // sortable folders, or back to INBOX).
    if (actualIsInbox || allowed.contains(c.actualFolder)) {
      await _evidence?.recordCorrection(c, fromAddress: from, fromDomain: domain, listId: listId, subjectNorm: subjectNorm);
    }

    // A contradicting rule wins: keep the row for the log but do not learn.
    var ruleWins = false;
    if (header != null) {
      final rule = _rules.firstMatch(await _rules.load(c.key.accountId), header);
      if (rule != null) {
        ruleWins = switch (rule.action) {
          RuleAction.moveTo => rule.folderPath != c.actualFolder,
          RuleAction.keepInInbox || RuleAction.neverAutoSort => !actualIsInbox,
        };
      }
    }

    await _db.into(_db.corrections).insertOnConflictUpdate(db.CorrectionsCompanion.insert(
          id: c.id,
          accountId: c.key.accountId,
          messageIdHash: c.key.messageIdHash,
          decisionId: Value(c.decisionId),
          kind: c.kind.name,
          weight: c.weight,
          predictedFolder: Value(c.predictedFolder),
          actualFolder: c.actualFolder,
          fromAddress: Value(from),
          fromDomain: Value(domain),
          listId: Value(listId),
          subjectNorm: Value(subjectNorm),
          superseded: Value(ruleWins),
          deviceId: Value(c.deviceId ?? deviceId),
          createdAt: c.at.millisecondsSinceEpoch,
        ));
    if (ruleWins) {
      _log.fine('Correction ${c.id} contradicts a rule; not learning');
      return;
    }

    final keys = _keys(from: from, domain: domain, listId: listId);
    final learnsPositive = allowed.contains(c.actualFolder) && c.kind != CorrectionKind.badgeDismiss && c.weight > 0;
    if (learnsPositive) {
      for (final (kind, key) in keys) {
        await _stats.addEvidence(c.key.accountId, kind, key, c.actualFolder, c.weight, c.at);
      }
      await _profiles.incrementUserFiled(c.key.accountId, c.actualFolder, c.at);
    }
    final wrong = c.predictedFolder;
    if (isVeto && wrong != null && wrong.toUpperCase() != 'INBOX' && wrong != c.actualFolder) {
      for (final (kind, key) in keys) {
        await _stats.addAgainst(c.key.accountId, kind, key, wrong);
      }
    }
    if (learnsPositive && header != null) await _markSupersededIfDeterministic(c.key.accountId, header, c.actualFolder, allowed, keys);
    await evict(c.key.accountId);
  }

  List<(StatKeyKind, String)> _keys({String? from, String? domain, String? listId}) => [
        if (listId != null && listId.isNotEmpty) (StatKeyKind.listId, listId),
        if (from != null && from.isNotEmpty) (StatKeyKind.fromAddr, from),
        if (domain != null && domain.isNotEmpty && !_stats.isFreeMail(domain)) (StatKeyKind.fromDomain, domain),
      ];

  /// Once stats decide a key deterministically, its few-shot examples are
  /// redundant; mark them superseded so eviction takes them first.
  Future<void> _markSupersededIfDeterministic(String accountId, MessageHeader h, String folder, Set<String> allowed, List<(StatKeyKind, String)> keys) async {
    final v = await _stats.lookup(accountId, h, allowedFolders: allowed);
    if (v == null || !v.deterministic || v.folder != folder) return;
    final col = switch (v.kind) {
      StatKeyKind.listId => _db.corrections.listId,
      StatKeyKind.fromAddr => _db.corrections.fromAddress,
      StatKeyKind.fromDomain => _db.corrections.fromDomain,
    };
    await (_db.update(_db.corrections)..where((c) => c.accountId.equals(accountId) & col.equals(v.key) & c.actualFolder.equals(folder)))
        .write(const db.CorrectionsCompanion(superseded: Value(true)));
  }

  /// Cap 500 per account: superseded first, then older than 180 days, never
  /// the newest 2 per folder.
  Future<int> evict(String accountId) async {
    final rows = await (_db.select(_db.corrections)..where((c) => c.accountId.equals(accountId))..orderBy([(c) => OrderingTerm.desc(c.createdAt)])).get();
    if (rows.length <= maxCorrections) return 0;
    final protectedIds = <String>{};
    final perFolder = <String, int>{};
    for (final r in rows) {
      final n = perFolder[r.actualFolder] ?? 0;
      if (n < keepPerFolder) {
        protectedIds.add(r.id);
        perFolder[r.actualFolder] = n + 1;
      }
    }
    final cutoff = _clock.now().millisecondsSinceEpoch - const Duration(days: staleDays).inMilliseconds;
    final oldestFirst = rows.reversed.where((r) => !protectedIds.contains(r.id)).toList();
    final victims = <String>[
      ...oldestFirst.where((r) => r.superseded).map((r) => r.id),
      ...oldestFirst.where((r) => !r.superseded && r.createdAt < cutoff).map((r) => r.id),
      ...oldestFirst.where((r) => !r.superseded && r.createdAt >= cutoff).map((r) => r.id),
    ];
    final toRemove = victims.take(rows.length - maxCorrections).toList();
    if (toRemove.isNotEmpty) await (_db.delete(_db.corrections)..where((c) => c.id.isIn(toRemove))).go();
    return toRemove.length;
  }

  Future<List<db.Correction>> _recent(String accountId, {int limit = 200}) =>
      (_db.select(_db.corrections)..where((c) => c.accountId.equals(accountId) & c.superseded.equals(false))..orderBy([(c) => OrderingTerm.desc(c.createdAt)])..limit(limit)).get();

  /// system[1]: 12 most recent, max 3 per folder, prefer undo/lateMove/
  /// badgeWrong; rendered without timestamps and sorted for cache stability.
  Future<String> fewShotText(String accountId) async {
    final rows = await _recent(accountId);
    final picked = <db.Correction>[];
    final perFolder = <String, int>{};
    for (final preferredPass in [true, false]) {
      for (final r in rows) {
        if (picked.length >= fewShotCount) break;
        final kind = CorrectionKind.values.byName(r.kind);
        if (preferredKinds.contains(kind) != preferredPass) continue;
        if (kind == CorrectionKind.badgeDismiss) continue;
        if ((perFolder[r.actualFolder] ?? 0) >= fewShotPerFolder) continue;
        perFolder[r.actualFolder] = (perFolder[r.actualFolder] ?? 0) + 1;
        picked.add(r);
      }
    }
    picked.sort((a, b) {
      final f = a.actualFolder.compareTo(b.actualFolder);
      if (f != 0) return f;
      final k = (a.fromAddress ?? a.listId ?? '').compareTo(b.fromAddress ?? b.listId ?? '');
      return k != 0 ? k : a.id.compareTo(b.id);
    });
    return picked.map((r) => '- ${render(r)}').join('\n');
  }

  /// Up to 6 corrections whose sender/list/domain appears in this batch.
  Future<List<String>> relevantFor(String accountId, Iterable<MessageHeader> headers, {int limit = 6}) async {
    final froms = <String>{}, lists = <String>{}, domains = <String>{};
    for (final h in headers) {
      final f = h.from?.email.toLowerCase();
      if (f != null) froms.add(f);
      final l = h.listId?.toLowerCase();
      if (l != null) lists.add(l);
      final d = h.from?.domain ?? '';
      if (d.isNotEmpty && !_stats.isFreeMail(d)) domains.add(d);
    }
    final rows = await _recent(accountId);
    return rows
        .where((r) => r.kind != CorrectionKind.badgeDismiss.name)
        .where((r) => froms.contains(r.fromAddress) || lists.contains(r.listId) || domains.contains(r.fromDomain))
        .take(limit)
        .map(render)
        .toList();
  }

  static String render(db.Correction r) {
    final who = r.listId != null ? 'list ${r.listId}' : 'sender ${r.fromAddress ?? r.fromDomain ?? 'unknown'}';
    final subj = r.subjectNorm == null || r.subjectNorm!.isEmpty ? '' : ' "${r.subjectNorm}"';
    final kind = CorrectionKind.values.byName(r.kind);
    final was = r.predictedFolder == null || r.predictedFolder == r.actualFolder ? '' : ' (sorter had chosen ${r.predictedFolder})';
    final verb = switch (kind) {
      CorrectionKind.undo => 'moved back to',
      CorrectionKind.badgeRight => 'confirmed',
      _ => 'filed in',
    };
    return 'From $who$subj: owner $verb ${r.actualFolder}$was';
  }
}
