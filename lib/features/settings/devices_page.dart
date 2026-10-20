import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';
import '../shell/format.dart';
import 'settings_common.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Devices')),
        body: AccountScope(builder: (_, id) => _DevicesBody(accountId: id)),
      );
}

class _DevicesBody extends ConsumerWidget {
  const _DevicesBody({required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(seenDevicesProvider(accountId));
    final device = ref.watch(deviceSettingsProvider).asData?.value ?? const DeviceSettings();
    final state = ref.watch(coordinationStateProvider(accountId)).asData?.value ?? CoordinationState.stopped;
    final lastSync = ref.watch(lastConfigSyncProvider(accountId)).asData?.value;
    final theme = Theme.of(context);
    final android = !kIsWeb && Platform.isAndroid;
    final ios = !kIsWeb && Platform.isIOS;

    return ListView(padding: const EdgeInsets.only(bottom: 32), children: [
      ListTile(
        leading: const Icon(Icons.auto_awesome_outlined),
        title: Text('This account is sorted by: ${Fmt.coordinationLabel(state)}'),
        subtitle: const Text('Desktops lead by default; phones sort while open. Leadership hands off automatically.'),
      ),
      if (lastSync != null)
        ListTile(
          leading: const Icon(Icons.sync_outlined),
          title: Text('Settings synced from ${_deviceName(devices.asData?.value, lastSync.deviceId)} ${Fmt.relativeDate(lastSync.at)} ago'),
          subtitle: const Text('Identities, rules, calendars and preferences follow you between devices'),
        ),
      const Divider(),
      ListTile(title: Text('Seen devices', style: theme.textTheme.titleSmall)),
      devices.when(
        loading: () => const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
        error: (e, _) => ListTile(title: Text('Unavailable: $e')),
        data: (list) => Column(children: [
          if (list.isEmpty) const ListTile(title: Text('No other devices seen yet')),
          for (final d in list)
            ListTile(
              leading: Icon(_platformIcon(d.platform)),
              title: Row(children: [
                Text(d.displayName),
                if (d.isLeader) ...[const SizedBox(width: 6), Icon(Icons.star, size: 18, color: theme.colorScheme.primary)],
                if (d.isThisDevice) ...[const SizedBox(width: 6), const Chip(label: Text('this device'), visualDensity: VisualDensity.compact)],
              ]),
              subtitle: Text('${d.platform} · priority ${d.priority} · seen ${Fmt.relativeDate(d.lastSeen)} ago'),
            ),
        ]),
      ),
      const Divider(),
      ListTile(title: Text('This device', style: theme.textTheme.titleSmall)),
      SwitchListTile(
        title: const Text('May lead sorting'),
        subtitle: const Text('Off: this device only shows results from others'),
        value: device.mayLead,
        onChanged: (v) => saveDeviceSettings(ref, (d) => d.copyWith(mayLead: v)),
      ),
      SwitchListTile(
        title: const Text('Prefer this device'),
        subtitle: const Text('Wins elections against other devices (priority 100)'),
        value: device.preferThisDevice,
        onChanged: device.mayLead ? (v) => saveDeviceSettings(ref, (d) => d.copyWith(preferThisDevice: v)) : null,
      ),
      if (android)
        SwitchListTile(
          title: const Text('Keep sorting in the background'),
          subtitle: const Text('Runs a persistent low-priority notification so this phone can lead while the app is closed'),
          value: device.androidForegroundService,
          onChanged: (v) => saveDeviceSettings(ref, (d) => d.copyWith(androidForegroundService: v)),
        ),
      if (ios)
        SwitchListTile(
          title: const Text('Keep sorting in the background'),
          subtitle: const Text('Keeps Sortie running after you leave it (a silent audio session) so this phone can lead; uses more battery'),
          value: device.backgroundKeepAlive,
          onChanged: (v) => saveDeviceSettings(ref, (d) => d.copyWith(backgroundKeepAlive: v)),
        ),
    ]);
  }

  static String _deviceName(List<SeenDevice>? list, String? deviceId) {
    if (deviceId == null) return 'a snapshot';
    for (final d in list ?? const <SeenDevice>[]) {
      if (d.deviceId == deviceId) return d.displayName;
    }
    return 'another device';
  }

  static IconData _platformIcon(String p) => switch (p.toLowerCase()) {
        'android' || 'ios' => Icons.smartphone_outlined,
        'linux' || 'windows' || 'macos' => Icons.computer_outlined,
        _ => Icons.devices_other_outlined,
      };
}
