import 'package:flutter/material.dart';

/// Touch layouts: swipe right = delete, swipe left = archive. Actions run
/// optimistically and the list stream removes the row, so the Dismissible
/// itself never removes anything (confirmDismiss always answers false).
class SwipeToAct extends StatelessWidget {
  const SwipeToAct({super.key, required this.swipeKey, required this.onDelete, required this.onArchive, required this.child});
  final Key swipeKey;
  final Future<void> Function() onDelete;
  final Future<void> Function() onArchive;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget bg(Color c, IconData i, String t, Alignment a) => Container(
          color: c,
          alignment: a,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(i, color: cs.onPrimary),
            Text(t, style: TextStyle(color: cs.onPrimary, fontSize: 12)),
          ]),
        );
    return Dismissible(
      key: swipeKey,
      background: bg(cs.error, Icons.delete_outline, 'Delete', Alignment.centerLeft),
      secondaryBackground: bg(cs.primary, Icons.archive_outlined, 'Archive', Alignment.centerRight),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          await onDelete();
        } else {
          await onArchive();
        }
        return false;
      },
      child: child,
    );
  }
}
