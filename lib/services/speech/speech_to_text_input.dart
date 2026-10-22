import 'package:logging/logging.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'speech_input.dart';

/// [SpeechInput] over the `speech_to_text` plugin: Apple's and Google's
/// on-device dictation. The only file that imports the plugin, so desktop
/// builds (which have no implementation) never construct it.
class SpeechToTextInput extends SpeechInput {
  SpeechToTextInput({SpeechToText? plugin}) : _stt = plugin ?? SpeechToText();

  static final _log = Logger('speech');
  final SpeechToText _stt;
  bool? _available;

  @override
  bool get supported => true;
  SpeechStatusCallback? _onStatus;
  SpeechErrorCallback? _onError;

  @override
  Future<bool> available() async {
    if (_available == true) return true;
    try {
      _available = await _stt.initialize(
        onStatus: (s) {
          final cb = _onStatus;
          if (cb == null) return;
          switch (s) {
            case SpeechToText.listeningStatus:
              cb(SpeechStatus.listening);
            case SpeechToText.notListeningStatus:
              cb(SpeechStatus.stopped);
            case SpeechToText.doneStatus:
              cb(SpeechStatus.done);
          }
        },
        onError: (e) {
          _log.fine('speech error ${e.errorMsg} permanent=${e.permanent}');
          _onError?.call(e.errorMsg, permanent: e.permanent);
        },
      );
    } catch (e) {
      _log.warning('speech init failed: $e');
      _available = false;
    }
    return _available ?? false;
  }

  @override
  Future<void> start({required SpeechResultCallback onResult, SpeechStatusCallback? onStatus, SpeechErrorCallback? onError, String? localeId}) async {
    if (!await available()) {
      onError?.call('Speech recognition is not available.', permanent: true);
      return;
    }
    _onStatus = onStatus;
    _onError = onError;
    await _stt.listen(
      onResult: (r) => onResult(r.recognizedWords, done: r.finalResult),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        autoPunctuation: true,
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 6),
        localeId: localeId,
      ),
    );
  }

  @override
  Future<void> stop() => _stt.isListening ? _stt.stop() : Future.value();

  @override
  Future<void> cancel() => _stt.isListening ? _stt.cancel() : Future.value();

  @override
  bool get isListening => _stt.isListening;
}
