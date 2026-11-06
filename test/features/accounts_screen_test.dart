import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/repositories/repositories.dart';
import 'package:sortie/domain/services/services.dart';
import 'package:sortie/features/accounts/accounts_screen.dart';

import '../fakes/ui_fakes.dart';

void main() {
  testWidgets('an account whose password is gone offers Sign in, checks the password and restarts sync', (tester) async {
    final f = UiFakes();
    f.sync.setStatus(const AccountSyncStatus(
        accountId: DemoData.accountId, state: AccountSyncState.authFailed, error: 'no password stored for account'));
    final tried = <String>[];
    await tester.pumpWidget(f.app(const AccountsScreen(), extra: [
      loginProbeProviderOverride((account, password) async {
        tried.add(password);
        if (password != 'right') throw Exception('AUTHENTICATIONFAILED');
      }),
    ]));
    await tester.pumpAndSettle();

    final button = find.byKey(const Key('accountPassword:${DemoData.accountId}'));
    expect(button, findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget, reason: 'prominent while login is failing');
    await tester.tap(button);
    await tester.pumpAndSettle();

    // A wrong password stays in the dialog with the server's answer.
    await tester.enterText(find.byKey(const Key('accountPasswordField')), 'wrong');
    await tester.tap(find.byKey(const Key('accountPasswordSignIn')));
    await tester.pumpAndSettle();
    expect(find.textContaining('AUTHENTICATIONFAILED'), findsOneWidget);
    expect(f.creds.values[CredentialStore.accountPassword(DemoData.accountId)], isNull);

    // The right one is stored and the account restarted.
    await tester.enterText(find.byKey(const Key('accountPasswordField')), 'right');
    await tester.tap(find.byKey(const Key('accountPasswordSignIn')));
    await tester.pumpAndSettle();
    expect(tried, ['wrong', 'right']);
    expect(find.byKey(const Key('accountPasswordField')), findsNothing);
    expect(f.creds.values[CredentialStore.accountPassword(DemoData.accountId)], 'right');
    expect(f.sync.calls, containsAllInOrder(['stopAccount:${DemoData.accountId}', 'startAccount:${DemoData.accountId}']));
    expect(find.textContaining('Signed in to'), findsOneWidget);
  });

  testWidgets('a healthy account still has a quiet Password button', (tester) async {
    final f = UiFakes();
    await tester.pumpWidget(f.app(const AccountsScreen()));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextButton, 'Password'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsNothing);
  });
}
