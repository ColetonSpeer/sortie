import 'package:drift/drift.dart';

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();
  TextColumn get email => text()();
  TextColumn get username => text()();
  TextColumn get imapHost => text()();
  IntColumn get imapPort => integer()();
  TextColumn get imapSecurity => text()();
  TextColumn get smtpHost => text()();
  IntColumn get smtpPort => integer()();
  TextColumn get smtpSecurity => text()();
  TextColumn get smtpUsername => text().nullable()();
  TextColumn get auth => text().withDefault(const Constant('password'))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  @override
  Set<Column> get primaryKey => {id};
}

class Identities extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get replyTo => text().nullable()();
  TextColumn get signature => text().withDefault(const Constant(''))();

  /// Optional HTML signature (schema v3).
  TextColumn get signatureHtml => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

class Folders extends Table {
  TextColumn get accountId => text().references(Accounts, #id, onDelete: KeyAction.cascade)();
  TextColumn get path => text()();
  TextColumn get name => text()();
  TextColumn get delimiter => text()();
  TextColumn get specialUse => text().withDefault(const Constant('none'))();
  IntColumn get uidValidity => integer().nullable()();
  IntColumn get uidNext => integer().nullable()();
  IntColumn get highestModSeq => integer().nullable()();
  IntColumn get messageCount => integer().withDefault(const Constant(0))();
  IntColumn get unseenCount => integer().withDefault(const Constant(0))();
  BoolColumn get subscribed => boolean().withDefault(const Constant(true))();
  BoolColumn get selectable => boolean().withDefault(const Constant(true))();
  IntColumn get lastSyncedAt => integer().nullable()();
  @override
  Set<Column> get primaryKey => {accountId, path};
}

class Messages extends Table {
  TextColumn get accountId => text()();
  TextColumn get messageIdHash => text()();
  TextColumn get folderPath => text()();

  /// Null after a UIDVALIDITY change until relinked.
  IntColumn get uid => integer().nullable()();
  IntColumn get uidValidity => integer().nullable()();
  TextColumn get messageId => text().nullable()();
  TextColumn get subject => text().withDefault(const Constant(''))();
  TextColumn get fromEmail => text().nullable()();
  TextColumn get fromName => text().nullable()();
  /// Recipient list as JSON. Named `toAddressesJson` in Dart because drift's
  /// generated data class already has a `toJson()` method.
  TextColumn get toAddressesJson => text().named('to_json').withDefault(const Constant('[]'))();
  TextColumn get ccJson => text().withDefault(const Constant('[]'))();
  TextColumn get replyTo => text().nullable()();
  IntColumn get date => integer()();
  IntColumn get internalDate => integer().nullable()();
  TextColumn get listId => text().nullable()();
  TextColumn get inReplyTo => text().nullable()();
  TextColumn get referencesJson => text().withDefault(const Constant('[]'))();
  TextColumn get precedence => text().nullable()();
  TextColumn get autoSubmitted => text().nullable()();
  BoolColumn get hasListUnsubscribe => boolean().withDefault(const Constant(false))();
  TextColumn get flagsJson => text().withDefault(const Constant('[]'))();
  IntColumn get size => integer().withDefault(const Constant(0))();
  TextColumn get snippet => text().withDefault(const Constant(''))();
  TextColumn get attachmentsJson => text().withDefault(const Constant('[]'))();
  IntColumn get lastOpenedAt => integer().nullable()();
  @override
  Set<Column> get primaryKey => {accountId, messageIdHash, folderPath};
}

class MessageBodies extends Table {
  TextColumn get accountId => text()();
  TextColumn get messageIdHash => text()();
  TextColumn get bodyText => text()();
  TextColumn get html => text().nullable()();

  /// JSON map cid -> base64.
  TextColumn get inlineJson => text().withDefault(const Constant('{}'))();
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();
  IntColumn get cachedAt => integer()();
  IntColumn get lastAccessAt => integer()();
  @override
  Set<Column> get primaryKey => {accountId, messageIdHash};
}

class PendingOps extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text()();
  TextColumn get type => text()();
  TextColumn get payloadJson => text()();
  IntColumn get createdAt => integer()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get nextAttemptAt => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get lastError => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Key/value settings; JSON values.
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();
  @override
  Set<Column> get primaryKey => {key};
}

class SortDecisions extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text()();
  TextColumn get messageIdHash => text()();
  IntColumn get uid => integer().nullable()();
  IntColumn get uidValidity => integer().nullable()();
  TextColumn get sourceFolder => text()();
  TextColumn get destination => text()();
  TextColumn get layer => text()();
  TextColumn get matchedKey => text().nullable()();
  RealColumn get confidence => real()();
  TextColumn get reason => text().withDefault(const Constant(''))();
  TextColumn get mode => text()();
  TextColumn get status => text()();
  TextColumn get modelId => text().nullable()();
  IntColumn get folderProfileVersion => integer().nullable()();
  RealColumn get costUsd => real().nullable()();
  TextColumn get deviceId => text().nullable()();
  IntColumn get epoch => integer().nullable()();
  BoolColumn get dryRun => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get appliedAt => integer().nullable()();
  IntColumn get seenObservedAt => integer().nullable()();
  TextColumn get finalFolder => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class Corrections extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text()();
  TextColumn get messageIdHash => text()();
  TextColumn get decisionId => text().nullable()();
  TextColumn get kind => text()();
  RealColumn get weight => real()();
  TextColumn get predictedFolder => text().nullable()();
  TextColumn get actualFolder => text()();
  TextColumn get fromAddress => text().nullable()();
  TextColumn get fromDomain => text().nullable()();
  TextColumn get listId => text().nullable()();
  TextColumn get subjectNorm => text().nullable()();
  BoolColumn get superseded => boolean().withDefault(const Constant(false))();
  TextColumn get deviceId => text().nullable()();
  IntColumn get createdAt => integer()();
  @override
  Set<Column> get primaryKey => {id};
}

