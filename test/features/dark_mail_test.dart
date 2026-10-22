import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/features/message_view/html/css_color.dart';
import 'package:sortie/features/message_view/html/dark_mail.dart';
import 'package:sortie/features/message_view/html/sanitizer.dart';
import 'package:sortie/features/message_view/html_body.dart';

const mail = '<div style="background:#ffffff;color:#000000">'
    '<table><tr><td style="background-color:#f4f4f4;border:1px solid #dddddd;color:#333333">Status</td>'
    '<td style="background-color:#2e7d32;color:#ffffff">UP</td>'
    '<td style="background-color:#ffe6e6"><a href="https://x" style="color:#1a56c4">link</a></td></tr></table></div>';

void main() {
  const a = DarkMailAdapter();
  double lum(CssColor c) => c.luminance;

  group('DarkMailAdapter colours', () {
    test('light greys go dark, dark greys stay', () {
      expect(lum(a.background(CssColor.white)), lessThan(0.05));
      expect(lum(a.background(const CssColor(0xf4, 0xf4, 0xf4))), lessThan(0.06));
      expect(a.background(const CssColor(0x22, 0x22, 0x22)), const CssColor(0x22, 0x22, 0x22));
    });
    test('dark text turns light, light text turns dark, saturated fills are kept', () {
      expect(lum(a.foreground(CssColor.black)), greaterThan(0.9));
      expect(lum(a.foreground(const CssColor(0x33, 0x33, 0x33))), greaterThan(0.5));
      expect(lum(a.foreground(const CssColor(0xee, 0xee, 0xee))), lessThan(0.02));
      expect(a.background(const CssColor(0x2e, 0x7d, 0x32)), const CssColor(0x2e, 0x7d, 0x32), reason: 'brand green stays');
      expect(a.foreground(const CssColor(0xff, 0xb3, 0x66)), const CssColor(0xff, 0xb3, 0x66), reason: 'a bright accent stays');
    });
    test('pastel tints are deepened and dark accents lifted', () {
      final pastel = a.background(const CssColor(0xff, 0xe6, 0xe6));
      expect(lum(pastel), lessThan(0.08));
      expect(pastel.r, greaterThan(pastel.g), reason: 'still reddish');
      final link = a.foreground(const CssColor(0x1a, 0x56, 0xc4));
      expect(lum(link), greaterThan(lum(const CssColor(0x1a, 0x56, 0xc4))));
      expect(link.b, greaterThan(link.r), reason: 'still blue');
    });
  });

  test('dark canvas sanitising recolours a light mail; light mode leaves it alone', () {
    final light = const HtmlSanitizer(darkCanvas: false).sanitize(mail, inlineParts: const {}, allowRemoteImages: false).html;
    expect(light, contains('background:#ffffff'));
    final dark = const HtmlSanitizer(darkCanvas: true).sanitize(mail, inlineParts: const {}, allowRemoteImages: false).html;
    expect(dark, isNot(contains('#ffffff;color:#000000')));
    expect(dark, contains('background-color:#2e7d32'), reason: 'the brand fill survives');
    expect(dark.toLowerCase(), isNot(contains('color:#000000')));
  });

  for (final (name, brightness, mode, expected) in [
    ('dark theme', Brightness.dark, BodyViewMode.html, MailCanvas.darkCanvasColor),
    ('dark theme, original formatting', Brightness.dark, BodyViewMode.original, MailCanvas.canvasColor),
    ('light theme', Brightness.light, BodyViewMode.html, MailCanvas.canvasColor),
  ]) {
    testWidgets('canvas colour: $name', (t) async {
      await t.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(body: MessageBodyView(body: const MessageBody(text: 'x', html: mail), allowRemoteImages: false, mode: mode, onRemoteImagesBlocked: (_) {})),
      ));
      await t.pump();
      final m = t.widget<Material>(find.byKey(MailCanvas.canvasKey));
      expect(m.color, expected);
    });
  }
}
