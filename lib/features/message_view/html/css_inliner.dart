import 'package:html/dom.dart' as dom;

import 'css_declarations.dart';

/// One parsed stylesheet rule for a single selector.
class CssRule {
  const CssRule({required this.selector, required this.declarations, required this.specificity, required this.order});
  final String selector;
  final List<CssDeclaration> declarations;

  /// `ids * 10000 + classes/attributes * 100 + tags`.
  final int specificity;

  /// Source position: later rules win ties.
  final int order;

  @override
  String toString() => '$selector{${declarations.join(';')}} [$specificity/$order]';
}

/// Moves `<style>` rules onto the elements they match as inline `style`
/// attributes, because the renderer only honours inline styles.
///
/// Selector support: tags, `.class`, `#id`, `[attr]`, `[attr=value]`,
/// descendant and child combinators, `,` lists. Selectors with pseudo
/// classes/elements (`:hover`, `::before`) and anything `package:html`'s
/// `querySelectorAll` cannot evaluate are skipped.
class CssInliner {
  const CssInliner({this.viewportWidth = 600});

  /// Width used to evaluate `min-width` / `max-width` media queries.
  final int viewportWidth;

  /// Properties worth inlining. Everything else (animations, transforms,
  /// positioning, dark-mode tricks) is dropped.
  static const _keepExact = {
    'width', 'max-width', 'min-width', 'height', 'max-height', 'color', 'display', 'text-align', 'line-height',
    'vertical-align', 'border-collapse', 'border-spacing', 'white-space', 'letter-spacing', 'list-style-type',
    'text-transform',
  };
  static const _keepPrefix = ['padding', 'margin', 'border', 'background', 'font', 'text-decoration'];

  static bool keepsProperty(String p) => _keepExact.contains(p) || _keepPrefix.any((k) => p == k || p.startsWith('$k-'));

  /// Inlines every `<style>` in [doc] (head and body) and removes them.
  void apply(dom.Document doc) {
    final styles = doc.querySelectorAll('style');
    if (styles.isEmpty) return;
    final rules = <CssRule>[];
    for (final s in styles) {
      rules.addAll(parseStylesheet(s.text, startOrder: rules.length));
      s.remove();
    }
    applyRules(doc, rules);
  }

  /// Parses stylesheet text into flat rules, resolving `@media` blocks.
  List<CssRule> parseStylesheet(String css, {int startOrder = 0}) {
    final out = <CssRule>[];
    _parseBlock(_stripComments(css), out, startOrder);
    return out;
  }

  void _parseBlock(String css, List<CssRule> out, int startOrder) {
    var i = 0;
    while (i < css.length) {
      final c = css[i];
      if (c.trim().isEmpty) {
        i++;
        continue;
      }
      if (c == '@') {
        final nameEnd = css.indexOf(RegExp(r'[\s{;]'), i);
        if (nameEnd < 0) return;
        final name = css.substring(i + 1, nameEnd).toLowerCase();
        final brace = css.indexOf('{', i);
        final semi = css.indexOf(';', i);
        if (brace < 0 || (semi >= 0 && semi < brace)) {
          // Statement at-rule (@import, @charset): skip to `;`.
          i = semi < 0 ? css.length : semi + 1;
          continue;
        }
        final end = _matchingBrace(css, brace);
        if (name == 'media' && mediaMatches(css.substring(nameEnd, brace))) {
          _parseBlock(css.substring(brace + 1, end), out, startOrder);
        }
        i = end + 1;
        continue;
      }
      final brace = css.indexOf('{', i);
      if (brace < 0) return;
      final end = _matchingBrace(css, brace);
      final selectors = css.substring(i, brace).trim();
      final decls = parseDeclarations(css.substring(brace + 1, end)).where((d) => keepsProperty(d.property)).toList();
      if (decls.isNotEmpty) {
        for (final sel in splitTopLevel(selectors, ',')) {
          out.add(CssRule(selector: sel, declarations: decls, specificity: specificity(sel), order: startOrder + out.length));
        }
      }
      i = end + 1;
    }
  }

  static int _matchingBrace(String css, int open) {
    var depth = 0;
    for (var i = open; i < css.length; i++) {
      if (css[i] == '{') depth++;
      if (css[i] == '}' && --depth == 0) return i;
    }
    return css.length;
  }

  static String _stripComments(String css) => css.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');

  /// Whether rules under `@media <condition>` apply to a light, screen-like
  /// viewport that is [viewportWidth] wide.
  bool mediaMatches(String condition) {
    final cond = condition.trim().toLowerCase();
    if (cond.isEmpty) return true;
    return cond.split(',').any((query) {
      final q = query.trim().replaceFirst(RegExp(r'^only\s+'), '');
      if (q.startsWith('not ')) return false;
      for (final part in q.split(RegExp(r'\s+and\s+'))) {
        final p = part.trim().replaceAll(RegExp(r'^\(|\)$'), '').trim();
        if (p == 'screen' || p == 'all') continue;
        if (p == 'print' || p == 'speech') return false;
        final m = RegExp(r'^([a-z-]+)\s*:\s*(.+)$').firstMatch(p);
        if (m == null) return false;
        final feature = m.group(1)!, value = m.group(2)!.trim();
        final px = double.tryParse(value.replaceAll(RegExp(r'px$'), ''));
        switch (feature) {
          case 'min-width':
          case 'min-device-width':
            if (px == null || viewportWidth < px) return false;
          case 'max-width':
          case 'max-device-width':
            if (px == null || viewportWidth > px) return false;
          case 'prefers-color-scheme':
            if (value != 'light') return false;
          default:
            return false;
        }
      }
      return true;
    });
  }

  /// CSS specificity of one selector (no pseudo support needed: skipped).
  static int specificity(String selector) {
    final ids = '#'.allMatches(selector).length;
    final classes = RegExp(r'\.[\w-]').allMatches(selector).length + '['.allMatches(selector).length;
    final tags = RegExp(r'(^|[\s>+~])[a-zA-Z][\w-]*').allMatches(selector).length;
    return ids * 10000 + classes * 100 + tags;
  }

  /// Applies [rules] to [doc], merging them into each element's `style`.
  /// Inline declarations win over rules unless the rule is `!important`.
  void applyRules(dom.Document doc, List<CssRule> rules) {
    final matches = <dom.Element, List<CssRule>>{};
    for (final rule in rules) {
      if (rule.selector.contains(':')) continue;
      List<dom.Element> elements;
      try {
        elements = doc.querySelectorAll(rule.selector);
      } catch (_) {
        continue; // unsupported selector
      }
      for (final el in elements) {
        (matches[el] ??= []).add(rule);
      }
    }
    matches.forEach((el, list) {
      list.sort((a, b) => a.specificity != b.specificity ? a.specificity - b.specificity : a.order - b.order);
      final fromRules = <String, CssDeclaration>{};
      for (final r in list) {
        for (final d in r.declarations) {
          final ex = fromRules[d.property];
          if (ex == null || !ex.important || d.important) fromRules[d.property] = d;
        }
      }
      final result = <String, CssDeclaration>{};
      for (final d in fromRules.values) {
        if (!d.important) result[d.property] = d;
      }
      for (final d in parseDeclarations(el.attributes['style'] ?? '')) {
        result.remove(d.property);
        result[d.property] = d;
      }
      for (final d in fromRules.values) {
        if (!d.important) continue;
        final ex = result[d.property];
        if (ex != null && ex.important) continue;
        result.remove(d.property);
        result[d.property] = d;
      }
      if (result.isNotEmpty) el.attributes['style'] = serializeDeclarations(result.values);
    });
  }
}
