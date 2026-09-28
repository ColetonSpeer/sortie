import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../domain/entities/calendar.dart';

enum CalendarViewMode { month, week, agenda }

class CalendarViewState {
  const CalendarViewState({required this.mode, required this.anchor});
  final CalendarViewMode mode;

  /// Local date (midnight) the view is centred on.
  final DateTime anchor;

  CalendarViewState copyWith({CalendarViewMode? mode, DateTime? anchor}) =>
      CalendarViewState(mode: mode ?? this.mode, anchor: anchor ?? this.anchor);
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

final calendarViewProvider = StateProvider<CalendarViewState>(
    (_) => CalendarViewState(mode: CalendarViewMode.month, anchor: dateOnly(DateTime.now())));

final calendarSourcesProvider =
    StreamProvider<List<CalendarSource>>((ref) => ref.watch(calendarRepositoryProvider).watchSources());
final calendarSyncStatusProvider =
    StreamProvider<Map<String, CalendarSyncStatus>>((ref) => ref.watch(calendarServiceProvider).watchStatus());
final calendarSettingsProvider =
    StreamProvider<CalendarSettings>((ref) => ref.watch(calendarServiceProvider).watchSettings());

typedef OccurrenceRange = ({DateTime from, DateTime to});

/// Occurrences overlapping a UTC window (records give value equality).
final occurrencesProvider = StreamProvider.family<List<EventOccurrence>, OccurrenceRange>(
    (ref, r) => ref.watch(calendarServiceProvider).watchOccurrences(r.from, r.to));

/// Local-date window of a view: 6 weeks for month, 7 days for week, 30 for agenda.
({DateTime first, DateTime last}) visibleDays(CalendarViewState v, int weekStart) {
  switch (v.mode) {
    case CalendarViewMode.month:
      final first = startOfWeek(DateTime(v.anchor.year, v.anchor.month, 1), weekStart);
      return (first: first, last: first.add(const Duration(days: 42)));
    case CalendarViewMode.week:
      final first = startOfWeek(v.anchor, weekStart);
      return (first: first, last: first.add(const Duration(days: 7)));
    case CalendarViewMode.agenda:
      return (first: v.anchor, last: v.anchor.add(const Duration(days: 30)));
  }
}

DateTime startOfWeek(DateTime d, int weekStart) {
  final day = dateOnly(d);
  final diff = (day.weekday - weekStart + 7) % 7;
  return day.subtract(Duration(days: diff));
}

OccurrenceRange rangeOf(({DateTime first, DateTime last}) days) => (from: days.first.toUtc(), to: days.last.toUtc());

/// Groups occurrences by the local calendar date(s) they cover.
Map<DateTime, List<EventOccurrence>> byDay(List<EventOccurrence> occ, DateTime first, DateTime last) {
  final out = <DateTime, List<EventOccurrence>>{};
  for (final o in occ) {
    final (s, e) = localSpan(o);
    var d = dateOnly(s);
    final endDay = dateOnly(e.subtract(const Duration(microseconds: 1)));
    while (!d.isAfter(endDay)) {
      if (!d.isBefore(first) && d.isBefore(last)) out.putIfAbsent(d, () => []).add(o);
      d = d.add(const Duration(days: 1));
    }
  }
  return out;
}

/// All-day events are date-based: their UTC midnight is a local date, not an instant.
(DateTime, DateTime) localSpan(EventOccurrence o) {
  if (o.isAllDay) {
    final s = DateTime(o.start.year, o.start.month, o.start.day);
    final e = DateTime(o.end.year, o.end.month, o.end.day);
    return (s, e.isAfter(s) ? e : s.add(const Duration(days: 1)));
  }
  final s = o.start.toLocal();
  final e = o.end.toLocal();
  return (s, e.isAfter(s) ? e : s.add(const Duration(minutes: 30)));
}

abstract final class CalFmt {
  static final _day = DateFormat.MMMEd();
  static final _time = DateFormat.jm();
  static final _month = DateFormat.yMMMM();
  static final _full = DateFormat.yMMMEd();

  static String month(DateTime d) => _month.format(d);
  static String day(DateTime d) => _day.format(d);
  static String fullDay(DateTime d) => _full.format(d);
  static String time(DateTime d) => _time.format(d);
  static String weekLabel(DateTime first) {
    final last = first.add(const Duration(days: 6));
    return first.month == last.month
        ? '${DateFormat.MMMd().format(first)} – ${DateFormat.d().format(last)}, ${last.year}'
        : '${DateFormat.MMMd().format(first)} – ${DateFormat.MMMd().format(last)}, ${last.year}';
  }

  static String span(EventOccurrence o) {
    final (s, e) = localSpan(o);
    if (o.isAllDay) {
      final days = e.difference(s).inDays;
      return days <= 1 ? 'All day, ${fullDay(s)}' : '${fullDay(s)} – ${fullDay(e.subtract(const Duration(days: 1)))}';
    }
    if (dateOnly(s) == dateOnly(e)) return '${fullDay(s)}, ${time(s)} – ${time(e)}';
    return '${fullDay(s)} ${time(s)} – ${fullDay(e)} ${time(e)}';
  }

  static String reminder(int minutes) {
    if (minutes == 0) return 'At start';
    if (minutes % 1440 == 0) return '${minutes ~/ 1440} day${minutes == 1440 ? '' : 's'} before';
    if (minutes % 60 == 0) return '${minutes ~/ 60} hour${minutes == 60 ? '' : 's'} before';
    return '$minutes min before';
  }
}

Color calendarColor(CalendarSource? s) => Color(s?.color ?? 0xFF3F51B5);

final calendarByIdProvider = Provider.family<CalendarSource?, String>((ref, id) =>
    ref.watch(calendarSourcesProvider).asData?.value.where((s) => s.id == id).firstOrNull);
