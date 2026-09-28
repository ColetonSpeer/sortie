/// Parses Thunderbird `prefs.js` (`user_pref("key", value);` lines).
///
/// Values are JSON-ish: double-quoted strings with `\"`, `\\`, `\n`, `\t`,
/// `\r`, `\uXXXX` escapes, integers, doubles, `true` / `false`. Anything else
/// (comments, `pref(` defaults, malformed lines) is ignored.
Map<String, Object?> parsePrefsJs(String text) {
  final out = <String, Object?>{};
  var i = 0;
  while (true) {
    final start = text.indexOf('user_pref(', i);
    if (start < 0) break;
    i = start + 'user_pref('.length;
    final key = _readString(text, _skipSpace(text, i));
    if (key == null) continue;
    var j = _skipSpace(text, key.end);
    if (j >= text.length || text[j] != ',') continue;
    j = _skipSpace(text, j + 1);
    final value = _readValue(text, j);
    if (value == null) continue;
    final close = _skipSpace(text, value.end);
    if (close < text.length && text[close] == ')') {
      out[key.value] = value.value;
      i = close + 1;
    }
  }
  return out;
}

int _skipSpace(String s, int i) {
  while (i < s.length && (s[i] == ' ' || s[i] == '\t' || s[i] == '\n' || s[i] == '\r')) {
    i++;
  }
  return i;
}

class _Parsed<T> {
  const _Parsed(this.value, this.end);
  final T value;
  final int end;
}

_Parsed<String>? _readString(String s, int i) {
  if (i >= s.length || s[i] != '"') return null;
  final b = StringBuffer();
  i++;
  while (i < s.length) {
    final c = s[i];
    if (c == '"') return _Parsed(b.toString(), i + 1);
    if (c == r'\' && i + 1 < s.length) {
      final n = s[i + 1];
      switch (n) {
        case 'n':
          b.write('\n');
        case 't':
          b.write('\t');
        case 'r':
          b.write('\r');
        case 'u':
          final hex = i + 5 < s.length ? s.substring(i + 2, i + 6) : '';
          final code = int.tryParse(hex, radix: 16);
          if (code != null) {
            b.writeCharCode(code);
            i += 4;
          } else {
            b.write('u');
          }
        default:
          b.write(n); // \" \\ \/ and anything else -> the char itself
      }
      i += 2;
      continue;
    }
    b.write(c);
    i++;
  }
  return null; // unterminated
}

_Parsed<Object?>? _readValue(String s, int i) {
  if (i >= s.length) return null;
  if (s[i] == '"') return _readString(s, i);
  if (s.startsWith('true', i)) return _Parsed(true, i + 4);
  if (s.startsWith('false', i)) return _Parsed(false, i + 5);
  final m = RegExp(r'-?\d+(\.\d+)?([eE][-+]?\d+)?').matchAsPrefix(s, i);
  if (m == null) return null;
  final raw = m.group(0)!;
  final num? n = m.group(1) == null && m.group(2) == null ? int.tryParse(raw) : double.tryParse(raw);
  if (n == null) return null;
  return _Parsed(n, m.end);
}

/// Typed accessors over a parsed prefs map.
extension PrefsAccess on Map<String, Object?> {
  String? str(String key) {
    final v = this[key];
    return v is String ? v : null;
  }

  int? integer(String key) {
    final v = this[key];
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  bool? boolean(String key) {
    final v = this[key];
    if (v is bool) return v;
    if (v is String) return v == 'true' ? true : (v == 'false' ? false : null);
    return null;
  }

  /// Comma-separated list pref (`"account1,account2"`).
  List<String> list(String key) => (str(key) ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
}
