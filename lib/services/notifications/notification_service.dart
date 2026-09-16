import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../domain/entities/entities.dart';
import '../../router/app_router.dart';

/// Local notifications on all platforms. Payload = in-app route to open.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final s = NotificationService();
  ref.onDispose(s.dispose);
  return s;
});

class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin]) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static final _log = Logger('notifications');
  static const _newMailChannel = 'new_mail';
  static const _sortedChannel = 'sorted';

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<String>.broadcast();
  bool _ready = false;

  /// Routes from tapped notifications (also the launch notification, once).
  Stream<String> get taps => _taps.stream;

  Future<void> init() async {
    if (_ready || kIsWeb) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
        macOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
        windows: WindowsInitializationSettings(
          appName: 'Sortie',
          appUserModelId: 'com.sortie.sortie',
          guid: '5c1f3a6e-7d2b-4c8e-9f10-2a3b4c5d6e7f',
        ),
      );
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (r) {
          final p = r.payload;
          if (p != null && p.isNotEmpty) _taps.add(p);
        },
      );
      _ready = true;
      try {
        final launch = await _plugin.getNotificationAppLaunchDetails();
        final p = launch?.notificationResponse?.payload;
        if (launch?.didNotificationLaunchApp == true && p != null && p.isNotEmpty) _taps.add(p);
      } on UnimplementedError {
        // Linux: launch details are not supported; nothing to restore.
      }
    } catch (e) {
      _log.warning('notification init failed', e);
    }
  }

  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      if (Platform.isAndroid) {
        return await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission() ?? false;
      }
      if (Platform.isIOS) {
        return await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
      }
      if (Platform.isMacOS) {
        return await _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
      }
    } catch (e) {
      _log.warning('permission request failed', e);
    }
    return true;
  }

  static int _id(String s) => s.hashCode & 0x7fffffff;

  NotificationDetails _details({required String channelId, required String channelName, required String group, bool low = false}) => NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: low ? Importance.low : Importance.defaultImportance,
          priority: low ? Priority.low : Priority.defaultPriority,
          groupKey: group,
          category: AndroidNotificationCategory.email,
        ),
        iOS: DarwinNotificationDetails(threadIdentifier: group),
        macOS: DarwinNotificationDetails(threadIdentifier: group),
        linux: LinuxNotificationDetails(category: LinuxNotificationCategory.email, urgency: low ? LinuxNotificationUrgency.low : LinuxNotificationUrgency.normal),
        windows: const WindowsNotificationDetails(),
      );

  /// One notification per message, grouped per account; tap opens it.
  Future<void> notifyNewMail(MessageHeader h) async {
    if (!_ready) return;
    final from = h.from?.name?.isNotEmpty == true ? h.from!.name! : (h.from?.email ?? 'New mail');
    try {
      await _plugin.show(
        id: _id(h.messageIdHash),
        title: from,
        body: h.subject.isEmpty ? '(no subject)' : h.subject,
        notificationDetails: _details(channelId: _newMailChannel, channelName: 'New mail', group: 'account:${h.accountId}'),
        payload: Routes.message(h.accountId, h.folderPath, h.uid),
      );
    } catch (e) {
      _log.warning('notifyNewMail failed', e);
    }
  }

  /// Optional toast after the sorter files a message.
  Future<void> notifySorted(MessageHeader h, String destination) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: _id('sorted:${h.messageIdHash}'),
        title: 'Filed to $destination',
        body: h.subject,
        notificationDetails: _details(channelId: _sortedChannel, channelName: 'Sorted mail', group: 'sorted:${h.accountId}', low: true),
        payload: Routes.message(h.accountId, destination, h.uid),
      );
    } catch (e) {
      _log.warning('notifySorted failed', e);
    }
  }

  Future<void> notifyTest() async {
    if (!_ready) await init();
    try {
      await _plugin.show(
        id: _id('test'),
        title: 'Sortie',
        body: 'Notifications are working.',
        notificationDetails: _details(channelId: _newMailChannel, channelName: 'New mail', group: 'test'),
      );
    } catch (e) {
      _log.warning('test notification failed', e);
    }
  }

  void dispose() => _taps.close();
}
