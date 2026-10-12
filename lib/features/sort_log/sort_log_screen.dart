import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';
import '../mailbox/message_actions.dart';
import '../shell/format.dart';
import 'suggestion_card.dart';

/// Reverse-chronological sorter activity for the selected account.
class SortLogScreen extends ConsumerWidget {
  const SortLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).asData?.value ?? const <Account>[];
    final selected = ref.watch(selectedAccountIdProvider) ?? accounts.firstOrNull?.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sort log'),
        actions: [
          if (accounts.length > 1 && selected != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: DropdownButton<String>(
                value: selected,
                underline: const SizedBox.shrink(),
                items: [for (final a in accounts) DropdownMenuItem(value: a.id, child: Text(a.displayName))],
                onChanged: (v) => ref.read(selectedAccountIdProvider.notifier).state = v,
              ),
            ),
        ],
      ),
      body: selected == null ? const Center(child: Text('No account')) : _LogBody(accountId: selected),
    );
  }
}

class _LogBody extends ConsumerWidget {
  const _LogBody({required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(sortLogProvider(accountId));
    final devices = ref.watch(seenDevicesProvider(accountId)).asData?.value ?? const <SeenDevice>[];
    String deviceName(String? id) => id == null ? '' : (devices.where((d) => d.deviceId == id).firstOrNull?.displayName ?? id.substring(0, id.length.clamp(0, 8)));

    return Column(children: [
      _Header(accountId: accountId),
      const Divider(height: 1),
      Expanded(
        child: log.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Sort log unavailable: $e')),
          data: (entries) {
            final sorted = List.of(entries)..sort((a, b) => b.at.compareTo(a.at));
            final rows = <Widget>[SuggestedRulesSection(accountId: accountId)];
            if (entries.isEmpty) {
              rows.add(const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Nothing sorted yet'))));
              return ListView(children: rows);
            }
            String? day;
            for (final e in sorted) {
              final heading = Fmt.dayHeading(e.at);
              if (heading != day) {
                day = heading;
                rows.add(Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(heading, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
                ));
              }
              rows.add(_LogTile(entry: e, deviceName: deviceName(e.deviceId)));
            }
            return ListView(children: rows);
          },
        ),
      ),
    ]);
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coordinationStateProvider(accountId)).asData?.value ?? CoordinationState.stopped;
    final spend = ref.watch(_spendProvider);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(spacing: 24, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.auto_awesome_outlined, size: 18),
          const SizedBox(width: 6),
          Text('Sorting: ${Fmt.coordinationLabel(state)}', style: theme.textTheme.titleSmall),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.payments_outlined, size: 18),
          const SizedBox(width: 6),
          Text(
            spend.when(
              data: (s) => 'AI spend: \$${s.$1.toStringAsFixed(3)} today · \$${s.$2.toStringAsFixed(2)} this month',
              loading: () => 'AI spend: …',
              error: (_, _) => 'AI spend: unavailable',
            ),
            style: theme.textTheme.bodySmall,
          ),
        ]),
      ]),
    );
  }
}

final _spendProvider = FutureProvider<(double, double)>((ref) => ref.watch(messageClassifierProvider).spend());

class _LogTile extends ConsumerWidget {
  const _LogTile({required this.entry, required this.deviceName});
  final SortLogEntry entry;
  final String deviceName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final route = entry.fromFolder != null && entry.toFolder != null ? '${entry.fromFolder} → ${entry.toFolder}' : (entry.toFolder ?? entry.fromFolder ?? '');
    final meta = [
      if (entry.confidence != null) Fmt.percent(entry.confidence!),
      if (deviceName.isNotEmpty) deviceName,
      if (entry.cause != null) entry.cause!,
      DateFormatShort.time(entry.at),
    ].join(' · ');

    return ListTile(
      leading: Icon(Fmt.logTypeIcon(entry.type), color: entry.type == 'undo' || entry.type == 'correction' ? cs.tertiary : cs.primary),
      title: Text(entry.subject.isEmpty ? '(no subject)' : entry.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(entry.from, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
        if (route.isNotEmpty) Text(route, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        if (entry.reason != null && entry.reason!.isNotEmpty) Text(entry.reason!, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        Text(meta, style: theme.textTheme.labelSmall?.copyWith(color: cs.outline)),
      ]),
      isThreeLine: true,
      trailing: entry.undoable && entry.decisionId != null
          ? TextButton(onPressed: () => MessageActions(context, ref).undo(entry.key.accountId, entry.decisionId!), child: const Text('Undo'))
          : null,
    );
  }
}

abstract final class DateFormatShort {
  static String time(DateTime d) => Fmt.relativeDate(d);
}
