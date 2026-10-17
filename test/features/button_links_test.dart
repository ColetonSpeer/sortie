import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/features/message_view/html/sanitizer.dart';
import 'package:sortie/features/message_view/html_body.dart';

/// The "bulletproof button" markup transactional mail uses: a coloured cell
/// whose only content is one link, here wrapped in an inline-block paragraph
/// as Anthropic's sign-in mail does.
const button = '<table width="600"><tr><td align="center" style="font-size:0px">'
    '<table role="presentation"><tr><td align="center" bgcolor="#141413" style="border-radius:10px">'
    '<p style="display:inline-block;font-size:13px;margin:0;padding:0">'
    '<a href="https://example.test/magic#a:b=" style="display:inline-block;padding:14px 36px;font-size:18px;color:white">Sign in</a>'
    '</p></td></tr></table></td></tr></table>';

String sanitized(String html) => HtmlSanitizer(viewportWidth: 800, contrastGuard: true).sanitize(html, inlineParts: const {}, allowRemoteImages: false).html;

void main() {
  group('lone link in a coloured cell', () {
    test('link and its inline wrappers become block-level', () {
      final out = sanitized(button);
      final a = RegExp(r'<a [^>]*>').firstMatch(out)!.group(0)!;
      final p = RegExp(r'<p [^>]*>').firstMatch(out)!.group(0)!;
      expect(a, contains('display:block'));
      expect(a, isNot(contains('inline-block')));
      expect(a, contains('padding:14px 36px'));
      expect(p, contains('display:block'));
    });

    test('links in running text and in plain cells are left alone', () {
      final text = sanitized('<p>Read the <a href="https://example.test/">docs</a> first.</p>');
      expect(text, isNot(contains('display:block')));
      final plainCell = sanitized('<table><tr><td><a href="https://example.test/">Home</a></td></tr></table>');
      expect(plainCell, isNot(contains('display:block')));
      final transparent = sanitized('<table><tr><td style="background:transparent"><a href="https://example.test/">Home</a></td></tr></table>');
      expect(transparent, isNot(contains('display:block')));
    });

    test('a cell with a link and other text is not a button', () {
      final out = sanitized('<table><tr><td bgcolor="#eee">Questions? <a href="https://example.test/">Contact us</a></td></tr></table>');
      expect(out, isNot(contains('display:block')));
    });

    testWidgets('tapping the bar away from the text opens the link', (t) async {
      t.view.physicalSize = const Size(1000, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessageBodyView(body: const MessageBody(text: '', html: button), allowRemoteImages: false, onRemoteImagesBlocked: (_) {}),
        ),
      ));
      await t.pump();
      final text = find.textContaining('Sign in', findRichText: true).first;
      final r = t.getRect(text);
      // The bar spans the cell; the text sits in its middle. Tap near the
      // left edge, well outside the text and its 36px padding.
      expect(r.width, greaterThan(400));
      await t.tapAt(Offset(r.left + 20, r.center.dy));
      await t.pump();
      expect(find.text('Open link?'), findsOneWidget);
    });
  });
}
