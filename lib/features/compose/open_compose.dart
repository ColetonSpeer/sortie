import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../platform/desktop/compose_window.dart';
import '../../platform/device_info.dart';
import '../../router/app_router.dart';

/// Mirrors `kDemo` in main.dart: the demo has no services for a second window.
const bool _demo = bool.fromEnvironment('SORTIE_DEMO');

/// Opens the composer: in a window of its own on desktop, as a route on
/// phones (or when no window could be created).
Future<void> openCompose(
  BuildContext context,
  WidgetRef ref, {
  required String accountId,
  String? folder,
  int? reply,
  int? replyAll,
  int? forward,
  int? draft,
  bool blabber = false,
}) async {
  if (isDesktop && !_demo) {
    final opened = await openComposeWindow(ComposeWindowArgs(
      accountId: accountId,
      replyUid: reply,
      replyAllUid: replyAll,
      forwardUid: forward,
      draftUid: draft,
      sourceFolder: folder,
      startBlabber: blabber,
    ));
    if (opened) return;
  }
  if (!context.mounted) return;
  context.push(Routes.composeWith(
    accountId: accountId,
    folder: folder,
    reply: reply?.toString(),
    replyAll: replyAll?.toString(),
    forward: forward?.toString(),
    draft: draft?.toString(),
    blabber: blabber,
  ));
}
