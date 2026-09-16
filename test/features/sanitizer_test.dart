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
    final r = s.sanitize('<div style="background:url(http://t.invalid/x.png)">a</div><style>p{background:url("http://t.invalid/y.png")}</style>');
    expect(r.html, isNot(contains('t.invalid')));
  });
}
