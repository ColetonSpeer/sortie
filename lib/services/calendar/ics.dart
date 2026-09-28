/// RFC 5545 iCalendar: content-line parsing/unfolding, component tree,
/// value codecs (TEXT, DATE, DATE-TIME, DURATION) and line folding.
/// Event mapping and the VCALENDAR serializer live in `ics_events.dart`.
library;

import 'dart:convert';

export 'ics_events.dart';

class IcsProperty {
  const IcsProperty(this.name, this.value, [this.params = const {}]);
  final String name;
  final String value;

  /// Parameter name (upper case) -> values (quotes removed).
  final Map<String, List<String>> params;

  String? param(String name) => params[name.toUpperCase()]?.firstOrNull;
}

class IcsComponent {
  IcsComponent(this.name);
  final String name;
  final List<IcsProperty> properties = [];
  final List<IcsComponent> children = [];

  IcsProperty? prop(String name) {
    final n = name.toUpperCase();
    for (final p in properties) {
      if (p.name == n) return p;
    }
    return null;
  }

  Iterable<IcsProperty> props(String name) => properties.where((p) => p.name == name.toUpperCase());
  Iterable<IcsComponent> childrenNamed(String name) => children.where((c) => c.name == name.toUpperCase());
}

/// Parses a whole iCalendar text into its top-level components.
List<IcsComponent> parseIcs(String text) {
  final root = IcsComponent('ROOT');
  final stack = <IcsComponent>[root];
  for (final line in unfoldLines(text)) {
    final p = parseContentLine(line);
    if (p == null) continue;
    if (p.name == 'BEGIN') {
      final c = IcsComponent(p.value.toUpperCase());
      stack.last.children.add(c);
      stack.add(c);
    } else if (p.name == 'END') {
      if (stack.length > 1) stack.removeLast();
    } else {
      stack.last.properties.add(p);
    }
  }
  return root.children;
}

/// Joins folded continuation lines (leading SPACE or HTAB) and drops blanks.
List<String> unfoldLines(String text) {
  final out = <String>[];
  for (final raw in const LineSplitter().convert(text)) {
    if (raw.isEmpty) continue;
    if ((raw.startsWith(' ') || raw.startsWith('\t')) && out.isNotEmpty) {
      out[out.length - 1] = out.last + raw.substring(1);
    } else {
      out.add(raw);
    }
  }
  return out;
}

/// `NAME;PARAM=a,"b:c";P2=x:VALUE` -> property. Returns null on garbage.
IcsProperty? parseContentLine(String line) {
  var i = 0;
  final nameBuf = StringBuffer();
  while (i < line.length && line[i] != ';' && line[i] != ':') {
    nameBuf.write(line[i]);
    i++;
  }
  if (i >= line.length || nameBuf.isEmpty) return null;
  final params = <String, List<String>>{};
  while (i < line.length && line[i] == ';') {
    i++;
    final pn = StringBuffer();
    while (i < line.length && line[i] != '=' && line[i] != ':' && line[i] != ';') {
      pn.write(line[i]);
      i++;
    }
    final values = <String>[];
    if (i < line.length && line[i] == '=') {
      i++;
      while (i < line.length) {
        final v = StringBuffer();
        if (line[i] == '"') {
          i++;
          while (i < line.length && line[i] != '"') {
            v.write(line[i]);
            i++;
          }
          i++; // closing quote
        } else {
          while (i < line.length && line[i] != ',' && line[i] != ';' && line[i] != ':') {
            v.write(line[i]);
            i++;
          }
        }
        values.add(v.toString());
        if (i < line.length && line[i] == ',') {
          i++;
          continue;
        }
        break;
      }
    }
    params[pn.toString().toUpperCase()] = values;
  }
  if (i >= line.length || line[i] != ':') return null;
  return IcsProperty(nameBuf.toString().toUpperCase(), line.substring(i + 1), params);
}

/// TEXT value unescaping (RFC 5545 §3.3.11).
String unescapeText(String s) {
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (c == r'\' && i + 1 < s.length) {
      final n = s[i + 1];
      i++;
      switch (n) {
        case 'n':
        case 'N':
          b.write('\n');
        case r'\':
        case ';':
        case ',':
          b.write(n);
        default:
          b.write(c);
          b.write(n);
      }
    } else {
      b.write(c);
    }
  }
  return b.toString();
}

String escapeText(String s) => s
    .replaceAll(r'\', r'\\')
    .replaceAll(';', r'\;')
    .replaceAll(',', r'\,')
    .replaceAll('\r\n', '\n')
    .replaceAll('\n', r'\n');

/// A parsed DATE or DATE-TIME: wall-clock fields carried in a UTC-flagged
/// DateTime (rrule-style); [isUtc] marks a trailing `Z`, [tzid] the TZID.
class IcsTime {
  const IcsTime(this.wall, {this.isDate = false, this.isUtc = false, this.tzid});
  final DateTime wall;
  final bool isDate;
  final bool isUtc;
  final String? tzid;
  bool get isFloating => !isDate && !isUtc && tzid == null;
}

final _dateRe = RegExp(r'^(\d{4})(\d{2})(\d{2})$');
final _dateTimeRe = RegExp(r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})?(Z)?$');

