import 'package:enough_mail/enough_mail.dart' as em;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/app/demo/fake_calendar.dart';
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

  testWidgets('Add without replying stores the event and sends nothing', (tester) async {
    final f = UiFakes();
    final h = DemoData.messages[0];
    f.sync.bodiesByHash[h.messageIdHash] = MessageBody(text: 'You are invited', calendar: request);
    final calendar = FakeCalendarRepository();
    final svc = InvitationService(
      composer: MessageComposer(clock: FakeClock()),
      send: (a, i, r, raw) => f.sync.send(a, i, r, raw),
      identities: f.accounts.identities,
      settings: f.settings,
      calendar: calendar,
    );
    await tester.pumpWidget(f.app(
      MessageScreen(accountId: h.accountId, folderPath: h.folderPath, uid: h.uid, standalone: false),
      extra: [invitationServiceProvider.overrideWithValue(svc)],
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('addToCalendar')));
    await tester.tap(find.byKey(const Key('addToCalendar')));
    await tester.pumpAndSettle();
    expect(f.sync.sent, isEmpty);
    expect(find.byKey(const Key('invitationInCalendar')), findsOneWidget);
    expect(find.byKey(const Key('addToCalendar')), findsNothing);
    expect(find.text('Accept'), findsOneWidget, reason: 'answering later is still possible');
    expect((await calendar.eventsByUid(InvitationService.localCalendarId, 'abc123@google.com')).single.summary, 'Speed upgrade planning');
  });

  testWidgets('a body cached before calendar support is fetched again once and then shows the card', (tester) async {
    final f = UiFakes();
    final h = DemoData.messages[0];
    f.sync.bodiesByHash[h.messageIdHash] = const MessageBody(text: 'old cache', calendarKnown: false);
    f.sync.refreshedBodiesByHash[h.messageIdHash] = MessageBody(text: 'fresh', calendar: request);
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
    expect(f.sync.calls.where((c) => c.endsWith(':refresh')).length, 1);
    expect(find.byKey(const Key('invitationCard')), findsOneWidget);
  });

  testWidgets('with several writable calendars the card asks which one', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final f = UiFakes();
    final h = DemoData.messages[0];
    f.sync.bodiesByHash[h.messageIdHash] = MessageBody(text: 'You are invited', calendar: request);
    final calendar = FakeCalendarRepository(sources: const [
      CalendarSource(id: 'home', name: 'Home', kind: CalendarKind.local, color: 0xFF00FF00, enabled: true),
      CalendarSource(id: 'google-1', name: 'HTC Installers', kind: CalendarKind.caldav, url: 'https://x', color: 0xFF0000FF, enabled: true),
    ]);
    final svc = InvitationService(
      composer: MessageComposer(clock: FakeClock()),
      send: (a, i, r, raw) => f.sync.send(a, i, r, raw),
      identities: f.accounts.identities,
      settings: f.settings,
      calendar: calendar,
    );
    await tester.pumpWidget(f.app(
      MessageScreen(accountId: h.accountId, folderPath: h.folderPath, uid: h.uid, standalone: false),
      extra: [invitationServiceProvider.overrideWithValue(svc), calendarRepositoryProvider.overrideWithValue(calendar)],
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('addToCalendar')));
    await tester.tap(find.byKey(const Key('addToCalendar')));
    await tester.pumpAndSettle();
    expect(find.text('Add to which calendar?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('calendarChoice:google-1')));
    await tester.pumpAndSettle();
    expect((await calendar.eventsByUid('google-1', 'abc123@google.com')).single.summary, 'Speed upgrade planning');
    expect(await calendar.eventsByUid('home', 'abc123@google.com'), isEmpty);
    expect(await svc.preferredCalendar(), 'google-1');
    expect(find.byKey(const Key('invitationInCalendar')), findsOneWidget);
  });
}
