import 'dart:async';
import 'dart:io';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/clock.dart';
import '../core/wake_detector.dart';
import '../data/ai/ai_provider.dart';
import '../data/ai/ai_provider_factory.dart';
import '../data/calendar/google_oauth.dart';
import '../data/credentials/encrypted_file_credential_store.dart';
import '../data/credentials/fallback_credential_store.dart';
import '../data/credentials/secure_storage_credential_store.dart';
import '../data/local/database.dart' show SortieDatabase;
import '../data/local/repositories/drift_account_repository.dart';
import '../data/local/repositories/drift_calendar_repository.dart';
import '../data/local/repositories/drift_folder_repository.dart';
import '../data/local/repositories/drift_message_repository.dart';
import '../data/local/repositories/drift_pending_op_repository.dart';
import '../data/local/repositories/drift_settings_repository.dart';
import '../data/mail/autodiscovery.dart' as disc;
import '../data/mail/enough/enough_imap_gateway.dart';
import '../data/mail/enough/enough_smtp_gateway.dart';
import '../domain/entities/entities.dart';
import '../domain/repositories/repositories.dart';
import '../domain/services/services.dart';
import '../platform/background/background_runner.dart';
import '../platform/device_info.dart';
import '../services/calendar/calendar_service.dart';
import '../services/compose/draft_request.dart';
import '../services/compose/message_composer.dart' as mc;
import '../services/coordination/coordination_service.dart';
import '../services/notifications/new_mail_notifier.dart';
import '../services/notifications/notification_service.dart';
import '../services/sorter/sorter_pipeline.dart';
import '../services/sync/sync_engine.dart';
import 'ai_models.dart';
import 'compose_models.dart';
import 'onboarding_models.dart';
import 'providers.dart';

/// Builds every real service once and exposes them as provider overrides.
/// This is the only place that knows concrete classes from data/ and services/.
class SortieServices {
  SortieServices._();

  static final _log = Logger('composition');

  late final SortieDatabase db;
  late final CredentialStore credentials;
  late final AccountRepository accounts;
  late final FolderRepository folders;
  late final DriftMessageRepository messages;
  late final PendingOpRepository pendingOps;
  late final SettingsRepository settings;
  late final SyncEngine sync;
  late final SorterService classifier;
  late final DeviceIdentity device;
  late final mc.MessageComposer composer;
  late final DriftCalendarRepository calendarRepo;
  late final GoogleAccountLinks googleLinks;
  late final CalendarService calendar;

  /// Owned here so calendar reminders can reach it; the bootstrap inits it.
  final notifications = NotificationService();
  late final NewMailNotifier newMail;
  final clock = SystemClock();

  final wake = WakeDetector();
  final _coordinators = <String, CoordinationService>{};
  final _accountCache = <String, Account>{};
  DeviceSettings _deviceSettings = const DeviceSettings();
  AiProvider? _aiProvider;
  String _aiProviderKey = '';
  final _subs = <StreamSubscription<void>>[];

  static Future<SortieServices> build() async {
    final s = SortieServices._();
    final support = await getApplicationSupportDirectory();

    s.db = SortieDatabase(driftDatabase(name: 'sortie'));
    s.credentials = FallbackCredentialStore(
      primary: SecureStorageCredentialStore(),
      fallback: await EncryptedFileCredentialStore.inAppSupportDir(),
    );
    s.accounts = DriftAccountRepository(s.db);
    s.folders = DriftFolderRepository(s.db);
    s.messages = DriftMessageRepository(s.db, clock: s.clock);
    s.pendingOps = DriftPendingOpRepository(s.db, clock: s.clock);
    s.settings = DriftSettingsRepository(s.db);

    s._deviceSettings = await s.settings.device();
    s.device = await loadDeviceIdentity(s.credentials, s._deviceSettings);

    s.sync = SyncEngine(
      accounts: s.accounts,
      folders: s.folders,
      messages: s.messages,
      pendingOps: s.pendingOps,
      credentials: s.credentials,
      gatewayFactory: (a) => () => EnoughImapGateway(logName: 'imap.${a.id}'),
      smtp: EnoughSmtpGateway(),
      clock: s.clock,
      spoolDir: Directory(p.join(support.path, 'outbox')),
      pruneBodyCache: s.messages.pruneBodyCache,
    );

    s.classifier = SorterService(
      database: s.db,
      messages: s.messages,
      settings: s.settings,
      provider: () => s._aiProvider,
      clock: s.clock,
      deviceId: s.device.deviceId,
    );
    s.composer = mc.MessageComposer(clock: s.clock);
    s._buildCalendar();
    final importance = ImportanceContext(accounts: s.accounts, folders: s.folders, messages: s.messages, clock: s.clock);
    s.newMail = NewMailNotifier(
      accounts: s.accounts.watchAll(),
      arrivals: s.sync.inboxArrivals,
      sink: s.notifications,
      mode: () => s._deviceSettings.effectiveNotifyMode(mobile: !isDesktop),
      judge: importance.judge,
      clock: s.clock,
    );

    await s._refreshAiProvider(await s.settings.ai());
    s._subs.add(s.settings.watchAi().listen(s._refreshAiProvider));
    s._subs.add(s.settings.watchDevice().listen((d) => s._deviceSettings = d));
    s._subs.add(s.accounts.watchAll().listen(s._onAccounts));

    backgroundCycle = s.runBackgroundCycle;
    return s;
  }

