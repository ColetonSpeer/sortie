import 'dart:convert';

import 'package:drift/drift.dart';

import '../../data/local/database.dart' as db;
import '../../domain/entities/entities.dart';

enum RuleAction { moveTo, keepInInbox, neverAutoSort }

/// One custom-header criterion, e.g. `X-Mailer` contains `Outlook`.
class HeaderMatch {
  const HeaderMatch({required this.name, required this.value});
  final String name;
  final String value;

  static HeaderMatch? fromJson(Object? j) {
    if (j is! Map) return null;
    final name = j['name'] as String?, value = j['value'] as String?;
    if (name == null || value == null) return null;
    return HeaderMatch(name: name, value: value);
  }

  Map<String, dynamic> toJson() => {'name': name, 'value': value};
}

/// Criteria of one rule (all case-insensitive). By default every non-null
/// criterion must match; with [any] one matching criterion is enough.
///
/// [bodyContains] needs the message text: pass `bodyText` to [matches]
/// (the pipeline hands over `ClassificationInput.bodyText`). When the body is
/// not available the criterion simply does not match. [headerContains] is
/// evaluated against `List-Id` (always) and any extra raw headers passed in.
class RuleMatch {
  const RuleMatch({
    this.from,
    this.fromDomain,
    this.fromContains,
    this.fromEndsWith,
    this.listId,
    this.subjectContains,
    this.subjectIs,
    this.toContains,
    this.bodyContains,
    this.headerContains,
    this.any = false,
  });
  final String? from;
  final String? fromDomain;
  final String? fromContains;
  final String? fromEndsWith;
  final String? listId;
  final String? subjectContains;
  final String? subjectIs;
  final String? toContains;
  final String? bodyContains;
  final HeaderMatch? headerContains;

  /// OR semantics: true when at least one criterion matches.
  final bool any;

  bool get isEmpty =>
      from == null &&
      fromDomain == null &&
      fromContains == null &&
      fromEndsWith == null &&
      listId == null &&
      subjectContains == null &&
      subjectIs == null &&
      toContains == null &&
      bodyContains == null &&
      headerContains == null;

  static RuleMatch fromJson(Map<String, dynamic> j) => RuleMatch(
        from: j['from'] as String?,
        fromDomain: j['fromDomain'] as String?,
        fromContains: j['fromContains'] as String?,
        fromEndsWith: j['fromEndsWith'] as String?,
        listId: j['listId'] as String?,
        subjectContains: j['subjectContains'] as String?,
        subjectIs: j['subjectIs'] as String?,
        toContains: j['toContains'] as String?,
        bodyContains: j['bodyContains'] as String?,
        headerContains: HeaderMatch.fromJson(j['headerContains']),
        any: (j['any'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        if (from != null) 'from': from,
        if (fromDomain != null) 'fromDomain': fromDomain,
        if (fromContains != null) 'fromContains': fromContains,
        if (fromEndsWith != null) 'fromEndsWith': fromEndsWith,
        if (listId != null) 'listId': listId,
        if (subjectContains != null) 'subjectContains': subjectContains,
        if (subjectIs != null) 'subjectIs': subjectIs,
        if (toContains != null) 'toContains': toContains,
        if (bodyContains != null) 'bodyContains': bodyContains,
        if (headerContains != null) 'headerContains': headerContains!.toJson(),
        if (any) 'any': true,
      };

  /// Human summary used for folder-description hints and the UI.
  String describe() {
    final parts = <String>[
      if (from != null) 'from $from',
      if (fromDomain != null) 'from domain $fromDomain',
      if (fromContains != null) "from contains '$fromContains'",
      if (fromEndsWith != null) "from ends with '$fromEndsWith'",
      if (listId != null) 'list $listId',
      if (subjectContains != null) "subject contains '$subjectContains'",
      if (subjectIs != null) "subject is '$subjectIs'",
      if (toContains != null) "to contains '$toContains'",
      if (bodyContains != null) "body contains '$bodyContains'",
      if (headerContains != null) "header ${headerContains!.name} contains '${headerContains!.value}'",
    ];
    return parts.join(any ? ' or ' : '; ');
  }

  bool matches(MessageHeader h, {String? bodyText, Map<String, String> headers = const {}}) {
    if (isEmpty) return false;
    final fromEmail = h.from?.email.toLowerCase() ?? '';
    final fromFull = h.from.toString().toLowerCase();
    final subject = h.subject.toLowerCase();
    final results = <bool>[
      if (from != null) fromEmail == from!.toLowerCase(),
      if (fromDomain != null) (h.from?.domain ?? '') == fromDomain!.toLowerCase(),
      if (fromContains != null) fromFull.contains(fromContains!.toLowerCase()),
      if (fromEndsWith != null) fromEmail.endsWith(fromEndsWith!.toLowerCase()),
      if (listId != null) (h.listId ?? '').toLowerCase() == listId!.toLowerCase(),
      if (subjectContains != null) subject.contains(subjectContains!.toLowerCase()),
      if (subjectIs != null) subject.trim() == subjectIs!.toLowerCase().trim(),
      if (toContains != null) _toMatches(h),
      if (bodyContains != null) bodyText != null && bodyText.toLowerCase().contains(bodyContains!.toLowerCase()),
      if (headerContains != null) _headerMatches(h, headers),
    ];
    return any ? results.any((r) => r) : results.every((r) => r);
  }

  bool _toMatches(MessageHeader h) {
    final needle = toContains!.toLowerCase();
    return [...h.to, ...h.cc].any((a) => a.toString().toLowerCase().contains(needle));
  }

  bool _headerMatches(MessageHeader h, Map<String, String> headers) {
    final name = headerContains!.name.toLowerCase();
    final needle = headerContains!.value.toLowerCase();
    String? value;
    if (name == 'list-id') value = h.listId;
    for (final e in headers.entries) {
      if (e.key.toLowerCase() == name) value = e.value;
    }
    return value != null && value.toLowerCase().contains(needle);
  }
}

class SortRule {
  const SortRule({
    required this.id,
    required this.accountId,
    required this.priority,
    required this.match,
    required this.action,
    this.folderPath,
    this.hits = 0,
    this.enabled = true,
    this.name,
  });
  final String id;
  final String accountId;
  final int priority;
  final RuleMatch match;
  final RuleAction action;
  final String? folderPath;
  final int hits;

  /// Disabled rules are kept but never match (e.g. imported as disabled).
  final bool enabled;

  /// Optional label (Thunderbird filter name). Shown in the sort log reason.
  final String? name;

  /// Stable wire format shared between devices through the journal.
  /// `hits` is device-local and deliberately not included.
  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'priority': priority,
        'match': match.toJson(),
        'action': action.name,
        if (folderPath != null) 'folderPath': folderPath,
        'enabled': enabled,
        if (name != null) 'name': name,
      };

  static SortRule fromJson(Map<String, dynamic> j) => SortRule(
        id: j['id'] as String,
        accountId: j['accountId'] as String,
        priority: (j['priority'] as num?)?.toInt() ?? 100,
        match: RuleMatch.fromJson(((j['match'] as Map?) ?? const {}).cast<String, dynamic>()),
        action: RuleAction.values.byName((j['action'] as String?) ?? 'moveTo'),
        folderPath: j['folderPath'] as String?,
        enabled: (j['enabled'] as bool?) ?? true,
        name: j['name'] as String?,
      );

  /// `enabled` / `name` have no column of their own: they ride along inside
  /// `match_json` under reserved keys so no schema migration is needed.
  static SortRule fromRow(db.UserRule r) {
    final j = (jsonDecode(r.matchJson) as Map).cast<String, dynamic>();
    return SortRule(
      id: r.id,
      accountId: r.accountId,
      priority: r.priority,
      match: RuleMatch.fromJson(j),
      action: RuleAction.values.byName(r.action),
      folderPath: r.folderPath,
      hits: r.hits,
      enabled: (j[_enabledKey] as bool?) ?? true,
      name: j[_nameKey] as String?,
    );
  }

  static const _enabledKey = '_enabled', _nameKey = '_name';

  String _matchJson() => jsonEncode({
        ...match.toJson(),
        if (!enabled) _enabledKey: false,
        if (name != null) _nameKey: name,
      });
}

/// The subset of [UserRulesService] other modules (importer, journal) need,
/// so they can be tested with an in-memory implementation.
abstract class SortRuleStore {
  Future<List<SortRule>> load(String accountId);
  Future<void> upsert(SortRule r, DateTime now);
}

/// Layer 1a: explicit user rules, lowest priority number first, first match wins.
class UserRulesService implements SortRuleStore {
  UserRulesService(this._db);
  final db.SortieDatabase _db;

