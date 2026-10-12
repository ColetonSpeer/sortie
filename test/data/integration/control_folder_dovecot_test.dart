// Control folder against a real Dovecot: commands interleaved with IDLE on
// one connection, at the spacings the leader loop produces (a journal
// append right after the IDLE resume that follows the previous one).
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/core/clock.dart';
import 'package:sortie/data/coordination/control_folder.dart';
import 'package:sortie/data/coordination/imap_control_folder.dart';
import 'package:sortie/data/mail/enough/enough_imap_gateway.dart';
import 'package:sortie/domain/entities/entities.dart';

void main() {
  const definedHost = String.fromEnvironment('IMAP_TEST_HOST');
  const definedPort = String.fromEnvironment('IMAP_TEST_PORT', defaultValue: '3143');
  final host = definedHost.isNotEmpty ? definedHost : Platform.environment['IMAP_TEST_HOST'];
  final port = int.tryParse(Platform.environment['IMAP_TEST_PORT'] ?? definedPort) ?? 3143;
  final user = Platform.environment['IMAP_TEST_USER'] ?? 'test';
  final password = Platform.environment['IMAP_TEST_PASSWORD'] ?? 'test';
  final skip = host == null || host.isEmpty ? 'set IMAP_TEST_HOST (see tool/docker-compose.dovecot.yml)' : false;
  final runId = DateTime.now().microsecondsSinceEpoch;
  final account = Account(
    id: 'it',
    displayName: 'Integration',
    email: '$user@example.test',
    username: user,
    imap: ImapEndpoint(host: host ?? '127.0.0.1', port: port, security: ConnectionSecurity.none),
    smtp: const SmtpEndpoint(host: '127.0.0.1', port: 3587, security: ConnectionSecurity.none),
  );

  test('a burst of appends and fetches around IDLE never stalls', () async {
    final f = ImapControlFolder(gateway: EnoughImapGateway(logName: 'ctl'), account: account, password: password, clock: SystemClock(), folderName: 'SortieIT$runId');
    await f.ensureExists();
    final errors = <Object>[];
    final sub = f.changes().listen((_) {}, onError: errors.add);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    const gaps = [0, 50, 100, 200, 240, 260, 300, 400, 600, 800, 1000, 0, 250, 250, 250, 300, 300, 50, 700, 260];
    var seq = 0;
    for (final gap in gaps) {
      await Future<void>.delayed(Duration(milliseconds: gap));
      final n = ++seq;
      final draft = ControlMessageDraft(type: 'moved', deviceId: 'ittest000000000', messageId: '<burst-$runId-$n@sortie.invalid>', seq: n, body: {'n': n}, epoch: 1);
      await f.append(draft).timeout(const Duration(seconds: 20), onTimeout: () => fail('append $n after ${gap}ms stalled'));
      if (n % 4 == 0) {
        final hs = await f.fetchHeaders(sinceUid: 1).timeout(const Duration(seconds: 20), onTimeout: () => fail('fetch after append $n stalled'));
        expect(hs.length, n);
      }
    }
    expect(errors, isEmpty);
    await sub.cancel();
    await f.dispose();
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}
