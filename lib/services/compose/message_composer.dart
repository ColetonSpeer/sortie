import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:enough_mail/enough_mail.dart' as em;

import '../../core/clock.dart';
import '../../data/mail/enough/mime_mapper.dart';
import '../../domain/entities/entities.dart';

enum ComposeMode { newMessage, reply, replyAll, forward }

class ComposeAttachment {
  const ComposeAttachment({required this.name, required this.mimeType, required this.bytes});
  final String name;
  final String mimeType;
  final List<int> bytes;
}

/// Everything needed to build one outgoing message. [prepare] fills one from
/// an original message; the UI edits it; [compose] renders it.
class ComposeRequest {
  const ComposeRequest({
    required this.identity,
    this.mode = ComposeMode.newMessage,
    this.to = const [],
    this.cc = const [],
    this.bcc = const [],
    this.subject = '',
    this.text = '',
    this.html,
    this.quotedText = '',
    this.attachments = const [],
    this.original,
    this.includeSignature = true,
    this.inReplyTo,
    this.references = const [],
    this.calendarReply,
  });

  final Identity identity;
  final ComposeMode mode;

  /// An iTIP `METHOD:REPLY` object: sent as a `text/calendar; method=REPLY`
  /// alternative plus a `reply.ics` attachment, the shape organizers' mail
  /// servers (Exchange, Google) process automatically.
  final String? calendarReply;

  /// Addresses as typed: `Name <a@b>` or bare.
  final List<String> to;
  final List<String> cc;
  final List<String> bcc;
  final String subject;

  /// The user's own text (above the quote).
  final String text;

  /// Optional HTML for [text]; derived from [text] when null.
  final String? html;

  /// Quoted original, already prefixed with `> `; appended below signature.
  final String quotedText;
  final List<ComposeAttachment> attachments;

  /// RFC 5322 bytes of the message being replied to / forwarded.
  final List<int>? original;
  final bool includeSignature;

  /// Threading headers used when [original] bytes are not available.
  final String? inReplyTo;
  final List<String> references;

  ComposeRequest copyWith({
    Identity? identity,
    List<String>? to,
    List<String>? cc,
    List<String>? bcc,
    String? subject,
    String? text,
    String? html,
    String? quotedText,
    List<ComposeAttachment>? attachments,
    bool? includeSignature,
  }) =>
      ComposeRequest(
        identity: identity ?? this.identity,
        mode: mode,
        to: to ?? this.to,
        cc: cc ?? this.cc,
        bcc: bcc ?? this.bcc,
        subject: subject ?? this.subject,
        text: text ?? this.text,
        html: html ?? this.html,
        quotedText: quotedText ?? this.quotedText,
        attachments: attachments ?? this.attachments,
        original: original,
        includeSignature: includeSignature ?? this.includeSignature,
        inReplyTo: inReplyTo,
        references: references,
      );
}

class ComposedMessage {
  const ComposedMessage({required this.raw, required this.recipients, required this.messageId, required this.subject});

  /// RFC 5322 bytes, CRLF line endings, ready for SMTP DATA and APPEND.
  final List<int> raw;

  /// Envelope recipients (To + Cc + Bcc), de-duplicated.
  final List<String> recipients;
  final String messageId;
  final String subject;
}

/// Builds RFC 5322 messages with enough_mail's [em.MessageBuilder].
class MessageComposer {
  /// The `Message-ID` header of [raw], or null when it has none.
  static String? messageIdOf(List<int> raw) {
    final head = String.fromCharCodes(raw.length > 65536 ? raw.sublist(0, 65536) : raw);
    final m = RegExp(r'^message-id:[ \t]*(<[^>]+>)', caseSensitive: false, multiLine: true).firstMatch(head);
    return m?.group(1);
  }

  MessageComposer({Clock? clock}) : clock = clock ?? SystemClock();
  final Clock clock;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // ---------------------------------------------------------------- prepare

  /// Pre-fills recipients, subject and quote for a reply or forward.
  /// [aliases] lets the composer pick the identity the original was sent to.
  ComposeRequest prepare({
    required ComposeMode mode,
    required List<int> original,
    required Identity identity,
    List<Identity> aliases = const [],
  }) {
    final msg = em.MimeMessage.parseFromData(Uint8List.fromList(original));
    final own = {identity.email.toLowerCase(), for (final a in aliases) a.email.toLowerCase()};
    final chosen = _pickIdentity(msg, identity, aliases);
    final subject = msg.decodeSubject() ?? '';
    switch (mode) {
      case ComposeMode.newMessage:
        return ComposeRequest(identity: chosen);
      case ComposeMode.reply:
      case ComposeMode.replyAll:
        final replyTo = _addrs(msg.replyTo).isNotEmpty ? _addrs(msg.replyTo) : _addrs(msg.from);
        var to = replyTo.where((a) => !own.contains(a.email.toLowerCase())).toList();
        var cc = <em.MailAddress>[];
        if (mode == ComposeMode.replyAll) {
          to = _dedupe([...to, ..._addrs(msg.to).where((a) => !own.contains(a.email.toLowerCase()))]);
          cc = _dedupe(_addrs(msg.cc).where((a) => !own.contains(a.email.toLowerCase()) && !to.any((t) => t.email.toLowerCase() == a.email.toLowerCase())).toList());
        }
        if (to.isEmpty) to = _addrs(msg.to); // replying to our own mail
        return ComposeRequest(
          identity: chosen,
          mode: mode,
          to: to.map(_render).toList(),
          cc: cc.map(_render).toList(),
          subject: em.MessageBuilder.createReplySubject(subject),
          quotedText: quote(msg),
          original: original,
        );
      case ComposeMode.forward:
        return ComposeRequest(
          identity: chosen,
          mode: mode,
          subject: em.MessageBuilder.createForwardSubject(subject),
          quotedText: forwardBlock(msg),
          attachments: _originalAttachments(msg),
          original: original,
        );
    }
  }

