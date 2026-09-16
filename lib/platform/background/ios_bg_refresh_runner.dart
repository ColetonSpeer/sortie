import 'dart:io';

import 'package:logging/logging.dart';
import 'package:workmanager/workmanager.dart';

import 'background_runner.dart';

/// Periodic short cycles via WorkManager (Android fallback) and iOS
/// BGAppRefresh/BGProcessing. Each run calls [backgroundCycle], which the
/// composition root points at `coordinator.runForegroundCycle()` per account.
///
/// iOS Info.plist keys added for this:
///   UIBackgroundModes: fetch, processing
///   BGTaskSchedulerPermittedIdentifiers: com.sortie.sortie.refresh,
///     com.sortie.sortie.processing (must match the identifiers below)
class PeriodicCycleRunner implements BackgroundRunner {
  static final _log = Logger('bg-cycle');
  static const refreshTask = 'com.sortie.sortie.refresh';
  static const processingTask = 'com.sortie.sortie.processing';
  static bool _initialized = false;

  @override
  Future<void> start() async {
    try {
      if (!_initialized) {
        await Workmanager().initialize(sortieBackgroundDispatcher);
        _initialized = true;
      }
      if (Platform.isIOS) {
        await Workmanager().registerProcessingTask(processingTask, processingTask, constraints: Constraints(networkType: NetworkType.connected));
        // BGAppRefresh (`Workmanager.iOSBackgroundTask`) is scheduled by the
        // system automatically once UIBackgroundModes contains `fetch`.
      } else {
        await Workmanager().registerPeriodicTask(
          refreshTask,
          refreshTask,
          frequency: const Duration(minutes: 15),
          constraints: Constraints(networkType: NetworkType.connected),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        );
      }
    } catch (e) {
      _log.warning('background registration failed', e);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await Workmanager().cancelAll();
    } catch (e) {
      _log.warning('background cancel failed', e);
    }
  }

  @override
  bool get canHoldIdle => false;
}

@pragma('vm:entry-point')
void sortieBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final cycle = backgroundCycle;
    if (cycle == null) return true; // Nothing wired yet; report success so the OS keeps scheduling us.
    try {
      await cycle().timeout(const Duration(seconds: 25));
      return true;
    } catch (_) {
      return false;
    }
  });
}
