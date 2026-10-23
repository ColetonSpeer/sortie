import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/features/mailbox/threading.dart';

final _t0 = DateTime.utc(2026, 9, 1, 12);

MessageHeader h(
  int uid, {
  String? mid,
  String? irt,
  List<String> refs = const [],
  String subject = 'Subject',
  String from = 'alice@example.test',
  List<String> to = const ['me@example.test'],
  int minutes = 0,
  bool seen = true,
  bool attach = false,
}) =>
    MessageHeader(
      accountId: 'a',
      folderPath: 'INBOX',
      uid: uid,
      uidValidity: 1,
      messageIdHash: 'hash-$uid',
      messageId: mid ?? '<m$uid@example.test>',
      inReplyTo: irt,
      references: refs,
      subject: subject,
      from: MailAddress(from, from.split('@').first),
      to: [for (final t in to) MailAddress(t)],
      date: _t0.add(Duration(minutes: minutes)),
      flags: {if (seen) r'\Seen'},
      attachments: attach ? const [AttachmentInfo(partId: '2', fileName: 'x', mimeType: 'text/plain', size: 1)] : const [],
    );

List<int> uids(MessageThread t) => t.messages.map((m) => m.uid).toList();

void main() {
  subjectFallbackTests();
  sentMergeTests();
  group('buildThreads', () {
    test('References / In-Reply-To chain becomes one thread, oldest first', () {
      final a = h(1, minutes: 0, subject: 'Plan');
      final b = h(2, irt: '<m1@example.test>', refs: ['<m1@example.test>'], minutes: 10, subject: 'Re: Plan', from: 'bob@example.test', seen: false);
      final c = h(3, irt: '<m2@example.test>', refs: ['<m1@example.test>', '<m2@example.test>'], minutes: 20, subject: 'Re: Plan', attach: true);
      final threads = buildThreads([c, a, b]);
      expect(threads, hasLength(1));
      final t = threads.single;
      expect(uids(t), [1, 2, 3]);
      expect(t.latest.uid, 3);
      expect(t.lastDate, c.date);
      expect(t.unreadCount, 1);
      expect(t.hasAttachments, isTrue);
      expect(t.subject, 'Plan');
      expect(t.id, 'hash-1');
      expect(t.participants, containsAll(['alice@example.test', 'bob@example.test', 'me@example.test']));
    });

    test('missing intermediate message still links root and leaf', () {
      final a = h(1, subject: 'Plan');
      final c = h(3, irt: '<m2@example.test>', refs: ['<m1@example.test>', '<m2@example.test>'], minutes: 20, subject: 'Re: Plan');
      final threads = buildThreads([a, c]);
      expect(threads, hasLength(1));
      expect(uids(threads.single), [1, 3]);
    });

    test('partial chains merge through an absent common ancestor', () {
      // Neither message is in the list's parent, but both reference m0.
      final b = h(2, refs: ['<m0@example.test>'], minutes: 5, subject: 'Re: X');
      final c = h(3, irt: '<M0@example.test>', minutes: 6, subject: 'Re: Y'); // different case + no brackets in refs
      final threads = buildThreads([b, c]);
      expect(threads, hasLength(1));
      expect(uids(threads.single), [2, 3]);
    });

    test('reply with a changed subject threads via References', () {
      final a = h(1, subject: 'Budget');
      final b = h(2, irt: '<m1@example.test>', refs: ['<m1@example.test>'], minutes: 1, subject: 'Totally different', from: 'bob@example.test');
      final threads = buildThreads([a, b]);
      expect(threads, hasLength(1));
      expect(threads.single.subject, 'Budget');
    });

    test('subject fallback merges header-less mail sharing a participant', () {
      final a = h(1, subject: 'Lunch?', from: 'alice@example.test', to: ['bob@example.test']);
      final b = h(2, subject: 'RE: Lunch?', from: 'bob@example.test', to: ['alice@example.test'], minutes: 30);
      final c = h(3, subject: '[team] Fwd: lunch?', from: 'carol@example.test', to: ['alice@example.test'], minutes: 60);
      final threads = buildThreads([a, b, c]);
      expect(threads, hasLength(1));
      expect(uids(threads.single), [1, 2, 3]);
    });

    test('same subject but no shared participant is NOT merged', () {
      final a = h(1, subject: 'Invoice', from: 'acme@example.test', to: ['me@example.test']);
      final b = h(2, subject: 'Re: Invoice', from: 'globex@example.test', to: ['me@example.test'], minutes: 5);
      // "me" is the user's own address, which never counts as shared.
      final threads = buildThreads([a, b], ownAddresses: {'ME@example.test'});
      expect(threads, hasLength(2));
      // Without knowing our own address the shared recipient does merge them.
      expect(buildThreads([a, b]), hasLength(1));
    });

    test('empty normalized subject never merges', () {
      final a = h(1, subject: 'Re:', from: 'alice@example.test', to: ['bob@example.test']);
      final b = h(2, subject: '', from: 'bob@example.test', to: ['alice@example.test'], minutes: 5);
      final c = h(3, subject: 'Fwd: [list]', from: 'alice@example.test', to: ['bob@example.test'], minutes: 6);
      expect(buildThreads([a, b, c]), hasLength(3));
    });

    test('header-less message can join a header-linked thread by subject', () {
      final a = h(1, subject: 'Plan', from: 'alice@example.test', to: ['bob@example.test']);
      final b = h(2, irt: '<m1@example.test>', subject: 'Re: Plan', from: 'bob@example.test', to: ['alice@example.test'], minutes: 5);
      final c = h(3, subject: 'Re: Plan', from: 'alice@example.test', to: ['bob@example.test'], minutes: 9); // e.g. sent from a broken client
      final threads = buildThreads([a, b, c]);
      expect(threads, hasLength(1));
      expect(uids(threads.single), [1, 2, 3]);
    });

    test('singletons stay threads of one; sorted by latest activity, stable across input order', () {
      final a = h(1, subject: 'Old', minutes: 0);
      final b = h(2, subject: 'Thread', minutes: 10);
      final c = h(3, irt: '<m2@example.test>', subject: 'Re: Thread', minutes: 50, from: 'bob@example.test');
      final d = h(4, subject: 'Newer single', minutes: 40);
      final t1 = buildThreads([a, b, c, d]);
      final t2 = buildThreads([d, c, b, a]);
      expect(t1.map((t) => t.id).toList(), ['hash-2', 'hash-4', 'hash-1']);
      expect(t2.map((t) => t.id).toList(), t1.map((t) => t.id).toList());
      expect(t1.map(uids).toList(), t2.map(uids).toList());
      expect(t1.every((t) => t.isSingle || t.id == 'hash-2'), isTrue);
    });

    test('messages without a Message-ID are keyed by hash and still thread', () {
      final a = h(1, mid: '<root@example.test>', subject: 'X');
      final b = MessageHeader(
        accountId: 'a',
        folderPath: 'INBOX',
        uid: 2,
        uidValidity: 1,
        messageIdHash: 'hash-2',
        subject: 'Re: X',
        from: const MailAddress('bob@example.test'),
        date: _t0.add(const Duration(minutes: 1)),
        references: const ['<root@example.test>'],
      );
      expect(buildThreads([a, b]), hasLength(1));
      expect(buildThreads([]), isEmpty);
    });
  });

  test('normalizeSubject strips reply/forward prefixes and list tags', () {
    expect(normalizeSubject('Re: Hello'), 'hello');
    expect(normalizeSubject('RE: FW: Fwd: AW: Hello  world '), 'hello world');
    expect(normalizeSubject('[dev-list] Re: Hello'), 'hello');
    expect(normalizeSubject('Re[2]: Hello'), 'hello');
    expect(normalizeSubject('Re:'), '');
    expect(normalizeSubject('Rehearsal tonight'), 'rehearsal tonight');
    expect(normalizeSubject('Fwd'), 'fwd');
  });

  test('participantSummary lists senders oldest-first with "you" last', () {
    final a = h(1, from: 'alice@example.test', to: ['me@example.test']);
    final b = h(2, irt: '<m1@example.test>', from: 'me@example.test', to: ['alice@example.test'], minutes: 1);
    final c = h(3, irt: '<m1@example.test>', from: 'bob@example.test', minutes: 2);
    final t = buildThreads([a, b, c]).single;
    expect(participantSummary(t, ownAddresses: {'me@example.test'}), 'alice, bob, you');
    expect(participantSummary(t), 'alice, me, bob');
    final many = buildThreads([a, c, h(4, irt: '<m1@example.test>', from: 'carol@example.test', minutes: 3), h(5, irt: '<m1@example.test>', from: 'dan@example.test', minutes: 4)]).single;
    expect(participantSummary(many), 'alice, bob, carol, +1');
  });
}

