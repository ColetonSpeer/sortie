import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/compose_models.dart';
import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import 'quote.dart';
import 'recipient_field.dart';

/// New message / reply / reply-all / forward / edit-draft.
class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({
    super.key,
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

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  List<MailAddress> _to = [];
  List<MailAddress> _cc = [];
  List<MailAddress> _bcc = [];
  bool _showCcBcc = false;
  Identity? _identity;
  List<Identity> _identities = const [];
  MessageHeader? _source;
  final _attachments = <ComposeAttachment>[];
  bool _ready = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final accounts = ref.read(accountRepositoryProvider);
      _identities = await accounts.identities(widget.accountId);
      final srcUid = widget.replyUid ?? widget.replyAllUid ?? widget.forwardUid ?? widget.draftUid;
      if (srcUid != null && widget.sourceFolder != null) {
        _source = await ref.read(messageRepositoryProvider).byUid(widget.accountId, widget.sourceFolder!, srcUid);
      }
      final src = _source;
      _identity = Quote.pickIdentity(_identities, src);
      if (src != null) {
        final body = await ref.read(mailSyncServiceProvider).body(src.accountId, src.folderPath, src.uid);
        if (widget.draftUid != null) {
          _to = List.of(src.to);
          _cc = List.of(src.cc);
          _subject.text = src.subject;
          _body.text = body.text;
        } else if (widget.forwardUid != null) {
          _subject.text = Quote.forwardSubject(src.subject);
          _body.text = _sig() + Quote.forward(src, body.text);
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
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _ready = true);
  }

  String _sig() {
    final s = _identity?.signature ?? '';
    return s.isEmpty ? '' : '\n\n$s';
  }

  void _switchIdentity(Identity? next) {
    if (next == null || next == _identity) return;
    final oldSig = _identity?.signature ?? '';
    if (oldSig.isNotEmpty && _body.text.contains(oldSig)) {
      _body.text = _body.text.replaceFirst(oldSig, next.signature);
    }
    setState(() => _identity = next);
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
      final raw = await ref.read(composeMessageProvider)(draft);
      await ref.read(mailSyncServiceProvider).send(widget.accountId, draft.identity.id, draft.allRecipients, raw);
    }, done: 'Sent');
  }

  Future<void> _saveDraft() async {
    if (_identity == null) return;
    await _run(() async {
      final raw = await ref.read(composeMessageProvider)(_draft());
      await ref.read(mailSyncServiceProvider).saveDraft(widget.accountId, raw);
    }, done: 'Draft saved');
  }

  Future<void> _run(Future<void> Function() f, {required String done}) async {
    setState(() => _busy = true);
    try {
      await f();
      if (!mounted) return;
      _snack(done);
      if (context.canPop()) context.pop();
    } catch (e) {
      _snack('Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String s) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(s)));

  Future<void> _attach() async {
    final result = await FilePicker.pickFiles(allowMultiple: true, withData: true);
    if (result == null) return;
    setState(() {
      for (final f in result.files) {
        if (f.bytes == null) continue;
        _attachments.add(ComposeAttachment(fileName: f.name, mimeType: _mime(f.name), bytes: f.bytes!));
      }
    });
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
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(recentAddressesProvider(widget.accountId)).asData?.value ?? const <MailAddress>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.draftUid != null ? 'Edit draft' : widget.forwardUid != null ? 'Forward' : (widget.replyUid ?? widget.replyAllUid) != null ? 'Reply' : 'New message'),
        actions: [
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
                      RecipientField(label: 'To', value: _to, onChanged: (v) => setState(() => _to = v), suggestions: suggestions, autofocus: _source == null),
                      if (_showCcBcc) ...[
                        RecipientField(label: 'Cc', value: _cc, onChanged: (v) => setState(() => _cc = v), suggestions: suggestions),
                        RecipientField(label: 'Bcc', value: _bcc, onChanged: (v) => setState(() => _bcc = v), suggestions: suggestions),
                      ],
                      TextField(
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
                            onDeleted: () => setState(() => _attachments.remove(a)),
                          ),
                      ]),
                    ),
                  Expanded(
                    child: TextField(
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
    );
  }
}
