import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:logging/logging.dart';

import 'background_runner.dart';

/// Low-priority persistent notification that keeps the process (and its IMAP
/// IDLE connections in the main isolate) alive on Android. On by default
/// (`DeviceSettings.androidForegroundService`); the periodic WorkManager
/// cycle is the fallback when it is switched off.
class AndroidForegroundRunner implements BackgroundRunner {
  static final _log = Logger('fg-service');
  static bool _initialized = false;

  static void _init() {
    if (_initialized) return;
    _initialized = true;
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'sortie_sync',
        channelName: 'Background sync',
        channelDescription: 'Keeps Sortie connected so it can sort mail while the app is closed',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
        showBadge: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false, // Android 15 forbids dataSync services from BOOT_COMPLETED.
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  @override
  Future<void> start() async {
    _init();
    try {
      if (await FlutterForegroundTask.isRunningService) return;
      final perm = await FlutterForegroundTask.checkNotificationPermission();
      if (perm != NotificationPermission.granted) await FlutterForegroundTask.requestNotificationPermission();
      final r = await FlutterForegroundTask.startService(
        serviceId: 4242,
        serviceTypes: [ForegroundServiceTypes.remoteMessaging],
        notificationTitle: 'Sortie is syncing',
        notificationText: 'Keeping your mailbox sorted',
        callback: sortieForegroundCallback,
      );
      if (r is ServiceRequestFailure) _log.warning('foreground service failed: ${r.error}');
    } catch (e) {
      _log.warning('foreground service start failed', e);
    }
  }

  @override
  Future<void> stop() async {
    try {
      if (await FlutterForegroundTask.isRunningService) await FlutterForegroundTask.stopService();
    } catch (e) {
      _log.warning('foreground service stop failed', e);
    }
  }

  @override
  bool get canHoldIdle => true;
}

/// Runs in the service isolate. The work happens in the main isolate; this
/// handler only exists so the service has a task to own.
@pragma('vm:entry-point')
void sortieForegroundCallback() => FlutterForegroundTask.setTaskHandler(_KeepAliveHandler());

class _KeepAliveHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}
  @override
  void onRepeatEvent(DateTime timestamp) {}
  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
