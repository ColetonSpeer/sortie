import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../services/sorter/user_rules.dart';
import '../sort_log/suggestion_card.dart';
import 'settings_common.dart';

/// Settings → Sorting rules: every rule the sorter runs without the AI
/// (imported Thunderbird filters, accepted suggestions, hand-made ones),
/// in evaluation order, with the pending AI suggestions on top.
class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context) => AccountScope(builder: (_, id) => _RulesScaffold(accountId: id));
}

class _RulesScaffold extends ConsumerStatefulWidget {
  const _RulesScaffold({required this.accountId});
  final String accountId;

  @override
  ConsumerState<_RulesScaffold> createState() => _RulesScaffoldState();
}

class _RulesScaffoldState extends ConsumerState<_RulesScaffold> {
  bool _running = false;

  void _snack(String m) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(m)));

  Future<void> _runAll() async {
    setState(() => _running = true);
    try {
      final n = await ref.read(sortCoordinatorProvider(widget.accountId)).applyRulesToInbox();
      _snack(n == 0
          ? 'No inbox messages match your rules right now (only the device doing the sorting can run this)'
          : '$n message${n == 1 ? '' : 's'} queued; they move after you read them if that setting is on');
    } catch (e) {
      _snack('Could not run rules: $e');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _edit(SortRule? existing) async {
    final folders = await ref.read(folderRepositoryProvider).all(widget.accountId);
    final rules = await ref.read(sortRuleStoreProvider).load(widget.accountId);
    if (!mounted) return;
    final result = await showDialog<SortRule>(
      context: context,
      builder: (_) => RuleEditorDialog(
        accountId: widget.accountId,
        folders: folders,
        existing: existing,
        nextPriority: rules.fold(0, (m, r) => r.priority > m ? r.priority : m) + 10,
      ),
    );
    if (result == null) return;
    await ref.read(sortRuleStoreProvider).upsert(result, DateTime.now().toUtc());
    if (!result.enabled) {
      _snack('Rule saved');
      return;
    }
    try {
      final n = await ref.read(sortCoordinatorProvider(widget.accountId)).applyRuleToInbox(result.id);
      _snack(n > 0 ? 'Rule saved · $n message${n == 1 ? '' : 's'} queued for sorting' : 'Rule saved');
    } catch (_) {
      _snack('Rule saved');
    }
  }

  Future<void> _delete(SortRule r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete rule?'),
        content: Text(r.name ?? r.match.describe()),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(key: const Key('deleteConfirm'), onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    final store = ref.read(sortRuleStoreProvider);
    if (store is SyncableRuleStore) await store.delete(r.id);
  }

  Future<void> _setEnabled(SortRule r, bool v) => ref.read(sortRuleStoreProvider).upsert(r.copyWith(enabled: v), DateTime.now().toUtc());

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(sortRulesProvider(widget.accountId));
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sorting rules'),
        actions: [
          IconButton(
            key: const Key('runAllRules'),
            tooltip: 'Run all rules on the inbox now',
            onPressed: _running ? null : _runAll,
            icon: _running ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addRule'),
        onPressed: () => _edit(null),
        icon: const Icon(Icons.add),
        label: const Text('Add rule'),
      ),
      body: rules.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Rules unavailable: $e')),
        data: (list) => ListView(padding: const EdgeInsets.only(bottom: 96), children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Rules run on whichever device is sorting, without the AI, and are shared with your other devices. '
                'The first matching rule wins, top to bottom. Imported Thunderbird filters appear here too.'),
          ),
          SuggestedRulesSection(accountId: widget.accountId),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No rules yet. Add one, accept a suggestion from the sort log, or import your Thunderbird filters.'),
            ),
          for (final r in list)
            ListTile(
              key: Key('rule:${r.id}'),
              leading: Icon(r.enabled ? Icons.rule : Icons.rule_folder_outlined, color: r.enabled ? null : theme.disabledColor),
              title: Text(r.name ?? r.match.describe(), style: r.enabled ? null : TextStyle(color: theme.disabledColor)),
              subtitle: Text(_subtitle(r)),
              isThreeLine: r.name != null,
              onTap: () => _edit(r),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Switch(key: Key('enabled:${r.id}'), value: r.enabled, onChanged: (v) => _setEnabled(r, v)),
                PopupMenuButton<String>(
                  key: Key('menu:${r.id}'),
                  onSelected: (v) => v == 'delete' ? _delete(r) : _edit(r),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ]),
            ),
        ]),
      ),
    );
  }

  static String _subtitle(SortRule r) {
    final action = switch (r.action) {
      RuleAction.moveTo => '→ ${r.folderPath ?? '?'}',
      RuleAction.keepInInbox => 'keep in inbox',
      RuleAction.neverAutoSort => 'never auto-sort',
    };
    final hits = r.hits == 0 ? 'not matched yet on this device' : 'matched ${r.hits} time${r.hits == 1 ? '' : 's'} on this device';
    return r.name == null ? '$action · $hits' : '${r.match.describe()}\n$action · $hits';
  }
}

/// The criteria a rule can carry, in the order shown in the editor.
const ruleFields = <String, String>{
  'from': 'Sender address is',
  'fromDomain': 'Sender domain is',
  'fromContains': 'Sender contains',
  'fromEndsWith': 'Sender ends with',
  'subjectContains': 'Subject contains',
  'subjectIs': 'Subject is',
  'toContains': 'To / Cc contains',
  'listId': 'List-Id is',
  'bodyContains': 'Body contains',
  'headerContains': 'Header contains (Name: text)',
};

