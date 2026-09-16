import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';

/// Resolves the account a per-account settings page works on and shows a
/// switcher when there is more than one.
class AccountScope extends ConsumerWidget {
  const AccountScope({super.key, required this.builder});
  final Widget Function(BuildContext context, String accountId) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).asData?.value ?? const <Account>[];
    if (accounts.isEmpty) return const Center(child: Text('Add an account first.'));
    final selected = ref.watch(selectedAccountIdProvider);
    final id = accounts.any((a) => a.id == selected) ? selected! : accounts.first.id;
    return Column(children: [
      if (accounts.length > 1)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: DropdownButtonFormField<String>(
            initialValue: id,
            decoration: const InputDecoration(labelText: 'Account', border: OutlineInputBorder()),
            items: [for (final a in accounts) DropdownMenuItem(value: a.id, child: Text('${a.displayName} <${a.email}>'))],
            onChanged: (v) => ref.read(selectedAccountIdProvider.notifier).state = v,
          ),
        ),
      Expanded(child: builder(context, id)),
    ]);
  }
}

/// Writes a SortConfig through the coordinator (shared with other devices),
/// falling back to the local mirror when the coordinator is unavailable.
Future<void> saveSortConfig(WidgetRef ref, String accountId, SortConfig c) async {
  try {
    await ref.read(sortCoordinatorProvider(accountId)).putConfig(c);
  } catch (_) {
    // Coordinator offline / not started: keep the local mirror current.
  }
  await ref.read(settingsRepositoryProvider).saveSortConfig(accountId, c);
}

Future<void> saveDeviceSettings(WidgetRef ref, DeviceSettings Function(DeviceSettings) edit) async {
  final repo = ref.read(settingsRepositoryProvider);
  await repo.saveDevice(edit(await repo.device()));
}

Future<void> saveAiSettings(WidgetRef ref, AiSettings Function(AiSettings) edit) async {
  final repo = ref.read(settingsRepositoryProvider);
  await repo.saveAi(edit(await repo.ai()));
}

/// Human description of what leaves the device for classification.
String privacySendingLine(AiSettings s) {
  if (s.kind == AiProviderKind.none) return 'Sending: nothing (AI sorting is off)';
  final what = switch (s.effectivePrivacy) {
    PrivacyLevel.full => 'Full message text',
    PrivacyLevel.snippet => 'Snippet',
    PrivacyLevel.headersOnly => 'Headers only',
  };
  final host = s.kind == AiProviderKind.anthropic ? 'api.anthropic.com' : (Uri.tryParse(s.baseUrl)?.host ?? '').trim();
  return 'Sending: $what to ${host.isEmpty ? 'your endpoint' : host}${s.isLocal ? ' (local network)' : ''}';
}

class PrivacySection extends ConsumerWidget {
  const PrivacySection({super.key, required this.settings});
  final AiSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = settings;
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RadioGroup<PrivacyLevel?>(
        groupValue: s.privacy,
        onChanged: (v) => saveAiSettings(ref, (a) => a.copyWith(privacy: v, clearPrivacy: v == null)),
        child: Column(children: [
          RadioListTile<PrivacyLevel?>(
            value: null,
            title: const Text('Automatic'),
            subtitle: Text('Full text for local endpoints, snippet for cloud (${s.isLocal ? 'full text' : 'snippet'} now)'),
          ),
          const RadioListTile<PrivacyLevel?>(value: PrivacyLevel.full, title: Text('Full message text')),
          const RadioListTile<PrivacyLevel?>(value: PrivacyLevel.snippet, title: Text('Snippet'), subtitle: Text('Headers plus the first few lines')),
          const RadioListTile<PrivacyLevel?>(value: PrivacyLevel.headersOnly, title: Text('Headers only'), subtitle: Text('Sender, subject, list headers')),
        ]),
      ),
      SwitchListTile(
        title: const Text('Redact secrets before sending'),
        subtitle: const Text('Masks codes, card numbers and links in the text'),
        value: s.effectiveRedact,
        onChanged: (v) => saveAiSettings(ref, (a) => a.copyWith(redactSecrets: v)),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(children: [
          Icon(Icons.shield_outlined, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(privacySendingLine(s), key: const Key('sendingLine'), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
        ]),
      ),
    ]);
  }
}
