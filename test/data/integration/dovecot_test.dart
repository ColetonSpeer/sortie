@Tags(['integration'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/core/clock.dart';
import 'package:sortie/data/mail/enough/enough_imap_gateway.dart';
import 'package:sortie/data/mail/imap_gateway.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/services/compose/message_composer.dart';

/// Runs against the Dovecot from tool/docker-compose.dovecot.yml. Skipped
/// unless IMAP_TEST_HOST is provided via `--dart-define` or the environment.
void main() {
  const definedHost = String.fromEnvironment('IMAP_TEST_HOST');
  const definedPort = String.fromEnvironment('IMAP_TEST_PORT', defaultValue: '3143');
  final host = definedHost.isNotEmpty ? definedHost : Platform.environment['IMAP_TEST_HOST'];
  final port = int.tryParse(Platform.environment['IMAP_TEST_PORT'] ?? definedPort) ?? 3143;
  final user = Platform.environment['IMAP_TEST_USER'] ?? 'test';
  final password = Platform.environment['IMAP_TEST_PASSWORD'] ?? 'test';
  final skip = host == null || host.isEmpty ? 'set IMAP_TEST_HOST (see tool/docker-compose.dovecot.yml)' : false;

  final account = Account(
    id: 'it',
    displayName: 'Integration',
    email: '$user@example.test',
    username: user,
    imap: ImapEndpoint(host: host ?? '127.0.0.1', port: port, security: ConnectionSecurity.none),
    smtp: const SmtpEndpoint(host: '127.0.0.1', port: 3587, security: ConnectionSecurity.none),
  );
  const identity = Identity(id: 'i', accountId: 'it', name: 'Integration', email: 'test@example.test');
  final composer = MessageComposer(clock: SystemClock());
  final runId = DateTime.now().microsecondsSinceEpoch;

  List<int> mail(String subject) => composer.compose(ComposeRequest(identity: identity, to: const ['someone@example.test'], subject: subject, text: 'body of $subject')).raw;

  group('EnoughImapGateway against Dovecot', () {
    late EnoughImapGateway gw;
    late ImapCapabilities caps;

    setUp(() async {
      gw = EnoughImapGateway(logName: 'it');
      caps = await gw.connect(account, password);
    });

    tearDown(() => gw.disconnect());

    test('capabilities and folder list with SPECIAL-USE', () async {
      expect(caps.idle, isTrue);
      expect(caps.move, isTrue);
      expect(caps.uidPlus, isTrue);
      expect(caps.condStore, isTrue);
      expect(caps.specialUse, isTrue);
      final folders = await gw.listFolders();
      expect(gw.delimiter, '/');
      expect(folders.map((f) => f.path), containsAll(['INBOX', 'Sent', 'Trash', 'Drafts']));
      expect(folders.singleWhere((f) => f.path == 'Trash').specialUse, SpecialUse.trash);
      expect(folders.singleWhere((f) => f.path == 'INBOX').specialUse, SpecialUse.inbox);
    });

    test('append, fetch headers/body, keyword store, search, move with COPYUID, expunge', () async {
      final subject = 'sortie-it-$runId';
      final ar = await gw.append('INBOX', mail(subject), flags: {r'\Seen'});
      expect(ar.uid, isNotNull, reason: 'APPENDUID');
      final uid = ar.uid!;
      final sel = await gw.select('INBOX');
      expect(sel.uidValidity, ar.uidValidity);
      expect(sel.highestModSeq, isNotNull);
      expect(sel.permanentFlagsAllowKeywords, isTrue);

      final headers = await gw.fetchHeadersByUids([uid]);
      final h = headers.single;
      expect(h.subject, subject);
      expect(h.from!.email, identity.email);
      expect(h.isSeen, isTrue);
      expect(h.messageId, isNotNull);
      expect(h.internalDate, isNotNull);
      expect(h.attachments, isEmpty);

      final since = await gw.fetchHeaders(UidRange.since(uid));
      expect(since.map((x) => x.uid), contains(uid));
      final body = await gw.fetchBody(uid);
      expect(body.text, contains('body of $subject'));
      expect(body.html, contains('body of'));
      final raw = await gw.fetchRaw(uid);
      expect(utf8.decode(raw, allowMalformed: true), contains('Subject: $subject'));
      expect((await gw.fetchTextBody(uid))!, contains('body of'));

      await gw.store([uid], add: {SortieKeywords.pending, r'\Flagged'});
      expect((await gw.fetchFlags(UidRange.single(uid)))[uid], containsAll([SortieKeywords.pending, r'\Flagged']));
      expect(await gw.searchKeyword(SortieKeywords.pending), contains(uid));
      expect(await gw.searchByMessageId(h.messageId!), [uid]);
      await gw.store([uid], remove: {SortieKeywords.pending});
      expect(await gw.searchKeyword(SortieKeywords.pending), isNot(contains(uid)));

      final rawHeaders = await gw.fetchRawHeaders(UidRange.single(uid), ['Subject', 'Message-ID']);
      expect(rawHeaders.single.headers['subject'], subject);
      expect(rawHeaders.single.headers['message-id'], h.messageId);

      final dest = 'SortieIT/$runId';
      await gw.createFolder(dest);
      await gw.unsubscribeFolder(dest);
      final mv = await gw.move([uid], dest);
      expect(mv.uidMapping[uid], isNotNull, reason: 'COPYUID');
      expect(await gw.allUids(), isNot(contains(uid)));
      await gw.select(dest);
      final moved = await gw.fetchHeadersByUids([mv.uidMapping[uid]!]);
      expect(moved.single.subject, subject);
      await gw.expunge([mv.uidMapping[uid]!]);
      expect(await gw.allUids(), isEmpty);
    });

    test('IDLE delivers NewMessagesEvent for an APPEND on another connection', () async {
      final other = EnoughImapGateway(logName: 'it2');
      await other.connect(account, password);
      try {
        await gw.select('INBOX');
        final stop = Completer<void>();
        final events = <MailboxEvent>[];
        final done = gw.idle(stop: stop.future).listen(events.add).asFuture<void>();
        await Future<void>.delayed(const Duration(milliseconds: 300));
        final ar = await other.append('INBOX', mail('idle-$runId'));
        await Future<void>.delayed(const Duration(seconds: 2));
        stop.complete();
        await done.timeout(const Duration(seconds: 10));
        expect(events.whereType<NewMessagesEvent>(), isNotEmpty);
        await gw.select('INBOX');
        await gw.expunge([ar.uid!]);
      } finally {
        await other.disconnect();
      }
    });

    test('wrong password is an auth failure', () async {
      final bad = EnoughImapGateway(logName: 'bad');
      await expectLater(bad.connect(account, 'definitely-wrong'), throwsA(isA<ImapGatewayException>().having((e) => e.isAuthFailure, 'auth', true)));
      await bad.disconnect();
    });
  }, skip: skip);
}
