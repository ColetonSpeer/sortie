import '../domain/entities/entities.dart';

/// Everything the composer needs to build an RFC 5322 message.
class ComposeAttachment {
  const ComposeAttachment({required this.fileName, required this.mimeType, required this.bytes});
  final String fileName;
  final String mimeType;
  final List<int> bytes;
  int get size => bytes.length;
}

class ComposeDraft {
  const ComposeDraft({
    required this.accountId,
    required this.identity,
    required this.to,
    this.cc = const [],
    this.bcc = const [],
    required this.subject,
    required this.bodyText,
    this.inReplyTo,
    this.references = const [],
    this.attachments = const [],
    this.draftUid,
  });

  final String accountId;
  final Identity identity;
  final List<MailAddress> to;
  final List<MailAddress> cc;
  final List<MailAddress> bcc;
  final String subject;
  final String bodyText;
  final String? inReplyTo;
  final List<String> references;
  final List<ComposeAttachment> attachments;

  /// UID in the Drafts folder when editing an existing draft.
  final int? draftUid;

  List<String> get allRecipients => [...to, ...cc, ...bcc].map((a) => a.email).toList();
}
