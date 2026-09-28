import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../domain/entities/entities.dart';
import '../../sorter/user_rules.dart';
import 'filter_rules_parser.dart';
import 'import_models.dart';

/// Turns one Thunderbird filter into Sortie sort rules.
///
/// Only folder actions become rules. Each supported condition maps onto a
/// [RuleMatch] field; `(status,is,read)` is dropped (Sortie's leave-until-read
/// setting covers it). OR filters whose terms all fit one [RuleMatch] become a
/// single rule with `any`, otherwise one rule per term. Ids are derived from
/// the account id and filter name so a re-import updates instead of
/// duplicating.
class RuleMapper {
  const RuleMapper();

  RuleImportOutcome map(TbFilter f, {required String accountId, required List<Folder> folders, required int priority}) {
    final folderAction = f.folderActions.firstOrNull;
    if (folderAction == null) {
      return RuleImportOutcome(filterName: f.name, rules: const [], skippedReason: 'no "Move to folder" action (${f.actions.map((a) => a.type).join(', ')})');
    }
    final rawPath = folderPathFromUri(folderAction.value ?? '');
    if (rawPath == null) return RuleImportOutcome(filterName: f.name, rules: const [], skippedReason: 'folder URI not understood: ${folderAction.value}');
    final target = resolveFolder(rawPath, folders);

    var droppedStatus = false;
    final matches = <RuleMatch>[];
    final unsupported = <String>[];
    for (final c in f.conditions) {
      if (c.field == 'status' && c.op == 'is' && c.value.toLowerCase() == 'read') {
        droppedStatus = true;
        continue;
      }
      final m = conditionToMatch(c);
      if (m == null) {
        unsupported.add(c.toString());
      } else {
        matches.add(m);
      }
    }
    if (matches.isEmpty) {
      final why = unsupported.isEmpty ? 'no usable conditions' : 'unsupported conditions: ${unsupported.join(' ')}';
      return RuleImportOutcome(filterName: f.name, rules: const [], folderPath: target.path, missingFolder: target.missing, droppedStatusRead: droppedStatus, skippedReason: why);
    }
    if (unsupported.isNotEmpty && !f.anyCondition) {
      return RuleImportOutcome(filterName: f.name, rules: const [], folderPath: target.path, missingFolder: target.missing, droppedStatusRead: droppedStatus, skippedReason: 'AND rule has unsupported conditions: ${unsupported.join(' ')}');
    }

    final combined = f.anyCondition ? _combineAny(matches) : _combineAll(matches);
    final rules = <SortRule>[];
    if (combined != null) {
      rules.add(_rule(accountId, f, combined, target.path, priority, 0));
    } else if (f.anyCondition) {
      for (var i = 0; i < matches.length; i++) {
        rules.add(_rule(accountId, f, matches[i], target.path, priority, i + 1));
      }
    } else {
      return RuleImportOutcome(filterName: f.name, rules: const [], folderPath: target.path, missingFolder: target.missing, droppedStatusRead: droppedStatus, skippedReason: 'AND rule repeats the same field twice');
    }
    return RuleImportOutcome(filterName: f.name, rules: rules, folderPath: target.path, missingFolder: target.missing, droppedStatusRead: droppedStatus);
  }

  SortRule _rule(String accountId, TbFilter f, RuleMatch m, String folderPath, int priority, int part) => SortRule(
        id: ruleId(accountId, f.name, part),
        accountId: accountId,
        priority: priority,
        match: m,
        action: RuleAction.moveTo,
        folderPath: folderPath,
        enabled: f.enabled,
        name: part == 0 ? f.name : '${f.name} ($part)',
      );

  /// Deterministic id: same account + filter name -> same rule on re-import.
  static String ruleId(String accountId, String filterName, int part) {
    final h = sha256.convert(utf8.encode('tb|$accountId|$filterName|$part')).toString();
    return 'tb-${h.substring(0, 16)}';
  }

