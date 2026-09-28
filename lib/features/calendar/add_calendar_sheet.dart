import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../data/calendar/caldav_client.dart';
import '../../data/calendar/google_oauth.dart';
import '../../domain/entities/calendar.dart';
import 'calendar_list_panel.dart';

Future<void> showAddCalendarSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 16), child: AddCalendarSheet()),
    );

enum _Kind { google, caldav, ics, local }

/// "Add calendar": Google (sign in, tick calendars), CalDAV (URL + login,
/// discover, tick), ICS URL, or a device-only local calendar.
class AddCalendarSheet extends ConsumerStatefulWidget {
  const AddCalendarSheet({super.key});
  @override
  ConsumerState<AddCalendarSheet> createState() => _AddCalendarSheetState();
}

class _AddCalendarSheetState extends ConsumerState<AddCalendarSheet> {
  _Kind _kind = _Kind.google;
  final _url = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  int _color = calendarPalette.first;
  bool _busy = false;
  String? _error;
  GoogleAccountLink? _link;
  List<DavCalendar> _found = const [];
  final _picked = <Uri>{};

  @override
  void dispose() {
    _url.dispose();
    _user.dispose();
    _pass.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        Text('Add calendar', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        SegmentedButton<_Kind>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: _Kind.google, label: Text('Google')),
            ButtonSegment(value: _Kind.caldav, label: Text('CalDAV')),
            ButtonSegment(value: _Kind.ics, label: Text('ICS')),
            ButtonSegment(value: _Kind.local, label: Text('Local')),
          ],
          selected: {_kind},
          onSelectionChanged: (s) => setState(() {
            _kind = s.first;
            _error = null;
            _found = const [];
            _picked.clear();
          }),
        ),
        const SizedBox(height: 16),
        ...switch (_kind) {
          _Kind.google => _google(),
          _Kind.caldav => _caldav(),
          _Kind.ics => _ics(),
          _Kind.local => _local(),
        },
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
      ]),
    );
  }

  List<Widget> _google() => [
        const Text('Sign in with your Google account in the browser, then choose the calendars to sync.'),
        const SizedBox(height: 12),
        if (_link == null)
          FilledButton.icon(
            onPressed: _busy ? null : _signIn,
            icon: const Icon(Icons.login),
            label: const Text('Sign in with Google'),
          )
        else ...[
          Text('Signed in as ${_link!.email}', style: Theme.of(context).textTheme.bodySmall),
          ..._foundList(),
          const SizedBox(height: 8),
          FilledButton(onPressed: _busy || _picked.isEmpty ? null : _addGoogle, child: Text('Add ${_picked.length} calendar(s)')),
        ],
      ];

  List<Widget> _caldav() => [
        TextField(controller: _url, decoration: const InputDecoration(labelText: 'Server or calendar URL', hintText: 'https://cloud.example.com/', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: _user, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: _busy ? null : _discover, icon: const Icon(Icons.search), label: const Text('Find calendars')),
        ..._foundList(),
        if (_found.isNotEmpty) ...[
          const SizedBox(height: 8),
          FilledButton(onPressed: _busy || _picked.isEmpty ? null : _addCalDav, child: Text('Add ${_picked.length} calendar(s)')),
        ],
      ];

  List<Widget> _ics() => [
        TextField(controller: _url, decoration: const InputDecoration(labelText: 'ICS / webcal URL', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        _colorRow(),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy
              ? null
              : () => _add(CalendarSource(
                    id: const Uuid().v4(),
                    name: _name.text.trim().isEmpty ? 'Subscription' : _name.text.trim(),
                    kind: CalendarKind.ics,
                    url: _url.text.trim(),
                    color: _color,
                    readOnly: true,
                  )),
          child: const Text('Subscribe'),
        ),
      ];

  List<Widget> _local() => [
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        _colorRow(),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy
              ? null
              : () => _add(CalendarSource(
                    id: const Uuid().v4(),
                    name: _name.text.trim().isEmpty ? 'Local calendar' : _name.text.trim(),
                    kind: CalendarKind.local,
                    color: _color,
                  )),
          child: const Text('Create'),
        ),
      ];

  Widget _colorRow() => Wrap(spacing: 6, children: [
        for (final c in calendarPalette)
          InkWell(
            onTap: () => setState(() => _color = c),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Color(c),
                shape: BoxShape.circle,
                border: c == _color ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) : null,
              ),
            ),
          ),
      ]);

  List<Widget> _foundList() => [
        for (final c in _found)
          CheckboxListTile(
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: _picked.contains(c.href),
            onChanged: (v) => setState(() => v == true ? _picked.add(c.href) : _picked.remove(c.href)),
            title: Row(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: Color(c.color ?? calendarPalette.first), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(c.displayName)),
            ]),
            subtitle: Text(c.href.path, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ];

  Future<void> _run(Future<void> Function() body) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await body();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signIn() => _run(() async {
        final service = ref.read(calendarServiceProvider);
        final link = await service.signInGoogle();
        final found = await service.listGoogleCalendars(link);
        setState(() {
          _link = link;
          _found = found;
          _picked.addAll(found.map((c) => c.href));
        });
      });

  Future<void> _addGoogle() => _run(() async {
        await ref.read(calendarServiceProvider).addGoogleCalendars(_link!, _found.where((c) => _picked.contains(c.href)));
        if (mounted) Navigator.of(context).pop();
      });

  Future<void> _discover() => _run(() async {
        final found = await ref.read(calendarServiceProvider).discoverCalDav(_url.text, username: _user.text.trim(), password: _pass.text);
        setState(() {
          _found = found;
          _picked.addAll(found.map((c) => c.href));
        });
        if (found.isEmpty) setState(() => _error = 'No calendars found at that address.');
      });

  Future<void> _addCalDav() => _run(() async {
        final service = ref.read(calendarServiceProvider);
        final user = _user.text.trim();
        for (final c in _found.where((c) => _picked.contains(c.href))) {
          await service.addSource(
            CalendarSource(
              id: const Uuid().v4(),
              name: c.displayName,
              kind: CalendarKind.caldav,
              url: c.href.toString(),
              username: user.isEmpty ? null : user,
              authKind: user.isEmpty ? CalendarAuthKind.none : CalendarAuthKind.basic,
              color: c.color ?? calendarPalette.first,
            ),
            password: user.isEmpty ? null : _pass.text,
          );
        }
        if (mounted) Navigator.of(context).pop();
      });

  Future<void> _add(CalendarSource s) => _run(() async {
        if (s.kind == CalendarKind.ics && Uri.tryParse(s.url)?.host.isEmpty != false) throw const FormatException('Enter a valid URL');
        await ref.read(calendarServiceProvider).addSource(s);
        if (mounted) Navigator.of(context).pop();
      });
}
