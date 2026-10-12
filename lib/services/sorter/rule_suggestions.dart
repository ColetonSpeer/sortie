import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart' as db;
import '../../domain/entities/entities.dart';
import 'sort_evidence.dart';
import 'user_rules.dart';

/// What cross-device config sync needs: observe pending suggestions and fold
/// a remote list into the local table.
abstract class SyncableSuggestionStore {
  Stream<List<RuleSuggestion>> watchPending(String accountId);
  Future<List<RuleSuggestion>> pending(String accountId);

  /// Merges by id. Local pending suggestions older than [at] that are absent
  /// from [remote] were decided elsewhere and are closed here.
  Future<void> mergeRemote(String accountId, List<RuleSuggestion> remote, {DateTime? at});
}

/// `rule_suggestions` table: pending / accepted / dismissed proposals.
/// Dismissed ones are remembered for [dismissMemory] so the same
/// (match, folder) is not proposed again right away.
class RuleSuggestionStore implements SyncableSuggestionStore {
  RuleSuggestionStore(this._db, {required SortRuleStore rules, SortEvidenceStore? evidence})
      : _rules = rules,
        _evidence = evidence;
  final db.SortieDatabase _db;
  final SortRuleStore _rules;
  final SortEvidenceStore? _evidence;
  static const _uuid = Uuid();

  static const dismissMemory = Duration(days: 30);

  SimpleSelectStatement<db.$RuleSuggestionsTable, db.RuleSuggestion> _pendingQuery(String accountId) => _db.select(_db.ruleSuggestions)
    ..where((s) => s.accountId.equals(accountId) & s.status.equals(SuggestionStatus.pending.name))
    ..orderBy([(s) => OrderingTerm.desc(s.confidence), (s) => OrderingTerm.desc(s.evidenceCount), (s) => OrderingTerm.asc(s.createdAt)]);

  @override
  Stream<List<RuleSuggestion>> watchPending(String accountId) => _pendingQuery(accountId).watch().map((rows) => rows.map(fromRow).toList());

  @override
  Future<List<RuleSuggestion>> pending(String accountId) async => (await _pendingQuery(accountId).get()).map(fromRow).toList();

  Future<RuleSuggestion?> byId(String id) async {
    final r = await (_db.select(_db.ruleSuggestions)..where((s) => s.id.equals(id))).getSingleOrNull();
    return r == null ? null : fromRow(r);
  }

  /// Dedupe keys that must not be proposed again: pending, accepted and
  /// recently dismissed suggestions plus existing rules.
  Future<Set<String>> blockedKeys(String accountId, DateTime now) async {
    final cutoff = now.subtract(dismissMemory).millisecondsSinceEpoch;
    final rows = await (_db.select(_db.ruleSuggestions)..where((s) => s.accountId.equals(accountId))).get();
    final keys = <String>{};
    for (final r in rows) {
      if (r.status == SuggestionStatus.dismissed.name && (r.decidedAt ?? r.createdAt) < cutoff) continue;
      keys.add(fromRow(r).dedupeKey);
    }
    for (final rule in await _rules.load(accountId)) {
      if (rule.action == RuleAction.moveTo && rule.folderPath != null) keys.add(RuleSuggestion.dedupeKeyFor(rule.match.toJson(), rule.folderPath!));
    }
    return keys;
  }

  Future<RuleSuggestion> insert({
    required String accountId,
    required Map<String, dynamic> match,
    required String folderPath,
    required String rationale,
    required double confidence,
    required SuggestionSource source,
    required int evidenceCount,
    required List<String> examples,
    required DateTime now,
    String? id,
  }) async {
    final s = RuleSuggestion(
      id: id ?? _uuid.v4(),
      accountId: accountId,
      match: match,
      folderPath: folderPath,
      rationale: rationale,
      confidence: confidence,
      source: source,
      evidenceCount: evidenceCount,
      examples: examples.take(3).toList(),
      createdAt: now,
    );
    await _upsert(s);
    return s;
  }

  Future<void> _upsert(RuleSuggestion s) => _db.into(_db.ruleSuggestions).insertOnConflictUpdate(db.RuleSuggestionsCompanion.insert(
        id: s.id,
        accountId: s.accountId,
        matchJson: jsonEncode(s.match),
        folderPath: s.folderPath,
        rationale: Value(s.rationale),
        confidence: s.confidence,
        source: s.source.name,
        evidenceCount: Value(s.evidenceCount),
        examplesJson: Value(jsonEncode(s.examples)),
        status: Value(s.status.name),
        createdAt: s.createdAt.millisecondsSinceEpoch,
        decidedAt: Value(s.decidedAt?.millisecondsSinceEpoch),
      ));

