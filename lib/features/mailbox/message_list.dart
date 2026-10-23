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
import 'swipe_actions.dart';
import 'thread_tile.dart';
import 'threading.dart';

/// Middle pane: search, list of tiles, swipe actions, multi-select toolbar.
///
/// With [MessageListPane.accountId] set to [Routes.allAccounts] it shows the
/// INBOX of every account in one list ("All inboxes"): rows carry the account
/// name, conversations are built per account (two accounts receiving the same
/// mail must not merge), and actions run per account.
class MessageListPane extends ConsumerStatefulWidget {
  const MessageListPane({
    super.key,
    required this.accountId,
    required this.folderPath,
    required this.selectedUid,
    required this.showMenuButton,
    this.selectedFolder,
    this.selectedAccount,
  });
  final String accountId;
  final String folderPath;
  final int? selectedUid;
  final bool showMenuButton;

  /// Folder of the selected message; defaults to [folderPath].
  final String? selectedFolder;

  /// Account of the selected message; defaults to [accountId].
  final String? selectedAccount;

  @override
  ConsumerState<MessageListPane> createState() => _MessageListPaneState();
}

class _MessageListPaneState extends ConsumerState<MessageListPane> {
  final _search = TextEditingController();
  bool _searching = false;

  // buildThreads memo per account: the stream hands us a new list only when
  // data changed.
  final _threadMemo = <String, _ThreadMemo>{};
  List<MessageThread> _mergedThreads = const [];
  List<List<MessageThread>>? _mergedFrom;

  // Merged flat list memo (All inboxes).
  List<List<MessageHeader>>? _flatFrom;
  List<MessageHeader> _flat = const [];

  bool get _isAll => widget.accountId == Routes.allAccounts;

  /// The folder each row lives in: the route's folder, or INBOX for All inboxes.
  String get _listFolder => _isAll ? 'INBOX' : widget.folderPath;

