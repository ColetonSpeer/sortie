import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../services/sorter/rule_advisor.dart' show FolderPlacement, RuleAdvisor;
import '../../services/sorter/user_rules.dart' show RuleMatch;

/// "Suggested rules" block at the top of the sort log: one card per pending
/// suggestion with Accept / Edit / Dismiss. Hidden when there is nothing.
class SuggestedRulesSection extends ConsumerWidget {
  const SuggestedRulesSection({super.key, required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingSuggestionsProvider(accountId)).asData?.value ?? const <RuleSuggestion>[];
    if (pending.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Row(children: [
          Icon(Icons.tips_and_updates_outlined, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text('Suggested rules', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(width: 6),
          Text('${pending.length}', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline)),
        ]),
      ),
      for (final s in pending) SuggestionCard(key: Key('suggestion:${s.id}'), suggestion: s),
      const Divider(),
    ]);
  }
}

class SuggestionCard extends ConsumerStatefulWidget {
  const SuggestionCard({super.key, required this.suggestion});
  final RuleSuggestion suggestion;

  @override
  ConsumerState<SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends ConsumerState<SuggestionCard> {
  bool _busy = false;

  /// For new-folder suggestions: the path after the owner's placement choice.
  String? _newFolderPath;

  RuleSuggestion get s => widget.suggestion;
  String get folderPath => _newFolderPath ?? s.folderPath;

  /// The parent the model proposed, when it proposed a subfolder.
  String? get proposedParent {
    final sep = RegExp(r'[./]').firstMatch(s.folderPath)?.group(0);
    if (sep == null || s.folderPath.toUpperCase().startsWith('INBOX$sep')) return null;
    final parts = s.folderPath.split(sep);
    return parts.length > 1 ? parts.sublist(0, parts.length - 1).join(sep) : null;
  }

  FolderPlacement get placement {
    final sep = RegExp(r'[./]').firstMatch(folderPath)?.group(0);
    if (sep == null) return FolderPlacement.top;
    if (folderPath.toUpperCase().startsWith('INBOX$sep')) return FolderPlacement.inbox;
    return FolderPlacement.under;
  }

  void _snack(String m) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(m)));

  Future<int> _matchingInbox(Map<String, dynamic> match) async => (await _matchingIn('INBOX', match)).length;

  Future<List<MessageHeader>> _matchingIn(String folder, Map<String, dynamic> match) async {
    final list = await ref.read(messageRepositoryProvider).list(MessageQuery(accountId: s.accountId, folderPath: folder, limit: 500));
    final m = RuleMatch.fromJson(match);
    return list.where((h) => folder != 'INBOX' || !h.hasSortieDone).where(m.matches).toList();
  }

  /// For a subfolder suggestion: the parent whose matching mail could move.
  String? _parentOf(String folder) {
    final sep = RegExp(r'[./]').firstMatch(folder)?.group(0);
    if (sep == null) return null;
    final parts = folder.split(sep);
    if (parts.length < 2) return null;
    final parent = parts.sublist(0, parts.length - 1).join(sep);
    return parent.toUpperCase() == 'INBOX' ? null : parent;
  }

  Future<void> _accept({Map<String, dynamic>? match, String? folderPath}) async {
    final m = match ?? s.match;
    final folder = folderPath ?? this.folderPath;
    setState(() => _busy = true);
    try {
      final n = await _matchingInbox(m);
      final parent = s.createsFolder ? _parentOf(folder) : null;
      final inParent = parent == null ? const <MessageHeader>[] : await _matchingIn(parent, m);
      if (!mounted) return;
      final choice = await showDialog<_AcceptChoice>(
          context: context, builder: (_) => _AcceptDialog(suggestion: s, match: m, folderPath: folder, matching: n, parent: parent, inParent: inParent.length));
      if (choice == null) return; // cancelled
      final ruleId = await ref.read(ruleAdvisorProvider).accept(s.id, match: m, folderPath: folder);
      var queued = 0;
      if (choice.applyInbox && n > 0) {
        try {
          queued = await ref.read(sortCoordinatorProvider(s.accountId)).applyRuleToInbox(ruleId);
        } catch (e) {
          _snack('Rule saved; could not apply it to the inbox now: $e');
          return;
        }
      }
      var moved = 0;
      if (choice.moveParent && parent != null && inParent.isNotEmpty) {
        try {
          await ref.read(mailSyncServiceProvider).move(s.accountId, parent, [for (final h in inParent) h.uid], folder, cause: 'subfolder');
          moved = inParent.length;
        } catch (e) {
          _snack('Rule saved; could not move the mail from $parent now: $e');
          return;
        }
      }
      final parts = [
        if (queued > 0) '$queued message${queued == 1 ? '' : 's'} queued for sorting',
        if (moved > 0) '$moved moved from $parent',
      ];
      _snack(parts.isEmpty ? 'Rule saved' : 'Rule saved · ${parts.join(' · ')}');
    } catch (e) {
      _snack('Could not accept: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final folders = ref.read(foldersProvider(s.accountId)).asData?.value ?? const <Folder>[];
    final r = await showDialog<(Map<String, dynamic>, String)>(
        context: context, builder: (_) => _EditDialog(suggestion: s, folders: folders, initialFolder: folderPath));
    if (r == null) return;
    await _accept(match: r.$1, folderPath: r.$2);
  }

  Future<void> _dismiss() async {
    setState(() => _busy = true);
    try {
      await ref.read(ruleAdvisorProvider).dismiss(s.id);
    } catch (e) {
      _snack('Could not dismiss: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final examples = s.examples.map((e) => '"$e"').join(' · ');
    final meta = '${s.evidenceCount} message${s.evidenceCount == 1 ? '' : 's'} · ${s.source == SuggestionSource.model ? 'AI' : 'pattern'} · ${(s.confidence * 100).round()}%';
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${s.matchLabel} → $folderPath${s.createsFolder ? ' (new folder)' : ''}', style: theme.textTheme.titleSmall),
          if (s.createsFolder)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SegmentedButton<FolderPlacement>(
                key: Key('placement:${s.id}'),
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: [
                  const ButtonSegment(value: FolderPlacement.inbox, label: Text('Under Inbox'), icon: Icon(Icons.inbox_outlined, size: 16)),
                  const ButtonSegment(value: FolderPlacement.top, label: Text('Top level'), icon: Icon(Icons.folder_outlined, size: 16)),
                  if (proposedParent != null)
                    ButtonSegment(value: FolderPlacement.under, label: Text('Under ${proposedParent!.split(RegExp(r'[./]')).last}'), icon: const Icon(Icons.subdirectory_arrow_right, size: 16)),
                ],
                selected: {placement},
                onSelectionChanged: _busy ? null : (v) => setState(() => _newFolderPath = RuleAdvisor.replacePlacement(folderPath, v.single, parent: proposedParent)),
              ),
            ),
          if (s.rationale.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(s.rationale, style: theme.textTheme.bodyMedium)),
          const SizedBox(height: 4),
          Text(examples.isEmpty ? meta : '$meta · e.g. $examples', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(key: Key('dismiss:${s.id}'), onPressed: _busy ? null : _dismiss, child: const Text('Dismiss')),
            TextButton(key: Key('edit:${s.id}'), onPressed: _busy ? null : _edit, child: const Text('Edit')),
            FilledButton.tonal(key: Key('accept:${s.id}'), onPressed: _busy ? null : () => _accept(), child: const Text('Accept')),
          ]),
        ]),
      ),
    );
  }
}

