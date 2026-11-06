import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/services.dart';
import '../../router/app_router.dart';

/// Account list: rename, enable/disable, identities, password, delete, add.
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
    final needsLogin = status?.state == AccountSyncState.authFailed;
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
          // A phone restored from a backup keeps the account but not its
          // keychain entry, so the password has to be entered again here.
          if (needsLogin)
            FilledButton.icon(
              key: Key('accountPassword:${account.id}'),
              icon: const Icon(Icons.key_outlined),
              label: const Text('Sign in'),
              onPressed: () => _password(context, ref),
            )
          else
            TextButton.icon(
              key: Key('accountPassword:${account.id}'),
              icon: const Icon(Icons.key_outlined),
              label: const Text('Password'),
              onPressed: () => _password(context, ref),
            ),
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

  /// Asks for the password, checks it against the server, stores it and
  /// restarts the account's sync (which may be parked in authFailed).
  Future<void> _password(BuildContext context, WidgetRef ref) async {
    final probe = ref.read(loginProbeProvider);
    final pw = await showDialog<String>(
      context: context,
      builder: (ctx) => _PasswordDialog(account: account, probe: probe),
    );
    if (pw == null) return;
    await ref.read(credentialStoreProvider).write(CredentialStore.accountPassword(account.id), pw);
    final sync = ref.read(mailSyncServiceProvider);
    try {
      await sync.stopAccount(account.id);
    } catch (_) {}
    if (account.enabled) await sync.startAccount(account.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signed in to ${account.displayName}.')));
    }
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

/// Password prompt that only closes with a password the server accepted.
class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.account, required this.probe});
  final Account account;
  final Future<void> Function(Account account, String password) probe;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  bool _show = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pw = _ctrl.text;
    if (pw.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.probe(widget.account, pw);
      if (mounted) Navigator.pop(context, pw);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Login failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Password for ${widget.account.email}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Checked on ${widget.account.imap.host} before it is saved.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            key: const Key('accountPasswordField'),
            controller: _ctrl,
            autofocus: true,
            obscureText: !_show,
            enabled: !_busy,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: _error,
              errorMaxLines: 4,
              suffixIcon: IconButton(
                icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _show = !_show),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ]),
        actions: [
          TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            key: const Key('accountPasswordSignIn'),
            onPressed: _busy ? null : _submit,
            child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign in'),
          ),
        ],
      );
}
