import '../../domain/entities/entities.dart';

/// A conversation: one or more messages joined by their References /
/// In-Reply-To chain, or (as a fallback) by normalized subject plus a shared
/// participant.
class MessageThread {
  MessageThread._({
    required this.id,
    required this.messages,
    required this.participants,
    required this.subject,
  })  : latest = messages.last,
        lastDate = messages.last.date,
        unreadCount = messages.where((m) => !m.isSeen).length,
        hasAttachments = messages.any((m) => m.hasAttachments),
        isFlagged = messages.any((m) => m.isFlagged);

  /// Stable across rebuilds: the messageIdHash of the oldest message.
  final String id;

  /// Oldest first.
  final List<MessageHeader> messages;
  final MessageHeader latest;
  final int unreadCount;
  final bool hasAttachments;
  final bool isFlagged;

  /// Lower-cased addresses of everyone in From/To/Cc across the thread.
  final Set<String> participants;

  /// Subject of the oldest message that has one, with reply/forward prefixes kept.
  final String subject;
  final DateTime lastDate;

  bool get isSingle => messages.length == 1;
  bool contains(MessageHeader h) => messages.any((m) => m.messageIdHash == h.messageIdHash);
}

final _prefix = RegExp(r'^\s*((re|fwd?|fw|aw|wg|sv|vs|antw)\s*(\[\d+\])?\s*:\s*|\[[^\]]*\]\s*)+', caseSensitive: false);

