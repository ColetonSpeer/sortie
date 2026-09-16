import 'dart:convert';

/// Best-effort extraction of one JSON object from model output: strict parse
/// first, then strip ``` fences, then the first balanced `{...}` (string and
/// escape aware). Returns null when nothing parses.
Map<String, dynamic>? extractJsonObject(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return null;
  final direct = _tryParse(text);
  if (direct != null) return direct;

  final fence = RegExp(r'```(?:json|JSON)?\s*([\s\S]*?)```').firstMatch(text);
  if (fence != null) {
    final inner = _tryParse(fence.group(1)!.trim());
    if (inner != null) return inner;
    text = text.replaceAll(RegExp(r'```(?:json|JSON)?'), '');
  }

  var start = text.indexOf('{');
  while (start >= 0) {
    final end = _balancedEnd(text, start);
    if (end < 0) return null;
    final candidate = _tryParse(text.substring(start, end + 1));
    if (candidate != null) return candidate;
    start = text.indexOf('{', start + 1);
  }
  return null;
}

Map<String, dynamic>? _tryParse(String s) {
  try {
    final v = jsonDecode(s);
    return v is Map<String, dynamic> ? v : null;
  } on FormatException {
    return null;
  }
}

/// Index of the `}` closing the object opened at [start], or -1.
int _balancedEnd(String s, int start) {
  var depth = 0;
  var inString = false;
  var escaped = false;
  for (var i = start; i < s.length; i++) {
    final c = s[i];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (c == r'\') {
        escaped = true;
      } else if (c == '"') {
        inString = false;
      }
      continue;
    }
    if (c == '"') {
      inString = true;
    } else if (c == '{') {
      depth++;
    } else if (c == '}') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}
