import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:enough_mail/enough_mail.dart' as em;
import 'package:event_bus/event_bus.dart';
import 'package:logging/logging.dart';

import '../../../domain/entities/entities.dart';
import '../imap_gateway.dart';
import 'mime_mapper.dart';

/// [ImapGateway] over enough_mail's [em.ImapClient]. One instance is one
/// connection; create a new instance to reconnect.
class EnoughImapGateway implements ImapGateway {
  EnoughImapGateway({
    this.connectTimeout = const Duration(seconds: 20),
    this.responseTimeout = const Duration(seconds: 90),
    this.logName = 'imap',
    this.onBadCertificate,
    this.protocolLog = false,
  });

  final Duration connectTimeout;
  final Duration responseTimeout;
  final String logName;
  final bool Function(X509Certificate)? onBadCertificate;
  final bool protocolLog;
  final _log = Logger('sortie.imap');

  em.ImapClient? _client;
  ImapCapabilities _caps = const ImapCapabilities();
  String? _delimiter;
  String? _selected;
  int _selectedUidValidity = 0;
  bool _lost = false;
  StreamSubscription<em.ImapConnectionLostEvent>? _lostSub;

  em.ImapClient get _c {
    final c = _client;
    if (c == null || !c.isConnected || _lost) {
      throw const ImapGatewayException('not connected', isConnectionLost: true);
    }
    return c;
  }

  ImapCapabilities get capabilities => _caps;

  // ---------------------------------------------------------------- session

  @override
  Future<ImapCapabilities> connect(Account account, String password) async {
    final client = em.ImapClient(
      bus: EventBus(sync: true),
      logName: logName,
      isLogEnabled: protocolLog,
      defaultResponseTimeout: responseTimeout,
      onBadCertificate: onBadCertificate,
    );
    _client = client;
    _lost = false;
    _lostSub = client.eventBus.on<em.ImapConnectionLostEvent>().listen((_) => _lost = true);
    final ep = account.imap;
    try {
      await client.connectToServer(ep.host, ep.port, isSecure: ep.security == ConnectionSecurity.tls, timeout: connectTimeout);
      if (ep.security == ConnectionSecurity.starttls) {
        await client.startTls();
      }
    } catch (e) {
      throw ImapGatewayException('connect to ${ep.host}:${ep.port} failed: ${_short(e)}', isConnectionLost: true, cause: e);
    }
    try {
      await client.login(account.username, password);
    } catch (e) {
      final text = _short(e);
      final auth = !_looksLikeConnectionLoss(e, client);
      throw ImapGatewayException('login failed: $text', isAuthFailure: auth, isConnectionLost: !auth, cause: e);
    }
    return _guard(() async {
      var caps = client.serverInfo.capabilities;
      if (caps == null || caps.isEmpty) caps = await client.capability();
      final names = caps.map((c) => c.name).toList();
      var enabledQresync = false;
      var enabledCondStore = false;
      // QRESYNC is deliberately NOT enabled: once it is on, servers emit
      // `* VANISHED` after UID MOVE/EXPUNGE and enough_mail's response parser
      // drops the COPYUID (and other) result codes when it sees them. The
      // folder synchronizer falls back to UID SEARCH diffs for deletions.
      // (QRESYNC support remains in select(); `enabledQresync` stays false.)
      if (!enabledCondStore && names.contains('CONDSTORE')) {
        try {
          await client.enable(['CONDSTORE']);
          enabledCondStore = true;
        } catch (e) {
          _log.fine('ENABLE CONDSTORE refused: ${_short(e)}');
        }
      }
      _caps = ImapCapabilities(
        idle: names.contains('IDLE'),
        move: names.contains('MOVE'),
        uidPlus: names.contains('UIDPLUS'),
        condStore: enabledCondStore,
        qresync: enabledQresync,
        specialUse: names.contains('SPECIAL-USE'),
        raw: names,
      );
      return _caps;
    });
  }

  @override
  bool get isConnected => !_lost && (_client?.isConnected ?? false);

  @override
  Future<void> disconnect() async {
    final c = _client;
    _client = null;
    _selected = null;
    await _lostSub?.cancel();
    _lostSub = null;
    if (c == null) return;
    try {
      if (c.isConnected && c.isLoggedIn) {
        await c.logout().timeout(const Duration(seconds: 5));
      }
    } catch (_) {
      // best effort
    }
    try {
      await c.disconnect();
    } catch (_) {}
  }

  @override
  Future<void> noop() => _guard(() async {
        await _c.noop();
      });

  // ---------------------------------------------------------------- folders

