import 'package:enough_mail/enough_mail.dart' as em;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/app/providers.dart';
import 'package:sortie/core/clock.dart';
import 'package:sortie/data/mail/enough/mime_mapper.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/features/message_view/message_screen.dart';
import 'package:sortie/services/calendar/invitations.dart';
import 'package:sortie/services/compose/message_composer.dart';

import '../fakes/ui_fakes.dart';

final request = '''BEGIN:VCALENDAR
VERSION:2.0
METHOD:REQUEST
BEGIN:VEVENT
DTSTART:20261022T140000Z
DTEND:20261022T143000Z
DTSTAMP:20261020T120000Z
ORGANIZER;CN=Brian Jeffers:mailto:brian@hky.test
UID:abc123@google.com
ATTENDEE;PARTSTAT=NEEDS-ACTION;CN=Me:mailto:${DemoData.identities[0].email}
SUMMARY:Speed upgrade planning
END:VEVENT
END:VCALENDAR
''';

void main() {
  testWidgets('an invitation shows a card; Accept mails the organizer and remembers the answer', (tester) async {
    final f = UiFakes();
    final h = DemoData.messages[0];
    f.sync.bodiesByHash[h.messageIdHash] = MessageBody(text: 'You are invited', calendar: request);
    final svc = InvitationService(
      composer: MessageComposer(clock: FakeClock()),
      send: (a, i, r, raw) => f.sync.send(a, i, r, raw),
      identities: f.accounts.identities,
      settings: f.settings,
    );
    await tester.pumpWidget(f.app(
      MessageScreen(accountId: h.accountId, folderPath: h.folderPath, uid: h.uid, standalone: false),
      extra: [invitationServiceProvider.overrideWithValue(svc)],
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('invitationCard')), findsOneWidget);
    expect(find.text('Speed upgrade planning'), findsOneWidget);
    expect(find.textContaining('Brian Jeffers'), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(f.sync.sent.single.$3, ['brian@hky.test']);
    final mime = em.MimeMessage.parseFromText(String.fromCharCodes(f.sync.sent.single.$4));
    final reply = MimeMapper.calendarPart(mime)!;
    expect(reply, contains('METHOD:REPLY'));
    expect(reply, contains('PARTSTAT=ACCEPTED'));
    expect(find.byKey(const Key('invitationAnswer')), findsOneWidget);
    expect(find.text('Accept'), findsNothing, reason: 'already accepted; the other answers stay available');
    expect(find.text('Decline'), findsOneWidget);
  });

  testWidgets('an invitation that only comes as an .ics attachment is picked up', (tester) async {
    final f = UiFakes();
    final h = DemoData.messages[1];
    f.sync.bodiesByHash[h.messageIdHash] = const MessageBody(
      text: 'See attached',
      attachments: [AttachmentInfo(partId: '2', fileName: 'invite.ics', mimeType: 'application/ics', size: 10)],
    );
    f.sync.attachmentBytes['2'] = request.codeUnits;
    final svc = InvitationService(
      composer: MessageComposer(clock: FakeClock()),
      send: (a, i, r, raw) => f.sync.send(a, i, r, raw),
      identities: f.accounts.identities,
      settings: f.settings,
    );
    await tester.pumpWidget(f.app(
      MessageScreen(accountId: h.accountId, folderPath: h.folderPath, uid: h.uid, standalone: false),
      extra: [invitationServiceProvider.overrideWithValue(svc)],
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('invitationCard')), findsOneWidget);
  });
}
