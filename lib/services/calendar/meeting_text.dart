/// Heuristics for mail that describes a meeting without carrying an
/// iCalendar part (a Teams block pasted into a plain message, "When:" lines
/// from Outlook, a date and time in the text).
library;

final _meetingLink = RegExp(
  r'https?://(?:[a-z0-9.-]*\.)?(?:teams\.microsoft\.com|zoom\.us|meet\.google\.com|webex\.com|gotomeeting\.com|teams\.live\.com)/\S+',
  caseSensitive: false,
);

/// First video-meeting link in [text], without trailing punctuation.
String? meetingLink(String text) {
  final m = _meetingLink.firstMatch(text);
  if (m == null) return null;
  return m.group(0)!.replaceAll(RegExp(r'[>.,;)\]]+$'), '');
}

const _months = {
  'jan': 1, 'january': 1, 'feb': 2, 'february': 2, 'mar': 3, 'march': 3, 'apr': 4, 'april': 4, 'may': 5, 'jun': 6, 'june': 6,
  'jul': 7, 'july': 7, 'aug': 8, 'august': 8, 'sep': 9, 'sept': 9, 'september': 9, 'oct': 10, 'october': 10,
  'nov': 11, 'november': 11, 'dec': 12, 'december': 12,
};

final _monthName = RegExp(
  r'\b(?:(?:mon|tues?|wed(?:nes)?|thu(?:rs)?|fri|sat(?:ur)?|sun)(?:day)?,?\s+)?'
  r'(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sept?(?:ember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\.?\s+(\d{1,2})(?:st|nd|rd|th)?,?\s+(\d{4})'
  r'(?:[\s,]+(?:at\s+|from\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?(?:\s*[-–to]+\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)?)?)?',
  caseSensitive: false,
);
final _numeric = RegExp(
  r'\b(\d{1,2})/(\d{1,2})/(\d{4})(?:[\s,]+(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?(?:\s*[-–to]+\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)?)?)?',
  caseSensitive: false,
);
final _iso = RegExp(r'\b(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2}))?');

int _hour(String h, String? ampm) {
  var v = int.parse(h);
  final a = ampm?.toLowerCase();
  if (a == 'pm' && v < 12) v += 12;
  if (a == 'am' && v == 12) v = 0;
  return v;
}

/// Start (and end, when the text says one) of the meeting described by
/// [text], as local wall-clock times. Null when nothing date-like is found.
/// An "am/pm" given only on the end time is applied to the start as well
/// ("2-3 PM"); a start without any time becomes 9:00.
({DateTime start, DateTime? end})? guessMeetingTime(String text) {
  final m = _monthName.firstMatch(text);
  if (m != null) {
    final month = _months[m.group(1)!.toLowerCase().replaceAll('.', '')];
    if (month != null) {
      return _build(int.parse(m.group(3)!), month, int.parse(m.group(2)!), m.group(4), m.group(5), m.group(6), m.group(7), m.group(8), m.group(9));
    }
  }
  final n = _numeric.firstMatch(text);
  if (n != null) {
    return _build(int.parse(n.group(3)!), int.parse(n.group(1)!), int.parse(n.group(2)!), n.group(4), n.group(5), n.group(6), n.group(7), n.group(8), n.group(9));
  }
  final i = _iso.firstMatch(text);
  if (i != null) {
    final start = DateTime(int.parse(i.group(1)!), int.parse(i.group(2)!), int.parse(i.group(3)!), int.parse(i.group(4) ?? '9'), int.parse(i.group(5) ?? '0'));
    return (start: start, end: null);
  }
  return null;
}

({DateTime start, DateTime? end})? _build(int y, int mo, int d, String? h1, String? m1, String? ap1, String? h2, String? m2, String? ap2) {
  if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
  if (h1 == null) return (start: DateTime(y, mo, d, 9), end: null);
  final ap = ap1 ?? ap2;
  final start = DateTime(y, mo, d, _hour(h1, ap), int.parse(m1 ?? '0'));
  DateTime? end;
  if (h2 != null) {
    end = DateTime(y, mo, d, _hour(h2, ap2 ?? ap), int.parse(m2 ?? '0'));
    if (!end.isAfter(start)) end = null;
  }
  return (start: start, end: end);
}
