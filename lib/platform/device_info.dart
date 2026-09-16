import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../domain/entities/entities.dart';
import '../domain/repositories/repositories.dart';

DevicePlatform currentPlatform() {
  if (kIsWeb) return DevicePlatform.other;
  if (Platform.isLinux) return DevicePlatform.linux;
  if (Platform.isWindows) return DevicePlatform.windows;
  if (Platform.isMacOS) return DevicePlatform.macos;
  if (Platform.isAndroid) return DevicePlatform.android;
  if (Platform.isIOS) return DevicePlatform.ios;
  return DevicePlatform.other;
}

bool get isDesktop => !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

/// Stable per-install id (kept in the credential store), a human name and the
/// election priority derived from settings.
Future<DeviceIdentity> loadDeviceIdentity(CredentialStore store, DeviceSettings settings) async {
  var id = await store.read(CredentialStore.deviceId);
  if (id == null || id.length < 12) {
    id = const Uuid().v4();
    await store.write(CredentialStore.deviceId, id);
  }
  final platform = currentPlatform();
  return DeviceIdentity(
    deviceId: id,
    displayName: _displayName(platform),
    platform: platform,
    priority: priorityFor(platform, settings),
  );
}

int priorityFor(DevicePlatform platform, DeviceSettings s) {
  if (!s.mayLead) return 0;
  if (s.preferThisDevice) return LeaderPriority.preferred;
  return LeaderPriority.defaultFor(platform, androidForegroundService: s.androidForegroundService);
}

String _displayName(DevicePlatform p) {
  String host = '';
  try {
    host = Platform.localHostname;
  } catch (_) {}
  return switch (p) {
    DevicePlatform.android => host.isEmpty || host == 'localhost' ? 'Android phone' : host,
    DevicePlatform.ios => 'iPhone',
    _ => host.isEmpty ? p.name : host,
  };
}
