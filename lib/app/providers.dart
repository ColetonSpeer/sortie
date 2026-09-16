import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import '../domain/entities/entities.dart';
import '../domain/repositories/repositories.dart';
import '../domain/services/services.dart';

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
final deviceIdentityProvider = Provider<DeviceIdentity>((_) => _unbound('deviceIdentity'));

/// One coordinator per account, created lazily by the override in main.dart.
final sortCoordinatorProvider = Provider.family<SortCoordinator, String>((_, __) => _unbound('sortCoordinator'));

/// Convenience streams shared by features.
final accountsProvider = StreamProvider<List<Account>>((ref) => ref.watch(accountRepositoryProvider).watchAll());
final aiSettingsProvider = StreamProvider<AiSettings>((ref) => ref.watch(settingsRepositoryProvider).watchAi());
final deviceSettingsProvider = StreamProvider<DeviceSettings>((ref) => ref.watch(settingsRepositoryProvider).watchDevice());
final sortConfigProvider = StreamProvider.family<SortConfig, String>((ref, accountId) => ref.watch(settingsRepositoryProvider).watchSortConfig(accountId));
final foldersProvider = StreamProvider.family<List<Folder>, String>((ref, accountId) => ref.watch(folderRepositoryProvider).watch(accountId));
final syncStatusProvider = StreamProvider<Map<String, AccountSyncStatus>>((ref) => ref.watch(mailSyncServiceProvider).watchAllStatus());
final pendingBadgesProvider = StreamProvider.family<Map<MessageKey, PendingBadge>, String>((ref, accountId) => ref.watch(sortCoordinatorProvider(accountId)).watchPending());
final coordinationStateProvider = StreamProvider.family<CoordinationState, String>((ref, accountId) => ref.watch(sortCoordinatorProvider(accountId)).state);
