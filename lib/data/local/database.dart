import 'package:drift/drift.dart';

import 'tables/calendar_tables.dart';
import 'tables/tables.dart';

export 'tables/calendar_tables.dart';
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
  SortEvidence,
  RuleSuggestions,
  AiUsage,
  JournalEvents,
  JournalCursors,
  Calendars,
  CalendarEvents,
  CalendarSyncQueue,
])
class SortieDatabase extends _$SortieDatabase {
  SortieDatabase(super.executor);

  @override
  int get schemaVersion => 5;

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
          await _createCalendarIndexes();
          await _createAdvisorIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(calendars);
            await m.createTable(calendarEvents);
            await m.createTable(calendarSyncQueue);
            await _createCalendarIndexes();
          }
          if (from < 3) {
            await m.addColumn(identities, identities.signatureHtml);
          }
          if (from < 4) {
            await m.createTable(sortEvidence);
            await m.createTable(ruleSuggestions);
            await _createAdvisorIndexes();
          }
          if (from < 5) {
            await m.addColumn(messageBodies, messageBodies.calendarText);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _createAdvisorIndexes() async {
    await customStatement('CREATE INDEX IF NOT EXISTS idx_sort_evidence_acct ON sort_evidence(account_id, consumed_at, last_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_rule_suggestions_acct ON rule_suggestions(account_id, status)');
  }

  Future<void> _createCalendarIndexes() async {
    await customStatement('CREATE INDEX IF NOT EXISTS idx_cal_events_cal ON calendar_events(calendar_id, start_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_cal_events_uid ON calendar_events(calendar_id, uid)');
  }

  /// FTS5 over subject / sender / body text, keyed by rowid of `messages`.
  Future<void> _createFts() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts USING fts5(
        account_id UNINDEXED, message_id_hash UNINDEXED, subject, from_text, body_text,
        tokenize = 'unicode61 remove_diacritics 2'
      )''');
  }
}
