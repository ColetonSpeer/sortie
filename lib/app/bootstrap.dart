import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../domain/entities/entities.dart';
import '../platform/background/background_runner.dart';
import '../platform/background/background_runner_provider.dart';
import '../platform/desktop/autostart.dart';
import '../platform/desktop/window_service.dart';
import '../platform/device_info.dart';
import '../router/app_router.dart';
import '../services/notifications/notification_service.dart';
import 'providers.dart';

/// Wires platform services to providers once the ProviderScope exists:
/// notifications (tap -> route), tray callbacks, background runner, autostart.
class SortieBootstrap extends ConsumerStatefulWidget {
  const SortieBootstrap({super.key});

  @override
  ConsumerState<SortieBootstrap> createState() => _SortieBootstrapState();
}

class _SortieBootstrapState extends ConsumerState<SortieBootstrap> {
  BackgroundRunner? _runner;
  bool? _lastAutostart;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final notifications = ref.read(notificationServiceProvider);
    await notifications.init();
    notifications.taps.listen((route) => ref.read(appRouterProvider).go(route));

    if (isDesktop) {
      final w = WindowService.instance;
      w.minimizeToTray = () => ref.read(deviceSettingsProvider).asData?.value.minimizeToTray ?? true;
      w.onSyncNow = () async {
        final sync = ref.read(mailSyncServiceProvider);
        for (final a in ref.read(accountsProvider).asData?.value ?? const <Account>[]) {
          await sync.syncNow(a.id);
        }
      };
      // main.dart installs the real shutdown (SortieServices.stop) before the
      // scope exists; keep it and fall back to stopping sync in demo mode.
      final prevQuit = w.onQuit;
      w.onQuit = () async {
        try {
          if (prevQuit != null) {
            await prevQuit();
          } else {
            await ref.read(mailSyncServiceProvider).stop();
          }
        } catch (_) {}
      };
    }

    ref.listenManual(deviceSettingsProvider, (_, next) {
      final s = next.asData?.value;
      if (s != null) _applySettings(s);
    }, fireImmediately: true);

    if (ref.read(deviceSettingsProvider).asData?.value.notifyNewMail ?? true) {
      await notifications.requestPermission();
    }
  }

  Future<void> _applySettings(DeviceSettings s) async {
    // Background runner: swap when the Android foreground-service toggle changes.
    final next = backgroundRunnerFor(s);
    if (_runner?.runtimeType != next.runtimeType) {
      await _runner?.stop();
      _runner = next;
      await _runner!.start();
    }
    if (isDesktop && _lastAutostart != s.launchAtStartup) {
      _lastAutostart = s.launchAtStartup;
      await Autostart.set(enabled: s.launchAtStartup);
    }
  }

  @override
  Widget build(BuildContext context) {
    const app = SortieApp();
    if (!kIsWeb && Platform.isAndroid) return const WithForegroundTask(child: app);
    return app;
  }
}
