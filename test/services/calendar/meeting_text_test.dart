import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/services/calendar/meeting_text.dart';

void main() {
  test('finds the video-meeting link', () {
    expect(meetingLink('Join: https://teams.microsoft.com/meet/2685172888736005?p=21H3K8kza5CrWz5myY\nMeeting ID: 1'),
        'https://teams.microsoft.com/meet/2685172888736005?p=21H3K8kza5CrWz5myY');
    expect(meetingLink('see https://zoom.us/j/123?pwd=abc.'), 'https://zoom.us/j/123?pwd=abc');
    expect(meetingLink('no link here'), isNull);
  });

  test('reads Outlook "When:" lines and prose dates', () {
    final w = guessMeetingTime('When: Thursday, October 22, 2026 2:00 PM-3:00 PM (UTC-05:00) Eastern Time\nWhere: Teams')!;
    expect(w.start, DateTime(2026, 10, 22, 14));
    expect(w.end, DateTime(2026, 10, 22, 15));
    final p = guessMeetingTime("Let's meet Oct 23, 2026 at 9:30 am")!;
    expect(p.start, DateTime(2026, 10, 23, 9, 30));
    expect(p.end, isNull);
    final n = guessMeetingTime('Call on 10/24/2026 1-2 PM')!;
    expect(n.start, DateTime(2026, 10, 24, 13));
    expect(n.end, DateTime(2026, 10, 24, 14));
    expect(guessMeetingTime('2026-10-25T16:45')!.start, DateTime(2026, 10, 25, 16, 45));
    expect(guessMeetingTime('May 6, 2026')!.start, DateTime(2026, 5, 6, 9));
  });

  test('gives up on text without a date', () {
    expect(guessMeetingTime('Discuss API issues and work toward resolution\nMicrosoft Teams meeting\nMeeting ID: 268 517 288 873 600 5'), isNull);
  });
}
