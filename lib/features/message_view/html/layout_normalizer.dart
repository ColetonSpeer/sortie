import 'package:html/dom.dart' as dom;

import 'css_declarations.dart';

/// Turns presentational HTML (attributes the renderer ignores or that the
/// contrast guard cannot see) into inline styles, and measures how wide the
/// content asks to be.
///
/// - `width`/`height` attributes on tables, cells and divs become CSS sizes
/// - `bgcolor`, `<font color>`, `<center>` and `align` become CSS
/// - images are clamped to the viewport while keeping their aspect ratio
/// - `<body>` styling (`bgcolor`, `text`, `style`) survives on a wrapper div
class LayoutNormalizer {
  const LayoutNormalizer();

  static const _sizedTags = {'table', 'td', 'th', 'div', 'tr', 'col'};
  static const _maxContentWidth = 2000;

  /// Normalises [doc] in place and returns the widest explicit pixel width
  /// the content requested (0 when it is fluid).
  int normalize(dom.Document doc) {
    final body = doc.body;
    if (body == null) return 0;
    var contentWidth = 0;

    void visit(dom.Element el) {
      final name = el.localName ?? '';
      var decls = parseDeclarations(el.attributes['style'] ?? '');
      final before = serializeDeclarations(decls);
      final prepend = <CssDeclaration>[];

      final bgcolor = el.attributes.remove('bgcolor');
      if (bgcolor != null && bgcolor.trim().isNotEmpty) prepend.add(CssDeclaration('background-color', bgcolor.trim()));

      if (name == 'font') {
        final color = el.attributes.remove('color');
        if (color != null && color.trim().isNotEmpty) prepend.add(CssDeclaration('color', color.trim()));
      }

      if (name == 'center') {
        prepend.addAll(const [CssDeclaration('display', 'block'), CssDeclaration('text-align', 'center')]);
      }
      final align = el.attributes['align']?.trim().toLowerCase();
      if (align != null && name != 'img' && const {'left', 'center', 'right', 'justify'}.contains(align)) {
        prepend.add(CssDeclaration('text-align', align));
      }

      if (_sizedTags.contains(name)) {
        final w = _cssLength(el.attributes['width']);
        if (w != null) prepend.add(CssDeclaration('width', w));
        final h = _cssLength(el.attributes['height']);
        if (h != null && name != 'tr') prepend.add(CssDeclaration('height', h));
      }

      decls = [...prepend, ...decls];
      if (name == 'img') {
        decls = replaceDeclaration(decls, 'max-width', '100%');
        if (el.attributes.containsKey('width') || decls.any((d) => d.property == 'width')) {
          decls = replaceDeclaration(decls, 'height', 'auto');
        }
      }

      if (name != 'td' && name != 'th') {
        for (final d in decls) {
          if (d.property == 'width' || d.property == 'min-width') {
            final px = _px(d.value);
            if (px != null && px > contentWidth) contentWidth = px.clamp(0, _maxContentWidth);
          }
        }
        if (name == 'img' || _sizedTags.contains(name)) {
          final px = _px(el.attributes['width']);
          if (px != null && px > contentWidth) contentWidth = px.clamp(0, _maxContentWidth);
        }
      }

      final after = serializeDeclarations(decls);
      if (after != before) {
        if (after.isEmpty) {
          el.attributes.remove('style');
        } else {
          el.attributes['style'] = after;
        }
      }
      for (final child in el.children) {
        visit(child);
      }
    }

    for (final child in body.children.toList()) {
      visit(child);
    }
    _wrapBodyStyle(doc, body);
    return contentWidth;
  }

  /// Keeps `<body bgcolor text style>` effective after the body tag itself is
  /// dropped by serialising `innerHtml`.
  static void _wrapBodyStyle(dom.Document doc, dom.Element body) {
    final decls = <CssDeclaration>[];
    final bg = body.attributes.remove('bgcolor');
    if (bg != null && bg.trim().isNotEmpty) decls.add(CssDeclaration('background-color', bg.trim()));
    final text = body.attributes.remove('text');
    if (text != null && text.trim().isNotEmpty) decls.add(CssDeclaration('color', text.trim()));
    decls.addAll(parseDeclarations(body.attributes.remove('style') ?? ''));
    if (decls.isEmpty) return;
    final wrapper = doc.createElement('div');
    wrapper.attributes['style'] = serializeDeclarations(decls);
    wrapper.attributes['data-mail-body'] = '';
    for (final node in body.nodes.toList()) {
      node.remove();
      wrapper.append(node);
    }
    body.append(wrapper);
  }

  /// `600` -> `600px`, `100%` -> `100%`, `600px` -> `600px`; null otherwise.
  static String? _cssLength(String? attr) {
    if (attr == null) return null;
    final v = attr.trim().toLowerCase();
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(v)) return '${v}px';
    if (RegExp(r'^\d+(\.\d+)?(px|%)$').hasMatch(v)) return v;
    return null;
  }

  static int? _px(String? v) {
    if (v == null) return null;
    final m = RegExp(r'^\s*(\d+(?:\.\d+)?)\s*(px)?\s*$').firstMatch(v);
    return m == null ? null : double.parse(m.group(1)!).round();
  }
}
