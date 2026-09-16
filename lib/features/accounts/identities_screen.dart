import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';

/// Identities (aliases) of one account.
class IdentitiesScreen extends ConsumerWidget {
  const IdentitiesScreen({super.key, required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(identitiesProvider(accountId));
    return Scaffold(
      appBar: AppBar(title: const Text('Identities')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showIdentityEditor(context, ref, accountId: accountId),
        icon: const Icon(Icons.add),
        label: const Text('Add identity'),
      ),
      body: ids.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => ListView(children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Aliases share this account\'s outgoing server. When you reply to mail sent to an alias, Sortie picks it automatically.'),
          ),
          for (final i in list)
            ListTile(
              leading: Icon(i.isDefault ? Icons.star : Icons.badge_outlined),
              title: Text('${i.name} <${i.email}>'),
              subtitle: Text([
                if (i.replyTo != null && i.replyTo!.isNotEmpty) 'Reply-To: ${i.replyTo}',
                if (i.signature.isNotEmpty) 'Signature: ${i.signature.split('\n').first}',
                if (i.isDefault) 'Default',
              ].join(' · ')),
              onTap: () => showIdentityEditor(context, ref, accountId: accountId, existing: i),
              trailing: IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: list.length <= 1 ? null : () => ref.read(accountRepositoryProvider).deleteIdentity(i.id),
              ),
            ),
        ]),
      ),
    );
  }
}

Future<void> showIdentityEditor(BuildContext context, WidgetRef ref, {required String accountId, Identity? existing}) {
  final name = TextEditingController(text: existing?.name ?? '');
  final email = TextEditingController(text: existing?.email ?? '');
  final replyTo = TextEditingController(text: existing?.replyTo ?? '');
  final signature = TextEditingController(text: existing?.signature ?? '');
  var isDefault = existing?.isDefault ?? false;
  final formKey = GlobalKey<FormState>();

  return showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(existing == null ? 'New identity' : 'Edit identity'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null),
              TextFormField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid address',
              ),
              TextFormField(controller: replyTo, decoration: const InputDecoration(labelText: 'Reply-To (optional)')),
              TextFormField(controller: signature, decoration: const InputDecoration(labelText: 'Signature'), minLines: 2, maxLines: 5),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Default identity'),
                value: isDefault,
                onChanged: (v) => setState(() => isDefault = v),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await ref.read(accountRepositoryProvider).upsertIdentity(Identity(
                    id: existing?.id ?? const Uuid().v4(),
                    accountId: accountId,
                    name: name.text.trim(),
                    email: email.text.trim(),
                    replyTo: replyTo.text.trim().isEmpty ? null : replyTo.text.trim(),
                    signature: signature.text,
                    isDefault: isDefault,
                  ));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
