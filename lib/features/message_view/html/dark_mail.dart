import 'dart:math' as math;

import 'package:html/dom.dart' as dom;

import 'css_color.dart';
import 'css_declarations.dart';

/// Re-colours a light mail for a dark page the way mail apps' dark modes do:
/// light, greyish backgrounds become dark greys, dark text becomes light,
/// saturated brand colours stay (pastel backgrounds are deepened, dark
/// accent text is lifted so it stays readable). Images are untouched.
class DarkMailAdapter {
  const DarkMailAdapter({this.canvas = DarkMailAdapter.darkCanvas});

  static const darkCanvas = CssColor(0x1c, 0x1c, 0x1e);

  /// Default text on [darkCanvas] (matches MailCanvas.darkTextFlutterColor).
  static const darkText = CssColor(0xe6, 0xe6, 0xe6);
  static const _colorProps = {'color', 'background-color', 'border-color', 'border-top-color', 'border-bottom-color', 'border-left-color', 'border-right-color'};
  static const _shorthandProps = {'background', 'border', 'border-top', 'border-bottom', 'border-left', 'border-right'};

  final CssColor canvas;

  void apply(dom.Element root) {
    _visit(root, false);
  }

  /// [onKeptFill]: the effective background is a saturated author colour
  /// that was left as is, so its text must be left as is too (white on a
  /// green status bar stays white).
  void _visit(dom.Element el, bool onKeptFill) {
    final name = el.localName ?? '';
    if (name == 'style' || name == 'script') return;
    var keptFill = onKeptFill;
    final raw = el.attributes['style'];
    if (raw != null && raw.isNotEmpty) {
      final decls = parseDeclarations(raw);
      final out = <CssDeclaration>[];
      var changed = false;
      // Backgrounds first: they decide how this element's text is treated.
      for (final d in decls) {
        final p = d.property;
        if (p == 'background-color') {
          final c = CssColor.parse(d.value);
          if (c != null) keptFill = !c.isTransparent && isKeptFill(c);
        } else if (p == 'background') {
          for (final t in splitValueTokens(d.value)) {
            final c = CssColor.parse(t);
            if (c != null) {
              keptFill = !c.isTransparent && isKeptFill(c);
              break;
            }
          }
        }
      }
      for (final d in decls) {
        final p = d.property;
        if (_colorProps.contains(p)) {
          final c = CssColor.parse(d.value);
          if (c != null && !c.isTransparent) {
            final m = p == 'color' ? (keptFill ? c : foreground(c)) : (p == 'background-color' ? background(c) : border(c));
            out.add(CssDeclaration(p, m.toCss(), important: d.important));
            changed = true;
            continue;
          }
        } else if (_shorthandProps.contains(p)) {
          final tokens = splitValueTokens(d.value);
          var any = false;
          final mapped = tokens.map((t) {
            final c = CssColor.parse(t);
            if (c == null || c.isTransparent) return t;
            any = true;
            return (p == 'background' ? background(c) : border(c)).toCss();
          }).toList();
          if (any) {
            out.add(CssDeclaration(p, mapped.join(' '), important: d.important));
            changed = true;
            continue;
          }
        }
        out.add(d);
      }
      if (changed) el.attributes['style'] = serializeDeclarations(out);
    }
    for (final child in el.children) {
      _visit(child, keptFill);
    }
  }

  /// A saturated fill that [background] leaves alone.
  bool isKeptFill(CssColor c) {
    final (_, s, l) = _hsl(c);
    return s >= 0.2 && l <= 0.8;
  }

  // ------------------------------------------------------------- mapping

  /// Backgrounds: light greys go dark (white -> the canvas), dark ones stay,
  /// pastel brand tints are deepened, saturated fills are kept.
  CssColor background(CssColor c) {
    final (h, s, l) = _hsl(c);
    if (s < 0.2) {
      if (l <= 0.5) return c;
      final nl = 0.11 + (1 - l) * 0.55; // 1.0 -> 0.11, 0.9 -> 0.165, 0.6 -> 0.33
      return _fromHsl(h, s, nl, c.a);
    }
    if (l > 0.8) return _fromHsl(h, math.min(s, 0.6), 0.22, c.a);
    return c;
  }

  /// Text: dark greys become light, light greys become dark (they were on a
  /// light page), dark accents are lifted to stay readable on the canvas.
  CssColor foreground(CssColor c) {
    final (h, s, l) = _hsl(c);
    if (s < 0.2) return _fromHsl(h, s, 1 - l, c.a);
    if (l < 0.55) return _fromHsl(h, s, math.max(l, 0.68), c.a);
    return c;
  }

  CssColor border(CssColor c) {
    final (h, s, l) = _hsl(c);
    if (s < 0.2) return _fromHsl(h, s, l > 0.5 ? 0.28 : math.max(l, 0.3), c.a);
    return c;
  }

  static (double, double, double) _hsl(CssColor c) {
    final r = c.r / 255, g = c.g / 255, b = c.b / 255;
    final max = math.max(r, math.max(g, b)), min = math.min(r, math.min(g, b));
    final l = (max + min) / 2;
    if (max == min) return (0, 0, l);
    final d = max - min;
    final s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    double h;
    if (max == r) {
      h = (g - b) / d + (g < b ? 6 : 0);
    } else if (max == g) {
      h = (b - r) / d + 2;
    } else {
      h = (r - g) / d + 4;
    }
    return (h / 6, s, l);
  }

  static CssColor _fromHsl(double h, double s, double l, double a) {
    l = l.clamp(0.0, 1.0);
    if (s == 0) {
      final v = (l * 255).round();
      return CssColor(v, v, v, a);
    }
    double hue(double p, double q, double t) {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1 / 6) return p + (q - p) * 6 * t;
      if (t < 1 / 2) return q;
      if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
      return p;
    }
    final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    final p = 2 * l - q;
    return CssColor((hue(p, q, h + 1 / 3) * 255).round(), (hue(p, q, h) * 255).round(), (hue(p, q, h - 1 / 3) * 255).round(), a);
  }
}
