import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

/// Turns a mail body into short, safe classifier input: HTML -> text, quoted
/// replies and signatures removed, URLs collapsed, secrets redacted.
abstract final class TextCleaner {
  static const _dropTags = {'script', 'style', 'head', 'noscript', 'template', 'svg', 'iframe', 'object'};
  static const _blockTags = {
    'p', 'div', 'br', 'li', 'tr', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'blockquote', 'pre', 'table', 'ul', 'ol',
    'section', 'article', 'header', 'footer', 'hr', 'dd', 'dt', 'address',
  };

  /// Full pipeline. Prefers [text]; derives from [html] when text is empty.
  static String clean(String? text, {String? html, bool redact = false}) {
    var t = (text ?? '').trim();
    if (t.isEmpty && html != null && html.isNotEmpty) t = htmlToText(html);
    if (looksLikeHtml(t)) t = htmlToText(t);
    t = stripQuotedReplies(t);
    t = stripSignature(t);
    t = collapseUrls(t);
    t = normalizeWhitespace(t);
    if (redact) t = redactSecrets(t);
    return t;
  }

  static bool looksLikeHtml(String s) =>
      RegExp(r'<\s*(html|body|div|p|br|table|span|a)\b', caseSensitive: false).hasMatch(s);

  static String htmlToText(String html) {
    final doc = html_parser.parse(html);
    final buf = StringBuffer();
    _walk(doc.body ?? doc.documentElement!, buf);
    return normalizeWhitespace(buf.toString());
  }

  static void _walk(Node node, StringBuffer out) {
    for (final child in node.nodes) {
      if (child is Text) {
        out.write(child.text.replaceAll(RegExp(r'\s+'), ' '));
      } else if (child is Element) {
        final tag = child.localName ?? '';
        if (_dropTags.contains(tag)) continue;
        if (tag == 'img') {
          if (_isTrackingPixel(child)) continue;
          final alt = child.attributes['alt']?.trim();
          if (alt != null && alt.isNotEmpty) out.write(' [$alt] ');
          continue;
        }
        if (child.attributes['aria-hidden'] == 'true' ||
            RegExp(r'display\s*:\s*none', caseSensitive: false).hasMatch(child.attributes['style'] ?? '')) {
          continue;
        }
        if (tag == 'a') {
          final inner = StringBuffer();
          _walk(child, inner);
          final href = (child.attributes['href'] ?? '').trim();
          final text = inner.toString().trim();
          out.write(text);
          if (href.startsWith(RegExp('https?://', caseSensitive: false)) && !text.contains(href)) out.write(' ($href)');
          continue;
        }
        final block = _blockTags.contains(tag);
        if (block) out.write('\n');
        if (tag == 'blockquote') {
          final inner = StringBuffer();
          _walk(child, inner);
          for (final line in inner.toString().split('\n')) {
            if (line.trim().isNotEmpty) out.write('> $line\n');
          }
        } else {
          _walk(child, out);
        }
        if (block) out.write('\n');
      }
    }
  }

  static bool _isTrackingPixel(Element img) {
    int? dim(String a) => int.tryParse((img.attributes[a] ?? '').replaceAll('px', '').trim());
    final w = dim('width'), h = dim('height');
    return (w != null && w <= 2) || (h != null && h <= 2);
  }

  static final _quoteMarkers = [
    RegExp(r'^\s*-{2,}\s*Original Message\s*-{2,}\s*$', multiLine: true, caseSensitive: false),
    RegExp(r'^\s*-{2,}\s*Forwarded message\s*-{2,}\s*$', multiLine: true, caseSensitive: false),
    RegExp(r'^\s*Begin forwarded message:\s*$', multiLine: true, caseSensitive: false),
    RegExp(r'^\s*On [^\n]{3,200}?\bwrote:\s*$', multiLine: true),
    RegExp(r'^\s*On [^\n]{3,120}\n[^\n]{0,120}\bwrote:\s*$', multiLine: true),
    RegExp(r'^\s*Le [^\n]{3,200}? a écrit\s*:\s*$', multiLine: true),
    RegExp(r'^\s*Am [^\n]{3,200}? schrieb [^\n]{1,80}:\s*$', multiLine: true),
    RegExp(r'^\s*From:\s[^\n]+\n(?:[^\n]*\n){0,3}?\s*(?:Sent|Date):\s[^\n]+\n(?:[^\n]*\n){0,3}?\s*(?:To|Subject):', multiLine: true),
  ];

