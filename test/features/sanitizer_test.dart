import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/features/message_view/html/sanitizer.dart';

void main() {
  const s = HtmlSanitizer();

  test('strips scripts, iframes, forms, meta refresh and event handlers', () {
    final r = s.sanitize('''
      <meta http-equiv="refresh" content="0;url=http://evil.invalid">
      <script>alert(1)</script>
      <iframe src="http://evil.invalid"></iframe>
      <form action="http://evil.invalid"><input name="pw"></form>
      <p onclick="steal()" style="color:red">Hello <a href="javascript:alert(1)">x</a> <a href="https://ok.invalid">ok</a></p>
    ''');
    expect(r.html, isNot(contains('<script')));
    expect(r.html, isNot(contains('<iframe')));
    expect(r.html, isNot(contains('<form')));
    expect(r.html, isNot(contains('http-equiv')));
    expect(r.html, isNot(contains('onclick')));
    expect(r.html, isNot(contains('javascript:')));
    expect(r.html, contains('https://ok.invalid'));
    expect(r.html, contains('color:red'));
  });

  test('blocks remote images unless allowed and inlines cid parts', () {
    const html = '<img src="https://track.invalid/p.gif"><img src="cid:logo@x" alt="logo">';
    final blocked = s.sanitize(html, inlineParts: {'logo@x': [0x89, 0x50, 0x4E, 0x47]});
    expect(blocked.blockedRemoteImages, isTrue);
    expect(blocked.remoteImageCount, 1);
    expect(blocked.html, isNot(contains('track.invalid')));
    expect(blocked.html, contains('data:image/png;base64,'));

    final allowed = s.sanitize(html, allowRemoteImages: true);
    expect(allowed.blockedRemoteImages, isFalse);
    expect(allowed.html, contains('https://track.invalid/p.gif'));
  });

  test('scrubs remote url() from css', () {
    final r = s.sanitize('<div style="background:url(http://t.invalid/x.png)">a</div><style>p{background:url("http://t.invalid/y.png")}</style><p>b</p>');
    expect(r.html, isNot(contains('t.invalid')));
    expect(r.html, isNot(contains('<style')));
  });

  test('inlines <style> rules before scrubbing and applies the contrast guard', () {
    final r = s.sanitize('''
      <html><head><style>
        .hero { background: #003366; font-size: 20px }
        .ghost { color: #fff }
        @media (prefers-color-scheme: dark) { .hero { background: #000; color: #fff } }
      </style></head><body>
        <div class="hero">Header</div>
        <p class="ghost">invisible</p>
      </body></html>
    ''');
    expect(r.html, contains('background:#003366;font-size:20px;color:#ffffff'));
    expect(r.html, contains('<p class="ghost">invisible</p>'));
    expect(r.html, isNot(contains('#000')));
  });

  test('original formatting keeps author colours', () {
    final r = const HtmlSanitizer(contrastGuard: false).sanitize('<p style="color:#fff">x</p>');
    expect(r.html, contains('color:#fff'));
  });

  test('converts presentational attributes and measures content width', () {
    final r = s.sanitize('''
      <body bgcolor="#222222" text="#eeeeee">
        <center><table width="640" bgcolor="#ffffff"><tr><td width="50%" height="20" align="right">x</td></tr></table></center>
        <font color="#ff0000">red</font>
        <img src="data:image/png;base64,AA==" width="800" height="100">
      </body>
    ''');
    expect(r.contentWidth, 800);
    expect(r.html, contains('data-mail-body'));
    expect(r.html, contains('background-color:#222222;color:#eeeeee'));
    expect(r.html, contains('<center style="display:block;text-align:center">'));
    expect(r.html, contains('<table width="640" style="background-color:#ffffff;width:640px;color:#1f1f1f"'));
    expect(r.html, contains('style="text-align:right;width:50%;height:20px"'));
    expect(r.html, contains('<font style="color:#ff0000">'));
    expect(r.html, contains('max-width:100%;height:auto'));
    expect(r.html, isNot(contains('bgcolor')));
  });
}
