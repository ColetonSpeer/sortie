import 'package:flutter/material.dart';

import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';
import '../shell/format.dart';

/// Chip on a message tile describing the pending sort decision.
///
/// moveNow / moveAfterRead: `→ Work/Invoices · 91%`
/// suggestOnly:             `Suggest: Work/Invoices [Move] [No]`
class PendingBadgeChip extends StatelessWidget {
  const PendingBadgeChip({
    super.key,
    required this.badge,
    required this.onTap,
    required this.onMove,
    required this.onDismiss,
  });
  final PendingBadge badge;
  final VoidCallback onTap;
  final VoidCallback onMove;
  final VoidCallback onDismiss;

  static String label(PendingBadge b) => b.mode == SortMode.suggestOnly
      ? 'Suggest: ${b.destination}'
      : '→ ${b.destination} · ${Fmt.percent(b.confidence)}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final suggest = badge.mode == SortMode.suggestOnly;
    final bg = suggest ? cs.tertiaryContainer : cs.primaryContainer;
    final fg = suggest ? cs.onTertiaryContainer : cs.onPrimaryContainer;
    final text = Theme.of(context).textTheme.labelSmall?.copyWith(color: fg);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Fmt.layerIcon(badge.layer), size: 12, color: fg),
            const SizedBox(width: 4),
            Flexible(child: Text(label(badge), style: text, maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (suggest) ...[
              const SizedBox(width: 6),
              _MiniButton(label: 'Move', fg: fg, onTap: onMove),
              const SizedBox(width: 2),
              _MiniButton(label: 'No', fg: fg, onTap: onDismiss),
            ],
          ]),
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.label, required this.fg, required this.onTap});
  final String label;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(border: Border.all(color: fg.withValues(alpha: 0.6)), borderRadius: BorderRadius.circular(6)),
          child: Text('[$label]', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w600)),
        ),
      );
}
