import 'package:flutter/material.dart';

import '../../services/compose/draft_reviewer.dart';

/// Splits a compose body into what the user wrote and the tail Sortie added
/// (signature, quoted reply, forwarded message), so only the former is
/// reviewed and the tail survives untouched.
///
/// Line endings are normalised to `\n` first (bodies read back from the
/// cache, such as a reopened draft, arrive with `\r\n`); both parts are
/// returned normalised. The cut is the earliest of: the identity's
/// signature, a `-- ` separator line, an "On … wrote:" header, a forwarded
/// message banner, or, failing all of those, the first quoted (`> `) block
/// with the header line right above it.
({String own, String tail}) splitOwnText(String body, {String signature = ''}) {
  body = body.replaceAll('\r\n', '\n');
  signature = signature.replaceAll('\r\n', '\n');
  var cut = -1;
  void consider(int i) {
    if (i >= 0 && (cut < 0 || i < cut)) cut = i;
  }

  if (signature.trim().isNotEmpty) {
    final i = body.indexOf(signature);
    if (i >= 0) {
      // Take the blank line(s) before the signature along with it.
      var start = i;
      while (start > 0 && body[start - 1] == '\n') {
        start--;
      }
      consider(start);
    }
  }
  for (final marker in [
    RegExp(r'\n-- ?\n'),
    RegExp(r'\n+On .{0,400}? wrote:\n', dotAll: true),
    RegExp(r'\n+-{3,} ?Forwarded message ?-{3,}\n'),
  ]) {
    final m = marker.firstMatch(body);
    if (m != null) consider(m.start);
  }
  if (cut < 0) {
    // No recognised header: the first quoted block, with the line above it
    // when that line introduces it ("… wrote:" / ends with a colon).
    final q = RegExp(r'(^|\n)(?:[^\n]*:[ \t]*\n)?> ', multiLine: false).firstMatch(body);
    if (q != null) consider(q.start);
  }
  if (cut < 0) return (own: body, tail: '');
  // The blank line(s) before the tail belong to the tail.
  while (cut > 0 && body[cut - 1] == '\n') {
    cut--;
  }
  return (own: body.substring(0, cut), tail: body.substring(cut));
}

/// What the user decided after seeing the review.
class ReviewOutcome {
  const ReviewOutcome({required this.body, this.subject});
  final String body;
  final String? subject;
}

/// Asks for an optional instruction, runs the review, shows notes and the
/// revised text, and returns what to apply (null = keep the draft as is).
/// Remembered for the session so the user does not re-pick it every time.
ReviewDepth _lastDepth = ReviewDepth.improve;

