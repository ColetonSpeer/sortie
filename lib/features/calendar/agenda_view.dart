import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/calendar.dart';
import 'calendar_providers.dart';

/// Chronological list grouped by day.
class AgendaView extends ConsumerWidget {
  const AgendaView({super.key, required this.first, required this.last, required this.occurrences, required this.onEventTap});
  final DateTime first;
  final DateTime last;
  final List<EventOccurrence> occurrences;
  final void Function(EventOccurrence o) onEventTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sources = ref.watch(calendarSourcesProvider).asData?.value ?? const <CalendarSource>[];
    final byId = {for (final s in sources) s.id: s};
    final grouped = byDay(occurrences, first, last);
    final days = grouped.keys.toList()..sort();
    final today = dateOnly(DateTime.now());
    if (days.isEmpty) {
      return Center(
        child: Text('No events between ${CalFmt.day(first)} and ${CalFmt.day(last.subtract(const Duration(days: 1)))}',
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
      );
    }
    return ListView.builder(
      itemCount: days.length,
      itemBuilder: (context, i) {
        final d = days[i];
        final items = grouped[d]!;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              d == today ? 'Today · ${CalFmt.fullDay(d)}' : CalFmt.fullDay(d),
              style: theme.textTheme.titleSmall?.copyWith(color: d == today ? cs.primary : cs.onSurfaceVariant),
            ),
          ),
          for (final o in items)
            ListTile(
              dense: true,
              leading: Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: calendarColor(byId[o.event.calendarId]), shape: BoxShape.circle),
              ),
              title: Text(o.event.summary.isEmpty ? '(untitled)' : o.event.summary,
                  style: o.event.status == 'CANCELLED' ? const TextStyle(decoration: TextDecoration.lineThrough) : null),
              subtitle: Text([
                o.isAllDay ? 'All day' : '${CalFmt.time(o.start.toLocal())} – ${CalFmt.time(o.end.toLocal())}',
                if (o.event.location?.isNotEmpty ?? false) o.event.location!,
              ].join(' · ')),
              trailing: o.event.conflicted ? Tooltip(message: 'A local edit was overwritten by the server', child: Icon(Icons.warning_amber_outlined, color: cs.error)) : null,
              onTap: () => onEventTap(o),
            ),
        ]);
      },
    );
  }
}
