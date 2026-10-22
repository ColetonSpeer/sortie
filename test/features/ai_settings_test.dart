import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/domain/repositories/repositories.dart';
import 'package:sortie/features/settings/ai_settings_page.dart';
import 'package:sortie/features/settings/settings_common.dart';

import '../fakes/ui_fakes.dart';

void main() {
  keyRefreshTests();
  testWidgets('AI page shows the "Sending: …" line for Anthropic', (tester) async {
    final f = UiFakes();
    await f.settings.saveAi(const AiSettings(kind: AiProviderKind.anthropic));

    await tester.pumpWidget(f.app(const AiSettingsPage()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('sendingLine')), 200, scrollable: find.byType(Scrollable).first);

    expect(find.text('Sending: Snippet to api.anthropic.com'), findsOneWidget);
  });

  testWidgets('local OpenAI-compatible endpoint sends full text', (tester) async {
    final f = UiFakes();
    await f.settings.saveAi(const AiSettings(kind: AiProviderKind.openAiCompat, baseUrl: 'http://10.10.11.2:11434/v1', model: 'llama3.1:8b'));

    await tester.pumpWidget(f.app(const AiSettingsPage()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('sendingLine')), 200, scrollable: find.byType(Scrollable).first);

    expect(find.byKey(const Key('sendingLine')), findsOneWidget);
    expect(find.text('Sending: Full message text to 10.10.11.2 (local network)'), findsOneWidget);
  });

  test('privacySendingLine honours an explicit privacy level', () {
    const s = AiSettings(kind: AiProviderKind.anthropic, privacy: PrivacyLevel.headersOnly);
    expect(privacySendingLine(s), 'Sending: Headers only to api.anthropic.com');
    expect(privacySendingLine(const AiSettings()), 'Sending: nothing (AI sorting is off)');
  });
}

void keyRefreshTests() {
  testWidgets('saving a key rebuilds the backend and the page shows whether this device is ready', (tester) async {
    final f = UiFakes();
    await f.settings.saveAi(const AiSettings(kind: AiProviderKind.anthropic, model: 'claude-sonnet-5'));
    await tester.pumpWidget(f.app(const AiSettingsPage()));
    await tester.pumpAndSettle();
    expect(find.textContaining('no API key is saved here'), findsOneWidget);
    f.aiReadyModel = 'claude-sonnet-5';
    await tester.enterText(find.byKey(const Key('apiKey')), 'sk-ant-test');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(f.aiRefreshes, 1);
    expect(await f.creds.read(CredentialStore.aiApiKey(AiProviderKind.anthropic)), 'sk-ant-test');
    expect(find.textContaining('Ready on this device as claude-sonnet-5'), findsOneWidget);
  });
}
