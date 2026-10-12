import 'package:flutter_riverpod/misc.dart';

import '../core/clock.dart';
import '../data/calendar/google_oauth.dart';
import '../domain/entities/entities.dart';
import '../domain/repositories/repositories.dart';
import '../domain/services/services.dart';
import '../services/calendar/calendar_service.dart';
import 'ai_models.dart';
import 'demo/demo_data.dart';
import 'demo/fake_calendar.dart';
import 'demo/fake_repositories.dart';
import 'demo/fake_services.dart';
import 'onboarding_models.dart';
import 'providers.dart';

export 'demo/demo_data.dart';
export 'demo/fake_calendar.dart';
export 'demo/fake_repositories.dart';
export 'demo/fake_services.dart';

/// Riverpod overrides that let the app run with obviously fake data before
/// the sync/sorter/coordination backends exist (`--dart-define=SORTIE_DEMO=true`).
List<Override> demoOverrides({bool withAccount = true}) {
  final creds = FakeCredentialStore()..values[CredentialStore.deviceId] = DemoData.deviceId;
  final accounts = FakeAccountRepository(
    accounts: withAccount ? [DemoData.account] : [],
    identities: withAccount ? DemoData.identities : [],
  );
  final folders = FakeFolderRepository(withAccount ? DemoData.folders : []);
  final messages = FakeMessageRepository(withAccount ? DemoData.messages : []);
  final settings = FakeSettingsRepository(
    ai: const AiSettings(kind: AiProviderKind.anthropic),
    sortConfigs: {DemoData.accountId: DemoData.sortConfig},
  );
  final sync = FakeMailSyncService(messages, status: {
    DemoData.accountId: const AccountSyncStatus(accountId: DemoData.accountId, state: AccountSyncState.idling),
  });
  final classifier = FakeMessageClassifier()..bootstrapped = true;
  final advisor = FakeRuleAdvisor(pending: withAccount ? DemoData.suggestions() : const []);
  final rules = FakeRuleStore();
  final coordinators = <String, FakeSortCoordinator>{};
  FakeSortCoordinator coordinatorFor(String id) => coordinators.putIfAbsent(
        id,
        () => FakeSortCoordinator(
          id,
          messages: messages,
          deviceId: DemoData.deviceId,
          pending: id == DemoData.accountId ? DemoData.pendingBadges() : {},
          log: id == DemoData.accountId ? DemoData.sortLog() : [],
          devices: id == DemoData.accountId ? DemoData.devices() : [],
          config: DemoData.sortConfig,
        ),
      );

  final calendarRepo = FakeCalendarRepository(sources: DemoCalendarData.sources, events: DemoCalendarData.events(DateTime.now()));
  final googleLinks = GoogleAccountLinks(
      credentials: creds,
      client: () => GoogleOAuthClient(clientId: GoogleOAuthClient.defaultClientId, clientSecret: GoogleOAuthClient.defaultClientSecret));
  final calendar = CalendarService(
      repo: calendarRepo, credentials: creds, settings: settings, clock: SystemClock(), google: googleLinks, startupDelay: Duration.zero);

  return [
    calendarRepositoryProvider.overrideWithValue(calendarRepo),
    calendarServiceProvider.overrideWithValue(calendar),
    googleOAuthProvider.overrideWithValue(googleLinks),
    calendarImportSinkProvider.overrideWithValue(calendar),
    credentialStoreProvider.overrideWithValue(creds),
    accountRepositoryProvider.overrideWithValue(accounts),
    folderRepositoryProvider.overrideWithValue(folders),
    messageRepositoryProvider.overrideWithValue(messages),
    settingsRepositoryProvider.overrideWithValue(settings),
    mailSyncServiceProvider.overrideWithValue(sync),
    messageClassifierProvider.overrideWithValue(classifier),
    ruleAdvisorProvider.overrideWithValue(advisor),
    sortRuleStoreProvider.overrideWithValue(rules),
    sortCoordinatorProvider.overrideWith((ref, id) => coordinatorFor(id)),
    deviceIdentityProvider.overrideWithValue(const DeviceIdentity(
        deviceId: DemoData.deviceId, displayName: 'This laptop (demo)', platform: DevicePlatform.linux, priority: 30)),
    autodiscoveryProvider.overrideWithValue((email) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      final domain = email.contains('@') ? email.split('@').last : 'example.invalid';
      return [
        ServerCandidate(
          imap: ImapEndpoint(host: 'imap.$domain', port: 993, security: ConnectionSecurity.tls),
          smtp: SmtpEndpoint(host: 'smtp.$domain', port: 587, security: ConnectionSecurity.starttls),
          username: email,
          source: 'demo guess',
        ),
      ];
    }),
    loginProbeProvider.overrideWithValue((account, password) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (password == 'fail') throw StateError('Authentication failed (demo: any password except "fail" works)');
    }),
    composeMessageProvider.overrideWithValue((draft) async =>
        'From: ${draft.identity.email}\r\nTo: ${draft.to.join(', ')}\r\nSubject: ${draft.subject}\r\n\r\n${draft.bodyText}'.codeUnits),
    listModelsProvider.overrideWithValue((s, key) async {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return switch (s.kind) {
        AiProviderKind.anthropic => ['claude-sonnet-5', 'claude-haiku-4-5', 'claude-opus-4-1'],
        AiProviderKind.openAiCompat => ['llama3.1:8b', 'qwen2.5:14b', 'gpt-4o-mini'],
        AiProviderKind.none => <String>[],
      };
    }),
    testAiConnectionProvider.overrideWithValue((s, key) async {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (s.kind == AiProviderKind.none) return const ConnectionTestSummary(ok: false, message: 'No provider selected.');
      if ((key ?? '').isEmpty && !s.isLocal) return const ConnectionTestSummary(ok: false, message: 'API key is empty.');
      return ConnectionTestSummary(ok: true, message: 'Demo: reached ${s.kind.name} (${s.model}).', estUsdPer1000: s.isLocal ? 0 : 0.42);
    }),
  ];
}
