import 'dart:async';
import 'dart:convert';

import 'package:sortie/core/hashing.dart';
import 'package:sortie/data/mail/imap_gateway.dart';
import 'package:sortie/domain/entities/entities.dart';

/// Server-side clock with 1-second resolution, independent of device clocks.
class FakeServerClock {
  FakeServerClock([DateTime? start]) : _now = start ?? DateTime.utc(2026, 1, 1, 12);
  DateTime _now;
  DateTime now() => DateTime.utc(_now.year, _now.month, _now.day, _now.hour, _now.minute, _now.second);
  void advance(Duration d) => _now = _now.add(d);
}

class FakeStoredMessage {
  FakeStoredMessage({
    required this.uid,
    required this.internalDate,
    required this.raw,
    required this.headers,
    required this.header,
    this.body,
    Set<String>? flags,
  }) : flags = flags ?? {};
  final int uid;
  final DateTime internalDate;
  final List<int> raw;

  /// Lower-cased header name -> first value.
  final Map<String, String> headers;
  MessageHeader header;
  final MessageBody? body;
  final Set<String> flags;
  String get textBody {
    final s = utf8.decode(raw, allowMalformed: true);
    final i = s.indexOf('\r\n\r\n');
    final j = s.indexOf('\n\n');
    if (i >= 0) return s.substring(i + 4);
    if (j >= 0) return s.substring(j + 2);
    return body?.text ?? '';
  }
}

class FakeMailbox {
  FakeMailbox(this.path, {this.uidValidity = 1, this.specialUse = SpecialUse.none, this.subscribed = true});
  final String path;
  int uidValidity;
  int uidNext = 1;
  int modSeq = 1;
  final SpecialUse specialUse;
  bool subscribed;
  final messages = <int, FakeStoredMessage>{};
  List<int> get uids => messages.keys.toList()..sort();
}

/// In-memory IMAP server shared by any number of [FakeImapGateway]
/// connections. Fault injection for tests.
class FakeImapServer {
  FakeImapServer({FakeServerClock? clock, this.delimiter = '/', this.allowKeywords = true, this.supportsMove = true, this.supportsUidPlus = true, this.supportsCondStore = true, this.maxKeywords = 100})
      : clock = clock ?? FakeServerClock() {
    createMailbox('INBOX', specialUse: SpecialUse.inbox);
  }

  final FakeServerClock clock;
  final String delimiter;
  final bool allowKeywords;
  final bool supportsMove;
  final bool supportsUidPlus;
  final bool supportsCondStore;
  final int maxKeywords;
  final mailboxes = <String, FakeMailbox>{};
  final keywordsSeen = <String, Set<String>>{};
  final _events = StreamController<MailboxEvent>.broadcast();
  Stream<MailboxEvent> get events => _events.stream;

  /// Fault injection.
  bool refuseConnections = false;
  bool refuseAuth = false;
  int dropNextAppendResponses = 0;
  int commandsUntilDisconnect = -1;
  final commandLog = <String>[];
  final connections = <FakeImapGateway>{};

  FakeMailbox createMailbox(String path, {SpecialUse specialUse = SpecialUse.none, bool subscribed = true}) =>
      mailboxes.putIfAbsent(path, () => FakeMailbox(path, specialUse: specialUse, subscribed: subscribed, uidValidity: DateTime.now().microsecondsSinceEpoch % 1000000 + 1));

  void deleteMailbox(String path) {
    mailboxes.remove(path);
  }

  /// Simulates an external client / server changing UIDVALIDITY.
  void bumpUidValidity(String path) {
    final mb = mailboxes[path]!;
    mb.uidValidity += 1;
    final old = mb.messages.values.toList();
    mb.messages.clear();
    mb.uidNext = 1;
    for (final m in old) {
      final uid = mb.uidNext++;
      mb.messages[uid] = FakeStoredMessage(uid: uid, internalDate: m.internalDate, raw: m.raw, headers: m.headers, header: m.header.copyWith(uid: uid, uidValidity: mb.uidValidity), body: m.body, flags: m.flags);
    }
  }

  void _tick(String cmd) {
    commandLog.add(cmd);
    if (commandsUntilDisconnect > 0) commandsUntilDisconnect--;
  }

