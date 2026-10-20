import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/clock.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';
import '../database.dart' as d;

/// Message header cache, FTS5 index upkeep and body cache.
///
/// Primary key of `messages` is (accountId, messageIdHash, folderPath); the
/// FTS row is keyed by (accountId, messageIdHash) so one search hit covers
/// every folder the message sits in.
class DriftMessageRepository implements MessageRepository {
  DriftMessageRepository(this.db, {Clock? clock}) : clock = clock ?? SystemClock();
  final d.SortieDatabase db;
  final Clock clock;

  // ------------------------------------------------------------ mapping

  static List<MailAddress> _addrs(String json) {
    try {
      return (jsonDecode(json) as List).map((e) => MailAddress((e as Map)['e'] as String, e['n'] as String?)).toList();
    } catch (_) {
      return const [];
    }
  }

  static String _addrsJson(List<MailAddress> list) => jsonEncode([
        for (final a in list) {'e': a.email, if (a.name != null) 'n': a.name},
      ]);

  static List<String> _strList(String json) {
    try {
      return (jsonDecode(json) as List).cast<String>();
    } catch (_) {
      return const [];
    }
  }

  static List<AttachmentInfo> _attachments(String json) {
    try {
      return (jsonDecode(json) as List)
          .map((e) => AttachmentInfo(partId: (e as Map)['p'] as String, fileName: e['f'] as String, mimeType: e['m'] as String, size: (e['s'] as num).toInt()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static String _attachmentsJson(List<AttachmentInfo> list) => jsonEncode([
        for (final a in list) {'p': a.partId, 'f': a.fileName, 'm': a.mimeType, 's': a.size},
      ]);

  static MessageHeader toEntity(d.Message r) => MessageHeader(
        accountId: r.accountId,
        folderPath: r.folderPath,
        uid: r.uid ?? 0,
        uidValidity: r.uidValidity ?? 0,
        messageIdHash: r.messageIdHash,
        messageId: r.messageId,
        subject: r.subject,
        from: r.fromEmail == null ? null : MailAddress(r.fromEmail!, r.fromName),
        to: _addrs(r.toAddressesJson),
        cc: _addrs(r.ccJson),
        replyTo: r.replyTo == null ? null : MailAddress(r.replyTo!),
        date: DateTime.fromMillisecondsSinceEpoch(r.date, isUtc: true),
        internalDate: r.internalDate == null ? null : DateTime.fromMillisecondsSinceEpoch(r.internalDate!, isUtc: true),
        listId: r.listId,
        inReplyTo: r.inReplyTo,
        references: _strList(r.referencesJson),
        precedence: r.precedence,
        autoSubmitted: r.autoSubmitted,
        hasListUnsubscribe: r.hasListUnsubscribe,
        flags: _strList(r.flagsJson).toSet(),
        size: r.size,
        snippet: r.snippet,
        attachments: _attachments(r.attachmentsJson),
      );

  static d.MessagesCompanion toRow(MessageHeader h) => d.MessagesCompanion(
        accountId: Value(h.accountId),
        messageIdHash: Value(h.messageIdHash),
        folderPath: Value(h.folderPath),
        uid: Value(h.uid),
        uidValidity: Value(h.uidValidity),
        messageId: Value(h.messageId),
        subject: Value(h.subject),
        fromEmail: Value(h.from?.email),
        fromName: Value(h.from?.name),
        toAddressesJson: Value(_addrsJson(h.to)),
        ccJson: Value(_addrsJson(h.cc)),
        replyTo: Value(h.replyTo?.email),
        date: Value(h.date.toUtc().millisecondsSinceEpoch),
        internalDate: Value(h.internalDate?.toUtc().millisecondsSinceEpoch),
        listId: Value(h.listId),
        inReplyTo: Value(h.inReplyTo),
        referencesJson: Value(jsonEncode(h.references)),
        precedence: Value(h.precedence),
        autoSubmitted: Value(h.autoSubmitted),
        hasListUnsubscribe: Value(h.hasListUnsubscribe),
        flagsJson: Value(jsonEncode(h.flags.toList()..sort())),
        size: Value(h.size),
        snippet: Value(h.snippet),
        attachmentsJson: Value(_attachmentsJson(h.attachments)),
      );

  // ------------------------------------------------------------ queries

  SimpleSelectStatement<d.$MessagesTable, d.Message> _list(MessageQuery q) {
    final s = db.select(db.messages);
    if (q.unifiedInbox) {
      s.where((t) => t.folderPath.equals('INBOX'));
    } else {
      s.where((t) => t.accountId.equals(q.accountId) & (q.folderPath == null ? const Constant(true) : t.folderPath.equals(q.folderPath!)));
    }
    s
      ..orderBy([(t) => OrderingTerm.desc(t.date), (t) => OrderingTerm.desc(t.uid)])
      ..limit(q.limit, offset: q.offset);
    return s;
  }

  @override
  Stream<List<MessageHeader>> watch(MessageQuery q) {
    if (q.search != null && q.search!.trim().isNotEmpty) {
      return Stream.fromFuture(search(q.accountId, q.search!, limit: q.limit));
    }
    return _list(q).watch().map((rows) => rows.map(toEntity).toList());
  }

  @override
  Future<List<MessageHeader>> list(MessageQuery q) async {
    if (q.search != null && q.search!.trim().isNotEmpty) return search(q.accountId, q.search!, limit: q.limit);
    return (await _list(q).get()).map(toEntity).toList();
  }

  @override
  Future<MessageHeader?> byUid(String accountId, String folderPath, int uid) async {
    final r = await (db.select(db.messages)..where((t) => t.accountId.equals(accountId) & t.folderPath.equals(folderPath) & t.uid.equals(uid))).getSingleOrNull();
    return r == null ? null : toEntity(r);
  }

  SimpleSelectStatement<d.$MessagesTable, d.Message> _byHash(String accountId, String hash) => db.select(db.messages)
    ..where((t) => t.accountId.equals(accountId) & t.messageIdHash.equals(hash))
    ..orderBy([(t) => OrderingTerm.desc(t.uid)])
    ..limit(1);

  @override
  Future<MessageHeader?> byMessageIdHash(String accountId, String messageIdHash) async {
    final r = await _byHash(accountId, messageIdHash).getSingleOrNull();
    return r == null ? null : toEntity(r);
  }

  @override
  Stream<MessageHeader?> watchByMessageIdHash(String accountId, String messageIdHash) =>
      _byHash(accountId, messageIdHash).watchSingleOrNull().map((r) => r == null ? null : toEntity(r));

  @override
  Future<List<int>> knownUids(String accountId, String folderPath) async {
    final q = db.selectOnly(db.messages)
      ..addColumns([db.messages.uid])
      ..where(db.messages.accountId.equals(accountId) & db.messages.folderPath.equals(folderPath) & db.messages.uid.isNotNull())
      ..orderBy([OrderingTerm.asc(db.messages.uid)]);
    return (await q.get()).map((r) => r.read(db.messages.uid)!).toList();
  }

  @override
  Future<int?> maxUid(String accountId, String folderPath) async {
    final m = db.messages.uid.max();
    final q = db.selectOnly(db.messages)
      ..addColumns([m])
      ..where(db.messages.accountId.equals(accountId) & db.messages.folderPath.equals(folderPath));
    return (await q.getSingle()).read(m);
  }

  @override
  Future<List<MessageHeader>> sample(String accountId, String folderPath, {int limit = 200}) async {
    final rows = await (db.select(db.messages)
          ..where((t) => t.accountId.equals(accountId) & t.folderPath.equals(folderPath))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .get();
    return rows.map(toEntity).toList();
  }

  // ------------------------------------------------------------ writes

  @override
  Future<void> upsertHeaders(List<MessageHeader> headers) async {
    if (headers.isEmpty) return;
    await db.transaction(() async {
      // Preserve a snippet already derived from the body.
      final existing = <String, String>{};
      for (final h in headers.where((h) => h.snippet.isEmpty)) {
        final r = await (db.selectOnly(db.messages)
              ..addColumns([db.messages.snippet])
              ..where(db.messages.accountId.equals(h.accountId) & db.messages.messageIdHash.equals(h.messageIdHash) & db.messages.folderPath.equals(h.folderPath)))
            .getSingleOrNull();
        final s = r?.read(db.messages.snippet);
        if (s != null && s.isNotEmpty) existing[h.messageIdHash] = s;
      }
      await db.batch((b) {
        b.insertAllOnConflictUpdate(db.messages, [
          for (final h in headers) toRow(existing.containsKey(h.messageIdHash) ? h.copyWith(snippet: existing[h.messageIdHash]) : h),
        ]);
      });
      for (final h in headers) {
        await _ftsUpsert(h.accountId, h.messageIdHash, subject: h.subject, from: _fromText(h));
      }
    });
  }

  static String _fromText(MessageHeader h) => h.from == null ? '' : '${h.from!.name ?? ''} ${h.from!.email}'.trim();

  Future<void> _ftsUpsert(String accountId, String hash, {String? subject, String? from, String? bodyText}) async {
    final rows = await db.customSelect('SELECT rowid AS id FROM messages_fts WHERE account_id = ? AND message_id_hash = ?', variables: [Variable.withString(accountId), Variable.withString(hash)]).get();
    if (rows.isEmpty) {
      String subj = subject ?? '', frm = from ?? '';
      if (subject == null || from == null) {
        final m = await _byHash(accountId, hash).getSingleOrNull();
        if (m != null) {
          subj = subject ?? m.subject;
          frm = from ?? _fromText(toEntity(m));
        }
      }
      await db.customStatement('INSERT INTO messages_fts(account_id, message_id_hash, subject, from_text, body_text) VALUES (?, ?, ?, ?, ?)', [accountId, hash, subj, frm, bodyText ?? '']);
      return;
    }
    final id = rows.first.read<int>('id');
    final sets = <String>[];
    final args = <Object?>[];
    if (subject != null) {
      sets.add('subject = ?');
      args.add(subject);
    }
    if (from != null) {
      sets.add('from_text = ?');
      args.add(from);
    }
    if (bodyText != null) {
      sets.add('body_text = ?');
      args.add(bodyText);
    }
    if (sets.isEmpty) return;
    args.add(id);
    await db.customStatement('UPDATE messages_fts SET ${sets.join(', ')} WHERE rowid = ?', args);
  }

  Future<void> _ftsDeleteIfOrphan(String accountId, String hash) async {
    final left = await (db.selectOnly(db.messages)
          ..addColumns([db.messages.messageIdHash.count()])
          ..where(db.messages.accountId.equals(accountId) & db.messages.messageIdHash.equals(hash)))
        .getSingle();
    if ((left.read(db.messages.messageIdHash.count()) ?? 0) > 0) return;
    await db.customStatement('DELETE FROM messages_fts WHERE account_id = ? AND message_id_hash = ?', [accountId, hash]);
    await (db.delete(db.messageBodies)..where((t) => t.accountId.equals(accountId) & t.messageIdHash.equals(hash))).go();
  }

  @override
  Future<void> updateFlags(String accountId, String folderPath, Map<int, Set<String>> flagsByUid) async {
    if (flagsByUid.isEmpty) return;
    await db.transaction(() async {
      for (final e in flagsByUid.entries) {
        await (db.update(db.messages)..where((t) => t.accountId.equals(accountId) & t.folderPath.equals(folderPath) & t.uid.equals(e.key)))
            .write(d.MessagesCompanion(flagsJson: Value(jsonEncode(e.value.toList()..sort()))));
      }
    });
  }

  @override
  Future<void> removeByUids(String accountId, String folderPath, List<int> uids) async {
    if (uids.isEmpty) return;
    await db.transaction(() async {
      for (var i = 0; i < uids.length; i += 500) {
        final chunk = uids.sublist(i, i + 500 > uids.length ? uids.length : i + 500);
        final rows = await (db.select(db.messages)..where((t) => t.accountId.equals(accountId) & t.folderPath.equals(folderPath) & t.uid.isIn(chunk))).get();
        await (db.delete(db.messages)..where((t) => t.accountId.equals(accountId) & t.folderPath.equals(folderPath) & t.uid.isIn(chunk))).go();
        for (final r in rows) {
          await _ftsDeleteIfOrphan(accountId, r.messageIdHash);
        }
      }
    });
  }

  /// Moves cached rows to [toFolder]. The destination UID is taken from
  /// [newUids] when known (COPYUID), otherwise stored as null and relinked by
  /// Message-ID hash on the next sync of [toFolder].
  @override
  Future<void> moveLocally(String accountId, String fromFolder, List<int> uids, String toFolder, {Map<int, int> newUids = const {}}) async {
    if (uids.isEmpty) return;
    await db.transaction(() async {
      final rows = await (db.select(db.messages)..where((t) => t.accountId.equals(accountId) & t.folderPath.equals(fromFolder) & t.uid.isIn(uids))).get();
      for (final r in rows) {
        await (db.delete(db.messages)..where((t) => t.accountId.equals(accountId) & t.folderPath.equals(fromFolder) & t.messageIdHash.equals(r.messageIdHash))).go();
        final newUid = newUids[r.uid];
        await db.into(db.messages).insertOnConflictUpdate(r.toCompanion(false).copyWith(
              folderPath: Value(toFolder),
              uid: Value(newUid),
              uidValidity: newUid == null ? const Value(null) : Value(r.uidValidity),
            ));
      }
    });
  }

  @override
  Future<void> invalidateUids(String accountId, String folderPath) => (db.update(db.messages)..where((t) => t.accountId.equals(accountId) & t.folderPath.equals(folderPath)))
      .write(const d.MessagesCompanion(uid: Value(null), uidValidity: Value(null)));

  @override
  Future<void> relinkUid(String accountId, String folderPath, String messageIdHash, int uid, int uidValidity) =>
      (db.update(db.messages)..where((t) => t.accountId.equals(accountId) & t.folderPath.equals(folderPath) & t.messageIdHash.equals(messageIdHash)))
          .write(d.MessagesCompanion(uid: Value(uid), uidValidity: Value(uidValidity)));

  @override
  Future<void> deleteOrphans(String accountId, String folderPath) => db.transaction(() async {
        final rows = await (db.select(db.messages)..where((t) => t.accountId.equals(accountId) & t.folderPath.equals(folderPath) & t.uid.isNull())).get();
        await (db.delete(db.messages)..where((t) => t.accountId.equals(accountId) & t.folderPath.equals(folderPath) & t.uid.isNull())).go();
        for (final r in rows) {
          await _ftsDeleteIfOrphan(accountId, r.messageIdHash);
        }
      });

  // ------------------------------------------------------------ search

  /// Turns free text into an FTS5 query: every token becomes a quoted prefix
  /// term so user input can never be a syntax error.
  static String ftsQuery(String input) {
    final tokens = input.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).map((t) => t.replaceAll('"', '""'));
    return tokens.map((t) => '"$t"*').join(' ');
  }

  @override
  Future<List<MessageHeader>> search(String accountId, String query, {int limit = 100}) async {
    final q = ftsQuery(query);
    if (q.isEmpty) return const [];
    final rows = await db.customSelect(
      'SELECT m.* FROM messages m JOIN ('
      '  SELECT account_id, message_id_hash, bm25(messages_fts) AS rank FROM messages_fts'
      '  WHERE messages_fts MATCH ? AND account_id = ?'
      ') f ON f.account_id = m.account_id AND f.message_id_hash = m.message_id_hash '
      'WHERE m.account_id = ? ORDER BY f.rank, m.date DESC LIMIT ?',
      variables: [Variable.withString(q), Variable.withString(accountId), Variable.withString(accountId), Variable.withInt(limit)],
      readsFrom: {db.messages},
    ).get();
    return rows.map((r) => toEntity(db.messages.map(r.data))).toList();
  }

  // ------------------------------------------------------------ bodies

  @override
  Future<MessageBody?> cachedBody(String accountId, String messageIdHash) async {
    final r = await (db.select(db.messageBodies)..where((t) => t.accountId.equals(accountId) & t.messageIdHash.equals(messageIdHash))).getSingleOrNull();
    if (r == null) return null;
    await (db.update(db.messageBodies)..where((t) => t.accountId.equals(accountId) & t.messageIdHash.equals(messageIdHash)))
        .write(d.MessageBodiesCompanion(lastAccessAt: Value(clock.now().toUtc().millisecondsSinceEpoch)));
    Map<String, List<int>> inline = const {};
    try {
      inline = (jsonDecode(r.inlineJson) as Map<String, dynamic>).map((k, v) => MapEntry(k, base64Decode(v as String)));
    } catch (_) {}
    final header = await _byHash(accountId, messageIdHash).getSingleOrNull();
    return MessageBody(
      text: r.bodyText,
      html: r.html,
      inlineParts: inline,
      attachments: header == null ? const [] : _attachments(header.attachmentsJson),
      calendar: r.calendarText,
    );
  }

  @override
  Future<void> cacheBody(String accountId, String messageIdHash, MessageBody body) async {
    final inlineJson = jsonEncode(body.inlineParts.map((k, v) => MapEntry(k, base64Encode(v))));
    final size = body.text.length + (body.html?.length ?? 0) + inlineJson.length;
    final now = clock.now().toUtc().millisecondsSinceEpoch;
    await db.transaction(() async {
      await db.into(db.messageBodies).insertOnConflictUpdate(d.MessageBodiesCompanion(
        accountId: Value(accountId),
        messageIdHash: Value(messageIdHash),
        bodyText: Value(body.text),
        html: Value(body.html),
        inlineJson: Value(inlineJson),
        calendarText: Value(body.calendar),
        sizeBytes: Value(size),
        cachedAt: Value(now),
        lastAccessAt: Value(now),
      ));
      await _afterBodyText(accountId, messageIdHash, body.text);
    });
  }

  @override
  Future<void> cacheBodyText(String accountId, String messageIdHash, String text) async {
    final now = clock.now().toUtc().millisecondsSinceEpoch;
    await db.transaction(() async {
      final existing = await (db.select(db.messageBodies)..where((t) => t.accountId.equals(accountId) & t.messageIdHash.equals(messageIdHash))).getSingleOrNull();
      if (existing == null) {
        await db.into(db.messageBodies).insert(d.MessageBodiesCompanion(
          accountId: Value(accountId),
          messageIdHash: Value(messageIdHash),
          bodyText: Value(text),
          sizeBytes: Value(text.length),
          cachedAt: Value(now),
          lastAccessAt: Value(now),
        ));
      }
      await _afterBodyText(accountId, messageIdHash, text);
    });
  }

  Future<void> _afterBodyText(String accountId, String hash, String text) async {
    await _ftsUpsert(accountId, hash, bodyText: text);
    final snippet = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (snippet.isEmpty) return;
    await (db.update(db.messages)..where((t) => t.accountId.equals(accountId) & t.messageIdHash.equals(hash) & t.snippet.equals('')))
        .write(d.MessagesCompanion(snippet: Value(snippet.length > 160 ? snippet.substring(0, 160) : snippet)));
  }

  /// Total bytes held by the body cache.
  Future<int> bodyCacheSize() async {
    final sum = db.messageBodies.sizeBytes.sum();
    final r = await (db.selectOnly(db.messageBodies)..addColumns([sum])).getSingle();
    return r.read(sum) ?? 0;
  }

  /// LRU eviction by lastAccessAt until the cache fits [maxBytes].
  /// Returns the number of bodies removed.
  Future<int> pruneBodyCache(int maxBytes) async {
    var total = await bodyCacheSize();
    var removed = 0;
    while (total > maxBytes) {
      final victims = await (db.select(db.messageBodies)..orderBy([(t) => OrderingTerm.asc(t.lastAccessAt)])..limit(50)).get();
      if (victims.isEmpty) break;
      for (final v in victims) {
        if (total <= maxBytes) break;
        await (db.delete(db.messageBodies)..where((t) => t.accountId.equals(v.accountId) & t.messageIdHash.equals(v.messageIdHash))).go();
        total -= v.sizeBytes;
        removed++;
      }
    }
    return removed;
  }
}
