/// Keeps sync/sorting alive while the app is not in the foreground.
abstract class BackgroundRunner {
  Future<void> start();
  Future<void> stop();

  /// True when this runner can keep an IMAP IDLE connection open in the
  /// background (desktop, Android foreground service). False means the device
  /// only gets short periodic cycles (iOS BGAppRefresh / WorkManager).
  bool get canHoldIdle;
}

/// Set by the composition root (`// TODO(wiring)` in main.dart): builds the
/// services in a background isolate and runs one bounded coordinator cycle
/// per account. Called by the WorkManager / BGAppRefresh dispatcher.
Future<void> Function()? backgroundCycle;