IcsTime? parseIcsTime(String value, {String? tzid, bool? forceDate}) {
  final v = value.trim();
  final m = _dateRe.firstMatch(v);
  if (m != null || forceDate == true) {
    final mm = m ?? _dateTimeRe.firstMatch(v);
    if (mm == null) return null;
    return IcsTime(DateTime.utc(int.parse(mm[1]!), int.parse(mm[2]!), int.parse(mm[3]!)), isDate: true);
  }
  final d = _dateTimeRe.firstMatch(v);
  if (d == null) return null;
  final wall = DateTime.utc(int.parse(d[1]!), int.parse(d[2]!), int.parse(d[3]!), int.parse(d[4]!), int.parse(d[5]!),
      int.parse(d[6] ?? '0'));
  final utc = d[7] == 'Z';
  return IcsTime(wall, isUtc: utc, tzid: utc ? null : tzid);
}

IcsTime? timeOf(IcsProperty p) =>
    parseIcsTime(p.value, tzid: p.param('TZID'), forceDate: p.param('VALUE')?.toUpperCase() == 'DATE');

String formatIcsDate(DateTime d) => '${_p4(d.year)}${_p2(d.month)}${_p2(d.day)}';
String formatIcsDateTime(DateTime wall, {bool utc = false}) =>
    '${formatIcsDate(wall)}T${_p2(wall.hour)}${_p2(wall.minute)}${_p2(wall.second)}${utc ? 'Z' : ''}';
String _p2(int n) => n.toString().padLeft(2, '0');
String _p4(int n) => n.toString().padLeft(4, '0');

final _durRe = RegExp(r'^([+-])?P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$');

/// ISO 8601 duration as used by DURATION and TRIGGER.
Duration? parseIcsDuration(String value) {
  final m = _durRe.firstMatch(value.trim());
  if (m == null) return null;
  int n(int i) => int.tryParse(m[i] ?? '') ?? 0;
  final d = Duration(days: n(2) * 7 + n(3), hours: n(4), minutes: n(5), seconds: n(6));
  return m[1] == '-' ? -d : d;
}

String formatIcsDuration(Duration d) {
  final neg = d.isNegative;
  var s = d.abs().inSeconds;
  final days = s ~/ 86400;
  s %= 86400;
  final h = s ~/ 3600;
  s %= 3600;
  final m = s ~/ 60;
  s %= 60;
  final b = StringBuffer(neg ? '-P' : 'P');
  if (days > 0) b.write('${days}D');
  if (h > 0 || m > 0 || s > 0 || days == 0) {
    b.write('T');
    if (h > 0) b.write('${h}H');
    if (m > 0 || (h == 0 && s == 0)) b.write('${m}M');
    if (s > 0) b.write('${s}S');
  }
  return b.toString();
}

/// Folds a content line at 75 octets (UTF-8), never inside a code point.
String foldLine(String line) {
  final bytes = utf8.encode(line);
  if (bytes.length <= 75) return line;
  final out = StringBuffer();
  var start = 0;
  var first = true;
  while (start < bytes.length) {
    final limit = first ? 75 : 74;
    var end = start + limit;
    if (end >= bytes.length) {
      end = bytes.length;
    } else {
      // Back up to a UTF-8 sequence boundary.
      while (end > start && (bytes[end] & 0xC0) == 0x80) {
        end--;
      }
    }
    if (!first) out.write('\r\n ');
    out.write(utf8.decode(bytes.sublist(start, end)));
    first = false;
    start = end;
  }
  return out.toString();
}

/// Writes properties into a VCALENDAR text with CRLF line endings.
class IcsWriter {
  final _lines = <String>[];

  void begin(String c) => _lines.add('BEGIN:$c');
  void end(String c) => _lines.add('END:$c');

  void prop(String name, String value, {Map<String, String> params = const {}}) {
    final b = StringBuffer(name);
    for (final e in params.entries) {
      final v = e.value;
      final needsQuote = v.contains(':') || v.contains(';') || v.contains(',');
      b.write(';${e.key}=${needsQuote ? '"$v"' : v}');
    }
    b.write(':');
    b.write(value);
    _lines.add(b.toString());
  }

  void text(String name, String? value, {Map<String, String> params = const {}}) {
    if (value == null || value.isEmpty) return;
    prop(name, escapeText(value), params: params);
  }

  @override
  String toString() => '${_lines.map(foldLine).join('\r\n')}\r\n';
}
