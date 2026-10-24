import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import '../../app/compose_models.dart';
import '../../app/providers.dart' show speechInputProvider;
import '../../domain/entities/entities.dart';
import '../../services/compose/blabber_composer.dart';
import '../../services/compose/draft_reviewer.dart';
import '../../services/compose/message_composer.dart' show MessageComposer;
import 'blabber_sheet.dart';
import 'compose_backend.dart';
import 'conversation_context.dart';
import 'quote.dart';
import 'recipient_field.dart';
import 'review_sheet.dart';

/// New message / reply / reply-all / forward / edit-draft.
///
/// Drafts autosave: [autosaveDelay] after the first unsaved change the
/// message is stored in Drafts, replacing the previous autosaved copy, so
/// closing the window (or a crash) never loses more than that much typing.
/// Sending removes the autosaved draft once the mail is out.
class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({
    super.key,
    required this.accountId,
    this.replyUid,
    this.replyAllUid,
    this.forwardUid,
    this.draftUid,
    this.sourceFolder,
    this.onClose,
    this.startBlabber = false,
  });
  final String accountId;
  final int? replyUid;
  final int? replyAllUid;
  final int? forwardUid;
  final int? draftUid;
  final String? sourceFolder;

  /// Set when the screen owns a window of its own: called to close it
  /// instead of popping a route.
  final VoidCallback? onClose;

  /// Opens Blabber (dictate the email) as soon as the composer is ready.
  final bool startBlabber;

  static const autosaveDelay = Duration(seconds: 20);

  @override
  ConsumerState<ComposeScreen> createState() => ComposeScreenState();
}

class ComposeScreenState extends ConsumerState<ComposeScreen> with WidgetsBindingObserver {
  static final _log = Logger('compose');
  final _subject = TextEditingController();
  final _body = TextEditingController();
  List<MailAddress> _to = [];
  List<MailAddress> _cc = [];
  List<MailAddress> _bcc = [];
  bool _showCcBcc = false;
  Identity? _identity;
  List<Identity> _identities = const [];
  List<MailAddress> _suggestions = const [];
  MessageHeader? _source;
  final _attachments = <ComposeAttachment>[];
  bool _ready = false;
  bool _busy = false;
  bool _allowPop = false;
  bool _blabberOpened = false;
  String? _error;

  // Draft autosave state.
  Timer? _autosaveTimer;
  String _initialSnapshot = '';
  String _savedSnapshot = '';
  String? _draftMessageId;
  DateTime? _savedAt;
  bool _saving = false;

