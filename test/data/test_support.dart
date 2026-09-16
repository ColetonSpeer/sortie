import 'dart:async';

import 'package:drift/native.dart';
import 'package:sortie/core/clock.dart';
import 'package:sortie/core/hashing.dart';
import 'package:sortie/data/local/database.dart' show SortieDatabase;
import 'package:sortie/data/local/repositories/drift_account_repository.dart';
import 'package:sortie/data/local/repositories/drift_folder_repository.dart';
import 'package:sortie/data/local/repositories/drift_message_repository.dart';
import 'package:sortie/data/local/repositories/drift_pending_op_repository.dart';
import 'package:sortie/data/local/repositories/drift_settings_repository.dart';
import 'package:sortie/data/mail/smtp_gateway.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/domain/repositories/repositories.dart';

/// In-memory database plus every drift repository, for unit tests.
class TestDb {
  TestDb._(this.db, this.clock)
      : accounts = DriftAccountRepository(db),
        folders = DriftFolderRepository(db),
        messages = DriftMessageRepository(db, clock: clock),
        pendingOps = DriftPendingOpRepository(db, clock: clock),
        settings = DriftSettingsRepository(db);

  static Future<TestDb> open({FakeClock? clock}) async {
    final db = SortieDatabase(NativeDatabase.memory());
    final t = TestDb._(db, clock ?? FakeClock());
    // force schema creation
    await db.customSelect('SELECT 1').get();
    return t;
  }

  final SortieDatabase db;
  final FakeClock clock;
  final DriftAccountRepository accounts;
  final DriftFolderRepository folders;
  final DriftMessageRepository messages;
  final DriftPendingOpRepository pendingOps;
  final DriftSettingsRepository settings;

  Future<void> close() => db.close();
}

const testAccountId = 'acc1';

Account testAccount({String id = testAccountId}) => Account(
      id: id,
      displayName: 'Test',
      email: 'test@example.com',
      username: 'test',
      imap: const ImapEndpoint(host: 'localhost', port: 143, security: ConnectionSecurity.none),
      smtp: const SmtpEndpoint(host: 'localhost', port: 587, security: ConnectionSecurity.none),
    );

int _counter = 0;

/// Header for delivery to a [FakeImapServer] (uid/uidValidity filled by it).
MessageHeader makeHeader({
  String? subject,
  String from = 'alice@example.com',
  String? messageId,
  DateTime? date,
  Set<String> flags = const {},
  String folderPath = 'INBOX',
  String accountId = '',
}) {
  _counter++;
  final mid = messageId ?? '<msg$_counter-${DateTime.now().microsecondsSinceEpoch}@example.com>';
  final subj = subject ?? 'Subject $_counter';
  final d = date ?? DateTime.utc(2026, 1, 1, 10, _counter % 60);
  return MessageHeader(
    accountId: accountId,
    folderPath: folderPath,
    uid: 0,
    uidValidity: 0,
    messageIdHash: messageIdHash(messageId: mid, from: from, date: d, subject: subj),
    messageId: mid,
    subject: subj,
    from: MailAddress(from, 'Alice'),
    to: const [MailAddress('test@example.com', 'Test')],
    date: d,
    flags: flags,
  );
}

class MemoryCredentialStore implements CredentialStore {
  final map = <String, String>{};
  @override
  Future<String?> read(String key) async => map[key];
  @override
  Future<void> write(String key, String value) async => map[key] = value;
  @override
  Future<void> delete(String key) async => map.remove(key);
}

class RecordingSmtpGateway implements SmtpGateway {
  final sent = <List<int>>[];
  final recipients = <List<String>>[];
  bool fail = false;
  @override
  Future<SmtpSendResult> send(Account account, String password, Identity identity, List<String> to, List<int> raw) async {
    if (fail) throw const SmtpGatewayException('451 try later');
    sent.add(raw);
    recipients.add(to);
    return const SmtpSendResult(accepted: true, response: '250 OK');
  }

  @override
  Future<void> testLogin(Account account, String password) async {}
}

/// Waits until [condition] is true, polling.
Future<void> eventually(FutureOr<bool> Function() condition, {Duration timeout = const Duration(seconds: 5), String? reason}) async {
  final deadline = DateTime.now().add(timeout);
  while (true) {
    if (await condition()) return;
    if (DateTime.now().isAfter(deadline)) throw TimeoutException(reason ?? 'condition not met within $timeout');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
