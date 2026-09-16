import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../shell/format.dart';
import 'folder_picker.dart';

/// Folder tree built from paths + delimiter, special-use first, collapsible.
class FolderList extends ConsumerStatefulWidget {
  const FolderList({super.key, required this.accountId, required this.selectedPath, required this.onSelect});
  final String accountId;
  final String selectedPath;
  final ValueChanged<String> onSelect;

  @override
  ConsumerState<FolderList> createState() => _FolderListState();
}

class _FolderListState extends ConsumerState<FolderList> {
  final _collapsed = <String>{};

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(foldersProvider(widget.accountId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Folders unavailable: $e')),
      data: (all) {
        final folders = visibleFolders(all);
        final paths = folders.map((f) => f.path).toSet();
        final rows = <Widget>[];
        for (final f in folders) {
          final parts = f.path.split(f.delimiter);
          final depth = parts.length - 1;
          // Hide children of collapsed ancestors.
          var hidden = false;
          for (var i = 1; i < parts.length; i++) {
            if (_collapsed.contains(parts.sublist(0, i).join(f.delimiter))) {
              hidden = true;
              break;
            }
          }
          if (hidden) continue;
          final hasChildren = paths.any((p) => p != f.path && p.startsWith('${f.path}${f.delimiter}'));
          rows.add(_FolderRow(
            folder: f,
            depth: depth,
            selected: f.path == widget.selectedPath,
            hasChildren: hasChildren,
            collapsed: _collapsed.contains(f.path),
            onToggle: () => setState(() => _collapsed.contains(f.path) ? _collapsed.remove(f.path) : _collapsed.add(f.path)),
            onTap: () => widget.onSelect(f.path),
          ));
        }
        return ListView(padding: const EdgeInsets.symmetric(vertical: 4), children: rows);
      },
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.folder,
    required this.depth,
    required this.selected,
    required this.hasChildren,
    required this.collapsed,
    required this.onToggle,
    required this.onTap,
  });
  final Folder folder;
  final int depth;
  final bool selected;
  final bool hasChildren;
  final bool collapsed;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unseen = folder.unseenCount;
    return Padding(
      padding: EdgeInsets.only(left: 8.0 + depth * 14, right: 8),
      child: ListTile(
        dense: true,
        selected: selected,
        selectedTileColor: cs.secondaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        leading: hasChildren
            ? IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                padding: EdgeInsets.zero,
                tooltip: collapsed ? 'Expand' : 'Collapse',
                icon: Icon(collapsed ? Icons.chevron_right : Icons.expand_more),
                onPressed: onToggle,
              )
            : Icon(Fmt.folderIcon(folder), size: 20),
        title: Text(
          folder.isInbox ? 'Inbox' : folder.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: unseen > 0 ? const TextStyle(fontWeight: FontWeight.w600) : null,
        ),
        trailing: unseen > 0
            ? Text('$unseen', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.primary))
            : null,
        onTap: onTap,
      ),
    );
  }
}
