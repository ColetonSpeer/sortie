import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/data/coordination/control_folder.dart';
import 'package:sortie/data/coordination/imap_control_folder.dart';
import 'package:sortie/data/mail/imap_gateway.dart';
import 'package:sortie/domain/entities/entities.dart';

import '../../fakes/fake_imap_server.dart';
import 'harness.dart';

/// Server that refuses CREATE at the namespace root.
class _RootRefusingGateway extends FakeImapGateway {
  _RootRefusingGateway(super.server);
  @override
  Future<Folder> createFolder(String path) {
    if (!path.contains(server.delimiter)) throw ImapGatewayException('NO cannot create $path at root');
    return super.createFolder(path);
  }
}

void main() {
  ControlMessageDraft draft({String type = 'presence', String dev = 'dev-1', String? mid, int seq = 1, Map<String, dynamic> body = const {'k': 1}, int? epoch, int? priority, int? upto}) =>
      ControlMessageDraft(type: type, deviceId: dev, messageId: mid ?? '<$type-$dev-$seq@sortie.invalid>', seq: seq, body: body, epoch: epoch, priority: priority, snapshotUpto: upto);

  test('ensureExists creates Sortie at root, unsubscribes and selects it', () {
    fakeAsync((fa) {
      final h = Harness(fa);
      final f = ImapControlFolder(gateway: FakeImapGateway(h.server), account: account, password: 'x', clock: FakeAsyncClock(fa));
      expect(h.wait(f.ensureExists()), 'Sortie');
      expect(h.server.mailboxes['Sortie']!.subscribed, isFalse);
      expect(h.commands('UNSUBSCRIBE Sortie'), isNotEmpty);
      expect(f.gateway.selectedPath, 'Sortie');
      // Second call is idempotent (no second CREATE).
      expect(h.wait(f.ensureExists()), 'Sortie');
      expect(h.countCommands('CREATE'), 1);
      h.wait(f.dispose());
    });
  });

  test('falls back to INBOX<delim>Sortie when root CREATE fails', () {
    fakeAsync((fa) {
      final h = Harness(fa, server: FakeImapServer(delimiter: '.'));
      final f = ImapControlFolder(gateway: _RootRefusingGateway(h.server), account: account, password: 'x', clock: FakeAsyncClock(fa));
      expect(h.wait(f.ensureExists()), 'INBOX.Sortie');
      expect(h.server.mailboxes['INBOX.Sortie']!.subscribed, isFalse);
      h.wait(f.dispose());
    });
  });

  test('render produces an RFC 5322 JSON message that parses back through fetchHeaders/fetchBody', () {
    fakeAsync((fa) {
      final h = Harness(fa);
      final f = ImapControlFolder(gateway: FakeImapGateway(h.server), account: account, password: 'x', clock: FakeAsyncClock(fa));
      h.wait(f.ensureExists());
      final d = draft(type: 'snapshot', dev: 'abcdef123456-7890', seq: 3, epoch: 4, priority: 30, upto: 77, body: {'a': [1, 2], 'b': 'x'});
      final raw = utf8.decode(f.render(d));
      final head = raw.split('\r\n\r\n').first;
      expect(head, contains('From: Sortie <sortie@sortie.invalid>'));
      expect(head, contains('Subject: [Sortie] snapshot abcdef123456'));
      expect(head, contains('Content-Type: application/json; charset=utf-8'));
      expect(head, contains('X-Sortie-Version: 1'));
      expect(head, contains('X-Sortie-Type: snapshot'));
      expect(head, contains('X-Sortie-Device: abcdef123456-7890'));
      expect(head, contains('X-Sortie-Seq: 3'));
      expect(head, contains('X-Sortie-Epoch: 4'));
      expect(head, contains('X-Sortie-Priority: 30'));
      expect(head, contains('X-Sortie-Snapshot-Upto: 77'));
      final appended = h.wait(f.append(d));
      expect(h.server.mailboxes['Sortie']!.messages[appended.uid]!.flags, contains(r'\Seen'));
      expect(appended.internalDate, h.server.clock.now());
      final msgs = h.wait(f.fetchHeaders());
      final m = msgs.single;
      expect(m.uid, appended.uid);
      expect(m.type, 'snapshot');
      expect(m.deviceId, 'abcdef123456-7890');
      expect(m.seq, 3);
      expect(m.epoch, 4);
      expect(m.priority, 30);
      expect(m.snapshotUpto, 77);
      expect(m.messageId, d.messageId);
      expect(m.body, isNull);
      expect(h.wait(f.fetchBody(m.uid)), {'a': [1, 2], 'b': 'x'});
      expect(h.wait(f.findByMessageId(d.messageId)), appended.uid);
      expect(h.wait(f.findByMessageId('<nope@sortie.invalid>')), isNull);
      h.wait(f.dispose());
    });
  });

  test('append fetches INTERNALDATE stamped by the server, not the device clock', () {
    fakeAsync((fa) {
      final h = Harness(fa);
      final f = ImapControlFolder(gateway: FakeImapGateway(h.server), account: account, password: 'x', clock: FakeAsyncClock(fa, skew: const Duration(days: 300)));
      h.wait(f.ensureExists());
      h.server.clock.advance(const Duration(hours: 2));
      final a = h.wait(f.append(draft()));
      expect(a.internalDate, DateTime.utc(2026, 1, 1, 14));
      h.wait(f.dispose());
    });
  });

  test('a dropped APPEND response is recovered through the Message-ID search', () {
    fakeAsync((fa) {
      final h = Harness(fa);
      final f = ImapControlFolder(gateway: FakeImapGateway(h.server), account: account, password: 'x', clock: FakeAsyncClock(fa));
      h.wait(f.ensureExists());
      h.server.dropNextAppendResponses = 1;
      final a = h.wait(f.append(draft(seq: 9)));
      expect(a.uid, 1);
      expect(h.wait(f.fetchHeaders()).length, 1);
      h.wait(f.dispose());
    });
  });

  test('fetchHeaders(sinceUid) skips older UIDs and foreign mail; expunge removes records', () {
    fakeAsync((fa) {
      final h = Harness(fa);
      final f = ImapControlFolder(gateway: FakeImapGateway(h.server), account: account, password: 'x', clock: FakeAsyncClock(fa));
      h.wait(f.ensureExists());
      final a = h.wait(f.append(draft(seq: 1)));
      h.server.deliver('Sortie', h.header('a stray human mail'));
      final b = h.wait(f.append(draft(seq: 2)));
      expect(h.wait(f.fetchHeaders()).map((m) => m.uid), [a.uid, b.uid]);
      expect(h.wait(f.fetchHeaders(sinceUid: b.uid)).map((m) => m.uid), [b.uid]);
      h.wait(f.expunge([a.uid]));
      expect(h.wait(f.fetchHeaders()).map((m) => m.uid), [b.uid]);
      expect(h.commands('UID EXPUNGE'), isNotEmpty);
      h.wait(f.dispose());
    });
  });

  test('changes() emits on folder activity, re-issues IDLE every 25 min and polls every 5 min', () {
    fakeAsync((fa) {
      final h = Harness(fa);
      final f = ImapControlFolder(gateway: FakeImapGateway(h.server), account: account, password: 'x', clock: FakeAsyncClock(fa));
      h.wait(f.ensureExists());
      var n = 0;
      final sub = f.changes().listen((_) => n++);
      h.settle();
      expect(h.countCommands('IDLE'), 1);
      h.wait(f.append(draft(seq: 1)));
      h.settle(400);
      expect(n, 1, reason: 'the append was reported although IDLE was paused for it');
      expect(h.countCommands('IDLE'), 2, reason: 'IDLE paused for the command and re-issued after it');
      h.elapse(const Duration(minutes: 5), step: const Duration(seconds: 30));
      expect(n, 2, reason: 'poll fallback fired');
      h.elapse(const Duration(minutes: 21), step: const Duration(minutes: 1));
      expect(h.countCommands('IDLE'), 3, reason: 'IDLE re-issued 25 min after the resume');
      // Broadcast cancel futures never resolve under fakeAsync; fire and settle.
      unawaited(sub.cancel());
      h.settle();
      h.wait(f.dispose());
    });
  });

  test('changes() reports connection loss as a stream error', () {
    fakeAsync((fa) {
      final h = Harness(fa);
      final f = ImapControlFolder(gateway: FakeImapGateway(h.server), account: account, password: 'x', clock: FakeAsyncClock(fa));
      h.wait(f.ensureExists());
      Object? err;
      f.changes().listen((_) {}, onError: (Object e) => err = e);
      h.settle();
      h.server.commandsUntilDisconnect = 1;
      expect(() => h.wait(f.noop()), throwsA(isA<ImapGatewayException>()));
      // IDLE re-issue after the drop surfaces the lost connection.
      h.elapse(const Duration(minutes: 26), step: const Duration(minutes: 1));
      expect(err, isNotNull);
      h.wait(f.dispose());
    });
  });

  test('uidValidity() re-selects and throws when the folder was deleted', () {
    fakeAsync((fa) {
      final h = Harness(fa);
      final f = ImapControlFolder(gateway: FakeImapGateway(h.server), account: account, password: 'x', clock: FakeAsyncClock(fa));
      h.wait(f.ensureExists());
      final uv = h.wait(f.uidValidity());
      h.server.bumpUidValidity('Sortie');
      expect(h.wait(f.uidValidity()), uv + 1);
      h.server.deleteMailbox('Sortie');
      expect(() => h.wait(f.uidValidity()), throwsA(isA<ImapGatewayException>()));
      h.wait(f.dispose());
    });
  });

  test('append without a selected folder fails fast', () {
    fakeAsync((fa) {
      final h = Harness(fa);
      final f = ImapControlFolder(gateway: FakeImapGateway(h.server), account: account, password: 'x', clock: FakeAsyncClock(fa));
      expect(() => h.wait(f.append(draft())), throwsA(isA<ImapGatewayException>()));
      unawaited(f.dispose());
    });
  });
}