  /// One condition -> one single-field match, or null when unsupported.
  static RuleMatch? conditionToMatch(TbCondition c) {
    final field = c.field.toLowerCase();
    final v = c.value.trim();
    if (v.isEmpty) return null;
    switch ((field, c.op)) {
      case ('from', 'is'):
        return RuleMatch(from: v);
      case ('from', 'ends with'):
        return RuleMatch(fromEndsWith: v);
      case ('from', 'contains'):
        return RuleMatch(fromContains: v);
      case ('subject', 'contains'):
        return RuleMatch(subjectContains: v);
      case ('subject', 'is'):
        return RuleMatch(subjectIs: v);
      case ('body', 'contains'):
        return RuleMatch(bodyContains: v);
      case ('to', 'contains') || ('cc', 'contains') || ('to or cc', 'contains') || ('all addresses', 'contains'):
        return RuleMatch(toContains: v);
      case ('to', 'is') || ('cc', 'is') || ('to or cc', 'is') || ('all addresses', 'is'):
        return RuleMatch(toContains: v);
      case ('list-id', 'is'):
        return RuleMatch(listId: v);
      case (_, 'contains') || (_, 'is'):
        if (_knownFields.contains(field)) return null;
        return RuleMatch(headerContains: HeaderMatch(name: c.field, value: v));
    }
    return null;
  }

  static const _knownFields = {'subject', 'from', 'to', 'cc', 'to or cc', 'all addresses', 'body', 'date', 'priority', 'status', 'size', 'age in days', 'tag', 'junk status', 'junk score origin', 'junk percent', 'attachment status', 'has attachment status'};

  /// AND: every field at most once, else null.
  static RuleMatch? _combineAll(List<RuleMatch> ms) => _merge(ms, any: false);

  /// OR: one rule with `any` when fields do not collide, else null.
  static RuleMatch? _combineAny(List<RuleMatch> ms) => ms.length == 1 ? ms.first : _merge(ms, any: true);

  static RuleMatch? _merge(List<RuleMatch> ms, {required bool any}) {
    final j = <String, dynamic>{};
    for (final m in ms) {
      for (final e in m.toJson().entries) {
        if (j.containsKey(e.key)) return null;
        j[e.key] = e.value;
      }
    }
    if (any) j['any'] = true;
    return RuleMatch.fromJson(j);
  }

  /// Matches the Thunderbird path (`/`-separated) against the account's
  /// folders, case-insensitively, normalising to the account's delimiter.
  /// A missing folder keeps the normalised path and is flagged.
  static ({String path, bool missing}) resolveFolder(String tbPath, List<Folder> folders) {
    final delimiter = folders.isEmpty ? '/' : folders.first.delimiter;
    final segments = tbPath.split('/').where((s) => s.isNotEmpty).toList();
    final normalised = segments.join(delimiter);
    final candidates = <String>{
      normalised,
      if (segments.length > 1 && segments.first.toUpperCase() == 'INBOX') segments.skip(1).join(delimiter),
      if (segments.first.toUpperCase() != 'INBOX') ['INBOX', ...segments].join(delimiter),
    };
    for (final c in candidates) {
      for (final f in folders) {
        if (f.path.toLowerCase() == c.toLowerCase()) return (path: f.path, missing: false);
      }
    }
    return (path: normalised, missing: true);
  }
}

/// Folder-description hints: one `Rules: a | b` line per folder, merged and
/// deduplicated with whatever the user already wrote.
abstract final class FolderHints {
  static const prefix = 'Rules: ';

  static String merge(String existing, List<String> clauses) {
    final lines = existing.split('\n');
    final idx = lines.indexWhere((l) => l.startsWith(prefix));
    final current = idx < 0 ? <String>[] : lines[idx].substring(prefix.length).split(' | ').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    for (final c in clauses) {
      if (!current.contains(c)) current.add(c);
    }
    final line = '$prefix${current.join(' | ')}';
    if (idx >= 0) {
      lines[idx] = line;
    } else if (existing.trim().isNotEmpty) {
      lines.add(line);
    } else {
      return line;
    }
    return lines.join('\n').trim();
  }
}
