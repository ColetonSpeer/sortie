import 'package:intl/intl.dart';

import '../../domain/entities/entities.dart';

/// Text helpers for reply / forward bodies and subjects.
abstract final class Quote {
  static String replySubject(String s) => RegExp(r'^\s*re:', caseSensitive: false).hasMatch(s) ? s : 'Re: $s';
  static String forwardSubject(String s) => RegExp(r'^\s*fwd?:', caseSensitive: false).hasMatch(s) ? s : 'Fwd: $s';

  static String reply(MessageHeader h, String bodyText) {
    final when = DateFormat.yMMMd().add_jm().format(h.date.toLocal());
    final quoted = bodyText.trimRight().split('\n').map((l) => l.startsWith('>') ? '>$l' : '> $l').join('\n');
    return '\n\nOn $when, ${h.from ?? 'someone'} wrote:\n$quoted\n';
  }

  static String forward(MessageHeader h, String bodyText) {
    final when = DateFormat.yMMMd().add_jm().format(h.date.toLocal());
    final b = StringBuffer('\n\n-------- Forwarded message --------\n')
      ..writeln('From: ${h.from ?? ''}')
      ..writeln('Date: $when')
      ..writeln('Subject: ${h.subject}')
      ..writeln('To: ${h.to.join(', ')}');
    if (h.cc.isNotEmpty) b.writeln('Cc: ${h.cc.join(', ')}');
    b
      ..writeln()
      ..write(bodyText.trimRight())
      ..writeln();
    return b.toString();
  }

  /// Picks the identity to send from: the one addressed in To/Cc, else the
  /// default, else the first.
  static Identity? pickIdentity(List<Identity> ids, MessageHeader? source) {
    if (ids.isEmpty) return null;
    if (source != null) {
      final addressed = {...source.to, ...source.cc}.map((a) => a.email.toLowerCase()).toSet();
      final hit = ids.where((i) => addressed.contains(i.email.toLowerCase())).firstOrNull;
      if (hit != null) return hit;
    }
    return ids.where((i) => i.isDefault).firstOrNull ?? ids.first;
  }

  /// Reply recipients, excluding our own identities.
  static (List<MailAddress> to, List<MailAddress> cc) replyRecipients(MessageHeader h, List<Identity> ids, {required bool all}) {
    final mine = ids.map((i) => i.email.toLowerCase()).toSet();
    bool notMine(MailAddress a) => !mine.contains(a.email.toLowerCase());
    final primary = h.replyTo ?? h.from;
    final to = <MailAddress>[?primary];
    if (!all) return (to, const []);
    for (final a in h.to) {
      if (notMine(a) && !to.any((t) => t.email.toLowerCase() == a.email.toLowerCase())) to.add(a);
    }
    final cc = h.cc.where(notMine).where((a) => !to.any((t) => t.email.toLowerCase() == a.email.toLowerCase())).toList();
    return (to, cc);
  }

  static MailAddress? parseAddress(String raw) {
    final s = raw.trim().replaceAll(RegExp(r'[,;]+$'), '');
    if (s.isEmpty) return null;
    final m = RegExp(r'^\s*"?([^"<]*)"?\s*<([^>]+)>\s*$').firstMatch(s);
    if (m != null) {
      final name = m.group(1)!.trim();
      return MailAddress(m.group(2)!.trim(), name.isEmpty ? null : name);
    }
    return isEmail(s) ? MailAddress(s) : null;
  }

  static bool isEmail(String s) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s.trim());
}
