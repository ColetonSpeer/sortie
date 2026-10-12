import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sortie/app/providers.dart';
import 'package:sortie/features/settings/import_page.dart';
import 'package:sortie/features/settings/settings_screen.dart';
import 'package:sortie/services/import/thunderbird/profile_locator.dart';

import '../fakes/ui_fakes.dart';
import '../services/import/fixtures.dart';

void main() {
  late Directory tmp;
  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('tbprofile');
    await writeProfile(tmp);
  });
  tearDown(() => tmp.delete(recursive: true));

  List<Override> extra(Directory profile) => [
        thunderbirdProfileLocatorProvider.overrideWithValue(FixedProfileLocator([TbProfile(name: 'default', path: profile.path, isDefault: true)])),
        loginProbeProviderOverride((a, pw) async {}),
      ];

  testWidgets('import page lists the detected profile and renders the preview after scanning', (tester) async {
    final f = UiFakes();
    await tester.pumpWidget(f.app(const ImportPage(), extra: extra(tmp)));
    await tester.pumpAndSettle();

    expect(find.text('default (default)'), findsOneWidget);
    // Scanning reads real files: let the I/O complete outside the fake-async zone.
    await tester.runAsync(() async {
      await tester.tap(find.byKey(Key('profile-${tmp.path}')));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(find.text('jane@example.test'), findsWidgets);
    expect(find.byKey(const Key('password-account1')), findsOneWidget);
    expect(find.text('Jane "JJ" Doe <jane@example.test>'), findsOneWidget);
    expect(find.text('Sorting rules'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('password-account1')), 'secret');
    // Lazy ListView: its max extent is only an estimate, so step down until the button is built.
    await tester.dragUntilVisible(find.byKey(const Key('importButton')), find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Holidays'), findsOneWidget);
    await tester.tap(find.byKey(const Key('importButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 account(s) created'), findsOneWidget);
    expect(find.textContaining('rule(s) imported'), findsOneWidget);
    expect(find.textContaining('mark read only'), findsOneWidget);
    expect((await f.accounts.all()).map((a) => a.email), contains('jane@example.test'));
  });

  testWidgets('settings entry navigates to /settings/import', (tester) async {
    final f = UiFakes();
    final router = GoRouter(initialLocation: '/settings', routes: [
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen(), routes: [
        GoRoute(path: 'import', builder: (_, _) => const ImportPage()),
      ]),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: f.overrides(extra: extra(tmp)),
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.byKey(const Key('importThunderbird')), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('importThunderbird')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/settings/import');
    expect(find.byType(ImportPage), findsOneWidget);
    expect(find.byKey(const Key('chooseFolder')), findsOneWidget);
  });
}
