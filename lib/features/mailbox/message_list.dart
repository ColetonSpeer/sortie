import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';
import '../../router/app_router.dart';
import '../settings/settings_common.dart';
import '../shell/adaptive_scaffold.dart';
import 'message_actions.dart';
import 'message_tile.dart';
import 'thread_tile.dart';
import 'threading.dart';

/// Middle pane: search, list of tiles, swipe actions, multi-select toolbar.
class MessageListPane extends ConsumerStatefulWidget {
  const MessageListPane({
    super.key,
    required this.accountId,
    required this.folderPath,
    required this.selectedUid,
    required this.showMenuButton,
    this.selectedFolder,
  });
  final String accountId;
  final String folderPath;
  final int? selectedUid;
  final bool showMenuButton;

  /// Folder of the selected message; defaults to [folderPath].
  final String? selectedFolder;

  @override
  ConsumerState<MessageListPane> createState() => _MessageListPaneState();
}

class _MessageListPaneState extends ConsumerState<MessageListPane> {
  final _search = TextEditingController();
  bool _searching = false;

  // buildThreads memo: the stream hands us a new list only when data changed.
  List<MessageHeader>? _threadedFrom;
  List<MessageHeader>? _threadedSent;
  Set<String>? _threadedOwn;
  List<MessageThread> _threads = const [];

  @override
  void didUpdateWidget(covariant MessageListPane old) {
    super.didUpdateWidget(old);
    if (old.folderPath != widget.folderPath || old.accountId != widget.accountId) {
      ref.read(selectedMessagesProvider.notifier).state = const {};
      ref.read(expandedThreadsProvider.notifier).state = const {};
    }
  }

  /// The user's own addresses (account + identities), lower-cased.
  Set<String> _ownAddresses() {
    final account = ref.watch(accountsProvider).asData?.value.where((a) => a.id == widget.accountId).firstOrNull;
    final identities = ref.watch(identitiesProvider(widget.accountId)).asData?.value ?? const [];
    return {
      if (account != null) account.email.toLowerCase(),
      for (final i in identities) i.email.toLowerCase(),
    };
  }

  List<MessageThread> _threadsFor(List<MessageHeader> list, List<MessageHeader> sent, Set<String> own) {
    if (!identical(list, _threadedFrom) || !identical(sent, _threadedSent) || !setEquals(_threadedOwn, own)) {
      _threadedFrom = list;
      _threadedSent = sent;
      _threadedOwn = own;
      _threads = buildThreadsWithSent(list, sent, ownAddresses: own);
    }
    return _threads;
  }

  void _select(Set<MessageKey> s) => ref.read(selectedMessagesProvider.notifier).state = s;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = (accountId: widget.accountId, folderPath: widget.folderPath, search: _search.text.trim());
    final messages = ref.watch(messagesProvider(key));
    final badges = ref.watch(pendingBadgesProvider(widget.accountId)).asData?.value ?? const <MessageKey, PendingBadge>{};
    final selection = ref.watch(selectedMessagesProvider);
    final folder = ref.watch(foldersProvider(widget.accountId)).asData?.value.where((f) => f.path == widget.folderPath).firstOrNull;
    final title = folder == null ? widget.folderPath : (folder.isInbox ? 'Inbox' : folder.name);
    final touch = MediaQuery.sizeOf(context).width < AdaptiveScaffold.compactBreakpoint;
    final threaded = ref.watch(deviceSettingsProvider).asData?.value.threadedView ?? true;
    final own = threaded ? _ownAddresses() : const <String>{};
    final isInbox = folder?.isInbox ?? widget.folderPath.toUpperCase() == 'INBOX';
    // Your own replies live in Sent; fold them into the threads of ordinary
    // folders so a conversation reads whole.
    final sentPath = ref.watch(foldersProvider(widget.accountId)).asData?.value.where((f) => f.specialUse == SpecialUse.sent).firstOrNull?.path;
    final su = folder?.specialUse ?? SpecialUse.none;
    final mergeSent = threaded &&
        sentPath != null &&
        sentPath != widget.folderPath &&
        (isInbox || su == SpecialUse.none || su == SpecialUse.archive);
    final sentList = mergeSent
        ? ref.watch(messagesProvider((accountId: widget.accountId, folderPath: sentPath, search: ''))).asData?.value ?? const <MessageHeader>[]
        : const <MessageHeader>[];
    final suggestionCount = isInbox && !ref.watch(suggestionBannerDismissedProvider)
        ? (ref.watch(pendingSuggestionsProvider(widget.accountId)).asData?.value.length ?? 0)
        : 0;