class _AcceptChoice {
  const _AcceptChoice({required this.applyInbox, required this.moveParent});
  final bool applyInbox;
  final bool moveParent;
}

/// Confirms the rule and asks whether to apply it to the inbox now (and,
/// for a subfolder, whether to move the parent's matching mail into it).
class _AcceptDialog extends StatefulWidget {
  const _AcceptDialog({required this.suggestion, required this.match, required this.folderPath, required this.matching, this.parent, this.inParent = 0});
  final RuleSuggestion suggestion;
  final Map<String, dynamic> match;
  final String folderPath;
  final int matching;
  final String? parent;
  final int inParent;

  @override
  State<_AcceptDialog> createState() => _AcceptDialogState();
}

class _AcceptDialogState extends State<_AcceptDialog> {
  bool _apply = true;
  bool _moveParent = true;

  @override
  Widget build(BuildContext context) {
    final label = widget.suggestion.copyWith(match: widget.match, folderPath: widget.folderPath).matchLabel;
    final n = widget.matching;
    return AlertDialog(
      title: const Text('Add sorting rule'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$label → ${widget.folderPath}'),
        const SizedBox(height: 12),
        CheckboxListTile(
          key: const Key('applyToInbox'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _apply && n > 0,
          onChanged: n == 0 ? null : (v) => setState(() => _apply = v ?? false),
          title: Text(n == 0 ? 'No matching messages in the inbox right now' : 'Also apply to the $n matching message${n == 1 ? '' : 's'} already in the inbox'),
        ),
        if (widget.parent != null)
          CheckboxListTile(
            key: const Key('moveFromParent'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _moveParent && widget.inParent > 0,
            onChanged: widget.inParent == 0 ? null : (v) => setState(() => _moveParent = v ?? false),
            title: Text(widget.inParent == 0
                ? 'Nothing matching in ${widget.parent} right now'
                : 'Also move the ${widget.inParent} matching message${widget.inParent == 1 ? '' : 's'} from ${widget.parent} into the new subfolder'),
          ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          key: const Key('acceptConfirm'),
          onPressed: () => Navigator.of(context).pop(_AcceptChoice(applyInbox: _apply && n > 0, moveParent: _moveParent && widget.inParent > 0)),
          child: const Text('Add rule'),
        ),
      ],
    );
  }
}

/// Small editor for the match text and destination folder.
class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.suggestion, required this.folders, this.initialFolder});
  final RuleSuggestion suggestion;
  final List<Folder> folders;
  final String? initialFolder;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final String _field;
  late final TextEditingController _value;
  late String _folder;

  @override
  void initState() {
    super.initState();
    final (k, v) = widget.suggestion.criterion;
    _field = k.isEmpty ? 'from' : k;
    _value = TextEditingController(text: v);
    _folder = widget.initialFolder ?? widget.suggestion.folderPath;
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paths = {for (final f in widget.folders) if (!f.isInbox) f.path, _folder}.toList()..sort();
    final label = switch (_field) {
      'from' => 'Sender address',
      'fromDomain' => 'Sender domain',
      'listId' => 'List-Id',
      'subjectContains' => 'Subject contains',
      _ => _field,
    };
    return AlertDialog(
      title: const Text('Edit suggestion'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(key: const Key('editValue'), controller: _value, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: const Key('editFolder'),
          initialValue: _folder,
          decoration: const InputDecoration(labelText: 'Folder', border: OutlineInputBorder()),
          items: [for (final p in paths) DropdownMenuItem(value: p, child: Text(p))],
          onChanged: (v) => setState(() => _folder = v ?? _folder),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          key: const Key('editConfirm'),
          onPressed: _value.text.trim().isEmpty ? null : () => Navigator.of(context).pop(({_field: _value.text.trim()}, _folder)),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
