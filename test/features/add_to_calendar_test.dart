import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/app/demo/fake_calendar.dart';
import 'package:sortie/app/demo/fake_repositories.dart';
import 'package:sortie/app/providers.dart';
import 'package:sortie/core/clock.dart';
import 'package:sortie/data/calendar/google_oauth.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/features/message_view/message_screen.dart';
import 'package:sortie/services/calendar/calendar_service.dart';
import 'package:sortie/services/calendar/tz.dart';

import '../fakes/ui_fakes.dart';

const teamsMail = '''Discuss API issues and work toward resolution
________________________________________________________________________________
Microsoft Teams meeting
Join: https://teams.microsoft.com/meet/2685172888736005?p=21H3K8kza5CrWz5myY
Meeting ID: 268 517 288 873 600 5
Passcode: r2JT9QV6
''';

void main() {
  setUpAll(ensureTimeZonesLoaded);

  testWidgets('Add to calendar on a mail without a calendar part opens the editor pre-filled', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final f = UiFakes();
    final h = DemoData.messages[0];
    f.sync.bodiesByHash[h.messageIdHash] = const MessageBody(text: teamsMail);
    final repo = FakeCalendarRepository(sources: DemoCalendarData.sources);
    final creds = FakeCredentialStore();
    late final CalendarService service;
    service = CalendarService(
      repo: repo,
      credentials: creds,
      settings: FakeSettingsRepository(),
      clock: SystemClock(),
      google: GoogleAccountLinks(credentials: creds, client: () => service.googleClient()),
      startupDelay: const Duration(days: 1),
    );
    await tester.pumpWidget(f.app(
      MessageScreen(accountId: h.accountId, folderPath: h.folderPath, uid: h.uid, standalone: false),
      extra: [
        calendarRepositoryProvider.overrideWithValue(repo),
        calendarServiceProvider.overrideWithValue(service),
        googleOAuthProvider.overrideWithValue(service.google),
      ],
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('invitationCard')), findsNothing, reason: 'no calendar part in this mail');

    await tester.tap(find.byType(PopupMenuButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to calendar'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('saveEvent')), findsOneWidget, reason: 'the event editor opened');
    final fields = find.byType(TextField).evaluate().map((e) => (e.widget as TextField).controller?.text ?? '').toList();
    expect(fields, contains(h.subject));
    expect(fields, contains('https://teams.microsoft.com/meet/2685172888736005?p=21H3K8kza5CrWz5myY'));
    expect(fields.any((t) => t.contains('Discuss API issues')), isTrue);
  });
}
