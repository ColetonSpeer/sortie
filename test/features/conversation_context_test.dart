import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/core/hashing.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/features/compose/compose_backend.dart';
import 'package:sortie/features/compose/conversation_context.dart';

class _Backend implements ComposeBackend {
  final byId = <String, MessageHeader>{};
  final bodies = <String, String>{};

  @override
  Future<MessageHeader?> messageById(String accountId, String messageId) async => byId[messageId];
  @override
  Future<MessageBody> body(String accountId, String folderPath, int uid) async => MessageBody(text: bodies['$folderPath/$uid'] ?? '');

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

MessageHeader h(int uid, String mid, String from, {List<String> refs = const [], String folder = 'INBOX'}) => MessageHeader(
      accountId: 'a',
      folderPath: folder,
      uid: uid,
      uidValidity: 1,
      messageIdHash: messageIdHash(messageId: mid),
      messageId: mid,
      subject: 'Internet issues',
      from: MailAddress(from, from.split('@').first),
      date: DateTime.utc(2026, 10, 21, 10, uid),
      references: refs,
    );

void main() {
  test('gathers the replied-to message and the earlier thread, oldest first, without their quoted tails', () async {
    final b = _Backend();
    final first = h(1, '<m1@x>', 'janie@icloud.test');
    final mine = h(440, '<m2@x>', 'me@prizm.test', refs: ['<m1@x>'], folder: 'Sent');
    final latest = h(3, '<m3@x>', 'janie@icloud.test', refs: ['<m1@x>', '<m2@x>']);
    b.byId.addAll({'<m1@x>': first, '<m2@x>': mine});
    b.bodies['INBOX/1'] = 'My internet keeps dropping.';
    b.bodies['Sent/440'] = 'Sorry to hear that. Can we visit Thursday?\n\nOn Tue, janie wrote:\n> My internet keeps dropping.';
    b.bodies['INBOX/3'] = 'Thursday works, 2pm?\n\nOn Wed, me wrote:\n> Sorry to hear that. Can we visit Thursday?';
    final turns = await gatherConversation(b, latest);
    expect(turns.map((t) => t.from).toList(), ['janie <janie@icloud.test>', 'me <me@prizm.test>', 'janie <janie@icloud.test>']);
    expect(turns[1].text, 'Sorry to hear that. Can we visit Thursday?');
    expect(turns[2].text, 'Thursday works, 2pm?');
    expect(turns.last.date, latest.date);
  });

  test('a thread whose earlier messages are not cached still yields the replied-to message', () async {
    final b = _Backend();
    final latest = h(3, '<m3@x>', 'janie@icloud.test', refs: ['<gone@x>']);
    b.bodies['INBOX/3'] = 'Are you still coming?';
    final turns = await gatherConversation(b, latest);
    expect(turns.single.text, 'Are you still coming?');
  });
}
