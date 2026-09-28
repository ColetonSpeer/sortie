import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/calendar.dart';
import '../shell/adaptive_scaffold.dart';
import 'agenda_view.dart';
import 'calendar_list_panel.dart';
import 'calendar_providers.dart';
import 'event_detail_sheet.dart';
import 'event_editor.dart';
import 'month_view.dart';
import 'week_view.dart';

/// `/calendar`: month / week / agenda with a calendar list side panel.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(calendarViewProvider);
    final settings = ref.watch(calendarSettingsProvider).asData?.value ?? const CalendarSettings();
    final days = visibleDays(view, settings.weekStart);
    final occ = ref.watch(occurrencesProvider(rangeOf(days))).asData?.value ?? const <EventOccurrence>[];
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= AdaptiveScaffold.expandedBreakpoint;
    final compact = width < AdaptiveScaffold.compactBreakpoint;

    final title = switch (view.mode) {
      CalendarViewMode.month => CalFmt.month(view.anchor),
      CalendarViewMode.week => CalFmt.weekLabel(days.first),
      CalendarViewMode.agenda => 'From ${CalFmt.day(view.anchor)}',
    };

    final segmented = SegmentedButton<CalendarViewMode>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: const [
        ButtonSegment(value: CalendarViewMode.month, label: Text('Month')),
        ButtonSegment(value: CalendarViewMode.week, label: Text('Week')),
        ButtonSegment(value: CalendarViewMode.agenda, label: Text('Agenda')),
      ],
      selected: {view.mode},
      onSelectionChanged: (s) => ref.read(calendarViewProvider.notifier).state = view.copyWith(mode: s.first),
    );

    Widget body = switch (view.mode) {
      CalendarViewMode.month => MonthView(
          anchor: view.anchor,
          first: days.first,
          occurrences: occ,
          weekStart: settings.weekStart,
          onDayTap: (d) => ref.read(calendarViewProvider.notifier).state = view.copyWith(mode: CalendarViewMode.agenda, anchor: d),
          onEventTap: (o) => showEventDetail(context, o),
        ),
      CalendarViewMode.week => WeekView(
          first: days.first,
          occurrences: occ,
          onEventTap: (o) => showEventDetail(context, o),
          onSlotTap: (t) => openEventEditor(context, initialStart: t),
        ),
      CalendarViewMode.agenda => AgendaView(
          first: days.first,
          last: days.last,
          occurrences: occ,
          onEventTap: (o) => showEventDetail(context, o),
        ),
    };
    if (wide) {
      body = Row(children: [
        Expanded(child: body),
        const VerticalDivider(width: 1),
        const SizedBox(width: 300, child: CalendarListPanel()),
      ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(tooltip: 'Today', icon: const Icon(Icons.today_outlined), onPressed: () => _goToday(ref, view)),
          IconButton(tooltip: 'Previous', icon: const Icon(Icons.chevron_left), onPressed: () => _shift(ref, view, -1)),
          IconButton(tooltip: 'Next', icon: const Icon(Icons.chevron_right), onPressed: () => _shift(ref, view, 1)),
          if (!compact) Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: segmented),
          if (!wide)
            IconButton(
              tooltip: 'Calendars',
              icon: const Icon(Icons.checklist_outlined),
              onPressed: () => showCalendarListSheet(context),
            ),
        ],
        bottom: compact
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Padding(padding: const EdgeInsets.only(bottom: 8), child: segmented),
              )
            : null,
      ),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('newEventFab'),
        onPressed: () => openEventEditor(context, initialStart: _defaultStart(view)),
        icon: const Icon(Icons.add),
        label: const Text('New event'),
      ),
    );
  }

  static DateTime _defaultStart(CalendarViewState v) {
    final now = DateTime.now();
    final base = v.anchor == dateOnly(now) ? now : v.anchor.add(Duration(hours: now.hour));
    final rounded = DateTime(base.year, base.month, base.day, base.hour + 1);
    return rounded;
  }

  void _goToday(WidgetRef ref, CalendarViewState v) =>
      ref.read(calendarViewProvider.notifier).state = v.copyWith(anchor: dateOnly(DateTime.now()));

  void _shift(WidgetRef ref, CalendarViewState v, int dir) {
    final a = v.anchor;
    final next = switch (v.mode) {
      CalendarViewMode.month => DateTime(a.year, a.month + dir, 1),
      CalendarViewMode.week => a.add(Duration(days: 7 * dir)),
      CalendarViewMode.agenda => a.add(Duration(days: 30 * dir)),
    };
    ref.read(calendarViewProvider.notifier).state = v.copyWith(anchor: next);
  }
}
