import 'package:logging/logging.dart';

import '../../domain/repositories/repositories.dart';

/// The platform secure store failed and the fallback has no value for the
/// key. Callers must treat this as "try again later", never as "no credential".
class CredentialStoreUnavailable implements Exception {
  const CredentialStoreUnavailable(this.cause);
  final Object cause;
  @override
  String toString() => 'CredentialStoreUnavailable: $cause';
}

/// Uses the platform secure store and falls back to [fallback] when it fails.
///
/// Two kinds of failure exist. On Linux without a Secret Service (or odd
/// Android builds) the primary never works: the store sticks to the fallback
/// so reads and writes stay consistent, and a missing value means "absent".
/// On iOS/macOS the keychain is unavailable only while the device is locked
/// (background refresh): with [transientPrimaryFailures] the primary is
/// retried after [retryPrimaryAfter], and a read that finds nothing in the
/// fallback throws [CredentialStoreUnavailable] instead of answering null.
class FallbackCredentialStore implements CredentialStore {
  FallbackCredentialStore({
    required CredentialStore primary,
    required CredentialStore fallback,
    this.transientPrimaryFailures = false,
    this.retryPrimaryAfter = const Duration(minutes: 1),
    DateTime Function()? now,
  })  : _primary = primary,
        _fallback = fallback,
        _now = now ?? DateTime.now;

  final CredentialStore _primary;
  final CredentialStore _fallback;
  final bool transientPrimaryFailures;
  final Duration retryPrimaryAfter;
  final DateTime Function() _now;
  final _log = Logger('sortie.credentials');
  DateTime? _primaryFailedAt;
  Object? _lastFailure;

  bool get usingFallback {
    final at = _primaryFailedAt;
    if (at == null) return false;
    return !transientPrimaryFailures || _now().difference(at) < retryPrimaryAfter;
  }

  void _degrade(Object e) {
    _log.warning('secure storage unavailable, using encrypted file store: ${e.runtimeType}');
    _primaryFailedAt = _now();
    _lastFailure = e;
  }

  @override
  Future<String?> read(String key) async {
    if (!usingFallback) {
      try {
        final v = await _primary.read(key);
        if (v != null) return v;
        // Value may have been written while degraded earlier.
        try {
          return await _fallback.read(key);
        } catch (_) {
          return null;
        }
      } catch (e) {
        _degrade(e);
      }
    }
    final v = await _fallback.read(key);
    if (v == null && transientPrimaryFailures) throw CredentialStoreUnavailable(_lastFailure ?? 'secure storage unavailable');
    return v;
  }

  @override
  Future<void> write(String key, String value) async {
    if (!usingFallback) {
      try {
        await _primary.write(key, value);
        return;
      } catch (e) {
        _degrade(e);
      }
    }
    await _fallback.write(key, value);
  }

  @override
  Future<void> delete(String key) async {
    if (!usingFallback) {
      try {
        await _primary.delete(key);
      } catch (e) {
        _degrade(e);
      }
    }
    try {
      await _fallback.delete(key);
    } catch (_) {}
  }
}
