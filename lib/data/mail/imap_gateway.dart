import '../../domain/entities/entities.dart';

/// Server capabilities relevant to Sortie.
class ImapCapabilities {
  const ImapCapabilities({
    this.idle = false,
    this.move = false,
    this.uidPlus = false,
    this.condStore = false,
    this.qresync = false,
    this.specialUse = false,
    this.customKeywords = true,
    this.raw = const [],
  });
  final bool idle;
  final bool move;
  final bool uidPlus;
  final bool condStore;
  final bool qresync;
  final bool specialUse;

  /// PERMANENTFLAGS of the selected mailbox contained `\*`.
  final bool customKeywords;
  final List<String> raw;

  ImapCapabilities copyWith({bool? customKeywords}) => ImapCapabilities(
        idle: idle,
        move: move,
        uidPlus: uidPlus,
        condStore: condStore,
        qresync: qresync,
        specialUse: specialUse,
        customKeywords: customKeywords ?? this.customKeywords,
        raw: raw,
      );
}

class SelectResult {
  const SelectResult({
    required this.path,
    required this.uidValidity,
    required this.uidNext,
    required this.exists,
    this.highestModSeq,
    this.permanentFlagsAllowKeywords = true,
    this.vanishedUids = const [],
  });
  final String path;
  final int uidValidity;
  final int uidNext;
  final int exists;
  final int? highestModSeq;
  final bool permanentFlagsAllowKeywords;

  /// QRESYNC: UIDs removed since the known modseq, when provided.
  final List<int> vanishedUids;
}

/// Events from an IDLE session or an untagged response.
sealed class MailboxEvent {
  const MailboxEvent(this.path);
  final String path;
}

class NewMessagesEvent extends MailboxEvent {
  const NewMessagesEvent(super.path, this.exists);
  final int exists;
}

class ExpungeEvent extends MailboxEvent {
  const ExpungeEvent(super.path, {this.uids = const [], this.sequenceNumbers = const []});
  final List<int> uids;
  final List<int> sequenceNumbers;
}

class FlagsChangedEvent extends MailboxEvent {
  const FlagsChangedEvent(super.path, this.uid, this.flags);
  final int? uid;
  final Set<String> flags;
}

class ConnectionLostEvent extends MailboxEvent {
  const ConnectionLostEvent(super.path, [this.error]);
  final Object? error;
}

class MoveResult {
  const MoveResult({this.uidMapping = const {}});

  /// source UID -> destination UID when the server supports UIDPLUS COPYUID.
  final Map<int, int> uidMapping;
}

class AppendResult {
  const AppendResult({this.uid, this.uidValidity});
  final int? uid;
  final int? uidValidity;
}

/// Raw fetch of the control-folder envelope used by the coordinator.
class RawMessage {
  const RawMessage({required this.uid, required this.internalDate, required this.flags, required this.headers, this.body});
  final int uid;
  final DateTime internalDate;
  final Set<String> flags;

  /// Lower-cased header name -> value (first occurrence).
  final Map<String, String> headers;
  final String? body;
}

class UidRange {
  const UidRange(this.from, [this.to]);
  const UidRange.single(int uid) : this(uid, uid);
  const UidRange.fromTo(this.from, this.to);
  const UidRange.since(this.from) : to = null;
  final int from;

  /// Null means `*`.
  final int? to;

  @override
  String toString() => to == null ? '$from:*' : (to == from ? '$from' : '$from:$to');
}

/// One IMAP connection. Implementations: `EnoughImapGateway` (real),
/// `FakeImapGateway` (tests). The sync engine owns two per account and the
/// coordinator a third. Methods throw [ImapGatewayException] on protocol or
/// connection failure.
abstract class ImapGateway {
  Future<ImapCapabilities> connect(Account account, String password);
  bool get isConnected;
  Future<void> disconnect();
  Future<void> noop();

  /// Hierarchy delimiter learned from LIST; null before connect.
  String? get delimiter;
  Future<List<Folder>> listFolders();
  Future<Folder> createFolder(String path);
  Future<void> unsubscribeFolder(String path);

  Future<SelectResult> select(String path, {int? knownUidValidity, int? knownModSeq});
  String? get selectedPath;
  Future<void> close();

  /// Runs IDLE until [stop] completes, emitting events. Callers re-issue
  /// IDLE every ~25 minutes.
  Stream<MailboxEvent> idle({required Future<void> stop});

  Future<List<MessageHeader>> fetchHeaders(UidRange range, {int? changedSince});
  Future<List<MessageHeader>> fetchHeadersByUids(List<int> uids);
  Future<Map<int, Set<String>>> fetchFlags(UidRange range, {int? changedSince});
  Future<MessageBody> fetchBody(int uid);
  Future<List<int>> fetchRaw(int uid);
  Future<List<int>> fetchAttachment(int uid, String partId);
  Future<List<int>> searchUids(String criteria);
  Future<List<int>> searchByMessageId(String messageId);
  Future<List<int>> searchKeyword(String keyword);
  Future<List<int>> allUids();

  Future<void> store(List<int> uids, {Set<String> add = const {}, Set<String> remove = const {}});
  Future<MoveResult> move(List<int> uids, String destinationPath);
  Future<void> expunge(List<int> uids);
  Future<AppendResult> append(String path, List<int> raw, {Set<String> flags = const {}});

  /// Control-folder helpers: header-only fetch with INTERNALDATE.
  Future<List<RawMessage>> fetchRawHeaders(UidRange range, List<String> headerNames);
  Future<String?> fetchTextBody(int uid);
}

class ImapGatewayException implements Exception {
  const ImapGatewayException(this.message, {this.isAuthFailure = false, this.isConnectionLost = false, this.cause});
  final String message;
  final bool isAuthFailure;
  final bool isConnectionLost;
  final Object? cause;
  @override
  String toString() => 'ImapGatewayException: $message';
}
