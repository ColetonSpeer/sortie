import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/calendar/google_oauth.dart';
import '../data/local/database.dart' show SortieDatabase;
import '../domain/entities/entities.dart';
import '../domain/repositories/calendar_repository.dart';
import '../domain/repositories/repositories.dart';
import '../domain/services/services.dart';
import '../services/calendar/calendar_service.dart';
import '../services/coordination/coordination_service.dart' show CoordinationService, SharedConfigSyncEvent;
import '../services/import/calendar_import_sink.dart';
import '../services/import/thunderbird/thunderbird_importer.dart';
import '../services/sorter/user_rules.dart';
import 'ai_models.dart';
import 'compose_models.dart';
import 'onboarding_models.dart';

/// Composition root. Every provider here is overridden in `main.dart` with the
/// real implementation; the defaults throw so a missing override is loud.
/// Feature code depends only on the interfaces in `domain/`.

Never _unbound(String name) => throw StateError('$name provider not overridden in main.dart');

final databaseProvider = Provider<SortieDatabase>((_) => _unbound('database'));
final credentialStoreProvider = Provider<CredentialStore>((_) => _unbound('credentialStore'));
final accountRepositoryProvider = Provider<AccountRepository>((_) => _unbound('accountRepository'));
final folderRepositoryProvider = Provider<FolderRepository>((_) => _unbound('folderRepository'));
final messageRepositoryProvider = Provider<MessageRepository>((_) => _unbound('messageRepository'));
final pendingOpRepositoryProvider = Provider<PendingOpRepository>((_) => _unbound('pendingOpRepository'));
final settingsRepositoryProvider = Provider<SettingsRepository>((_) => _unbound('settingsRepository'));
final mailSyncServiceProvider = Provider<MailSyncService>((_) => _unbound('mailSyncService'));
final messageClassifierProvider = Provider<MessageClassifier>((_) => _unbound('messageClassifier'));

/// Rule advisor (sorter module): suggestions, accept / dismiss, "Ask now".
final ruleAdvisorProvider = Provider<RuleAdvisorApi>((_) => _unbound('ruleAdvisor'));

/// Pending rule suggestions of one account.
final pendingSuggestionsProvider = StreamProvider.family<List<RuleSuggestion>, String>(
    (ref, accountId) => ref.watch(ruleAdvisorProvider).watchPending(accountId));

/// Inbox "N suggested sorting rules" banner hidden for this session (UI state only).
final suggestionBannerDismissedProvider = StateProvider<bool>((_) => false);
final deviceIdentityProvider = Provider<DeviceIdentity>((_) => _unbound('deviceIdentity'));

/// One coordinator per account, created lazily by the override in main.dart.
final sortCoordinatorProvider = Provider.family<SortCoordinator, String>((_, _) => _unbound('sortCoordinator'));

/// Convenience streams shared by features.
final accountsProvider = StreamProvider<List<Account>>((ref) => ref.watch(accountRepositoryProvider).watchAll());
final aiSettingsProvider = StreamProvider<AiSettings>((ref) => ref.watch(settingsRepositoryProvider).watchAi());
final deviceSettingsProvider = StreamProvider<DeviceSettings>((ref) => ref.watch(settingsRepositoryProvider).watchDevice());
final sortConfigProvider = StreamProvider.family<SortConfig, String>((ref, accountId) => ref.watch(settingsRepositoryProvider).watchSortConfig(accountId));
final foldersProvider = StreamProvider.family<List<Folder>, String>((ref, accountId) => ref.watch(folderRepositoryProvider).watch(accountId));
final syncStatusProvider = StreamProvider<Map<String, AccountSyncStatus>>((ref) => ref.watch(mailSyncServiceProvider).watchAllStatus());
final pendingBadgesProvider = StreamProvider.family<Map<MessageKey, PendingBadge>, String>((ref, accountId) => ref.watch(sortCoordinatorProvider(accountId)).watchPending());
final coordinationStateProvider = StreamProvider.family<CoordinationState, String>((ref, accountId) => ref.watch(sortCoordinatorProvider(accountId)).state);

// ---------------------------------------------------------------------------
// UI-layer providers (added by the UI module). The composition root must
// override every `_unbound` one below with the real implementation.
// ---------------------------------------------------------------------------

/// Autodiscovery: email -> candidate IMAP/SMTP servers (best first).
final autodiscoveryProvider =
    Provider<Future<List<ServerCandidate>> Function(String email)>((_) => _unbound('autodiscovery'));

/// Test IMAP + SMTP login for an account with the given password; throws on failure.
final loginProbeProvider =
    Provider<Future<void> Function(Account account, String password)>((_) => _unbound('loginProbe'));

/// Builds RFC 5322 bytes from a draft (the compose module's MessageComposer).
final composeMessageProvider =
    Provider<Future<List<int>> Function(ComposeDraft draft)>((_) => _unbound('composeMessage'));

/// Lists model ids available at the configured AI endpoint.
final listModelsProvider =
    Provider<Future<List<String>> Function(AiSettings settings, String? apiKey)>((_) => _unbound('listModels'));

/// Sends one tiny request to the AI endpoint and reports the outcome.
final testAiConnectionProvider =
    Provider<Future<ConnectionTestSummary> Function(AiSettings settings, String? apiKey)>(
        (_) => _unbound('testAiConnection'));

