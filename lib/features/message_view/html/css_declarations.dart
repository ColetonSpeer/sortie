/// One `property: value` pair from a `style` attribute or a stylesheet rule.
class CssDeclaration {
  const CssDeclaration(this.property, this.value, {this.important = false});

  /// Lower-cased property name.
  final String property;

  /// Trimmed value without any `!important` suffix.
  final String value;
  final bool important;

  String toCss() => '$property:$value';

  @override
  String toString() => '$property:$value${important ? ' !important' : ''}';
}

/// Parses a declaration block (`color:red; background:url(a;b)`), keeping
/// `;` inside parentheses and quotes intact.
List<CssDeclaration> parseDeclarations(String css) {
  final out = <CssDeclaration>[];
  for (final part in splitTopLevel(css, ';')) {
    final colon = part.indexOf(':');
    if (colon <= 0) continue;
    final prop = part.substring(0, colon).trim().toLowerCase();
    var value = part.substring(colon + 1).trim();
    if (prop.isEmpty || value.isEmpty || !RegExp(r'^-?[a-z][a-z0-9-]*$').hasMatch(prop)) continue;
    var important = false;
    final bang = RegExp(r'!\s*important\s*$', caseSensitive: false);
    if (bang.hasMatch(value)) {
      important = true;
      value = value.replaceAll(bang, '').trim();
      if (value.isEmpty) continue;
    }
    out.add(CssDeclaration(prop, value, important: important));
  }
  return out;
}

/// Serialises declarations back into a `style` attribute value. `!important`
/// flags are dropped: after inlining, declaration order already encodes
/// precedence.
String serializeDeclarations(Iterable<CssDeclaration> decls) => decls.map((d) => d.toCss()).join(';');

/// Splits [s] on [sep] (a single character) ignoring separators inside
/// `(...)`, `[...]`, `"..."` and `'...'`.
List<String> splitTopLevel(String s, String sep) {
  final out = <String>[];
  final buf = StringBuffer();
  var depth = 0;
  String? quote;
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (quote != null) {
      buf.write(c);
      if (c == quote) quote = null;
      continue;
    }
    if (c == '"' || c == "'") {
      quote = c;
      buf.write(c);
    } else if (c == '(' || c == '[') {
      depth++;
      buf.write(c);
    } else if (c == ')' || c == ']') {
      if (depth > 0) depth--;
      buf.write(c);
    } else if (c == sep && depth == 0) {
      out.add(buf.toString());
      buf.clear();
    } else {
      buf.write(c);
    }
  }
  out.add(buf.toString());
  return [for (final p in out) if (p.trim().isNotEmpty) p.trim()];
}

/// Splits a value on whitespace, keeping function calls like `rgb(1, 2, 3)`
/// together.
List<String> splitValueTokens(String value) {
  final tokens = <String>[];
  final buf = StringBuffer();
  var depth = 0;
  for (var i = 0; i < value.length; i++) {
    final c = value[i];
    if (c == '(') depth++;
    if (c == ')' && depth > 0) depth--;
    if (depth == 0 && (c == ' ' || c == '\t' || c == '\n')) {
      if (buf.isNotEmpty) tokens.add(buf.toString());
      buf.clear();
    } else {
      buf.write(c);
    }
  }
  if (buf.isNotEmpty) tokens.add(buf.toString());
  return tokens;
}

/// Removes every declaration named [property] and appends a new one, so the
/// new value is the one a last-wins renderer sees.
List<CssDeclaration> replaceDeclaration(List<CssDeclaration> decls, String property, String value) =>
    [...decls.where((d) => d.property != property), CssDeclaration(property, value)];