  @override
  void didUpdateWidget(covariant MessageListPane old) {
    super.didUpdateWidget(old);
    if (old.folderPath != widget.folderPath || old.accountId != widget.accountId) {
      ref.read(selectedMessagesProvider.notifier).state = const {};
      ref.read(expandedThreadsProvider.notifier).state = const {};
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Account> _accounts() {
    final all = ref.watch(accountsProvider).asData?.value ?? const <Account>[];
    return _isAll ? all : all.where((a) => a.id == widget.accountId).toList();
  }

  /// The user's own addresses (accounts + identities), lower-cased.
  Set<String> _ownAddresses(List<Account> accounts) => {
        for (final a in accounts) a.email.toLowerCase(),
        for (final a in accounts)
          for (final i in ref.watch(identitiesProvider(a.id)).asData?.value ?? const <Identity>[]) i.email.toLowerCase(),
      };

  List<MessageThread> _threadsFor(String accountId, List<MessageHeader> list, List<MessageHeader> sent, Set<String> own) {
    final m = _threadMemo[accountId];
    if (m != null && identical(list, m.from) && identical(sent, m.sent) && setEquals(m.own, own)) return m.threads;
    final threads = buildThreadsWithSent(list, sent, ownAddresses: own);
    _threadMemo[accountId] = _ThreadMemo(list, sent, own, threads);
    return threads;
  }

  List<MessageThread> _mergeThreads(List<List<MessageThread>> parts) {
    final prev = _mergedFrom;
    if (prev != null && prev.length == parts.length && [for (var i = 0; i < parts.length; i++) identical(prev[i], parts[i])].every((x) => x)) {
      return _mergedThreads;
    }
    _mergedFrom = parts;
    return _mergedThreads = [for (final p in parts) ...p]
      ..sort((a, b) {
        final c = b.lastDate.compareTo(a.lastDate);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
  }

  List<MessageHeader> _mergeFlat(List<List<MessageHeader>> parts) {
    final prev = _flatFrom;
    if (prev != null && prev.length == parts.length && [for (var i = 0; i < parts.length; i++) identical(prev[i], parts[i])].every((x) => x)) {
      return _flat;
    }
    _flatFrom = parts;
    return _flat = [for (final p in parts) ...p]..sort((a, b) => b.date.compareTo(a.date));
  }

  void _select(Set<MessageKey> s) => ref.read(selectedMessagesProvider.notifier).state = s;

  @override
  Widget build(BuildContext context) {
    final accounts = _accounts();
    final ids = _isAll ? [for (final a in accounts) a.id] : [widget.accountId];
    final search = _search.text.trim();
    final lists = {for (final id in ids) id: ref.watch(messagesProvider((accountId: id, folderPath: _listFolder, search: search)))};
    final badges = <MessageKey, PendingBadge>{
      for (final id in ids) ...ref.watch(pendingBadgesProvider(id)).asData?.value ?? const <MessageKey, PendingBadge>{},
    };
    final selection = ref.watch(selectedMessagesProvider);
    final folder = _isAll ? null : ref.watch(foldersProvider(widget.accountId)).asData?.value.where((f) => f.path == widget.folderPath).firstOrNull;
    final title = _isAll ? 'All inboxes' : folder == null ? widget.folderPath : (folder.isInbox ? 'Inbox' : folder.name);
    final touch = MediaQuery.sizeOf(context).width < AdaptiveScaffold.compactBreakpoint;
    final threaded = ref.watch(deviceSettingsProvider).asData?.value.threadedView ?? true;
    final own = threaded ? _ownAddresses(accounts) : const <String>{};
    final isInbox = _isAll || (folder?.isInbox ?? widget.folderPath.toUpperCase() == 'INBOX');
    // Your own replies live in Sent; fold them into the threads of ordinary
    // folders so a conversation reads whole.
    final su = folder?.specialUse ?? SpecialUse.none;
    final sentLists = <String, List<MessageHeader>>{};
    if (threaded && (isInbox || su == SpecialUse.none || su == SpecialUse.archive)) {
      for (final id in ids) {
        final sentPath = ref.watch(foldersProvider(id)).asData?.value.where((f) => f.specialUse == SpecialUse.sent).firstOrNull?.path;
        if (sentPath == null || sentPath == _listFolder) continue;
        sentLists[id] = ref.watch(messagesProvider((accountId: id, folderPath: sentPath, search: ''))).asData?.value ?? const <MessageHeader>[];
      }
    }
    var suggestionCount = 0;
    if (isInbox && !ref.watch(suggestionBannerDismissedProvider)) {
      for (final id in ids) {
        suggestionCount += ref.watch(pendingSuggestionsProvider(id)).asData?.value.length ?? 0;
      }
    }
    final labels = _isAll && accounts.length > 1 ? {for (final a in accounts) a.id: a.displayName} : const <String, String>{};
    final actions = MessageActions(context, ref);

    Widget tile(MessageHeader h) {
      final t = MessageTile(
        header: h,
        badge: badges[h.key],
        accountLabel: labels[h.accountId],
        selected: h.uid == widget.selectedUid &&
            h.folderPath == (widget.selectedFolder ?? widget.folderPath) &&
            h.accountId == (widget.selectedAccount ?? widget.accountId),
        checked: selection.contains(h.key),
        selectionMode: selection.isNotEmpty,
        onTap: () => context.go(Routes.messageIn(widget.accountId, widget.folderPath, h.folderPath, h.uid, account: h.accountId)),
        onToggleCheck: () {
          final s = Set<MessageKey>.of(selection);
          s.contains(h.key) ? s.remove(h.key) : s.add(h.key);
          _select(s);
        },
      );
      return touch
          ? SwipeToAct(
              swipeKey: ValueKey('swipe:${h.accountId}:${h.messageIdHash}'),
              onDelete: () => actions.delete([h]),
              onArchive: () => actions.archive([h]),
              child: t,
            )
          : t;
    }

    // Combined load state: loading until something arrives, error only when
    // nothing arrived at all.
    final AsyncValue<List<MessageHeader>> messages;
    final values = lists.values.toList();
    if (values.every((v) => v.isLoading && !v.hasValue)) {
      messages = const AsyncValue.loading();
    } else if (values.every((v) => v.hasError && !v.hasValue)) {
      messages = AsyncValue.error(values.first.error!, values.first.stackTrace ?? StackTrace.current);
    } else if (!_isAll) {
      messages = AsyncValue.data(values.first.asData?.value ?? const []);
    } else {
      messages = AsyncValue.data(_mergeFlat([for (final v in values) v.asData?.value ?? const <MessageHeader>[]]));
    }
    List<MessageThread> threads() => _mergeThreads([
          for (final id in ids) _threadsFor(id, lists[id]!.asData?.value ?? const [], sentLists[id] ?? const [], own),
        ]);

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
                      decoration: InputDecoration(hintText: _isAll ? 'Search all inboxes' : 'Search this folder', border: InputBorder.none),
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
                  onPressed: () {
                    final sync = ref.read(mailSyncServiceProvider);
                    for (final id in ids) {
                      sync.syncNow(id, folderPath: _listFolder);
                    }
                  },
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
        Expanded(child: _content(context, messages, threaded ? threads : null, own, selection, badges, labels, touch ? actions : null, tile)),
      ]),
    );
  }

  Widget _content(
    BuildContext context,
    AsyncValue<List<MessageHeader>> messages,
    List<MessageThread> Function()? threads,
    Set<String> own,
    Set<MessageKey> selection,
    Map<MessageKey, PendingBadge> badges,
    Map<String, String> labels,
    MessageActions? swipe,
    Widget Function(MessageHeader) tile,
  ) =>
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
          if (threads != null) {
            final ts = threads();
            return ListView.separated(
              key: PageStorageKey('threads:${widget.accountId}:${widget.folderPath}'),
              itemCount: ts.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 58),
              itemBuilder: (context, i) {
                final t = ts[i];
                final keys = t.messages.map((m) => m.key).toSet();
                // Swiping a conversation acts on its messages in this folder;
                // your own copies in Sent stay where they are.
                List<MessageHeader> here() => [for (final m in t.messages) if (m.folderPath == _listFolder) m];
                return ThreadTile(
                  key: ValueKey('thread:${t.latest.accountId}:${t.id}'),
                  thread: t,
                  ownAddresses: own,
                  selection: selection,
                  badge: badges[t.latest.key],
                  accountLabel: labels[t.latest.accountId],
                  buildMessageTile: tile,
                  onSelectAll: () => _select({...selection, ...keys}),
                  onToggleAll: () => _select(selection.containsAll(keys) ? selection.difference(keys) : {...selection, ...keys}),
                  onDelete: swipe == null ? null : () => swipe.delete(here()),
                  onArchive: swipe == null ? null : () => swipe.archive(here()),
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

class _ThreadMemo {
  const _ThreadMemo(this.from, this.sent, this.own, this.threads);
  final List<MessageHeader> from;
  final List<MessageHeader> sent;
  final Set<String> own;
  final List<MessageThread> threads;
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
