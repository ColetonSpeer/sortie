import 'package:enough_mail/enough_mail.dart' as em;
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/app/demo/fake_calendar.dart';
import 'package:sortie/app/demo/fake_repositories.dart';
import 'package:sortie/core/clock.dart';
import 'package:sortie/data/mail/enough/mime_mapper.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/services/calendar/invitations.dart';
import 'package:sortie/services/compose/message_composer.dart';

const request = '''BEGIN:VCALENDAR
PRODID:-//Google Inc//Google Calendar 70.9054//EN
VERSION:2.0
METHOD:REQUEST
BEGIN:VEVENT
DTSTART:20261022T140000Z
DTEND:20261022T143000Z
DTSTAMP:20261020T120000Z
ORGANIZER;CN=Brian Jeffers:mailto:brian@hky.test
UID:abc123@google.com
ATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;CN=Coleton Speer;X-NUM-GUESTS=0:mailto:coleton@hky.test
ATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=ACCEPTED;CN=Brian Jeffers:mailto:brian@hky.test
SEQUENCE:2
LOCATION:Conference room
SUMMARY:Speed upgrade planning
END:VEVENT
END:VCALENDAR
''';

const me = Identity(id: 'i1', accountId: 'acct', name: 'Coleton Speer', email: 'coleton@hky.test', isDefault: true);

