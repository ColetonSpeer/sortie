import 'dart:math' as math;

/// An sRGB colour with alpha, parsed from CSS. Pure Dart.
class CssColor {
  const CssColor(this.r, this.g, this.b, [this.a = 1.0]);

  final int r, g, b;

  /// 0 (transparent) .. 1 (opaque).
  final double a;

  static const white = CssColor(255, 255, 255);
  static const black = CssColor(0, 0, 0);
  static const transparent = CssColor(0, 0, 0, 0);

  bool get isTransparent => a <= 0.001;
  bool get isOpaque => a >= 0.999;

  /// Parses `#rgb`, `#rgba`, `#rrggbb`, `#rrggbbaa`, `rgb()`, `rgba()`,
  /// `hsl()`, `hsla()`, named colours and `transparent`.
  ///
  /// Returns null for anything that is not a concrete colour, including
  /// `inherit`, `currentcolor`, `initial`, `unset`, `none` and `var(...)`.
  static CssColor? parse(String? input) {
    if (input == null) return null;
    final s = input.trim().toLowerCase();
    if (s.isEmpty) return null;
    if (s == 'transparent') return transparent;
    if (s.startsWith('#')) return _hex(s.substring(1));
    final fn = RegExp(r'^(rgba?|hsla?)\s*\((.*)\)$').firstMatch(s);
    if (fn != null) {
      final args = fn.group(2)!.replaceAll('/', ' ').split(RegExp(r'[\s,]+')).where((t) => t.isNotEmpty).toList();
      if (args.length < 3) return null;
      final alpha = args.length > 3 ? _alpha(args[3]) : 1.0;
      if (alpha == null) return null;
      if (fn.group(1)!.startsWith('rgb')) {
        final c = [for (final t in args.take(3)) _channel(t)];
        if (c.any((v) => v == null)) return null;
        return CssColor(c[0]!, c[1]!, c[2]!, alpha);
      }
      final h = double.tryParse(args[0].replaceAll('deg', ''));
      final sat = _percent(args[1]), light = _percent(args[2]);
      if (h == null || sat == null || light == null) return null;
      return _fromHsl(h, sat, light, alpha);
    }
    final named = _named[s];
    if (named == null) return null;
    return CssColor((named >> 16) & 0xff, (named >> 8) & 0xff, named & 0xff);
  }

  static CssColor? _hex(String h) {
    if (!RegExp(r'^[0-9a-f]+$').hasMatch(h)) return null;
    String ch(int i) => h.length <= 4 ? h[i] * 2 : h.substring(i * 2, i * 2 + 2);
    int v(int i) => int.parse(ch(i), radix: 16);
    switch (h.length) {
      case 3:
        return CssColor(v(0), v(1), v(2));
      case 4:
        return CssColor(v(0), v(1), v(2), v(3) / 255);
      case 6:
        return CssColor(v(0), v(1), v(2));
      case 8:
        return CssColor(v(0), v(1), v(2), v(3) / 255);
      default:
        return null;
    }
  }

  static int? _channel(String t) {
    if (t.endsWith('%')) {
      final p = double.tryParse(t.substring(0, t.length - 1));
      return p == null ? null : (p * 2.55).round().clamp(0, 255);
    }
    return double.tryParse(t)?.round().clamp(0, 255);
  }

  static double? _alpha(String t) {
    if (t.endsWith('%')) {
      final p = double.tryParse(t.substring(0, t.length - 1));
      return p == null ? null : (p / 100).clamp(0.0, 1.0);
    }
    return double.tryParse(t)?.clamp(0.0, 1.0);
  }

  static double? _percent(String t) {
    final v = double.tryParse(t.replaceAll('%', ''));
    return v == null ? null : (v / 100).clamp(0.0, 1.0);
  }

