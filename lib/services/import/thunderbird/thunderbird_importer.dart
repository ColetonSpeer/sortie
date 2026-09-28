import 'dart:io';

import 'package:uuid/uuid.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';
import '../../sorter/user_rules.dart';
import '../calendar_import_sink.dart';
import 'import_models.dart';
import 'profile_locator.dart';
import 'profile_scanner.dart';
import 'rule_mapper.dart';

export 'filter_rules_parser.dart' show TbAction, TbCondition, TbFilter, folderPathFromUri;
export 'import_models.dart';
export 'profile_locator.dart' show FixedProfileLocator, PlatformProfileLocator, ProfileLocator, TbProfile, looksLikeProfile;
export 'profile_scanner.dart' show ImportException;

/// Imports accounts, identities, sorting rules, folder hints and calendars
/// from a Thunderbird profile. Passwords are never read from the profile:
/// the UI collects them and they are verified with [loginProbe] first.
class ThunderbirdImporter {
  ThunderbirdImporter({
    required this.locator,
    required this.accounts,
    required this.folders,
    required this.settings,
    required this.credentials,
    required this.rules,
    required this.calendarSink,
    required this.loginProbe,
    Future<void> Function(String accountId, SortConfig config)? saveSortConfig,
    this.onAccountCreated,
    String Function()? newId,
    DateTime Function()? now,
    this.scanner = const ProfileScanner(),
    this.mapper = const RuleMapper(),
  })  : _saveSortConfig = saveSortConfig ?? settings.saveSortConfig,
        _newId = newId ?? (() => const Uuid().v4()),
        _now = now ?? DateTime.now;

  final ProfileLocator locator;
  final AccountRepository accounts;
  final FolderRepository folders;
  final SettingsRepository settings;
  final CredentialStore credentials;
  final SortRuleStore rules;
  final CalendarImportSink calendarSink;
  final Future<void> Function(Account account, String password) loginProbe;

  /// Called after a new account is saved (the app starts its sync here).
  final Future<void> Function(String accountId)? onAccountCreated;
  final Future<void> Function(String, SortConfig) _saveSortConfig;
  final String Function() _newId;
  final DateTime Function() _now;
  final ProfileScanner scanner;
  final RuleMapper mapper;

  Future<List<TbProfile>> discoverProfiles() => locator.discover();

  Future<ImportPreview> scan(Directory profile) async => scanner.scan(profile, existing: await accounts.all());

  /// Applies [selection]. Accounts whose IMAP host + username already exist
  /// are reused (only identities and rules are added). New accounts need a
  /// password in [passwordsByAccountEmail] (keyed by [TbAccount.email]).
  Future<ImportResult> apply(ImportPreview preview, ImportSelection selection, {required Map<String, String> passwordsByAccountEmail}) async {
    final created = <Account>[], reused = <Account>[], identities = <Identity>[];
    final outcomes = <RuleImportOutcome>[];
    final hints = <String, List<String>>{};
    final skipped = <String>[], errors = <String>[];

    for (final tb in preview.accounts) {
      if (!selection.accountKeys.contains(tb.key)) continue;
      Account? account;
      if (tb.existingAccountId != null) {
        account = await accounts.byId(tb.existingAccountId!);
        if (account != null) reused.add(account);
      }
      if (account == null) {
        final password = passwordsByAccountEmail[tb.email] ?? passwordsByAccountEmail[tb.key];
        if (password == null || password.isEmpty) {
          skipped.add('${tb.displayName}: no password entered, account not created');
          continue;
        }
        account = tb.toAccount(_newId());
        try {
          await loginProbe(account, password);
        } catch (e) {
          errors.add('${tb.displayName}: login failed (${_short(e)})');
          continue;
        }
        await credentials.write(CredentialStore.accountPassword(account.id), password);
        await accounts.upsert(account);
        created.add(account);
        try {
          await onAccountCreated?.call(account.id);
        } catch (_) {
          // Sync start is best effort; the account is saved either way.
        }
      }
      identities.addAll(await _importIdentities(tb, account, selection, skipped, isNewAccount: created.contains(account)));
      final r = await _importRules(tb, account, selection, hints);
      outcomes.addAll(r);
    }

    var calendarCount = 0;
    final calendars = preview.calendars.where((c) => selection.calendarIds.contains(c.id)).toList();
    if (calendars.isNotEmpty) {
      try {
        await calendarSink.importCalendars(calendars);
        calendarCount = calendars.length;
      } catch (e) {
        errors.add('Calendars: ${_short(e)}');
      }
    }
    return ImportResult(
      createdAccounts: created,
      reusedAccounts: reused,
      createdIdentities: identities,
      rules: outcomes,
      folderHints: hints,
      calendarsImported: calendarCount,
      skipped: skipped,
      errors: errors,
    );
  }

  Future<List<Identity>> _importIdentities(TbAccount tb, Account account, ImportSelection selection, List<String> skipped, {required bool isNewAccount}) async {
    final existing = await accounts.identities(account.id);
    final known = {for (final i in existing) i.email.toLowerCase()};
    final out = <Identity>[];
    var hasDefault = existing.any((i) => i.isDefault);
    for (final tbId in tb.identities) {
      if (!selection.identityKeys.contains(tbId.key)) continue;
      if (known.contains(tbId.email.toLowerCase())) {
        skipped.add('Identity ${tbId.email} already exists on ${account.displayName}');
        continue;
      }
      final id = Identity(
        id: _newId(),
        accountId: account.id,
        name: tbId.name,
        email: tbId.email,
        replyTo: tbId.replyTo,
        signature: tbId.signature,
        signatureHtml: tbId.signatureHtml,
        isDefault: !hasDefault && (tbId.isDefault || isNewAccount),
      );
      hasDefault = hasDefault || id.isDefault;
      await accounts.upsertIdentity(id);
      known.add(tbId.email.toLowerCase());
      out.add(id);
    }
    return out;
  }

  Future<List<RuleImportOutcome>> _importRules(TbAccount tb, Account account, ImportSelection selection, Map<String, List<String>> hints) async {
    final selected = tb.filters.where((f) => selection.filter(tb.key, f.name)).toList();
    if (selected.isEmpty) return const [];
    final accountFolders = await folders.all(account.id);
    final existingRules = await rules.load(account.id);
    var priority = existingRules.fold(0, (m, r) => r.priority > m ? r.priority : m) + 10;
    final now = _now();
    final out = <RuleImportOutcome>[];
    final clausesByFolder = <String, List<String>>{};
    for (final f in selected) {
      final o = mapper.map(f, accountId: account.id, folders: accountFolders, priority: priority);
      out.add(o);
      if (!o.imported) continue;
      priority += 10;
      for (final r in o.rules) {
        await rules.upsert(r, now);
        clausesByFolder.putIfAbsent(o.folderPath!, () => []).add(r.match.describe());
      }
    }
    if (clausesByFolder.isNotEmpty) {
      final config = await settings.sortConfig(account.id);
      final descriptions = Map<String, String>.of(config.folderDescriptions);
      for (final e in clausesByFolder.entries) {
        descriptions[e.key] = FolderHints.merge(descriptions[e.key] ?? '', e.value);
      }
      await _saveSortConfig(account.id, config.copyWith(folderDescriptions: descriptions));
      hints[account.id] = clausesByFolder.keys.toList();
    }
    return out;
  }

  static String _short(Object e) {
    final s = e.toString().replaceAll('\n', ' ');
    return s.length > 160 ? '${s.substring(0, 160)}…' : s;
  }
}
