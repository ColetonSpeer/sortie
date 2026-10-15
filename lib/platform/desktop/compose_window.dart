import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:multiview_desktop/multiview_desktop.dart';

import '../../features/compose/compose_screen.dart';

final _log = Logger('compose.window');

/// What a compose window is opened with.
class ComposeWindowArgs {
  const ComposeWindowArgs({
    required this.accountId,
    this.replyUid,
    this.replyAllUid,
    this.forwardUid,
    this.draftUid,
    this.sourceFolder,
  });
  final String accountId;
  final int? replyUid;
  final int? replyAllUid;
  final int? forwardUid;
  final int? draftUid;
  final String? sourceFolder;

  String get title => draftUid != null
      ? 'Edit draft'
      : forwardUid != null
          ? 'Forward'
          : (replyUid ?? replyAllUid) != null
              ? 'Reply'
              : 'New message';
}

/// Opens the composer in an OS window of its own (same engine and isolate:
/// the window is just another view over the app's providers). False when
/// the platform could not create one; the caller then uses the in-app route.
Future<bool> openComposeWindow(ComposeWindowArgs a) async {
  try {
    final id = await openWindow(
      (_, _) => ComposeWindow(args: a),
      options: WindowOptions(
        title: a.title,
        size: const Size(960, 760),
        minimumSize: const Size(640, 480),
        alignment: Alignment.center,
      ),
    );
    _log.fine('opened compose window $id');
    return true;
  } catch (e, s) {
    _log.warning('compose window unavailable, using the in-app composer: $e', e, s);
    return false;
  }
}

/// Root of a compose window: routes the native close button through the
/// composer's save/discard prompt.
class ComposeWindow extends StatefulWidget {
  const ComposeWindow({super.key, required this.args});
  final ComposeWindowArgs args;

  @override
  State<ComposeWindow> createState() => _ComposeWindowState();
}

class _ComposeWindowState extends State<ComposeWindow> with WindowListener {
  final _screen = GlobalKey<ComposeScreenState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) MultiViewDesktop.of(context).setPreventClose(true);
    });
  }

  /// Native close button: same prompt as the in-app Close button.
  @override
  Future<bool> onWindowClose() async {
    final state = _screen.currentState;
    if (state == null) {
      _closeNow();
      return true;
    }
    return state.requestClose();
  }

  void _closeNow() {
    if (!mounted) return;
    final win = MultiViewDesktop.of(context);
    win.setPreventClose(false);
    unawaited(win.closeWindow());
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.args;
    return ComposeScreen(
      key: _screen,
      accountId: a.accountId,
      replyUid: a.replyUid,
      replyAllUid: a.replyAllUid,
      forwardUid: a.forwardUid,
      draftUid: a.draftUid,
      sourceFolder: a.sourceFolder,
      onClose: _closeNow,
    );
  }
}
