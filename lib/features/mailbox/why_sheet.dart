import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';
import '../shell/format.dart';
import 'folder_picker.dart';

/// Bottom sheet explaining a pending sort decision with feedback buttons.
Future<void> showWhySheet(BuildContext context, WidgetRef ref, MessageHeader header, PendingBadge badge) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => WhySheet(header: header, badge: badge),
  );
}

class WhySheet extends ConsumerWidget {
  const WhySheet({super.key, required this.header, required this.badge});
  final MessageHeader header;
  final PendingBadge badge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final coord = ref.read(sortCoordinatorProvider(header.accountId));
    final modeText = switch (badge.mode) {
      SortMode.moveNow => 'Will move as soon as possible',
      SortMode.moveAfterRead => 'Will move after you finish reading it',
      SortMode.suggestOnly => 'Suggestion only — nothing moves unless you say so',
      SortMode.keep => 'Stays in the inbox',
    };
    void close() => Navigator.of(context).pop();
    void snack(String s) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(s)));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(header.subject, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          Text(header.from?.toString() ?? '', style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.drive_file_move_outlined),
            const SizedBox(width: 8),
            Expanded(child: Text('${header.folderPath} → ${badge.destination}', style: theme.textTheme.titleSmall)),
            Chip(label: Text(Fmt.percent(badge.confidence)), avatar: const Icon(Icons.speed_outlined, size: 16)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Fmt.layerIcon(badge.layer), size: 18),
            const SizedBox(width: 8),
            Text(Fmt.layerLabel(badge.layer), style: theme.textTheme.labelLarge),
            const SizedBox(width: 12),
            Expanded(child: Text(modeText, style: theme.textTheme.bodySmall)),
          ]),
          const SizedBox(height: 12),
          Text('Reason', style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(badge.reason.isEmpty ? '(no reason recorded)' : badge.reason),
          const SizedBox(height: 20),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.tonalIcon(
              icon: const Icon(Icons.thumb_down_outlined),
              label: const Text('Wrong folder'),
              onPressed: () async {
                final dest = await pickFolder(context, ref, header.accountId,
                    title: 'Where should it go?', exclude: {badge.destination});
                if (dest == null) return;
                await coord.changeDestination(header.key, dest);
                if (context.mounted) {
                  snack('Will move to $dest');
                  close();
                }
              },
            ),
            FilledButton.icon(
              icon: const Icon(Icons.thumb_up_outlined),
              label: const Text('Right'),
              onPressed: () async {
                await coord.markRight(header.key);
                if (context.mounted) {
                  snack('Thanks — noted as correct');
                  close();
                }
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.rule_outlined),
              label: const Text('Always sort this sender here'),
              onPressed: () {
                snack('Sender rules are coming soon');
                close();
              },
            ),
          ]),
        ]),
      ),
    );
  }
}
