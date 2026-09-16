import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Desktop window + tray: min size, title, minimize-to-tray on close,
/// tray menu (Show / Sync now / Quit), single-instance lock file.
class WindowService with WindowListener, TrayListener {
  WindowService._();
  static final instance = WindowService._();
  static final _log = Logger('window');

  bool Function() minimizeToTray = () => true;
  Future<void> Function()? onSyncNow;
  Future<void> Function()? onQuit;
  RandomAccessFile? _lock;
  bool _trayReady = false;

  /// Returns false when another instance already holds the lock.
  Future<bool> acquireSingleInstance() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}${Platform.pathSeparator}sortie.lock');
      final raf = await f.open(mode: FileMode.write);
      try {
        await raf.lock(FileLock.exclusive);
      } on FileSystemException {
        await raf.close();
        return false;
      }
      _lock = raf;
      return true;
    } catch (e) {
      _log.warning('single-instance guard unavailable', e);
      return true;
    }
  }

  Future<void> init() async {
    await windowManager.ensureInitialized();
    const options = WindowOptions(minimumSize: Size(900, 600), size: Size(1280, 800), center: true, title: 'Sortie');
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setPreventClose(true);
      await windowManager.show();
      await windowManager.focus();
    });
    windowManager.addListener(this);
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
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> quit() async {
    try {
      await onQuit?.call();
    } catch (e) {
      _log.warning('shutdown hook failed', e);
    }
    if (_trayReady) await trayManager.destroy();
    await _lock?.close();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  void onWindowClose() async {
    if (minimizeToTray() && _trayReady) {
      await windowManager.hide();
    } else {
      await quit();
    }
  }

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