  @override
  String? get delimiter => _delimiter;

  @override
  Future<List<Folder>> listFolders() => _guard(() async {
        final c = _c;
        List<em.Mailbox> boxes;
        if (_caps.specialUse) {
          try {
            boxes = await c.listMailboxes(recursive: true, returnOptions: [em.ReturnOption.specialUse()]);
          } catch (e) {
            _log.fine('LIST RETURN (SPECIAL-USE) failed, plain LIST: ${_short(e)}');
            boxes = await c.listMailboxes(recursive: true);
          }
        } else {
          boxes = await c.listMailboxes(recursive: true);
        }
        _delimiter = c.serverInfo.pathSeparator ?? (boxes.isNotEmpty ? boxes.first.pathSeparator : '/');
        Set<String>? subscribed;
        try {
          subscribed = (await c.listSubscribedMailboxes(recursive: true)).map((b) => b.path).toSet();
        } catch (e) {
          _log.fine('LSUB failed: ${_short(e)}');
        }
        final usedSpecial = <SpecialUse>{};
        final out = <Folder>[];
        for (final b in boxes) {
          var special = _specialUseFromFlags(b);
          if (special == SpecialUse.none) {
            final guess = _specialUseFromName(b.name, b.path);
            if (guess != SpecialUse.none && !usedSpecial.contains(guess)) special = guess;
          }
          if (special != SpecialUse.none) usedSpecial.add(special);
          out.add(Folder(
            accountId: '',
            path: b.path,
            name: b.name,
            delimiter: b.pathSeparator,
            specialUse: special,
            uidValidity: b.uidValidity,
            uidNext: b.uidNext,
            messageCount: b.messagesExists,
            unseenCount: b.messagesUnseen,
            subscribed: subscribed == null || subscribed.contains(b.path) || b.isInbox,
            selectable: !b.isNotSelectable,
          ));
        }
        return out;
      });

  static SpecialUse _specialUseFromFlags(em.Mailbox b) {
    if (b.isInbox) return SpecialUse.inbox;
    if (b.isSent) return SpecialUse.sent;
    if (b.isDrafts) return SpecialUse.drafts;
    if (b.isTrash) return SpecialUse.trash;
    if (b.isJunk) return SpecialUse.junk;
    if (b.isArchive) return SpecialUse.archive;
    if (b.hasFlag(em.MailboxFlag.all)) return SpecialUse.all;
    if (b.hasFlag(em.MailboxFlag.flagged)) return SpecialUse.flagged;
    return SpecialUse.none;
  }

  static SpecialUse _specialUseFromName(String name, String path) {
    final n = name.toLowerCase().trim();
    if (path.toUpperCase() == 'INBOX') return SpecialUse.inbox;
    return switch (n) {
      'sent' || 'sent items' || 'sent mail' || 'sent messages' || 'outbox.sent' => SpecialUse.sent,
      'drafts' || 'draft' => SpecialUse.drafts,
      'trash' || 'deleted' || 'deleted items' || 'deleted messages' || 'bin' => SpecialUse.trash,
      'junk' || 'spam' || 'junk e-mail' || 'junk email' || 'bulk mail' => SpecialUse.junk,
      'archive' || 'archives' => SpecialUse.archive,
      'all mail' => SpecialUse.all,
      'starred' || 'flagged' => SpecialUse.flagged,
      _ => SpecialUse.none,
    };
  }

  @override
  Future<Folder> createFolder(String path) => _guard(() async {
        final b = await _c.createMailbox(path);
        _delimiter ??= b.pathSeparator;
        return Folder(accountId: '', path: b.path, name: b.name, delimiter: b.pathSeparator, uidValidity: b.uidValidity, uidNext: b.uidNext);
      });

  @override
  Future<void> unsubscribeFolder(String path) => _guard(() async {
        final sep = _delimiter ?? '/';
        final name = path.contains(sep) ? path.substring(path.lastIndexOf(sep) + 1) : path;
        await _c.unsubscribeMailbox(em.Mailbox(encodedName: name, encodedPath: path, flags: [], pathSeparator: sep));
      });

  // ---------------------------------------------------------------- select