/// Add / edit one rule: name, one or more criteria (all / any), action and
/// folder. Returns the rule to save, or null when cancelled.
class RuleEditorDialog extends StatefulWidget {
  const RuleEditorDialog({super.key, required this.accountId, required this.folders, this.existing, required this.nextPriority});
  final String accountId;
  final List<Folder> folders;
  final SortRule? existing;
  final int nextPriority;

  @override
  State<RuleEditorDialog> createState() => _RuleEditorDialogState();
}

class _RuleEditorDialogState extends State<RuleEditorDialog> {
  late final TextEditingController _name;
  late final List<_Criterion> _criteria;
  late bool _any;
  late RuleAction _action;
  String? _folder;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _criteria = e == null ? [_Criterion('from', '')] : _fromMatch(e.match);
    if (_criteria.isEmpty) _criteria.add(_Criterion('from', ''));
    _any = e?.match.any ?? false;
    _action = e?.action ?? RuleAction.moveTo;
    _folder = e?.folderPath;
  }

  @override
  void dispose() {
    _name.dispose();
    for (final c in _criteria) {
      c.value.dispose();
    }
    super.dispose();
  }

  static List<_Criterion> _fromMatch(RuleMatch m) {
    final out = <_Criterion>[];
    for (final e in m.toJson().entries) {
      if (e.key == 'any') continue;
      if (e.key == 'headerContains' && e.value is Map) {
        final h = (e.value as Map).cast<String, dynamic>();
        out.add(_Criterion('headerContains', '${h['name']}: ${h['value']}'));
      } else if (e.value is String) {
        out.add(_Criterion(e.key, e.value as String));
      }
    }
    return out;
  }

  RuleMatch? _buildMatch() {
    final j = <String, dynamic>{};
    for (final c in _criteria) {
      final v = c.value.text.trim();
      if (v.isEmpty || j.containsKey(c.field)) return null;
      if (c.field == 'headerContains') {
        final i = v.indexOf(':');
        if (i <= 0) return null;
        j['headerContains'] = {'name': v.substring(0, i).trim(), 'value': v.substring(i + 1).trim()};
      } else {
        j[c.field] = v;
      }
    }
    if (_any && _criteria.length > 1) j['any'] = true;
    return RuleMatch.fromJson(j);
  }

  bool get _valid => _buildMatch() != null && (_action != RuleAction.moveTo || (_folder ?? '').isNotEmpty);

  void _save() {
    final m = _buildMatch();
    if (m == null) return;
    final name = _name.text.trim();
    final e = widget.existing;
    Navigator.of(context).pop(SortRule(
      id: e?.id ?? 'r-${const Uuid().v4()}',
      accountId: widget.accountId,
      priority: e?.priority ?? widget.nextPriority,
      match: m,
      action: _action,
      folderPath: _action == RuleAction.moveTo ? _folder : null,
      hits: e?.hits ?? 0,
      enabled: e?.enabled ?? true,
      name: name.isEmpty ? null : name,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final paths = {for (final f in widget.folders) if (!f.isInbox && !f.isControlFolder) f.path, ?_folder}.toList()..sort();
    return AlertDialog(
      title: Text(widget.existing == null ? 'New rule' : 'Edit rule'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              key: const Key('ruleName'),
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _criteria.length; i++) ...[
              Row(children: [
                Expanded(
                  flex: 5,
                  child: DropdownButtonFormField<String>(
                    key: Key('ruleField$i'),
                    initialValue: _criteria[i].field,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    items: [for (final e in ruleFields.entries) DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))],
                    onChanged: (v) => setState(() => _criteria[i].field = v ?? _criteria[i].field),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: TextField(
                    key: Key('ruleValue$i'),
                    controller: _criteria[i].value,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: _criteria.length == 1 ? null : () => setState(() => _criteria.removeAt(i).value.dispose()),
                  icon: const Icon(Icons.close),
                ),
              ]),
              const SizedBox(height: 8),
            ],
            Row(children: [
              TextButton.icon(
                key: const Key('addCriterion'),
                onPressed: () => setState(() => _criteria.add(_Criterion('subjectContains', ''))),
                icon: const Icon(Icons.add),
                label: const Text('Add criterion'),
              ),
              const Spacer(),
              if (_criteria.length > 1)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Match any'),
                  Switch(value: _any, onChanged: (v) => setState(() => _any = v)),
                ]),
            ]),
            const SizedBox(height: 8),
            SegmentedButton<RuleAction>(
              segments: const [
                ButtonSegment(value: RuleAction.moveTo, label: Text('Move to')),
                ButtonSegment(value: RuleAction.keepInInbox, label: Text('Keep in inbox')),
                ButtonSegment(value: RuleAction.neverAutoSort, label: Text('Never auto-sort')),
              ],
              selected: {_action},
              onSelectionChanged: (s) => setState(() => _action = s.first),
            ),
            if (_action == RuleAction.moveTo) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('ruleFolder'),
                initialValue: paths.contains(_folder) ? _folder : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Folder', border: OutlineInputBorder()),
                items: [for (final p in paths) DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis))],
                onChanged: (v) => setState(() => _folder = v),
              ),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(key: const Key('ruleSave'), onPressed: _valid ? _save : null, child: const Text('Save')),
      ],
    );
  }
}

class _Criterion {
  _Criterion(this.field, String text) : value = TextEditingController(text: text);
  String field;
  final TextEditingController value;
}
