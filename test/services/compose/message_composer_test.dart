import 'dart:convert';

import 'package:enough_mail/enough_mail.dart' as em;
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/core/clock.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/services/compose/message_composer.dart';

void main() {
  calendarReplyTests();
  const identity = Identity(id: 'i', accountId: 'a', name: 'Coleton Speer', email: 'coleton@example.com', replyTo: 'reply@example.com', signature: 'Coleton\nExample Corp');
  final composer = MessageComposer(clock: FakeClock(DateTime.utc(2026, 9, 16, 9, 30)));

  final original = utf8.encode('From: "Bob Jones" <bob@example.org>\r\n'
      'To: "Coleton Speer" <coleton@example.com>, other@example.net\r\n'
      'Cc: carol@example.org\r\n'
      'Subject: Lunch plans\r\n'
      'Message-ID: <orig-1@example.org>\r\n'
      'Date: Tue, 15 Sep 2026 12:00:00 +0000\r\n'
      'MIME-Version: 1.0\r\n'
      'Content-Type: text/plain; charset=utf-8\r\n'
      '\r\n'
      'Are we still on for Thursday?\r\n'
      '\r\n'
      'Bob\r\n');

  test('new message: alternative text/html, identity headers, recipients', () {
    final out = composer.compose(const ComposeRequest(
      identity: identity,
      to: ['"Dana" <dana@example.org>'],
      cc: ['eve@example.org', 'dana@example.org'],
      bcc: ['hidden@example.org'],
      subject: 'Hello there',
      text: 'Hi Dana,\n\nJust a note.',
    ));
    expect(out.recipients, ['dana@example.org', 'eve@example.org', 'hidden@example.org']);
    expect(out.messageId, startsWith('<'));
    final text = utf8.decode(out.raw);
    expect(text, contains('\r\n'));
    final m = em.MimeMessage.parseFromText(text);
    expect(m.decodeSubject(), 'Hello there');
    expect(m.from!.single.email, 'coleton@example.com');
    expect(m.from!.single.personalName, 'Coleton Speer');
    expect(m.getHeaderValue('reply-to'), 'reply@example.com');
    expect(m.to!.single.email, 'dana@example.org');
    expect(m.cc!.map((a) => a.email), ['eve@example.org', 'dana@example.org']);
    expect(m.mediaType.sub, em.MediaSubtype.multipartAlternative);
    final plain = m.decodeTextPlainPart()!.replaceAll('\r\n', '\n');
    expect(plain, contains('Just a note.'));
    expect(plain, contains('-- \nColeton\nExample Corp'));
    final html = m.decodeTextHtmlPart()!;
    expect(html, contains('Just a note.'));
    expect(html, contains('<br>'));
    expect(m.getHeaderValue('date'), contains('2026'));
  });

  test('reply quotes the original and threads it', () {
    final draft = composer.prepare(mode: ComposeMode.reply, original: original, identity: identity);
    expect(draft.to, ['"Bob Jones" <bob@example.org>']);
    expect(draft.cc, isEmpty);
    expect(draft.subject, 'Re: Lunch plans');
    expect(draft.quotedText, startsWith('On '));
    expect(draft.quotedText, contains('"Bob Jones" <bob@example.org> wrote:'));
    expect(draft.quotedText, contains('> Are we still on for Thursday?'));
    expect(draft.quotedText, contains('> Bob'));

    final out = composer.compose(draft.copyWith(text: 'Yes, see you then.'));
    final m = em.MimeMessage.parseFromText(utf8.decode(out.raw));
    expect(m.getHeaderValue('in-reply-to'), '<orig-1@example.org>');
    expect(m.getHeaderValue('references'), '<orig-1@example.org>');
    final plain = m.decodeTextPlainPart()!;
    expect(plain.indexOf('Yes, see you then.'), lessThan(plain.indexOf('> Are we still on')));
    expect(plain, contains('> Are we still on for Thursday?'));
    expect(out.recipients, ['bob@example.org']);
  });

  test('reply-all keeps other recipients but drops our own identities', () {
    const alias = Identity(id: 'i2', accountId: 'a', name: 'C', email: 'other@example.net');
    final draft = composer.prepare(mode: ComposeMode.replyAll, original: original, identity: identity, aliases: const [alias]);
    expect(draft.to, ['"Bob Jones" <bob@example.org>']);
    expect(draft.cc, ['carol@example.org']);
    expect(draft.identity.email, 'coleton@example.com', reason: 'picked from the To header');
  });

  test('forward carries the original block and attachments', () {
    final withAttachment = composer.compose(ComposeRequest(
      identity: identity,
      to: const ['bob@example.org'],
      subject: 'Report',
      text: 'See attached.',
      attachments: [ComposeAttachment(name: 'report.csv', mimeType: 'text/csv', bytes: utf8.encode('a,b\n1,2\n'))],
    ));
    final parsed = em.MimeMessage.parseFromText(utf8.decode(withAttachment.raw));
    expect(parsed.mediaType.sub, em.MediaSubtype.multipartMixed);
    expect(parsed.decodeTextPlainPart(), contains('See attached.'));
    expect(parsed.decodeTextHtmlPart(), contains('See attached.'));
    final infos = parsed.findContentInfo();
    expect(infos.single.fileName, 'report.csv');
    expect(utf8.decode(parsed.getPart(infos.single.fetchId)!.decodeContentBinary()!), 'a,b\n1,2\n');

    final fwd = composer.prepare(mode: ComposeMode.forward, original: withAttachment.raw, identity: identity);
    expect(fwd.subject, 'Fwd: Report');
    expect(fwd.to, isEmpty);
    expect(fwd.quotedText, contains('---------- Forwarded message ----------'));
    expect(fwd.quotedText, contains('From: "Coleton Speer" <coleton@example.com>'));
    expect(fwd.quotedText, contains('See attached.'));
    expect(fwd.attachments.single.name, 'report.csv');
    final out = composer.compose(fwd.copyWith(to: ['dana@example.org'], text: 'FYI'));
    final m = em.MimeMessage.parseFromText(utf8.decode(out.raw));
    expect(m.getHeaderValue('in-reply-to'), isNull);
    expect(m.findContentInfo().single.fileName, 'report.csv');
    expect(m.decodeTextPlainPart(), contains('FYI'));
  });
}

