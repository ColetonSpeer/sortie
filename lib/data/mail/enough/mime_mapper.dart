import 'dart:convert';

import 'package:enough_mail/enough_mail.dart' as em;

import '../../../core/hashing.dart';
import '../../../domain/entities/entities.dart';

/// Pure functions translating enough_mail structures into domain entities.
abstract final class MimeMapper {
  /// Header fields requested with `BODY.PEEK[HEADER.FIELDS (...)]` for
  /// list views. Envelope covers From/To/Subject/Date/Message-ID.
  static const headerFields = [
    'List-Id',
    'Precedence',
    'Auto-Submitted',
    'List-Unsubscribe',
    'In-Reply-To',
    'References',
    'Message-ID',
    'Reply-To',
  ];

  static String headerFieldsClause([List<String> fields = headerFields]) => 'BODY.PEEK[HEADER.FIELDS (${fields.join(' ')})]';

  static const snippetLength = 160;

  static MailAddress? address(em.MailAddress? a) {
    if (a == null || a.email.isEmpty) return null;
    final name = a.personalName?.trim();
    return MailAddress(a.email.trim(), name == null || name.isEmpty ? null : name);
  }

  static List<MailAddress> addresses(List<em.MailAddress>? list) =>
      (list ?? const []).map(address).whereType<MailAddress>().toList();

  static DateTime? internalDate(em.MimeMessage m) {
    final raw = m.internalDate;
    if (raw == null) return null;
    return em.DateCodec.decodeDate(raw)?.toUtc();
  }

  static Set<String> flags(em.MimeMessage m) => (m.flags ?? const []).toSet();

  static String? header(em.MimeMessage m, String name) {
    final v = m.getHeaderValue(name);
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  static String? messageId(em.MimeMessage m) => header(m, 'message-id') ?? m.envelope?.messageId?.trim();

  static List<String> references(String? raw) {
    if (raw == null) return const [];
    return RegExp(r'<[^>]+>').allMatches(raw).map((x) => x.group(0)!).toList();
  }

  static String? listId(String? raw) {
    if (raw == null) return null;
    final m = RegExp(r'<([^>]+)>').firstMatch(raw);
    return (m?.group(1) ?? raw).trim();
  }

  static List<AttachmentInfo> attachments(em.MimeMessage m) {
    final out = <AttachmentInfo>[];
    final seen = <String>{};
    for (final info in m.findContentInfo()) {
      if (!seen.add(info.fetchId)) continue;
      out.add(AttachmentInfo(
        partId: info.fetchId,
        fileName: info.fileName ?? 'attachment-${info.fetchId}',
        mimeType: info.mediaType?.text ?? 'application/octet-stream',
        size: info.size ?? 0,
      ));
    }
    return out;
  }

  static String snippet(String? text) {
    if (text == null) return '';
    final collapsed = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return collapsed.length <= snippetLength ? collapsed : collapsed.substring(0, snippetLength);
  }

  /// Builds a [MessageHeader] from a message fetched with FLAGS, ENVELOPE,
  /// BODYSTRUCTURE, RFC822.SIZE, INTERNALDATE and the header fields above.
  static MessageHeader headerFrom(
    em.MimeMessage m, {
    required String accountId,
    required String folderPath,
    required int uidValidity,
    DateTime? fallbackDate,
  }) {
    final uid = m.uid;
    if (uid == null) throw ArgumentError('message without UID');
    final env = m.envelope;
    final from = address(m.from?.firstOrNull) ?? address(env?.from?.firstOrNull);
    final subject = m.decodeSubject() ?? env?.subject ?? '';
    final idate = internalDate(m);
    final date = m.decodeDate() ?? env?.date ?? idate ?? fallbackDate ?? DateTime.now().toUtc();
    final mid = messageId(m);
    final refs = references(header(m, 'references'));
    final replyTo = address(m.replyTo?.firstOrNull) ?? address(env?.replyTo?.firstOrNull);
    return MessageHeader(
      accountId: accountId,
      folderPath: folderPath,
      uid: uid,
      uidValidity: uidValidity,
      messageIdHash: messageIdHash(messageId: mid, from: from?.email, date: date, subject: subject),
      messageId: mid,
      subject: subject,
      from: from,
      to: addresses(m.to ?? env?.to),
      cc: addresses(m.cc ?? env?.cc),
      replyTo: replyTo,
      date: date,
      internalDate: idate,
      listId: listId(header(m, 'list-id')),
      inReplyTo: header(m, 'in-reply-to') ?? env?.inReplyTo,
      references: refs,
      precedence: header(m, 'precedence'),
      autoSubmitted: header(m, 'auto-submitted'),
      hasListUnsubscribe: header(m, 'list-unsubscribe') != null,
      flags: flags(m),
      size: m.size ?? 0,
      attachments: attachments(m),
    );
  }

  /// Body from a fully downloaded message (`BODY.PEEK[]`).
  static MessageBody bodyFrom(em.MimeMessage m) {
    var text = m.decodeTextPlainPart();
    final html = m.decodeTextHtmlPart();
    if ((text == null || text.trim().isEmpty) && html != null) text = htmlToText(html);
    final inline = <String, List<int>>{};
    for (final info in m.findContentInfo(disposition: em.ContentDisposition.inline)) {
      final cid = info.cid?.replaceAll(RegExp(r'^<|>$'), '');
      if (cid == null || cid.isEmpty || info.isText) continue;
      final bytes = m.getPart(info.fetchId)?.decodeContentBinary();
      if (bytes != null) inline[cid] = bytes;
    }
    return MessageBody(text: text ?? '', html: html, inlineParts: inline, attachments: attachments(m));
  }

  /// Raw header map (lower-cased name -> first value) from a header-only fetch.
  static Map<String, String> rawHeaders(em.MimeMessage m) {
    final out = <String, String>{};
    for (final h in m.headers ?? const <em.Header>[]) {
      final v = h.value;
      if (v == null) continue;
      out.putIfAbsent(h.lowerCaseName, () => em.MailCodec.decodeHeader(v) ?? v);
    }
    return out;
  }

  /// Cheap HTML to text conversion for snippets and search indexing.
  static String htmlToText(String html) {
    var s = html.replaceAll(RegExp(r'<(script|style)[^>]*>.*?</\1>', caseSensitive: false, dotAll: true), ' ');
    s = s.replaceAll(RegExp(r'<br\s*/?>|</p>|</div>|</tr>|</li>|</h[1-6]>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    s = s
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m.group(1)!)));
    return s.replaceAll(RegExp(r'[ \t]+'), ' ').replaceAll(RegExp(r'\n\s*\n+'), '\n\n').trim();
  }

  /// Simple text -> HTML alternative used by the composer.
  static String textToHtml(String text) {
    final esc = const HtmlEscape(HtmlEscapeMode.element).convert(text);
    return '<html><body>\n<div style="font-family:sans-serif">\n${esc.replaceAll('\n', '<br>\n')}\n</div>\n</body></html>';
  }
}
