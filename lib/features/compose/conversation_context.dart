import '../../domain/entities/entities.dart';
import '../../services/compose/draft_reviewer.dart';
import '../../services/sorter/text_cleaner.dart';
import 'compose_backend.dart';

/// The thread a reply answers, for the AI review: the message being replied
/// to plus up to [maxEarlier] earlier messages reachable through its
/// References, oldest first. Each message's own quoted tail is stripped so
/// the thread is not repeated inside itself. Best effort: anything missing
/// from the local cache is skipped.
Future<List<ConversationTurn>> gatherConversation(ComposeBackend backend, MessageHeader source, {int maxEarlier = 3, int maxChars = 2500}) async {
  final turns = <ConversationTurn>[];
  Future<ConversationTurn?> turnOf(MessageHeader h) async {
    try {
      final body = await backend.body(h.accountId, h.folderPath, h.uid);
      var text = TextCleaner.stripQuotedReplies(body.text).trim();
      if (text.isEmpty) text = body.text.trim();
      if (text.isEmpty) return null;
      if (text.length > maxChars) text = '${text.substring(0, maxChars)}\n[...]';
      final from = h.from == null ? 'unknown' : (h.from!.name?.isNotEmpty == true ? '${h.from!.name} <${h.from!.email}>' : h.from!.email);
      return ConversationTurn(from: from, text: text, date: h.date);
    } catch (_) {
      return null;
    }
  }

  // References are oldest-first; take the last few before the source.
  final seen = <String>{source.messageIdHash};
  final earlier = <MessageHeader>[];
  for (final mid in source.references.reversed) {
    if (earlier.length >= maxEarlier) break;
    final h = await backend.messageById(source.accountId, mid);
    if (h == null || !seen.add(h.messageIdHash)) continue;
    earlier.add(h);
  }
  for (final h in earlier.reversed) {
    final t = await turnOf(h);
    if (t != null) turns.add(t);
  }
  final last = await turnOf(source);
  if (last != null) turns.add(last);
  return turns;
}