/// Addresses harvested from recent headers, most recent first.
final recentAddressesProvider = FutureProvider.family<List<MailAddress>, String>((ref, accountId) async {
  final repo = ref.watch(messageRepositoryProvider);
  final folders = await ref.watch(folderRepositoryProvider).all(accountId);
  final seen = <String, MailAddress>{};
  final targets = <String?>[null];
  for (final f in folders) {
    if (f.specialUse == SpecialUse.sent) targets.add(f.path);
  }
  for (final path in targets) {
    final headers = await repo.list(MessageQuery(accountId: accountId, folderPath: path, limit: 300));
    for (final h in headers) {
      for (final a in [if (h.from != null) h.from!, ...h.to, ...h.cc, if (h.replyTo != null) h.replyTo!]) {
        final k = a.email.toLowerCase();
        if (k.isEmpty || seen.containsKey(k)) continue;
        seen[k] = a;
      }
    }
  }
  return seen.values.toList();
});

/// Identities of one account.
final identitiesProvider = StreamProvider.family<List<Identity>, String>(
    (ref, accountId) => ref.watch(accountRepositoryProvider).watchIdentities(accountId));

/// Messages of one folder, optionally filtered by a search string. Keyed by a
/// record because [MessageQuery] has no value equality.
typedef FolderMessagesKey = ({String accountId, String folderPath, String search});
final messagesProvider = StreamProvider.family<List<MessageHeader>, FolderMessagesKey>((ref, k) =>
    ref.watch(messageRepositoryProvider).watch(MessageQuery(
        accountId: k.accountId, folderPath: k.folderPath, search: k.search.isEmpty ? null : k.search, limit: 500)));

/// Follows one message across moves.
final messageByHashProvider = StreamProvider.family<MessageHeader?, MessageKey>(
    (ref, key) => ref.watch(messageRepositoryProvider).watchByMessageIdHash(key.accountId, key.messageIdHash));

/// Sort log and seen devices of one account's coordinator.
final sortLogProvider = StreamProvider.family<List<SortLogEntry>, String>(
    (ref, accountId) => ref.watch(sortCoordinatorProvider(accountId)).watchLog());
final seenDevicesProvider = StreamProvider.family<List<SeenDevice>, String>(
    (ref, accountId) => ref.watch(sortCoordinatorProvider(accountId)).watchDevices());

/// Last shared-config section applied on this device (null = never).
final lastConfigSyncProvider = StreamProvider.family<SharedConfigSyncEvent?, String>((ref, accountId) {
  final c = ref.watch(sortCoordinatorProvider(accountId));
  return c is CoordinationService ? c.configSyncEvents : Stream.value(null);
});

/// Currently selected account id in the shell (UI state only).
final selectedAccountIdProvider = StateProvider<String?>((_) => null);

/// Ids of messages selected in the message list for bulk actions (UI state only).
final selectedMessagesProvider = StateProvider<Set<MessageKey>>((_) => const {});

// ---------------------------------------------------------------------------
// Import (Thunderbird). Additive wiring; only the rule store needs a real
// override (the composition root passes the sorter's UserRulesService).
// ---------------------------------------------------------------------------

/// Persistence for user sort rules (the sorter's UserRulesService).
final sortRuleStoreProvider = Provider<SortRuleStore>((_) => _unbound('sortRuleStore'));

/// Live rule list for Settings → Rules. Falls back to a one-shot load when
/// the bound store cannot watch.
final sortRulesProvider = StreamProvider.family<List<SortRule>, String>((ref, accountId) {
  final store = ref.watch(sortRuleStoreProvider);
  return store is SyncableRuleStore ? store.watch(accountId) : Stream.fromFuture(store.load(accountId));
});

/// Where imported calendars go. Until the calendar module registers its own
/// sink the default parks them under settings key `import.calendars.pending`.
final calendarImportSinkProvider =
    Provider<CalendarImportSink>((ref) => PendingCalendarImportSink(ref.watch(settingsRepositoryProvider)));

/// Finds Thunderbird profiles on this machine (tests inject a fixed list).
final thunderbirdProfileLocatorProvider = Provider<ProfileLocator>((_) => PlatformProfileLocator());

final thunderbirdImporterProvider = Provider<ThunderbirdImporter>((ref) {
  Future<void> saveConfig(String accountId, SortConfig c) async {
    try {
      await ref.read(sortCoordinatorProvider(accountId)).putConfig(c);
    } catch (_) {
      // Coordinator offline / not started: the local mirror below still wins.
    }
    await ref.read(settingsRepositoryProvider).saveSortConfig(accountId, c);
  }

  return ThunderbirdImporter(
    locator: ref.watch(thunderbirdProfileLocatorProvider),
    accounts: ref.watch(accountRepositoryProvider),
    folders: ref.watch(folderRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    credentials: ref.watch(credentialStoreProvider),
    rules: ref.watch(sortRuleStoreProvider),
    calendarSink: ref.watch(calendarImportSinkProvider),
    loginProbe: ref.watch(loginProbeProvider),
    saveSortConfig: saveConfig,
    onAccountCreated: (id) => ref.read(mailSyncServiceProvider).startAccount(id),
  );
});

// ---------------------------------------------------------------------------
// Calendar module. Overridden in the composition root and the demo build.
// ---------------------------------------------------------------------------

final calendarRepositoryProvider = Provider<CalendarRepository>((_) => _unbound('calendarRepository'));
final calendarServiceProvider = Provider<CalendarService>((_) => _unbound('calendarService'));

/// Google account links (refresh tokens keyed by email) shared by calendars.
final googleOAuthProvider = Provider<GoogleAccountLinks>((_) => _unbound('googleOAuth'));
