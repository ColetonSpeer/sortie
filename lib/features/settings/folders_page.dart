import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../mailbox/folder_picker.dart';
import '../shell/format.dart';
import 'settings_common.dart';

class FoldersPage extends StatelessWidget {
  const FoldersPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Folders')),
        body: AccountScope(builder: (_, id) => _FoldersBody(accountId: id)),
      );
}

class _FoldersBody extends ConsumerWidget {
  const _FoldersBody({required this.accountId});
  final String accountId;

  static const _alwaysExcluded = {SpecialUse.inbox, SpecialUse.sent, SpecialUse.drafts, SpecialUse.trash, SpecialUse.junk};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersProvider(accountId)).asData?.value ?? const <Folder>[];
    final config = ref.watch(sortConfigProvider(accountId)).asData?.value ?? const SortConfig();
    final list = visibleFolders(folders);
    return ListView(padding: const EdgeInsets.only(bottom: 32), children: [
      const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Describe what belongs in each folder to help the sorter. Turn off "Sort into" for folders you file by hand.'),
      ),
      for (final f in list)
        _FolderRow(
          folder: f,
          fixed: _alwaysExcluded.contains(f.specialUse) || f.isInbox,
          neverSort: config.neverSortFolders.contains(f.path),
          description: config.folderDescriptions[f.path] ?? '',
          onNeverSort: (v) {
            final s = Set<String>.of(config.neverSortFolders);
            v ? s.add(f.path) : s.remove(f.path);
            saveSortConfig(ref, accountId, config.copyWith(neverSortFolders: s));
          },
          onDescription: (v) {
            final m = Map<String, String>.of(config.folderDescriptions);
            v.trim().isEmpty ? m.remove(f.path) : m[f.path] = v.trim();
            saveSortConfig(ref, accountId, config.copyWith(folderDescriptions: m));
          },
        ),
    ]);
  }
}

class _FolderRow extends StatefulWidget {
  const _FolderRow({
    required this.folder,
    required this.fixed,
    required this.neverSort,
    required this.description,
    required this.onNeverSort,
    required this.onDescription,
  });
  final Folder folder;
  final bool fixed;
  final bool neverSort;
  final String description;
  final ValueChanged<bool> onNeverSort;
  final ValueChanged<String> onDescription;

  @override
  State<_FolderRow> createState() => _FolderRowState();
}

class _FolderRowState extends State<_FolderRow> {
  late final _ctrl = TextEditingController(text: widget.description);

  @override
  void didUpdateWidget(covariant _FolderRow old) {
    super.didUpdateWidget(old);
    if (old.description != widget.description && _ctrl.text != widget.description) _ctrl.text = widget.description;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.folder;
    final depth = f.path.split(f.delimiter).length - 1;
    final sortable = !widget.fixed && !widget.neverSort;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.0 + depth * 16, 4, 16, 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Icon(Fmt.folderIcon(f), size: 20),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(f.isInbox ? 'Inbox' : f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          flex: 4,
          child: TextField(
            controller: _ctrl,
            enabled: sortable,
            decoration: const InputDecoration(isDense: true, hintText: 'Description, e.g. "vendor invoices and receipts"', border: OutlineInputBorder()),
            onSubmitted: widget.onDescription,
            onTapOutside: (_) {
              if (_ctrl.text != widget.description) widget.onDescription(_ctrl.text);
            },
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: widget.fixed ? 'System folders are never sort targets' : 'Sort into this folder',
          child: Switch(value: sortable, onChanged: widget.fixed ? null : (v) => widget.onNeverSort(!v)),
        ),
      ]),
    );
  }
}
