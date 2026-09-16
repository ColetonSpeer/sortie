import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/features/onboarding/onboarding_screen.dart';

import '../fakes/ui_fakes.dart';

void main() {
  testWidgets('credentials form validates email and password', (tester) async {
    final f = UiFakes(seed: false);
    await tester.pumpWidget(f.app(const OnboardingScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('getStarted')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('continue')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('email')), 'not-an-email');
    await tester.tap(find.byKey(const Key('continue')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('valid credentials start autodiscovery', (tester) async {
    final f = UiFakes(seed: false);
    var discovered = '';
    await tester.pumpWidget(f.app(const OnboardingScreen(), extra: [
      autodiscoveryProviderOverride((email) async {
        discovered = email;
        await Future<void>.delayed(const Duration(days: 1)); // never completes in this test
        return [];
      }),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('getStarted')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('email')), 'demo@example.invalid');
    await tester.enterText(find.byKey(const Key('password')), 'secret');
    await tester.tap(find.byKey(const Key('continue')));
    await tester.pump();

    expect(discovered, 'demo@example.invalid');
    expect(find.text('Finding your server…'), findsOneWidget);
    // Cancel the pending fake future's timer.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(days: 2));
  });
}
