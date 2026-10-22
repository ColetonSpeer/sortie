import 'dart:typed_data';

import 'package:enough_mail/enough_mail.dart' as em;
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/data/mail/enough/mime_mapper.dart';

void main() {
  test('cid images declared as attachments are inline parts, not attachments', () {
    final raw = [
      'From: prtg@example.test',
      'To: me@example.test',
      'Subject: [PRTG] Down',
      'MIME-Version: 1.0',
      'Content-Type: multipart/related; boundary="rel"',
      '',
      '--rel',
      'Content-Type: text/html; charset=utf-8',
      'Content-Disposition: inline',
      '',
      '<html><body><table><tr><td><img src="cid:4788"></td></tr></table></body></html>',
      '--rel',
      'Content-Type: image/png',
      'Content-Disposition: attachment',
      'Content-ID: <4788>',
      'Content-Transfer-Encoding: base64',
      '',
      'iVBORw0KGgo=',
      '--rel--',
      '',
    ].join('\r\n');
    final m = em.MimeMessage()..mimeData = em.BinaryMimeData(Uint8List.fromList(raw.codeUnits), containsHeader: true);
    m.parse();
    final body = MimeMapper.bodyFrom(m);
    expect(body.inlineParts.keys, ['4788']);
    expect(body.inlineParts['4788'], isNotEmpty);
    expect(body.attachments, isEmpty, reason: 'the picture belongs to the HTML, not the attachment strip');
  });
}