  /// Deliver a user-style message (as if from SMTP). Returns UID.
  int deliver(String path, MessageHeader header, {MessageBody? body, Set<String>? flags, DateTime? internalDate}) {
    final mb = mailboxes[path] ?? createMailbox(path);
    final uid = mb.uidNext++;
    mb.modSeq++;
    final idate = internalDate ?? clock.now();
    final raw = utf8.encode('From: ${header.from ?? ''}\r\nSubject: ${header.subject}\r\nMessage-ID: ${header.messageId ?? '<${header.messageIdHash}@fake>'}\r\nDate: ${header.date.toUtc()}\r\n\r\n${body?.text ?? ''}');
    final stored = FakeStoredMessage(
      uid: uid,
      internalDate: idate,
      raw: raw,
      headers: {'message-id': header.messageId ?? '<${header.messageIdHash}@fake>', 'subject': header.subject},
      header: header.copyWith(uid: uid, uidValidity: mb.uidValidity, folderPath: path, flags: {...header.flags, ...?flags}),
      body: body,
      flags: {...header.flags, ...?flags},
    );
    mb.messages[uid] = stored;
    _events.add(NewMessagesEvent(path, mb.messages.length));
    return uid;
  }

  /// External client moves a message (e.g. Thunderbird).
  void externalMove(String from, int uid, String to) {
    final src = mailboxes[from]!;
    final m = src.messages.remove(uid);
    if (m == null) return;
    _events.add(ExpungeEvent(from, uids: [uid]));
    final dst = mailboxes[to] ?? createMailbox(to);
    final nuid = dst.uidNext++;
    dst.messages[nuid] = FakeStoredMessage(uid: nuid, internalDate: m.internalDate, raw: m.raw, headers: m.headers, header: m.header.copyWith(uid: nuid, uidValidity: dst.uidValidity, folderPath: to), body: m.body, flags: m.flags);
    _events.add(NewMessagesEvent(to, dst.messages.length));
  }

  void externalSetFlags(String path, int uid, {Set<String> add = const {}, Set<String> remove = const {}}) {
    final m = mailboxes[path]!.messages[uid]!;
    m.flags.addAll(add);
    m.flags.removeAll(remove);
    m.header = m.header.copyWith(flags: {...m.flags});
    mailboxes[path]!.modSeq++;
    _events.add(FlagsChangedEvent(path, uid, {...m.flags}));
  }

  void externalDelete(String path, int uid) {
    mailboxes[path]!.messages.remove(uid);
    _events.add(ExpungeEvent(path, uids: [uid]));
  }

  static Map<String, String> parseHeaders(List<int> raw) {
    final s = utf8.decode(raw, allowMalformed: true);
    var end = s.indexOf('\r\n\r\n');
    var sep = '\r\n';
    if (end < 0) {
      end = s.indexOf('\n\n');
      sep = '\n';
    }
    final headPart = end < 0 ? s : s.substring(0, end);
    final lines = headPart.split(sep);
    final out = <String, String>{};
    String? name;
    final buf = StringBuffer();
    void flush() {
      if (name != null) out.putIfAbsent(name.toLowerCase(), () => buf.toString().trim());
      buf.clear();
    }
    for (final l in lines) {
      if (l.startsWith(' ') || l.startsWith('\t')) {
        buf.write(' ${l.trim()}');
        continue;
      }
      flush();
      final i = l.indexOf(':');
      if (i <= 0) {
        name = null;
        continue;
      }
      name = l.substring(0, i);
      buf.write(l.substring(i + 1));
    }
    flush();
    return out;
  }
}

/// One connection to a [FakeImapServer].
class FakeImapGateway implements ImapGateway {
  FakeImapGateway(this.server, {this.name = 'conn'});
  final FakeImapServer server;
  final String name;
  bool _connected = false;
  String? _selected;

  FakeMailbox get _mb {
    final p = _selected;
    if (p == null) throw const ImapGatewayException('no mailbox selected');
    final mb = server.mailboxes[p];
    if (mb == null) throw ImapGatewayException('mailbox $p gone');
    return mb;
  }

  void _cmd(String c) {
    if (!_connected) throw const ImapGatewayException('not connected', isConnectionLost: true);
    server._tick('$name $c');
    if (server.commandsUntilDisconnect == 0) {
      server.commandsUntilDisconnect = -1;
      _connected = false;
      throw const ImapGatewayException('connection dropped', isConnectionLost: true);
    }
  }

  @override
  Future<ImapCapabilities> connect(Account account, String password) async {
    if (server.refuseConnections) throw const ImapGatewayException('refused', isConnectionLost: true);
    if (server.refuseAuth) throw const ImapGatewayException('auth failed', isAuthFailure: true);
    _connected = true;
    server.connections.add(this);
    return ImapCapabilities(idle: true, move: server.supportsMove, uidPlus: server.supportsUidPlus, condStore: server.supportsCondStore, qresync: false, specialUse: true, customKeywords: server.allowKeywords, raw: const ['IMAP4rev1', 'IDLE']);
  }

  @override
  bool get isConnected => _connected;

  @override
  Future<void> disconnect() async {
    _connected = false;
    _selected = null;
    server.connections.remove(this);
  }

  @override
  Future<void> noop() async => _cmd('NOOP');

  @override
  String? get delimiter => server.delimiter;

