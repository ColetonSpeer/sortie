import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:sortie/features/message_view/html/contrast_guard.dart';
import 'package:sortie/features/message_view/html/css_color.dart';

void main() {
  group('CssColor.parse', () {
    test('hex forms', () {
      expect(CssColor.parse('#fff'), CssColor.white);
      expect(CssColor.parse('#1F1F1F'), const CssColor(0x1f, 0x1f, 0x1f));
      expect(CssColor.parse('#80808080')!.a, closeTo(0.5, 0.01));
      expect(CssColor.parse('#0008')!.a, closeTo(0.53, 0.01));
      expect(CssColor.parse('#12'), isNull);
    });

    test('rgb, rgba, hsl and percentages', () {
      expect(CssColor.parse('rgb(10, 20, 30)'), const CssColor(10, 20, 30));
      expect(CssColor.parse('rgba(0,0,0,0.5)'), const CssColor(0, 0, 0, 0.5));
      expect(CssColor.parse('rgb(100% 0% 0% / 50%)'), const CssColor(255, 0, 0, 0.5));
      expect(CssColor.parse('hsl(120, 100%, 25%)'), const CssColor(0, 128, 0));
      expect(CssColor.parse('hsla(0, 0%, 100%, 0)')!.isTransparent, isTrue);
    });

    test('named colours and keywords', () {
      expect(CssColor.parse('rebeccapurple'), const CssColor(0x66, 0x33, 0x99));
      expect(CssColor.parse('White'), CssColor.white);
      expect(CssColor.parse('transparent')!.isTransparent, isTrue);
      expect(CssColor.parse('inherit'), isNull);
      expect(CssColor.parse('currentcolor'), isNull);
      expect(CssColor.parse('var(--brand)'), isNull);
      expect(CssColor.parse('none'), isNull);
    });
  });

  group('contrast', () {
    test('known ratios', () {
      expect(CssColor.contrast(CssColor.black, CssColor.white), closeTo(21, 0.01));
      expect(CssColor.contrast(CssColor.white, CssColor.white), closeTo(1, 0.001));
      expect(CssColor.contrast(const CssColor(0x77, 0x77, 0x77), CssColor.white), closeTo(4.48, 0.02));
      expect(CssColor.contrast(const CssColor(0xff, 0, 0), CssColor.white), closeTo(4.0, 0.02));
    });

    test('alpha compositing', () {
      expect(const CssColor(0, 0, 0, 0.5).over(CssColor.white), const CssColor(128, 128, 128));
      expect(CssColor.transparent.over(CssColor.white), CssColor.white);
    });
  });

  group('ContrastGuard', () {
    String run(String html, String selector) {
      final doc = html_parser.parse(html);
      const ContrastGuard().apply(doc.body!);
      return doc.querySelector(selector)?.attributes['style'] ?? '';
    }

    test('drops invisible white-on-white text colour', () {
      expect(run('<p style="color:#fff">x</p>', 'p'), '');
      expect(run('<p style="font-size:12px;color:#ffffff">x</p>', 'p'), 'font-size:12px');
      expect(run('<p style="color:rgba(255,255,255,0.1)">x</p>', 'p'), '');
    });

    test('keeps readable author colours', () {
      expect(run('<p style="color:#333">x</p>', 'p'), 'color:#333');
      expect(run('<p style="color:#1a56c4">x</p>', 'p'), 'color:#1a56c4');
      expect(run('<div style="background:#000;color:#fff">x</div>', 'div'), 'background:#000;color:#fff');
    });

    test('adds a readable colour when a background hides the inherited text', () {
      expect(run('<table><tr><td style="background-color:#003366">x</td></tr></table>', 'td'), 'background-color:#003366;color:#ffffff');
      expect(run('<table><tr><td style="background:#eee url(x.png) no-repeat">x</td></tr></table>', 'td'), 'background:#eee url(x.png) no-repeat');
    });

    test('resolves nested backgrounds', () {
      const html = '<div id="o" style="background:#000"><div id="i" style="background:#fff"><p style="color:#222">x</p></div></div>';
      expect(run(html, '#o'), 'background:#000;color:#ffffff');
      expect(run(html, '#i'), 'background:#fff;color:#1f1f1f');
      expect(run(html, 'p'), 'color:#222');

      const table = '<table style="background:#000"><tr><td style="color:#fff">x</td></tr></table>';
      expect(run(table, 'td'), 'color:#fff');

      const translucent = '<div style="background:rgba(0,0,0,0.9)"><span style="color:#fff">x</span></div>';
      expect(run(translucent, 'span'), 'color:#fff');
    });

    test('transparent background inherits the parent canvas', () {
      expect(run('<div style="background:transparent"><p style="color:#fff">x</p></div>', 'p'), '');
      expect(run('<div style="background:none;color:#fff">x</div>', 'div'), 'background:none');
    });

    test('strips dark-scheme tricks and near-invisible opacity on text', () {
      expect(
        run('<p style="color-scheme:dark;mix-blend-mode:difference;filter:invert(1);opacity:0.1;color:#222">x</p>', 'p'),
        'color:#222',
      );
      expect(run('<p style="opacity:0.8;filter:blur(1px)">x</p>', 'p'), 'opacity:0.8;filter:blur(1px)');
    });
  });
}
