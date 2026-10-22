import 'package:sortie/services/speech/speech_input.dart';

/// Scripted recogniser: tests drive it with [emit], [finish] and [fail].
class FakeSpeechInput extends SpeechInput {
  FakeSpeechInput({this.availableResult = true, this.supported = true});

  bool availableResult;
  @override
  final bool supported;
  int starts = 0;
  int stops = 0;
  int cancels = 0;
  bool _listening = false;
  SpeechResultCallback? _onResult;
  SpeechStatusCallback? _onStatus;
  SpeechErrorCallback? _onError;

  @override
  Future<bool> available() async => availableResult;

  @override
  Future<void> start({required SpeechResultCallback onResult, SpeechStatusCallback? onStatus, SpeechErrorCallback? onError, String? localeId}) async {
    starts++;
    _listening = true;
    _onResult = onResult;
    _onStatus = onStatus;
    _onError = onError;
    onStatus?.call(SpeechStatus.listening);
  }

  /// A partial (or, with [done], the final) result of the current session.
  void emit(String text, {bool done = false}) {
    _onResult?.call(text, done: done);
    if (done) {
      _listening = false;
      _onStatus?.call(SpeechStatus.stopped);
      _onStatus?.call(SpeechStatus.done);
    }
  }

  /// The platform ended the session (silence, limit) with [text] as final.
  void finish([String? text]) => emit(text ?? '', done: true);

  void fail(String message, {bool permanent = true}) {
    _onError?.call(message, permanent: permanent);
    if (permanent) {
      _listening = false;
      _onStatus?.call(SpeechStatus.done);
    }
  }

  @override
  Future<void> stop() async {
    stops++;
    // The real recogniser delivers the final result after stop(); tests
    // call [finish] to simulate that, or rely on the sheet's fallback.
  }

  @override
  Future<void> cancel() async {
    cancels++;
    _listening = false;
  }

  @override
  bool get isListening => _listening;
}
