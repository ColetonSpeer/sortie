import '../../core/hashing.dart';
import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';

/// Obviously fake seed data for `--dart-define=SORTIE_DEMO=true`.
abstract final class DemoData {
  static const accountId = 'demo-account';
  static const deviceId = 'demo-device-0000-0000-000000000000';

  static const account = Account(
    id: accountId,
    displayName: 'Demo Mailbox (fake)',
    email: 'demo@example.invalid',
    username: 'demo@example.invalid',
    imap: ImapEndpoint(host: 'imap.example.invalid', port: 993, security: ConnectionSecurity.tls),
    smtp: SmtpEndpoint(host: 'smtp.example.invalid', port: 587, security: ConnectionSecurity.starttls),
  );

  static const identities = [
    Identity(id: 'id-main', accountId: accountId, name: 'Demo User', email: 'demo@example.invalid', isDefault: true, signature: '-- \nDemo User (this is fake data)'),
    Identity(id: 'id-alias', accountId: accountId, name: 'Demo Alias', email: 'alias@example.invalid'),
  ];

  static Folder _f(String path, String name, {SpecialUse use = SpecialUse.none, int unseen = 0, int count = 0}) =>
      Folder(accountId: accountId, path: path, name: name, delimiter: '/', specialUse: use, unseenCount: unseen, messageCount: count);

  static final folders = [
    _f('INBOX', 'INBOX', use: SpecialUse.inbox, unseen: 11, count: 25),
    _f('Sent', 'Sent', use: SpecialUse.sent, count: 4),
    _f('Drafts', 'Drafts', use: SpecialUse.drafts, count: 1),
    _f('Trash', 'Trash', use: SpecialUse.trash),
    _f('Junk', 'Junk', use: SpecialUse.junk, unseen: 2),
    _f('Archive', 'Archive', use: SpecialUse.archive, count: 2),
    _f('Work', 'Work', count: 1),
    _f('Work/Invoices', 'Invoices', count: 3, unseen: 1),
    _f('Work/Projects', 'Projects', count: 1),
    _f('Newsletters', 'Newsletters', count: 2),
    _f('Family', 'Family', count: 1),
    _f('Sortie', 'Sortie'), // hidden control folder
  ];

  static const _senders = [
    ('Acme Billing (fake)', 'billing@acme.example.invalid'),
    ('Pat Example', 'pat@example.invalid'),
    ('Weekly Digest', 'digest@newsletter.example.invalid'),
    ('Mom (demo)', 'mom@family.example.invalid'),
    ('Project Bot', 'bot@projects.example.invalid'),
    ('Sam Colleague', 'sam@work.example.invalid'),
    ('Demo User', 'demo@example.invalid'),
  ];

  static const _subjects = [
    'Invoice #DEMO-1042 is ready',
    'Lunch on Thursday?',
    'Your weekly digest: 5 things (fake)',
    'Photos from the weekend',
    'Build #318 passed',
    'Re: Q3 planning notes',
    'Payment reminder — sample only',
    'Quick question about the deck',
    'Newsletter: demo edition',
    'Dinner recipe you asked for',
    'Your statement is available (fake)',
    'Parking on Friday',
    'Weekly digest: 3 more things (fake)',
    'Grandma says hi',
    'Deploy #52 finished',
    'Office plants rota',
    'Card ending 0000 — sample only',
    'Slides for Monday',
    'Newsletter: another demo edition',
    'Recipe round two',
  ];

  static String _mid(int i) => '<demo-$i@example.invalid>';

  static MessageHeader _msg(
    int i,
    String folder, {
    bool seen = true,
    bool flagged = false,
    bool attach = false,
    List<MailAddress>? to,
    int? sender,
    String? subject,
    int? hoursAgo,
    String? inReplyTo,
    List<String> references = const [],
  }) {
    final si = sender ?? i % 6;
    final s = _senders[si];
    subject ??= _subjects[i % _subjects.length];
    final date = DateTime.now().subtract(Duration(hours: hoursAgo ?? (i * 7 + (i % 3) * 2)));
    final mid = _mid(i);
    return MessageHeader(
      accountId: accountId,
      folderPath: folder,
      uid: 1000 + i,
      uidValidity: 1,
      messageIdHash: messageIdHash(messageId: mid),
      messageId: mid,
      subject: subject,
      from: MailAddress(s.$2, s.$1),
      to: to ?? const [MailAddress('demo@example.invalid', 'Demo User')],
      date: date,
      inReplyTo: inReplyTo,
      references: references,
      listId: si == 2 ? '<digest.newsletter.example.invalid>' : null,
      hasListUnsubscribe: si == 2,
      flags: {if (seen) r'\Seen', if (flagged) r'\Flagged'},
      size: 4200 + i * 311,
      snippet: 'This is fake demo text for message $i. Nothing here is real — it exists only so the UI has something to show.',
      attachments: attach
          ? const [AttachmentInfo(partId: '2', fileName: 'demo-invoice.pdf', mimeType: 'application/pdf', size: 48213)]
          : const [],
    );
  }

  static const _pat = MailAddress('pat@example.invalid', 'Pat Example');
  static const _sam = MailAddress('sam@work.example.invalid', 'Sam Colleague');
  static const _me = MailAddress('demo@example.invalid', 'Demo User');

