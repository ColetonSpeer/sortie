import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/calendar.dart';
import '../../services/calendar/recurrence.dart';
import '../../services/calendar/tz.dart';
import 'calendar_providers.dart';

Future<void> openEventEditor(BuildContext context, {EventOccurrence? occurrence, bool thisOccurrenceOnly = false, DateTime? initialStart}) =>
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => EventEditorPage(occurrence: occurrence, thisOccurrenceOnly: thisOccurrenceOnly, initialStart: initialStart),
    ));

/// Create / edit form. Validates that the end is after the start.
class EventEditorPage extends ConsumerStatefulWidget {
  const EventEditorPage({super.key, this.occurrence, this.thisOccurrenceOnly = false, this.initialStart});
  final EventOccurrence? occurrence;
  final bool thisOccurrenceOnly;
  final DateTime? initialStart;

  @override
  ConsumerState<EventEditorPage> createState() => _EventEditorPageState();
}

class _EventEditorPageState extends ConsumerState<EventEditorPage> {
  static const reminderChoices = [0, 5, 10, 15, 30, 60, 120, 1440, 2880];

  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _description;
  late final TextEditingController _rrule;
  String? _calendarId;
  bool _allDay = false;
  late DateTime _start;
  late DateTime _end;
  RepeatPreset _repeat = RepeatPreset.none;
  List<int> _alarms = [];
  String? _error;
  bool _saving = false;
  bool _seeded = false;

  CalendarEvent? get _existing => widget.occurrence?.event;