  ComposeBackend get _backend => ref.read(composeBackendProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subject.addListener(_touch);
    _body.addListener(_touch);
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      _identities = await _backend.identities(widget.accountId);
      final srcUid = widget.replyUid ?? widget.replyAllUid ?? widget.forwardUid ?? widget.draftUid;
      if (srcUid != null && widget.sourceFolder != null) {
        _source = await _backend.message(widget.accountId, widget.sourceFolder!, srcUid);
      }
      final src = _source;
      _identity = Quote.pickIdentity(_identities, src);
      if (src != null) {
        final body = await _backend.body(src.accountId, src.folderPath, src.uid);
        if (widget.draftUid != null) {
          _to = List.of(src.to);
          _cc = List.of(src.cc);
          _showCcBcc = _cc.isNotEmpty;
          _subject.text = src.subject;
          _body.text = body.text;
          _draftMessageId = src.messageId;
        } else if (widget.forwardUid != null) {
          _subject.text = Quote.forwardSubject(src.subject);
          _body.text = _sig() + Quote.forward(src, body.text);
          await _carryAttachments(src, body);
        } else {
          final (to, cc) = Quote.replyRecipients(src, _identities, all: widget.replyAllUid != null);
          _to = to;
          _cc = cc;
          _showCcBcc = cc.isNotEmpty;
          _subject.text = Quote.replySubject(src.subject);
          _body.text = _sig() + Quote.reply(src, body.text);
        }
      } else {
        _body.text = _sig();
      }
      // Cursor at the top: the user types above the signature and any quote.
      _body.selection = const TextSelection.collapsed(offset: 0);
      try {
        _suggestions = await _backend.recentAddresses(widget.accountId);
      } catch (e) {
        _log.fine('recent addresses unavailable: $e');
      }
    } catch (e) {
      _error = e.toString();
    }
    _initialSnapshot = _savedSnapshot = _snapshot();
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    if (mounted) setState(() => _ready = true);
    if (widget.startBlabber && !_blabberOpened && mounted) {
      _blabberOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_blabber());
      });
    }
  }

  /// Forwarding carries the original's files along. Inline images already
  /// travel inside the quoted HTML-less body text as nothing, so only real
  /// attachments are fetched; one that cannot be fetched is reported, not
  /// silently dropped.
  Future<void> _carryAttachments(MessageHeader src, MessageBody body) async {
    final seen = <String>{};
    final failed = <String>[];
    for (final a in [...body.attachments, ...src.attachments]) {
      if (!seen.add(a.partId)) continue;
      try {
        final bytes = await _backend.attachment(src.accountId, src.folderPath, src.uid, a.partId);
        if (bytes.isEmpty) {
          failed.add(a.fileName);
          continue;
        }
        _attachments.add(ComposeAttachment(fileName: a.fileName, mimeType: a.mimeType, bytes: bytes));
      } catch (e) {
        _log.warning('could not fetch ${a.fileName} to forward it: $e');
        failed.add(a.fileName);
      }
    }
    if (failed.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not attach ${failed.join(', ')}. Attach the file again before sending.')));
    }
  }

  /// Signature block for the body, with the standard `-- ` separator unless
  /// the stored signature already carries one.
  String _sig() {
    final s = _identity?.signature ?? '';
    if (s.trim().isEmpty) return '';
    return s.startsWith('-- ') ? '\n\n$s' : '\n\n-- \n$s';
  }

  List<MailAddress> _list(RecipientKind k) => switch (k) { RecipientKind.to => _to, RecipientKind.cc => _cc, RecipientKind.bcc => _bcc };

  void _setList(RecipientKind k, List<MailAddress> v) {
    switch (k) {
      case RecipientKind.to:
        _to = v;
      case RecipientKind.cc:
        _cc = v;
      case RecipientKind.bcc:
        _bcc = v;
    }
    _touch();
  }

  Widget _recipients(RecipientKind k, {bool autofocus = false}) => RecipientField(
        key: ValueKey('recipients-${k.label}'),
        kind: k,
        value: _list(k),
        onChanged: (v) => setState(() => _setList(k, v)),
        onMove: (a, to) => _move(a, k, to),
        suggestions: _suggestions,
        autofocus: autofocus,
      );

  /// Moves [a] from the [from] line to the [to] line (chip context menu).
  void _move(MailAddress a, RecipientKind from, RecipientKind to) {
    if (from == to) return;
    setState(() {
      _setList(from, _list(from).where((v) => v != a).toList());
      final target = _list(to);
      if (!target.any((v) => v.email.toLowerCase() == a.email.toLowerCase())) _setList(to, [...target, a]);
      if (to != RecipientKind.to) _showCcBcc = true;
    });
  }

  void _switchIdentity(Identity? next) {
    if (next == null || next == _identity) return;
    final oldSig = _identity?.signature ?? '';
    if (oldSig.isNotEmpty && _body.text.contains(oldSig)) {
      _body.text = _body.text.replaceFirst(oldSig, next.signature);
    }
    setState(() => _identity = next);
    _touch();
  }

  // ------------------------------------------------------------ drafts

  /// Everything that goes into the draft, as one comparable string.
  String _snapshot() => [
        _identity?.id ?? '',
        _to.join(','),
        _cc.join(','),
        _bcc.join(','),
        _subject.text,
        _body.text,
        _attachments.map((a) => '${a.fileName}:${a.size}').join(','),
      ].join('\x1f');

  bool get _dirty => _snapshot() != _savedSnapshot;

  /// False while the message is still exactly what the screen opened with
  /// (an untouched new message is never saved).
  bool get _hasContent => _snapshot() != _initialSnapshot;

  /// Called on every edit: arms the autosave timer once per unsaved stretch.
  /// Sends what the user wrote (not the signature or the quote) to the AI
  /// backend and swaps in the revision if they accept it.
  Future<void> _review() async {
    final reason = await _backend.reviewUnavailableReason();
    if (!mounted) return;
    if (reason != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
      return;
    }
    final parts = splitOwnText(_body.text, signature: _sig());
    if (parts.own.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write something first.')));
      return;
    }
    final src = widget.draftUid == null ? _source : null;
    final outcome = await showReviewSheet(
      context,
      currentSubject: _subject.text,
      run: (instruction, depth, history) async {
        final conversation = src == null ? const <ConversationTurn>[] : await gatherConversation(_backend, src);
        return _backend.reviewDraft(DraftReviewRequest(
          subject: _subject.text,
          body: parts.own,
          recipients: [for (final a in [..._to, ..._cc]) a.toString()],
          instruction: instruction,
          senderName: _identity?.name ?? '',
          senderContext: _identity?.signature ?? '',
          conversation: conversation,
          depth: depth,
          history: history,
          now: DateTime.now(),
        ));
      },
    );
    if (outcome == null || !mounted) return;
    // Re-split: the tail may have changed while the dialog was open.
    final now = splitOwnText(_body.text, signature: _sig());
    final body = outcome.body.trimRight();
    _body.value = TextEditingValue(text: '$body${now.tail}', selection: TextSelection.collapsed(offset: body.length));
    if (outcome.subject != null) _subject.text = outcome.subject!;
    _touch();
    setState(() {});
  }

  /// Blabber: dictated (or typed) thoughts become the email text. Replies
  /// hand the thread along; whatever the user already wrote is treated as
  /// the draft the transcript changes. The signature and the quote stay.
  Future<void> _blabber() async {
    final reason = await _backend.blabberUnavailableReason();
    if (!mounted) return;
    if (reason != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
      return;
    }
    final parts = splitOwnText(_body.text, signature: _sig());
    final src = widget.draftUid == null && widget.forwardUid == null ? _source : null;
    final outcome = await showBlabberSheet(
      context,
      speech: ref.read(speechInputProvider),
      currentSubject: _subject.text,
      isReply: src != null,
      hasOwnText: parts.own.trim().isNotEmpty,
      run: (transcript, instruction) async {
        final conversation = src == null ? const <ConversationTurn>[] : await gatherConversation(_backend, src);
        return _backend.blabber(BlabberRequest(
          transcript: transcript,
          instruction: instruction,
          senderName: _identity?.name ?? '',
          recipients: [for (final a in [..._to, ..._cc]) a.toString()],
          currentSubject: _subject.text,
          existingText: splitOwnText(_body.text, signature: _sig()).own,
          conversation: conversation,
          isReply: src != null,
          now: DateTime.now(),
        ));
      },
    );
    if (outcome == null || !mounted) return;
    final now = splitOwnText(_body.text, signature: _sig());
    final body = outcome.body.trimRight();
    _body.value = TextEditingValue(text: '$body${now.tail}', selection: TextSelection.collapsed(offset: body.length));
    if (outcome.applySubject && outcome.subject.trim().isNotEmpty) _subject.text = outcome.subject.trim();
    _touch();
    setState(() {});
  }

  void _touch() {
    if (!_ready || _autosaveTimer != null) return;
    _autosaveTimer = Timer(ComposeScreen.autosaveDelay, _autosave);
  }

  Future<void> _autosave() async {
    _autosaveTimer = null;
    if (!mounted || _busy || _saving || !_dirty || !_hasContent || _identity == null) return;
    await _persistDraft();
  }

  /// Stores the current content in Drafts, replacing the previous copy.
  Future<bool> _persistDraft() async {
    if (_identity == null) return false;
    _saving = true;
    final snap = _snapshot();
    try {
      final raw = await _backend.compose(_draft());
      final mid = MessageComposer.messageIdOf(raw);
      await _backend.saveDraft(widget.accountId, raw, supersedesMessageId: _draftMessageId);
      _draftMessageId = mid ?? _draftMessageId;
      _savedSnapshot = snap;
      if (mounted) setState(() => _savedAt = DateTime.now());
      return true;
    } catch (e) {
      _log.warning('draft save failed: $e');
      if (mounted) _snack('Could not save draft: $e');
      return false;
    } finally {
      _saving = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) unawaited(_autosave());
  }

  ComposeDraft _draft() {
    final src = widget.draftUid == null ? _source : null;
    return ComposeDraft(
      accountId: widget.accountId,
      identity: _identity!,
      to: _to,
      cc: _cc,
      bcc: _bcc,
      subject: _subject.text.trim(),
      bodyText: _body.text,
      inReplyTo: widget.forwardUid == null ? src?.messageId : null,
      references: widget.forwardUid == null && src != null ? [...src.references, if (src.messageId != null) src.messageId!] : const [],
      attachments: _attachments,
      draftUid: widget.draftUid,
    );
  }

  // ------------------------------------------------------------ actions

  Future<void> _send() async {
    if (_identity == null) return _snack('Pick an identity first.');
    if (_to.isEmpty && _cc.isEmpty && _bcc.isEmpty) return _snack('Add at least one recipient.');
    if (_subject.text.trim().isEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Send without a subject?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
          ],
        ),
      );
      if (ok != true) return;
    }
    await _run(() async {
      final draft = _draft();
      final raw = await _backend.compose(draft);
      await _backend.send(widget.accountId, draft.identity.id, draft.allRecipients, raw, draftMessageId: _draftMessageId);
      _savedSnapshot = _snapshot();
    }, done: 'Sent');
  }

  Future<void> _saveDraft() async {
    if (_identity == null) return;
    setState(() => _busy = true);
    try {
      if (await _persistDraft()) {
        _snack('Draft saved');
        await _close();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _run(Future<void> Function() f, {required String done}) async {
    setState(() => _busy = true);
    try {
      await f();
      if (!mounted) return;
      _snack(done);
      await _close();
    } catch (e) {
      _snack('Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Leaves the screen: closes the window or pops the route.
  Future<void> _close() async {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    if (!mounted || !context.canPop()) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) context.pop();
  }

  /// Close requested by the user (Close button, back gesture or the window's
  /// own close button): offers to keep unsaved changes. True once the screen
  /// is closing, false when the user cancelled.
  Future<bool> requestClose() async {
    if (_busy) return false;
    if (!_dirty || !_hasContent) {
      await _close();
      return true;
    }
    final editingDraft = widget.draftUid != null;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save as draft?'),
        content: Text(editingDraft ? 'Keep your changes to this draft?' : 'This message has not been sent.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'discard'), child: Text(editingDraft ? 'Discard changes' : 'Discard')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'save'), child: const Text('Save')),
        ],
      ),
    );
    if (!mounted) return false;
    switch (choice) {
      case 'save':
        if (!await _persistDraft()) return false;
        await _close();
        return true;
      case 'discard':
        // A new message that was autosaved leaves no draft behind; edits to an
        // existing draft keep whatever was last saved.
        if (!editingDraft && _draftMessageId != null) {
          try {
            await _backend.discardDraft(widget.accountId, _draftMessageId!);
          } catch (e) {
            _log.warning('discard failed: $e');
          }
        }
        _savedSnapshot = _snapshot();
        await _close();
        return true;
      default:
        return false;
    }
  }

  void _snack(String s) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(s)));

  Future<void> _attach() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty) return;
    final picked = <ComposeAttachment>[];
    for (final f in files) {
      try {
        final bytes = await f.readAsBytes();
        picked.add(ComposeAttachment(fileName: f.name, mimeType: _mime(f.name), bytes: bytes));
      } catch (e) {
        _snack('Could not read ${f.name}: $e');
      }
    }
    if (!mounted) return;
    setState(() => _attachments.addAll(picked));
    _touch();
  }

  static String _mime(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return const {
      'pdf': 'application/pdf', 'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'gif': 'image/gif',
      'txt': 'text/plain', 'csv': 'text/csv', 'zip': 'application/zip', 'json': 'application/json',
      'doc': 'application/msword', 'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel', 'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    }[ext] ?? 'application/octet-stream';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autosaveTimer?.cancel();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.draftUid != null ? 'Edit draft' : widget.forwardUid != null ? 'Forward' : (widget.replyUid ?? widget.replyAllUid) != null ? 'Reply' : 'New message';
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(requestClose());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: _busy ? null : requestClose),
          title: Text(title),
          actions: [
            if (_savedAt != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text('Draft saved ${DateFormat.jm().format(_savedAt!)}',
                    key: const Key('draftSavedAt'), style: Theme.of(context).textTheme.labelSmall),
              ),
            IconButton(key: const Key('blabber'), tooltip: 'Blabber: talk, get an email', icon: const Icon(Icons.mic_none_outlined), onPressed: _busy || !_ready ? null : _blabber),
            IconButton(key: const Key('reviewDraft'), tooltip: 'Review with AI', icon: const Icon(Icons.auto_fix_high_outlined), onPressed: _busy || !_ready ? null : _review),
            IconButton(tooltip: 'Attach file', icon: const Icon(Icons.attach_file), onPressed: _busy ? null : _attach),
            IconButton(tooltip: 'Save draft', icon: const Icon(Icons.save_outlined), onPressed: _busy || !_ready ? null : _saveDraft),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FilledButton.icon(
                onPressed: _busy || !_ready ? null : _send,
                icon: _busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                label: const Text('Send'),
              ),
            ),
          ],
        ),
        body: !_ready
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(children: [
                    if (_error != null) MaterialBanner(content: Text(_error!), actions: const [SizedBox.shrink()]),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Row(children: [
                          SizedBox(width: 44, child: Text('From', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
                          Expanded(
                            child: DropdownButton<Identity>(
                              key: const Key('identityPicker'),
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              value: _identity,
                              items: [for (final i in _identities) DropdownMenuItem(value: i, child: Text('${i.name} <${i.email}>', overflow: TextOverflow.ellipsis))],
                              onChanged: _switchIdentity,
                            ),
                          ),
                          if (!_showCcBcc) TextButton(onPressed: () => setState(() => _showCcBcc = true), child: const Text('Cc/Bcc')),
                        ]),
                        _recipients(RecipientKind.to, autofocus: _source == null),
                        if (_showCcBcc) ...[
                          _recipients(RecipientKind.cc),
                          _recipients(RecipientKind.bcc),
                        ],
                        TextField(
                          key: const Key('composeSubject'),
                          controller: _subject,
                          decoration: const InputDecoration(hintText: 'Subject', border: InputBorder.none),
                          style: Theme.of(context).textTheme.titleMedium,
                          textInputAction: TextInputAction.next,
                        ),
                        const Divider(height: 1),
                      ]),
                    ),
                    if (_attachments.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Wrap(spacing: 8, runSpacing: 4, children: [
                          for (final a in _attachments)
                            InputChip(
                              avatar: const Icon(Icons.attach_file, size: 16),
                              label: Text(a.fileName),
                              onDeleted: () {
                                setState(() => _attachments.remove(a));
                                _touch();
                              },
                            ),
                        ]),
                      ),
                    Expanded(
                      child: TextField(
                        key: const Key('composeBody'),
                        controller: _body,
                        autofocus: _source != null,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.all(16), border: InputBorder.none, hintText: 'Write your message'),
                      ),
                    ),
                  ]),
                ),
              ),
      ),
    );
  }
}