  Future<void> _refreshAiProvider(AiSettings ai) async {
    final key = ai.kind == AiProviderKind.none ? null : await credentials.read(CredentialStore.aiApiKey(ai.kind));
    final sig = '${ai.kind.name}|${ai.model}|${ai.baseUrl}|${key?.length ?? 0}';
    if (sig == _aiProviderKey) return;
    _aiProviderKey = sig;
    _aiProvider = buildProvider(ai, key);
    _log.info('AI provider: ${_aiProvider?.modelId ?? 'none'}');
  }

  void _onAccounts(List<Account> list) {
    final ids = <String>{};
    for (final a in list) {
      _accountCache[a.id] = a;
      ids.add(a.id);
      if (a.enabled) unawaited(_ensureCoordinator(a.id).start());
    }
    for (final id in _coordinators.keys.toList()) {
      final a = _accountCache[id];
      if (!ids.contains(id) || a == null || !a.enabled) {
        final c = _coordinators.remove(id);
        unawaited(c?.stop());
      }
    }
  }

  CoordinationService _ensureCoordinator(String accountId) => _coordinators.putIfAbsent(
        accountId,
        () => CoordinationService(
          accountId: accountId,
          me: device,
          gatewayFactory: sync.gatewayFactory(accountId),
          password: () => sync.password(accountId),
          account: () => _accountCache[accountId]!,
          sync: sync,
          classifier: classifier,
          messages: messages,
          settings: settings,
          db: db,
          clock: clock,
          mayLead: () => _deviceSettings.mayLead,
          sharedConfig: SharedConfigDeps(accounts: accounts, rules: classifier.rules, calendars: calendarRepo, settings: settings, suggestions: classifier.suggestions),
          advisor: (id) => classifier.advisor.maybeRun(id),
        ),
      );

  SortCoordinator coordinator(String accountId) {
    final c = _ensureCoordinator(accountId);
    if (c.currentState == CoordinationState.stopped && (_accountCache[accountId]?.enabled ?? false)) {
      unawaited(c.start());
    }
    return c;
  }

  /// One bounded cycle per account for WorkManager / BGAppRefresh.
  Future<void> runBackgroundCycle() async {
    for (final a in await accounts.all()) {
      if (!a.enabled) continue;
      try {
        await coordinator(a.id).runForegroundCycle();
      } catch (e, st) {
        _log.warning('background cycle failed for ${a.id}', e, st);
      }
    }
  }

  void _buildCalendar() {
    calendarRepo = DriftCalendarRepository(db);
    googleLinks = GoogleAccountLinks(credentials: credentials, client: () => calendar.googleClient());
    calendar = CalendarService(
      repo: calendarRepo,
      credentials: credentials,
      settings: settings,
      clock: clock,
      google: googleLinks,
      onReminder: (o, minutes) async {
        final n = notifications;
        final when = minutes == 0 ? 'now' : 'in $minutes min';
        await n.notifyEventReminder(id: o.key, title: o.event.summary.isEmpty ? 'Event' : o.event.summary, body: 'Starts $when${o.event.location == null ? '' : ' · ${o.event.location}'}');
      },
    );
  }

  Future<void> start() async {
    newMail.start();
    await sync.start();
    unawaited(calendar.start());
    final startup = _coordinators.values.toList();
    for (final c in startup) {
      unawaited(c.start());
    }
    _subs.add(wake.wakes.listen(_onWake));
    wake.start();
  }

  void _onWake(Duration asleep) {
    _log.info('woke after ${asleep.inMinutes}m: resyncing');
    sync.onResume();
    for (final c in _coordinators.values) {
      c.onResume(asleep);
    }
  }

