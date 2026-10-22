import 'dart:io';
import 'dart:typed_data';

import 'package:enough_mail/enough_mail.dart' as em;
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/data/mail/enough/mime_mapper.dart';
import 'package:sortie/services/calendar/invitations.dart';
import 'package:sortie/services/calendar/tz.dart';

void main() {
  setUpAll(ensureTimeZonesLoaded);

  test('an Outlook meeting request (multipart/alternative with text/calendar, Windows zone names) is understood', () {
    final raw = File('test/fixtures/outlook_meeting_request.eml').readAsBytesSync();
    expect(String.fromCharCodes(raw), contains('\r\n'), reason: 'IMAP delivers CRLF; enough_mail needs it');
    // The gateway path: fetched bytes become mimeData, then parse().
    final fetched = em.MimeMessage()..mimeData = em.BinaryMimeData(Uint8List.fromList(raw), containsHeader: true);
    fetched.parse();
    final body = MimeMapper.bodyFrom(fetched);
    expect(body.calendar, isNotNull);
    expect(body.calendarKnown, isTrue);
    expect(body.attachments, isEmpty, reason: 'the calendar part is an alternative, not an attachment');
    final inv = MeetingInvitation.parse(body.calendar!)!;
    expect(inv.method, InvitationMethod.request);
    expect(inv.event.summary, 'Hickory API discussion');
    expect(inv.event.tzid, 'Central Standard Time');
    // 13:00 Central on 2026-10-23 is 18:00Z (2:00 PM Eastern).
    expect(inv.event.start, DateTime.utc(2026, 10, 23, 18));
    expect(inv.event.end, DateTime.utc(2026, 10, 23, 18, 30));
  });
}
