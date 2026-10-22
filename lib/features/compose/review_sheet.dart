import 'package:flutter/material.dart';

import '../../services/compose/draft_reviewer.dart';

/// Splits a compose body into what the user wrote and the tail Sortie added
/// (signature, quoted reply, forwarded message), so only the former is
/// reviewed and the tail survives untouched.
({String own, String tail}) splitOwnText(String body, {String signature = ''}) {
  var cut = -1;
  if (signature.trim().isNotEmpty) {
    final i = body.indexOf(signature);
    if (i >= 0) cut = i;
  }
  for (final marker in [RegExp(r'\n\n-- \n'), RegExp(r'\n\nOn .{0,200}? wrote:\n', dotAll: true), RegExp(r'\n\n-------- Forwarded message --------\n')]) {
    final m = marker.firstMatch(body);
    if (m != null && (cut < 0 || m.start < cut)) cut = m.start;
  }
  if (cut < 0) return (own: body, tail: '');
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
Future<ReviewOutcome?> showReviewSheet(
  BuildContext context, {
  required Future<DraftReview> Function(String instruction) run,
  required String currentSubject,
}) =>
    showDialog<ReviewOutcome>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ReviewDialog(run: run, currentSubject: currentSubject),
    );

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.run, required this.currentSubject});
  final Future<DraftReview> Function(String instruction) run;
  final String currentSubject;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _instruction = TextEditingController();
  DraftReview? _review;
  bool _busy = false;
  bool _applySubject = true;
  String? _error;

  @override
  void dispose() {
    _instruction.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await widget.run(_instruction.text);
      if (mounted) setState(() => _review = r);
    } catch (e) {
      if (mounted) setState(() => _error = e is DraftReviewException ? e.message : 'Review failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = _review;
    final width = (MediaQuery.sizeOf(context).width * 0.8).clamp(320.0, 760.0);
    return AlertDialog(
      title: Row(children: [
        const Icon(Icons.auto_fix_high_outlined),
        const SizedBox(width: 8),
        Text(r == null ? 'Review with AI' : 'Suggested revision'),
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
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Keep mine')),
              TextButton(key: const Key('reviewAgain'), onPressed: () => setState(() => _review = null), child: const Text('Try again')),
              FilledButton(
                key: const Key('applyReview'),
                onPressed: () => Navigator.of(context).pop(ReviewOutcome(
                  body: r.revisedBody,
                  subject: _applySubject ? r.revisedSubject : null,
                )),
                child: const Text('Use revision'),
              ),
            ],
    );
  }

  Widget _ask(ThemeData theme) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('The text you wrote is sent to your AI backend for proofreading. Your signature and any quoted message stay as they are.'),
        const SizedBox(height: 12),
        TextField(
          key: const Key('reviewInstruction'),
          controller: _instruction,
          enabled: !_busy,
          decoration: const InputDecoration(
            labelText: 'Anything in particular? (optional)',
            hintText: 'e.g. shorter, more formal, friendlier, fix the tone',
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
              Text('Changes', style: theme.textTheme.titleSmall),
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
          ]),
        ),
      );
}
