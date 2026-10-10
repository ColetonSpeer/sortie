import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/features/message_view/html_body.dart';
import 'package:sortie/features/message_view/plain_text_view.dart';

/// Effective text colour of the first span whose text contains [needle].
Color? _spanColor(WidgetTester tester, Finder scope, String needle) {
  Color? found;
  void visit(InlineSpan span, Color? inherited) {
    final color = span.style?.color ?? inherited;
    if (found == null && span is TextSpan && (span.text ?? '').contains(needle)) found = color;
    span.visitDirectChildren((child) {
      visit(child, color);
      return found == null;
    });
  }

  for (final rich in tester.widgetList<RichText>(find.descendant(of: scope, matching: find.byType(RichText)))) {
    visit(rich.text, rich.text.style?.color);
    if (found != null) break;
  }
  return found;
}

void main() {
  testWidgets('dark-theme app renders author #222 text visibly on a white canvas', (tester) async {
    const body = MessageBody(text: 'Hello world', html: '<p style="color:#222">Hello world</p><p>Default text</p>');
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: SingleChildScrollView(
          child: MessageBodyView(body: body, allowRemoteImages: false, onRemoteImagesBlocked: (_) {}),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final canvas = find.byKey(MailCanvas.canvasKey);
    expect(tester.widget<Material>(canvas).color, MailCanvas.canvasColor);
    expect(DefaultTextStyle.of(tester.element(find.byType(SelectionArea).first)).style.color, MailCanvas.textColor);
    expect(_spanColor(tester, canvas, 'Hello world'), const Color(0xFF222222));
    expect(_spanColor(tester, canvas, 'Default text'), MailCanvas.textColor);
    // Fluid content gets no horizontal viewport of its own.
    expect(find.ancestor(of: canvas, matching: find.byType(SingleChildScrollView)), findsOneWidget);
  });

  testWidgets('wide fixed-width tables get a horizontal viewport', (tester) async {
    const body = MessageBody(text: '', html: '<table width="900"><tr><td>wide</td></tr></table>');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 400, child: MessageBodyView(body: body, allowRemoteImages: false, onRemoteImagesBlocked: (_) {})),
      ),
    ));
    await tester.pumpAndSettle();
    final scroll = tester.widget<SingleChildScrollView>(
      find.ancestor(of: find.byKey(MailCanvas.canvasKey), matching: find.byType(SingleChildScrollView)),
    );
    expect(scroll.scrollDirection, Axis.horizontal);
    expect(tester.getSize(find.byKey(MailCanvas.canvasKey)).width, 900 + 2 * MailCanvas.padding);
  });

  testWidgets('plain-text view shows quoted lines dimmed with a border', (tester) async {
    const text = 'Thanks!\n\n> quoted line one\n> quoted line two\n\nBye https://example.invalid/x';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PlainTextBodyView(text: text, onOpenUrl: (_) async {})),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(QuotedTextBlock), findsOneWidget);
    expect(find.descendant(of: find.byType(QuotedTextBlock), matching: find.textContaining('quoted line two')), findsOneWidget);
    expect(find.textContaining('Thanks!'), findsOneWidget);
    expect(find.textContaining('https://example.invalid/x'), findsOneWidget);
  });

  testWidgets('plainText mode shows the text alternative instead of HTML', (tester) async {
    const body = MessageBody(text: 'plain version', html: '<p>html version</p>');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MessageBodyView(body: body, allowRemoteImages: false, onRemoteImagesBlocked: (_) {}, mode: BodyViewMode.plainText)),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('plain version'), findsOneWidget);
    expect(find.byKey(MailCanvas.canvasKey), findsNothing);
  });

  test('parsePlainText joins format=flowed soft breaks and nests quote depth', () {
    final blocks = parsePlainText('This is a long \nflowed line \nending here.\n>> deep\n> shallow\nend');
    expect(blocks.map((b) => b.depth), [0, 2, 1, 0]);
    expect(blocks[0].text, 'This is a long flowed line ending here.');
    expect(blocks[1].text, 'deep');
  });
}
