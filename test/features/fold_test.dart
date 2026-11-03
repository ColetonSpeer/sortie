import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sortie/features/mailbox/message_list.dart';
import 'package:sortie/features/message_view/message_screen.dart';
import 'package:sortie/features/shell/adaptive_scaffold.dart';
import 'package:sortie/platform/fold/fold_geometry.dart';
import 'package:sortie/router/app_router.dart';

import '../fakes/ui_fakes.dart';

// iPhone Duo window sizes in logical points (iOS 27.1 simulator).
const outer = Size(466, 678);
const innerBook = Size(951, 669);
const innerUpright = Size(669, 951);

/// The fold as UIKit reports it: the window's middle 40 pt including margins.
FoldGeometry bookFold({required bool active}) => FoldGeometry([FoldRegion(const Rect.fromLTWH(455.5, 0, 40, 669), active: active)]);
FoldGeometry laptopFold({required bool active}) => FoldGeometry([FoldRegion(const Rect.fromLTWH(0, 455.5, 669, 40), active: active)]);

/// The real mail routes behind the shell, sized by the test's view.
Widget shell(UiFakes f, String initial, Stream<FoldGeometry> folds) {
  Page<void> page(GoRouterState s, int? uid) => NoTransitionPage(
    key: s.pageKey,
    child: AdaptiveScaffold(
      accountId: Uri.decodeComponent(s.pathParameters['accountId']!),
      folderPath: Uri.decodeComponent(s.pathParameters['folder']!),
      uid: uid,
    ),
  );
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/mail/:accountId/:folder',
        pageBuilder: (_, s) => page(s, null),
        routes: [GoRoute(path: 'message/:uid', pageBuilder: (_, s) => page(s, int.parse(s.pathParameters['uid']!)))],
      ),
    ],
  );
  return ProviderScope(
    overrides: f.overrides(),
    child: MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => FoldAware(folds: folds, child: child!),
    ),
  );
}

void setView(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
}

void main() {
  late StreamController<FoldGeometry> folds;
  setUp(() => folds = StreamController<FoldGeometry>.broadcast());
  tearDown(() => folds.close());

  testWidgets('book pose: the list sits left of the fold and the message right of it', (tester) async {
    setView(tester, innerBook);
    addTearDown(tester.view.reset);
    final f = UiFakes();
    final h = DemoData.messages.first;
    await tester.pumpWidget(shell(f, Routes.message(h.accountId, h.folderPath, h.uid), folds.stream));
    await tester.pumpAndSettle();
    // No fold known yet: the default list width.
    expect(tester.getSize(find.byType(MessageListPane)).width, AdaptiveScaffold.twoPaneListWidth);

    // Lying flat: the divider lands on the seam.
    folds.add(bookFold(active: false));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MessageListPane)).width, 475.5);
    expect(tester.getTopLeft(find.byType(MessageScreen)).dx, 476.5);
    expect(MediaQuery.displayFeaturesOf(tester.element(find.byType(MessageScreen))), isEmpty);

    // Partially folded: the whole reserved strip stays empty.
    folds.add(bookFold(active: true));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MessageListPane)).width, 455.5);
    expect(tester.getTopLeft(find.byType(MessageScreen)).dx, 495.5);
    expect(MediaQuery.displayFeaturesOf(tester.element(find.byType(MessageScreen))), hasLength(1));
  });

  testWidgets('laptop pose: the message reads above the fold, the list scrolls below it', (tester) async {
    setView(tester, innerUpright);
    addTearDown(tester.view.reset);
    final f = UiFakes();
    final h = DemoData.messages.first;
    await tester.pumpWidget(shell(f, Routes.message(h.accountId, h.folderPath, h.uid), folds.stream));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(MessageScreen)).dx, greaterThan(0), reason: 'side by side while flat');

    folds.add(laptopFold(active: true));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(MessageScreen)), const Rect.fromLTWH(0, 0, 669, 455.5));
    expect(tester.getTopLeft(find.byType(MessageListPane)), const Offset(0, 495.5));

    // Flat again: back to two columns.
    folds.add(laptopFold(active: false));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(MessageScreen)).dx, greaterThan(0));
    expect(tester.getTopLeft(find.byType(MessageListPane)), Offset.zero);
  });

  testWidgets('opening and closing the phone keeps the open message, its state and its hold', (tester) async {
    setView(tester, outer);
    addTearDown(tester.view.reset);
    final f = UiFakes();
    final h = DemoData.messages.first;
    await tester.pumpWidget(shell(f, Routes.message(h.accountId, h.folderPath, h.uid), folds.stream));
    await tester.pumpAndSettle();
    // Closed: the message fills the outer display, list hidden behind it.
    expect(find.byType(MessageListPane), findsNothing);
    final state = tester.state(find.byType(MessageScreen));
    expect(f.coordinator.opened, [h.key]);
    expect(f.coordinator.closed, isEmpty);

    // Opened: two panes, same reader.
    setView(tester, innerBook);
    folds.add(bookFold(active: false));
    await tester.pumpAndSettle();
    expect(find.byType(MessageListPane), findsOneWidget);
    expect(identical(tester.state(find.byType(MessageScreen)), state), isTrue, reason: 'the reader keeps its State');
    expect(f.coordinator.closed, isEmpty, reason: 'the hold never lapsed');
    expect(f.coordinator.opened, [h.key]);

    // Closed again.
    setView(tester, outer);
    folds.add(FoldGeometry.none);
    await tester.pumpAndSettle();
    expect(find.byType(MessageListPane), findsNothing);
    expect(identical(tester.state(find.byType(MessageScreen)), state), isTrue);
    expect(f.coordinator.closed, isEmpty);
  });

  testWidgets('a dialog opened while partially folded stays on one side of the fold', (tester) async {
    setView(tester, innerBook);
    addTearDown(tester.view.reset);
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => FoldAware(folds: folds.stream, child: child!),
        home: Builder(
          builder: (c) {
            ctx = c;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );
    folds.add(bookFold(active: true));
    await tester.pumpAndSettle();
    unawaited(
      showDialog<void>(
        context: ctx,
        builder: (_) => const AlertDialog(title: Text('Move to…')),
      ),
    );
    await tester.pumpAndSettle();
    final r = tester.getRect(find.byType(AlertDialog));
    expect(r.right, lessThanOrEqualTo(455.5), reason: 'left half, not across the crease');
    expect(r.width, greaterThan(200));
  });

  test('FoldGeometry parses the native map and ignores junk', () {
    final g = FoldGeometry.parse({
      'folds': [
        {'x': 455.5, 'y': 0, 'w': 40, 'h': 669, 'active': true},
        'junk',
      ],
    });
    expect(g.folds, [FoldRegion(const Rect.fromLTWH(455.5, 0, 40, 669), active: true)]);
    expect(g.verticalFoldIn(innerBook), isNotNull);
    expect(g.activeHorizontalFoldIn(innerBook), isNull);
    expect(g.displayFeatures.single.bounds, const Rect.fromLTWH(455.5, 0, 40, 669));
    expect(FoldGeometry.parse(null), FoldGeometry.none);
    expect(FoldGeometry.parse({'folds': 3}), FoldGeometry.none);
    // A fold that does not cross the whole window splits nothing.
    expect(FoldGeometry([FoldRegion(const Rect.fromLTWH(455.5, 100, 40, 200), active: true)]).verticalFoldIn(innerBook), isNull);
  });
}
