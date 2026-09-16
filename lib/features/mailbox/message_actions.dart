import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';
import 'folder_picker.dart';
import 'why_sheet.dart';

/// User actions on one or more messages, shared by tile menus, swipe actions,
/// the multi-select toolbar and the message view. All are optimistic via the
/// sync service; errors surface as SnackBars.
class MessageActions {
  MessageActions(this.context, this.ref);
  final BuildContext context;
  final WidgetRef ref;

  MailSyncService get _sync => ref.read(mailSyncServiceProvider);

  void _snack(String msg, {SnackBarAction? action}) {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(msg), action: action));
  }

  Future<void> _guard(Future<void> Function() f, {String? done}) async {
    try {
      await f();
      if (done != null) _snack(done);
    } catch (e) {
      _snack('Failed: $e');
    }
  }

  Future<String?> _specialFolder(String accountId, SpecialUse use, String fallback) async {
    final folders = await ref.read(folderRepositoryProvider).all(accountId);
    return folders.where((f) => f.specialUse == use).firstOrNull?.path ??
        folders.where((f) => f.name.toLowerCase() == fallback.toLowerCase()).firstOrNull?.path;
  }

  Future<void> markRead(Iterable<MessageHeader> msgs, {bool read = true}) => _guard(() async {
        for (final g in _groupByFolder(msgs).entries) {
          await _sync.setFlags(g.value.first.accountId, g.key, g.value.map((m) => m.uid).toList(),
              add: read ? {r'\Seen'} : {}, remove: read ? {} : {r'\Seen'});
        }
      });

  Future<void> toggleFlag(MessageHeader m) => _guard(() => _sync.setFlags(m.accountId, m.folderPath, [m.uid],
      add: m.isFlagged ? {} : {r'\Flagged'}, remove: m.isFlagged ? {r'\Flagged'} : {}));

  Future<void> flag(Iterable<MessageHeader> msgs, {bool flagged = true}) => _guard(() async {
        for (final g in _groupByFolder(msgs).entries) {
          await _sync.setFlags(g.value.first.accountId, g.key, g.value.map((m) => m.uid).toList(),
              add: flagged ? {r'\Flagged'} : {}, remove: flagged ? {} : {r'\Flagged'});
        }
      });

  Future<void> archive(Iterable<MessageHeader> msgs) async {
    final list = msgs.toList();
    if (list.isEmpty) return;
    final dest = await _specialFolder(list.first.accountId, SpecialUse.archive, 'Archive');
    if (dest == null) return _snack('No Archive folder on this account.');
    await moveTo(list, dest);
  }

  Future<void> delete(Iterable<MessageHeader> msgs) => _guard(() async {
        for (final g in _groupByFolder(msgs).entries) {
          final first = g.value.first;
          final trash = await _specialFolder(first.accountId, SpecialUse.trash, 'Trash');
          await _sync.delete(first.accountId, g.key, g.value.map((m) => m.uid).toList(),
              permanent: trash == null || g.key == trash);
        }
      }, done: 'Deleted');

  Future<void> moveTo(Iterable<MessageHeader> msgs, String dest) => _guard(() async {
        for (final g in _groupByFolder(msgs).entries) {
          if (g.key == dest) continue;
          await _sync.move(g.value.first.accountId, g.key, g.value.map((m) => m.uid).toList(), dest);
        }
      }, done: 'Moved to $dest');

  Future<void> movePrompt(Iterable<MessageHeader> msgs) async {
    final list = msgs.toList();
    if (list.isEmpty) return;
    final dest = await pickFolder(context, ref, list.first.accountId, exclude: {list.first.folderPath});
    if (dest != null) await moveTo(list, dest);
  }

  // --- Sorter badge actions -------------------------------------------------

  SortCoordinator _coord(String accountId) => ref.read(sortCoordinatorProvider(accountId));

  Future<void> badgeMoveNow(MessageKey key) => _guard(() => _coord(key.accountId).moveNow(key));

  Future<void> badgeKeep(MessageKey key) => _guard(() => _coord(key.accountId).keepInInbox(key), done: 'Kept in Inbox');

  Future<void> badgeChangeFolder(MessageKey key, {String? current}) async {
    final dest = await pickFolder(context, ref, key.accountId,
        title: 'Sort into…', exclude: {if (current != null) current});
    if (dest != null) await _guard(() => _coord(key.accountId).changeDestination(key, dest), done: 'Will move to $dest');
  }

  Future<void> badgeWhy(MessageHeader header, PendingBadge badge) => showWhySheet(context, ref, header, badge);

  Future<void> undo(String accountId, String decisionId) =>
      _guard(() => _coord(accountId).undo(decisionId), done: 'Undone');

  static Map<String, List<MessageHeader>> _groupByFolder(Iterable<MessageHeader> msgs) {
    final out = <String, List<MessageHeader>>{};
    for (final m in msgs) {
      out.putIfAbsent(m.folderPath, () => []).add(m);
    }
    return out;
  }
}

/// Context menu for one message (long-press / right-click).
Future<void> showMessageMenu(
  BuildContext context,
  WidgetRef ref,
  MessageHeader m, {
  required Offset position,
  PendingBadge? badge,
}) async {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final actions = MessageActions(context, ref);
  final choice = await showMenu<String>(
    context: context,
    position: RelativeRect.fromRect(position & const Size(1, 1), Offset.zero & overlay.size),
    items: [
      if (badge != null) ...[
        const PopupMenuItem(value: 'moveNow', child: ListTile(dense: true, leading: Icon(Icons.drive_file_move_outlined), title: Text('Move now'))),
        const PopupMenuItem(value: 'keep', child: ListTile(dense: true, leading: Icon(Icons.inbox_outlined), title: Text('Keep here'))),
        const PopupMenuItem(value: 'change', child: ListTile(dense: true, leading: Icon(Icons.folder_open_outlined), title: Text('Change folder…'))),
        const PopupMenuItem(value: 'why', child: ListTile(dense: true, leading: Icon(Icons.help_outline), title: Text('Why?'))),
        const PopupMenuDivider(),
      ],
      PopupMenuItem(value: 'read', child: ListTile(dense: true, leading: Icon(m.isSeen ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined), title: Text(m.isSeen ? 'Mark unread' : 'Mark read'))),
      PopupMenuItem(value: 'flag', child: ListTile(dense: true, leading: Icon(m.isFlagged ? Icons.star : Icons.star_outline), title: Text(m.isFlagged ? 'Unflag' : 'Flag'))),
      const PopupMenuItem(value: 'archive', child: ListTile(dense: true, leading: Icon(Icons.archive_outlined), title: Text('Archive'))),
      const PopupMenuItem(value: 'move', child: ListTile(dense: true, leading: Icon(Icons.drive_file_move_outline), title: Text('Move to…'))),
      const PopupMenuItem(value: 'delete', child: ListTile(dense: true, leading: Icon(Icons.delete_outline), title: Text('Delete'))),
    ],
  );
  switch (choice) {
    case 'moveNow':
      await actions.badgeMoveNow(m.key);
    case 'keep':
      await actions.badgeKeep(m.key);
    case 'change':
      await actions.badgeChangeFolder(m.key, current: m.folderPath);
    case 'why':
      if (badge != null) await actions.badgeWhy(m, badge);
    case 'read':
      await actions.markRead([m], read: !m.isSeen);
    case 'flag':
      await actions.toggleFlag(m);
    case 'archive':
      await actions.archive([m]);
    case 'move':
      await actions.movePrompt([m]);
    case 'delete':
      await actions.delete([m]);
    default:
      break;
  }
}
