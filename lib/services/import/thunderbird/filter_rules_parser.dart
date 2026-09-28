/// Parser for Thunderbird `msgFilterRules.dat`.
///
/// ```
/// version="9"
/// logging="no"
/// name="Calix orders"
/// enabled="yes"
/// type="17"
/// action="Move to folder"
/// actionValue="imap://user%40host@host/INBOX/Calix%20orders"
/// condition="AND (from,is,order.management@calix.com) AND (subject,contains,Calix Order Acknowledgement)"
/// ```
library;

class TbCondition {
  const TbCondition({required this.field, required this.op, required this.value});

  /// `subject`, `from`, `to`, `cc`, `to or cc`, `all addresses`, `body`,
  /// `status`, `List-Id` (custom headers keep their name, quotes stripped)…
  final String field;

  /// `is`, `isn't`, `contains`, `doesn't contain`, `begins with`, `ends with`…
  final String op;
  final String value;

  @override
  String toString() => '($field,$op,$value)';
}

class TbAction {
  const TbAction({required this.type, this.value});

  /// `Move to folder`, `Copy to folder`, `Mark read`, `Delete`, `Add Tag`…
  final String type;

  /// For folder actions: `imap://user%40host@host/INBOX/Sub%20Folder`.
  final String? value;
}

class TbFilter {
  const TbFilter({
    required this.name,
    required this.enabled,
    required this.conditions,
    required this.actions,
    this.anyCondition = false,
    this.type,
  });
  final String name;
  final bool enabled;
  final List<TbCondition> conditions;
  final List<TbAction> actions;

  /// `OR` between conditions (Thunderbird "Match any of the following").
  final bool anyCondition;
  final String? type;

  Iterable<TbAction> get folderActions => actions.where((a) => a.type == 'Move to folder' || a.type == 'Copy to folder');
}

/// Reads every filter record; header keys (`version`, `logging`) are ignored.
List<TbFilter> parseFilterRules(String text) {
  final out = <TbFilter>[];
  String? name;
  var enabled = true;
  String? type;
  var any = false;
  var conditions = <TbCondition>[];
  var actions = <TbAction>[];

  void flush() {
    if (name != null) {
      out.add(TbFilter(name: name!, enabled: enabled, conditions: conditions, actions: actions, anyCondition: any, type: type));
    }
    name = null;
    enabled = true;
    type = null;
    any = false;
    conditions = [];
    actions = [];
  }

  for (final raw in text.split('\n')) {
    final line = raw.trimRight();
    final eq = line.indexOf('=');
    if (eq <= 0) continue;
    final key = line.substring(0, eq).trim();
    final value = _unquote(line.substring(eq + 1).trim());
    switch (key) {
      case 'name':
        flush();
        name = value;
      case 'enabled':
        enabled = value != 'no';
      case 'type':
        type = value;
      case 'action':
        actions.add(TbAction(type: value));
      case 'actionValue':
        if (actions.isNotEmpty) actions[actions.length - 1] = TbAction(type: actions.last.type, value: value);
      case 'condition':
        final parsed = parseCondition(value);
        conditions = parsed.terms;
        any = parsed.any;
    }
  }
  flush();
  return out;
}

String _unquote(String v) {
  if (v.length >= 2 && v.startsWith('"') && v.endsWith('"')) v = v.substring(1, v.length - 1);
  return v.replaceAll(r'\"', '"').replaceAll(r'\\', r'\');
}

/// `AND (field,op,value) AND ("Custom-Header",contains,x)`. A value runs to
/// the `)` that is followed by the next ` AND (` / ` OR (` or the end, so
/// commas and parentheses inside values survive.
({List<TbCondition> terms, bool any}) parseCondition(String condition) {
  final terms = <TbCondition>[];
  var any = false;
  final re = RegExp(r'(AND|OR)\s*\((.*?)\)(?=\s+(?:AND|OR)\s*\(|\s*$)', dotAll: true);
  for (final m in re.allMatches(condition.trim())) {
    if (m.group(1) == 'OR') any = true;
    final body = m.group(2)!;
    final c1 = body.indexOf(',');
    if (c1 < 0) continue;
    final c2 = body.indexOf(',', c1 + 1);
    var field = body.substring(0, c1).trim();
    if (field.length >= 2 && field.startsWith('"') && field.endsWith('"')) field = field.substring(1, field.length - 1);
    final op = (c2 < 0 ? body.substring(c1 + 1) : body.substring(c1 + 1, c2)).trim();
    final value = c2 < 0 ? '' : body.substring(c2 + 1);
    terms.add(TbCondition(field: field, op: op, value: value));
  }
  return (terms: terms, any: any);
}

/// `imap://user%40host@host/INBOX/Calix%20orders` -> `INBOX/Calix orders`
/// (segments URL-decoded, `/` kept as the separator). Returns null when the
/// URI has no folder path (e.g. `mailbox://` Local Folders root).
String? folderPathFromUri(String uri) {
  final u = Uri.tryParse(uri.trim());
  if (u == null) return null;
  final segs = u.pathSegments.where((s) => s.isNotEmpty).map(Uri.decodeComponent).toList();
  if (segs.isEmpty) return null;
  return segs.join('/');
}
