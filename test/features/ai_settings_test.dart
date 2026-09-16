import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/features/settings/ai_settings_page.dart';
import 'package:sortie/features/settings/settings_common.dart';

import '../fakes/ui_fakes.dart';

void main() {
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
