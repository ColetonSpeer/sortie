import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../domain/entities/calendar.dart';
import 'calendar_providers.dart';
import 'event_editor.dart';

final _urlRe = RegExp(r'https?://[^\s<>"]+');

Future<void> showEventDetail(BuildContext context, EventOccurrence o) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => EventDetailSheet(occurrence: o),
    );

/// Read-only event view with edit / delete for writable calendars.
class EventDetailSheet extends ConsumerWidget {
  const EventDetailSheet({super.key, required this.occurrence});
  final EventOccurrence occurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = occurrence;
    final e = o.event;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cal = ref.watch(calendarByIdProvider(e.calendarId));
    final url = e.description == null ? null : _urlRe.firstMatch(e.description!)?.group(0);
    final writable = cal?.isWritable ?? false;

    Widget row(IconData icon, Widget child) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(child: child),
          ]),
        );

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(color: calendarColor(cal), borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(e.summary.isEmpty ? '(untitled)' : e.summary,
                    style: theme.textTheme.titleLarge?.copyWith(
                        decoration: e.status == 'CANCELLED' ? TextDecoration.lineThrough : null)),
              ),
            ]),
            const SizedBox(height: 8),
            row(Icons.schedule_outlined, Text(CalFmt.span(o))),
            if (e.isRecurring || e.isOverride) row(Icons.repeat, Text(e.isOverride ? 'Edited occurrence of a repeating event' : 'Repeats: ${e.rrule}')),
            if (e.location?.isNotEmpty ?? false) row(Icons.place_outlined, SelectableText(e.location!)),
            if (e.description?.isNotEmpty ?? false) row(Icons.notes_outlined, SelectableText(e.description!)),
            if (url != null)
              row(
                Icons.link_outlined,
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_browser_outlined),
                    label: const Text('Open in browser'),
                  ),
                ),
              ),
            if (e.attendees.isNotEmpty)
              row(
                Icons.people_outline,
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (e.organizer != null) Text('Organizer: ${e.organizer}', style: theme.textTheme.bodySmall),
                  for (final a in e.attendees)
                    Text('${a.name ?? a.email}${a.name != null ? ' <${a.email}>' : ''} · ${_status(a.status)}'),
                ]),
              ),
            if (e.alarms.isNotEmpty) row(Icons.alarm_outlined, Text(e.alarms.map(CalFmt.reminder).join(', '))),
            row(Icons.calendar_month_outlined, Text(cal?.name ?? e.calendarId)),
            if (e.conflicted)
              row(Icons.warning_amber_outlined, Text('Your last edit conflicted with the server; showing the server version.', style: TextStyle(color: cs.error))),
            if (e.dirty && !e.conflicted) row(Icons.cloud_upload_outlined, Text('Waiting to upload', style: theme.textTheme.bodySmall)),
            if (writable) ...[
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton.icon(
                  onPressed: () => _delete(context, ref, o),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: () => _edit(context, ref, o),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  static String _status(AttendeeStatus s) => switch (s) {
        AttendeeStatus.accepted => 'accepted',
        AttendeeStatus.declined => 'declined',
        AttendeeStatus.tentative => 'tentative',
        AttendeeStatus.delegated => 'delegated',
        AttendeeStatus.needsAction => 'no reply',
      };

  /// null = cancelled, true = this occurrence only, false = whole series.
  static Future<bool?> _scopeDialog(BuildContext context, String verb) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('$verb repeating event'),
          content: Text('$verb only this occurrence, or the entire series?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('This occurrence')),
            FilledButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Entire series')),
          ],
        ),
      );

  Future<void> _edit(BuildContext context, WidgetRef ref, EventOccurrence o) async {
    var thisOnly = false;
    if (o.event.isRecurring) {
      final r = await _scopeDialog(context, 'Edit');
      if (r == null || !context.mounted) return;
      thisOnly = r;
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();
    await openEventEditor(context, occurrence: o, thisOccurrenceOnly: thisOnly);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, EventOccurrence o) async {
    final service = ref.read(calendarServiceProvider);
    if (o.event.isRecurring || o.event.isOverride) {
      final r = await _scopeDialog(context, 'Delete');
      if (r == null) return;
      if (r) {
        await service.deleteOccurrence(o);
      } else {
        await service.deleteEvent(o.event);
      }
    } else {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete event?'),
          content: Text(o.event.summary),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
          ],
        ),
      );
      if (ok != true) return;
      await service.deleteEvent(o.event);
    }
    if (context.mounted) Navigator.of(context).pop();
  }
}
