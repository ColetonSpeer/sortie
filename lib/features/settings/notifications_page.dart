import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../services/notifications/notification_service.dart';
import 'settings_common.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(deviceSettingsProvider).asData?.value ?? const DeviceSettings();
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(children: [
        SwitchListTile(
          title: const Text('New mail'),
          subtitle: const Text('One notification per message, grouped per account'),
          value: device.notifyNewMail,
          onChanged: (v) async {
            await saveDeviceSettings(ref, (d) => d.copyWith(notifyNewMail: v));
            if (v) await ref.read(notificationServiceProvider).requestPermission();
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications_active_outlined),
          title: const Text('Send a test notification'),
          onTap: () => ref.read(notificationServiceProvider).notifyTest(),
        ),
      ]),
    );
  }
}
