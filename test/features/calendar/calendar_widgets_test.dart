import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/app/demo/fake_calendar.dart';
import 'package:sortie/app/demo/fake_repositories.dart';
import 'package:sortie/app/providers.dart';
import 'package:sortie/core/clock.dart';
import 'package:sortie/data/calendar/google_oauth.dart';
import 'package:sortie/domain/entities/calendar.dart';
import 'package:sortie/features/calendar/calendar_providers.dart';
import 'package:sortie/features/calendar/calendar_screen.dart';
import 'package:sortie/features/calendar/event_editor.dart';
import 'package:sortie/services/calendar/calendar_service.dart';
import 'package:sortie/services/calendar/tz.dart';

class _Harness {
  _Harness({List<CalendarEvent> events = const []})
      : repo = FakeCalendarRepository(sources: DemoCalendarData.sources, events: events) {
    final creds = FakeCredentialStore();
    service = CalendarService(
      repo: repo,
      credentials: creds,
      settings: FakeSettingsRepository(),
      clock: SystemClock(),
      google: GoogleAccountLinks(credentials: creds, client: () => service.googleClient()),
      startupDelay: const Duration(days: 1),
    );
  }
  final FakeCalendarRepository repo;
  late final CalendarService service;

  Widget app(Widget child, {Size size = const Size(1200, 800)}) => ProviderScope(
        overrides: [
          calendarRepositoryProvider.overrideWithValue(repo),
          calendarServiceProvider.overrideWithValue(service),
          googleOAuthProvider.overrideWithValue(service.google),
        ],
        child: MaterialApp(home: MediaQuery(data: MediaQueryData(size: size), child: child)),
      );
}

void main() {
  setUpAll(ensureTimeZonesLoaded);

  final now = DateTime.now();
  final mid = DateTime(now.year, now.month, 15, 10);

  testWidgets('month view renders demo events with calendar colours and switches to agenda on day tap', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final events = [
      ...DemoCalendarData.events(now),
      CalendarEvent(
        id: 'demo-cal-work|widget',
        calendarId: DemoCalendarData.workId,
        uid: 'widget',
        summary: 'Widget test event',
        start: mid.toUtc(),
        end: mid.add(const Duration(hours: 1)).toUtc(),
        updatedAt: now.toUtc(),
      ),
    ];
    final h = _Harness(events: events);
    await tester.pumpWidget(h.app(const CalendarScreen()));
    await tester.pumpAndSettle();

    expect(find.text(CalFmt.month(now)), findsOneWidget);
    expect(find.text('Widget test event'), findsOneWidget);
    expect(find.text('Work (demo)'), findsOneWidget); // side panel on wide layouts
    expect(find.byKey(const Key('newEventFab')), findsOneWidget);

    await tester.tap(find.text('Widget test event'));
    await tester.pumpAndSettle();
    expect(find.text('Work (demo)'), findsNWidgets(2)); // detail sheet names the calendar
    expect(find.text('Edit'), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();
    expect(find.textContaining('From '), findsOneWidget);
  });

  testWidgets('editor rejects an end before the start and saves a valid event', (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final h = _Harness();
    await tester.pumpWidget(h.app(Builder(
      builder: (c) => Scaffold(body: TextButton(onPressed: () => openEventEditor(c, initialStart: mid), child: const Text('open'))),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(EventEditorPage), findsOneWidget);

    await tester.enterText(find.byKey(const Key('eventTitle')), 'Lunch');
    // Move the end date to the 1st of the month: before the start.
    await tester.tap(find.byKey(const Key('endDate')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').first);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('saveEvent')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('editorError')), findsOneWidget);
    expect(find.text('End must be after start'), findsOneWidget);
    expect(h.repo.eventList, isEmpty);

    // Fix the end date (the 28th) and save.
    await tester.tap(find.byKey(const Key('endDate')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('28').first);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveEvent')));
    await tester.pumpAndSettle();
    expect(find.byType(EventEditorPage), findsNothing);
    expect(h.repo.eventList.single.summary, 'Lunch');
    expect(h.repo.eventList.single.alarms, [10]);
    expect(h.repo.eventList.single.calendarId, DemoCalendarData.workId);
  });
}
