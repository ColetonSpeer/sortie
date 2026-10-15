import '../../domain/entities/entities.dart';

/// Decides which new mail counts as "important" for the important-only
/// notification mode. Deterministic, header-only, no model calls.
///
/// Important: flagged mail; mail from someone the owner has written to; a
/// reply in a conversation the owner is on; mail addressed directly to one
/// of the owner's addresses by a person (small recipient list).
/// Not important: mailing lists, bulk and auto-submitted mail, automated
/// senders (no-reply, notifications, newsletters, ...), mail where the
/// owner is only in Cc or in a long recipient list, the owner's own copies.
class ImportanceJudge {
  const ImportanceJudge({required this.myAddresses, required this.correspondents, this.maxDirectRecipients = 10});

  /// Lower-cased addresses of the owner's identities.
  final Set<String> myAddresses;

  /// Lower-cased addresses the owner has sent mail to or answered.
  final Set<String> correspondents;

  /// Direct mail with more recipients than this is treated as a broadcast.
  final int maxDirectRecipients;

  static final _automatedLocalPart = RegExp(
    r'^(no[-_.]?reply|do[-_.]?not[-_.]?reply|donotreply|mailer-daemon|postmaster|bounces?|notifications?|notify|alerts?|'
    r'newsletters?|news|marketing|digest|updates?|automated|auto|robot|bot|daemon|system|orders?|receipts?)([-_.+].*)?$',
    caseSensitive: false,
  );

  /// True for the owner's own copies (sent mail that lands in INBOX).
  bool isOwn(MessageHeader h) => myAddresses.contains(h.from?.email.toLowerCase() ?? '');

  bool isImportant(MessageHeader h) {
    if (h.isFlagged) return true;
    final from = h.from?.email.toLowerCase() ?? '';
    if (from.isEmpty || isOwn(h)) return false;
    if (h.isBulk) return false;
    if (correspondents.contains(from)) return true;
    if (looksAutomated(from)) return false;
    final toMe = h.to.any((a) => myAddresses.contains(a.email.toLowerCase()));
    if (!toMe) return false;
    if (h.inReplyTo != null || h.references.isNotEmpty) return true;
    return h.to.length + h.cc.length <= maxDirectRecipients;
  }

  /// `noreply@`, `notifications@`, `news@`, `no-reply+abc@` and friends.
  static bool looksAutomated(String email) {
    final at = email.indexOf('@');
    final local = at < 0 ? email : email.substring(0, at);
    return _automatedLocalPart.hasMatch(local);
  }
}
