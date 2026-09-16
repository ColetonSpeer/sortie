import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';
import '../../router/app_router.dart';
import '../mailbox/message_actions.dart';
import 'html_body.dart';
import 'message_header_view.dart';

/// Reads one message. Holds the read-guard while open (and while the app is
/// foregrounded), follows the message if the sorter moves it, and offers Undo.
class MessageScreen extends ConsumerStatefulWidget {
  const MessageScreen({
    super.key,
    required this.accountId,
    required this.folderPath,
    required this.uid,
    required this.standalone,
  });
  final String accountId;
  final String folderPath;
  final int uid;

  /// True on narrow layouts where this screen is its own page.
  final bool standalone;

  @override
  ConsumerState<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends ConsumerState<MessageScreen> with WidgetsBindingObserver {
  MessageHeader? _header;
  MessageKey? _key;
  Future<MessageBody>? _body;
  String? _lastFolder;
  PendingBadge? _lastBadge;
  bool _holding = false;
  bool _loadRemoteOnce = false;
  int _blockedImages = 0;
  Object? _error;

  SortCoordinator get _coord => ref.read(sortCoordinatorProvider(widget.accountId));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    try {
      final h = await ref.read(messageRepositoryProvider).byUid(widget.accountId, widget.folderPath, widget.uid);
      if (!mounted) return;
      if (h == null) {
        setState(() => _error = 'Message not found');
        return;
      }
      setState(() {
        _header = h;
        _key = h.key;
        _lastFolder = h.folderPath;
        _body = ref.read(mailSyncServiceProvider).body(h.accountId, h.folderPath, h.uid);
      });
      _hold();
      if (!h.isSeen) {
        await ref.read(mailSyncServiceProvider).markSeen(h.accountId, h.folderPath, h.uid);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _hold() {
    if (_holding || _key == null) return;
    _holding = true;
    _coord.onMessageOpened(_key!);
  }

  void _release() {
    if (!_holding || _key == null) return;
    _holding = false;
    _coord.onMessageClosed(_key!);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _hold();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden || state == AppLifecycleState.detached) {
      _release();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _release();
    super.dispose();
  }

  void _onMoved(MessageHeader moved) {
    final decisionId = _lastBadge?.decisionId ??
        ref
            .read(sortLogProvider(widget.accountId))
            .asData
            ?.value
            .where((e) => e.type == 'moved' && e.key == moved.key && e.undoable)
            .firstOrNull
            ?.decisionId;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      content: Text('Moved to ${moved.folderPath}'),
      duration: const Duration(seconds: 8),
      action: decisionId == null
          ? null
          : SnackBarAction(label: 'Undo', onPressed: () => MessageActions(context, ref).undo(widget.accountId, decisionId)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final key = _key;
    if (key != null) {
      // Follow the message across moves without leaving the screen.
      ref.listen(messageByHashProvider(key), (_, next) {
        final h = next.asData?.value;
        if (h == null) return;
        if (_lastFolder != null && h.folderPath != _lastFolder) _onMoved(h);
        _lastFolder = h.folderPath;
        if (mounted) setState(() => _header = h);
      });
    }
    final badges = ref.watch(pendingBadgesProvider(widget.accountId)).asData?.value;
    final badge = key == null ? null : badges?[key];
    if (badge != null) _lastBadge = badge;
    final settings = ref.watch(deviceSettingsProvider).asData?.value ?? const DeviceSettings();
    final allowRemote = settings.loadRemoteImages || _loadRemoteOnce;
    final h = _header;
    final actions = MessageActions(context, ref);

    return Scaffold(
      appBar: AppBar(
        leading: widget.standalone
            ? BackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.mailbox(widget.accountId, widget.folderPath)))
            : null,
        automaticallyImplyLeading: false,
        title: h == null ? const SizedBox.shrink() : Text(h.folderPath, style: Theme.of(context).textTheme.titleSmall),
        actions: h == null
            ? const []
            : [
                IconButton(tooltip: 'Reply', icon: const Icon(Icons.reply), onPressed: () => _compose(reply: h)),
                IconButton(tooltip: 'Reply all', icon: const Icon(Icons.reply_all), onPressed: () => _compose(replyAll: h)),
                IconButton(tooltip: 'Forward', icon: const Icon(Icons.forward), onPressed: () => _compose(forward: h)),
                IconButton(
                  tooltip: h.isFlagged ? 'Unflag' : 'Flag',
                  icon: Icon(h.isFlagged ? Icons.star : Icons.star_outline),
                  onPressed: () => actions.toggleFlag(h),
                ),
                IconButton(tooltip: 'Move to…', icon: const Icon(Icons.drive_file_move_outline), onPressed: () => actions.movePrompt([h])),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await actions.delete([h]);
                    if (context.mounted && widget.standalone) context.go(Routes.mailbox(widget.accountId, widget.folderPath));
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'unread') actions.markRead([h], read: false);
                    if (v == 'archive') actions.archive([h]);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'unread', child: Text('Mark unread')),
                    PopupMenuItem(value: 'archive', child: Text('Archive')),
                  ],
                ),
              ],
      ),
      body: _error != null
          ? Center(child: Text('$_error'))
          : h == null
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  if (badge != null) _PendingBanner(badge: badge, onMoveNow: () => actions.badgeMoveNow(key!), onKeep: () => actions.badgeKeep(key!)),
                  if (_blockedImages > 0 && !allowRemote)
                    MaterialBanner(
                      leading: const Icon(Icons.image_not_supported_outlined),
                      content: Text('$_blockedImages remote image${_blockedImages == 1 ? '' : 's'} blocked to protect your privacy.'),
                      actions: [
                        TextButton(onPressed: () => setState(() => _loadRemoteOnce = true), child: const Text('Load remote images')),
                      ],
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        MessageHeaderView(header: h),
                        const Divider(height: 32),
                        FutureBuilder<MessageBody>(
                          future: _body,
                          builder: (context, snap) {
                            if (snap.hasError) return Text('Could not load body: ${snap.error}');
                            if (!snap.hasData) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
                            return MessageBodyView(
                              body: snap.data!,
                              allowRemoteImages: allowRemote,
                              onRemoteImagesBlocked: (n) {
                                if (mounted && n != _blockedImages) setState(() => _blockedImages = n);
                              },
                            );
                          },
                        ),
                      ]),
                    ),
                  ),
                ]),
    );
  }

  void _compose({MessageHeader? reply, MessageHeader? replyAll, MessageHeader? forward}) {
    final src = reply ?? replyAll ?? forward!;
    context.push(Routes.composeWith(
      accountId: widget.accountId,
      folder: src.folderPath,
      reply: reply?.uid.toString(),
      replyAll: replyAll?.uid.toString(),
      forward: forward?.uid.toString(),
    ));
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.badge, required this.onMoveNow, required this.onKeep});
  final PendingBadge badge;
  final VoidCallback onMoveNow;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    final text = switch (badge.mode) {
      SortMode.suggestOnly => 'Suggested folder: ${badge.destination}',
      SortMode.moveNow => 'Will move to ${badge.destination} shortly',
      _ => 'Will move to ${badge.destination} after you finish reading',
    };
    return MaterialBanner(
      leading: const Icon(Icons.auto_awesome_outlined),
      content: Text(text),
      actions: [
        TextButton(onPressed: onMoveNow, child: const Text('Move now')),
        TextButton(onPressed: onKeep, child: const Text('Keep here')),
      ],
    );
  }
}
