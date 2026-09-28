/// A parsed control-folder message. Ordering and expiry always use
/// [internalDate] (server-assigned) and [uid]; never device clocks.
class ControlMessage {
  const ControlMessage({
    required this.uid,
    required this.internalDate,
    required this.type,
    required this.deviceId,
    required this.messageId,
    required this.seq,
    this.epoch,
    this.priority,
    this.snapshotUpto,
    this.body,
  });
  final int uid;
  final DateTime internalDate;

  /// lease-claim | lease-beat | lease-release | presence | decision | moved |
  /// undo | correction | resolved | config | identities | rules | calendars |
  /// prefs | snapshot
  final String type;
  final String deviceId;
  final String messageId;
  final int seq;
  final int? epoch;
  final int? priority;
  final int? snapshotUpto;

  /// Decoded JSON body; null until fetched for header-only reads.
  final Map<String, dynamic>? body;

  static const journalTypes = {'decision', 'moved', 'undo', 'correction', 'resolved', 'config', ...sharedSectionTypes};

  /// Shared-config sections (docs/coordination-protocol.md, "Shared config"):
  /// each is its own last-writer-wins-by-UID section of the journal.
  static const sharedSectionTypes = {'identities', 'rules', 'calendars', 'prefs'};
  bool get isJournal => journalTypes.contains(type);

  ControlMessage withBody(Map<String, dynamic> b) => ControlMessage(
        uid: uid,
        internalDate: internalDate,
        type: type,
        deviceId: deviceId,
        messageId: messageId,
        seq: seq,
        epoch: epoch,
        priority: priority,
        snapshotUpto: snapshotUpto,
        body: b,
      );
}

/// What a writer appends. The implementation renders it as an RFC 5322
/// message with `X-Sortie-*` headers and a JSON body, appended with `\Seen`
/// and no date argument so the server stamps INTERNALDATE.
class ControlMessageDraft {
  const ControlMessageDraft({
    required this.type,
    required this.deviceId,
    required this.messageId,
    required this.seq,
    required this.body,
    this.epoch,
    this.priority,
    this.snapshotUpto,
  });
  final String type;
  final String deviceId;
  final String messageId;
  final int seq;
  final Map<String, dynamic> body;
  final int? epoch;
  final int? priority;
  final int? snapshotUpto;
}

class AppendedControlMessage {
  const AppendedControlMessage({required this.uid, required this.internalDate});
  final int uid;
  final DateTime internalDate;
}

/// Thin IMAP abstraction over the hidden `Sortie` folder. Implemented by
/// `ImapControlFolder` (over an [ImapGateway]) and faked in tests.
abstract class ControlFolder {
  /// CREATE + UNSUBSCRIBE if missing, probing the namespace. Returns the path.
  Future<String> ensureExists();
  Future<int> uidValidity();

  /// Appends and returns the UID plus the server INTERNALDATE (fetched back).
  Future<AppendedControlMessage> append(ControlMessageDraft draft);
  Future<List<ControlMessage>> fetchHeaders({int sinceUid = 1});
  Future<Map<String, dynamic>?> fetchBody(int uid);
  Future<int?> findByMessageId(String messageId);
  Future<void> expunge(Iterable<int> uids);

  /// IDLE-driven; emits whenever the folder changes. Implementations
  /// re-issue IDLE themselves and emit an error on connection loss.
  Stream<void> changes();
  Future<void> noop();
  Future<void> dispose();
}