    Widget tile(MessageHeader h) {
      final t = MessageTile(
        header: h,
        badge: badges[h.key],
        selected: h.uid == widget.selectedUid && h.folderPath == (widget.selectedFolder ?? widget.folderPath),
        checked: selection.contains(h.key),
        selectionMode: selection.isNotEmpty,
        onTap: () => context.go(Routes.messageIn(widget.accountId, widget.folderPath, h.folderPath, h.uid)),
        onToggleCheck: () {
          final s = Set<MessageKey>.of(selection);
          s.contains(h.key) ? s.remove(h.key) : s.add(h.key);
          _select(s);
        },
      );
      return touch ? _Swipeable(header: h, child: t) : t;
    }

    return Scaffold(
      appBar: selection.isNotEmpty
          ? _SelectionBar(
              accountId: widget.accountId,
              selection: selection,
              all: messages.asData?.value ?? const [],
              onClear: () => ref.read(selectedMessagesProvider.notifier).state = const {},
            )
          : AppBar(
              leading: widget.showMenuButton
                  ? IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())
                  : null,
              automaticallyImplyLeading: false,
              title: _searching
                  ? TextField(
                      controller: _search,
                      autofocus: true,
                      decoration: const InputDecoration(hintText: 'Search this folder', border: InputBorder.none),
                      onChanged: (_) => setState(() {}),
                    )
                  : Text(title),
              actions: [
                IconButton(
                  tooltip: _searching ? 'Close search' : 'Search',
                  icon: Icon(_searching ? Icons.close : Icons.search),
                  onPressed: () => setState(() {
                    _searching = !_searching;
                    if (!_searching) _search.clear();
                  }),
                ),
                IconButton(
                  tooltip: 'Sync now',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.read(mailSyncServiceProvider).syncNow(widget.accountId, folderPath: widget.folderPath),
                ),
                PopupMenuButton<String>(
                  tooltip: 'More',
                  onSelected: (v) {
                    if (v == 'threaded') saveDeviceSettings(ref, (d) => d.copyWith(threadedView: !threaded));
                  },
                  itemBuilder: (_) => [
                    CheckedPopupMenuItem(value: 'threaded', checked: threaded, child: const Text('Group by conversation')),
                  ],
                ),
              ],
            ),
      body: Column(children: [
        if (suggestionCount > 0) _SuggestionBanner(count: suggestionCount),
        Expanded(child: _content(context, messages, sentList, threaded, own, selection, badges, tile)),
      ]),
    );
  }

  Widget _content(BuildContext context, AsyncValue<List<MessageHeader>> messages, List<MessageHeader> sent, bool threaded, Set<String> own,
      Set<MessageKey> selection, Map<MessageKey, PendingBadge> badges, Widget Function(MessageHeader) tile) =>
      messages.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load messages: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(_search.text.isEmpty ? 'Nothing here' : 'No matches',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.outline)),
            );
          }
          if (threaded) {
            final threads = _threadsFor(list, sent, own);
            return ListView.separated(
              key: PageStorageKey('threads:${widget.accountId}:${widget.folderPath}'),
              itemCount: threads.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 58),
              itemBuilder: (context, i) {
                final t = threads[i];
                final keys = t.messages.map((m) => m.key).toSet();
                return ThreadTile(
                  key: ValueKey('thread:${t.id}'),
                  thread: t,
                  ownAddresses: own,
                  selection: selection,
                  badge: badges[t.latest.key],
                  buildMessageTile: tile,
                  onSelectAll: () => _select({...selection, ...keys}),
                  onToggleAll: () => _select(selection.containsAll(keys) ? selection.difference(keys) : {...selection, ...keys}),
                );
              },
            );
          }
          return ListView.separated(
            key: PageStorageKey('msgs:${widget.accountId}:${widget.folderPath}'),
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 58),
            itemBuilder: (context, i) => tile(list[i]),
          );
        },
      );
}

