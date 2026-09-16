import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';
import '../shell/format.dart';
import 'badge_chip.dart';
import 'message_actions.dart';

/// One row of the message list.
class MessageTile extends ConsumerWidget {
  const MessageTile({
    super.key,
    required this.header,
    required this.selected,
    required this.checked,
    required this.selectionMode,
    required this.onTap,
    required this.onToggleCheck,
    this.badge,
  });

  final MessageHeader header;
  final bool selected;
  final bool checked;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onToggleCheck;
  final PendingBadge? badge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final unread = !header.isSeen;
    final weight = unread ? FontWeight.w700 : FontWeight.w400;
    final actions = MessageActions(context, ref);

    void menu(Offset pos) => showMessageMenu(context, ref, header, position: pos, badge: badge);

    return Listener(
      onPointerDown: (e) {
        if (e.kind == PointerDeviceKind.mouse && e.buttons == kSecondaryMouseButton) menu(e.position);
      },
      child: Material(
        color: selected ? cs.secondaryContainer : Colors.transparent,
        child: InkWell(
          onTap: selectionMode ? onToggleCheck : onTap,
          onLongPress: () {
            if (selectionMode) return;
            final box = context.findRenderObject() as RenderBox?;
            final pos = box == null ? Offset.zero : box.localToGlobal(box.size.center(Offset.zero));
            menu(pos);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Leading(header: header, checked: checked, selectionMode: selectionMode, onToggle: onToggleCheck),
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
                      child: Text(Fmt.sender(header),
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: weight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (header.hasAttachments)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.attach_file, size: 14, color: cs.onSurfaceVariant),
                      ),
                    const SizedBox(width: 6),
                    Text(Fmt.relativeDate(header.date),
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: unread ? cs.primary : cs.onSurfaceVariant,
                            fontWeight: unread ? FontWeight.w600 : null)),
                  ]),
                  const SizedBox(height: 2),
                  Text(header.subject.isEmpty ? '(no subject)' : header.subject,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: weight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (header.snippet.isNotEmpty)
                    Text(header.snippet,
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  if (badge != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: PendingBadgeChip(
                        badge: badge!,
                        onTap: () => actions.badgeWhy(header, badge!),
                        onMove: () => actions.badgeMoveNow(header.key),
                        onDismiss: () => actions.badgeKeep(header.key),
                      ),
                    ),
                ]),
              ),
              const SizedBox(width: 4),
              InkResponse(
                radius: 18,
                onTap: () => actions.toggleFlag(header),
                child: Icon(header.isFlagged ? Icons.star : Icons.star_outline,
                    size: 18, color: header.isFlagged ? cs.tertiary : cs.outlineVariant),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.header, required this.checked, required this.selectionMode, required this.onToggle});
  final MessageHeader header;
  final bool checked;
  final bool selectionMode;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (selectionMode || checked) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Checkbox(value: checked, onChanged: (_) => onToggle()),
      );
    }
    return InkResponse(
      radius: 22,
      onTap: onToggle,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: cs.surfaceContainerHighest,
        foregroundColor: cs.onSurfaceVariant,
        child: Text(Fmt.initials(Fmt.sender(header)), style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}
