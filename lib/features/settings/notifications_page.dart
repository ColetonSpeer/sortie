import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../platform/device_info.dart';
import '../../services/notifications/notification_service.dart';
import 'settings_common.dart';

String notifyModeLabel(NotifyMode m) => switch (m) {
      NotifyMode.off => 'Off',
      NotifyMode.all => 'Every message',
      NotifyMode.important => 'Important only',
    };

/// Per-device: a desktop usually wants every message, a phone only the
/// important ones. The choice is not shared through the mail account.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = !isDesktop;
    final device = ref.watch(deviceSettingsProvider).asData?.value ?? const DeviceSettings();
    final mode = device.effectiveNotifyMode(mobile: mobile);
    final platformDefault = const DeviceSettings().effectiveNotifyMode(mobile: mobile);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('New mail on this device', style: theme.textTheme.titleSmall),
        ),
        RadioGroup<NotifyMode>(
          groupValue: mode,
          onChanged: (v) async {
            if (v == null) return;
            await saveDeviceSettings(ref, (d) => d.copyWith(notifyMode: v));
            if (v != NotifyMode.off) await ref.read(notificationServiceProvider).requestPermission();
          },
          child: Column(children: [
            RadioListTile<NotifyMode>(
              value: NotifyMode.all,
              title: const Text('Every message'),
              subtitle: Text('One notification per unread message that lands in the inbox${platformDefault == NotifyMode.all ? ' (default on computers)' : ''}'),
            ),
            RadioListTile<NotifyMode>(
              value: NotifyMode.important,
              title: const Text('Important only'),
              subtitle: Text('People you have written to, replies in your conversations, flagged mail, and mail sent directly to you by a person${platformDefault == NotifyMode.important ? ' (default on phones)' : ''}'),
            ),
            const RadioListTile<NotifyMode>(value: NotifyMode.off, title: Text('Off')),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Important only stays quiet for mailing lists, newsletters, automated senders such as no-reply or notifications addresses, '
            'and mail where you are only copied or one of many recipients. Mail you already read on another device is never announced. '
            'Each device keeps its own choice.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.notifications_active_outlined),
          title: const Text('Send a test notification'),
          onTap: () => ref.read(notificationServiceProvider).notifyTest(),
        ),
      ]),
    );
  }
}