  static CssColor _fromHsl(double h, double s, double l, double a) {
    final hue = ((h % 360) + 360) % 360 / 360;
    double f(double p, double q, double t) {
      var tt = t;
      if (tt < 0) tt += 1;
      if (tt > 1) tt -= 1;
      if (tt < 1 / 6) return p + (q - p) * 6 * tt;
      if (tt < 1 / 2) return q;
      if (tt < 2 / 3) return p + (q - p) * (2 / 3 - tt) * 6;
      return p;
    }

    if (s == 0) {
      final v = (l * 255).round();
      return CssColor(v, v, v, a);
    }
    final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    final p = 2 * l - q;
    return CssColor(
      (f(p, q, hue + 1 / 3) * 255).round(),
      (f(p, q, hue) * 255).round(),
      (f(p, q, hue - 1 / 3) * 255).round(),
      a,
    );
  }

  /// This colour painted over an opaque [bg].
  CssColor over(CssColor bg) {
    if (isOpaque) return this;
    if (isTransparent) return bg;
    int mix(int top, int bottom) => (top * a + bottom * (1 - a)).round().clamp(0, 255);
    return CssColor(mix(r, bg.r), mix(g, bg.g), mix(b, bg.b));
  }

  /// WCAG relative luminance (0 black .. 1 white).
  double get luminance {
    double lin(int c) {
      final v = c / 255;
      return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
  }

  /// WCAG contrast ratio, 1 (identical) .. 21 (black on white).
  static double contrast(CssColor a, CssColor b) {
    final la = a.luminance, lb = b.luminance;
    final hi = math.max(la, lb), lo = math.min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
  }

  String toCss() => isOpaque
      ? '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
      : 'rgba($r,$g,$b,${a.toStringAsFixed(2)})';

  @override
  String toString() => toCss();

  @override
  bool operator ==(Object other) => other is CssColor && other.r == r && other.g == g && other.b == b && (other.a - a).abs() < 0.005;

  @override
  int get hashCode => Object.hash(r, g, b, (a * 255).round());

  static const _named = <String, int>{
    'aliceblue': 0xf0f8ff, 'antiquewhite': 0xfaebd7, 'aqua': 0x00ffff, 'aquamarine': 0x7fffd4, 'azure': 0xf0ffff,
    'beige': 0xf5f5dc, 'bisque': 0xffe4c4, 'black': 0x000000, 'blanchedalmond': 0xffebcd, 'blue': 0x0000ff,
    'blueviolet': 0x8a2be2, 'brown': 0xa52a2a, 'burlywood': 0xdeb887, 'cadetblue': 0x5f9ea0, 'chartreuse': 0x7fff00,
    'chocolate': 0xd2691e, 'coral': 0xff7f50, 'cornflowerblue': 0x6495ed, 'cornsilk': 0xfff8dc, 'crimson': 0xdc143c,
    'cyan': 0x00ffff, 'darkblue': 0x00008b, 'darkcyan': 0x008b8b, 'darkgoldenrod': 0xb8860b, 'darkgray': 0xa9a9a9,
    'darkgreen': 0x006400, 'darkgrey': 0xa9a9a9, 'darkkhaki': 0xbdb76b, 'darkmagenta': 0x8b008b,
    'darkolivegreen': 0x556b2f, 'darkorange': 0xff8c00, 'darkorchid': 0x9932cc, 'darkred': 0x8b0000,
    'darksalmon': 0xe9967a, 'darkseagreen': 0x8fbc8f, 'darkslateblue': 0x483d8b, 'darkslategray': 0x2f4f4f,
    'darkslategrey': 0x2f4f4f, 'darkturquoise': 0x00ced1, 'darkviolet': 0x9400d3, 'deeppink': 0xff1493,
    'deepskyblue': 0x00bfff, 'dimgray': 0x696969, 'dimgrey': 0x696969, 'dodgerblue': 0x1e90ff, 'firebrick': 0xb22222,
    'floralwhite': 0xfffaf0, 'forestgreen': 0x228b22, 'fuchsia': 0xff00ff, 'gainsboro': 0xdcdcdc,
    'ghostwhite': 0xf8f8ff, 'gold': 0xffd700, 'goldenrod': 0xdaa520, 'gray': 0x808080, 'green': 0x008000,
    'greenyellow': 0xadff2f, 'grey': 0x808080, 'honeydew': 0xf0fff0, 'hotpink': 0xff69b4, 'indianred': 0xcd5c5c,
    'indigo': 0x4b0082, 'ivory': 0xfffff0, 'khaki': 0xf0e68c, 'lavender': 0xe6e6fa, 'lavenderblush': 0xfff0f5,
    'lawngreen': 0x7cfc00, 'lemonchiffon': 0xfffacd, 'lightblue': 0xadd8e6, 'lightcoral': 0xf08080,
    'lightcyan': 0xe0ffff, 'lightgoldenrodyellow': 0xfafad2, 'lightgray': 0xd3d3d3, 'lightgreen': 0x90ee90,
    'lightgrey': 0xd3d3d3, 'lightpink': 0xffb6c1, 'lightsalmon': 0xffa07a, 'lightseagreen': 0x20b2aa,
    'lightskyblue': 0x87cefa, 'lightslategray': 0x778899, 'lightslategrey': 0x778899, 'lightsteelblue': 0xb0c4de,
    'lightyellow': 0xffffe0, 'lime': 0x00ff00, 'limegreen': 0x32cd32, 'linen': 0xfaf0e6, 'magenta': 0xff00ff,
    'maroon': 0x800000, 'mediumaquamarine': 0x66cdaa, 'mediumblue': 0x0000cd, 'mediumorchid': 0xba55d3,
    'mediumpurple': 0x9370db, 'mediumseagreen': 0x3cb371, 'mediumslateblue': 0x7b68ee, 'mediumspringgreen': 0x00fa9a,
    'mediumturquoise': 0x48d1cc, 'mediumvioletred': 0xc71585, 'midnightblue': 0x191970, 'mintcream': 0xf5fffa,
    'mistyrose': 0xffe4e1, 'moccasin': 0xffe4b5, 'navajowhite': 0xffdead, 'navy': 0x000080, 'oldlace': 0xfdf5e6,
    'olive': 0x808000, 'olivedrab': 0x6b8e23, 'orange': 0xffa500, 'orangered': 0xff4500, 'orchid': 0xda70d6,
    'palegoldenrod': 0xeee8aa, 'palegreen': 0x98fb98, 'paleturquoise': 0xafeeee, 'palevioletred': 0xdb7093,
    'papayawhip': 0xffefd5, 'peachpuff': 0xffdab9, 'peru': 0xcd853f, 'pink': 0xffc0cb, 'plum': 0xdda0dd,
    'powderblue': 0xb0e0e6, 'purple': 0x800080, 'rebeccapurple': 0x663399, 'red': 0xff0000, 'rosybrown': 0xbc8f8f,
    'royalblue': 0x4169e1, 'saddlebrown': 0x8b4513, 'salmon': 0xfa8072, 'sandybrown': 0xf4a460, 'seagreen': 0x2e8b57,
    'seashell': 0xfff5ee, 'sienna': 0xa0522d, 'silver': 0xc0c0c0, 'skyblue': 0x87ceeb, 'slateblue': 0x6a5acd,
    'slategray': 0x708090, 'slategrey': 0x708090, 'snow': 0xfffafa, 'springgreen': 0x00ff7f, 'steelblue': 0x4682b4,
    'tan': 0xd2b48c, 'teal': 0x008080, 'thistle': 0xd8bfd8, 'tomato': 0xff6347, 'turquoise': 0x40e0d0,
    'violet': 0xee82ee, 'wheat': 0xf5deb3, 'white': 0xffffff, 'whitesmoke': 0xf5f5f5, 'yellow': 0xffff00,
    'yellowgreen': 0x9acd32,
  };
}