  @override
  Future<List<Folder>> listFolders() async {
    _cmd('LIST');
    return server.mailboxes.values
        .map((mb) => Folder(
              accountId: '',
              path: mb.path,
              name: mb.path.split(server.delimiter).last,
              delimiter: server.delimiter,
              specialUse: mb.specialUse,
              uidValidity: mb.uidValidity,
              uidNext: mb.uidNext,
              messageCount: mb.messages.length,
              unseenCount: mb.messages.values.where((m) => !m.flags.contains(r'\Seen')).length,
              subscribed: mb.subscribed,
            ))
        .toList();
  }

  @override
  Future<Folder> createFolder(String path) async {
    _cmd('CREATE $path');
    final mb = server.createMailbox(path);
    return Folder(accountId: '', path: path, name: path.split(server.delimiter).last, delimiter: server.delimiter, uidValidity: mb.uidValidity);
  }

  @override
  Future<void> unsubscribeFolder(String path) async {
    _cmd('UNSUBSCRIBE $path');
    server.mailboxes[path]?.subscribed = false;
  }

  @override
  Future<SelectResult> select(String path, {int? knownUidValidity, int? knownModSeq}) async {
    _cmd('SELECT $path');
    final mb = server.mailboxes[path];
    if (mb == null) throw ImapGatewayException('NO mailbox $path');
    _selected = path;
    return SelectResult(path: path, uidValidity: mb.uidValidity, uidNext: mb.uidNext, exists: mb.messages.length, highestModSeq: server.supportsCondStore ? mb.modSeq : null, permanentFlagsAllowKeywords: server.allowKeywords);
  }

  @override
  String? get selectedPath => _selected;

  @override
  Future<void> close() async {
    _cmd('CLOSE');
    _selected = null;
  }

  @override
  Stream<MailboxEvent> idle({required Future<void> stop}) {
    _cmd('IDLE');
    final path = _selected!;
    final ctrl = StreamController<MailboxEvent>();
    final sub = server.events.where((e) => e.path == path).listen(ctrl.add);
    // Not awaited: cancelling a broadcast subscription returns a root-zone
    // future that fakeAsync never drives, which would keep the stream open.
    stop.then((_) {
      unawaited(sub.cancel());
      unawaited(ctrl.close());
    });
    return ctrl.stream;
  }

  @override
  Stream<MailboxEvent> mailboxEvents() => server.events.where((e) => e.path == _selected);

  List<FakeStoredMessage> _inRange(UidRange r) {
    final mb = _mb;
    return mb.uids.where((u) => u >= r.from && (r.to == null || u <= r.to!)).map((u) => mb.messages[u]!).toList();
  }

  @override
  Future<List<MessageHeader>> fetchHeaders(UidRange range, {int? changedSince}) async {
    _cmd('UID FETCH $range');
    return _inRange(range).map((m) => m.header.copyWith(flags: {...m.flags})).toList();
  }

  @override
  Future<List<MessageHeader>> fetchHeadersByUids(List<int> uids) async {
    _cmd('UID FETCH ${uids.join(',')}');
    final mb = _mb;
    return uids.where(mb.messages.containsKey).map((u) => mb.messages[u]!.header.copyWith(flags: {...mb.messages[u]!.flags})).toList();
  }

  @override
  Future<Map<int, Set<String>>> fetchFlags(UidRange range, {int? changedSince}) async {
    _cmd('UID FETCH $range (FLAGS)');
    return {for (final m in _inRange(range)) m.uid: {...m.flags}};
  }

  @override
  Future<MessageBody> fetchBody(int uid) async {
    _cmd('UID FETCH $uid BODY');
    final m = _mb.messages[uid];
    if (m == null) throw ImapGatewayException('no uid $uid');
    return m.body ?? MessageBody(text: m.textBody);
  }

  @override
  Future<List<int>> fetchRaw(int uid) async {
    _cmd('UID FETCH $uid RFC822');
    return _mb.messages[uid]?.raw ?? (throw ImapGatewayException('no uid $uid'));
  }

  @override
  Future<List<int>> fetchAttachment(int uid, String partId) async => throw UnimplementedError();

  @override
  Future<List<int>> searchUids(String criteria) async {
    _cmd('UID SEARCH $criteria');
    return _mb.uids;
  }

  @override
  Future<List<int>> searchByMessageId(String messageId) async {
    _cmd('UID SEARCH HEADER Message-ID');
    final want = messageId.trim().toLowerCase();
    return _mb.messages.values.where((m) => (m.headers['message-id'] ?? m.header.messageId ?? '').trim().toLowerCase() == want).map((m) => m.uid).toList();
  }

  @override
  Future<List<int>> searchKeyword(String keyword) async {
    _cmd('UID SEARCH KEYWORD $keyword');
    return _mb.messages.values.where((m) => m.flags.contains(keyword)).map((m) => m.uid).toList();
  }