  @override
  Future<SelectResult> select(String path, {int? knownUidValidity, int? knownModSeq}) => _guard(() async {
        final c = _c;
        final vanished = <int>[];
        final sub = c.eventBus.on<em.ImapVanishedEvent>().listen((e) {
          final seq = e.vanishedMessages;
          if (seq != null && seq.isUidSequence) vanished.addAll(seq.toList());
        });
        try {
          em.QResyncParameters? q;
          if (_caps.qresync && knownUidValidity != null && knownModSeq != null) {
            q = em.QResyncParameters(knownUidValidity, knownModSeq);
          }
          final box = await c.selectMailboxByPath(path, enableCondStore: _caps.condStore && q == null, qresync: q);
          _selected = path;
          _selectedUidValidity = box.uidValidity ?? 0;
          final permanent = box.permanentMessageFlags;
          final allowKeywords = permanent.isEmpty || permanent.contains(r'\*');
          if (permanent.isNotEmpty && !allowKeywords && _caps.customKeywords) _caps = _caps.copyWith(customKeywords: false);
          return SelectResult(
            path: path,
            uidValidity: box.uidValidity ?? 0,
            uidNext: box.uidNext ?? (box.messagesExists + 1),
            exists: box.messagesExists,
            highestModSeq: box.highestModSequence,
            permanentFlagsAllowKeywords: allowKeywords,
            vanishedUids: q == null || box.uidValidity != knownUidValidity ? const [] : vanished,
          );
        } finally {
          await sub.cancel();
        }
      });

  @override
  String? get selectedPath => _selected;

  @override
  Future<void> close() => _guard(() async {
        await _c.closeMailbox();
        _selected = null;
      });

  // ---------------------------------------------------------------- idle

  @override
  Stream<MailboxEvent> idle({required Future<void> stop}) {
    final path = _selected;
    final ctrl = StreamController<MailboxEvent>();
    if (path == null) {
      ctrl.addError(const ImapGatewayException('idle: no mailbox selected'));
      ctrl.close();
      return ctrl.stream;
    }
    late em.ImapClient c;
    try {
      c = _c;
    } on ImapGatewayException catch (e) {
      ctrl.add(ConnectionLostEvent(path, e));
      ctrl.close();
      return ctrl.stream;
    }
    final sub = c.eventBus.on<em.ImapEvent>().listen((e) {
      final mapped = _mapEvent(e, path);
      if (mapped != null && !ctrl.isClosed) ctrl.add(mapped);
    });
    var done = false;
    Future<void> finish() async {
      if (done) return;
      done = true;
      await sub.cancel();
      if (!ctrl.isClosed) await ctrl.close();
    }

    () async {
      try {
        await c.idleStart();
      } catch (e) {
        if (!ctrl.isClosed) ctrl.add(ConnectionLostEvent(path, e));
        await finish();
        return;
      }
      await stop;
      try {
        if (c.isConnected && !_lost) await c.idleDone().timeout(const Duration(seconds: 10));
      } catch (e) {
        _log.fine('idleDone failed: ${_short(e)}');
        if (!ctrl.isClosed) ctrl.add(ConnectionLostEvent(path, e));
      }
      await finish();
    }();
    return ctrl.stream;
  }

  @override
  Stream<MailboxEvent> mailboxEvents() {
    final c = _c;
    return c.eventBus.on<em.ImapEvent>().map((e) => _mapEvent(e, _selected ?? '')).where((e) => e != null).cast<MailboxEvent>();
  }

