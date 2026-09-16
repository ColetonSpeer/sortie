import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import '../../core/clock.dart';
import '../../domain/entities/entities.dart';
import '../mail/imap_gateway.dart';
import 'control_folder.dart';

/// [ControlFolder] over one dedicated [ImapGateway] connection.
///
/// The gateway is connected lazily by [ensureExists] and kept selected on the
/// control folder. Every append goes without a date argument so the server
/// stamps INTERNALDATE, which is then fetched back (the caller feeds it to
/// its `ServerClock`).
class ImapControlFolder implements ControlFolder {
  ImapControlFolder({
    required ImapGateway gateway,
    required Account account,
    required String password,
    required Clock clock,
    this.folderName = Folder.controlFolderName,
    this.idleReissue = const Duration(minutes: 25),
    this.pollFallback = const Duration(minutes: 5),
  })  : _gw = gateway,
        _account = account,
        _password = password,
        _clock = clock;

  static final _log = Logger('sortie.coordination.controlFolder');
  static const headerNames = [
    'message-id',
    'x-sortie-version',
    'x-sortie-type',
    'x-sortie-device',
    'x-sortie-seq',
    'x-sortie-epoch',
    'x-sortie-priority',
    'x-sortie-snapshot-upto',
  ];

  final ImapGateway _gw;
  final Account _account;
  final String _password;
  final Clock _clock;
  final String folderName;
  final Duration idleReissue;
  final Duration pollFallback;

  String? _path;
  int? _uidValidity;
  ImapCapabilities? _caps;
  bool _disposed = false;
  StreamController<void>? _changes;
  Completer<void>? _idleStop;
  Timer? _pollTimer;
  Timer? _reissueTimer;

  String? get path => _path;
  ImapCapabilities? get capabilities => _caps;
  ImapGateway get gateway => _gw;

  Future<void> _connect() async {
    if (_gw.isConnected) return;
    _caps = await _gw.connect(_account, _password);
    _path = null;
  }

  @override
  Future<String> ensureExists() async {
    await _connect();
    final folders = await _gw.listFolders();
    final existing = folders.where((f) => f.isControlFolder).toList();
    String path;
    if (existing.isNotEmpty) {
      path = existing.first.path;
    } else {
      path = await _create();
    }
    final sel = await _gw.select(path);
    _path = path;
    _uidValidity = sel.uidValidity;
    return path;
  }

  Future<String> _create() async {
    final delim = _gw.delimiter ?? '/';
    try {
      await _gw.createFolder(folderName);
      await _gw.unsubscribeFolder(folderName);
      return folderName;
    } on ImapGatewayException catch (e) {
      if (e.isConnectionLost) rethrow;
      _log.fine('CREATE $folderName at root failed ($e); trying under INBOX');
      final path = 'INBOX$delim$folderName';
      await _gw.createFolder(path);
      await _gw.unsubscribeFolder(path);
      return path;
    }
  }

  String get _selectedPath {
    final p = _path;
    if (p == null) throw const ImapGatewayException('control folder not selected');
    return p;
  }

  @override
  Future<int> uidValidity() async {
    // A fresh SELECT both detects deletion (NO) and UIDVALIDITY changes.
    final sel = await _gw.select(_selectedPath);
    _uidValidity = sel.uidValidity;
    return sel.uidValidity;
  }

  int? get lastKnownUidValidity => _uidValidity;

  // ---------------------------------------------------------------- append

  List<int> render(ControlMessageDraft d) {
    final short = d.deviceId.replaceAll('-', '');
    final shortId = short.length <= 12 ? short : short.substring(0, 12);
    final b = StringBuffer()
      ..write('From: Sortie <sortie@sortie.invalid>\r\n')
      ..write('To: Sortie <sortie@sortie.invalid>\r\n')
      ..write('Subject: [Sortie] ${d.type} $shortId\r\n')
      ..write('Message-ID: ${d.messageId}\r\n')
      ..write('Date: ${_rfc2822(_clock.now())}\r\n')
      ..write('MIME-Version: 1.0\r\n')
      ..write('Content-Type: application/json; charset=utf-8\r\n')
      ..write('Content-Transfer-Encoding: 8bit\r\n')
      ..write('X-Sortie-Version: 1\r\n')
      ..write('X-Sortie-Type: ${d.type}\r\n')
      ..write('X-Sortie-Device: ${d.deviceId}\r\n')
      ..write('X-Sortie-Seq: ${d.seq}\r\n');
    if (d.epoch != null) b.write('X-Sortie-Epoch: ${d.epoch}\r\n');
    if (d.priority != null) b.write('X-Sortie-Priority: ${d.priority}\r\n');
    if (d.snapshotUpto != null) b.write('X-Sortie-Snapshot-Upto: ${d.snapshotUpto}\r\n');
    b.write('\r\n');
    b.write(jsonEncode(d.body));
    b.write('\r\n');
    return utf8.encode(b.toString());
  }

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static String _rfc2822(DateTime t) {
    final u = t.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${_days[u.weekday - 1]}, ${two(u.day)} ${_months[u.month - 1]} ${u.year} ${two(u.hour)}:${two(u.minute)}:${two(u.second)} +0000';
  }

