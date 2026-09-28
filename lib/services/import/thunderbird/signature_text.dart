/// Converts an HTML signature to the plain text Sortie's composer appends.
/// Block elements and `<br>` become line breaks, tags are dropped and the
/// common entities decoded. Good enough for signatures; not a general HTML
/// renderer.
String htmlSignatureToText(String html) {
  var t = html;
  t = t.replaceAll(RegExp(r'<(script|style)[^>]*>.*?</\1>', caseSensitive: false, dotAll: true), '');
  t = t.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  t = t.replaceAll(RegExp(r'</(p|div|tr|li|h[1-6]|table|blockquote)>', caseSensitive: false), '\n');
  t = t.replaceAll(RegExp(r'<[^>]+>'), '');
  t = t
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m.group(1)!)))
      .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)));
  final lines = t.split('\n').map((l) => l.replaceAll(RegExp(r'[ \t]+'), ' ').trim()).toList();
  final out = <String>[];
  for (final l in lines) {
    if (l.isEmpty && (out.isEmpty || out.last.isEmpty)) continue;
    out.add(l);
  }
  while (out.isNotEmpty && out.last.isEmpty) {
    out.removeLast();
  }
  return out.join('\n');
}

/// Heuristic: does this signature file / text look like HTML?
bool looksLikeHtml(String text) => RegExp(r'<\s*(html|body|div|p|br|span|a|table|b|i|font)\b', caseSensitive: false).hasMatch(text);
