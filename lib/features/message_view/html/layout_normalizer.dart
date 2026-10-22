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
/// - a coloured cell whose only content is one link becomes tappable as a
///   whole ("bulletproof button" mail markup)
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
      if (const {'table', 'thead', 'tbody', 'tfoot', 'tr', 'td', 'th'}.contains(name)) {
        // Browsers keep a cell a cell whatever `display`/`float` say (mail
        // templates put `display:block; float:left` on cells for phones);
        // flutter_widget_from_html_core would drop the cell and its content.
        decls = decls.where((d) => !((d.property == 'display' && d.value.trim().toLowerCase() != 'none') || d.property == 'float' || d.property == 'clear')).toList();
      }
      if (name == 'table' || name == 'td' || name == 'th' || name == 'div') {
        // flutter_widget_from_html_core collapses tables that carry max-width
        // or min-width (the column shrinks to one glyph per line).
        // Dropping both (rather than converting max-width to width) is what
        // renders correctly: a fixed width on a nested table also collapses.
        decls = decls.where((d) => d.property != 'max-width' && d.property != 'min-width').toList();
      }
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
    _fillCellsWithLoneLinks(body);
    _wrapBodyStyle(doc, body);
    return contentWidth;
  }

  static const _inlineWrappers = {'p', 'span', 'div', 'font', 'b', 'strong', 'em', 'i', 'u', 'center'};
  static const _tableWrappers = {'td', 'th', 'tr', 'tbody', 'thead', 'tfoot', 'table'};

  /// Mail "buttons" are a coloured cell holding a single link. The renderer
  /// draws the cell at full width but only the link text (plus its padding)
  /// reacts to taps, so most of the visible button is dead. Making the link
  /// and its inline wrappers block-level lets the tap target cover the cell.
  static void _fillCellsWithLoneLinks(dom.Element body) {
    for (final a in body.querySelectorAll('a[href]')) {
      if (a.querySelector('a') != null || a.text.trim().isEmpty && a.querySelector('img') == null) continue;
      final chain = <dom.Element>[];
      dom.Element cur = a;
      var found = false;
      while (true) {
        final parent = cur.parent;
        if (parent == null || !_isLoneChild(cur, parent)) break;
        if (_hasBackground(parent)) {
          found = true;
          break;
        }
        final pname = parent.localName ?? '';
        if (_inlineWrappers.contains(pname)) {
          chain.add(parent);
        } else if (!_tableWrappers.contains(pname)) {
          break;
        }
        cur = parent;
      }
      if (!found) continue;
      for (final el in [a, ...chain]) {
        final decls = replaceDeclaration(parseDeclarations(el.attributes['style'] ?? ''), 'display', 'block');
        el.attributes['style'] = serializeDeclarations(decls);
      }
    }
  }

  static bool _isLoneChild(dom.Element child, dom.Element parent) =>
      parent.nodes.every((n) => identical(n, child) || n is dom.Comment || (n is dom.Text && n.text.trim().isEmpty));

  static bool _hasBackground(dom.Element el) {
    if ((el.attributes['background'] ?? '').trim().isNotEmpty) return true;
    for (final d in parseDeclarations(el.attributes['style'] ?? '')) {
      if (d.property != 'background' && d.property != 'background-color') continue;
      final v = d.value.trim().toLowerCase();
      if (v.isNotEmpty && v != 'transparent' && v != 'none' && v != 'inherit') return true;
    }
    return false;
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
