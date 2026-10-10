import 'package:html/dom.dart' as dom;

import 'css_color.dart';
import 'css_declarations.dart';

/// Keeps mail text readable on the white mail canvas.
///
/// Walks the tree tracking the effective background and text colour (author
/// colours composited over their ancestors, defaulting to the canvas).
/// Whenever an element's own `color` would fall below [minRatio] against the
/// effective background, the declaration is dropped so the inherited colour
/// applies; whenever an element sets a background that the inherited text
/// colour cannot be read on, a readable `color` is added. Readable author
/// colours are left alone. Dark-mode tricks that the renderer would get wrong
/// (`color-scheme`, `mix-blend-mode`, `filter: invert`, near-zero `opacity`
/// on text) are removed.
class ContrastGuard {
  const ContrastGuard({this.minRatio = 3.0, this.canvas = CssColor.white, this.defaultText = const CssColor(0x1f, 0x1f, 0x1f)});

  final double minRatio;
  final CssColor canvas;
  final CssColor defaultText;

  static const _bgProps = {'background', 'background-color'};

  void apply(dom.Element root) => _walk(root, canvas, defaultText);

  void _walk(dom.Element el, CssColor parentBg, CssColor parentFg) {
    final name = el.localName ?? '';
    var decls = parseDeclarations(el.attributes['style'] ?? '');
    final original = serializeDeclarations(decls);

    decls = _stripTricks(decls, el);

    final bgSet = backgroundOf(decls);
    final effBg = bgSet == null || bgSet.isTransparent ? parentBg : bgSet.over(parentBg);

    var fg = parentFg;
    final fgSet = colorOf(decls);
    var fgResolved = false;
    if (fgSet != null) {
      final candidate = fgSet.over(effBg);
      if (CssColor.contrast(candidate, effBg) >= minRatio) {
        fg = candidate;
        fgResolved = true;
      } else {
        decls = decls.where((d) => d.property != 'color').toList();
        el.attributes.remove('color');
      }
    }
    if (!fgResolved && CssColor.contrast(fg, effBg) < minRatio) {
      fg = CssColor.contrast(defaultText, effBg) >= CssColor.contrast(CssColor.white, effBg) ? defaultText : CssColor.white;
      decls = replaceDeclaration(decls, 'color', fg.toCss());
    }

    final updated = serializeDeclarations(decls);
    if (updated != original) {
      if (updated.isEmpty) {
        el.attributes.remove('style');
      } else {
        el.attributes['style'] = updated;
      }
    }
    if (name == 'script' || name == 'style') return;
    for (final child in el.children) {
      _walk(child, effBg, fg);
    }
  }

  List<CssDeclaration> _stripTricks(List<CssDeclaration> decls, dom.Element el) {
    bool? hasText;
    return decls.where((d) {
      switch (d.property) {
        case 'color-scheme':
        case 'mix-blend-mode':
        case '-webkit-filter':
          return false;
        case 'filter':
          return !d.value.toLowerCase().contains('invert');
        case 'opacity':
          final v = double.tryParse(d.value);
          if (v == null || v >= 0.3) return true;
          return !(hasText ??= el.text.trim().isNotEmpty);
        default:
          return true;
      }
    }).toList();
  }

  /// The last concrete `color` declaration, or null when none/`inherit`.
  static CssColor? colorOf(List<CssDeclaration> decls) {
    CssColor? out;
    for (final d in decls) {
      if (d.property != 'color') continue;
      final c = CssColor.parse(d.value);
      if (c != null) out = c;
    }
    return out;
  }

  /// The last background colour set through `background-color` or the
  /// `background` shorthand. `transparent`/`none` yield [CssColor.transparent].
  static CssColor? backgroundOf(List<CssDeclaration> decls) {
    CssColor? out;
    for (final d in decls) {
      if (!_bgProps.contains(d.property)) continue;
      final v = d.value.trim().toLowerCase();
      if (v == 'none' || v == 'transparent') {
        out = CssColor.transparent;
        continue;
      }
      if (d.property == 'background-color') {
        out = CssColor.parse(v) ?? out;
        continue;
      }
      // Shorthand: pick the first token that is a colour (the renderer keeps
      // the full value; we only need to know the colour it paints).
      CssColor? found;
      for (final token in splitValueTokens(v)) {
        found = CssColor.parse(token);
        if (found != null) break;
      }
      if (found != null) {
        out = found;
      } else if (!v.contains('url(') && !v.contains('gradient(')) {
        out = CssColor.transparent;
      }
    }
    return out;
  }
}
