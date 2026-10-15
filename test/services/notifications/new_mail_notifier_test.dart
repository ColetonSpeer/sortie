import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/core/clock.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/services/notifications/importance.dart';
import 'package:sortie/services/notifications/new_mail_notifier.dart';

class _Sink implements NewMailSink {
  final single = <MessageHeader>[];
  final summaries = <List<MessageHeader>>[];
  int inits = 0;

  @override
  Future<void> init() async => inits++;
  @override
  Future<void> notifyNewMail(MessageHeader h) async => single.add(h);
  @override
  Future<void> notifyNewMailSummary(String accountId, List<MessageHeader> headers) async => summaries.add(headers);
}

const me = 'me@hky.test';
final clock = FakeClock(DateTime.utc(2026, 10, 15, 12));
int _n = 0;

MessageHeader msg(
  String subject, {
  String from = 'alice@example.test',
  List<String> to = const [me],
  List<String> cc = const [],
  Set<String> flags = const {},
  String? listId,
  String? precedence,
  String? inReplyTo,
  bool unsubscribe = false,
  DateTime? at,
}) {
  final n = ++_n;
  return MessageHeader(
    accountId: 'acct',
    folderPath: 'INBOX',
    uid: n,
    uidValidity: 1,
    messageIdHash: 'h$n',
    messageId: '<m$n@x>',
    subject: subject,
    from: MailAddress(from),
    to: [for (final t in to) MailAddress(t)],
    cc: [for (final c in cc) MailAddress(c)],
    date: at ?? clock.now(),
    internalDate: at ?? clock.now(),
    flags: flags,
    listId: listId,
    precedence: precedence,
    inReplyTo: inReplyTo,
    hasListUnsubscribe: unsubscribe,
  );
}

const judge = ImportanceJudge(myAddresses: {me}, correspondents: {'bob@partner.test'});

void main() {
  group('ImportanceJudge', () {
    test('a person writing directly to me is important', () {
      expect(judge.isImportant(msg('hi')), isTrue);
    });
    test('mailing lists, bulk and unsubscribe mail are not', () {
      expect(judge.isImportant(msg('digest', listId: 'dev.lists.test')), isFalse);
      expect(judge.isImportant(msg('promo', precedence: 'bulk')), isFalse);
      expect(judge.isImportant(msg('promo', unsubscribe: true)), isFalse);
    });
    test('automated senders are not, unless I have written to them', () {
      expect(judge.isImportant(msg('x', from: 'noreply@shop.test')), isFalse);
      expect(judge.isImportant(msg('x', from: 'no-reply+abc@shop.test')), isFalse);
      expect(judge.isImportant(msg('x', from: 'notifications@github.test')), isFalse);
      expect(judge.isImportant(msg('x', from: 'orders@shop.test')), isFalse);
      expect(judge.isImportant(msg('x', from: 'bob@partner.test', to: ['someone@else.test'])), isTrue);
    });
    test('cc-only and broadcasts are not; replies in my threads are', () {
      expect(judge.isImportant(msg('fyi', to: ['other@x.test'], cc: [me])), isFalse);
      final many = [for (var i = 0; i < 12; i++) 'p$i@x.test', me];
      expect(judge.isImportant(msg('all hands', to: many)), isFalse);
      expect(judge.isImportant(msg('Re: all hands', to: many, inReplyTo: '<m1@x>')), isTrue);
    });
    test('flagged wins, my own copies never count', () {
      expect(judge.isImportant(msg('x', from: 'news@x.test', flags: {r'\Flagged'})), isTrue);
      expect(judge.isImportant(msg('x', from: me)), isFalse);
      expect(judge.isOwn(msg('x', from: 'ME@hky.test')), isTrue);
    });
  });

  group('NewMailNotifier', () {
    late _Sink sink;
    late NotifyMode mode;
    late StreamController<List<Account>> accounts;
    late StreamController<List<MessageHeader>> arrivals;
    late NewMailNotifier notifier;

    setUp(() {
      sink = _Sink();
      mode = NotifyMode.all;
      accounts = StreamController<List<Account>>.broadcast();
      arrivals = StreamController<List<MessageHeader>>.broadcast();
      notifier = NewMailNotifier(
        accounts: accounts.stream,
        arrivals: (_) => arrivals.stream,
        sink: sink,
        mode: () => mode,
        judge: (_) async => judge,
        clock: clock,
      );
    });

    tearDown(() async {
      await notifier.stop();
      await accounts.close();
      await arrivals.close();
    });

    test('every-message mode announces unread arrivals once and skips read, old and own mail', () async {
      final a = msg('new');
      await notifier.handle('acct', [
        a,
        msg('read elsewhere', flags: {r'\Seen'}),
        msg('stale', at: clock.now().subtract(const Duration(days: 2))),
        msg('my copy', from: me),
        msg('newsletter', from: 'news@x.test', listId: 'news.x.test'),
      ]);
      expect(sink.single.map((h) => h.subject), ['new', 'newsletter']);
      expect(sink.inits, 1);
      await notifier.handle('acct', [a]);
      expect(sink.single.length, 2, reason: 'a resync of the same message is not announced again');
    });

    test('important-only mode filters through the judge', () async {
      mode = NotifyMode.important;
      await notifier.handle('acct', [
        msg('from a person'),
        msg('newsletter', from: 'news@x.test', listId: 'news.x.test'),
        msg('robot', from: 'noreply@x.test'),
        msg('partner', from: 'bob@partner.test', to: ['team@x.test']),
      ]);
      expect(sink.single.map((h) => h.subject), ['from a person', 'partner']);
    });

    test('off mode announces nothing', () async {
      mode = NotifyMode.off;
      await notifier.handle('acct', [msg('x')]);
      expect(sink.single, isEmpty);
      expect(sink.inits, 0);
    });

    test('a burst collapses into one summary', () async {
      await notifier.handle('acct', [for (var i = 0; i < 20; i++) msg('m$i')]);
      expect(sink.single, isEmpty);
      expect(sink.summaries.single.length, 20);
    });

    test('subscribes to arrivals of every account from the accounts stream', () async {
      notifier.start();
      accounts.add([
        const Account(id: 'acct', displayName: 'A', email: me, username: me, imap: ImapEndpoint(host: 'imap', port: 993, security: ConnectionSecurity.tls), smtp: SmtpEndpoint(host: 'smtp', port: 587, security: ConnectionSecurity.starttls)),
      ]);
      await Future<void>.delayed(Duration.zero);
      arrivals.add([msg('live')]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(sink.single.map((h) => h.subject), ['live']);
    });
  });

  group('DeviceSettings notify mode', () {
    test('platform default and legacy boolean', () {
      const d = DeviceSettings();
      expect(d.effectiveNotifyMode(mobile: true), NotifyMode.important);
      expect(d.effectiveNotifyMode(mobile: false), NotifyMode.all);
      expect(DeviceSettings.fromJson({'notify': false}).notifyMode, NotifyMode.off);
      expect(DeviceSettings.fromJson({'notify': true}).notifyMode, isNull);
      expect(DeviceSettings.fromJson({'notifyMode': 'important', 'notify': false}).notifyMode, NotifyMode.important);
      expect(DeviceSettings.fromJson(d.copyWith(notifyMode: NotifyMode.all).toJson()).notifyMode, NotifyMode.all);
    });
  });
}
