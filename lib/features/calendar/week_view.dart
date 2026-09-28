import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/calendar.dart';
import 'calendar_providers.dart';
import 'month_view.dart';

/// Seven day columns: all-day row on top, then a scrollable 24-hour grid.
class WeekView extends ConsumerStatefulWidget {
  const WeekView({
    super.key,
    required this.first,
    required this.occurrences,
    required this.onEventTap,
    required this.onSlotTap,
  });

  final DateTime first;
  final List<EventOccurrence> occurrences;
  final void Function(EventOccurrence o) onEventTap;
  final void Function(DateTime start) onSlotTap;

  static const hourHeight = 56.0;
  static const gutter = 52.0;

  @override
  ConsumerState<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends ConsumerState<WeekView> {
  final _scroll = ScrollController(initialScrollOffset: WeekView.hourHeight * 7);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final first = widget.first;
    final occurrences = widget.occurrences;
    final onEventTap = widget.onEventTap;
    final onSlotTap = widget.onSlotTap;
    const gutter = WeekView.gutter;
    const hourHeight = WeekView.hourHeight;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final today = dateOnly(DateTime.now());
    final sources = ref.watch(calendarSourcesProvider).asData?.value ?? const <CalendarSource>[];
    final colorOf = {for (final s in sources) s.id: Color(s.color)};
    final days = [for (var i = 0; i < 7; i++) first.add(Duration(days: i))];
    final grouped = byDay(occurrences, first, first.add(const Duration(days: 7)));
    final allDay = {for (final d in days) d: (grouped[d] ?? const <EventOccurrence>[]).where(_spansDay).toList()};
    final timed = {for (final d in days) d: (grouped[d] ?? const <EventOccurrence>[]).where((o) => !_spansDay(o)).toList()};
    final allDayRows = allDay.values.fold<int>(0, (m, l) => l.length > m ? l.length : m);

    return Column(children: [
      Row(children: [
        const SizedBox(width: gutter),
        for (final d in days)
          Expanded(
            child: Column(children: [
              Text(DateFormat.E().format(d), style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: d == today ? BoxDecoration(color: cs.primary, shape: BoxShape.circle) : null,
                child: Text('${d.day}', style: theme.textTheme.titleSmall?.copyWith(color: d == today ? cs.onPrimary : null)),
              ),
            ]),
          ),
      ]),
      if (allDayRows > 0)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: gutter,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: Text('all-day', textAlign: TextAlign.right, style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            ),
          ),
          for (final d in days)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Column(children: [
                  for (final o in allDay[d]!) EventChip(occurrence: o, color: colorOf[o.event.calendarId] ?? cs.primary, onTap: () => onEventTap(o)),
                ]),
              ),
            ),
        ]),
      const Divider(height: 1),
      Expanded(
        child: SingleChildScrollView(
          controller: _scroll,
          child: SizedBox(
            height: hourHeight * 24,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: gutter,
                child: Stack(children: [
                  for (var h = 1; h < 24; h++)
                    Positioned(
                      top: h * hourHeight - 7,
                      right: 6,
                      child: Text(DateFormat.j().format(DateTime(2000, 1, 1, h)),
                          style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                    ),
                ]),
              ),
              for (final d in days)
                Expanded(
                  child: _DayColumn(
                    day: d,
                    items: timed[d]!,
                    colorOf: colorOf,
                    onEventTap: onEventTap,
                    onSlotTap: onSlotTap,
                  ),
                ),
            ]),
          ),
        ),
      ),
    ]);
  }

  bool _spansDay(EventOccurrence o) {
    if (o.isAllDay) return true;
    final (s, e) = localSpan(o);
    return e.difference(s) >= const Duration(hours: 24);
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({required this.day, required this.items, required this.colorOf, required this.onEventTap, required this.onSlotTap});
  final DateTime day;
  final List<EventOccurrence> items;
  final Map<String, Color> colorOf;
  final void Function(EventOccurrence) onEventTap;
  final void Function(DateTime) onSlotTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final placed = _layout(items, day);
    return LayoutBuilder(builder: (context, c) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          final hour = (d.localPosition.dy / WeekView.hourHeight).floor().clamp(0, 23);
          onSlotTap(DateTime(day.year, day.month, day.day, hour));
        },
        child: Stack(children: [
          for (var h = 0; h < 24; h++)
            Positioned(
              top: h * WeekView.hourHeight,
              left: 0,
              right: 0,
              child: Container(height: WeekView.hourHeight, decoration: BoxDecoration(border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5), left: BorderSide(color: cs.outlineVariant, width: 0.5)))),
            ),
          for (final p in placed)
            Positioned(
              top: p.top,
              height: p.height < 18 ? 18 : p.height,
              left: c.maxWidth * p.col / p.cols + 1,
              width: c.maxWidth / p.cols - 2,
              child: _TimedBlock(occurrence: p.o, color: colorOf[p.o.event.calendarId] ?? cs.primary, onTap: () => onEventTap(p.o)),
            ),
        ]),
      );
    });
  }

  /// Greedy column packing for overlapping events.
  static List<_Placed> _layout(List<EventOccurrence> items, DateTime day) {
    final dayStart = day;
    final dayEnd = day.add(const Duration(days: 1));
    final list = <_Placed>[];
    for (final o in items) {
      var (s, e) = localSpan(o);
      if (s.isBefore(dayStart)) s = dayStart;
      if (e.isAfter(dayEnd)) e = dayEnd;
      final top = s.difference(dayStart).inMinutes / 60 * WeekView.hourHeight;
      final height = e.difference(s).inMinutes / 60 * WeekView.hourHeight;
      list.add(_Placed(o, top, height));
    }
    list.sort((a, b) => a.top.compareTo(b.top));
    // Clusters of transitively overlapping blocks share the width.
    var i = 0;
    while (i < list.length) {
      var j = i;
      var clusterEnd = list[i].top + list[i].height;
      final colEnds = <double>[];
      while (j < list.length && (j == i || list[j].top < clusterEnd)) {
        final p = list[j];
        var col = colEnds.indexWhere((end) => end <= p.top);
        if (col < 0) {
          colEnds.add(p.top + p.height);
          col = colEnds.length - 1;
        } else {
          colEnds[col] = p.top + p.height;
        }
        p.col = col;
        if (p.top + p.height > clusterEnd) clusterEnd = p.top + p.height;
        j++;
      }
      for (var k = i; k < j; k++) {
        list[k].cols = colEnds.length;
      }
      i = j;
    }
    return list;
  }
}

class _Placed {
  _Placed(this.o, this.top, this.height);
  final EventOccurrence o;
  final double top;
  final double height;
  int col = 0;
  int cols = 1;
}

class _TimedBlock extends StatelessWidget {
  const _TimedBlock({required this.occurrence, required this.color, required this.onTap});
  final EventOccurrence occurrence;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onFill = ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black;
    return Material(
      color: color.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            '${CalFmt.time(occurrence.start.toLocal())} ${occurrence.event.summary}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(color: onFill),
          ),
        ),
      ),
    );
  }
}