/// Strips Re:/Fwd:/AW:/[list tags] repeatedly, lower-cases, trims and squeezes
/// whitespace. Empty when nothing meaningful is left.
String normalizeSubject(String s) => s.replaceAll(_prefix, '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// `<Abc@x>` / ` abc@X ` -> `abc@x`. Empty when there is no id.
String _normId(String? raw) {
  if (raw == null) return '';
  var s = raw.trim();
  if (s.startsWith('<')) s = s.substring(1);
  if (s.endsWith('>')) s = s.substring(0, s.length - 1);
  return s.trim().toLowerCase();
}

Iterable<String> _refIds(MessageHeader h) sync* {
  for (final r in h.references) {
    for (final part in r.split(RegExp(r'\s+'))) {
      final id = _normId(part);
      if (id.isNotEmpty) yield id;
    }
  }
  final irt = _normId(h.inReplyTo);
  if (irt.isNotEmpty) yield irt;
}

Set<String> _participantsOf(MessageHeader h) => {
      if (h.from != null) h.from!.email.toLowerCase(),
      for (final a in h.to) a.email.toLowerCase(),
      for (final a in h.cc) a.email.toLowerCase(),
    }..removeWhere((e) => e.isEmpty);

int _byDateThenHash(MessageHeader a, MessageHeader b) {
  final c = a.date.compareTo(b.date);
  return c != 0 ? c : a.messageIdHash.compareTo(b.messageIdHash);
}

/// Union-find over Message-ID strings with path halving and union by size.
class _UnionFind {
  final Map<String, String> _parent = {};
  final Map<String, int> _size = {};

  String find(String x) {
    _parent.putIfAbsent(x, () => x);
    var cur = x;
    while (_parent[cur] != cur) {
      final gp = _parent[_parent[cur]!]!;
      _parent[cur] = gp;
      cur = gp;
    }
    return cur;
  }

  String union(String a, String b) {
    var ra = find(a), rb = find(b);
    if (ra == rb) return ra;
    final sa = _size[ra] ?? 1, sb = _size[rb] ?? 1;
    // Deterministic: larger set wins, ties broken by key order.
    if (sa < sb || (sa == sb && ra.compareTo(rb) > 0)) {
      final t = ra;
      ra = rb;
      rb = t;
    }
    _parent[rb] = ra;
    _size[ra] = sa + sb;
    return ra;
  }
}

/// Groups [msgs] into conversations. O(n log n); deterministic for equal input.
///
/// 1. Messages are joined through every Message-ID they mention (their own,
///    In-Reply-To, References), so partial chains and missing intermediate
///    messages still end up in one thread.
/// 2. A message whose headers connected it to nothing (none present, or all
///    pointing at messages not in the list) joins an existing thread when its
///    normalized subject is non-empty and equal, and it shares a participant
///    with that thread. Addresses in [ownAddresses] (the user's own) do not
///    count as shared, otherwise every mail addressed to the user would match.
/// 3. Threads are sorted newest activity first.
List<MessageThread> buildThreads(List<MessageHeader> msgs, {Set<String> ownAddresses = const {}}) {
  if (msgs.isEmpty) return const [];
  final sorted = List<MessageHeader>.of(msgs)..sort(_byDateThenHash);
  final own = {for (final a in ownAddresses) a.toLowerCase()};

  // Node key for each message: its Message-ID or, lacking one, its hash.
  String nodeOf(MessageHeader h) {
    final id = _normId(h.messageId);
    return id.isNotEmpty ? 'id:$id' : 'hash:${h.messageIdHash}';
  }

  final uf = _UnionFind();
  final known = <String>{for (final h in sorted) nodeOf(h)};
  final connected = <String>{}; // message nodes whose headers hit a known message
  for (final h in sorted) {
    final me = nodeOf(h);
    uf.find(me);
    for (final r in _refIds(h)) {
      final node = 'id:$r';
      if (node == me) continue;
      uf.union(me, node);
      if (known.contains(node)) {
        connected.add(me);
        connected.add(node);
      }
    }
  }

  // Subject fallback. subject -> participant -> some node in that group.
  final bySubject = <String, Map<String, String>>{};
  final participantsOf = <MessageHeader, Set<String>>{for (final h in sorted) h: _participantsOf(h)};
  for (final h in sorted) {
    final me = nodeOf(h);
    final subj = normalizeSubject(h.subject);
    if (subj.isEmpty) continue;
    final index = bySubject.putIfAbsent(subj, () => {});
    final shared = participantsOf[h]!.where((p) => !own.contains(p)).toList();
    if (!connected.contains(me)) {
      for (final p in shared) {
        final other = index[p];
        if (other != null && uf.find(other) != uf.find(me)) {
          uf.union(me, other);
          break;
        }
      }
    }
    for (final p in shared) {
      index.putIfAbsent(p, () => me);
    }
  }

  // Collect groups (input already oldest-first, so each list is oldest-first).
  final groups = <String, List<MessageHeader>>{};
  for (final h in sorted) {
    groups.putIfAbsent(uf.find(nodeOf(h)), () => []).add(h);
  }

  final threads = <MessageThread>[];
  for (final list in groups.values) {
    final participants = <String>{for (final h in list) ...participantsOf[h]!};
    final subject = list.firstWhere((m) => m.subject.trim().isNotEmpty, orElse: () => list.first).subject;
    threads.add(MessageThread._(
      id: list.first.messageIdHash,
      messages: List.unmodifiable(list),
      participants: Set.unmodifiable(participants),
      subject: subject,
    ));
  }
  threads.sort((a, b) {
    final c = b.lastDate.compareTo(a.lastDate);
    return c != 0 ? c : a.id.compareTo(b.id);
  });
  return threads;
}

/// Threads of a folder's messages with the user's own replies from the Sent
/// folder folded in: Sent mail joins through its References / In-Reply-To
/// headers (or the subject fallback), and threads made only of Sent mail are
/// dropped so the folder shows nothing it does not hold itself.
List<MessageThread> buildThreadsWithSent(List<MessageHeader> folder, List<MessageHeader> sent, {Set<String> ownAddresses = const {}}) {
  if (sent.isEmpty) return buildThreads(folder, ownAddresses: ownAddresses);
  final inFolder = {for (final h in folder) h.messageIdHash};
  final merged = [...folder, for (final h in sent) if (!inFolder.contains(h.messageIdHash)) h];
  final threads = buildThreads(merged, ownAddresses: ownAddresses);
  return [for (final t in threads) if (t.messages.any((m) => inFolder.contains(m.messageIdHash))) t];
}

/// "Alice, Bob, you" for the thread header: distinct senders oldest-first,
/// the user's own addresses collapsed to "you" at the end.
String participantSummary(MessageThread t, {Set<String> ownAddresses = const {}, int max = 3}) {
  final own = {for (final a in ownAddresses) a.toLowerCase()};
  final names = <String>[];
  final seen = <String>{};
  var includesYou = false;
  for (final m in t.messages) {
    final f = m.from;
    if (f == null) continue;
    final email = f.email.toLowerCase();
    if (own.contains(email)) {
      includesYou = true;
      continue;
    }
    if (!seen.add(email)) continue;
    final name = (f.name?.trim().isNotEmpty ?? false) ? f.name!.trim() : f.email;
    names.add(name.split(RegExp(r'\s+')).first);
  }
  if (names.isEmpty && !includesYou) return t.latest.from?.email ?? '(unknown)';
  final shown = names.take(includesYou ? max - 1 : max).toList();
  final hidden = names.length - shown.length;
  if (hidden > 0) shown.add('+$hidden');
  if (includesYou) shown.add('you');
  return shown.join(', ');
}
