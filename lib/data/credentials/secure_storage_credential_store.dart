import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/repositories/repositories.dart';

/// Platform keychain / keystore / Secret Service via flutter_secure_storage.
class SecureStorageCredentialStore implements CredentialStore {
  SecureStorageCredentialStore({FlutterSecureStorage? storage, this.prefix = 'sortie.'})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
            );

  final FlutterSecureStorage _storage;
  final String prefix;

  @override
  Future<String?> read(String key) => _storage.read(key: '$prefix$key');

  @override
  Future<void> write(String key, String value) => _storage.write(key: '$prefix$key', value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: '$prefix$key');
}
