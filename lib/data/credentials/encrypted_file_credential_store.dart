import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/repositories.dart';

/// Fallback for desktops without a Secret Service: values AES-256-GCM
/// encrypted into `credentials.json`, with the key in a sibling file readable
/// only by the user. Protects against casual disk reads, not a root attacker.
class EncryptedFileCredentialStore implements CredentialStore {
  EncryptedFileCredentialStore(this.directory, {this.keyFileName = 'credentials.key', this.valuesFileName = 'credentials.json'});

  /// Store under the platform app-support directory.
  static Future<EncryptedFileCredentialStore> inAppSupportDir() async {
    final dir = await getApplicationSupportDirectory();
    return EncryptedFileCredentialStore(Directory(p.join(dir.path, 'credentials')));
  }

  final Directory directory;
  final String keyFileName;
  final String valuesFileName;
  final _aes = AesGcm.with256bits();
  SecretKey? _key;
  Map<String, String>? _values;

  File get _keyFile => File(p.join(directory.path, keyFileName));
  File get _valuesFile => File(p.join(directory.path, valuesFileName));

  Future<SecretKey> _loadKey() async {
    final cached = _key;
    if (cached != null) return cached;
    await directory.create(recursive: true);
    if (await _keyFile.exists()) {
      final bytes = base64Decode((await _keyFile.readAsString()).trim());
      return _key = SecretKey(bytes);
    }
    final rnd = Random.secure();
    final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    await _keyFile.writeAsString(base64Encode(bytes), flush: true);
    await _restrict(_keyFile);
    return _key = SecretKey(bytes);
  }

  Future<void> _restrict(File f) async {
    if (Platform.isLinux || Platform.isMacOS) {
      try {
        await Process.run('chmod', ['600', f.path]);
      } catch (_) {}
    }
  }

  Future<Map<String, String>> _load() async {
    final cached = _values;
    if (cached != null) return cached;
    if (!await _valuesFile.exists()) return _values = {};
    try {
      final raw = jsonDecode(await _valuesFile.readAsString()) as Map<String, dynamic>;
      return _values = raw.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return _values = {};
    }
  }

  Future<void> _save(Map<String, String> values) async {
    await directory.create(recursive: true);
    final tmp = File('${_valuesFile.path}.tmp');
    await tmp.writeAsString(jsonEncode(values), flush: true);
    await tmp.rename(_valuesFile.path);
    await _restrict(_valuesFile);
    _values = values;
  }

  @override
  Future<String?> read(String key) async {
    final enc = (await _load())[key];
    if (enc == null) return null;
    final secretKey = await _loadKey();
    final box = SecretBox.fromConcatenation(base64Decode(enc), nonceLength: 12, macLength: 16);
    final clear = await _aes.decrypt(box, secretKey: secretKey, aad: utf8.encode(key));
    return utf8.decode(clear);
  }

  @override
  Future<void> write(String key, String value) async {
    final secretKey = await _loadKey();
    final box = await _aes.encrypt(utf8.encode(value), secretKey: secretKey, aad: utf8.encode(key));
    final values = Map<String, String>.from(await _load());
    values[key] = base64Encode(box.concatenation());
    await _save(values);
  }

  @override
  Future<void> delete(String key) async {
    final values = Map<String, String>.from(await _load());
    if (values.remove(key) != null) await _save(values);
  }
}
