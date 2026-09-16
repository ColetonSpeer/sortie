/// In-memory fakes for widget tests. The implementations live under
/// `lib/app/demo/` so the demo build can share them; this file re-exports them
/// and adds test-only helpers.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:sortie/app/demo/demo_data.dart';
import 'package:sortie/app/demo/fake_repositories.dart';
import 'package:sortie/app/demo/fake_services.dart';
import 'package:sortie/app/providers.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/domain/services/services.dart';

export 'package:sortie/app/demo/demo_data.dart';
export 'package:sortie/app/demo/fake_repositories.dart';
export 'package:sortie/app/demo/fake_services.dart';

/// A fully wired set of fakes with the demo seed data.
class UiFakes {
  UiFakes({bool seed = true})
      : creds = FakeCredentialStore(),
        accounts = FakeAccountRepository(
            accounts: seed ? [DemoData.account] : [], identities: seed ? DemoData.identities : []),
        folders = FakeFolderRepository(seed ? DemoData.folders : []),
        messages = FakeMessageRepository(seed ? DemoData.messages : []),
        settings = FakeSettingsRepository(sortConfigs: {DemoData.accountId: DemoData.sortConfig}),
        classifier = FakeMessageClassifier() {
    sync = FakeMailSyncService(messages, status: {
      DemoData.accountId: const AccountSyncStatus(accountId: DemoData.accountId, state: AccountSyncState.idling),
    });
    coordinator = FakeSortCoordinator(
      DemoData.accountId,
      messages: messages,
      deviceId: DemoData.deviceId,
      pending: seed ? DemoData.pendingBadges() : {},
      log: seed ? DemoData.sortLog() : [],
      devices: seed ? DemoData.devices() : [],
      config: DemoData.sortConfig,
    );
  }

  final FakeCredentialStore creds;
  final FakeAccountRepository accounts;
  final FakeFolderRepository folders;
  final FakeMessageRepository messages;
  final FakeSettingsRepository settings;
  final FakeMessageClassifier classifier;
  late final FakeMailSyncService sync;
  late final FakeSortCoordinator coordinator;

  List<Override> overrides({List<Override> extra = const []}) => [
        credentialStoreProvider.overrideWithValue(creds),
        accountRepositoryProvider.overrideWithValue(accounts),
        folderRepositoryProvider.overrideWithValue(folders),
        messageRepositoryProvider.overrideWithValue(messages),
        settingsRepositoryProvider.overrideWithValue(settings),
        mailSyncServiceProvider.overrideWithValue(sync),
        messageClassifierProvider.overrideWithValue(classifier),
        sortCoordinatorProvider.overrideWith((ref, id) => coordinator),
        deviceIdentityProvider.overrideWithValue(const DeviceIdentity(
            deviceId: DemoData.deviceId, displayName: 'test', platform: DevicePlatform.linux, priority: 30)),
        ...extra,
      ];

  /// Wraps [child] in a ProviderScope + MaterialApp for pumping.
  Widget app(Widget child, {List<Override> extra = const [], Size size = const Size(1200, 800)}) => ProviderScope(
        overrides: overrides(extra: extra),
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: child,
          ),
        ),
      );
}
