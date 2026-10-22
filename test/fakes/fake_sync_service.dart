import 'dart:async';

import 'package:sortie/data/mail/imap_gateway.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/domain/services/services.dart';

import 'fake_coordination_repos.dart';
import 'fake_imap_server.dart';

/// Minimal [MailSyncService] for coordination tests. Tests push headers
/// into [emitNew] / [emitFlags] as the real sync engine would after caching
/// them; [gatewayFactory] hands out connections to the shared fake server.
class CoordFakeSyncService implements MailSyncService {
  CoordFakeSyncService({required this.server, required this.repo, this.name = 'dev', this.secret = 'secret'});

  final FakeImapServer server;
  final MemoryMessageRepository repo;
  final String name;
  final String secret;
  final _new = <String, StreamController<List<MessageHeader>>>{};
  final _flags = <String, StreamController<FlagsObservation>>{};
  final moves = <(String, String, List<int>, String, String)>[];
  final flagCalls = <(String, String, List<int>, Set<String>, Set<String>)>[];
  int _conn = 0;

  StreamController<List<MessageHeader>> _newCtrl(String a) => _new.putIfAbsent(a, StreamController<List<MessageHeader>>.broadcast);
  StreamController<FlagsObservation> _flagCtrl(String a) => _flags.putIfAbsent(a, StreamController<FlagsObservation>.broadcast);

  void emitNew(String accountId, List<MessageHeader> headers) => _newCtrl(accountId).add(headers);
  void emitFlags(String accountId, MessageHeader header, DateTime observedAt) =>
      _flagCtrl(accountId).add(FlagsObservation(accountId: accountId, folderPath: header.folderPath, header: header, observedAt: observedAt));

  @override
  Stream<List<MessageHeader>> newInboxMessages(String accountId) => _newCtrl(accountId).stream;

  @override
  Stream<FlagsObservation> flagChanges(String accountId) => _flagCtrl(accountId).stream;

  @override
  ImapCapabilities? capabilities(String accountId) => ImapCapabilities(idle: true, move: true, uidPlus: true, customKeywords: server.allowKeywords);

  @override
  ImapGatewayFactory gatewayFactory(String accountId) => () => FakeImapGateway(server, name: '$name-c${++_conn}');

  @override
  Future<String> password(String accountId) async => secret;

  @override
  Future<void> move(String accountId, String fromFolder, List<int> uids, String toFolder, {String cause = 'manual'}) async =>
      moves.add((accountId, fromFolder, uids, toFolder, cause));

  @override
  Future<void> setFlags(String accountId, String folderPath, List<int> uids, {Set<String> add = const {}, Set<String> remove = const {}}) async =>
      flagCalls.add((accountId, folderPath, uids, add, remove));

  @override
  Future<void> markSeen(String accountId, String folderPath, int uid, {bool seen = true}) async {}
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> startAccount(String accountId) async {}
  @override
  Future<void> stopAccount(String accountId) async {}
  @override
  Stream<AccountSyncStatus> watchStatus(String accountId) => const Stream.empty();
  @override
  Stream<Map<String, AccountSyncStatus>> watchAllStatus() => const Stream.empty();
  @override
  Future<void> syncNow(String accountId, {String? folderPath}) async {}
  @override
  Future<void> refreshFolders(String accountId) async {}
  @override
  Future<void> createFolder(String accountId, String path) async => server.createMailbox(path);
  @override
  Future<void> delete(String accountId, String folderPath, List<int> uids, {bool permanent = false}) async {}
  @override
  Future<MessageBody> body(String accountId, String folderPath, int uid, {bool refresh = false}) async =>
      server.mailboxes[folderPath]?.messages[uid]?.body ?? const MessageBody(text: '');
  @override
  Future<List<int>> attachment(String accountId, String folderPath, int uid, String partId) async => const [];
  @override
  Future<List<int>> rawMessage(String accountId, String folderPath, int uid) async => const [];
  @override
  Future<void> saveDraft(String accountId, List<int> raw, {String? supersedesMessageId}) async {}

  @override
  Future<void> discardDraft(String accountId, String messageId) async {}
  @override
  Future<void> send(String accountId, String identityId, List<String> recipients, List<int> raw, {String? draftMessageId}) async {}
}
