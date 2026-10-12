import '../../data/mail/imap_gateway.dart';
import '../entities/entities.dart';

/// Creates a fresh, unconnected IMAP connection. Both the sync engine and the
/// coordinator need their own sessions to the same account.
typedef ImapGatewayFactory = ImapGateway Function();

enum AccountSyncState { idle, connecting, syncing, idling, backoff, offline, authFailed, disabled }

class AccountSyncStatus {
  const AccountSyncStatus({required this.accountId, required this.state, this.error, this.nextRetryAt});
  final String accountId;
  final AccountSyncState state;
  final String? error;
  final DateTime? nextRetryAt;
}

/// Per-message flag change seen on the server (IDLE or poll). The read-guard
/// uses `\Seen` transitions to start the grace period.
class FlagsObservation {
  const FlagsObservation({required this.accountId, required this.folderPath, required this.header, required this.observedAt});
  final String accountId;
  final String folderPath;
  final MessageHeader header;

  /// Local monotonic-derived wall time when the leader saw it.
  final DateTime observedAt;
}

/// Owned by the sync module. One instance for the whole app.
abstract class MailSyncService {
  Future<void> start();
  Future<void> stop();
  Future<void> startAccount(String accountId);
  Future<void> stopAccount(String accountId);
  Stream<AccountSyncStatus> watchStatus(String accountId);
  Stream<Map<String, AccountSyncStatus>> watchAllStatus();
  Future<void> syncNow(String accountId, {String? folderPath});
  Future<void> refreshFolders(String accountId);

  /// Headers newly arrived in INBOX (after they are in the local cache).
  Stream<List<MessageHeader>> newInboxMessages(String accountId);
  Stream<FlagsObservation> flagChanges(String accountId);

  /// Capabilities learned on the last connect, null before.
  ImapCapabilities? capabilities(String accountId);

  /// User actions. Applied optimistically and queued.
  Future<void> setFlags(String accountId, String folderPath, List<int> uids, {Set<String> add = const {}, Set<String> remove = const {}});
  Future<void> markSeen(String accountId, String folderPath, int uid, {bool seen = true});
  Future<void> move(String accountId, String fromFolder, List<int> uids, String toFolder, {String cause = 'manual'});
  Future<void> delete(String accountId, String folderPath, List<int> uids, {bool permanent = false});
  Future<MessageBody> body(String accountId, String folderPath, int uid);
  Future<List<int>> attachment(String accountId, String folderPath, int uid, String partId);
  Future<List<int>> rawMessage(String accountId, String folderPath, int uid);
  Future<void> saveDraft(String accountId, List<int> raw);
  Future<void> send(String accountId, String identityId, List<String> recipients, List<int> raw);

  /// A dedicated connection for the coordinator's control folder.
  ImapGatewayFactory gatewayFactory(String accountId);
  Future<String> password(String accountId);
}

class ClassificationInput {
  const ClassificationInput({required this.header, this.bodyText});
  final MessageHeader header;

  /// Cleaned text if already cached; the classifier may fetch/strip itself.
  final String? bodyText;
}

/// Owned by the sorter module. Called only by the leader.
abstract class MessageClassifier {
  /// Runs rules -> learned stats -> model. Returns one decision per input
  /// (mode `keep` when nothing applies). Never moves anything.
  Future<List<SortDecision>> classify(String accountId, List<ClassificationInput> inputs, SortConfig config, {bool dryRun = false});

  /// Learn from a user action. Never called for the sorter's own moves.
  Future<void> recordCorrection(Correction c);

  /// Builds folder profiles from the local cache; first run per account.
  Future<void> bootstrap(String accountId, SortConfig config, {void Function(String)? progress});
  Future<bool> isBootstrapped(String accountId);

  /// Replays recent user filings and reports agreement 0..1.
  Future<double> accuracyReplay(String accountId, SortConfig config, {int sample = 200});

  /// Spend so far today / this month in USD.
  Future<(double, double)> spend();
  Stream<String> get statusMessages;
}

/// Owned by the sorter module: proposes sorting rules from what the
/// deterministic layers could not place and from the owner's manual moves.
/// Never moves anything; accepting a suggestion only creates a rule.
abstract class RuleAdvisorApi {
  Stream<List<RuleSuggestion>> watchPending(String accountId);

  /// Pattern pass now; model pass only if the mode, provider and caps allow.
  /// [force] = the user pressed "Ask now" (ignores the interval).
  Future<AdvisorRun> runNow(String accountId, {bool force = true});

  /// Creates the rule (with optional edits) and returns its id.
  Future<String> accept(String suggestionId, {Map<String, dynamic>? match, String? folderPath});
  Future<void> dismiss(String suggestionId);
}

enum CoordinationState { stopped, connecting, syncing, follower, candidate, leader, yielding }

class PendingBadge {
  const PendingBadge({required this.key, required this.destination, required this.confidence, required this.reason, required this.mode, required this.decisionId, this.layer});
  final MessageKey key;
  final String destination;
  final double confidence;
  final String reason;
  final SortMode mode;
  final String decisionId;
  final SortLayer? layer;
}

class SortLogEntry {
  const SortLogEntry({
    required this.id,
    required this.at,
    required this.type,
    required this.key,
    required this.subject,
    required this.from,
    this.fromFolder,
    this.toFolder,
    this.reason,
    this.confidence,
    this.deviceId,
    this.cause,
    this.undoable = false,
    this.decisionId,
  });
  final String id;
  final DateTime at;

  /// decision | moved | undo | correction | resolved
  final String type;
  final MessageKey key;
  final String subject;
  final String from;
  final String? fromFolder;
  final String? toFolder;
  final String? reason;
  final double? confidence;
  final String? deviceId;
  final String? cause;
  final bool undoable;
  final String? decisionId;
}

class SeenDevice {
  const SeenDevice({required this.deviceId, required this.displayName, required this.platform, required this.priority, required this.lastSeen, required this.isLeader, required this.isThisDevice});
  final String deviceId;
  final String displayName;
  final String platform;
  final int priority;
  final DateTime lastSeen;
  final bool isLeader;
  final bool isThisDevice;
}

/// Owned by the coordination module. One per account.
abstract class SortCoordinator {
  String get accountId;
  Future<void> start();
  Future<void> stop({bool graceful = true});
  Stream<CoordinationState> get state;
  CoordinationState get currentState;
  int? get epoch;

  Stream<Map<MessageKey, PendingBadge>> watchPending();
  Stream<List<SortLogEntry>> watchLog({int limit = 200});
  Stream<List<SeenDevice>> watchDevices();
  Stream<SortConfig> watchConfig();
  Future<void> putConfig(SortConfig c);

  /// User actions from any device.
  Future<void> undo(String decisionId);
  Future<void> moveNow(MessageKey key);
  Future<void> keepInInbox(MessageKey key);
  Future<void> changeDestination(MessageKey key, String folderPath);
  Future<void> markRight(MessageKey key);

  /// Read-guard hooks from the message view.
  void onMessageOpened(MessageKey key);
  void onMessageClosed(MessageKey key);

  /// iOS BGAppRefresh / WorkManager: one bounded cycle.
  Future<void> runForegroundCycle({Duration budget = const Duration(seconds: 25)});

  /// Re-classifies the INBOX messages a (new) rule matches through the normal
  /// path, so read-guard and leave-until-read still apply. Only the leader can
  /// do this; other devices return 0.
  Future<int> applyRuleToInbox(String ruleId);

  /// Same for every enabled rule at once (Settings → Rules → Run now).
  Future<int> applyRulesToInbox();
}
