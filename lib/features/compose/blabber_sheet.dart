import 'dart:async';

import 'package:flutter/material.dart';

import '../../platform/background/background_keep_alive.dart';
import '../../services/compose/blabber_composer.dart';
import '../../services/speech/speech_input.dart';
import '../shell/adaptive_scaffold.dart' show AdaptiveScaffold;

/// What the user accepted from Blabber.
class BlabberOutcome {
  const BlabberOutcome({required this.subject, required this.body, required this.applySubject});
  final String subject;
  final String body;
  final bool applySubject;
}

/// Blabber: listen (phones) or take typed thoughts (desktop), send the
/// transcript to the AI backend, show the email it wrote, and return what
/// to put into the composer (null = nothing).
Future<BlabberOutcome?> showBlabberSheet(
  BuildContext context, {
  required SpeechInput speech,
  required Future<BlabberResult> Function(String transcript, String instruction) run,
  required String currentSubject,
  required bool isReply,
  bool hasOwnText = false,
  bool autoListen = true,
}) =>
    showDialog<BlabberOutcome>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BlabberDialog(
        speech: speech,
        run: run,
        currentSubject: currentSubject,
        isReply: isReply,
        hasOwnText: hasOwnText,
        autoListen: autoListen,
      ),
    );

enum _Phase { idle, listening, generating, result }

class _BlabberDialog extends StatefulWidget {
  const _BlabberDialog({
    required this.speech,
    required this.run,
    required this.currentSubject,
    required this.isReply,
    required this.hasOwnText,
    required this.autoListen,
  });
  final SpeechInput speech;
  final Future<BlabberResult> Function(String transcript, String instruction) run;
  final String currentSubject;
  final bool isReply;
  final bool hasOwnText;
  final bool autoListen;

  @override
  State<_BlabberDialog> createState() => _BlabberDialogState();
}

class _BlabberDialogState extends State<_BlabberDialog> with WidgetsBindingObserver {
  /// Sessions restarted on their own (silence, platform limit) per sheet.
  static const maxRestarts = 20;

  final _transcript = TextEditingController();
  final _instruction = TextEditingController();
  _Phase _phase = _Phase.idle;
  bool? _mic; // null = still checking
  String _committed = '';
  String _live = '';
  bool _userStopped = false;
  bool _heard = false;
  bool _sessionEnded = true;
  int _restarts = 0;
  bool _pausedKeepAlive = false;
  Timer? _stopFallback;
  BlabberResult? _result;
  bool _applySubject = true;
  String? _error;
  String? _hint;

