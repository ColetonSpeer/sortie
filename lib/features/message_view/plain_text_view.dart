import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// One run of consecutive lines sharing a quote depth.
class PlainTextBlock {
  const PlainTextBlock(this.depth, this.lines);
  final int depth;
  final List<String> lines;
  String get text => lines.join('\n');
}

/// Splits plain mail text into quote-depth blocks. Soft line breaks from
/// `format=flowed` bodies (lines ending in a space) are joined first.
List<PlainTextBlock> parsePlainText(String text) {
  final raw = text.replaceAll('\r\n', '\n').split('\n');
  final flowed = _looksFlowed(raw);
  final blocks = <PlainTextBlock>[];
  var pending = StringBuffer();
  var pendingSoft = false;
  int? pendingDepth;

  void flushLine() {
    if (pendingDepth == null) return;
    final line = pending.toString();
    if (blocks.isNotEmpty && blocks.last.depth == pendingDepth) {
      blocks.last.lines.add(line);
    } else {
      blocks.add(PlainTextBlock(pendingDepth!, [line]));
    }
    pending = StringBuffer();
    pendingSoft = false;
    pendingDepth = null;
  }

  for (final rawLine in raw) {
    var depth = 0;
    var line = rawLine;
    while (true) {
      final m = RegExp(r'^\s{0,1}>').firstMatch(line);
      if (m == null) break;
      depth++;
      line = line.substring(m.end);
    }
    if (depth > 0 && line.startsWith(' ')) line = line.substring(1);
    if (flowed && line.startsWith(' ')) line = line.substring(1); // space-stuffing
    final soft = flowed && line.endsWith(' ') && line.trim() != '--';
    if (pendingSoft && pendingDepth == depth) {
      pending.write(line);
    } else {
      flushLine();
      pendingDepth = depth;
      pending.write(line);
    }
    pendingSoft = soft;
    if (!soft) flushLine();
  }
  flushLine();
  return blocks;
}

bool _looksFlowed(List<String> lines) {
  var soft = 0;
  for (var i = 0; i < lines.length - 1; i++) {
    final l = lines[i];
    if (l.endsWith(' ') && l.trim().isNotEmpty && lines[i + 1].trim().isNotEmpty) soft++;
  }
  return soft >= 2;
}

final _urlPattern = RegExp(r'''(https?://[^\s<>"'()]+[^\s<>"'().,;:!?])|(www\.[^\s<>"'()]+[^\s<>"'().,;:!?])|([\w.+-]+@[\w-]+(?:\.[\w-]+)+)''');

/// Proportional plain-text body: wraps long lines, preserves breaks, makes
/// URLs tappable and dims quoted (`>`) lines behind a left border.
class PlainTextBodyView extends StatefulWidget {
  const PlainTextBodyView({super.key, required this.text, required this.onOpenUrl});
  final String text;
  final Future<void> Function(String url) onOpenUrl;

  @override
  State<PlainTextBodyView> createState() => _PlainTextBodyViewState();
}

class _PlainTextBodyViewState extends State<PlainTextBodyView> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium!.copyWith(height: 1.45);
    final blocks = parsePlainText(widget.text);
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final b in blocks)
            b.depth == 0
                ? Text.rich(_linkify(b.text, base, theme.colorScheme.primary))
                : QuotedTextBlock(depth: b.depth, child: Text.rich(_linkify(b.text, base.copyWith(color: theme.colorScheme.onSurfaceVariant), theme.colorScheme.primary))),
        ],
      ),
    );
  }

  TextSpan _linkify(String text, TextStyle style, Color linkColor) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _urlPattern.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      final raw = m.group(0)!;
      final url = m.group(3) != null ? 'mailto:$raw' : (raw.startsWith('www.') ? 'https://$raw' : raw);
      final rec = TapGestureRecognizer()..onTap = () => widget.onOpenUrl(url);
      _recognizers.add(rec);
      spans.add(TextSpan(text: raw, style: TextStyle(color: linkColor, decoration: TextDecoration.underline), recognizer: rec));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return TextSpan(style: style, children: spans);
  }
}

/// A quoted run of lines: dimmed, behind a left border per quote level.
class QuotedTextBlock extends StatelessWidget {
  const QuotedTextBlock({super.key, required this.depth, required this.child});
  final int depth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: EdgeInsets.only(left: 10.0 + (depth - 1) * 8.0),
      decoration: BoxDecoration(border: Border(left: BorderSide(color: cs.outlineVariant, width: 2.0 * depth.clamp(1, 3)))),
      child: child,
    );
  }
}
