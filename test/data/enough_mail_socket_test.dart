import 'dart:async';
import 'dart:io';

import 'package:enough_mail/enough_mail.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the Sortie patch in third_party/enough_mail (client_base.dart):
/// when the server closes the connection, the client closes its half too.
/// Stock enough_mail 2.1.7 left it in CLOSE_WAIT until the process exited.
void main() {
  test('an IMAP client whose server hung up closes its socket', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final clientClosed = Completer<void>();
    server.listen((s) {
      s.write('* OK ready\r\n');
      // onDone here fires only once the client closes (or resets) its side.
      s.listen((_) {}, onDone: () => clientClosed.complete(), onError: (Object _) => clientClosed.complete());
      Future<void>.delayed(const Duration(milliseconds: 50), s.close);
    });
    final client = ImapClient(bus: EventBus(sync: true), isLogEnabled: false);
    final lost = Completer<void>();
    client.eventBus.on<ImapConnectionLostEvent>().listen((_) => lost.complete());
    await client.connectToServer(InternetAddress.loopbackIPv4.address, server.port, isSecure: false);
    await lost.future.timeout(const Duration(seconds: 3));
    await clientClosed.future.timeout(const Duration(seconds: 3));
    expect(client.isConnected, isFalse);
    await client.disconnect(); // idempotent on a dead client
    await server.close();
  });

  test('disconnect() after the server dropped the connection is harmless and leaves nothing open', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final clientClosed = Completer<void>();
    server.listen((s) {
      s.write('* OK ready\r\n');
      s.listen((_) {}, onDone: () => clientClosed.complete(), onError: (Object _) => clientClosed.complete());
      Future<void>.delayed(const Duration(milliseconds: 50), s.close);
    });
    final client = ImapClient(bus: EventBus(sync: true), isLogEnabled: false);
    final lost = Completer<void>();
    client.eventBus.on<ImapConnectionLostEvent>().listen((_) => lost.complete());
    await client.connectToServer(InternetAddress.loopbackIPv4.address, server.port, isSecure: false);
    await lost.future.timeout(const Duration(seconds: 3));
    // The gateway always calls disconnect() during cleanup; on a dead
    // client it used to be a no-op that kept the socket.
    await client.disconnect();
    await client.disconnect();
    await clientClosed.future.timeout(const Duration(seconds: 3));
    await server.close();
  });
}
