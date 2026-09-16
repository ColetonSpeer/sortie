import 'package:logging/logging.dart';

import '../../domain/repositories/repositories.dart';

/// Uses the platform secure store and falls back to [fallback] when it fails
/// (no Secret Service on Linux, keystore errors on odd Android builds).
/// Once the primary fails the store sticks to the fallback for the process
/// lifetime so reads and writes stay consistent.
class FallbackCredentialStore implements CredentialStore {
  FallbackCredentialStore({required CredentialStore primary, required CredentialStore fallback})
      : _primary = primary,
        _fallback = fallback;

  final CredentialStore _primary;
  final CredentialStore _fallback;
  final _log = Logger('sortie.credentials');
  bool _usingFallback = false;

  bool get usingFallback => _usingFallback;

  Future<T> _run<T>(Future<T> Function(CredentialStore) op) async {
    if (!_usingFallback) {
      try {
        return await op(_primary);
      } catch (e) {
        _log.warning('secure storage unavailable, using encrypted file store: ${e.runtimeType}');
        _usingFallback = true;
      }
    }
    return op(_fallback);
  }

  @override
  Future<String?> read(String key) => _run((s) async {
        final v = await s.read(key);
        if (v == null && identical(s, _primary)) {
          // Value may have been written while degraded earlier.
          try {
            return await _fallback.read(key);
          } catch (_) {
            return null;
          }
        }
        return v;
      });

  @override
  Future<void> write(String key, String value) => _run((s) => s.write(key, value));

  @override
  Future<void> delete(String key) => _run((s) async {
        await s.delete(key);
        if (identical(s, _primary)) {
          try {
            await _fallback.delete(key);
          } catch (_) {}
        }
      });
}