/// One-line "N suggested sorting rules — Review" strip above the inbox.
class _SuggestionBanner extends ConsumerWidget {
  const _SuggestionBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      key: const Key('suggestionBanner'),
      color: cs.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        child: Row(children: [
          Icon(Icons.tips_and_updates_outlined, size: 18, color: cs.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(child: Text('$count suggested sorting rule${count == 1 ? '' : 's'}', style: TextStyle(color: cs.onSecondaryContainer))),
          TextButton(onPressed: () => context.push(Routes.sortLog), child: const Text('Review')),
          IconButton(
            tooltip: 'Hide for now',
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => ref.read(suggestionBannerDismissedProvider.notifier).state = true,
          ),
        ]),
      ),
    );
  }
}

/// Swipe right = archive, swipe left = delete (touch layouts only). Actions
/// run optimistically; the list stream removes the row, so we never let
/// Dismissible remove it itself.
class _Swipeable extends ConsumerWidget {
  const _Swipeable({required this.header, required this.child});
  final MessageHeader header;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    Widget bg(Color c, IconData i, String t, Alignment a) => Container(
          color: c,
          alignment: a,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(i, color: cs.onPrimary),
            Text(t, style: TextStyle(color: cs.onPrimary, fontSize: 12)),
          ]),
        );
    return Dismissible(
      key: ValueKey('swipe:${header.messageIdHash}'),
      background: bg(cs.primary, Icons.archive_outlined, 'Archive', Alignment.centerLeft),
      secondaryBackground: bg(cs.error, Icons.delete_outline, 'Delete', Alignment.centerRight),
      confirmDismiss: (dir) async {
        final a = MessageActions(context, ref);
        if (dir == DismissDirection.startToEnd) {
          await a.archive([header]);
        } else {
          await a.delete([header]);
        }
        return false;
      },
      child: child,
    );
  }
}

class _SelectionBar extends ConsumerWidget implements PreferredSizeWidget {
  const _SelectionBar({required this.accountId, required this.selection, required this.all, required this.onClear});
  final String accountId;
  final Set<MessageKey> selection;
  final List<MessageHeader> all;
  final VoidCallback onClear;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final msgs = all.where((h) => selection.contains(h.key)).toList();
    final a = MessageActions(context, ref);
    Future<void> run(Future<void> Function() f) async {
      await f();
      onClear();
    }

    final anyUnread = msgs.any((m) => !m.isSeen);
    return AppBar(
      leading: IconButton(icon: const Icon(Icons.close), tooltip: 'Clear selection', onPressed: onClear),
      title: Text('${msgs.length} selected'),
      actions: [
        IconButton(
          tooltip: anyUnread ? 'Mark read' : 'Mark unread',
          icon: Icon(anyUnread ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined),
          onPressed: () => run(() => a.markRead(msgs, read: anyUnread)),
        ),
        IconButton(tooltip: 'Flag', icon: const Icon(Icons.star_outline), onPressed: () => run(() => a.flag(msgs))),
        IconButton(tooltip: 'Archive', icon: const Icon(Icons.archive_outlined), onPressed: () => run(() => a.archive(msgs))),
        IconButton(tooltip: 'Move to…', icon: const Icon(Icons.drive_file_move_outline), onPressed: () => run(() => a.movePrompt(msgs))),
        IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline), onPressed: () => run(() => a.delete(msgs))),
        IconButton(
          tooltip: 'Select all',
          icon: const Icon(Icons.select_all),
          onPressed: () => ref.read(selectedMessagesProvider.notifier).state = all.map((h) => h.key).toSet(),
        ),
      ],
    );
  }
}
