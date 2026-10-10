import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:sortie/features/message_view/html/css_inliner.dart';

void main() {
  const inliner = CssInliner(viewportWidth: 600);

  String styleOf(String html, String selector) {
    final doc = html_parser.parse(html);
    inliner.apply(doc);
    return doc.querySelector(selector)?.attributes['style'] ?? '';
  }

  group('parseStylesheet', () {
    test('strips comments and parses rules, lists and !important', () {
      final rules = inliner.parseStylesheet('''
        /* header */ p, .lead { color: red; font-size: 14px !important }
        /* trailing comment { with brace } */
        a { color: blue; }
      ''');
      expect(rules.map((r) => r.selector), ['p', '.lead', 'a']);
      expect(rules[0].declarations.map((d) => d.toString()), ['color:red', 'font-size:14px !important']);
      expect(rules[1].declarations[1].important, isTrue);
      expect(rules[2].order, greaterThan(rules[1].order));
    });

    test('keeps screen/all/narrow media blocks, drops print, dark and wide ones', () {
      final rules = inliner.parseStylesheet('''
        @media print { p { color: print } }
        @media (prefers-color-scheme: dark) { p { color: dark } }
        @media only screen and (max-width: 600px) { p { color: mobile } }
        @media screen and (min-width: 480px) { p { color: tablet } }
        @media (min-width: 900px) { p { color: desktop } }
        @media screen { p { color: screen } }
        @media all { p { color: all } }
        p { color: plain }
      ''');
      expect(rules.map((r) => r.declarations.single.value), ['mobile', 'tablet', 'screen', 'all', 'plain']);
    });

    test('ignores @font-face, @import, @keyframes and unsupported properties', () {
      final rules = inliner.parseStylesheet('''
        @import url("https://fonts.invalid/x.css");
        @font-face { font-family: X; src: url(x.woff) }
        @keyframes spin { from { transform: rotate(0) } to { transform: rotate(360deg) } }
        p { position: absolute; animation: spin 1s; padding: 4px }
      ''');
      expect(rules, hasLength(1));
      expect(rules.single.declarations.map((d) => d.property), ['padding']);
    });

    test('computes specificity', () {
      expect(CssInliner.specificity('p'), 1);
      expect(CssInliner.specificity('.a'), 100);
      expect(CssInliner.specificity('#x'), 10000);
      expect(CssInliner.specificity('div p.a'), 102);
      expect(CssInliner.specificity('table td[valign]'), 102);
    });
  });

  group('apply', () {
    test('inlines class, id, tag, attribute and combinator selectors and removes <style>', () {
      final doc = html_parser.parse('''
        <style>
          .hero { color: #fff; background: #000 }
          #cta { font-weight: bold }
          table td { padding: 8px }
          div > p { line-height: 1.6 }
          img[width] { display: block }
          [data-role="x"] { text-align: center }
        </style>
        <div class="hero"><p id="cta">x</p></div>
        <table><tr><td>y</td></tr></table>
        <img width="10"><span data-role="x">z</span>
      ''');
      inliner.apply(doc);
      expect(doc.querySelectorAll('style'), isEmpty);
      expect(doc.querySelector('.hero')!.attributes['style'], 'color:#fff;background:#000');
      // Ascending specificity: `div > p` (2) is emitted before `#cta` (10000).
      expect(doc.querySelector('#cta')!.attributes['style'], 'line-height:1.6;font-weight:bold');
      expect(doc.querySelector('td')!.attributes['style'], 'padding:8px');
      expect(doc.querySelector('img')!.attributes['style'], 'display:block');
      expect(doc.querySelector('span')!.attributes['style'], 'text-align:center');
    });

    test('inline style wins unless the rule is !important', () {
      expect(styleOf('<style>p{font-size:18px;color:red}</style><p style="font-size:12px">x</p>', 'p'),
          'color:red;font-size:12px');
      expect(styleOf('<style>p{font-size:18px !important}</style><p style="font-size:12px">x</p>', 'p'), 'font-size:18px');
    });

    test('applies rules in specificity then source order', () {
      expect(styleOf('<style>.a{color:red} p{color:blue}</style><p class="a">x</p>', 'p'), 'color:red');
      expect(styleOf('<style>.a{color:red} .b{color:blue}</style><p class="a b">x</p>', 'p'), 'color:blue');
      expect(styleOf('<style>.b{color:blue} .a{color:red}</style><p class="a b">x</p>', 'p'), 'color:red');
      expect(styleOf('<style>p{color:blue !important} .a{color:red}</style><p class="a">x</p>', 'p'), 'color:blue');
    });

    test('skips pseudo-class and otherwise unsupported selectors without failing', () {
      final style = styleOf(
        '<style>a:hover{color:red} p::before{color:red} p:nth-child(2n+1){color:red} p ~ ~ {color:red} p{color:green}</style><p>x</p>',
        'p',
      );
      expect(style, 'color:green');
    });
  });
}
