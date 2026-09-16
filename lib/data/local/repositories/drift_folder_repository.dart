import 'package:drift/drift.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';
import '../database.dart' as d;

class DriftFolderRepository implements FolderRepository {
  DriftFolderRepository(this.db);
  final d.SortieDatabase db;

  static Folder toEntity(d.Folder r) => Folder(
        accountId: r.accountId,
        path: r.path,
        name: r.name,
        delimiter: r.delimiter,
        specialUse: SpecialUse.values.byName(r.specialUse),
        uidValidity: r.uidValidity,
        uidNext: r.uidNext,
        highestModSeq: r.highestModSeq,
        messageCount: r.messageCount,
        unseenCount: r.unseenCount,
        subscribed: r.subscribed,
        selectable: r.selectable,
      );

  static d.FoldersCompanion toRow(Folder f, {DateTime? lastSyncedAt}) => d.FoldersCompanion(
        accountId: Value(f.accountId),
        path: Value(f.path),
        name: Value(f.name),
        delimiter: Value(f.delimiter),
        specialUse: Value(f.specialUse.name),
        uidValidity: Value(f.uidValidity),
        uidNext: Value(f.uidNext),
        highestModSeq: Value(f.highestModSeq),
        messageCount: Value(f.messageCount),
        unseenCount: Value(f.unseenCount),
        subscribed: Value(f.subscribed),
        selectable: Value(f.selectable),
        lastSyncedAt: lastSyncedAt == null ? const Value.absent() : Value(lastSyncedAt.millisecondsSinceEpoch),
      );

  SimpleSelectStatement<d.$FoldersTable, d.Folder> _q(String accountId) => db.select(db.folders)
    ..where((t) => t.accountId.equals(accountId))
    ..orderBy([(t) => OrderingTerm.asc(t.path)]);

  @override
  Stream<List<Folder>> watch(String accountId) => _q(accountId).watch().map((rows) => _sorted(rows.map(toEntity).toList()));

  @override
  Future<List<Folder>> all(String accountId) async => _sorted((await _q(accountId).get()).map(toEntity).toList());

  /// INBOX first, then special folders, then alphabetically by path.
  static List<Folder> _sorted(List<Folder> list) {
    int rank(Folder f) => switch (f.specialUse) {
          SpecialUse.inbox => 0,
          SpecialUse.drafts => 1,
          SpecialUse.sent => 2,
          SpecialUse.archive => 3,
          SpecialUse.junk => 4,
          SpecialUse.trash => 5,
          _ => f.isInbox ? 0 : 10,
        };
    list.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : a.path.toLowerCase().compareTo(b.path.toLowerCase());
    });
    return list;
  }

  @override
  Future<Folder?> byPath(String accountId, String path) async {
    final r = await (db.select(db.folders)..where((t) => t.accountId.equals(accountId) & t.path.equals(path))).getSingleOrNull();
    return r == null ? null : toEntity(r);
  }

  /// Replaces the folder list from a LIST response while keeping the sync
  /// cursors (UIDVALIDITY, UIDNEXT, HIGHESTMODSEQ, lastSyncedAt) of folders
  /// that still exist. Messages of vanished folders are dropped.
  @override
  Future<void> replaceAll(String accountId, List<Folder> folders) => db.transaction(() async {
        final existing = {for (final r in await _q(accountId).get()) r.path: r};
        final keep = folders.map((f) => f.path).toSet();
        for (final gone in existing.keys.where((p) => !keep.contains(p)).toList()) {
          await (db.delete(db.folders)..where((t) => t.accountId.equals(accountId) & t.path.equals(gone))).go();
          await (db.delete(db.messages)..where((t) => t.accountId.equals(accountId) & t.folderPath.equals(gone))).go();
        }
        for (final f in folders) {
          final old = existing[f.path];
          final merged = Folder(
            accountId: accountId,
            path: f.path,
            name: f.name,
            delimiter: f.delimiter,
            specialUse: f.specialUse,
            uidValidity: old?.uidValidity ?? f.uidValidity,
            uidNext: old?.uidNext ?? f.uidNext,
            highestModSeq: old?.highestModSeq ?? f.highestModSeq,
            messageCount: f.messageCount,
            unseenCount: f.unseenCount,
            subscribed: f.subscribed,
            selectable: f.selectable,
          );
          await db.into(db.folders).insertOnConflictUpdate(toRow(merged));
        }
      });

  @override
  Future<void> update(Folder f) => db.into(db.folders).insertOnConflictUpdate(toRow(f, lastSyncedAt: DateTime.now()));

  /// Sync cursor update after a successful folder sync.
  Future<void> markSynced(String accountId, String path, {int? uidValidity, int? uidNext, int? highestModSeq, int? messageCount, int? unseenCount, DateTime? at}) =>
      (db.update(db.folders)..where((t) => t.accountId.equals(accountId) & t.path.equals(path))).write(d.FoldersCompanion(
        uidValidity: uidValidity == null ? const Value.absent() : Value(uidValidity),
        uidNext: uidNext == null ? const Value.absent() : Value(uidNext),
        highestModSeq: highestModSeq == null ? const Value.absent() : Value(highestModSeq),
        messageCount: messageCount == null ? const Value.absent() : Value(messageCount),
        unseenCount: unseenCount == null ? const Value.absent() : Value(unseenCount),
        lastSyncedAt: Value((at ?? DateTime.now()).millisecondsSinceEpoch),
      ));
}
