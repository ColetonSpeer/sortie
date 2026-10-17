import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/data/credentials/fallback_credential_store.dart';
import 'package:sortie/domain/repositories/repositories.dart';

class _Memory implements CredentialStore {
  final map = <String, String>{};
  bool broken = false;
  int reads = 0;

  @override
  Future<String?> read(String key) async {
    reads++;
    if (broken) throw StateError('locked');
    return map[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (broken) throw StateError('locked');
    map[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (broken) throw StateError('locked');
    map.remove(key);
  }
}

void main() {
  late _Memory primary, fallback;
  var now = DateTime.utc(2026, 10, 17, 12);

  setUp(() {
    primary = _Memory();
    fallback = _Memory();
    now = DateTime.utc(2026, 10, 17, 12);
  });

  group('permanent primary failure (Linux without a keyring)', () {
    test('sticks to the fallback and a missing value is simply absent', () async {
      final store = FallbackCredentialStore(primary: primary, fallback: fallback, now: () => now);
      primary.broken = true;
      expect(await store.read('pw'), isNull);
      await store.write('pw', 'secret');
      expect(fallback.map['pw'], 'secret');
      now = now.add(const Duration(hours: 1));
      primary.broken = false;
      expect(await store.read('pw'), 'secret');
      expect(primary.reads, 1, reason: 'never retried after the first failure');
    });
  });

  group('transient primary failure (locked iPhone keychain)', () {
    test('a locked keychain throws instead of answering "no password"', () async {
      final store = FallbackCredentialStore(primary: primary, fallback: fallback, transientPrimaryFailures: true, now: () => now);
      await store.write('pw', 'secret');
      expect(primary.map['pw'], 'secret');
      primary.broken = true;
      await expectLater(store.read('pw'), throwsA(isA<CredentialStoreUnavailable>()));
      expect(store.usingFallback, isTrue);
    });

    test('the keychain is retried once the retry window passes', () async {
      final store = FallbackCredentialStore(primary: primary, fallback: fallback, transientPrimaryFailures: true, now: () => now);
      await store.write('pw', 'secret');
      primary.broken = true;
      await expectLater(store.read('pw'), throwsA(isA<CredentialStoreUnavailable>()));
      now = now.add(const Duration(seconds: 30));
      await expectLater(store.read('pw'), throwsA(isA<CredentialStoreUnavailable>()));
      expect(primary.reads, 1, reason: 'inside the window the keychain is left alone');
      primary.broken = false;
      now = now.add(const Duration(minutes: 1));
      expect(await store.read('pw'), 'secret');
      expect(store.usingFallback, isFalse);
    });

    test('a value written while degraded is still found', () async {
      final store = FallbackCredentialStore(primary: primary, fallback: fallback, transientPrimaryFailures: true, now: () => now);
      primary.broken = true;
      await store.write('pw', 'secret');
      expect(fallback.map['pw'], 'secret');
      expect(await store.read('pw'), 'secret');
      primary.broken = false;
      now = now.add(const Duration(minutes: 2));
      expect(await store.read('pw'), 'secret', reason: 'primary has nothing, fallback does');
    });
  });
}
