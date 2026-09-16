import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/providers.dart';
import '../../core/logging.dart';
import '../../domain/services/services.dart';
import '../shell/format.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>((_) => PackageInfo.fromPlatform());

class DiagnosticsPage extends ConsumerWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(_packageInfoProvider);
    final status = ref.watch(syncStatusProvider).asData?.value ?? const <String, AccountSyncStatus>{};
    final lines = logBuffer.snapshot();
    final theme = Theme.of(context);
    String? deviceId;
    try {
      deviceId = ref.read(deviceIdentityProvider).deviceId;
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: ListView(children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Version'),
          subtitle: Text(info.when(
            data: (p) => '${p.appName} ${p.version}+${p.buildNumber}',
            loading: () => '…',
            error: (e, _) => 'unknown ($e)',
          )),
        ),
        ListTile(
          leading: const Icon(Icons.computer_outlined),
          title: const Text('Platform'),
          subtitle: Text(kIsWeb ? 'web' : '${Platform.operatingSystem} ${Platform.operatingSystemVersion}'),
        ),
        if (deviceId != null)
          ListTile(leading: const Icon(Icons.fingerprint), title: const Text('Device id'), subtitle: SelectableText(deviceId)),
        for (final s in status.values)
          ListTile(
            leading: Icon(Fmt.syncIcon(s.state)),
            title: Text('Account ${s.accountId}: ${Fmt.syncLabel(s.state)}'),
            subtitle: s.error == null ? null : Text(s.error!),
          ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Export log'),
          subtitle: Text('${lines.length} lines in memory'),
          onTap: () => _export(context, lines),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 360),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
            child: SingleChildScrollView(
              child: SelectableText(
                lines.isEmpty ? '(no log lines yet)' : lines.reversed.take(200).join('\n'),
                style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _export(BuildContext context, List<String> lines) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final path = await FilePicker.saveFile(
        dialogTitle: 'Export Sortie log',
        fileName: 'sortie-log-$stamp.txt',
        bytes: Uint8List.fromList(utf8.encode(lines.join('\n'))),
      );
      if (path != null) messenger?.showSnackBar(SnackBar(content: Text('Saved to $path')));
    } catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}