  @override
  void initState() {
    super.initState();
    final e = _existing;
    final o = widget.occurrence;
    _title = TextEditingController(text: e?.summary ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _rrule = TextEditingController(text: e?.rrule ?? '');
    _calendarId = e?.calendarId;
    _allDay = e?.isAllDay ?? false;
    if (o != null) {
      final (s, en) = localSpan(o);
      _start = s;
      _end = en;
    } else {
      final s = widget.initialStart ?? DateTime.now();
      _start = DateTime(s.year, s.month, s.day, s.hour, (s.minute ~/ 15) * 15);
      _end = _start.add(const Duration(hours: 1));
    }
    _repeat = widget.thisOccurrenceOnly ? RepeatPreset.none : presetOf(e?.rrule);
    _alarms = List.of(e?.alarms ?? const []);
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    _rrule.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sources = (ref.watch(calendarSourcesProvider).asData?.value ?? const <CalendarSource>[]).where((s) => s.isWritable).toList();
    final settings = ref.watch(calendarSettingsProvider).asData?.value ?? const CalendarSettings();
    if (!_seeded && _existing == null) {
      _seeded = true;
      _alarms = [settings.defaultReminderMinutes];
      _calendarId ??= sources.firstOrNull?.id;
    }
    _calendarId ??= sources.firstOrNull?.id;
    final editing = _existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? (widget.thisOccurrenceOnly ? 'Edit occurrence' : 'Edit event') : 'New event'),
        actions: [
          TextButton(key: const Key('saveEvent'), onPressed: _saving ? null : _save, child: const Text('Save')),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(
          key: const Key('eventTitle'),
          controller: _title,
          autofocus: !editing,
          decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        if (sources.isEmpty)
          const ListTile(leading: Icon(Icons.info_outline), title: Text('No writable calendar. Add a local or CalDAV calendar first.'))
        else
          DropdownButtonFormField<String>(
            initialValue: sources.any((s) => s.id == _calendarId) ? _calendarId : sources.first.id,
            decoration: const InputDecoration(labelText: 'Calendar', border: OutlineInputBorder()),
            items: [
              for (final s in sources)
                DropdownMenuItem(
                  value: s.id,
                  child: Row(children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: Color(s.color), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(s.name),
                  ]),
                ),
            ],
            onChanged: editing ? null : (v) => setState(() => _calendarId = v),
          ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('All day'),
          value: _allDay,
          onChanged: (v) => setState(() {
            _allDay = v;
            if (v) {
              _start = dateOnly(_start);
              _end = dateOnly(_end.subtract(const Duration(microseconds: 1))).add(const Duration(days: 1));
              if (!_end.isAfter(_start)) _end = _start.add(const Duration(days: 1));
            }
          }),
        ),
        _DateTimeRow(label: 'Starts', value: _start, allDay: _allDay, keyPrefix: 'start', onChanged: (d) => setState(() {
              final dur = _end.difference(_start);
              _start = d;
              _end = d.add(dur);
            })),
        _DateTimeRow(label: 'Ends', value: _allDay ? _end.subtract(const Duration(days: 1)) : _end, allDay: _allDay, keyPrefix: 'end',
            onChanged: (d) => setState(() => _end = _allDay ? d.add(const Duration(days: 1)) : d)),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(_error!, key: const Key('editorError'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _location,
          decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder(), prefixIcon: Icon(Icons.place_outlined)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _description,
          minLines: 3,
          maxLines: 8,
          decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), alignLabelWithHint: true),
        ),
        const SizedBox(height: 12),
        if (!widget.thisOccurrenceOnly) ...[
          DropdownButtonFormField<RepeatPreset>(
            initialValue: _repeat,
            decoration: const InputDecoration(labelText: 'Repeat', border: OutlineInputBorder(), prefixIcon: Icon(Icons.repeat)),
            items: const [
              DropdownMenuItem(value: RepeatPreset.none, child: Text('Does not repeat')),
              DropdownMenuItem(value: RepeatPreset.daily, child: Text('Daily')),
              DropdownMenuItem(value: RepeatPreset.weekly, child: Text('Weekly')),
              DropdownMenuItem(value: RepeatPreset.monthly, child: Text('Monthly')),
              DropdownMenuItem(value: RepeatPreset.yearly, child: Text('Yearly')),
              DropdownMenuItem(value: RepeatPreset.custom, child: Text('Custom (RRULE)')),
            ],
            onChanged: (v) => setState(() => _repeat = v ?? RepeatPreset.none),
          ),
          if (_repeat == RepeatPreset.custom) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _rrule,
              decoration: const InputDecoration(labelText: 'RRULE', hintText: 'FREQ=WEEKLY;BYDAY=MO,WE;COUNT=10', border: OutlineInputBorder()),
            ),
          ],
          const SizedBox(height: 12),
        ],
        Text('Reminders', style: Theme.of(context).textTheme.titleSmall),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final m in _alarms)
            InputChip(label: Text(CalFmt.reminder(m)), onDeleted: () => setState(() => _alarms = _alarms.where((x) => x != m).toList())),
          PopupMenuButton<int>(
            tooltip: 'Add reminder',
            onSelected: (m) => setState(() => _alarms = {..._alarms, m}.toList()..sort()),
            itemBuilder: (_) => [for (final m in reminderChoices) PopupMenuItem(value: m, child: Text(CalFmt.reminder(m)))],
            child: const Chip(avatar: Icon(Icons.add, size: 18), label: Text('Add')),
          ),
        ]),
      ]),
    );
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_end.isAfter(_start)) {
      setState(() => _error = 'End must be after start');
      return;
    }
    if (_calendarId == null) {
      setState(() => _error = 'Choose a calendar');
      return;
    }
    final rrule = widget.thisOccurrenceOnly ? null : rruleOf(_repeat, custom: _rrule.text);
    if (_repeat == RepeatPreset.custom && rrule != null && parseRrule(rrule) == null) {
      setState(() => _error = 'RRULE is not valid');
      return;
    }
    final tz = _allDay ? null : (_existing?.tzid ?? localTimeZoneId());
    final startUtc = _allDay ? DateTime.utc(_start.year, _start.month, _start.day) : _start.toUtc();
    final endUtc = _allDay ? DateTime.utc(_end.year, _end.month, _end.day) : _end.toUtc();
    final base = _existing ??
        CalendarEvent(id: '', calendarId: _calendarId!, uid: '', start: startUtc, end: endUtc, updatedAt: DateTime.now().toUtc());
    final e = base.copyWith(
      calendarId: _calendarId,
      summary: _title.text.trim(),
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      start: startUtc,
      end: endUtc,
      isAllDay: _allDay,
      tzid: tz,
      clearTzid: tz == null,
      floating: !_allDay && tz == null && (_existing?.floating ?? true),
      rrule: rrule,
      clearRrule: rrule == null,
      alarms: _alarms,
    );
    setState(() => _saving = true);
    try {
      final service = ref.read(calendarServiceProvider);
      if (_existing == null) {
        await service.createEvent(e);
      } else if (widget.thisOccurrenceOnly) {
        await service.updateOccurrence(widget.occurrence!, e);
      } else {
        await service.updateEvent(e);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (err) {
      setState(() {
        _saving = false;
        _error = err.toString();
      });
    }
  }
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({required this.label, required this.value, required this.allDay, required this.keyPrefix, required this.onChanged});
  final String label;
  final DateTime value;
  final bool allDay;
  final String keyPrefix;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(width: 64, child: Text(label)),
      TextButton(
        key: Key('${keyPrefix}Date'),
        onPressed: () async {
          final d = await showDatePicker(context: context, initialDate: value, firstDate: DateTime(1970), lastDate: DateTime(2100));
          if (d != null) onChanged(DateTime(d.year, d.month, d.day, value.hour, value.minute));
        },
        child: Text(CalFmt.fullDay(value)),
      ),
      if (!allDay)
        TextButton(
          key: Key('${keyPrefix}Time'),
          onPressed: () async {
            final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(value));
            if (t != null) onChanged(DateTime(value.year, value.month, value.day, t.hour, t.minute));
          },
          child: Text(CalFmt.time(value)),
        ),
    ]);
  }
}
