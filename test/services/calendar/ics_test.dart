import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/calendar.dart';
import 'package:sortie/services/calendar/ics.dart';
import 'package:sortie/services/calendar/tz.dart';

const _cal = 'cal1';

CalendarEvent _one(String ics) {
  final list = eventsFromIcs(ics, calendarId: _cal, href: '/x.ics', etag: '"1"');
  expect(list, hasLength(1));
  return list.single;
}

CalendarEvent _roundTrip(CalendarEvent e) => eventsFromIcs(icsFromEvents([e]), calendarId: _cal).single;

void main() {
  setUpAll(ensureTimeZonesLoaded);

  group('content lines', () {
    test('unfolds continuation lines and parses params with quotes', () {
      final lines = unfoldLines('DESCRIPTION;X-A="a:b,c";X-B=1,2:hello\r\n  world\r\nSUMMARY:x\r\n');
      expect(lines, ['DESCRIPTION;X-A="a:b,c";X-B=1,2:hello world', 'SUMMARY:x']);
      final p = parseContentLine(lines[0])!;
      expect(p.name, 'DESCRIPTION');
      expect(p.params['X-A'], ['a:b,c']);
      expect(p.params['X-B'], ['1', '2']);
      expect(p.value, 'hello world');
    });

    test('folds at 75 octets without splitting multibyte characters', () {
      final long = 'SUMMARY:${'é' * 60}';
      final folded = foldLine(long);
      for (final l in folded.split('\r\n')) {
        expect(l.codeUnits.length <= 75, isTrue);
      }
      expect(unfoldLines(folded).single, long);
    });

    test('text escaping round-trips', () {
      const s = 'a;b,c\\d\nline2';
      expect(unescapeText(escapeText(s)), s);
      expect(escapeText(s), r'a\;b\,c\\d\nline2');
    });

    test('durations', () {
      expect(parseIcsDuration('-PT15M'), const Duration(minutes: -15));
      expect(parseIcsDuration('P1DT2H'), const Duration(days: 1, hours: 2));
      expect(parseIcsDuration('P2W'), const Duration(days: 14));
      expect(formatIcsDuration(const Duration(minutes: -10)), '-PT10M');
      expect(formatIcsDuration(const Duration(days: 1)), 'P1D');
    });
  });

  group('event round trips', () {
    test('all-day event', () {
      final e = _one('BEGIN:VCALENDAR\nBEGIN:VEVENT\nUID:a1\nDTSTART;VALUE=DATE:20260301\nDTEND;VALUE=DATE:20260303\nSUMMARY:Trip\nEND:VEVENT\nEND:VCALENDAR');
      expect(e.isAllDay, isTrue);
      expect(e.start, DateTime.utc(2026, 3, 1));
      expect(e.end, DateTime.utc(2026, 3, 3));
      expect(e.href, '/x.ics');
      final back = _roundTrip(e);
      expect(back.isAllDay, isTrue);
      expect(back.start, e.start);
      expect(back.end, e.end);
      expect(icsFromEvents([e]), contains('DTSTART;VALUE=DATE:20260301'));
    });

    test('TZID America/New_York converts wall time to UTC and back', () {
      final e = _one('BEGIN:VEVENT\nUID:tz1\nDTSTART;TZID=America/New_York:20260115T090000\nDTEND;TZID=America/New_York:20260115T100000\nSUMMARY:Meet\nEND:VEVENT');
      expect(e.start, DateTime.utc(2026, 1, 15, 14)); // EST = UTC-5
      expect(e.tzid, 'America/New_York');
      final out = icsFromEvents([e]);
      expect(out, contains('DTSTART;TZID=America/New_York:20260115T090000'));
      final back = _roundTrip(e);
      expect(back.start, e.start);
      expect(back.tzid, 'America/New_York');
      // Summer instance of the same wall time is UTC-4.
      final s = _one('BEGIN:VEVENT\nUID:tz2\nDTSTART;TZID=America/New_York:20260715T090000\nDTEND;TZID=America/New_York:20260715T100000\nEND:VEVENT');
      expect(s.start, DateTime.utc(2026, 7, 15, 13));
    });

    test('UTC (Z) times', () {
      final e = _one('BEGIN:VEVENT\nUID:u1\nDTSTART:20260401T120000Z\nDURATION:PT30M\nSUMMARY:Call\nEND:VEVENT');
      expect(e.start, DateTime.utc(2026, 4, 1, 12));
      expect(e.end, DateTime.utc(2026, 4, 1, 12, 30));
      expect(e.tzid, isNull);
      expect(e.floating, isFalse);
      expect(icsFromEvents([e]), contains('DTSTART:20260401T120000Z'));
      expect(_roundTrip(e).start, e.start);
    });

    test('floating times use the device zone and stay floating', () {
      final e = _one('BEGIN:VEVENT\nUID:f1\nDTSTART:20260401T083000\nDTEND:20260401T090000\nEND:VEVENT');
      expect(e.floating, isTrue);
      expect(e.start, DateTime(2026, 4, 1, 8, 30).toUtc());
      final out = icsFromEvents([e]);
      expect(out, contains('DTSTART:20260401T083000\r\n'));
      expect(_roundTrip(e).floating, isTrue);
    });

    test('weekly RRULE with EXDATE, alarms, attendees and escaped text', () {
      const ics = 'BEGIN:VCALENDAR\r\n'
          'BEGIN:VEVENT\r\n'
          'UID:r1\r\n'
          'DTSTART;TZID=Europe/Berlin:20260105T100000\r\n'
          'DTEND;TZID=Europe/Berlin:20260105T110000\r\n'
          'RRULE:FREQ=WEEKLY;BYDAY=MO;COUNT=10\r\n'
          'EXDATE;TZID=Europe/Berlin:20260112T100000,20260119T100000\r\n'
          'SUMMARY:Weekly\\, sync\\; notes\r\n'
          'DESCRIPTION:Line one\\nLine two with a very long text that will certainly exc\r\n'
          ' eed the seventy five octet limit of a content line\r\n'
          'LOCATION:Room \\"A\\"\r\n'
          'ORGANIZER;CN=Boss:mailto:boss@example.com\r\n'
          'ATTENDEE;CN=Pat;PARTSTAT=ACCEPTED:mailto:pat@example.com\r\n'
          'ATTENDEE;PARTSTAT=DECLINED:mailto:sam@example.com\r\n'
          'STATUS:CONFIRMED\r\n'
          'BEGIN:VALARM\r\nACTION:DISPLAY\r\nTRIGGER:-PT15M\r\nEND:VALARM\r\n'
          'BEGIN:VALARM\r\nACTION:DISPLAY\r\nTRIGGER:-P1D\r\nEND:VALARM\r\n'
          'END:VEVENT\r\n'
          'END:VCALENDAR\r\n';
      final e = _one(ics);
      expect(e.rrule, 'FREQ=WEEKLY;BYDAY=MO;COUNT=10');
      expect(e.exdates, [DateTime.utc(2026, 1, 12, 9), DateTime.utc(2026, 1, 19, 9)]);
      expect(e.summary, 'Weekly, sync; notes');
      expect(e.description, startsWith('Line one\nLine two with a very long text that will certainly exceed'));
      expect(e.organizer, 'boss@example.com');
      expect(e.attendees.map((a) => a.email), ['pat@example.com', 'sam@example.com']);
      expect(e.attendees.first.name, 'Pat');
      expect(e.attendees.first.status, AttendeeStatus.accepted);
      expect(e.attendees.last.status, AttendeeStatus.declined);
      expect(e.alarms, [15, 1440]);
      expect(e.status, 'CONFIRMED');

      final out = icsFromEvents([e]);
      expect(out, contains('RRULE:FREQ=WEEKLY;BYDAY=MO;COUNT=10'));
      expect(out, contains('EXDATE;TZID=Europe/Berlin:20260112T100000'));
      expect(out, contains(r'SUMMARY:Weekly\, sync\; notes'));
      expect(out, contains('TRIGGER:-PT15M'));
      expect(out, contains('TRIGGER:-P1D'));
      expect(out, contains('ATTENDEE;CN=Pat;PARTSTAT=ACCEPTED:mailto:pat@example.com'));
      final back = _roundTrip(e);
      expect(back.exdates, e.exdates);
      expect(back.alarms, e.alarms);
      expect(back.description, e.description);
      expect(back.attendees.length, 2);
    });

    test('RECURRENCE-ID override shares the uid with a distinct id', () {
      const ics = 'BEGIN:VCALENDAR\nBEGIN:VEVENT\nUID:m\nDTSTART:20260101T100000Z\nDTEND:20260101T110000Z\nRRULE:FREQ=DAILY\nEND:VEVENT\n'
          'BEGIN:VEVENT\nUID:m\nRECURRENCE-ID:20260103T100000Z\nDTSTART:20260103T120000Z\nDTEND:20260103T130000Z\nSUMMARY:Moved\nEND:VEVENT\nEND:VCALENDAR';
      final list = eventsFromIcs(ics, calendarId: _cal);
      expect(list, hasLength(2));
      final o = list.firstWhere((e) => e.isOverride);
      expect(o.recurrenceId, DateTime.utc(2026, 1, 3, 10));
      expect(o.id, isNot(list.firstWhere((e) => !e.isOverride).id));
      expect(icsFromEvents(list), contains('RECURRENCE-ID:20260103T100000Z'));
    });

    test('Windows time zone names map to IANA; unknown TZID falls back to VTIMEZONE offset', () {
      final e = _one('BEGIN:VEVENT\nUID:w\nDTSTART;TZID=Eastern Standard Time:20260115T090000\nDTEND;TZID=Eastern Standard Time:20260115T100000\nEND:VEVENT');
      expect(e.start, DateTime.utc(2026, 1, 15, 14));
      const withVtz = 'BEGIN:VCALENDAR\nBEGIN:VTIMEZONE\nTZID:Custom/Zone\nBEGIN:STANDARD\nTZOFFSETFROM:+0100\nTZOFFSETTO:+0300\nEND:STANDARD\nEND:VTIMEZONE\n'
          'BEGIN:VEVENT\nUID:v\nDTSTART;TZID=Custom/Zone:20260115T090000\nDTEND;TZID=Custom/Zone:20260115T100000\nEND:VEVENT\nEND:VCALENDAR';
      final v = _one(withVtz);
      expect(v.start, DateTime.utc(2026, 1, 15, 6));
    });
  });
}
