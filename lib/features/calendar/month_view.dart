import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/calendar.dart';
import 'calendar_providers.dart';

/// Six-week grid; each cell lists up to a few event chips and "+N more".
class MonthView extends ConsumerWidget {
  const MonthView({
    super.key,
    required this.anchor,
    required this.first,
    required this.occurrences,
    required this.weekStart,
    required this.onDayTap,
    required this.onEventTap,
  });

  final DateTime anchor;
  final DateTime first;
  final List<EventOccurrence> occurrences;
  final int weekStart;
  final void Function(DateTime day) onDayTap;
  final void Function(EventOccurrence o) onEventTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final grouped = byDay(occurrences, first, first.add(const Duration(days: 42)));
    final today = dateOnly(DateTime.now());
    final sources = ref.watch(calendarSourcesProvider).asData?.value ?? const <CalendarSource>[];
    final colorOf = {for (final s in sources) s.id: Color(s.color)};

    return Column(children: [
      Row(children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                DateFormat.E().format(first.add(Duration(days: i))),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ),
      ]),
      const Divider(height: 1),
      Expanded(
        child: LayoutBuilder(builder: (context, c) {
          final rowHeight = c.maxHeight / 6;
          final maxChips = ((rowHeight - 26) / 20).floor().clamp(0, 6);
          return Column(children: [
            for (var w = 0; w < 6; w++)
              Expanded(
                child: Row(children: [
                  for (var d = 0; d < 7; d++)
                    Expanded(
                      child: _DayCell(
                        day: first.add(Duration(days: w * 7 + d)),
                        inMonth: first.add(Duration(days: w * 7 + d)).month == anchor.month,
                        isToday: first.add(Duration(days: w * 7 + d)) == today,
                        items: grouped[first.add(Duration(days: w * 7 + d))] ?? const [],
                        maxChips: maxChips,
                        colorOf: colorOf,
                        onTap: onDayTap,
                        onEventTap: onEventTap,
                      ),
                    ),
                ]),
              ),
          ]);
        }),
      ),
    ]);
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.items,
    required this.maxChips,
    required this.colorOf,
    required this.onTap,
    required this.onEventTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final List<EventOccurrence> items;
  final int maxChips;
  final Map<String, Color> colorOf;
  final void Function(DateTime) onTap;
  final void Function(EventOccurrence) onEventTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final shown = items.take(maxChips).toList();
    final more = items.length - shown.length;
    return InkWell(
      onTap: () => onTap(day),
      child: Container(
        decoration: BoxDecoration(
          color: inMonth ? null : cs.surfaceContainerLow,
          border: Border(right: BorderSide(color: cs.outlineVariant, width: 0.5), bottom: BorderSide(color: cs.outlineVariant, width: 0.5)),
        ),
        padding: const EdgeInsets.all(2),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: isToday ? BoxDecoration(color: cs.primary, shape: BoxShape.circle) : null,
              child: Text(
                '${day.day}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isToday ? cs.onPrimary : (inMonth ? cs.onSurface : cs.onSurfaceVariant),
                  fontWeight: isToday ? FontWeight.bold : null,
                ),
              ),
            ),
          ),
          for (final o in shown) EventChip(occurrence: o, color: colorOf[o.event.calendarId] ?? cs.primary, onTap: () => onEventTap(o)),
          if (more > 0)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text('+$more more', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            ),
        ]),
      ),
    );
  }
}

/// One-line event chip: filled for all-day, dot + text for timed.
class EventChip extends StatelessWidget {
  const EventChip({super.key, required this.occurrence, required this.color, required this.onTap});
  final EventOccurrence occurrence;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final o = occurrence;
    final title = o.event.summary.isEmpty ? '(untitled)' : o.event.summary;
    final onFill = ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 18,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(color: o.isAllDay ? color : null, borderRadius: BorderRadius.circular(4)),
          child: Row(children: [
            if (!o.isAllDay) ...[
              Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(CalFmt.time(o.start.toLocal()), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(width: 3),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: o.isAllDay ? onFill : theme.colorScheme.onSurface,
                  decoration: o.event.status == 'CANCELLED' ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