void main() {
  test('parses a Google-style request', () {
    final inv = MeetingInvitation.parse(request)!;
    expect(inv.method, InvitationMethod.request);
    expect(inv.event.summary, 'Speed upgrade planning');
    expect(inv.event.uid, 'abc123@google.com');
    expect(inv.organizer, 'brian@hky.test');
    expect(inv.organizerName, 'Brian Jeffers');
    expect(inv.sequence, 2);
    expect(inv.event.location, 'Conference room');
    expect(inv.attendeeFor(['COLETON@hky.test'])?.name, 'Coleton Speer');
    expect(MeetingInvitation.parse('hello'), isNull);
    expect(MeetingInvitation.parse(request.replaceFirst('METHOD:REQUEST', 'METHOD:CANCEL'))!.method, InvitationMethod.cancel);
  });

  test('builds an iTIP reply for the organizer', () {
    final inv = MeetingInvitation.parse(request)!;
    final ics = inv.replyIcs(me: me, status: AttendeeStatus.accepted, now: DateTime.utc(2026, 10, 20, 12));
    expect(ics, contains('METHOD:REPLY'));
    expect(ics, contains('UID:abc123@google.com'));
    expect(ics, contains('SEQUENCE:2'));
    expect(ics, contains('ORGANIZER;CN=Brian Jeffers:mailto:brian@hky.test'));
    expect(ics, contains('PARTSTAT=ACCEPTED'));
    expect(ics, contains('mailto:coleton@hky.test'));
    expect(ics, contains('SUMMARY:Accepted: Speed upgrade planning'));
    expect(ics, contains('DTSTART:20261022T140000Z'));
  });

  test('respond mails the organizer, records the answer and keeps the event locally', () async {
    final sent = <(String, String, List<String>, List<int>)>[];
    final settings = FakeSettingsRepository();
    final calendar = FakeCalendarRepository();
    final svc = InvitationService(
      composer: MessageComposer(clock: FakeClock()),
      send: (a, i, r, raw) async => sent.add((a, i, r, raw)),
      identities: (_) async => [me],
      settings: settings,
      calendar: calendar,
      now: () => DateTime.utc(2026, 10, 20, 12),
    );
    final inv = MeetingInvitation.parse(request)!;
    expect(await svc.responseOf('acct', inv), isNull);
    await svc.respond(accountId: 'acct', invitation: inv, status: AttendeeStatus.tentative);
    expect(sent.single.$3, ['brian@hky.test']);
    final raw = String.fromCharCodes(sent.single.$4);
    expect(raw, contains('Subject: Tentative: Speed upgrade planning'));
    expect(raw, contains('text/calendar'));
    expect(raw, contains('method=REPLY'));
    expect(raw, contains('reply.ics'));
    expect(await svc.responseOf('acct', inv), AttendeeStatus.tentative);
    final stored = await calendar.eventsByUid(InvitationService.localCalendarId, 'abc123@google.com');
    expect(stored.single.attendees.firstWhere((a) => a.email == me.email).status, AttendeeStatus.tentative);
    await svc.respond(accountId: 'acct', invitation: inv, status: AttendeeStatus.declined);
    expect(await calendar.eventsByUid(InvitationService.localCalendarId, 'abc123@google.com'), isEmpty);
    expect(sent.length, 2);
  });

  test('the text/calendar alternative of a MIME message is picked up', () {
    final b = em.MessageBuilder()
      ..from = [em.MailAddress('Brian', 'brian@hky.test')]
      ..to = [em.MailAddress('Coleton', 'coleton@hky.test')]
      ..subject = 'Invitation';
    b.setContentType(em.MediaSubtype.multipartAlternative.mediaType);
    b.addTextPlain('You are invited');
    b.addText(request, mediaType: em.MediaType.fromText('text/calendar'));
    final mime = b.buildMimeMessage();
    final parsed = em.MimeMessage.parseFromText(mime.renderMessage());
    expect(MimeMapper.bodyFrom(parsed).calendar, contains('BEGIN:VCALENDAR'));
  });

  test('addToCalendar keeps the event without mailing anyone', () async {
    final sent = <List<String>>[];
    final calendar = FakeCalendarRepository();
    final svc = InvitationService(
      composer: MessageComposer(clock: FakeClock()),
      send: (a, i, r, raw) async => sent.add(r),
      identities: (_) async => [me],
      settings: FakeSettingsRepository(),
      calendar: calendar,
    );
    final inv = MeetingInvitation.parse(request)!;
    expect(await svc.isInCalendar(inv), isFalse);
    await svc.addToCalendar(accountId: 'acct', invitation: inv);
    expect(sent, isEmpty);
    expect(await svc.isInCalendar(inv), isTrue);
    expect(await svc.responseOf('acct', inv), isNull, reason: 'no answer was given');
    final stored = (await calendar.eventsByUid(InvitationService.localCalendarId, 'abc123@google.com')).single;
    expect(stored.summary, 'Speed upgrade planning');
  });

  test('a method-less calendar object still parses so it can be added', () {
    final ics = request.replaceFirst('METHOD:REQUEST\n', '').replaceFirst('ORGANIZER;CN=Brian Jeffers:mailto:brian@hky.test\n', '');
    final inv = MeetingInvitation.parse(ics)!;
    expect(inv.method, InvitationMethod.other);
    expect(inv.organizer, isNull);
  });

  test('a chosen calendar is used through the calendar service create/update hooks', () async {
    final calendar = FakeCalendarRepository(sources: const [
      CalendarSource(id: 'google-1', name: 'HTC Installers', kind: CalendarKind.caldav, url: 'https://x', color: 0xFF0000FF, enabled: true),
    ]);
    final created = <CalendarEvent>[];
    final updated = <CalendarEvent>[];
    final settings = FakeSettingsRepository();
    final svc = InvitationService(
      composer: MessageComposer(clock: FakeClock()),
      send: (a, i, r, raw) async {},
      identities: (_) async => [me],
      settings: settings,
      calendar: calendar,
      createEvent: (d) async {
        created.add(d);
        await calendar.upsertEvents([d]);
        return d;
      },
      updateEvent: (e) async {
        updated.add(e);
        await calendar.upsertEvents([e]);
      },
    );
    final inv = MeetingInvitation.parse(request)!;
    await svc.addToCalendar(accountId: 'acct', invitation: inv, calendarId: 'google-1');
    expect(created.single.calendarId, 'google-1');
    expect(created.single.id, 'google-1|abc123@google.com');
    expect(await calendar.eventsByUid(InvitationService.localCalendarId, 'abc123@google.com'), isEmpty, reason: 'not duplicated locally');
    // Answering later updates the same event instead of creating another.
    await svc.respond(accountId: 'acct', invitation: inv, status: AttendeeStatus.accepted, calendarId: 'google-1');
    expect(created.length, 1);
    expect(updated.single.attendees.firstWhere((a) => a.email == me.email).status, AttendeeStatus.accepted);
    await svc.rememberCalendar('google-1');
    expect(await svc.preferredCalendar(), 'google-1');
  });
}
