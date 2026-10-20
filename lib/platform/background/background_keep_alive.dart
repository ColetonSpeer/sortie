import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

/// iOS only: asks the native side to hold a silent audio session so the
/// process keeps running (and sorting) after the user leaves the app.
/// See `BackgroundKeepAlive` in ios/Runner/AppDelegate.swift.
abstract final class BackgroundKeepAlive {
  static final _log = Logger('keep-alive');
  static const _channel = MethodChannel('com.sortie.sortie/background');
  static bool? _last;

  static bool get supported => !kIsWeb && Platform.isIOS;

  static Future<void> set({required bool enabled}) async {
    if (!supported || _last == enabled) return;
    try {
      await _channel.invokeMethod<void>('keepAlive', enabled);
      _last = enabled;
      _log.info(enabled ? 'background keep-alive on' : 'background keep-alive off');
    } on MissingPluginException {
      _log.fine('keep-alive channel not available');
    } catch (e) {
      _log.warning('keep-alive toggle failed', e);
    }
  }
}
