import 'background_runner.dart';

/// Desktop keeps running (minimized to tray); nothing to schedule.
class DesktopRunner implements BackgroundRunner {
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
  @override
  bool get canHoldIdle => true;
}