  Future<void> stop() async {
    await wake.dispose();
    await newMail.stop();
    for (final c in _coordinators.values) {
      await c.stop();
    }
    await sync.stop();
    await calendar.stop();
    for (final s in _subs) {
      await s.cancel();
    }
    await classifier.dispose();
    await db.close();
  }

  // ------------------------------------------------------------ UI adapters

  /// Discovery guesses several hosts (imap./mail./bare domain). Keep only the
  /// ones that resolve and accept a TCP connection so the pre-filled server
  /// is one that really exists; autoconfig/SRV results come first anyway.
  Future<List<ServerCandidate>> autodiscover(String email) async {
    final found = await disc.Autodiscovery(imapFactory: EnoughImapGateway.new, smtp: EnoughSmtpGateway()).discover(email);
    final reachable = <String, bool>{};
    Future<bool> ok(String host, int port) async {
      final key = '$host:$port';
      final cached = reachable[key];
      if (cached != null) return cached;
      var result = false;
      try {
        final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 4));
        socket.destroy();
        result = true;
      } catch (_) {
        result = false;
      }
      return reachable[key] = result;
    }

    final out = <ServerCandidate>[];
    for (final c in found) {
      if (await ok(c.imap.host, c.imap.port) && await ok(c.smtp.host, c.smtp.port)) {
        out.add(ServerCandidate(imap: c.imap, smtp: c.smtp, username: c.username, source: c.source));
      }
    }
    _log.info('autodiscovery for ${email.split('@').last}: ${found.length} guesses, ${out.length} reachable');
    return out;
  }

  Future<void> loginProbe(Account account, String password) async {
    final imap = EnoughImapGateway(logName: 'probe');
    try {
      await imap.connect(account, password);
    } finally {
      await imap.disconnect();
    }
    await EnoughSmtpGateway().testLogin(account, password);
  }

  Future<List<int>> compose(ComposeDraft d) async => composer.compose(requestForDraft(d)).raw;

  Future<List<String>> listModels(AiSettings ai, String? apiKey) async {
    final provider = buildProvider(ai, apiKey);
    if (provider == null) return const [];
    return (await provider.listModels()).map((m) => m.id).toList();
  }

  Future<ConnectionTestSummary> testAi(AiSettings ai, String? apiKey) async {
    final provider = buildProvider(ai, apiKey);
    if (provider == null) return const ConnectionTestSummary(ok: false, message: 'No AI provider configured.');
    try {
      final r = await provider.testConnection();
      final msg = r.error ??
          r.warning ??
          (r.ok
              ? 'Connected to ${provider.modelId}'
                  '${r.latency != null ? ' in ${r.latency!.inMilliseconds} ms' : ''}'
                  '${r.schemaEnforced ? ', JSON schema enforced' : ''}.'
              : 'Connection test failed.');
      return ConnectionTestSummary(ok: r.ok, message: msg, estUsdPer1000: r.estUsdPer1000);
    } on AiProviderException catch (e) {
      return ConnectionTestSummary(ok: false, message: e.message);
    }
  }

  List<Override> overrides() => [
        databaseProvider.overrideWithValue(db),
        credentialStoreProvider.overrideWithValue(credentials),
        accountRepositoryProvider.overrideWithValue(accounts),
        folderRepositoryProvider.overrideWithValue(folders),
        messageRepositoryProvider.overrideWithValue(messages),
        pendingOpRepositoryProvider.overrideWithValue(pendingOps),
        settingsRepositoryProvider.overrideWithValue(settings),
        mailSyncServiceProvider.overrideWithValue(sync),
        messageClassifierProvider.overrideWithValue(classifier),
        ruleAdvisorProvider.overrideWithValue(classifier.advisor),
        deviceIdentityProvider.overrideWithValue(device),
        sortCoordinatorProvider.overrideWith((ref, accountId) => coordinator(accountId)),
        sortRuleStoreProvider.overrideWithValue(classifier.rules),
        autodiscoveryProvider.overrideWithValue(autodiscover),
        loginProbeProvider.overrideWithValue(loginProbe),
        composeMessageProvider.overrideWithValue(compose),
        listModelsProvider.overrideWithValue(listModels),
        testAiConnectionProvider.overrideWithValue(testAi),
        calendarRepositoryProvider.overrideWithValue(calendarRepo),
        calendarServiceProvider.overrideWithValue(calendar),
        googleOAuthProvider.overrideWithValue(googleLinks),
        calendarImportSinkProvider.overrideWithValue(calendar),
        notificationServiceProvider.overrideWithValue(notifications),
      ];
}
