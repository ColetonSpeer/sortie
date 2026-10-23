import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';
import '../shell/format.dart';
import 'badge_chip.dart';
import 'message_actions.dart';
import 'message_tile.dart' show AccountLabel;
import 'swipe_actions.dart';
import 'threading.dart';

/// Ids of threads currently expanded in the message list (UI state only).
/// Keyed by [MessageThread.id] so it survives list rebuilds; the list pane
/// clears it when the folder changes.
final expandedThreadsProvider = StateProvider<Set<String>>((_) => const {});

/// One conversation in the threaded message list.
///
/// Single-message threads render the ordinary [MessageTile] through
/// [buildMessageTile]. Multi-message threads show a collapsible header row that
/// stays aligned with the tiles around it and, when expanded, the member tiles
/// indented below it (oldest first).
class ThreadTile extends ConsumerWidget {
  const ThreadTile({
    super.key,
    required this.thread,
    required this.ownAddresses,
    required this.selection,
    required this.buildMessageTile,
    required this.onSelectAll,
    required this.onToggleAll,
    this.badge,
    this.onDelete,
    this.onArchive,
    this.accountLabel,
  });

  final MessageThread thread;
  final Set<String> ownAddresses;

  /// Touch layouts: swiping the collapsed header right deletes the whole
  /// conversation, left archives it. Null = no swipe (desktop).
  final Future<void> Function()? onDelete;
  final Future<void> Function()? onArchive;

  /// Shown next to the date when the list mixes accounts.
  final String? accountLabel;

  /// Current multi-select state; non-empty means selection mode.
  final Set<MessageKey> selection;

  /// Builds the inner tile (with swipe wrapper etc.) for one member.
  final Widget Function(MessageHeader header) buildMessageTile;

  /// Long-press on the header: add every member to the selection.
  final VoidCallback onSelectAll;

  /// Selection-mode tap / checkbox: check or uncheck the whole thread.
  final VoidCallback onToggleAll;

  /// Pending sort decision of the latest message, if any.
  final PendingBadge? badge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (thread.isSingle) return buildMessageTile(thread.latest);

    final expanded = ref.watch(expandedThreadsProvider.select((s) => s.contains(thread.id)));
    void toggleExpand() {
      final s = Set<String>.of(ref.read(expandedThreadsProvider));
      s.contains(thread.id) ? s.remove(thread.id) : s.add(thread.id);
      ref.read(expandedThreadsProvider.notifier).state = s;
    }

    final cs = Theme.of(context).colorScheme;
    Widget header = _ThreadHeader(
      thread: thread,
      ownAddresses: ownAddresses,
      selection: selection,
      expanded: expanded,
      badge: badge,
      accountLabel: accountLabel,
      onToggleExpand: toggleExpand,
      onSelectAll: onSelectAll,
      onToggleAll: onToggleAll,
    );
    final del = onDelete;
    final arch = onArchive;
    if (del != null && arch != null && !expanded && !selection.isNotEmpty) {
      header = SwipeToAct(swipeKey: ValueKey('swipe-thread:${thread.id}'), onDelete: del, onArchive: arch, child: header);
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [
      header,
      // Custom instead of ExpansionTile so the header keeps MessageTile's geometry.
      AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: expanded
            ? Container(
                margin: const EdgeInsets.only(left: 27),
                decoration: BoxDecoration(border: Border(left: BorderSide(color: cs.outlineVariant, width: 2))),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    for (var i = 0; i < thread.messages.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 58),
                      buildMessageTile(thread.messages[i]),
                    ],
                  ]),
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
    ]);
  }
}

class _ThreadHeader extends ConsumerWidget {
  const _ThreadHeader({
    required this.thread,
    required this.ownAddresses,
    required this.selection,
    required this.expanded,
    required this.badge,
    required this.onToggleExpand,
    required this.onSelectAll,
    required this.onToggleAll,
    this.accountLabel,
  });

  final MessageThread thread;
  final Set<String> ownAddresses;
  final Set<MessageKey> selection;
  final bool expanded;
  final PendingBadge? badge;
  final String? accountLabel;
  final VoidCallback onToggleExpand;
  final VoidCallback onSelectAll;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final latest = thread.latest;
    final unread = thread.unreadCount > 0;
    final weight = unread ? FontWeight.w700 : FontWeight.w400;
    final selectionMode = selection.isNotEmpty;
    final checkedCount = thread.messages.where((m) => selection.contains(m.key)).length;
    final actions = MessageActions(context, ref);
    final n = thread.messages.length;
    final summary = participantSummary(thread, ownAddresses: ownAddresses);
    final senderFirst = Fmt.sender(latest).split(RegExp(r'\s+')).first;

    return Semantics(
      label: '$n messages in conversation, ${thread.unreadCount} unread',
      expanded: expanded,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // InkWell activates on Enter/Space when focused (ActivateIntent).
          onTap: selectionMode ? onToggleAll : onToggleExpand,
          onLongPress: onSelectAll,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Leading(
                latest: latest,
                selectionMode: selectionMode,
                checked: checkedCount == 0 ? false : (checkedCount == n ? true : null),
                onToggle: onToggleAll,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    if (unread)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                        ),
                      ),
                    Expanded(
                      child: Text(summary,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: weight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    _CountPill(count: n, unread: thread.unreadCount),
                    if (thread.hasAttachments)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.attach_file, size: 14, color: cs.onSurfaceVariant),
                      ),
                    if (accountLabel != null) AccountLabel(accountLabel!),
                    const SizedBox(width: 6),
                    Text(Fmt.relativeDate(thread.lastDate),
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: unread ? cs.primary : cs.onSurfaceVariant,
                            fontWeight: unread ? FontWeight.w600 : null)),
                  ]),
                  const SizedBox(height: 2),
                  Text(thread.subject.isEmpty ? '(no subject)' : thread.subject,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: weight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (latest.snippet.isNotEmpty)
                    Text('$senderFirst: ${latest.snippet}',
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  if (badge != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: PendingBadgeChip(
                        badge: badge!,
                        onTap: () => actions.badgeWhy(latest, badge!),
                        onMove: () => actions.badgeMoveNow(latest.key),
                        onDismiss: () => actions.badgeKeep(latest.key),
                      ),
                    ),
                ]),
              ),
              const SizedBox(width: 4),
              Column(children: [
                Icon(thread.isFlagged ? Icons.star : Icons.star_outline,
                    size: 18, color: thread.isFlagged ? cs.tertiary : cs.outlineVariant),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    tooltip: expanded ? 'Collapse conversation' : 'Expand conversation',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                    icon: Icon(Icons.expand_more, color: cs.onSurfaceVariant),
                    onPressed: onToggleExpand,
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.latest, required this.selectionMode, required this.checked, required this.onToggle});
  final MessageHeader latest;
  final bool selectionMode;

  /// null = some members selected.
  final bool? checked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (selectionMode) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Checkbox(value: checked, tristate: true, onChanged: (_) => onToggle()),
      );
    }
    return InkResponse(
      radius: 22,
      onTap: onToggle,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: cs.secondaryContainer,
        foregroundColor: cs.onSecondaryContainer,
        child: Text(Fmt.initials(Fmt.sender(latest)), style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count, required this.unread});
  final int count;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hot = unread > 0;
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: hot ? cs.primary : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: hot ? cs.onPrimary : cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
