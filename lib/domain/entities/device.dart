enum DevicePlatform { linux, windows, macos, android, ios, other }

/// Default election priorities. Higher wins. Settings may override to 100
/// ("prefer this device") or disable claiming entirely.
abstract final class LeaderPriority {
  static const desktop = 30;
  static const androidForegroundService = 20;
  static const androidWorkManager = 15;
  static const ios = 10;
  static const preferred = 100;

  static int defaultFor(DevicePlatform p, {bool androidForegroundService = false}) => switch (p) {
        DevicePlatform.linux || DevicePlatform.windows || DevicePlatform.macos => desktop,
        DevicePlatform.android => androidForegroundService ? LeaderPriority.androidForegroundService : androidWorkManager,
        DevicePlatform.ios => ios,
        DevicePlatform.other => androidWorkManager,
      };
}

class DeviceIdentity {
  const DeviceIdentity({required this.deviceId, required this.displayName, required this.platform, required this.priority});
  final String deviceId;
  final String displayName;
  final DevicePlatform platform;
  final int priority;

  /// Short stable id used in Message-IDs of control messages.
  String get shortId => deviceId.replaceAll('-', '').substring(0, 12);

  DeviceIdentity withPriority(int p) =>
      DeviceIdentity(deviceId: deviceId, displayName: displayName, platform: platform, priority: p);
}
