import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/entities/calendar.dart';
import '../../router/app_router.dart';
import '../shell/format.dart';
import 'add_calendar_sheet.dart';
import 'calendar_providers.dart';

Future<void> showCalendarListSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SizedBox(height: MediaQuery.sizeOf(context).height * 0.7, child: const CalendarListPanel()),
    );

/// Palette offered by the colour picker (calendar colours are data).
const calendarPalette = <int>[
  0xFF3F51B5, 0xFF1E88E5, 0xFF00897B, 0xFF43A047, 0xFF7CB342, 0xFFFDD835,
  0xFFFB8C00, 0xFFE53935, 0xFFD81B60, 0xFF8E24AA, 0xFF5E35B1, 0xFF6D4C41,
];

/// Per-calendar visibility, colour, status and sync; "Add calendar" at the bottom.
class CalendarListPanel extends ConsumerWidget {
  const CalendarListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sources = ref.watch(calendarSourcesProvider).asData?.value ?? const <CalendarSource>[];
    final status = ref.watch(calendarSyncStatusProvider).asData?.value ?? const <String, CalendarSyncStatus>{};
    final service = ref.read(calendarServiceProvider);

    return Material(
      color: cs.surfaceContainerLow,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(children: [
            Expanded(child: Text('Calendars', style: theme.textTheme.titleMedium)),
            IconButton(
              tooltip: 'Sync all',
              icon: const Icon(Icons.sync_outlined),
              onPressed: () => service.syncAll(),
            ),
            IconButton(
              tooltip: 'Calendar settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push(Routes.settingsPage('calendar')),
            ),
          ]),
        ),
        Expanded(
          child: sources.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No calendars yet. Add a Google, CalDAV, ICS or local calendar.',
                        textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                )
              : ListView(children: [
                  for (final s in sources) _SourceTile(source: s, status: status[s.id]),
                ]),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.tonalIcon(
            key: const Key('addCalendar'),
            onPressed: () => showAddCalendarSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Add calendar'),
          ),
        ),
      ]),
    );
  }
}

class _SourceTile extends ConsumerWidget {
  const _SourceTile({required this.source, required this.status});
  final CalendarSource source;
  final CalendarSyncStatus? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = source;
    final cs = Theme.of(context).colorScheme;
    final service = ref.read(calendarServiceProvider);
    final state = status?.state ?? (s.enabled ? CalendarSyncState.idle : CalendarSyncState.disabled);
    final error = status?.error ?? s.lastError;

    final subtitle = switch (state) {
      CalendarSyncState.syncing => 'Syncing…',
      CalendarSyncState.needsSignIn => 'Sign in to Google${s.googleEmail == null ? '' : ' (${s.googleEmail})'} to sync',
      CalendarSyncState.error => error ?? 'Sync failed',
      CalendarSyncState.disabled => _kindLabel(s),
      CalendarSyncState.idle => s.lastSyncAt == null ? _kindLabel(s) : '${_kindLabel(s)} · synced ${Fmt.relativeDate(s.lastSyncAt!.toLocal())}',
    };
    final bad = state == CalendarSyncState.error || state == CalendarSyncState.needsSignIn;

    return ListTile(
      dense: true,
      leading: Checkbox(
        value: s.enabled,
        onChanged: (v) => service.updateSource(s.copyWith(enabled: v ?? true, clearError: true)),
      ),
      title: Row(children: [
        InkWell(
          onTap: () => _pickColor(context, ref, s),
          borderRadius: BorderRadius.circular(8),
          child: Container(width: 14, height: 14, decoration: BoxDecoration(color: Color(s.color), borderRadius: BorderRadius.circular(3))),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
        if (s.readOnly) Icon(Icons.lock_outline, size: 14, color: cs.onSurfaceVariant),
      ]),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: bad ? cs.error : null)),
      trailing: state == CalendarSyncState.syncing
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : state == CalendarSyncState.needsSignIn
              ? TextButton(onPressed: () => _signIn(context, ref, s), child: const Text('Sign in'))
              : PopupMenuButton<String>(
                  onSelected: (v) => _menu(context, ref, s, v),
                  itemBuilder: (_) => [
                    if (s.kind != CalendarKind.local) const PopupMenuItem(value: 'sync', child: Text('Sync now')),
                    const PopupMenuItem(value: 'rename', child: Text('Rename…')),
                    if (s.authKind == CalendarAuthKind.basic) const PopupMenuItem(value: 'password', child: Text('Set password…')),
                    const PopupMenuItem(value: 'remove', child: Text('Remove')),
                  ],
                ),
    );
  }

  static String _kindLabel(CalendarSource s) => switch (s.kind) {
        CalendarKind.caldav => s.authKind == CalendarAuthKind.googleOAuth ? 'Google' : 'CalDAV',
        CalendarKind.ics => 'ICS feed',
        CalendarKind.local => 'On this device',
      };

  Future<void> _signIn(BuildContext context, WidgetRef ref, CalendarSource s) async {
    final service = ref.read(calendarServiceProvider);
    try {
      await service.signInGoogle(loginHint: s.googleEmail);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
    }
  }

  Future<void> _pickColor(BuildContext context, WidgetRef ref, CalendarSource s) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Calendar colour'),
        content: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in calendarPalette)
            InkWell(
              onTap: () => Navigator.pop(ctx, c),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(c),
                  shape: BoxShape.circle,
                  border: c == s.color ? Border.all(color: Theme.of(ctx).colorScheme.onSurface, width: 3) : null,
                ),
              ),
            ),
        ]),
      ),
    );
    if (picked != null) await ref.read(calendarServiceProvider).updateSource(s.copyWith(color: picked));
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, CalendarSource s, String action) async {
    final service = ref.read(calendarServiceProvider);
    switch (action) {
      case 'sync':
        await service.syncNow(calendarId: s.id);
      case 'rename':
        final name = await _prompt(context, 'Rename calendar', initial: s.name);
        if (name != null && name.trim().isNotEmpty) await service.updateSource(s.copyWith(name: name.trim()));
      case 'password':
        final pw = await _prompt(context, 'Password for ${s.name}', obscure: true);
        if (pw != null) await service.addSource(s.copyWith(clearError: true), password: pw);
      case 'remove':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Remove ${s.name}?'),
            content: const Text('Events are removed from this device only.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
            ],
          ),
        );
        if (ok == true) await service.removeSource(s.id);
    }
  }
}

Future<String?> _prompt(BuildContext context, String title, {String initial = '', bool obscure = false}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: c, obscureText: obscure, autofocus: true, onSubmitted: (v) => Navigator.pop(ctx, v)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('OK')),
      ],
    ),
  );
}
