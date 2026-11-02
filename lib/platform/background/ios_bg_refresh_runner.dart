import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

import '../../app/composition_root.dart';
import '../../core/logging.dart';
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

/// Set once per isolate; the file sink is shared with the main isolate's
/// `sortie.log` so a cycle that ran while the app was frozen shows up in
/// Settings > Diagnostics after the next launch.
bool _loggingReady = false;

Future<void> _initBackgroundLogging() async {
  if (_loggingReady) return;
  _loggingReady = true;
  final dir = await getApplicationSupportDirectory();
  final sink = FileLogSink(p.join(dir.path, 'sortie.log'));
  initLogging(level: Level.INFO, sink: (line) => sink('[bg] $line'));
}

@pragma('vm:entry-point')
void sortieBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final log = Logger('bg-cycle');
    var cycle = backgroundCycle;
    SortieServices? own;
    if (cycle == null) {
      // iOS and WorkManager run this in a fresh isolate with nothing wired:
      // build the services for this one cycle and tear them down after.
      try {
        WidgetsFlutterBinding.ensureInitialized();
        await _initBackgroundLogging();
        own = await SortieServices.build(forBackgroundCycle: true).timeout(const Duration(seconds: 10));
        cycle = own.runBackgroundCycle;
      } catch (e, s) {
        log.warning('background cycle ($task): services unavailable', e, s);
        return false;
      }
    }
    final sw = Stopwatch()..start();
    log.info('background cycle ($task) starting');
    try {
      await cycle().timeout(const Duration(seconds: 29));
      log.info('background cycle done in ${sw.elapsed.inSeconds}s');
      return true;
    } catch (e, s) {
      log.warning('background cycle failed after ${sw.elapsed.inSeconds}s', e, s);
      return false;
    } finally {
      try {
        await own?.stop().timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
  });
}
