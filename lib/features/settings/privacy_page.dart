import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import 'settings_common.dart';

class PrivacyPage extends ConsumerWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ai = ref.watch(aiSettingsProvider).asData?.value ?? const AiSettings();
    final device = ref.watch(deviceSettingsProvider).asData?.value ?? const DeviceSettings();
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Sortie only sends what is needed to classify a message. Nothing is sent when AI sorting is off.'),
        ),
        PrivacySection(settings: ai),
        const Divider(),
        SwitchListTile(
          title: const Text('Always load remote images'),
          subtitle: const Text('Remote images can reveal that you opened a message'),
          value: device.loadRemoteImages,
          onChanged: (v) => saveDeviceSettings(ref, (d) => d.copyWith(loadRemoteImages: v)),
        ),
      ]),
    );
  }
}
