import 'dart:convert';

import '../../data/local/database.dart' show JournalEvent;
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/services.dart';
import 'control_messages.dart';
import 'journal_store.dart';

/// Turns materialized `journal_events` rows into Sort Log entries, looking
/// up subject / sender in the local message cache.
class SortLogMapper {
  SortLogMapper({required this.accountId, required MessageRepository messages, required JournalStore store})
      : _messages = messages,
        _store = store;

  final String accountId;
  final MessageRepository _messages;
  final JournalStore _store;

  Future<List<SortLogEntry>> map(List<JournalEvent> rows) async {
    final out = <SortLogEntry>[];
    for (final r in rows) {
      final body = jsonDecode(r.bodyJson) as Map<String, dynamic>;
      final at = DateTime.fromMillisecondsSinceEpoch(r.internalDate, isUtc: true);
      switch (r.type) {
        case ControlTypes.decision:
          var i = 0;
          for (final item in (body['items'] as List?) ?? const []) {
            if (item is! Map<String, dynamic>) continue;
            final d = SortDecision.fromJson(accountId, item);
            final (subject, from) = await _names(d.key.messageIdHash);
            out.add(SortLogEntry(
              id: '${r.uid}:${i++}',
              at: at,
              type: 'decision',
              key: d.key,
              subject: subject,
              from: from,
              fromFolder: d.sourceFolder,
              toFolder: d.destination,
              reason: d.reason,
              confidence: d.confidence,
              deviceId: r.deviceId,
              cause: d.mode.name,
              decisionId: d.id,
            ));
          }
        case ControlTypes.moved:
          var i = 0;
          for (final item in (body['items'] as List?) ?? const []) {
            if (item is! Map<String, dynamic>) continue;
            final keyJson = (item['key'] as Map?)?.cast<String, dynamic>() ?? const {};
            final key = messageKeyFromJson(accountId, keyJson);
            final (subject, from) = await _names(key.messageIdHash, fallbackSubject: keyJson['subject'] as String?, fallbackFrom: keyJson['from'] as String?);
            final decisionId = item['decisionId'] as String?;
            final cause = (item['cause'] as String?) ?? 'manual';
            var undoable = cause != 'undo';
            if (undoable && decisionId != null) {
              final d = await _store.decisionById(decisionId);
              undoable = d != null && d.status != DecisionStatus.undone;
            }
            out.add(SortLogEntry(
              id: '${r.uid}:${i++}',
              at: at,
              type: 'moved',
              key: key,
              subject: subject,
              from: from,
              fromFolder: item['from'] as String?,
              toFolder: item['to'] as String?,
              deviceId: r.deviceId,
              cause: cause,
              undoable: undoable,
              decisionId: decisionId,
            ));
          }
        case ControlTypes.undo:
          final key = messageKeyFromJson(accountId, (body['key'] as Map).cast<String, dynamic>());
          final (subject, from) = await _names(key.messageIdHash);
          out.add(SortLogEntry(
            id: '${r.uid}',
            at: at,
            type: 'undo',
            key: key,
            subject: subject,
            from: from,
            toFolder: 'INBOX',
            deviceId: r.deviceId,
            cause: body['executed'] == true ? 'executed' : 'queued',
            decisionId: body['decisionId'] as String?,
          ));
        case ControlTypes.correction:
          final c = Correction.fromJson(accountId, body);
          final (subject, from) = await _names(c.key.messageIdHash, fallbackSubject: c.subjectNorm, fallbackFrom: c.fromAddress);
          out.add(SortLogEntry(
            id: '${r.uid}',
            at: at,
            type: 'correction',
            key: c.key,
            subject: subject,
            from: from,
            fromFolder: c.predictedFolder,
            toFolder: c.actualFolder,
            deviceId: r.deviceId,
            cause: c.kind.name,
            decisionId: c.decisionId,
          ));
        case ControlTypes.resolved:
          final key = messageKeyFromJson(accountId, (body['key'] as Map).cast<String, dynamic>());
          final (subject, from) = await _names(key.messageIdHash);
          out.add(SortLogEntry(
            id: '${r.uid}',
            at: at,
            type: 'resolved',
            key: key,
            subject: subject,
            from: from,
            deviceId: r.deviceId,
            cause: body['why'] as String?,
          ));
      }
    }
    return out;
  }

  Future<(String, String)> _names(String mid, {String? fallbackSubject, String? fallbackFrom}) async {
    final h = await _messages.byMessageIdHash(accountId, mid);
    return (h?.subject ?? fallbackSubject ?? '', h?.from?.toString() ?? fallbackFrom ?? '');
  }
}
