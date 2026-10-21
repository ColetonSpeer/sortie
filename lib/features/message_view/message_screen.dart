import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';
import '../../router/app_router.dart';
import '../../services/calendar/invitations.dart';
import '../compose/open_compose.dart';
import '../mailbox/message_actions.dart';
import '../mailbox/threading.dart';
import 'html_body.dart';
import 'invitation_card.dart';
import 'message_header_view.dart';
import 'open_in_browser.dart';

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

  /// Per-screen view choices; null = follow [DeviceSettings.htmlMailMode].
  bool? _plainText;
  bool _originalFormatting = false;
  Object? _error;
  List<MessageHeader>? _threadSrc;
  List<MessageThread> _threads = const [];

  /// Cached so dispose() can release the hold without touching `ref`.
  late final SortCoordinator _coord = ref.read(sortCoordinatorProvider(widget.accountId));

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
        _body = loadBodyWithCalendar(ref.read(mailSyncServiceProvider), h);
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _coord; // resolve while the element is still mounted
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
    final plainText = _plainText ?? (settings.htmlMailMode == 'plainText');
    final bodyMode = plainText
        ? BodyViewMode.plainText
        : _originalFormatting
            ? BodyViewMode.original
            : BodyViewMode.html;
    final h = _header;
    final actions = MessageActions(context, ref);
    final thread = h == null || !settings.threadedView ? null : _threadOf(h);

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
                if (h.flags.contains(r'\Draft'))
                  IconButton(tooltip: 'Edit draft', icon: const Icon(Icons.edit_outlined), onPressed: () => _compose(draft: h)),
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
                    if (v == 'plain') setState(() => _plainText = !plainText);
                    if (v == 'original') setState(() => _originalFormatting = !_originalFormatting);
                    if (v == 'browser') _openInBrowser(h, allowRemote);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'unread', child: Text('Mark unread')),
                    const PopupMenuItem(value: 'archive', child: Text('Archive')),
                    const PopupMenuDivider(),
                    CheckedPopupMenuItem(value: 'plain', checked: plainText, child: const Text('View as plain text')),
                    CheckedPopupMenuItem(
                      value: 'original',
                      checked: _originalFormatting,
                      enabled: !plainText,
                      child: const Text('Original formatting'),
                    ),
                    const PopupMenuItem(value: 'browser', child: Text('Open in browser')),
                  ],
                ),
              ],
      ),
      body: _error != null
          ? Center(child: Text('$_error'))
          : h == null
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  if (thread != null && !thread.isSingle)
                    _ConversationBar(
                      thread: thread,
                      current: h,
                      onOpen: (m) => context.go(Routes.message(widget.accountId, widget.folderPath, m.uid)),
                    ),
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
                            final body = snap.data!;
                            final invitation = body.calendar == null ? null : MeetingInvitation.parse(body.calendar!);
                            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              if (invitation != null) InvitationCard(header: h, invitation: invitation),
                              MessageBodyView(
                                body: body,
                                allowRemoteImages: allowRemote,
                                mode: bodyMode,
                                onRemoteImagesBlocked: (n) {
                                  if (mounted && n != _blockedImages) setState(() => _blockedImages = n);
                                },
                              ),
                            ]);
                          },
                        ),
                      ]),
                    ),
                  ),
                ]),
    );
  }

  /// The conversation [h] belongs to within the folder this screen was opened
  /// from (the same grouping the list pane shows).
  MessageThread? _threadOf(MessageHeader h) {
    final list = ref
        .watch(messagesProvider((accountId: widget.accountId, folderPath: widget.folderPath, search: '')))
        .asData
        ?.value;
    if (list == null || list.length < 2) return null;
    if (!identical(list, _threadSrc)) {
      final account = ref.watch(accountsProvider).asData?.value.where((a) => a.id == widget.accountId).firstOrNull;
      _threadSrc = list;
      _threads = buildThreads(list, ownAddresses: {if (account != null) account.email.toLowerCase()});
    }
    return _threads.where((t) => t.contains(h)).firstOrNull;
  }

  Future<void> _openInBrowser(MessageHeader h, bool allowRemote) async {
    final future = _body;
    if (future == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final body = await future;
      final error = await openMessageInBrowser(body, allowRemoteImages: allowRemote, title: h.subject);
      if (error != null) messenger?.showSnackBar(SnackBar(content: Text(error)));
    } catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text('Could not open in browser: $e')));
    }
  }

  void _compose({MessageHeader? reply, MessageHeader? replyAll, MessageHeader? forward, MessageHeader? draft}) {
    final src = reply ?? replyAll ?? forward ?? draft!;
    openCompose(
      context,
      ref,
      accountId: widget.accountId,
      folder: src.folderPath,
      reply: reply?.uid,
      replyAll: replyAll?.uid,
      forward: forward?.uid,
      draft: draft?.uid,
    );
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

/// "3 messages in this conversation" with older/newer navigation.
class _ConversationBar extends StatelessWidget {
  const _ConversationBar({required this.thread, required this.current, required this.onOpen});
  final MessageThread thread;
  final MessageHeader current;
  final void Function(MessageHeader) onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final msgs = thread.messages;
    final i = msgs.indexWhere((m) => m.messageIdHash == current.messageIdHash);
    final older = i > 0 ? msgs[i - 1] : null;
    final newer = i >= 0 && i < msgs.length - 1 ? msgs[i + 1] : null;
    return Material(
      color: cs.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Row(children: [
          Icon(Icons.forum_outlined, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${msgs.length} messages in this conversation${i >= 0 ? ' · ${i + 1} of ${msgs.length}' : ''}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Older message',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.expand_less),
            onPressed: older == null ? null : () => onOpen(older),
          ),
          IconButton(
            tooltip: 'Newer message',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.expand_more),
            onPressed: newer == null ? null : () => onOpen(newer),
          ),
        ]),
      ),
    );
  }
}

