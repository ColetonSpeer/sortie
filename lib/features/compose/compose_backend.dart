import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/compose_models.dart';
import '../../app/providers.dart';
import '../../core/hashing.dart';
import '../../domain/entities/entities.dart';
import '../../services/compose/draft_reviewer.dart';

/// Everything the compose screen needs from the rest of the app, so the
/// same screen can run inside the main window or in a separate compose
/// window whose engine reaches the services over a window channel.
abstract class ComposeBackend {
  Future<List<Identity>> identities(String accountId);
  Future<MessageHeader?> message(String accountId, String folderPath, int uid);

  /// An earlier message of a thread by its Message-ID, from the local cache.
  Future<MessageHeader?> messageById(String accountId, String messageId);
  Future<MessageBody> body(String accountId, String folderPath, int uid);
  Future<List<MailAddress>> recentAddresses(String accountId);
  Future<List<int>> compose(ComposeDraft draft);
  Future<void> saveDraft(String accountId, List<int> raw, {String? supersedesMessageId});
  Future<void> discardDraft(String accountId, String messageId);
  Future<void> send(String accountId, String identityId, List<String> recipients, List<int> raw, {String? draftMessageId});
  Future<String?> reviewUnavailableReason();
  Future<DraftReview> reviewDraft(DraftReviewRequest request);
}

/// In-process backend over the app's repositories and sync service.
class LocalComposeBackend implements ComposeBackend {
  LocalComposeBackend(this._ref);
  final Ref _ref;

  @override
  Future<List<Identity>> identities(String accountId) => _ref.read(accountRepositoryProvider).identities(accountId);

  @override
  Future<MessageHeader?> message(String accountId, String folderPath, int uid) =>
      _ref.read(messageRepositoryProvider).byUid(accountId, folderPath, uid);

  @override
  Future<MessageHeader?> messageById(String accountId, String messageId) =>
      _ref.read(messageRepositoryProvider).byMessageIdHash(accountId, messageIdHash(messageId: messageId));

  @override
  Future<MessageBody> body(String accountId, String folderPath, int uid) =>
      _ref.read(mailSyncServiceProvider).body(accountId, folderPath, uid);

  @override
  Future<List<MailAddress>> recentAddresses(String accountId) => _ref.read(recentAddressesProvider(accountId).future);

  @override
  Future<List<int>> compose(ComposeDraft draft) => _ref.read(composeMessageProvider)(draft);

  @override
  Future<void> saveDraft(String accountId, List<int> raw, {String? supersedesMessageId}) =>
      _ref.read(mailSyncServiceProvider).saveDraft(accountId, raw, supersedesMessageId: supersedesMessageId);

  @override
  Future<void> discardDraft(String accountId, String messageId) => _ref.read(mailSyncServiceProvider).discardDraft(accountId, messageId);

  @override
  Future<void> send(String accountId, String identityId, List<String> recipients, List<int> raw, {String? draftMessageId}) =>
      _ref.read(mailSyncServiceProvider).send(accountId, identityId, recipients, raw, draftMessageId: draftMessageId);

  @override
  Future<String?> reviewUnavailableReason() => _ref.read(draftReviewerProvider).unavailableReason();

  @override
  Future<DraftReview> reviewDraft(DraftReviewRequest request) => _ref.read(draftReviewerProvider).review(request);
}

final composeBackendProvider = Provider<ComposeBackend>((ref) => LocalComposeBackend(ref));