  @override
  Future<AppendedControlMessage> append(ControlMessageDraft draft) async {
    final path = _selectedPath;
    AppendResult? result;
    try {
      result = await _gw.append(path, render(draft), flags: {r'\Seen'});
    } on ImapGatewayException catch (e) {
      // Ambiguous: the server may have stored it. Message-ID is the
      // idempotency key, so look before re-appending (the caller retries).
      _log.fine('APPEND ${draft.messageId} failed ambiguously: $e');
      if (!_gw.isConnected) rethrow;
      final uid = await findByMessageId(draft.messageId);
      if (uid == null) rethrow;
      return _fetchAppended(uid);
    }
    final uid = result.uid ?? await findByMessageId(draft.messageId);
    if (uid == null) throw ImapGatewayException('appended ${draft.messageId} but cannot find it');
    return _fetchAppended(uid);
  }

  Future<AppendedControlMessage> _fetchAppended(int uid) async {
    final rows = await _gw.fetchRawHeaders(UidRange.single(uid), const ['message-id']);
    if (rows.isEmpty) throw ImapGatewayException('uid $uid vanished after APPEND');
    return AppendedControlMessage(uid: uid, internalDate: rows.first.internalDate);
  }

  // ----------------------------------------------------------------- fetch

  @override
  Future<List<ControlMessage>> fetchHeaders({int sinceUid = 1}) async {
    _selectedPath;
    final rows = await _gw.fetchRawHeaders(UidRange.since(sinceUid < 1 ? 1 : sinceUid), headerNames);
    final out = <ControlMessage>[];
    for (final r in rows) {
      final m = parse(r);
      if (m != null) out.add(m);
    }
    out.sort((a, b) => a.uid.compareTo(b.uid));
    return out;
  }

  /// Parses one raw header fetch; null for foreign mail in the folder.
  static ControlMessage? parse(RawMessage r) {
    final h = r.headers;
    final type = h['x-sortie-type']?.trim();
    final device = h['x-sortie-device']?.trim();
    if (type == null || type.isEmpty || device == null || device.isEmpty) return null;
    int? asInt(String? s) => s == null ? null : int.tryParse(s.trim());
    return ControlMessage(
      uid: r.uid,
      internalDate: r.internalDate,
      type: type,
      deviceId: device,
      messageId: (h['message-id'] ?? '').trim(),
      seq: asInt(h['x-sortie-seq']) ?? 0,
      epoch: asInt(h['x-sortie-epoch']),
      priority: asInt(h['x-sortie-priority']),
      snapshotUpto: asInt(h['x-sortie-snapshot-upto']),
    );
  }

  @override
  Future<Map<String, dynamic>?> fetchBody(int uid) async {
    _selectedPath;
    final text = await _gw.fetchTextBody(uid);
    if (text == null) return null;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const {};
    try {
      final v = jsonDecode(trimmed);
      return v is Map<String, dynamic> ? v : null;
    } on FormatException catch (e) {
      _log.warning('control uid $uid has a malformed body: $e');
      return null;
    }
  }

  @override
  Future<int?> findByMessageId(String messageId) async {
    _selectedPath;
    final uids = await _gw.searchByMessageId(messageId);
    if (uids.isEmpty) return null;
    return uids.reduce((a, b) => a < b ? a : b);
  }

  @override
  Future<void> expunge(Iterable<int> uids) async {
    final list = uids.toList()..sort();
    if (list.isEmpty) return;
    _selectedPath;
    await _gw.store(list, add: {r'\Deleted'});
    await _gw.expunge(list);
  }

  @override
  Future<void> noop() => _gw.noop();

  // --------------------------------------------------------------- changes

  @override
  Stream<void> changes() {
    final existing = _changes;
    if (existing != null) return existing.stream;
    final ctrl = StreamController<void>.broadcast(onCancel: _stopIdle);
    _changes = ctrl;
    _pollTimer = Timer.periodic(pollFallback, (_) {
      if (!ctrl.isClosed) ctrl.add(null);
    });
    _startIdle(ctrl);
    return ctrl.stream;
  }

  void _startIdle(StreamController<void> ctrl) {
    if (_disposed || ctrl.isClosed) return;
    final stop = Completer<void>();
    _idleStop = stop;
    Stream<MailboxEvent> events;
    try {
      _selectedPath;
      events = _gw.idle(stop: stop.future);
    } catch (e) {
      _fail(ctrl, e);
      return;
    }
    _reissueTimer?.cancel();
    _reissueTimer = Timer(idleReissue, () {
      if (!stop.isCompleted) stop.complete();
      _startIdle(ctrl);
    });
    events.listen(
      (e) {
        if (e is ConnectionLostEvent) {
          _fail(ctrl, e.error ?? const ImapGatewayException('connection lost', isConnectionLost: true));
          return;
        }
        if (!ctrl.isClosed) ctrl.add(null);
      },
      onError: (Object e) => _fail(ctrl, e),
      cancelOnError: true,
    );
  }

  void _fail(StreamController<void> ctrl, Object e) {
    _reissueTimer?.cancel();
    _pollTimer?.cancel();
    if (!ctrl.isClosed) ctrl.addError(e);
  }

  Future<void> _stopIdle() async {
    _reissueTimer?.cancel();
    _pollTimer?.cancel();
    final s = _idleStop;
    if (s != null && !s.isCompleted) s.complete();
    _idleStop = null;
    final c = _changes;
    _changes = null;
    if (c != null && !c.isClosed) await c.close();
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _stopIdle();
    try {
      if (_gw.isConnected) await _gw.disconnect();
    } catch (_) {}
  }
}