void subjectFallbackTests() {
  group('subject fallback', () {
    test('recurring mail with the same subject and sender is not one thread', () {
      final a = h(1, subject: 'Form Submission - Contact Us', from: 'form@squarespace.test', minutes: 0);
      final b = h(2, subject: 'Form Submission - Contact Us', from: 'form@squarespace.test', minutes: 60 * 24 * 90);
      final c = h(3, subject: 'Form Submission - Contact Us', from: 'form@squarespace.test', minutes: 60 * 24 * 180);
      expect(buildThreads([a, b, c]).length, 3);
    });
    test('a header-less reply joins a recent conversation, not one from months ago', () {
      final first = h(1, subject: 'Internet issues', from: 'janie@icloud.test', minutes: 0);
      final soon = h(2, subject: 'Re: Internet issues', from: 'janie@icloud.test', minutes: 60 * 24 * 3, irt: '<lost@x>');
      final late = h(3, subject: 'Re: Internet issues', from: 'janie@icloud.test', minutes: 60 * 24 * 120, irt: '<lost2@x>');
      final threads = buildThreads([first, soon, late]);
      expect(threads.length, 2);
      expect(threads.firstWhere((t) => t.contains(first)).messages.length, 2, reason: 'the reply three days later belongs');
      expect(threads.firstWhere((t) => t.contains(late)).isSingle, isTrue, reason: 'four months later is a new conversation');
    });
    test('replies to different submissions do not chain into one thread', () {
      final replies = [
        h(10, subject: 'Re: Form Submission - Contact Us', from: 'me@example.test', to: const ['a@x.test'], minutes: 0),
        h(11, subject: 'Re: Form Submission - Contact Us', from: 'me@example.test', to: const ['b@x.test'], minutes: 60 * 24 * 100),
        h(12, subject: 'Re: Form Submission - Contact Us', from: 'me@example.test', to: const ['c@x.test'], minutes: 60 * 24 * 200),
      ];
      expect(buildThreads(replies, ownAddresses: {'me@example.test'}).length, 3);
    });
  });
}

