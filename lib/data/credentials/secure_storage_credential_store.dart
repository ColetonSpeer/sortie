import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/repositories/repositories.dart';

/// Platform keychain / keystore / Secret Service via flutter_secure_storage.
///
/// On iOS and macOS items are stored with `AfterFirstUnlockThisDeviceOnly`
/// accessibility: the default (`WhenUnlocked`) made every background refresh
/// on a locked phone fail with "no password stored". The keychain query
/// includes the accessibility level, so items written before this change are
/// read through [legacy] once and re-written under the new level.
class SecureStorageCredentialStore implements CredentialStore {
  SecureStorageCredentialStore({FlutterSecureStorage? storage, FlutterSecureStorage? legacy, this.prefix = 'sortie.'})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
              mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
            ),
        _legacy = legacy ?? (_apple ? const FlutterSecureStorage(aOptions: AndroidOptions()) : null);

  static bool get _apple => !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  final FlutterSecureStorage _storage;
  final FlutterSecureStorage? _legacy;
  final String prefix;

  @override
  Future<String?> read(String key) async {
    final k = '$prefix$key';
    final v = await _storage.read(key: k);
    final legacy = _legacy;
    if (v != null || legacy == null) return v;
    final old = await legacy.read(key: k);
    if (old == null) return null;
    // Same account + service: the old item must go before the new one is added.
    await legacy.delete(key: k);
    await _storage.write(key: k, value: old);
    return old;
  }

  @override
  Future<void> write(String key, String value) async {
    final k = '$prefix$key';
    final legacy = _legacy;
    if (legacy != null) {
      try {
        await legacy.delete(key: k);
      } catch (_) {}
    }
    await _storage.write(key: k, value: value);
  }

  @override
  Future<void> delete(String key) async {
    final k = '$prefix$key';
    await _storage.delete(key: k);
    final legacy = _legacy;
    if (legacy != null) {
      try {
        await legacy.delete(key: k);
      } catch (_) {}
    }
  }
}
