import 'package:drift/drift.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';
import '../database.dart' as d;

class DriftAccountRepository implements AccountRepository {
  DriftAccountRepository(this.db);
  final d.SortieDatabase db;

  static Account toEntity(d.Account r) => Account(
        id: r.id,
        displayName: r.displayName,
        email: r.email,
        username: r.username,
        imap: ImapEndpoint(host: r.imapHost, port: r.imapPort, security: ConnectionSecurity.values.byName(r.imapSecurity)),
        smtp: SmtpEndpoint(host: r.smtpHost, port: r.smtpPort, security: ConnectionSecurity.values.byName(r.smtpSecurity)),
        auth: AuthMethod.values.byName(r.auth),
        smtpUsername: r.smtpUsername,
        enabled: r.enabled,
      );

  static d.AccountsCompanion toRow(Account a) => d.AccountsCompanion(
        id: Value(a.id),
        displayName: Value(a.displayName),
        email: Value(a.email),
        username: Value(a.username),
        imapHost: Value(a.imap.host),
        imapPort: Value(a.imap.port),
        imapSecurity: Value(a.imap.security.name),
        smtpHost: Value(a.smtp.host),
        smtpPort: Value(a.smtp.port),
        smtpSecurity: Value(a.smtp.security.name),
        smtpUsername: Value(a.smtpUsername),
        auth: Value(a.auth.name),
        enabled: Value(a.enabled),
      );

  static Identity identityToEntity(d.Identity r) => Identity(
        id: r.id,
        accountId: r.accountId,
        name: r.name,
        email: r.email,
        replyTo: r.replyTo,
        signature: r.signature,
        isDefault: r.isDefault,
      );

  static d.IdentitiesCompanion identityToRow(Identity i) => d.IdentitiesCompanion(
        id: Value(i.id),
        accountId: Value(i.accountId),
        name: Value(i.name),
        email: Value(i.email),
        replyTo: Value(i.replyTo),
        signature: Value(i.signature),
        isDefault: Value(i.isDefault),
      );

  SimpleSelectStatement<d.$AccountsTable, d.Account> get _ordered => db.select(db.accounts)..orderBy([(t) => OrderingTerm.asc(t.displayName)]);

  @override
  Stream<List<Account>> watchAll() => _ordered.watch().map((rows) => rows.map(toEntity).toList());

  @override
  Future<List<Account>> all() async => (await _ordered.get()).map(toEntity).toList();

  @override
  Future<Account?> byId(String id) async {
    final r = await (db.select(db.accounts)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : toEntity(r);
  }

  @override
  Future<void> upsert(Account a) => db.into(db.accounts).insertOnConflictUpdate(toRow(a));

  @override
  Future<void> delete(String id) => db.transaction(() async {
        // Cascades cover identities/folders; message tables have no FK on purpose.
        await (db.delete(db.messages)..where((t) => t.accountId.equals(id))).go();
        await (db.delete(db.messageBodies)..where((t) => t.accountId.equals(id))).go();
        await (db.delete(db.pendingOps)..where((t) => t.accountId.equals(id))).go();
        await db.customStatement('DELETE FROM messages_fts WHERE account_id = ?', [id]);
        await (db.delete(db.accounts)..where((t) => t.id.equals(id))).go();
      });

  SimpleSelectStatement<d.$IdentitiesTable, d.Identity> _identities(String accountId) => db.select(db.identities)
    ..where((t) => t.accountId.equals(accountId))
    ..orderBy([(t) => OrderingTerm.desc(t.isDefault), (t) => OrderingTerm.asc(t.email)]);

  @override
  Stream<List<Identity>> watchIdentities(String accountId) => _identities(accountId).watch().map((rows) => rows.map(identityToEntity).toList());

  @override
  Future<List<Identity>> identities(String accountId) async => (await _identities(accountId).get()).map(identityToEntity).toList();

  @override
  Future<void> upsertIdentity(Identity i) => db.transaction(() async {
        if (i.isDefault) {
          await (db.update(db.identities)..where((t) => t.accountId.equals(i.accountId) & t.id.equals(i.id).not()))
              .write(const d.IdentitiesCompanion(isDefault: Value(false)));
        }
        await db.into(db.identities).insertOnConflictUpdate(identityToRow(i));
      });

  @override
  Future<void> deleteIdentity(String id) => (db.delete(db.identities)..where((t) => t.id.equals(id))).go();
}
