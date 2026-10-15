/// Queued mailbox mutations applied optimistically and drained when online.
sealed class PendingOp {
  const PendingOp({required this.id, required this.accountId, required this.createdAt});
  final String id;
  final String accountId;
  final DateTime createdAt;
}

class SetFlagsOp extends PendingOp {
  const SetFlagsOp({
    required super.id,
    required super.accountId,
    required super.createdAt,
    required this.folderPath,
    required this.uidValidity,
    required this.messageIdHashes,
    required this.uids,
    this.add = const {},
    this.remove = const {},
  });
  final String folderPath;
  final int uidValidity;
  final List<String> messageIdHashes;
  final List<int> uids;
  final Set<String> add;
  final Set<String> remove;
}

class MoveOp extends PendingOp {
  const MoveOp({
    required super.id,
    required super.accountId,
    required super.createdAt,
    required this.fromFolder,
    required this.toFolder,
    required this.uidValidity,
    required this.messageIdHashes,
    required this.uids,
    this.cause = 'manual',
  });
  final String fromFolder;
  final String toFolder;
  final int uidValidity;
  final List<String> messageIdHashes;
  final List<int> uids;

  /// manual | auto | undo | correction
  final String cause;
}

class DeleteOp extends PendingOp {
  const DeleteOp({
    required super.id,
    required super.accountId,
    required super.createdAt,
    required this.folderPath,
    required this.uidValidity,
    required this.messageIdHashes,
    required this.uids,
    this.permanent = false,
    this.messageIds = const [],
  });
  final String folderPath;
  final int uidValidity;
  final List<String> messageIdHashes;
  final List<int> uids;
  final bool permanent;

  /// Raw Message-IDs resolved on the server at execution time, for messages
  /// that may not be in the local cache (e.g. a just-autosaved draft).
  final List<String> messageIds;
}

class AppendOp extends PendingOp {
  const AppendOp({
    required super.id,
    required super.accountId,
    required super.createdAt,
    required this.folderPath,
    required this.rawMessagePath,
    this.flags = const {},
    this.supersedesMessageId,
  });
  final String folderPath;

  /// File in app support dir holding the RFC 5322 bytes.
  final String rawMessagePath;
  final Set<String> flags;

  /// Message-ID of the previous copy of the same draft, expunged from
  /// [folderPath] once this one is stored (draft autosave).
  final String? supersedesMessageId;
}

class SendOp extends PendingOp {
  const SendOp({
    required super.id,
    required super.accountId,
    required super.createdAt,
    required this.identityId,
    required this.rawMessagePath,
    required this.recipients,
    this.smtpAccepted = false,
    this.draftMessageId,
  });
  final String identityId;
  final String rawMessagePath;
  final List<String> recipients;

  /// Autosaved draft of this message, expunged from Drafts after the send.
  final String? draftMessageId;

  /// Once SMTP returned 2xx this is never retried; only the Sent APPEND is.
  final bool smtpAccepted;
}