  /// Messages 0-19 sit in the inbox; three of them are roots or replies of
  /// the conversations below (shared References so the threaded view groups
  /// them): 37 -> 5 -> 38 (planning), 39 -> 1 -> 40 (lunch, ends with a reply
  /// from the user), 4 -> [missing] -> 41 (build, intermediate not in folder).
  static final messages = <MessageHeader>[
    for (var i = 0; i < 20; i++)
      _msg(i, 'INBOX', seen: i >= 9, flagged: i == 3 || i == 11, attach: i % 5 == 0,
          to: i == 7 ? const [MailAddress('alias@example.invalid', 'Demo Alias')] : null,
          inReplyTo: i == 5 ? _mid(37) : (i == 1 ? _mid(39) : null),
          references: i == 5 ? [_mid(37)] : (i == 1 ? [_mid(39)] : const [])),
    _msg(37, 'INBOX', sender: 1, subject: 'Q3 planning notes', hoursAgo: 60, to: const [_me, _sam]),
    _msg(38, 'INBOX', sender: 5, subject: 'Re: Q3 planning notes', hoursAgo: 20, seen: false,
        to: const [_me, _pat], inReplyTo: _mid(5), references: [_mid(37), _mid(5)]),
    _msg(39, 'INBOX', sender: 5, subject: 'Lunch on Thursday?', hoursAgo: 30, to: const [_me, _pat]),
    _msg(40, 'INBOX', sender: 6, subject: 'Re: Lunch on Thursday?', hoursAgo: 5, to: const [_pat, _sam],
        inReplyTo: _mid(1), references: [_mid(39), _mid(1)]),
    _msg(41, 'INBOX', sender: 5, subject: 'Re: Build #318 passed', hoursAgo: 3, seen: false,
        inReplyTo: _mid(99), references: [_mid(4), _mid(99)]),
    for (var i = 20; i < 24; i++) _msg(i, 'Sent'),
    for (var i = 24; i < 27; i++) _msg(i, 'Work/Invoices', seen: i != 24, attach: true),
    _msg(27, 'Newsletters'),
    _msg(28, 'Newsletters'),
    _msg(29, 'Family', attach: true),
    _msg(30, 'Archive'),
    _msg(31, 'Archive'),
    _msg(32, 'Work'),
    _msg(33, 'Work/Projects'),
    _msg(34, 'Junk', seen: false),
    _msg(35, 'Junk', seen: false),
    _msg(36, 'Drafts'),
  ];

  static Map<MessageKey, PendingBadge> pendingBadges() {
    PendingBadge b(int i, String dest, double conf, SortMode mode, String reason, SortLayer layer) {
      final h = messages[i];
      return PendingBadge(key: h.key, destination: dest, confidence: conf, reason: reason, mode: mode, decisionId: 'dec-$i', layer: layer);
    }

    return {
      messages[0].key: b(0, 'Work/Invoices', 0.91, SortMode.moveAfterRead, 'Sender acme billing always files to Invoices; subject mentions an invoice number.', SortLayer.learned),
      messages[2].key: b(2, 'Newsletters', 0.97, SortMode.moveNow, 'List-Id matches the Weekly Digest newsletter.', SortLayer.rule),
      messages[5].key: b(5, 'Work/Projects', 0.62, SortMode.suggestOnly, 'Reply in a planning thread from a work colleague.', SortLayer.model),
      messages[9].key: b(9, 'Family', 0.71, SortMode.suggestOnly, 'Personal recipe from a family contact.', SortLayer.model),
    };
  }

  static List<SortLogEntry> sortLog() {
    final now = DateTime.now();
    SortLogEntry e(int i, String type, String from, String to, {double? conf, String? reason, bool undoable = false, String device = deviceId, int hoursAgo = 1}) {
      final h = messages[i];
      return SortLogEntry(
        id: 'log-$type-$i',
        at: now.subtract(Duration(hours: hoursAgo)),
        type: type,
        key: h.key,
        subject: h.subject,
        from: h.from.toString(),
        fromFolder: from,
        toFolder: to,
        reason: reason,
        confidence: conf,
        deviceId: device,
        cause: type == 'moved' ? 'auto' : null,
        undoable: undoable,
        decisionId: 'dec-$i',
      );
    }

    return [
      e(24, 'moved', 'INBOX', 'Work/Invoices', conf: 0.93, reason: 'Invoice from a known billing sender.', undoable: true, hoursAgo: 2),
      e(27, 'moved', 'INBOX', 'Newsletters', conf: 0.98, reason: 'List-Id newsletter rule.', undoable: true, device: 'other-phone-1111', hoursAgo: 5),
      e(0, 'decision', 'INBOX', 'Work/Invoices', conf: 0.91, reason: 'Waiting until read (leave-until-read is on).', hoursAgo: 6),
      e(30, 'undo', 'Archive', 'INBOX', hoursAgo: 26),
      e(33, 'correction', 'Work', 'Work/Projects', reason: 'You moved it manually.', hoursAgo: 30),
      e(28, 'moved', 'INBOX', 'Newsletters', conf: 0.96, reason: 'List-Id newsletter rule.', device: 'other-phone-1111', hoursAgo: 50),
    ];
  }

  static List<SeenDevice> devices() {
    final now = DateTime.now();
    return [
      SeenDevice(deviceId: deviceId, displayName: 'This laptop (demo)', platform: 'linux', priority: 30, lastSeen: now, isLeader: true, isThisDevice: true),
      SeenDevice(deviceId: 'other-phone-1111', displayName: 'Demo Phone', platform: 'android', priority: 15, lastSeen: now.subtract(const Duration(minutes: 3)), isLeader: false, isThisDevice: false),
      SeenDevice(deviceId: 'other-desk-2222', displayName: 'Demo Desktop', platform: 'windows', priority: 30, lastSeen: now.subtract(const Duration(days: 2)), isLeader: false, isThisDevice: false),
    ];
  }

  static const sortConfig = SortConfig(mode: SortingMode.auto, folderDescriptions: {'Work/Invoices': 'Bills and invoices from vendors'});
}
