import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import 'android_foreground_runner.dart';
import 'background_runner.dart';
import 'desktop_runner.dart';
import 'ios_bg_refresh_runner.dart';

/// Picks the runner for this platform and the current device settings.
final backgroundRunnerProvider = Provider<BackgroundRunner>((ref) {
  final settings = ref.watch(deviceSettingsProvider).asData?.value ?? const DeviceSettings();
  return backgroundRunnerFor(settings);
});

BackgroundRunner backgroundRunnerFor(DeviceSettings settings) {
  if (kIsWeb) return DesktopRunner();
  if (Platform.isAndroid) return settings.androidForegroundService ? AndroidForegroundRunner() : PeriodicCycleRunner();
  if (Platform.isIOS) return PeriodicCycleRunner();
  return DesktopRunner();
}