  SimpleSelectStatement<db.$UserRulesTable, db.UserRule> _query(String accountId) => _db.select(_db.userRules)
    ..where((r) => r.accountId.equals(accountId))
    ..orderBy([(r) => OrderingTerm.asc(r.priority), (r) => OrderingTerm.asc(r.createdAt)]);

  @override
  Future<List<SortRule>> load(String accountId) async => (await _query(accountId).get()).map(SortRule.fromRow).toList();

  Stream<List<SortRule>> watch(String accountId) => _query(accountId).watch().map((rows) => rows.map(SortRule.fromRow).toList());

  /// Body text and raw headers are optional: rules that need them do not
  /// match when they are absent.
  SortRule? firstMatch(List<SortRule> rules, MessageHeader h, {String? bodyText, Map<String, String> headers = const {}}) {
    for (final r in rules) {
      if (!r.enabled) continue;
      if (r.match.matches(h, bodyText: bodyText, headers: headers)) return r;
    }
    return null;
  }

  Future<void> recordHit(String id) async {
    await _db.customUpdate('UPDATE user_rules SET hits = hits + 1 WHERE id = ?',
        variables: [Variable.withString(id)], updates: {_db.userRules});
  }

  @override
  Future<void> upsert(SortRule r, DateTime now) async {
    final existing = await (_db.select(_db.userRules)..where((x) => x.id.equals(r.id))).getSingleOrNull();
    await _db.into(_db.userRules).insertOnConflictUpdate(db.UserRulesCompanion.insert(
          id: r.id,
          accountId: r.accountId,
          priority: r.priority,
          matchJson: r._matchJson(),
          action: r.action.name,
          folderPath: Value(r.folderPath),
          hits: Value(existing?.hits ?? r.hits),
          createdAt: existing?.createdAt ?? now.millisecondsSinceEpoch,
        ));
  }

  /// Makes the account's rule set equal to [rules]: ids are kept, rows not in
  /// the list are removed, existing rows keep their hit counts. Safe to call
  /// repeatedly with the same input (journal replay).
  Future<void> replaceAll(String accountId, List<SortRule> rules, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    await _db.transaction(() async {
      final keep = {for (final r in rules) r.id};
      await (_db.delete(_db.userRules)..where((r) => r.accountId.equals(accountId) & r.id.isNotIn(keep.toList()))).go();
      for (final r in rules) {
        await upsert(r, at);
      }
    });
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.userRules)..where((r) => r.id.equals(id))).go();
  }
}