  SpeechInput get _speech => widget.speech;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applySubject = !widget.isReply;
    unawaited(_probeMic());
  }

  Future<void> _probeMic() async {
    if (!_speech.supported) {
      if (mounted) setState(() => _mic = false);
      return;
    }
    final ok = await _speech.available();
    if (!mounted) return;
    setState(() {
      _mic = ok;
      if (!ok) _hint = 'Microphone or speech recognition is not allowed. Allow it in the system settings, or type your thoughts.';
    });
    if (ok && widget.autoListen) await _listen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopFallback?.cancel();
    if (_speech.isListening) unawaited(_speech.cancel());
    if (_pausedKeepAlive) unawaited(BackgroundKeepAlive.resumeAfterDictation());
    _transcript.dispose();
    _instruction.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused || state == AppLifecycleState.hidden) && _phase == _Phase.listening) unawaited(_stop());
  }

  String get _joined => _live.isEmpty ? _committed : (_committed.isEmpty ? _live : '$_committed $_live');

  Future<void> _listen() async {
    if (_mic != true || _phase == _Phase.listening || _phase == _Phase.generating) return;
    if (!_pausedKeepAlive) {
      _pausedKeepAlive = true;
      await BackgroundKeepAlive.pauseForDictation();
    }
    setState(() {
      _phase = _Phase.listening;
      _error = null;
      _result = null;
      _userStopped = false;
      _restarts = 0;
    });
    await _startSession();
  }

  Future<void> _startSession() async {
    _committed = _transcript.text.trim();
    _live = '';
    _heard = false;
    _sessionEnded = false;
    try {
      await _speech.start(
        onResult: (text, {required done}) {
          if (!mounted || _phase != _Phase.listening) return;
          _live = text;
          if (text.trim().isNotEmpty) _heard = true;
          if (done) {
            _committed = _joined.trim();
            _live = '';
          }
          setState(() => _transcript.text = _joined);
        },
        onStatus: (s) {
          if (s == SpeechStatus.done) _onSessionEnded();
        },
        onError: (msg, {required permanent}) {
          if (!permanent) return;
          if (msg.contains('permission') || msg.contains('denied')) {
            _mic = false;
            _hint = 'Microphone or speech recognition is not allowed. Allow it in the system settings, or type your thoughts.';
            _userStopped = true;
          }
          _onSessionEnded();
        },
      );
    } catch (e) {
      _error = 'Could not start listening: $e';
      _onSessionEnded();
    }
  }

  /// One recogniser session is over (final result delivered). Keep going
  /// unless the user stopped, nothing was heard, or we have restarted a lot.
  void _onSessionEnded() {
    if (_sessionEnded || !mounted) return;
    _sessionEnded = true;
    _committed = _joined.trim();
    _live = '';
    _transcript.text = _committed;
    if (_phase != _Phase.listening) return;
    if (!_userStopped && _heard && _restarts < maxRestarts) {
      _restarts++;
      unawaited(_startSession());
      return;
    }
    _stopFallback?.cancel();
    setState(() => _phase = _Phase.idle);
  }

  Future<void> _stop() async {
    if (_userStopped || _phase != _Phase.listening) return;
    _userStopped = true;
    await _speech.stop();
    // A recogniser that never reports the end of the session must not
    // leave the sheet stuck on Stop.
    _stopFallback?.cancel();
    _stopFallback = Timer(const Duration(seconds: 3), () {
      if (mounted && _phase == _Phase.listening) _onSessionEnded();
    });
  }

  Future<void> _go() async {
    if (_phase == _Phase.listening) {
      await _stop();
      if (_phase == _Phase.listening) {
        // Wait for the final result (bounded by the fallback above).
        for (var i = 0; i < 35 && _phase == _Phase.listening && mounted; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
    }
    final transcript = _transcript.text.trim();
    if (transcript.isEmpty) {
      setState(() => _error = 'Nothing was heard. Say or type something first.');
      return;
    }
    setState(() {
      _phase = _Phase.generating;
      _error = null;
    });
    try {
      final r = await widget.run(transcript, _instruction.text);
      if (!mounted) return;
      setState(() {
        _result = r;
        _phase = _Phase.result;
        if (widget.isReply && r.subject.trim() == widget.currentSubject.trim()) _applySubject = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is BlabberException ? e.message : 'Blabber failed: $e';
        _phase = _Phase.idle;
      });
    }
  }

  void _again() => setState(() {
        _result = null;
        _phase = _Phase.idle;
      });

  Future<void> _more() async {
    _again();
    await _listen();
  }

  void _use(BlabberResult r) => Navigator.of(context).pop(BlabberOutcome(subject: r.subject, body: r.body, applySubject: _applySubject));

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < AdaptiveScaffold.compactBreakpoint;
    final title = switch (_phase) {
      _Phase.listening => 'Listening…',
      _Phase.generating => 'Writing the email…',
      _Phase.result => 'Here is your email',
      _Phase.idle => 'Blabber',
    };
    if (compact) {
      return Dialog.fullscreen(
        key: const Key('blabberSheet'),
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: _phase == _Phase.generating ? null : () => Navigator.of(context).pop()),
            title: Text(title),
          ),
          body: SafeArea(
            child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: SingleChildScrollView(child: _content(context))),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: _actions(context, compact: true)),
            ),
          ),
        ),
      );
    }
    final width = (MediaQuery.sizeOf(context).width * 0.8).clamp(320.0, 760.0);
    return AlertDialog(
      key: const Key('blabberSheet'),
      title: Row(children: [const Icon(Icons.mic_none_outlined), const SizedBox(width: 8), Text(title)]),
      content: SizedBox(
        width: width,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
          child: SingleChildScrollView(child: _content(context)),
        ),
      ),
      actions: _actions(context, compact: false),
    );
  }

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    final r = _result;
    if (r != null && _phase == _Phase.result) return _resultView(theme, r);
    final listening = _phase == _Phase.listening;
    final busy = _phase == _Phase.generating;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        _mic == true
            ? 'Say what the email should get across, as rough as you like. Sortie writes it up; only the text goes to your AI backend.'
            : 'Type or paste your thoughts, as rough as you like. Sortie turns them into the email and you review it before anything is sent.',
        style: theme.textTheme.bodyMedium,
      ),
      if (_hint != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_hint!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
      const SizedBox(height: 12),
      TextField(
        key: const Key('blabberTranscript'),
        controller: _transcript,
        readOnly: listening || busy,
        enabled: !busy,
        minLines: 4,
        maxLines: 10,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: listening ? 'What I hear' : 'Your thoughts',
          hintText: _mic == true ? 'Tap the microphone and talk' : 'e.g. tell brian thursday works, ask about the invoice, keep it short',
          border: const OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const Key('blabberInstruction'),
        controller: _instruction,
        enabled: !busy && !listening,
        decoration: const InputDecoration(
          labelText: 'How should it sound? (optional)',
          hintText: 'e.g. formal, friendly, two short paragraphs',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => busy ? null : _go(),
      ),
      if (_mic == true) ...[
        const SizedBox(height: 16),
        Center(
          child: listening
              ? FilledButton.icon(key: const Key('blabberStop'), onPressed: _stop, icon: const Icon(Icons.stop_circle_outlined), label: const Text('Stop'))
              : FilledButton.tonalIcon(key: const Key('blabberMic'), onPressed: busy ? null : _listen, icon: const Icon(Icons.mic), label: Text(_transcript.text.trim().isEmpty ? 'Talk' : 'Keep talking')),
        ),
        if (listening)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.graphic_eq, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Flexible(child: Text('Listening. Pause as long as you like; tap Stop when you are done.', style: theme.textTheme.bodySmall)),
            ]),
          ),
      ],
      if (busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, key: const Key('blabberError'), style: TextStyle(color: theme.colorScheme.error))),
    ]);
  }

  Widget _resultView(ThemeData theme, BlabberResult r) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        CheckboxListTile(
          key: const Key('blabberApplySubject'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _applySubject,
          onChanged: (v) => setState(() => _applySubject = v ?? true),
          title: Text('Subject: ${r.subject.isEmpty ? '(none)' : r.subject}'),
          subtitle: widget.currentSubject.trim().isEmpty || widget.currentSubject.trim() == r.subject ? null : Text('now: ${widget.currentSubject}'),
        ),
        Text('Email', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
          child: SelectableText(r.body, key: const Key('blabberBody')),
        ),
        if (r.notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Notes', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          for (final n in r.notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('• '), Expanded(child: Text(n))]),
            ),
        ],
        const SizedBox(height: 8),
        Text(
          '${r.modelId}${r.costUsd > 0 ? ' · \$${r.costUsd.toStringAsFixed(4)}' : ''}',
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ]);

  List<Widget> _actions(BuildContext context, {required bool compact}) {
    final r = _result;
    if (r != null && _phase == _Phase.result) {
      return [
        if (!compact) TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        if (_mic == true) TextButton.icon(key: const Key('blabberMore'), onPressed: _more, icon: const Icon(Icons.mic), label: const Text('Keep talking')),
        TextButton(key: const Key('blabberAgain'), onPressed: _again, child: const Text('Try again')),
        FilledButton(key: const Key('blabberUse'), onPressed: () => _use(r), child: Text(widget.hasOwnText ? 'Replace my text' : 'Use it')),
      ];
    }
    final busy = _phase == _Phase.generating;
    return [
      if (!compact) TextButton(onPressed: busy ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
      FilledButton.icon(
        key: const Key('blabberGo'),
        onPressed: busy ? null : _go,
        icon: const Icon(Icons.auto_awesome_outlined),
        label: const Text('Make the email'),
      ),
    ];
  }
}