  /// Creates the rule (priority after every existing one), marks the
  /// suggestion accepted and consumes the evidence behind it. Returns the
  /// rule id.
  Future<String> accept(String id, DateTime now, {Map<String, dynamic>? match, String? folderPath}) async {
    final s = await byId(id);
    if (s == null) throw ArgumentError.value(id, 'id', 'unknown suggestion');
    final m = match ?? s.match;
    final folder = folderPath ?? s.folderPath;
    final existing = await _rules.load(s.accountId);
    final priority = existing.fold<int>(0, (a, r) => r.priority > a ? r.priority : a) + 10;
    final rule = SortRule(
      id: _uuid.v4(),
      accountId: s.accountId,
      priority: priority,
      match: RuleMatch.fromJson(m),
      action: RuleAction.moveTo,
      folderPath: folder,
      name: 'Suggested: ${RuleMatch.fromJson(m).describe()}',
    );
    await _rules.upsert(rule, now);
    await _setStatus(id, SuggestionStatus.accepted, now, match: m, folderPath: folder);
    await _evidence?.consumeMatching(s.accountId, m, now);
    return rule.id;
  }

  Future<void> dismiss(String id, DateTime now) async {
    final s = await byId(id);
    if (s == null) return;
    await _setStatus(id, SuggestionStatus.dismissed, now);
    await _evidence?.consumeMatching(s.accountId, s.match, now);
  }

  Future<void> _setStatus(String id, SuggestionStatus status, DateTime now, {Map<String, dynamic>? match, String? folderPath}) =>
      (_db.update(_db.ruleSuggestions)..where((s) => s.id.equals(id))).write(db.RuleSuggestionsCompanion(
        status: Value(status.name),
        decidedAt: Value(now.millisecondsSinceEpoch),
        matchJson: match == null ? const Value.absent() : Value(jsonEncode(match)),
        folderPath: folderPath == null ? const Value.absent() : Value(folderPath),
      ));

  @override
  Future<void> mergeRemote(String accountId, List<RuleSuggestion> remote, {DateTime? at}) async {
    final local = {for (final r in await (_db.select(_db.ruleSuggestions)..where((s) => s.accountId.equals(accountId))).get()) r.id: r};
    final remoteIds = <String>{};
    for (final s in remote) {
      remoteIds.add(s.id);
      final l = local[s.id];
      if (l != null && l.status != SuggestionStatus.pending.name) continue; // a local decision wins
      await _upsert(RuleSuggestion(
        id: s.id,
        accountId: accountId,
        match: s.match,
        folderPath: s.folderPath,
        rationale: s.rationale,
        confidence: s.confidence,
        source: s.source,
        evidenceCount: s.evidenceCount,
        examples: s.examples,
        createdAt: s.createdAt,
      ));
    }
    // Pending here but gone from the writer's list: decided on another device.
    final cutoff = at?.millisecondsSinceEpoch;
    final rules = await _rules.load(accountId);
    final ruleKeys = {for (final r in rules) if (r.action == RuleAction.moveTo && r.folderPath != null) RuleSuggestion.dedupeKeyFor(r.match.toJson(), r.folderPath!)};
    for (final l in local.values) {
      if (l.status != SuggestionStatus.pending.name || remoteIds.contains(l.id)) continue;
      if (cutoff != null && l.createdAt > cutoff) continue;
      final s = fromRow(l);
      final status = ruleKeys.contains(s.dedupeKey) ? SuggestionStatus.accepted : SuggestionStatus.dismissed;
      await _setStatus(l.id, status, at ?? DateTime.now().toUtc());
    }
  }

  /// Forgets dismissed / accepted rows older than [dismissMemory].
  Future<int> prune(String accountId, DateTime now) async {
    final cutoff = now.subtract(dismissMemory).millisecondsSinceEpoch;
    return (_db.delete(_db.ruleSuggestions)
          ..where((s) => s.accountId.equals(accountId) & s.status.equals(SuggestionStatus.pending.name).not() & s.decidedAt.isSmallerThanValue(cutoff)))
        .go();
  }

  static RuleSuggestion fromRow(db.RuleSuggestion r) => RuleSuggestion(
        id: r.id,
        accountId: r.accountId,
        match: ((jsonDecode(r.matchJson) as Map?) ?? const {}).cast<String, dynamic>(),
        folderPath: r.folderPath,
        rationale: r.rationale,
        confidence: r.confidence,
        source: r.source == SuggestionSource.model.name ? SuggestionSource.model : SuggestionSource.pattern,
        evidenceCount: r.evidenceCount,
        examples: ((jsonDecode(r.examplesJson) as List?) ?? const []).map((e) => e.toString()).toList(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt, isUtc: true),
        status: SuggestionStatus.values.byName(r.status),
        decidedAt: r.decidedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(r.decidedAt!, isUtc: true),
      );
}