  /// Drops `>` lines and everything after the first reply/forward marker.
  static String stripQuotedReplies(String text) {
    var cut = text.length;
    for (final re in _quoteMarkers) {
      final m = re.firstMatch(text);
      if (m != null && m.start < cut) cut = m.start;
    }
    var t = text.substring(0, cut);
    final lines = t.split('\n').where((l) => !l.trimLeft().startsWith('>')).toList();
    t = lines.join('\n');
    return t.trimRight();
  }

  /// Cuts at the standard `-- ` signature separator.
  static String stripSignature(String text) {
    final m = RegExp(r'^-- ?$', multiLine: true).firstMatch(text);
    return m == null ? text : text.substring(0, m.start).trimRight();
  }

  /// `https://x.example.com/a/b?c=d` -> `https://x.example.com/…`.
  static String collapseUrls(String text) => text.replaceAllMapped(
        RegExp(r'\b(https?)://([^\s/<>"\)\]]+)(/[^\s<>"\)\]]*)?', caseSensitive: false),
        (m) => '${m.group(1)!.toLowerCase()}://${m.group(2)!.toLowerCase()}/…',
      );

  static String normalizeWhitespace(String text) {
    var t = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    t = t.replaceAll(RegExp(r'[ \t ]+'), ' ');
    t = t.replaceAll(RegExp(r' *\n *'), '\n');
    t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return t.trim();
  }

  /// Verification codes -> [CODE], long digit runs -> [NUM], long mixed
  /// alphanumeric tokens -> [TOKEN].
  static String redactSecrets(String text) {
    var t = text;
    final codeWords = RegExp(r'\b(code|OTP|one-time|verification|verify|PIN|passcode)\b', caseSensitive: false);
    final digits = RegExp(r'(?<![\d.])\d{4,8}(?!\d)');
    final protectedRanges = <(int, int)>[];
    t = t.replaceAllMapped(digits, (m) {
      final from = (m.start - 40).clamp(0, t.length);
      final to = (m.end + 40).clamp(0, t.length);
      final window = t.substring(from, to);
      if (codeWords.hasMatch(window) && !_looksLikeYear(m.group(0)!)) {
        protectedRanges.add((m.start, m.end));
        return '[CODE]';
      }
      return m.group(0)!;
    });
    t = t.replaceAllMapped(RegExp(r'(?<![\w/])([A-Za-z0-9_\-]{20,})(?![\w/])'), (m) {
      final s = m.group(1)!;
      final hasLetter = RegExp('[A-Za-z]').hasMatch(s), hasDigit = RegExp(r'\d').hasMatch(s);
      return hasLetter && hasDigit ? '[TOKEN]' : s;
    });
    t = t.replaceAll(RegExp(r'\d[\d \-]{6,}\d'), '[NUM]');
    t = t.replaceAll(RegExp(r'\d{8,}'), '[NUM]');
    return t;
  }

  static bool _looksLikeYear(String s) => s.length == 4 && s.startsWith(RegExp('19|20'));

  /// Hard cap without splitting a word when possible.
  static String truncate(String s, int max) {
    if (s.length <= max) return s;
    final cut = s.lastIndexOf(RegExp(r'\s'), max);
    return '${s.substring(0, cut > max ~/ 2 ? cut : max).trimRight()}…';
  }
}
