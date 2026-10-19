import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:multiview_desktop/multiview_desktop.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tray_manager/tray_manager.dart';

import 'instance_requests.dart';

/// Desktop main window + tray: minimize-to-tray on close, tray menu
/// (Show / Sync now / Quit), single-instance lock file. The window itself
/// is managed by multiview_desktop (the same engine also hosts the compose
/// windows); [init] must run after `runMultiApp`.
class WindowService with TrayListener implements WindowListenerCallbacks {
  WindowService._();
  static final instance = WindowService._();
  static final _log = Logger('window');

  bool Function() minimizeToTray = () => true;
  Future<void> Function()? onSyncNow;
  Future<void> Function()? onQuit;
  RandomAccessFile? _lock;
  InstanceRequests? _requests;
  bool _trayReady = false;
  MultiViewDesktop? _main;
  bool _quitting = false;

  /// Returns false when another instance already holds the lock; [args] are
  /// then handed to that instance, which raises its window (and opens a
  /// composer for `--compose`).
  Future<bool> acquireSingleInstance(List<String> args) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}${Platform.pathSeparator}sortie.lock');
      final raf = await f.open(mode: FileMode.write);
      try {
        await raf.lock(FileLock.exclusive);
      } on FileSystemException {
        await raf.close();
        await InstanceRequests(dir).send(args);
        return false;
      }
      _lock = raf;
      _requests = InstanceRequests(dir);
      return true;
    } catch (e) {
      _log.warning('single-instance guard unavailable', e);
      return true;
    }
  }

  /// Starts serving launches of further instances: each one raises the
  /// window; [onArgs] gets its arguments (e.g. `--compose`).
  void serveInstanceRequests(void Function(List<String> args) onArgs) {
    _requests?.watch((args) {
      unawaited(show());
      onArgs(args);
    });
  }

  /// Hooks the main window's close button and sets up the tray.
  Future<void> init() async {
    try {
      final main = MultiViewDesktop.main;
      _main = main;
      main.setPreventClose(true);
      MultiViewDesktop.addListenerForView(main.id, this);
    } catch (e) {
      _log.warning('main window hooks unavailable', e);
    }
    await _initTray();
  }

  Future<void> _initTray() async {
    try {
      await trayManager.setIcon(Platform.isWindows ? 'assets/tray/sortie.ico' : 'assets/tray/sortie.png');
      if (!Platform.isLinux) await trayManager.setToolTip('Sortie');
      await trayManager.setContextMenu(Menu(items: [
        MenuItem(key: 'show', label: 'Show Sortie'),
        MenuItem(key: 'sync', label: 'Sync now'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Quit'),
      ]));
      trayManager.addListener(this);
      _trayReady = true;
    } catch (e) {
      _log.warning('tray unavailable', e);
    }
  }

  Future<void> show() async {
    final m = _main;
    if (m == null) return;
    m.show();
    m.focus();
  }

  Future<void> quit() async {
    if (_quitting) return;
    _quitting = true;
    try {
      await onQuit?.call();
    } catch (e) {
      _log.warning('shutdown hook failed', e);
    }
    if (_trayReady) await trayManager.destroy();
    await _lock?.close();
    try {
      _main?.setPreventClose(false);
      await MultiViewDesktop.closeApp(closeMode: CloseMode.destroy);
    } catch (e) {
      _log.warning('closeApp failed: $e');
    }
    exit(0);
  }

  // ------------------------------------------------------------ main window

  @override
  FutureOr<bool> onWindowClose() {
    if (minimizeToTray() && _trayReady) {
      _main?.hide();
      return false;
    }
    unawaited(quit());
    return false;
  }

  @override
  void onWindowFocus() {}
  @override
  void onWindowBlur() {}
  @override
  void onWindowMaximize() {}
  @override
  void onWindowUnmaximize() {}
  @override
  void onWindowMinimize() {}
  @override
  void onWindowRestore() {}
  @override
  void onWindowResize() {}
  @override
  void onWindowResized() {}
  @override
  void onWindowMove() {}
  @override
  void onWindowMoved() {}
  @override
  void onWindowEnterFullScreen() {}
  @override
  void onWindowLeaveFullScreen() {}
  @override
  void onWindowEvent(String eventName) {}

  // ------------------------------------------------------------ tray

  @override
  void onTrayIconMouseDown() => show();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        show();
      case 'sync':
        onSyncNow?.call();
      case 'quit':
        quit();
    }
  }
}
