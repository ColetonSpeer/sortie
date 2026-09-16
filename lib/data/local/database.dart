import 'package:drift/drift.dart';

import 'tables/tables.dart';

export 'tables/tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Accounts,
  Identities,
  Folders,
  Messages,
  MessageBodies,
  PendingOps,
  Settings,
  SortDecisions,
  Corrections,
  FolderProfiles,
  FolderProfileHistory,
  SenderStats,
  UserRules,
  SortQueue,
  AiUsage,
  JournalEvents,
  JournalCursors,
])
class SortieDatabase extends _$SortieDatabase {
  SortieDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createFts();
          await customStatement('CREATE INDEX IF NOT EXISTS idx_messages_folder_date ON messages(account_id, folder_path, date DESC)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_messages_uid ON messages(account_id, folder_path, uid)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_decisions_msg ON sort_decisions(account_id, message_id_hash)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_corrections_recent ON corrections(account_id, superseded, created_at DESC)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_sender_stats_key ON sender_stats(account_id, key_kind, key)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_journal_type ON journal_events(account_id, type, uid)');
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// FTS5 over subject / sender / body text, keyed by rowid of `messages`.
  Future<void> _createFts() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts USING fts5(
        account_id UNINDEXED, message_id_hash UNINDEXED, subject, from_text, body_text,
        tokenize = 'unicode61 remove_diacritics 2'
      )''');
  }
}