  MailboxEvent? _mapEvent(em.ImapEvent e, String path) {
    switch (e) {
      case em.ImapMessagesExistEvent():
        return NewMessagesEvent(path, e.newMessagesExists);
      case em.ImapExpungeEvent():
        return ExpungeEvent(path, sequenceNumbers: [e.messageSequenceId]);
      case em.ImapVanishedEvent():
        final seq = e.vanishedMessages;
        if (seq == null) return null;
        return seq.isUidSequence ? ExpungeEvent(path, uids: seq.toList()) : ExpungeEvent(path, sequenceNumbers: seq.toList());
      case em.ImapFetchEvent():
        return FlagsChangedEvent(path, e.message.uid, MimeMapper.flags(e.message));
      case em.ImapConnectionLostEvent():
        return ConnectionLostEvent(path);
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------- fetch

  static em.MessageSequence _seq(UidRange r) => r.to == null
      ? em.MessageSequence.fromRangeToLast(r.from, isUidSequence: true)
      : em.MessageSequence.fromRange(r.from, r.to!, isUidSequence: true);

  static em.MessageSequence _seqOf(List<int> uids) => em.MessageSequence.fromIds(uids, isUid: true);

  static final _headerDef = '(UID FLAGS ENVELOPE BODYSTRUCTURE RFC822.SIZE INTERNALDATE ${MimeMapper.headerFieldsClause()})';

  String get _path {
    final p = _selected;
    if (p == null) throw const ImapGatewayException('no mailbox selected');
    return p;
  }

  List<MessageHeader> _toHeaders(Iterable<em.MimeMessage> msgs, {int minUid = 0}) {
    final path = _path;
    final out = <MessageHeader>[];
    for (final m in msgs) {
      final uid = m.uid;
      if (uid == null || uid < minUid) continue;
      try {
        out.add(MimeMapper.headerFrom(m, accountId: '', folderPath: path, uidValidity: _selectedUidValidity));
      } catch (e) {
        _log.warning('skipping unparsable header uid=$uid: ${_short(e)}');
      }
    }
    return out;
  }

  @override
  Future<List<MessageHeader>> fetchHeaders(UidRange range, {int? changedSince}) => _guard(() async {
        final r = await _c.uidFetchMessages(_seq(range), _headerDef, changedSinceModSequence: changedSince);
        return _toHeaders(r.messages, minUid: range.from);
      });

  @override
  Future<List<MessageHeader>> fetchHeadersByUids(List<int> uids) => _guard(() async {
        if (uids.isEmpty) return <MessageHeader>[];
        final r = await _c.uidFetchMessages(_seqOf(uids), _headerDef);
        final want = uids.toSet();
        return _toHeaders(r.messages.where((m) => want.contains(m.uid)));
      });

  @override
  Future<Map<int, Set<String>>> fetchFlags(UidRange range, {int? changedSince}) => _guard(() async {
        final r = await _c.uidFetchMessages(_seq(range), '(UID FLAGS)', changedSinceModSequence: changedSince);
        return {
          for (final m in r.messages)
            if (m.uid != null && m.uid! >= range.from) m.uid!: MimeMapper.flags(m),
        };
      });

  Future<em.MimeMessage> _fetchFull(int uid) async {
    final r = await _c.uidFetchMessage(uid, '(UID BODY.PEEK[])');
    final m = r.messages.where((x) => x.uid == uid).firstOrNull ?? r.messages.firstOrNull;
    if (m == null) throw ImapGatewayException('uid $uid not found in $_path');
    return m;
  }

  @override
  Future<MessageBody> fetchBody(int uid) => _guard(() async => MimeMapper.bodyFrom(await _fetchFull(uid)));

  @override
  Future<List<int>> fetchRaw(int uid) => _guard(() async {
        final m = await _fetchFull(uid);
        final data = m.mimeData;
        if (data is em.BinaryMimeData) return data.data;
        if (data is em.TextMimeData) return latin1.encode(data.text);
        return utf8.encode(m.renderMessage());
      });

  @override
  Future<List<int>> fetchAttachment(int uid, String partId) => _guard(() async {
        final r = await _c.uidFetchMessage(uid, '(UID BODYSTRUCTURE BODY.PEEK[$partId])');
        final m = r.messages.firstOrNull;
        if (m == null) throw ImapGatewayException('uid $uid not found');
        final part = m.getPart(partId);
        final structure = m.body?.getChildPart(partId);
        final data = part?.mimeData;
        if (data == null) throw ImapGatewayException('part $partId of uid $uid not returned');
        final text = data is em.TextMimeData ? data.text : latin1.decode((data as em.BinaryMimeData).data);
        return em.MailCodec.decodeBinary(text, structure?.encoding);
      });

  @override
  Future<List<RawMessage>> fetchRawHeaders(UidRange range, List<String> headerNames) => _guard(() async {
        final clause = headerNames.isEmpty ? 'BODY.PEEK[HEADER]' : MimeMapper.headerFieldsClause(headerNames);
        final r = await _c.uidFetchMessages(_seq(range), '(UID INTERNALDATE FLAGS $clause)');
        final out = <RawMessage>[];
        for (final m in r.messages) {
          final uid = m.uid;
          if (uid == null || uid < range.from) continue;
          out.add(RawMessage(
            uid: uid,
            internalDate: MimeMapper.internalDate(m) ?? DateTime.now().toUtc(),
            flags: MimeMapper.flags(m),
            headers: MimeMapper.rawHeaders(m),
          ));
        }
        return out;
      });

  @override
  Future<String?> fetchTextBody(int uid) => _guard(() async {
        final m = await _fetchFull(uid);
        return m.decodeTextPlainPart() ?? m.decodeContentText();
      });

  // ---------------------------------------------------------------- search

  Future<List<int>> _search(String criteria) async {
    final r = await _c.uidSearchMessages(searchCriteria: criteria);
    final seq = r.matchingSequence;
    if (seq == null || seq.isNil || seq.isEmpty) return <int>[];
    return seq.toList()..sort();
  }

  @override
  Future<List<int>> searchUids(String criteria) => _guard(() => _search(criteria));

  @override
  Future<List<int>> searchByMessageId(String messageId) => _guard(() {
        final id = messageId.trim().replaceAll('"', '').replaceAll('\\', '');
        return _search('HEADER Message-ID "$id"');
      });

  @override
  Future<List<int>> searchKeyword(String keyword) => _guard(() => _search('KEYWORD $keyword'));

  @override
  Future<List<int>> allUids() => _guard(() => _search('ALL'));

  // ---------------------------------------------------------------- mutate

  @override
  Future<void> store(List<int> uids, {Set<String> add = const {}, Set<String> remove = const {}}) => _guard(() async {
        if (uids.isEmpty) return;
        final c = _c;
        if (add.isNotEmpty) await c.uidStore(_seqOf(uids), add.toList(), action: em.StoreAction.add, silent: true);
        if (remove.isNotEmpty) await c.uidStore(_seqOf(uids), remove.toList(), action: em.StoreAction.remove, silent: true);
      });

  static Map<int, int> _uidMapping(em.UidResponseCode? code) {
    if (code == null) return const {};
    final src = code.originalSequence?.toList() ?? const <int>[];
    final dst = code.targetSequence.toList();
    if (src.length != dst.length) return const {};
    return {for (var i = 0; i < src.length; i++) src[i]: dst[i]};
  }

  @override
  Future<MoveResult> move(List<int> uids, String destinationPath) => _guard(() async {
        if (uids.isEmpty) return const MoveResult();
        final c = _c;
        if (_caps.move) {
          final r = await c.uidMove(_seqOf(uids), targetMailboxPath: destinationPath);
          return MoveResult(uidMapping: _uidMapping(r.responseCodeCopyUid));
        }
        final r = await c.uidCopy(_seqOf(uids), targetMailboxPath: destinationPath);
        final mapping = _uidMapping(r.responseCodeCopyUid);
        await c.uidStore(_seqOf(uids), [r'\Deleted'], action: em.StoreAction.add, silent: true);
        if (_caps.uidPlus) {
          await c.uidExpunge(_seqOf(uids));
        } else {
          await c.expunge();
        }
        return MoveResult(uidMapping: mapping);
      });

  @override
  Future<void> expunge(List<int> uids) => _guard(() async {
        if (uids.isEmpty) return;
        final c = _c;
        await c.uidStore(_seqOf(uids), [r'\Deleted'], action: em.StoreAction.add, silent: true);
        if (_caps.uidPlus) {
          await c.uidExpunge(_seqOf(uids));
        } else {
          await c.expunge();
        }
      });

  @override
  Future<AppendResult> append(String path, List<int> raw, {Set<String> flags = const {}}) => _guard(() async {
        final text = utf8.decode(raw, allowMalformed: true);
        final r = await _c.appendMessageText(text, flags: flags.toList(), targetMailboxPath: path, responseTimeout: responseTimeout);
        final code = r.responseCodeAppendUid;
        final uids = code?.targetSequence.toList();
        return AppendResult(uid: uids == null || uids.isEmpty ? null : uids.first, uidValidity: code?.uidValidity);
      });

  // ---------------------------------------------------------------- errors

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on ImapGatewayException {
      rethrow;
    } catch (e, s) {
      final c = _client;
      final lost = c == null || _looksLikeConnectionLoss(e, c);
      final text = _short(e);
      final auth = RegExp(r'AUTHENTICATIONFAILED|AUTHORIZATIONFAILED|Authentication failed|Invalid credentials', caseSensitive: false).hasMatch(text);
      _log.fine('imap error (lost=$lost): $text', null, s);
      throw ImapGatewayException(text, isAuthFailure: auth, isConnectionLost: lost && !auth, cause: e);
    }
  }

  bool _looksLikeConnectionLoss(Object e, em.ImapClient c) {
    if (_lost || !c.isConnected) return true;
    if (e is SocketException || e is TimeoutException || e is HandshakeException || e is TlsException) return true;
    final t = e.toString();
    return t.contains('reconnect') || t.contains('connection lost') || t.contains('Socket') || t.contains('timed out');
  }

  static String _short(Object e) {
    var t = e is em.ImapException ? (e.message ?? e.toString()) : e.toString();
    // never leak credentials that might echo in a LOGIN failure
    t = t.replaceAll(RegExp(r'LOGIN\s+"[^"]*"\s+"[^"]*"'), 'LOGIN ****');
    return t.length > 300 ? '${t.substring(0, 300)}…' : t;
  }
}