Future<ReviewOutcome?> showReviewSheet(
  BuildContext context, {
  required Future<DraftReview> Function(String instruction, ReviewDepth depth, List<ReviewTurn> history) run,
  required String currentSubject,
}) =>
    showDialog<ReviewOutcome>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ReviewDialog(run: run, currentSubject: currentSubject),
    );

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.run, required this.currentSubject});
  final Future<DraftReview> Function(String instruction, ReviewDepth depth, List<ReviewTurn> history) run;
  final String currentSubject;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _instruction = TextEditingController();
  final _correction = TextEditingController();
  DraftReview? _review;
  final _history = <ReviewTurn>[];
  bool _busy = false;
  bool _applySubject = true;
  ReviewDepth _depth = _lastDepth;
  String? _error;

  @override
  void dispose() {
    _instruction.dispose();
    _correction.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _lastDepth = _depth;
      final r = await widget.run(_instruction.text, _depth, List.unmodifiable(_history));
      if (mounted) setState(() => _review = r);
    } catch (e) {
      if (mounted) setState(() => _error = e is DraftReviewException ? e.message : 'Review failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The user says what the last revision got wrong; the model revises
  /// again with every earlier correction still in force.
  Future<void> _revise() async {
    final r = _review;
    final text = _correction.text.trim();
    if (r == null || text.isEmpty) return;
    _history.add(ReviewTurn(revisedBody: r.revisedBody, correction: text));
    _correction.clear();
    await _go();
  }

  void _startOver() => setState(() {
        _review = null;
        _history.clear();
        _error = null;
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = _review;
    final width = (MediaQuery.sizeOf(context).width * 0.8).clamp(320.0, 760.0);
    return AlertDialog(
      title: Row(children: [
        const Icon(Icons.auto_fix_high_outlined),
        const SizedBox(width: 8),
        Text(r == null ? 'Review with AI' : _history.isEmpty ? 'Suggested revision' : 'Revision ${_history.length + 1}'),
      ]),
      content: SizedBox(
        width: width,
        child: r == null ? _ask(theme) : _result(theme, r),
      ),
      actions: r == null
          ? [
              TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
              FilledButton(key: const Key('runReview'), onPressed: _busy ? null : _go, child: const Text('Review')),
            ]
          : [
              TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: const Text('Keep mine')),
              TextButton(key: const Key('reviewAgain'), onPressed: _busy ? null : _startOver, child: const Text('Start over')),
              FilledButton(
                key: const Key('applyReview'),
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).pop(ReviewOutcome(
                  body: r.revisedBody,
                  subject: _applySubject ? r.revisedSubject : null,
                )),
                child: const Text('Use revision'),
              ),
            ],
    );
  }

  Widget _ask(ThemeData theme) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('The text you wrote (and, for a reply, the conversation) is sent to your AI backend. Your signature and any quoted message stay as they are.'),
        const SizedBox(height: 12),
        SegmentedButton<ReviewDepth>(
          key: const Key('reviewDepth'),
          segments: const [
            ButtonSegment(value: ReviewDepth.proofread, label: Text('Proofread'), icon: Icon(Icons.spellcheck)),
            ButtonSegment(value: ReviewDepth.improve, label: Text('Improve'), icon: Icon(Icons.auto_fix_high_outlined)),
            ButtonSegment(value: ReviewDepth.rewrite, label: Text('Rewrite'), icon: Icon(Icons.edit_note_outlined)),
          ],
          selected: {_depth},
          showSelectedIcon: false,
          onSelectionChanged: _busy ? null : (v) => setState(() => _depth = v.single),
        ),
        const SizedBox(height: 6),
        Text(
          switch (_depth) {
            ReviewDepth.proofread => 'Spelling, grammar and clumsy phrasing only.',
            ReviewDepth.improve => 'Also clarity, structure, tone, a clear ask, and anything the reader will need. Gaps become [placeholders] for you to fill.',
            ReviewDepth.rewrite => 'The best version of this email from what you meant to say; it may be restructured freely.',
          },
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('reviewInstruction'),
          controller: _instruction,
          enabled: !_busy,
          decoration: const InputDecoration(
            labelText: 'Anything in particular? (optional)',
            hintText: 'e.g. shorter, more formal, push back politely, add a deadline',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _busy ? null : _go(),
        ),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
      ]);

  Widget _result(ThemeData theme, DraftReview r) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (r.notes.isNotEmpty) ...[
              Text('Changes and suggestions', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              for (final n in r.notes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('• '),
                    Expanded(child: Text(n)),
                  ]),
                ),
              const SizedBox(height: 12),
            ],
            if (r.revisedSubject != null)
              CheckboxListTile(
                key: const Key('applySubject'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _applySubject,
                onChanged: (v) => setState(() => _applySubject = v ?? true),
                title: Text('Subject: ${r.revisedSubject}'),
                subtitle: Text('was: ${widget.currentSubject}'),
              ),
            Text('Revised text', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(r.revisedBody, key: const Key('revisedBody')),
            ),
            const SizedBox(height: 8),
            Text(
              '${r.modelId}${r.costUsd > 0 ? ' · \$${r.costUsd.toStringAsFixed(4)}' : ''}',
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text('Not quite right?', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            if (_history.isNotEmpty) ...[
              for (final t in _history)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.person_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(child: Text(t.correction, style: theme.textTheme.bodySmall)),
                  ]),
                ),
              const SizedBox(height: 4),
            ],
            TextField(
              key: const Key('reviewCorrection'),
              controller: _correction,
              enabled: !_busy,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Tell it what to fix, e.g. "the call already happened" or "we agreed on Friday, not Thursday"',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  key: const Key('reviseReview'),
                  tooltip: 'Revise',
                  icon: const Icon(Icons.send_outlined),
                  onPressed: _busy ? null : _revise,
                ),
              ),
              onSubmitted: (_) => _busy ? null : _revise(),
            ),
            if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
          ]),
        ),
      );
}
