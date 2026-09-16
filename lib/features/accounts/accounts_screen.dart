import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../router/app_router.dart';

/// Account list: rename, enable/disable, identities, delete, add.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.onboarding),
        icon: const Icon(Icons.add),
        label: const Text('Add account'),
      ),
      body: accounts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => ListView(
          children: [for (final a in list) _AccountTile(account: a)],
        ),
      ),
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(accountRepositoryProvider);
    final status = ref.watch(syncStatusProvider).asData?.value[account.id];
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(children: [
        ListTile(
          leading: CircleAvatar(child: Text(account.displayName.isEmpty ? '?' : account.displayName[0].toUpperCase())),
          title: Text(account.displayName),
          subtitle: Text('${account.email}\n${account.imap.host}:${account.imap.port} · ${account.smtp.host}:${account.smtp.port}'
              '${status?.error != null ? '\n${status!.error}' : ''}'),
          isThreeLine: true,
          trailing: Switch(
            value: account.enabled,
            onChanged: (v) async {
              await repo.upsert(account.copyWith(enabled: v));
              final sync = ref.read(mailSyncServiceProvider);
              if (v) {
                await sync.startAccount(account.id);
              } else {
                await sync.stopAccount(account.id);
              }
            },
          ),
        ),
        OverflowBar(alignment: MainAxisAlignment.end, children: [
          TextButton.icon(icon: const Icon(Icons.edit_outlined), label: const Text('Rename'), onPressed: () => _rename(context, repo)),
          TextButton.icon(
            icon: const Icon(Icons.badge_outlined),
            label: const Text('Identities'),
            onPressed: () => context.push(Routes.identities(account.id)),
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove'),
            onPressed: () => _delete(context, ref),
          ),
        ]),
      ]),
    );
  }

  Future<void> _rename(BuildContext context, AccountRepository repo) async {
    final ctrl = TextEditingController(text: account.displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Account name'),
        content: TextField(controller: ctrl, autofocus: true, onSubmitted: (v) => Navigator.pop(ctx, v)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Save')),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) await repo.upsert(account.copyWith(displayName: name.trim()));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${account.displayName}?'),
        content: const Text('Cached mail on this device is deleted. Nothing changes on the server.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(mailSyncServiceProvider).stopAccount(account.id);
    } catch (_) {}
    await ref.read(credentialStoreProvider).delete(CredentialStore.accountPassword(account.id));
    await ref.read(accountRepositoryProvider).delete(account.id);
  }
}