  @override
  Future<List<int>> allUids() async {
    _cmd('UID SEARCH ALL');
    return _mb.uids;
  }

  @override
  Future<void> store(List<int> uids, {Set<String> add = const {}, Set<String> remove = const {}}) async {
    _cmd('UID STORE ${uids.join(',')} +${add.join(' ')} -${remove.join(' ')}');
    final mb = _mb;
    final seen = server.keywordsSeen.putIfAbsent(mb.path, () => {});
    for (final k in add.where((f) => !f.startsWith(r'\'))) {
      if (!server.allowKeywords) continue;
      seen.add(k);
      if (seen.length > server.maxKeywords) throw const ImapGatewayException('NO too many keywords');
    }
    for (final u in uids) {
      final m = mb.messages[u];
      if (m == null) continue;
      m.flags.addAll(server.allowKeywords ? add : add.where((f) => f.startsWith(r'\')));
      m.flags.removeAll(remove);
      m.header = m.header.copyWith(flags: {...m.flags});
      mb.modSeq++;
      server._events.add(FlagsChangedEvent(mb.path, u, {...m.flags}));
    }
  }

  @override
  Future<MoveResult> move(List<int> uids, String destinationPath) async {
    _cmd('UID MOVE ${uids.join(',')} $destinationPath');
    final src = _mb;
    final dst = server.mailboxes[destinationPath];
    if (dst == null) throw ImapGatewayException('NO [TRYCREATE] $destinationPath');
    final mapping = <int, int>{};
    for (final u in uids) {
      final m = src.messages.remove(u);
      if (m == null) continue;
      final nuid = dst.uidNext++;
      dst.messages[nuid] = FakeStoredMessage(uid: nuid, internalDate: m.internalDate, raw: m.raw, headers: m.headers, header: m.header.copyWith(uid: nuid, uidValidity: dst.uidValidity, folderPath: destinationPath), body: m.body, flags: m.flags);
      mapping[u] = nuid;
      server._events.add(ExpungeEvent(src.path, uids: [u]));
    }
    if (mapping.isNotEmpty) server._events.add(NewMessagesEvent(destinationPath, dst.messages.length));
    return MoveResult(uidMapping: server.supportsUidPlus ? mapping : const {});
  }

  @override
  Future<void> expunge(List<int> uids) async {
    _cmd('UID EXPUNGE ${uids.join(',')}');
    final mb = _mb;
    for (final u in uids) {
      if (mb.messages.remove(u) != null) server._events.add(ExpungeEvent(mb.path, uids: [u]));
    }
  }

  @override
  Future<AppendResult> append(String path, List<int> raw, {Set<String> flags = const {}}) async {
    _cmd('APPEND $path');
    final mb = server.mailboxes[path];
    if (mb == null) throw ImapGatewayException('NO [TRYCREATE] $path');
    final headers = FakeImapServer.parseHeaders(raw);
    final uid = mb.uidNext++;
    final mid = headers['message-id'];
    final subject = headers['subject'] ?? '';
    final from = headers['from'];
    final date = DateTime.tryParse(headers['date'] ?? '') ?? server.clock.now();
    final hash = messageIdHash(messageId: mid, from: from, date: date, subject: subject);
    final header = MessageHeader(accountId: '', folderPath: path, uid: uid, uidValidity: mb.uidValidity, messageIdHash: hash, messageId: mid, subject: subject, from: from == null ? null : MailAddress(from), date: date, flags: {...flags}, internalDate: server.clock.now());
    mb.messages[uid] = FakeStoredMessage(uid: uid, internalDate: server.clock.now(), raw: raw, headers: headers, header: header, flags: {...flags});
    mb.modSeq++;
    server._events.add(NewMessagesEvent(path, mb.messages.length));
    if (server.dropNextAppendResponses > 0) {
      server.dropNextAppendResponses--;
      throw const ImapGatewayException('response lost', isConnectionLost: true);
    }
    return AppendResult(uid: server.supportsUidPlus ? uid : null, uidValidity: mb.uidValidity);
  }

  @override
  Future<List<RawMessage>> fetchRawHeaders(UidRange range, List<String> headerNames) async {
    _cmd('UID FETCH $range (INTERNALDATE FLAGS HEADER.FIELDS)');
    final want = headerNames.map((h) => h.toLowerCase()).toSet();
    return _inRange(range).map((m) => RawMessage(uid: m.uid, internalDate: m.internalDate, flags: {...m.flags}, headers: {for (final e in m.headers.entries) if (want.isEmpty || want.contains(e.key)) e.key: e.value})).toList();
  }

  @override
  Future<String?> fetchTextBody(int uid) async {
    _cmd('UID FETCH $uid BODY[TEXT]');
    return _mb.messages[uid]?.textBody;
  }
}
