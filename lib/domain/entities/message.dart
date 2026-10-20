/// IMAP keywords Sortie writes on user mail. Never add per-folder or
/// per-device keywords: servers cap the number of distinct keywords.
abstract final class SortieKeywords {
  /// A sort decision exists but has not been executed.
  static const pending = r'$SortiePending';

  /// Sortie already acted on this message; never auto-sort it again.
  static const done = r'$SortieDone';
}

class MailAddress {
  const MailAddress(this.email, [this.name]);
  final String email;
  final String? name;

  String get domain => email.contains('@') ? email.substring(email.indexOf('@') + 1).toLowerCase() : '';

  @override
  String toString() => name == null || name!.isEmpty ? email : '"$name" <$email>';
}

/// Identifies one message across UID changes and devices.
class MessageKey {
  const MessageKey({required this.accountId, required this.messageIdHash, this.uid, this.uidValidity});
  final String accountId;

  /// sha256 of Message-ID, or of `from|date|subject` when absent.
  final String messageIdHash;
  final int? uid;
  final int? uidValidity;

  @override
  bool operator ==(Object other) =>
      other is MessageKey && other.accountId == accountId && other.messageIdHash == messageIdHash;
  @override
  int get hashCode => Object.hash(accountId, messageIdHash);
  @override
  String toString() => '$accountId:${messageIdHash.substring(0, 8)}${uid != null ? '#$uid' : ''}';
}

class AttachmentInfo {
  const AttachmentInfo({required this.partId, required this.fileName, required this.mimeType, required this.size});
  final String partId;
  final String fileName;
  final String mimeType;
  final int size;
}

class MessageHeader {
  const MessageHeader({
    required this.accountId,
    required this.folderPath,
    required this.uid,
    required this.uidValidity,
    required this.messageIdHash,
    required this.subject,
    required this.from,
    required this.date,
    this.messageId,
    this.to = const [],
    this.cc = const [],
    this.replyTo,
    this.listId,
    this.inReplyTo,
    this.references = const [],
    this.precedence,
    this.autoSubmitted,
    this.hasListUnsubscribe = false,
    this.flags = const {},
    this.size = 0,
    this.snippet = '',
    this.attachments = const [],
    this.internalDate,
  });

  final String accountId;
  final String folderPath;
  final int uid;
  final int uidValidity;
  final String messageIdHash;
  final String? messageId;
  final String subject;
  final MailAddress? from;
  final List<MailAddress> to;
  final List<MailAddress> cc;
  final MailAddress? replyTo;
  final DateTime date;
  final DateTime? internalDate;
  final String? listId;
  final String? inReplyTo;
  final List<String> references;
  final String? precedence;
  final String? autoSubmitted;
  final bool hasListUnsubscribe;

  /// System flags (`\Seen`) and keywords (`$SortiePending`).
  final Set<String> flags;
  final int size;
  final String snippet;
  final List<AttachmentInfo> attachments;

  bool get isSeen => flags.contains(r'\Seen');
  bool get isFlagged => flags.contains(r'\Flagged');
  bool get isAnswered => flags.contains(r'\Answered');
  bool get hasSortiePending => flags.contains(SortieKeywords.pending);
  bool get hasSortieDone => flags.contains(SortieKeywords.done);
  bool get hasAttachments => attachments.isNotEmpty;

  /// Mailing-list / automated mail heuristics used by the sorter's read policy.
  bool get isBulk =>
      listId != null ||
      hasListUnsubscribe ||
      (precedence != null && RegExp(r'bulk|list|junk', caseSensitive: false).hasMatch(precedence!)) ||
      (autoSubmitted != null && autoSubmitted!.toLowerCase() != 'no');

  MessageKey get key =>
      MessageKey(accountId: accountId, messageIdHash: messageIdHash, uid: uid, uidValidity: uidValidity);

  MessageHeader copyWith({Set<String>? flags, String? folderPath, int? uid, int? uidValidity, String? snippet, DateTime? internalDate}) =>
      MessageHeader(
        accountId: accountId,
        folderPath: folderPath ?? this.folderPath,
        uid: uid ?? this.uid,
        uidValidity: uidValidity ?? this.uidValidity,
        messageIdHash: messageIdHash,
        messageId: messageId,
        subject: subject,
        from: from,
        to: to,
        cc: cc,
        replyTo: replyTo,
        date: date,
        internalDate: internalDate ?? this.internalDate,
        listId: listId,
        inReplyTo: inReplyTo,
        references: references,
        precedence: precedence,
        autoSubmitted: autoSubmitted,
        hasListUnsubscribe: hasListUnsubscribe,
        flags: flags ?? this.flags,
        size: size,
        snippet: snippet ?? this.snippet,
        attachments: attachments,
      );
}

class MessageBody {
  const MessageBody({required this.text, this.html, this.inlineParts = const {}, this.attachments = const [], this.calendar});

  /// Plain text (decoded, or derived from HTML when the mail has none).
  final String text;
  final String? html;

  /// The `text/calendar` part (meeting invitation, update, cancellation or
  /// reply) when the mail carries one.
  final String? calendar;

  /// cid: -> bytes for inline images.
  final Map<String, List<int>> inlineParts;
  final List<AttachmentInfo> attachments;
}
