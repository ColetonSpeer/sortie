import 'package:sortie/core/hashing.dart';
import 'package:sortie/domain/entities/entities.dart';

/// Synthetic mailbox for sorter tests. Nothing here is real mail.
abstract final class Corpus {
  static const account = 'acc-1';
  static final today = DateTime.utc(2026, 9, 16, 9);

  static const inbox = 'INBOX';
  static const invoices = 'Work/Invoices';
  static const newsletters = 'Newsletters';
  static const family = 'Family';
  static const receipts = 'Receipts';
  static const apollo = 'Projects/Apollo';
  static const oldArchive = 'Old/Archive2019';
  static const sent = 'Sent';
  static const trash = 'Trash';
  static const junk = 'Junk';

  /// (path, name, specialUse, messageCount)
  static const folders = [
    (inbox, 'INBOX', 'inbox', 40),
    (sent, 'Sent', 'sent', 50),
    (trash, 'Trash', 'trash', 10),
    (junk, 'Junk', 'junk', 3),
    (invoices, 'Invoices', 'none', 9),
    (newsletters, 'Newsletters', 'none', 8),
    (family, 'Family', 'none', 6),
    (receipts, 'Receipts', 'none', 7),
    (apollo, 'Apollo', 'none', 2),
    (oldArchive, 'Archive2019', 'none', 3),
    ('Sortie', 'Sortie', 'none', 0),
  ];

  static int _uid = 1000;

  static MessageHeader msg({
    required String folder,
    required String from,
    required String subject,
    String? fromName,
    DateTime? date,
    int daysAgo = 3,
    String? listId,
    String? precedence,
    String? autoSubmitted,
    bool listUnsubscribe = false,
    List<String> to = const ['me@example.com'],
    List<String> cc = const [],
    Set<String> flags = const {},
    String snippet = '',
    List<AttachmentInfo> attachments = const [],
    String? messageId,
  }) {
    final d = date ?? today.subtract(Duration(days: daysAgo, hours: _uid % 7));
    final mid = messageId ?? '<$_uid.${from.hashCode.toRadixString(16)}@synthetic.test>';
    return MessageHeader(
      accountId: account,
      folderPath: folder,
      uid: _uid++,
      uidValidity: 1,
      messageIdHash: messageIdHash(messageId: mid),
      messageId: mid,
      subject: subject,
      from: MailAddress(from, fromName),
      to: to.map(MailAddress.new).toList(),
      cc: cc.map(MailAddress.new).toList(),
      date: d,
      listId: listId,
      precedence: precedence,
      autoSubmitted: autoSubmitted,
      hasListUnsubscribe: listUnsubscribe,
      flags: flags,
      snippet: snippet,
      attachments: attachments,
    );
  }

  /// Historical, user-filed mail used for bootstrap and learned stats.
  static List<MessageHeader> history() => [
        for (var i = 0; i < 6; i++)
          msg(folder: invoices, from: 'billing@acme.com', fromName: 'Acme Billing', subject: 'Invoice #48${20 + i} from Acme', daysAgo: 10 + i * 9),
        for (var i = 0; i < 3; i++)
          msg(folder: invoices, from: 'invoices@aws.amazon.com', subject: 'Your AWS receipt for ${['June', 'July', 'August'][i]}', daysAgo: 20 + i * 30),
        for (var i = 0; i < 5; i++)
          msg(folder: newsletters, from: 'news@example.com', subject: 'Weekly digest #${100 + i}', listId: 'news.example.com', listUnsubscribe: true, daysAgo: 5 + i * 7),
        for (var i = 0; i < 3; i++)
          msg(folder: newsletters, from: 'hello@substack.example', subject: 'Issue ${30 + i}: on writing', listId: 'weekly.substack.example', daysAgo: 8 + i * 7),
        for (var i = 0; i < 4; i++) msg(folder: family, from: 'mom@gmail.com', fromName: 'Mom', subject: ['Sunday dinner?', 'Photos from the lake', 'Re: Sunday dinner?', 'Your dad says hi'][i], daysAgo: 4 + i * 15),
        for (var i = 0; i < 2; i++) msg(folder: family, from: 'uncle.bob@yahoo.com', subject: 'Fishing trip ${i + 1}', daysAgo: 30 + i * 40),
        for (var i = 0; i < 3; i++) msg(folder: receipts, from: 'receipts@shop.example', subject: 'Your order #${7000 + i} has shipped', daysAgo: 6 + i * 12),
        for (var i = 0; i < 4; i++) msg(folder: receipts, from: 'orders@amazon.example', subject: 'Order confirmation #${1000 + i}', daysAgo: 3 + i * 10),
        for (var i = 0; i < 2; i++) msg(folder: apollo, from: 'pm@apollo.example', subject: 'Apollo standup notes ${i + 1}', daysAgo: 2 + i),
        for (var i = 0; i < 3; i++)
          msg(folder: oldArchive, from: 'archive@old.example', subject: 'Quarterly report Q${i + 1} 2019', date: DateTime.utc(2019, 3 + i * 3, 1)),
      ];

  /// New INBOX arrivals with the folder a human would pick (null = stays).
  static List<(MessageHeader, String?)> arrivals() => [
        (msg(folder: inbox, from: 'billing@acme.com', fromName: 'Acme Billing', subject: 'Invoice #4890 from Acme', daysAgo: 0), invoices),
        (msg(folder: inbox, from: 'news@example.com', subject: 'Weekly digest #106', listId: 'news.example.com', listUnsubscribe: true, daysAgo: 0), newsletters),
        (msg(folder: inbox, from: 'orders@amazon.example', subject: 'Order confirmation #1009', daysAgo: 0), receipts),
        (msg(folder: inbox, from: 'mom@gmail.com', fromName: 'Mom', subject: 'Thanksgiving plans', daysAgo: 0), family),
        (msg(folder: inbox, from: 'stranger@random.example', subject: 'Quick question about your talk', daysAgo: 0), null),
        (msg(folder: inbox, from: 'pm@apollo.example', subject: 'Apollo standup notes 3', daysAgo: 0), apollo),
        (msg(folder: inbox, from: 'promo@deals.example', subject: 'FLASH SALE 50% off', listId: 'deals.example', precedence: 'bulk', daysAgo: 0), null),
        (msg(folder: inbox, from: 'noreply@bank.example', subject: 'Your verification code is 482913', daysAgo: 0), null),
        (msg(folder: inbox, from: 'friend@outlook.com', subject: 'Re: lunch tomorrow', daysAgo: 0), null),
        (msg(folder: inbox, from: 'invoices@aws.amazon.com', subject: 'Your AWS receipt for September', daysAgo: 0), invoices),
      ];

  static const htmlBody = '''
<html><head><style>.x{color:red}</style><title>Hi</title></head>
<body><div>Hi there,</div><p>Your invoice <b>#4890</b> is attached. Pay at <a href="https://pay.acme.com/inv/4890?token=abc123">the portal</a>.</p>
<img src="https://track.example/pixel.gif" width="1" height="1">
<script>alert(1)</script>
<blockquote>On Tue, Sep 15, 2026, Someone wrote:<br>old stuff</blockquote>
<div>-- <br>Acme Billing Team</div></body></html>''';

  static const quotedReplyBody = '''
Thanks, that works for me.

Let's meet at 10.

On Mon, Sep 14, 2026 at 9:02 AM Alice <alice@example.com> wrote:
> Does Tuesday work?
> I could also do Wednesday.
>
> -- 
> Alice
''';
}
