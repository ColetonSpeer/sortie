/// Lifecycle of a dictation session as seen by the UI.
enum SpeechStatus { listening, stopped, done }

typedef SpeechResultCallback = void Function(String text, {required bool done});
typedef SpeechStatusCallback = void Function(SpeechStatus status);
typedef SpeechErrorCallback = void Function(String message, {required bool permanent});

/// On-device speech recognition behind a small interface so the UI and the
/// tests never touch the platform plugin. One implementation wraps the
/// `speech_to_text` plugin (phones); desktop gets [NoSpeechInput].
///
/// Semantics every implementation keeps:
/// * [start] opens one session. `onResult` carries the whole text heard in
///   that session so far (replace, never append); `done: true` is the last
///   result of the session.
/// * The session ends on [stop], on [cancel], on silence or on a platform
///   limit; `onStatus` reports [SpeechStatus.done] once it has.
abstract class SpeechInput {
  const SpeechInput();

  /// False on platforms with no recogniser at all (desktop): the UI then
  /// does not even offer a microphone.
  bool get supported;

  /// False when the device has no recogniser or the user denied the
  /// microphone / speech permission. May prompt for permissions.
  Future<bool> available();

  Future<void> start({
    required SpeechResultCallback onResult,
    SpeechStatusCallback? onStatus,
    SpeechErrorCallback? onError,
    String? localeId,
  });

  /// Ends the session and lets the recogniser deliver its final result.
  Future<void> stop();

  /// Ends the session and drops whatever was being recognised.
  Future<void> cancel();

  bool get isListening;
}

/// Desktop and tests: nothing to listen with. Blabber then shows a text box.
class NoSpeechInput extends SpeechInput {
  const NoSpeechInput();

  @override
  bool get supported => false;

  @override
  Future<bool> available() async => false;

  @override
  Future<void> start({required SpeechResultCallback onResult, SpeechStatusCallback? onStatus, SpeechErrorCallback? onError, String? localeId}) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}

  @override
  bool get isListening => false;
}
