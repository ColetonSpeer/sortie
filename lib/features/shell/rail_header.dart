import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';
import '../../router/app_router.dart';
import 'format.dart';

/// Account switcher + sync status + "Sorting: …" badge.
class RailHeader extends ConsumerWidget {
  const RailHeader({super.key, required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).asData?.value ?? const <Account>[];
    final current = accounts.where((a) => a.id == accountId).firstOrNull;
    final status = ref.watch(syncStatusProvider).asData?.value[accountId];
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: PopupMenuButton<String>(
              tooltip: 'Switch account',
              onSelected: (v) {
                if (v == '__manage') {
                  context.push(Routes.accounts);
                } else if (v == '__add') {
                  context.push(Routes.onboarding);
                } else {
                  context.go(Routes.mailbox(v, 'INBOX'));
                }
              },
              itemBuilder: (_) => [
                for (final a in accounts)
                  PopupMenuItem(
                    value: a.id,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(a.id == accountId ? Icons.radio_button_checked : Icons.radio_button_off),
                      title: Text(a.displayName),
                      subtitle: Text(a.email),
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(value: '__add', child: Text('Add account…')),
                const PopupMenuItem(value: '__manage', child: Text('Manage accounts…')),
              ],
              child: Row(children: [
                CircleAvatar(
                  radius: 16,
                  child: Text(Fmt.initials(current?.displayName ?? '?')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(current?.displayName ?? 'Account',
                        style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(current?.email ?? '',
                        style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                const Icon(Icons.arrow_drop_down),
              ]),
            ),
          ),
          SyncStatusIndicator(status: status, accountId: accountId),
        ]),
        const SizedBox(height: 8),
        CoordinationBadge(accountId: accountId),
      ]),
    );
  }
}

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key, required this.status, required this.accountId});
  final AccountSyncStatus? status;
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = status?.state ?? AccountSyncState.idle;
    final cs = Theme.of(context).colorScheme;
    final color = switch (state) {
      AccountSyncState.authFailed || AccountSyncState.offline => cs.error,
      AccountSyncState.idling => cs.primary,
      _ => cs.onSurfaceVariant,
    };
    final busy = state == AccountSyncState.syncing || state == AccountSyncState.connecting;
    final tip = [
      Fmt.syncLabel(state),
      if (status?.error != null) status!.error!,
      if (status?.nextRetryAt != null) 'retry ${Fmt.relativeDate(status!.nextRetryAt!)}',
    ].join('\n');
    return IconButton(
      tooltip: '$tip\nClick to sync now',
      onPressed: () => ref.read(mailSyncServiceProvider).syncNow(accountId),
      icon: busy
          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: color))
          : Icon(Fmt.syncIcon(state), color: color, size: 20),
    );
  }
}

/// "Sorting: this device" / "Sorting: `<other device>`" / "Sorting: off".
class CoordinationBadge extends ConsumerWidget {
  const CoordinationBadge({super.key, required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final config = ref.watch(sortConfigProvider(accountId)).asData?.value;
    final state = ref.watch(coordinationStateProvider(accountId));
    final devices = ref.watch(seenDevicesProvider(accountId)).asData?.value ?? const <SeenDevice>[];

    String label;
    IconData icon;
    Color fg;
    if (config?.mode == SortingMode.off || state.hasError) {
      label = 'Sorting: off';
      icon = Icons.pause_circle_outline;
      fg = cs.onSurfaceVariant;
    } else {
      final s = state.asData?.value ?? CoordinationState.stopped;
      switch (s) {
        case CoordinationState.leader:
          label = 'Sorting: this device';
          icon = Icons.auto_awesome;
          fg = cs.primary;
        case CoordinationState.follower:
          final leader = devices.where((d) => d.isLeader && !d.isThisDevice).firstOrNull;
          label = 'Sorting: ${leader?.displayName ?? 'another device'}';
          icon = Icons.devices_other_outlined;
          fg = cs.onSurfaceVariant;
        case CoordinationState.stopped:
          label = 'Sorting: off';
          icon = Icons.pause_circle_outline;
          fg = cs.onSurfaceVariant;
        default:
          label = 'Sorting: ${Fmt.coordinationLabel(s)}';
          icon = Icons.sync_outlined;
          fg = cs.onSurfaceVariant;
      }
    }
    return Tooltip(
      message: 'Which device runs the sorter for this account. Change in Settings > Devices.',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(Routes.settingsPage('devices')),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      ),
    );
  }
}
