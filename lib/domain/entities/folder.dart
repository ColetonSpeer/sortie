enum SpecialUse { inbox, sent, drafts, trash, junk, archive, all, flagged, none }

class Folder {
  const Folder({
    required this.accountId,
    required this.path,
    required this.name,
    required this.delimiter,
    this.specialUse = SpecialUse.none,
    this.uidValidity,
    this.uidNext,
    this.highestModSeq,
    this.messageCount = 0,
    this.unseenCount = 0,
    this.subscribed = true,
    this.selectable = true,
  });

  final String accountId;

  /// Full IMAP path, e.g. `Work/Invoices` or `INBOX.Work.Invoices`.
  final String path;
  final String name;
  final String delimiter;
  final SpecialUse specialUse;
  final int? uidValidity;
  final int? uidNext;
  final int? highestModSeq;
  final int messageCount;
  final int unseenCount;
  final bool subscribed;
  final bool selectable;

  bool get isInbox => specialUse == SpecialUse.inbox || path.toUpperCase() == 'INBOX';

  /// Sortie's hidden control folder is never shown or sorted into.
  static const controlFolderName = 'Sortie';
  bool get isControlFolder =>
      name == controlFolderName && (path == controlFolderName || path.endsWith('$delimiter$controlFolderName'));

  Folder copyWith({
    int? uidValidity,
    int? uidNext,
    int? highestModSeq,
    int? messageCount,
    int? unseenCount,
    SpecialUse? specialUse,
  }) =>
      Folder(
        accountId: accountId,
        path: path,
        name: name,
        delimiter: delimiter,
        specialUse: specialUse ?? this.specialUse,
        uidValidity: uidValidity ?? this.uidValidity,
        uidNext: uidNext ?? this.uidNext,
        highestModSeq: highestModSeq ?? this.highestModSeq,
        messageCount: messageCount ?? this.messageCount,
        unseenCount: unseenCount ?? this.unseenCount,
        subscribed: subscribed,
        selectable: selectable,
      );
}
