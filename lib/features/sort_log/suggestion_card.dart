import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
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

  RuleSuggestion get s => widget.suggestion;

  void _snack(String m) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(m)));

  Future<int> _matchingInbox(Map<String, dynamic> match) async {
    final list = await ref.read(messageRepositoryProvider).list(MessageQuery(accountId: s.accountId, folderPath: 'INBOX', limit: 500));
    final m = RuleMatch.fromJson(match);
    return list.where((h) => !h.hasSortieDone && m.matches(h)).length;
  }

  Future<void> _accept({Map<String, dynamic>? match, String? folderPath}) async {
    final m = match ?? s.match;
    final folder = folderPath ?? s.folderPath;
    setState(() => _busy = true);
    try {
      final n = await _matchingInbox(m);
      if (!mounted) return;
      final apply = await showDialog<bool>(context: context, builder: (_) => _AcceptDialog(suggestion: s, match: m, folderPath: folder, matching: n));
      if (apply == null) return; // cancelled
      final ruleId = await ref.read(ruleAdvisorProvider).accept(s.id, match: m, folderPath: folder);
      var queued = 0;
      if (apply && n > 0) {
        try {
          queued = await ref.read(sortCoordinatorProvider(s.accountId)).applyRuleToInbox(ruleId);
        } catch (e) {
          _snack('Rule saved; could not apply it to the inbox now: $e');
          return;
        }
      }
      _snack(queued > 0 ? 'Rule saved · $queued message${queued == 1 ? '' : 's'} queued for sorting' : 'Rule saved');
    } catch (e) {
      _snack('Could not accept: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final folders = ref.read(foldersProvider(s.accountId)).asData?.value ?? const <Folder>[];
    final r = await showDialog<(Map<String, dynamic>, String)>(context: context, builder: (_) => _EditDialog(suggestion: s, folders: folders));
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
          Text('${s.matchLabel} → ${s.folderPath}${s.createsFolder ? ' (new folder)' : ''}', style: theme.textTheme.titleSmall),
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

/// Confirms the rule and asks whether to apply it to the inbox now.
class _AcceptDialog extends StatefulWidget {
  const _AcceptDialog({required this.suggestion, required this.match, required this.folderPath, required this.matching});
  final RuleSuggestion suggestion;
  final Map<String, dynamic> match;
  final String folderPath;
  final int matching;

  @override
  State<_AcceptDialog> createState() => _AcceptDialogState();
}

class _AcceptDialogState extends State<_AcceptDialog> {
  bool _apply = true;

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
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(key: const Key('acceptConfirm'), onPressed: () => Navigator.of(context).pop(_apply && n > 0), child: const Text('Add rule')),
      ],
    );
  }
}

/// Small editor for the match text and destination folder.
class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.suggestion, required this.folders});
  final RuleSuggestion suggestion;
  final List<Folder> folders;

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
    _folder = widget.suggestion.folderPath;
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
