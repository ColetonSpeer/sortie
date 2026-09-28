import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/calendar/google_oauth.dart';
import '../../domain/entities/calendar.dart';
import 'calendar_providers.dart';

/// `/settings/calendar`: reminders, week start, sync interval, Google client.
class CalendarSettingsPage extends ConsumerStatefulWidget {
  const CalendarSettingsPage({super.key});
  @override
  ConsumerState<CalendarSettingsPage> createState() => _CalendarSettingsPageState();
}

class _CalendarSettingsPageState extends ConsumerState<CalendarSettingsPage> {
  final _clientId = TextEditingController();
  final _clientSecret = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _clientId.dispose();
    _clientSecret.dispose();
    super.dispose();
  }

  Future<void> _save(CalendarSettings Function(CalendarSettings) edit) async {
    final service = ref.read(calendarServiceProvider);
    await service.saveSettings(edit(service.settings));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(calendarSettingsProvider).asData?.value ?? const CalendarSettings();
    if (!_seeded) {
      _seeded = true;
      _clientId.text = s.googleClientId;
      _clientSecret.text = s.googleClientSecret;
    }
    final theme = Theme.of(context);
    final usingDefault = s.googleClientId.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: ListView(children: [
        ListTile(
          leading: const Icon(Icons.alarm_outlined),
          title: const Text('Default reminder'),
          trailing: DropdownButton<int>(
            value: s.defaultReminderMinutes,
            items: [
              for (final m in const [0, 5, 10, 15, 30, 60, 120, 1440]) DropdownMenuItem(value: m, child: Text(CalFmt.reminder(m))),
            ],
            onChanged: (v) => _save((c) => c.copyWith(defaultReminderMinutes: v)),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.view_week_outlined),
          title: const Text('Week starts on'),
          trailing: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: DateTime.monday, label: Text('Mon')),
              ButtonSegment(value: DateTime.saturday, label: Text('Sat')),
              ButtonSegment(value: DateTime.sunday, label: Text('Sun')),
            ],
            selected: {s.weekStart},
            onSelectionChanged: (v) => _save((c) => c.copyWith(weekStart: v.first)),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.sync_outlined),
          title: const Text('Sync interval'),
          trailing: DropdownButton<int>(
            value: s.syncIntervalMinutes,
            items: const [
              DropdownMenuItem(value: 5, child: Text('5 min')),
              DropdownMenuItem(value: 15, child: Text('15 min')),
              DropdownMenuItem(value: 30, child: Text('30 min')),
              DropdownMenuItem(value: 60, child: Text('1 hour')),
            ],
            onChanged: (v) => _save((c) => c.copyWith(syncIntervalMinutes: v)),
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('Google OAuth client', style: theme.textTheme.titleSmall),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            usingDefault
                ? 'Using the built-in public installed-app credentials (same as Thunderbird). No Google Cloud setup needed. '
                    'Enter your own client id and secret to replace them.'
                : 'Using your own client credentials.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _clientId,
            decoration: InputDecoration(labelText: 'Client ID', hintText: GoogleOAuthClient.defaultClientId, border: const OutlineInputBorder()),
            onChanged: (v) => _save((c) => c.copyWith(googleClientId: v)),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _clientSecret,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Client secret', border: OutlineInputBorder()),
            onChanged: (v) => _save((c) => c.copyWith(googleClientSecret: v)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: usingDefault
                  ? null
                  : () {
                      _clientId.clear();
                      _clientSecret.clear();
                      _save((c) => c.copyWith(googleClientId: '', googleClientSecret: ''));
                    },
              child: const Text('Reset to built-in credentials'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            'Sign-in opens your browser and returns to the app through http://127.0.0.1 (loopback). '
            'Refresh tokens are stored in the system keychain, one per Google account, and shared by all its calendars.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ]),
    );
  }
}
