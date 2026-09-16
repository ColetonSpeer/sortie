import 'dart:convert';

import 'package:drift/drift.dart';

import '../../data/local/database.dart' as db;
import '../../domain/entities/entities.dart';

enum RuleAction { moveTo, keepInInbox, neverAutoSort }

/// All non-null criteria must match (case-insensitive).
class RuleMatch {
  const RuleMatch({this.from, this.fromDomain, this.fromContains, this.listId, this.subjectContains, this.toContains});
  final String? from;
  final String? fromDomain;
  final String? fromContains;
  final String? listId;
  final String? subjectContains;
  final String? toContains;

  bool get isEmpty =>
      from == null && fromDomain == null && fromContains == null && listId == null && subjectContains == null && toContains == null;

  static RuleMatch fromJson(Map<String, dynamic> j) => RuleMatch(
        from: j['from'] as String?,
        fromDomain: j['fromDomain'] as String?,
        fromContains: j['fromContains'] as String?,
        listId: j['listId'] as String?,
        subjectContains: j['subjectContains'] as String?,
        toContains: j['toContains'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (from != null) 'from': from,
        if (fromDomain != null) 'fromDomain': fromDomain,
        if (fromContains != null) 'fromContains': fromContains,
        if (listId != null) 'listId': listId,
        if (subjectContains != null) 'subjectContains': subjectContains,
        if (toContains != null) 'toContains': toContains,
      };

  bool matches(MessageHeader h) {
    if (isEmpty) return false;
    final fromEmail = h.from?.email.toLowerCase() ?? '';
    if (from != null && fromEmail != from!.toLowerCase()) return false;
    if (fromDomain != null && (h.from?.domain ?? '') != fromDomain!.toLowerCase()) return false;
    if (fromContains != null && !h.from.toString().toLowerCase().contains(fromContains!.toLowerCase())) return false;
    if (listId != null && (h.listId ?? '').toLowerCase() != listId!.toLowerCase()) return false;
    if (subjectContains != null && !h.subject.toLowerCase().contains(subjectContains!.toLowerCase())) return false;
    if (toContains != null) {
      final needle = toContains!.toLowerCase();
      if (![...h.to, ...h.cc].any((a) => a.toString().toLowerCase().contains(needle))) return false;
    }
    return true;
  }
}

class SortRule {
  const SortRule({required this.id, required this.accountId, required this.priority, required this.match, required this.action, this.folderPath, this.hits = 0});
  final String id;
  final String accountId;
  final int priority;
  final RuleMatch match;
  final RuleAction action;
  final String? folderPath;
  final int hits;

  static SortRule fromRow(db.UserRule r) => SortRule(
        id: r.id,
        accountId: r.accountId,
        priority: r.priority,
        match: RuleMatch.fromJson((jsonDecode(r.matchJson) as Map).cast<String, dynamic>()),
        action: RuleAction.values.byName(r.action),
        folderPath: r.folderPath,
        hits: r.hits,
      );
}

/// Layer 1a: explicit user rules, lowest priority number first, first match wins.
class UserRulesService {
  UserRulesService(this._db);
  final db.SortieDatabase _db;

  Future<List<SortRule>> load(String accountId) async {
    final rows = await (_db.select(_db.userRules)
          ..where((r) => r.accountId.equals(accountId))
          ..orderBy([(r) => OrderingTerm.asc(r.priority), (r) => OrderingTerm.asc(r.createdAt)]))
        .get();
    return rows.map(SortRule.fromRow).toList();
  }

  SortRule? firstMatch(List<SortRule> rules, MessageHeader h) {
    for (final r in rules) {
      if (r.match.matches(h)) return r;
    }
    return null;
  }

  Future<void> recordHit(String id) async {
    await _db.customUpdate('UPDATE user_rules SET hits = hits + 1 WHERE id = ?',
        variables: [Variable.withString(id)], updates: {_db.userRules});
  }

  Future<void> upsert(SortRule r, DateTime now) async {
    await _db.into(_db.userRules).insertOnConflictUpdate(db.UserRulesCompanion.insert(
          id: r.id,
          accountId: r.accountId,
          priority: r.priority,
          matchJson: jsonEncode(r.match.toJson()),
          action: r.action.name,
          folderPath: Value(r.folderPath),
          createdAt: now.millisecondsSinceEpoch,
        ));
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.userRules)..where((r) => r.id.equals(id))).go();
  }
}
