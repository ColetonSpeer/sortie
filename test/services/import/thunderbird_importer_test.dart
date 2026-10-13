import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/app/demo/fake_repositories.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/domain/repositories/repositories.dart';
import 'package:sortie/services/import/calendar_import_sink.dart';
import 'package:sortie/services/import/thunderbird/thunderbird_importer.dart';

import 'fixtures.dart';

void main() {
  late Directory tmp;
  late FakeAccountRepository accounts;
  late FakeFolderRepository folders;
  late FakeSettingsRepository settings;
  late FakeCredentialStore creds;
  late InMemoryRuleStore rules;
  late List<(String, String)> probes;
  late List<String> started;
  late Map<String, SortConfig> savedConfigs;
  var ids = 0;

  ThunderbirdImporter importer({bool failLogin = false}) => ThunderbirdImporter(
        locator: const FixedProfileLocator([]),
        accounts: accounts,
        folders: folders,
        settings: settings,
        credentials: creds,
        rules: rules,
        calendarSink: PendingCalendarImportSink(settings),
        loginProbe: (a, pw) async {
          probes.add((a.email, pw));
          if (failLogin) throw Exception('535 bad credentials');
        },
        saveSortConfig: (id, c) async {
          savedConfigs[id] = c;
          await settings.saveSortConfig(id, c);
        },
        onAccountCreated: (id) async => started.add(id),
        newId: () => 'id-${++ids}',
        now: () => DateTime.utc(2026, 9, 28),
      );

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('tbprofile');
    await writeProfile(tmp);
    accounts = FakeAccountRepository();
    folders = FakeFolderRepository();
    settings = FakeSettingsRepository();
    creds = FakeCredentialStore();
    rules = InMemoryRuleStore();
    probes = [];
    started = [];
    savedConfigs = {};
    ids = 0;
  });
  tearDown(() => tmp.delete(recursive: true));

  test('scan finds the IMAP account, identities, filters and calendars; skips POP3 and Local Folders', () async {
    final preview = await importer().scan(tmp);
    expect(preview.accounts.length, 1);
    final a = preview.accounts.single;
    expect(a.displayName, 'jane@example.test');
    expect(a.imap.host, 'mail.example.test');
    expect(a.imap.port, 993);
    expect(a.imap.security, ConnectionSecurity.tls);
    expect(a.smtp.host, 'smtp.example.test');
    expect(a.smtp.security, ConnectionSecurity.starttls);
    expect(a.isNew, isTrue);
    expect(a.identities.length, 2);
    expect(a.identities[0].name, 'Jane "JJ" Doe');
    expect(a.identities[0].signature, 'Jane Doe\nExample Co & Sons');
    expect(a.identities[0].signatureHtml, contains('<b>Jane Doe</b>'));
    expect(a.identities[0].isDefault, isTrue);
    expect(a.identities[1].replyTo, 'replies@example.test');
    expect(a.identities[1].signatureHtml, isNull);
    expect(a.filters.length, 12);
    expect(preview.calendars.map((c) => c.name), ['Holidays', 'Home'], reason: 'sortOrder honoured');
    expect(preview.calendars[0].readOnly, isTrue);
    expect(preview.calendars[1].color, '#ff0000');
    expect(preview.skipped.single, contains('pop3'));
  });

  test('scan reads a signature file when attach_signature is set', () async {
    final sig = File('${tmp.path}/sig.txt')..writeAsStringSync('-- \nFrom file\n');
    final prefs = '$prefsJs\nuser_pref("mail.identity.id2.attach_signature", true);\nuser_pref("mail.identity.id2.sig_file", "${sig.path}");\n';
    await writeProfile(tmp, prefs: prefs);
    final preview = await importer().scan(tmp);
    expect(preview.accounts.single.identities[1].signature, '-- \nFrom file');
  });

  test('apply creates the account, identities, rules, hints and parks calendars', () async {
    await folders.replaceAll('id-1', [
      Folder(accountId: 'id-1', path: 'INBOX', name: 'INBOX', delimiter: '/'),
      Folder(accountId: 'id-1', path: 'INBOX/Calix orders', name: 'Calix orders', delimiter: '/'),
    ]);
    await settings.saveSortConfig('id-1', const SortConfig(folderDescriptions: {'INBOX/Calix orders': 'Orders from Calix'}));
    final imp = importer();
    final preview = await imp.scan(tmp);
    final result = await imp.apply(preview, preview.selectAll(), passwordsByAccountEmail: {'jane@example.test': 'pw1'});

    expect(probes, [('jane@example.test', 'pw1')]);
    expect(result.createdAccounts.single.id, 'id-1');
    expect(await creds.read(CredentialStore.accountPassword('id-1')), 'pw1');
    expect(started, ['id-1']);
    final ident = await accounts.identities('id-1');
    expect(ident.map((i) => i.email), ['jane@example.test', 'alias@example.test']);
    expect(ident.where((i) => i.isDefault).single.email, 'jane@example.test');
    expect(ident.first.signatureHtml, isNotNull);

    expect(result.rulesImported, 11, reason: '12 filters minus the Mark-read one; OR rule stays one rule, Copy-to-folder counts');
    expect(result.rules.where((r) => !r.imported).single.filterName, 'mark read only');
    expect(result.rulesWithMissingFolder, greaterThan(0));
    expect(result.rulesDisabled, 1);
    final stored = await rules.load('id-1');
    expect(stored.length, 11);
    expect(stored.map((r) => r.priority).toSet().length, 11, reason: 'distinct priorities');
    expect(stored.every((r) => r.id.startsWith('tb-')), isTrue);

    final cfg = savedConfigs['id-1']!;
    expect(cfg.folderDescriptions['INBOX/Calix orders'], startsWith('Orders from Calix\nRules: from order.management@calix.com | '));
    expect(cfg.folderDescriptions['INBOX/Calix orders'], contains("subject contains 'Calix Order Acknowledgement'"));
    expect(result.folderHints['id-1'], contains('INBOX/Calix orders'));

    expect(result.calendarsImported, 2);
    final pending = jsonDecode(settings.strings[PendingCalendarImportSink.settingsKey]!) as List;
    expect(pending.length, 2);
    expect((pending.first as Map)['type'], 'ics');
    expect(result.errors, isEmpty);

    // Re-import is idempotent: same ids, no duplicates.
    final again = await imp.apply(preview, preview.selectAll(), passwordsByAccountEmail: const {});
    expect(again.reusedAccounts, isEmpty, reason: 'preview predates the account, so it is treated as new and skipped without a password');
    expect(again.skipped.single, contains('no password'));
    final rescan = await imp.scan(tmp);
    expect(rescan.accounts.single.existingAccountId, 'id-1');
    final third = await imp.apply(rescan, rescan.selectAll(), passwordsByAccountEmail: const {});
    expect(third.reusedAccounts.single.id, 'id-1');
    expect(third.createdIdentities, isEmpty);
    expect(third.skipped.where((s) => s.contains('already exists')).length, 2);
    expect((await rules.load('id-1')).length, 11);
    expect((await accounts.identities('id-1')).length, 2);
  });

  test('existing account (same host + username) is reused; login is not probed', () async {
    await accounts.upsert(const Account(
      id: 'existing',
      displayName: 'Jane',
      email: 'jane@example.test',
      username: 'JANE@example.test',
      imap: ImapEndpoint(host: 'MAIL.example.test', port: 993, security: ConnectionSecurity.tls),
      smtp: SmtpEndpoint(host: 'smtp.example.test', port: 587, security: ConnectionSecurity.starttls),
    ));
    await accounts.upsertIdentity(const Identity(id: 'i0', accountId: 'existing', name: 'Jane', email: 'jane@example.test', isDefault: true));
    final imp = importer();
    final preview = await imp.scan(tmp);
    expect(preview.accounts.single.existingAccountId, 'existing');
    final result = await imp.apply(preview, preview.selectAll(), passwordsByAccountEmail: const {});
    expect(probes, isEmpty);
    expect(result.createdAccounts, isEmpty);
    expect(result.reusedAccounts.single.id, 'existing');
    expect(result.createdIdentities.single.email, 'alias@example.test');
    expect(result.createdIdentities.single.isDefault, isFalse);
    expect((await rules.load('existing')).length, 11);

    // The onboarding-created identity had no signature: Thunderbird's is filled in.
    final jane = (await accounts.identities('existing')).singleWhere((i) => i.id == 'i0');
    expect(jane.signature, 'Jane Doe\nExample Co & Sons');
    expect(jane.signatureHtml, contains('<b>Jane Doe</b>'));
    expect(jane.isDefault, isTrue);
    expect(jane.name, 'Jane');
    expect(result.skipped.single, contains('signature filled in'));
  });

  test('failed login skips the account and reports it', () async {
    final imp = importer(failLogin: true);
    final preview = await imp.scan(tmp);
    final result = await imp.apply(preview, preview.selectAll(), passwordsByAccountEmail: {'jane@example.test': 'bad'});
    expect(result.createdAccounts, isEmpty);
    expect(result.errors.single, contains('login failed'));
    expect(await accounts.all(), isEmpty);
    expect(await creds.read(CredentialStore.accountPassword('id-1')), isNull);
  });

  test('selection is honoured', () async {
    final imp = importer();
    final preview = await imp.scan(tmp);
    final sel = preview.selectAll().copyWith(identityKeys: {'id1'}, filterNames: {'account1/from is'}, calendarIds: {});
    final result = await imp.apply(preview, sel, passwordsByAccountEmail: {'jane@example.test': 'pw'});
    expect(result.createdIdentities.single.email, 'jane@example.test');
    expect(result.rulesImported, 1);
    expect(result.calendarsImported, 0);
    expect(settings.strings[PendingCalendarImportSink.settingsKey], isNull);
  });

  test('scan of a directory without prefs.js throws ImportException', () async {
    final empty = await Directory.systemTemp.createTemp('notprofile');
    addTearDown(() => empty.delete(recursive: true));
    expect(() => importer().scan(empty), throwsA(isA<ImportException>()));
  });
}