  static Identity _pickIdentity(em.MimeMessage msg, Identity fallback, List<Identity> aliases) {
    if (aliases.isEmpty) return fallback;
    final recipients = {..._addrs(msg.to), ..._addrs(msg.cc)}.map((a) => a.email.toLowerCase()).toSet();
    for (final a in [fallback, ...aliases]) {
      if (recipients.contains(a.email.toLowerCase())) return a;
    }
    return fallback;
  }

  static List<em.MailAddress> _addrs(List<em.MailAddress>? l) => (l ?? const []).where((a) => a.email.isNotEmpty).toList();

  static List<em.MailAddress> _dedupe(List<em.MailAddress> l) {
    final seen = <String>{};
    return [for (final a in l) if (seen.add(a.email.toLowerCase())) a];
  }

  static String _render(em.MailAddress a) {
    final n = a.personalName?.trim();
    if (n == null || n.isEmpty) return a.email;
    final safe = n.replaceAll('"', '');
    return '"$safe" <${a.email}>';
  }

  static List<ComposeAttachment> _originalAttachments(em.MimeMessage msg) {
    final out = <ComposeAttachment>[];
    for (final info in msg.findContentInfo()) {
      final bytes = msg.getPart(info.fetchId)?.decodeContentBinary();
      if (bytes == null) continue;
      out.add(ComposeAttachment(name: info.fileName ?? 'attachment', mimeType: info.mediaType?.text ?? 'application/octet-stream', bytes: bytes));
    }
    return out;
  }

  /// `On <date>, <from> wrote:` followed by `> ` prefixed lines.
  static String quote(em.MimeMessage original) {
    final from = _addrs(original.from).firstOrNull;
    final who = from == null ? 'someone' : _render(from);
    final date = original.decodeDate();
    final header = 'On ${date == null ? 'an unknown date' : formatDate(date)}, $who wrote:';
    final text = _plainText(original);
    final lines = text.trimRight().split('\n').map((l) => l.isEmpty ? '>' : '> ${l.trimRight()}');
    return '$header\n${lines.join('\n')}';
  }

  static String forwardBlock(em.MimeMessage original) {
    final b = StringBuffer('---------- Forwarded message ----------\n');
    final from = _addrs(original.from);
    if (from.isNotEmpty) b.writeln('From: ${from.map(_render).join(', ')}');
    final date = original.decodeDate();
    if (date != null) b.writeln('Date: ${formatDate(date)}');
    b.writeln('Subject: ${original.decodeSubject() ?? ''}');
    final to = _addrs(original.to);
    if (to.isNotEmpty) b.writeln('To: ${to.map(_render).join(', ')}');
    final cc = _addrs(original.cc);
    if (cc.isNotEmpty) b.writeln('Cc: ${cc.map(_render).join(', ')}');
    b.writeln();
    b.write(_plainText(original).trimRight());
    return b.toString();
  }

  static String _plainText(em.MimeMessage m) {
    final t = m.decodeTextPlainPart();
    if (t != null && t.trim().isNotEmpty) return t.replaceAll('\r\n', '\n');
    final h = m.decodeTextHtmlPart();
    return h == null ? '' : MimeMapper.htmlToText(h);
  }

  static String formatDate(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${_days[l.weekday - 1]}, ${l.day} ${_months[l.month - 1]} ${l.year} at ${two(l.hour)}:${two(l.minute)}';
  }

  // ---------------------------------------------------------------- compose

  static final _rng = Random.secure();
  String _newMessageId(String fromEmail) {
    final domain = fromEmail.contains('@') ? fromEmail.substring(fromEmail.indexOf('@') + 1) : 'sortie.local';
    final rand = List.generate(12, (_) => _rng.nextInt(36).toRadixString(36)).join();
    return '<${clock.now().toUtc().millisecondsSinceEpoch.toRadixString(36)}.$rand@$domain>';
  }

