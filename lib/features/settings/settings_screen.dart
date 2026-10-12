import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../router/app_router.dart';
import 'settings_common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ai = ref.watch(aiSettingsProvider).asData?.value ?? const AiSettings();
    final device = ref.watch(deviceSettingsProvider).asData?.value ?? const DeviceSettings();
    final desktop = !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

    Widget link(String sub, IconData icon, String title, String subtitle) => ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(Routes.settingsPage(sub)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        ListTile(
          leading: const Icon(Icons.account_circle_outlined),
          title: const Text('Accounts & identities'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(Routes.accounts),
        ),
        const Divider(),
        link('ai', Icons.auto_awesome_outlined, 'AI backend', ai.kind == AiProviderKind.none ? 'Off' : '${ai.kind.name} · ${ai.model}'),
        link('sorting', Icons.low_priority_outlined, 'Sorting', 'Mode, grace period, thresholds, bootstrap'),
        link('rules', Icons.rule, 'Sorting rules', 'View, add and edit rules; imported Thunderbird filters'),
        link('privacy', Icons.shield_outlined, 'Privacy', privacySendingLine(ai)),
        link('folders', Icons.folder_outlined, 'Folders', 'Exclusions and descriptions'),
        link('devices', Icons.devices_outlined, 'Devices', 'Which device sorts'),
        link('notifications', Icons.notifications_outlined, 'Notifications', device.notifyNewMail ? 'On' : 'Off'),
        link('calendar', Icons.calendar_month_outlined, 'Calendar', 'Reminders, week start, sync, Google'),
        link('diagnostics', Icons.bug_report_outlined, 'Diagnostics', 'Logs, version, export'),
        const Divider(),
        ListTile(
          key: const Key('importThunderbird'),
          leading: const Icon(Icons.move_to_inbox_outlined),
          title: const Text('Import from Thunderbird'),
          subtitle: const Text('Accounts, identities, signatures, filters, calendars'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(Routes.settingsImport),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.brightness_6_outlined),
          title: const Text('Theme'),
          trailing: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'system', label: Text('System')),
              ButtonSegment(value: 'light', label: Text('Light')),
              ButtonSegment(value: 'dark', label: Text('Dark')),
            ],
            selected: {device.themeMode},
            onSelectionChanged: (s) => saveDeviceSettings(ref, (d) => d.copyWith(themeMode: s.first)),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.image_outlined),
          title: const Text('Always load remote images'),
          subtitle: const Text('Off is more private; you can load per message'),
          value: device.loadRemoteImages,
          onChanged: (v) => saveDeviceSettings(ref, (d) => d.copyWith(loadRemoteImages: v)),
        ),
        if (desktop) ...[
          SwitchListTile(
            secondary: const Icon(Icons.minimize_outlined),
            title: const Text('Keep running in the tray when closed'),
            subtitle: const Text('Needed to keep syncing and sorting in the background'),
            value: device.minimizeToTray,
            onChanged: (v) => saveDeviceSettings(ref, (d) => d.copyWith(minimizeToTray: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.power_settings_new_outlined),
            title: const Text('Launch at startup'),
            value: device.launchAtStartup,
            onChanged: (v) => saveDeviceSettings(ref, (d) => d.copyWith(launchAtStartup: v)),
          ),
        ],
      ]),
    );
  }
}