/// Loads the body and, for mail cached before invitation support (or
/// invitations that only come as an attachment), pulls the `.ics` part so
/// the invitation card can show.
Future<MessageBody> loadBodyWithCalendar(MailSyncService sync, MessageHeader h) async {
  final body = await sync.body(h.accountId, h.folderPath, h.uid);
  if (body.calendar != null) return body;
  final seen = <String>{};
  for (final a in [...body.attachments, ...h.attachments]) {
    if (!seen.add(a.partId)) continue;
    final mt = a.mimeType.toLowerCase();
    final isCal = mt.startsWith('text/calendar') || mt == 'application/ics' || a.fileName.toLowerCase().endsWith('.ics');
    if (!isCal) continue;
    try {
      final bytes = await sync.attachment(h.accountId, h.folderPath, h.uid, a.partId);
      var text = utf8.decode(bytes, allowMalformed: true);
      if (!text.contains('BEGIN:VCALENDAR')) {
        // Transfer encoding not applied by the server path: try base64.
        try {
          text = utf8.decode(base64Decode(text.replaceAll(RegExp(r'\s'), '')), allowMalformed: true);
        } catch (_) {}
      }
      if (text.contains('BEGIN:VCALENDAR')) {
        _log.info('invitation part ${a.partId} of ${h.folderPath}/${h.uid} loaded (${bytes.length} bytes)');
        return MessageBody(text: body.text, html: body.html, inlineParts: body.inlineParts, attachments: body.attachments, calendar: text);
      }
      _log.info('attachment ${a.partId} of ${h.folderPath}/${h.uid} is not an iCalendar object (${bytes.length} bytes)');
    } catch (e) {
      _log.warning('could not load invitation part ${a.partId} of ${h.folderPath}/${h.uid}: $e');
    }
  }
  return body;
}

final _log = Logger('invitations.ui');
