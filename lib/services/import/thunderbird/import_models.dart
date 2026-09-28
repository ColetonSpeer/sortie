import '../../../domain/entities/entities.dart';
import '../../sorter/user_rules.dart';
import '../calendar_import_sink.dart';
import 'filter_rules_parser.dart';

/// An identity found in prefs.js (`mail.identity.idN.*`).
class TbIdentity {
  const TbIdentity({
    required this.key,
    required this.name,
    required this.email,
    this.replyTo,
    this.organization,
    this.signature = '',
    this.signatureHtml,
    this.isDefault = false,
    this.notes = const [],
  });
  final String key;
  final String name;
  final String email;
  final String? replyTo;
  final String? organization;

  /// Plain-text signature (HTML stripped / sig_file read).
  final String signature;
  final String? signatureHtml;
  final bool isDefault;
  final List<String> notes;
}

/// An IMAP account found in prefs.js (POP3 and Local Folders are reported
/// as [ImportPreview.skipped]).
class TbAccount {
  const TbAccount({
    required this.key,
    required this.displayName,
    required this.email,
    required this.username,
    required this.imap,
    required this.smtp,
    this.smtpUsername,
    required this.identities,
    required this.filters,
    this.filterFile,
    this.existingAccountId,
    this.notes = const [],
  });
  final String key;
  final String displayName;
  final String email;
  final String username;
  final ImapEndpoint imap;
  final SmtpEndpoint smtp;
  final String? smtpUsername;
  final List<TbIdentity> identities;
  final List<TbFilter> filters;
  final String? filterFile;

  /// Set when a Sortie account with the same IMAP host + username exists.
  final String? existingAccountId;
  final List<String> notes;

  bool get isNew => existingAccountId == null;

  Account toAccount(String id) => Account(
        id: id,
        displayName: displayName,
        email: email,
        username: username,
        imap: imap,
        smtp: smtp,
        smtpUsername: smtpUsername,
      );
}

/// Everything found in a profile, before the user picks what to import.
class ImportPreview {
  const ImportPreview({
    required this.profilePath,
    required this.accounts,
    required this.calendars,
    this.skipped = const [],
  });
  final String profilePath;
  final List<TbAccount> accounts;
  final List<ImportedCalendar> calendars;

  /// Human explanations of things that were found but cannot be imported.
  final List<String> skipped;

  int get filterCount => accounts.fold(0, (n, a) => n + a.filters.length);

  /// Selects everything by default.
  ImportSelection selectAll() => ImportSelection(
        accountKeys: {for (final a in accounts) a.key},
        identityKeys: {for (final a in accounts) for (final i in a.identities) i.key},
        filterNames: {for (final a in accounts) for (final f in a.filters) '${a.key}/${f.name}'},
        calendarIds: {for (final c in calendars) c.id},
      );
}

/// Which parts of the preview to import. Filters are keyed `accountKey/name`.
class ImportSelection {
  const ImportSelection({
    this.accountKeys = const {},
    this.identityKeys = const {},
    this.filterNames = const {},
    this.calendarIds = const {},
  });
  final Set<String> accountKeys;
  final Set<String> identityKeys;
  final Set<String> filterNames;
  final Set<String> calendarIds;

  bool filter(String accountKey, String name) => filterNames.contains('$accountKey/$name');

  ImportSelection copyWith({Set<String>? accountKeys, Set<String>? identityKeys, Set<String>? filterNames, Set<String>? calendarIds}) =>
      ImportSelection(
        accountKeys: accountKeys ?? this.accountKeys,
        identityKeys: identityKeys ?? this.identityKeys,
        filterNames: filterNames ?? this.filterNames,
        calendarIds: calendarIds ?? this.calendarIds,
      );
}

/// Outcome of one imported filter.
class RuleImportOutcome {
  const RuleImportOutcome({required this.filterName, required this.rules, this.folderPath, this.missingFolder = false, this.droppedStatusRead = false, this.skippedReason});
  final String filterName;
  final List<SortRule> rules;
  final String? folderPath;

  /// The target folder does not exist on the account (rule imported anyway).
  final bool missingFolder;

  /// A `(status,is,read)` term was dropped (leave-until-read covers it).
  final bool droppedStatusRead;
  final String? skippedReason;

  bool get imported => rules.isNotEmpty;
}

class ImportResult {
  const ImportResult({
    this.createdAccounts = const [],
    this.reusedAccounts = const [],
    this.createdIdentities = const [],
    this.rules = const [],
    this.folderHints = const {},
    this.calendarsImported = 0,
    this.skipped = const [],
    this.errors = const [],
  });
  final List<Account> createdAccounts;
  final List<Account> reusedAccounts;
  final List<Identity> createdIdentities;
  final List<RuleImportOutcome> rules;

  /// accountId -> folder paths whose description got a "Rules: …" hint.
  final Map<String, List<String>> folderHints;
  final int calendarsImported;

  /// What was skipped and why (missing password, duplicate identity, …).
  final List<String> skipped;
  final List<String> errors;

  int get rulesImported => rules.where((r) => r.imported).length;
  int get rulesWithMissingFolder => rules.where((r) => r.imported && r.missingFolder).length;
  int get rulesDisabled => rules.where((r) => r.imported && r.rules.every((x) => !x.enabled)).length;
}
