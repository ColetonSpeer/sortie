import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../shell/format.dart';

/// Folders the user may file into (no control folder, unsubscribed or
/// unselectable ones).
List<Folder> visibleFolders(Iterable<Folder> all) =>
    all.where((f) => !f.isControlFolder && f.subscribed && f.selectable).toList()..sort(_compareFolders);

int _specialRank(Folder f) => switch (f.specialUse) {
      SpecialUse.inbox => 0,
      SpecialUse.drafts => 1,
      SpecialUse.sent => 2,
      SpecialUse.archive => 3,
      SpecialUse.junk => 4,
      SpecialUse.trash => 5,
      _ => f.isInbox ? 0 : 10,
    };

int _compareFolders(Folder a, Folder b) {
  final r = _specialRank(a).compareTo(_specialRank(b));
  if (r != 0) return r;
  return a.path.toLowerCase().compareTo(b.path.toLowerCase());
}

/// Modal folder chooser. Returns the chosen path or null.
Future<String?> pickFolder(BuildContext context, WidgetRef ref, String accountId,
    {String? title, Set<String> exclude = const {}}) async {
  final folders = visibleFolders(await ref.read(folderRepositoryProvider).all(accountId))
      .where((f) => !exclude.contains(f.path))
      .toList();
  if (!context.mounted) return null;
  return showDialog<String>(
    context: context,
    builder: (ctx) => _FolderPickerDialog(title: title ?? 'Move to…', folders: folders),
  );
}

class _FolderPickerDialog extends StatefulWidget {
  const _FolderPickerDialog({required this.title, required this.folders});
  final String title;
  final List<Folder> folders;
  @override
  State<_FolderPickerDialog> createState() => _FolderPickerDialogState();
}

class _FolderPickerDialogState extends State<_FolderPickerDialog> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final items = widget.folders.where((f) => f.path.toLowerCase().contains(_filter.toLowerCase())).toList();
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 380,
        height: 420,
        child: Column(children: [
          TextField(
            autofocus: true,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Filter folders'),
            onChanged: (v) => setState(() => _filter = v),
            onSubmitted: (_) {
              if (items.length == 1) Navigator.of(context).pop(items.first.path);
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final f = items[i];
                final depth = f.path.split(f.delimiter).length - 1;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.only(left: 8.0 + depth * 16, right: 8),
                  leading: Icon(Fmt.folderIcon(f)),
                  title: Text(f.name),
                  subtitle: depth > 0 ? Text(f.path, style: Theme.of(context).textTheme.labelSmall) : null,
                  onTap: () => Navigator.of(context).pop(f.path),
                );
              },
            ),
          ),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))],
    );
  }
}
