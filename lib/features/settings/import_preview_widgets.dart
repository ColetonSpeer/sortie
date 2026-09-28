import 'package:flutter/material.dart';

import '../../services/import/thunderbird/thunderbird_importer.dart';

/// Section header used by the preview and the results.
class ImportSection extends StatelessWidget {
  const ImportSection({super.key, required this.title, required this.children, this.trailing});
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ?trailing,
          ]),
        ),
        ...children,
      ]),
    );
  }
}

/// Preview with checkboxes and password fields for new accounts.
class ImportPreviewView extends StatelessWidget {
  const ImportPreviewView({
    super.key,
    required this.preview,
    required this.selection,
    required this.onSelection,
    required this.passwords,
  });
  final ImportPreview preview;
  final ImportSelection selection;
  final ValueChanged<ImportSelection> onSelection;

  /// Controllers keyed by account key; created by the page.
  final Map<String, TextEditingController> passwords;

  Set<String> _toggle(Set<String> set, String key, bool on) => on ? {...set, key} : ({...set}..remove(key));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ImportSection(title: 'Accounts', children: [
        if (preview.accounts.isEmpty) const ListTile(title: Text('No IMAP accounts found')),
        for (final a in preview.accounts) ...[
          CheckboxListTile(
            key: Key('account-${a.key}'),
            value: selection.accountKeys.contains(a.key),
            onChanged: (v) => onSelection(selection.copyWith(accountKeys: _toggle(selection.accountKeys, a.key, v ?? false))),
            title: Text(a.displayName),
            subtitle: Text([
              '${a.imap.host}:${a.imap.port} · ${a.username}',
              if (!a.isNew) 'Already in Sortie: only identities and rules will be added',
              ...a.notes,
            ].join('\n')),
            isThreeLine: !a.isNew || a.notes.isNotEmpty,
          ),
          if (a.isNew && selection.accountKeys.contains(a.key))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                key: Key('password-${a.key}'),
                controller: passwords[a.key],
                obscureText: true,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Password for ${a.email.isEmpty ? a.username : a.email}',
                  helperText: 'Passwords are not read from Thunderbird; the login is verified before the account is created',
                  helperMaxLines: 2,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
        ],
      ]),
      ImportSection(title: 'Identities & signatures', children: [
        for (final a in preview.accounts)
          for (final i in a.identities)
            CheckboxListTile(
              key: Key('identity-${i.key}'),
              value: selection.identityKeys.contains(i.key),
              onChanged: (v) => onSelection(selection.copyWith(identityKeys: _toggle(selection.identityKeys, i.key, v ?? false))),
              title: Text(i.name.isEmpty ? i.email : '${i.name} <${i.email}>'),
              subtitle: Text([
                if (i.signature.isNotEmpty) 'Signature: ${_firstLine(i.signature)}${i.signatureHtml != null ? ' (HTML kept)' : ''}',
                if (i.signature.isEmpty) 'No signature',
                ...i.notes,
              ].join('\n')),
            ),
      ]),
      ImportSection(
        title: 'Sorting rules',
        trailing: Text('${preview.filterCount}', style: theme.textTheme.labelLarge),
        children: [
          if (preview.filterCount == 0) const ListTile(title: Text('No message filters found')),
          for (final a in preview.accounts)
            for (final f in a.filters)
              CheckboxListTile(
                key: Key('filter-${a.key}-${f.name}'),
                value: selection.filter(a.key, f.name),
                onChanged: (v) => onSelection(selection.copyWith(filterNames: _toggle(selection.filterNames, '${a.key}/${f.name}', v ?? false))),
                title: Text(f.enabled ? f.name : '${f.name} (disabled)'),
                subtitle: Text(_filterLine(f)),
              ),
        ],
      ),
      ImportSection(title: 'Calendars', children: [
        if (preview.calendars.isEmpty) const ListTile(title: Text('No calendars found')),
        for (final c in preview.calendars)
          CheckboxListTile(
            key: Key('calendar-${c.id}'),
            value: selection.calendarIds.contains(c.id),
            onChanged: (v) => onSelection(selection.copyWith(calendarIds: _toggle(selection.calendarIds, c.id, v ?? false))),
            title: Text(c.name),
            subtitle: Text('${c.type}${c.uri.isNotEmpty ? ' · ${c.uri}' : ''}${c.disabled ? ' · disabled' : ''}'),
          ),
      ]),
      if (preview.skipped.isNotEmpty)
        ImportSection(title: 'Not importable', children: [
          for (final s in preview.skipped) ListTile(dense: true, leading: const Icon(Icons.info_outline), title: Text(s)),
        ]),
    ]);
  }

  static String _firstLine(String s) {
    final l = s.trim().split('\n').first;
    return l.length > 60 ? '${l.substring(0, 60)}…' : l;
  }

  static String _filterLine(TbFilter f) {
    final folder = f.folderActions.map((a) => folderPathFromUri(a.value ?? '')).whereType<String>().firstOrNull;
    final conds = f.conditions.map((c) => '${c.field} ${c.op} ${c.value}').join(f.anyCondition ? ' or ' : '; ');
    if (folder == null) return 'No folder action (${f.actions.map((a) => a.type).join(', ')}) - skipped';
    return '→ $folder · $conds';
  }
}

/// Summary after [ThunderbirdImporter.apply].
class ImportResultView extends StatelessWidget {
  const ImportResultView({super.key, required this.result});
  final ImportResult result;

  @override
  Widget build(BuildContext context) {
    final rules = result.rules;
    final missing = rules.where((r) => r.imported && r.missingFolder).toList();
    final dropped = rules.where((r) => r.imported && r.droppedStatusRead).length;
    final skippedRules = rules.where((r) => !r.imported).toList();
    Widget line(IconData icon, String text) => ListTile(dense: true, leading: Icon(icon), title: Text(text));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ImportSection(title: 'Imported', children: [
        line(Icons.account_circle_outlined, '${result.createdAccounts.length} account(s) created, ${result.reusedAccounts.length} existing reused'),
        line(Icons.badge_outlined, '${result.createdIdentities.length} identit${result.createdIdentities.length == 1 ? 'y' : 'ies'} added'),
        line(Icons.low_priority_outlined,
            '${result.rulesImported} rule(s) imported${result.rulesDisabled > 0 ? ', ${result.rulesDisabled} disabled' : ''}${dropped > 0 ? ', $dropped had a "status is read" term dropped (leave-until-read covers it)' : ''}'),
        for (final e in result.folderHints.entries) line(Icons.folder_outlined, 'Folder descriptions updated: ${e.value.join(', ')}'),
        line(Icons.calendar_month_outlined, '${result.calendarsImported} calendar(s) handed to the calendar module'),
      ]),
      if (missing.isNotEmpty)
        ImportSection(title: 'Rules pointing at folders that do not exist yet', children: [
          for (final r in missing) line(Icons.warning_amber_outlined, '${r.filterName} → ${r.folderPath} (create the folder and it starts working)'),
        ]),
      if (skippedRules.isNotEmpty || result.skipped.isNotEmpty)
        ImportSection(title: 'Skipped', children: [
          for (final r in skippedRules) line(Icons.block_outlined, '${r.filterName}: ${r.skippedReason}'),
          for (final s in result.skipped) line(Icons.block_outlined, s),
        ]),
      if (result.errors.isNotEmpty)
        ImportSection(title: 'Errors', children: [
          for (final e in result.errors) line(Icons.error_outline, e),
        ]),
    ]);
  }
}