void sentMergeTests() {
  group('buildThreadsWithSent', () {
    MessageHeader sent(int uid, {String? irt, String subject = 'Re: Subject', String to = 'alice@example.test'}) => MessageHeader(
          accountId: 'a',
          folderPath: 'Sent',
          uid: uid,
          uidValidity: 1,
          messageIdHash: 'sent-$uid',
          messageId: '<s$uid@example.test>',
          inReplyTo: irt,
          subject: subject,
          from: const MailAddress('me@example.test', 'Me'),
          to: [MailAddress(to)],
          // Replies come after the inbox mail they answer.
          date: DateTime.utc(2030, 1, 1, 0, uid),
          flags: const {r'\Seen'},
        );

    test('my reply joins the inbox thread through In-Reply-To and the folder stays the source of truth', () {
      final inbox = [h(1, minutes: 0), h(2, irt: '<m1@example.test>', minutes: 1, subject: 'Re: Subject')];
      final reply = sent(10, irt: '<m2@example.test>');
      final unrelated = sent(11, subject: 'Lunch?', to: 'bob@example.test');
      final threads = buildThreadsWithSent(inbox, [reply, unrelated], ownAddresses: {'me@example.test'});
      expect(threads.length, 1, reason: 'the Sent-only conversation is not shown in the inbox');
      final t = threads.single;
      expect(t.messages.map((m) => m.folderPath), ['INBOX', 'INBOX', 'Sent']);
      expect(t.latest.messageIdHash, 'sent-10');
      expect(participantSummary(t, ownAddresses: {'me@example.test'}), 'alice, you');
    });

    test('without Sent mail the threads are unchanged', () {
      final inbox = [h(1), h(2, irt: '<m1@example.test>', minutes: 1)];
      expect(buildThreadsWithSent(inbox, const []).single.messages.length, 2);
    });
  });

  test('a Message-ID folded in the middle still threads and never leaks a fragment into another thread', () {
    // Outlook ids are long; a client that folds the header inside the id
    // leaves "nampr d13" after unfolding. The fragment must not become an
    // id of its own, or two unrelated tickets from the same tenant merge.
    const idA = '<IA3PR13MB9943422F9C9F110BF028AD7D1CB4652@IA3PR13MB994342.namprd13.prod.outlook.com>';
    const idB = '<MWHPR1301MB2160265CBB877CB093E1FEB7BB672@MWHPR1301MB2160.namprd13.prod.outlook.com>';
    final ticketA = h(1, mid: idA, subject: 'RE: AXOS plugin', from: 'sdp@innovsys.test');
    final replyA = h(2, mid: '<r1@me.test>', irt: idA.replaceFirst('namprd13', 'nampr d13'), refs: [idA.replaceFirst('namprd13', 'namprd 13')], subject: 'RE: AXOS plugin', from: 'me@example.test', to: ['sdp@innovsys.test'], minutes: 10);
    final ticketB = h(3, mid: idB, subject: 'Re: Calix plugin', from: 'aaron@innovsys.test', minutes: 20);
    final replyB = h(4, mid: '<r2@me.test>', irt: idB, refs: ['<x@y.test> ${idB.replaceFirst('namprd13', 'nampr d13')}'], subject: 'Re: Calix plugin', from: 'me@example.test', to: ['aaron@innovsys.test'], minutes: 30);
    final threads = buildThreads([ticketA, replyA, ticketB, replyB], ownAddresses: {'me@example.test'});
    expect(threads.length, 2);
    expect(threads.map((t) => t.messages.map((m) => m.uid).toList()).toSet(), {[1, 2], [3, 4]});
    expect(messageIdsIn('<a@b.test>\r\n <c@d.te st>').toList(), ['a@b.test', 'c@d.test']);
    expect(messageIdsIn('a@b.test c@d.test').toList(), ['a@b.test', 'c@d.test']);
  });
}
