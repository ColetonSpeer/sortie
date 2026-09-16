import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';
import '../../router/app_router.dart';
import '../shell/adaptive_scaffold.dart';
import 'message_actions.dart';
import 'message_tile.dart';

/// Middle pane: search, list of tiles, swipe actions, multi-select toolbar.
class MessageListPane extends ConsumerStatefulWidget {
  const MessageListPane({
    super.key,
    required this.accountId,
    required this.folderPath,
    required this.selectedUid,
    required this.showMenuButton,
  });
  final String accountId;
  final String folderPath;
  final int? selectedUid;
  final bool showMenuButton;

  @override
  ConsumerState<MessageListPane> createState() => _MessageListPaneState();
}

class _MessageListPaneState extends ConsumerState<MessageListPane> {
  final _search = TextEditingController();
  bool _searching = false;

  @override
  void didUpdateWidget(covariant MessageListPane old) {
    super.didUpdateWidget(old);
    if (old.folderPath != widget.folderPath || old.accountId != widget.accountId) {
      ref.read(selectedMessagesProvider.notifier).state = const {};
    }
  }

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
              ],
            ),
      body: messages.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load messages: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(_search.text.isEmpty ? 'Nothing here' : 'No matches',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.outline)),
            );
          }
          return ListView.separated(
            key: PageStorageKey('msgs:${widget.accountId}:${widget.folderPath}'),
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 58),
            itemBuilder: (context, i) {
              final h = list[i];
              final tile = MessageTile(
                header: h,
                badge: badges[h.key],
                selected: h.uid == widget.selectedUid,
                checked: selection.contains(h.key),
                selectionMode: selection.isNotEmpty,
                onTap: () => context.go(Routes.message(widget.accountId, widget.folderPath, h.uid)),
                onToggleCheck: () {
                  final s = Set<MessageKey>.of(selection);
                  s.contains(h.key) ? s.remove(h.key) : s.add(h.key);
                  ref.read(selectedMessagesProvider.notifier).state = s;
                },
              );
              if (!touch) return tile;
              return _Swipeable(header: h, child: tile);
            },
          );
        },
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