  ComposedMessage compose(ComposeRequest r) {
    final id = r.identity;
    final b = em.MessageBuilder()
      ..from = [em.MailAddress(id.name.isEmpty ? null : id.name, id.email)]
      ..to = _parseAll(r.to)
      ..cc = _parseAll(r.cc)
      ..bcc = _parseAll(r.bcc)
      ..subject = r.subject
      ..date = clock.now();
    final replyTo = id.replyTo?.trim();
    if (replyTo != null && replyTo.isNotEmpty) b.setHeader('Reply-To', replyTo);
    b.setHeader('User-Agent', 'Sortie');
    final original = r.original;
    if (original != null && (r.mode == ComposeMode.reply || r.mode == ComposeMode.replyAll)) {
      b.originalMessage = em.MimeMessage.parseFromData(Uint8List.fromList(original));
    } else {
      final irt = r.inReplyTo?.trim();
      if (irt != null && irt.isNotEmpty) b.setHeader('In-Reply-To', irt);
      if (r.references.isNotEmpty) b.setHeader('References', r.references.join(' '));
    }

    final text = _assembleText(r);
    final html = r.html ?? _assembleHtml(r, text);
    final cal = r.calendarReply;
    if (r.attachments.isEmpty && cal == null) {
      b.setContentType(em.MediaSubtype.multipartAlternative.mediaType);
      b.addTextPlain(text, transferEncoding: em.TransferEncoding.quotedPrintable);
      b.addTextHtml(html, transferEncoding: em.TransferEncoding.quotedPrintable);
    } else {
      b.setContentType(em.MediaSubtype.multipartMixed.mediaType);
      final alt = b.addPart(mediaSubtype: em.MediaSubtype.multipartAlternative);
      alt.addTextPlain(text, transferEncoding: em.TransferEncoding.quotedPrintable);
      alt.addTextHtml(html, transferEncoding: em.TransferEncoding.quotedPrintable);
      if (cal != null) {
        final calType = em.MediaType.fromText('text/calendar');
        final part = alt.addText(cal, mediaType: calType, transferEncoding: em.TransferEncoding.quotedPrintable);
        part.setContentType(calType, characterSet: em.CharacterSet.utf8, parameters: {'method': 'REPLY'});
        final bytes = Uint8List.fromList(utf8.encode(cal));
        b.addBinary(
          bytes,
          calType,
          filename: 'reply.ics',
          disposition: em.ContentDispositionHeader.from(em.ContentDisposition.attachment, filename: 'reply.ics', size: bytes.length),
        );
      }
      for (final a in r.attachments) {
        final bytes = Uint8List.fromList(a.bytes);
        b.addBinary(
          bytes,
          em.MediaType.fromText(a.mimeType),
          filename: a.name,
          disposition: em.ContentDispositionHeader.from(em.ContentDisposition.attachment, filename: a.name, size: bytes.length),
        );
      }
    }
    // Always stamp a Message-ID: threading, the sort journal and Sent-folder
    // de-duplication all key on it, and enough_mail does not add one itself.
    b.messageId ??= _newMessageId(id.email);
    b.setHeader('Message-ID', b.messageId!);
    final mime = b.buildMimeMessage();
    final rendered = mime.renderMessage();
    final recipients = <String>[];
    final seen = <String>{};
    for (final a in [...?b.to, ...?b.cc, ...?b.bcc]) {
      if (seen.add(a.email.toLowerCase())) recipients.add(a.email);
    }
    return ComposedMessage(
      raw: utf8.encode(rendered),
      recipients: recipients,
      messageId: b.messageId ?? mime.getHeaderValue('message-id') ?? '',
      subject: r.subject,
    );
  }

  /// HTML alternative. When the identity carries an HTML signature it is
  /// spliced in for the signature block; otherwise the text is converted.
  static String _assembleHtml(ComposeRequest r, String text) {
    final sigHtml = r.identity.signatureHtml?.trim() ?? '';
    final sigText = r.identity.signature.trim();
    if (!r.includeSignature || sigHtml.isEmpty || sigText.isEmpty) return MimeMapper.textToHtml(text);
    final marker = '\n\n-- \n$sigText';
    final i = text.indexOf(marker);
    if (i < 0) return MimeMapper.textToHtml(text);
    String frag(String t) => const HtmlEscape(HtmlEscapeMode.element).convert(t).replaceAll('\n', '<br>\n');
    final after = text.substring(i + marker.length).trim();
    return '<html><body>\n<div style="font-family:sans-serif">\n${frag(text.substring(0, i))}\n'
        '<br><br><div class="sortie-signature">-- <br>\n$sigHtml</div>\n'
        '${after.isEmpty ? '' : '<br>${frag(after)}\n'}</div>\n</body></html>';
  }

  static String _assembleText(ComposeRequest r) {
    final b = StringBuffer(r.text.trimRight());
    final sig = r.identity.signature.trim();
    if (r.includeSignature && sig.isNotEmpty) {
      b.write('\n\n-- \n$sig');
    }
    if (r.quotedText.trim().isNotEmpty) {
      b.write('\n\n${r.quotedText.trimRight()}');
    }
    return '${b.toString().trimRight()}\n';
  }

  static List<em.MailAddress> _parseAll(List<String> raw) {
    final out = <em.MailAddress>[];
    for (final r in raw) {
      final t = r.trim();
      if (t.isEmpty) continue;
      try {
        out.add(em.MailAddress.parse(t));
      } catch (_) {
        if (t.contains('@')) out.add(em.MailAddress(null, t));
      }
    }
    return out;
  }
}