// Meeting replies: the iTIP object travels as a text/calendar alternative
// with method=REPLY plus a reply.ics attachment.
void calendarReplyTests() => test('calendar reply: text/calendar;method=REPLY alternative plus reply.ics attachment', () {
  final composer = MessageComposer(clock: FakeClock(DateTime.utc(2026, 10, 20, 12)));
  const id = Identity(id: 'i', accountId: 'a', name: 'Me', email: 'me@hky.test', isDefault: true);
  const ics = 'BEGIN:VCALENDAR\r\nMETHOD:REPLY\r\nBEGIN:VEVENT\r\nUID:u1\r\nATTENDEE;PARTSTAT=ACCEPTED:mailto:me@hky.test\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n';
  final out = composer.compose(const ComposeRequest(identity: id, to: ['org@hky.test'], subject: 'Accepted: x', text: 'ok', includeSignature: false, calendarReply: ics));
  final mime = em.MimeMessage.parseFromText(utf8.decode(out.raw));
  expect(mime.mediaType.sub, em.MediaSubtype.multipartMixed);
  final parts = mime.allPartsFlat;
  final calParts = parts.where((p) => p.mediaType.sub == em.MediaSubtype.textCalendar).toList();
  expect(calParts.length, 2, reason: 'alternative part and attachment');
  final alternative = calParts.firstWhere((p) => p.decodeFileName() == null);
  expect(alternative.getHeaderValue('content-type')!.toLowerCase(), contains('method=reply'));
  expect(alternative.decodeContentText(), contains('PARTSTAT=ACCEPTED'));
  final attachment = calParts.firstWhere((p) => p.decodeFileName() != null);
  expect(attachment.decodeFileName(), 'reply.ics');
});