class FolderProfiles extends Table {
  TextColumn get accountId => text()();
  TextColumn get path => text()();
  TextColumn get name => text()();
  TextColumn get specialUse => text().nullable()();
  BoolColumn get neverSort => boolean().withDefault(const Constant(false))();
  TextColumn get neverSortSource => text().withDefault(const Constant('default'))();
  TextColumn get description => text().nullable()();
  TextColumn get descriptionSource => text().withDefault(const Constant('auto'))();
  TextColumn get topSendersJson => text().withDefault(const Constant('[]'))();
  TextColumn get topListIdsJson => text().withDefault(const Constant('[]'))();
  TextColumn get topDomainsJson => text().withDefault(const Constant('[]'))();
  TextColumn get sampleSubjectsJson => text().withDefault(const Constant('[]'))();
  IntColumn get messageCount => integer().withDefault(const Constant(0))();
  IntColumn get userFiledCount => integer().withDefault(const Constant(0))();
  IntColumn get lastUserFiledAt => integer().nullable()();
  IntColumn get profileVersion => integer().withDefault(const Constant(1))();
  TextColumn get renderedText => text().nullable()();
  IntColumn get updatedAt => integer()();
  @override
  Set<Column> get primaryKey => {accountId, path};
}

class FolderProfileHistory extends Table {
  TextColumn get accountId => text()();
  TextColumn get path => text()();
  IntColumn get profileVersion => integer()();
  TextColumn get renderedText => text()();
  IntColumn get createdAt => integer()();
  @override
  Set<Column> get primaryKey => {accountId, path, profileVersion};
}

class SenderStats extends Table {
  TextColumn get accountId => text()();

  /// list_id | from_addr | from_domain
  TextColumn get keyKind => text()();
  TextColumn get key => text()();
  TextColumn get folderPath => text()();
  RealColumn get count => real().withDefault(const Constant(0))();
  RealColumn get weightedCount => real().withDefault(const Constant(0))();
  IntColumn get countAgainst => integer().withDefault(const Constant(0))();
  IntColumn get firstSeenAt => integer().nullable()();
  IntColumn get lastUserAt => integer().nullable()();
  @override
  Set<Column> get primaryKey => {accountId, keyKind, key, folderPath};
}

class UserRules extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text()();
  IntColumn get priority => integer()();
  TextColumn get matchJson => text()();

  /// moveTo | keepInInbox | neverAutoSort
  TextColumn get action => text()();
  TextColumn get folderPath => text().nullable()();
  IntColumn get hits => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  @override
  Set<Column> get primaryKey => {id};
}

class SortQueue extends Table {
  TextColumn get accountId => text()();
  TextColumn get messageIdHash => text()();
  IntColumn get uid => integer().nullable()();
  IntColumn get enqueuedAt => integer()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get nextAttemptAt => integer().nullable()();
  TextColumn get lastError => text().nullable()();
  @override
  Set<Column> get primaryKey => {accountId, messageIdHash};
}

class AiUsage extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ts => integer()();
  TextColumn get provider => text().nullable()();
  TextColumn get modelId => text().nullable()();

  /// sort | bootstrap | test | accuracy | batch
  TextColumn get kind => text()();
  IntColumn get inputTokens => integer().withDefault(const Constant(0))();
  IntColumn get cacheReadTokens => integer().withDefault(const Constant(0))();
  IntColumn get cacheWriteTokens => integer().withDefault(const Constant(0))();
  IntColumn get outputTokens => integer().withDefault(const Constant(0))();
  RealColumn get costUsd => real()();
  TextColumn get batchId => text().nullable()();
}

/// Materialized view of the shared control-folder journal, per account.
class JournalEvents extends Table {
  TextColumn get accountId => text()();
  IntColumn get uid => integer()();
  TextColumn get type => text()();
  TextColumn get deviceId => text()();
  IntColumn get epoch => integer().nullable()();
  IntColumn get internalDate => integer()();
  TextColumn get bodyJson => text()();
  @override
  Set<Column> get primaryKey => {accountId, uid};
}

class JournalCursors extends Table {
  TextColumn get accountId => text()();
  IntColumn get uidValidity => integer().withDefault(const Constant(0))();
  IntColumn get snapshotUid => integer().withDefault(const Constant(0))();
  IntColumn get lastAppliedUid => integer().withDefault(const Constant(0))();
  IntColumn get lastEpoch => integer().withDefault(const Constant(0))();
  IntColumn get writerSeq => integer().withDefault(const Constant(0))();
  TextColumn get controlPath => text().nullable()();
  @override
  Set<Column> get primaryKey => {accountId};
}
