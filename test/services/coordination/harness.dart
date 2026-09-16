import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/core/clock.dart';
import 'package:sortie/core/hashing.dart';
import 'package:sortie/data/coordination/control_folder.dart';
import 'package:sortie/data/coordination/imap_control_folder.dart';
import 'package:sortie/data/local/database.dart' show SortieDatabase;
import 'package:sortie/data/mail/imap_gateway.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/domain/services/services.dart';
import 'package:sortie/services/coordination/coordination_service.dart';

import '../../fakes/fake_classifier.dart';
import '../../fakes/fake_coordination_repos.dart';
import '../../fakes/fake_imap_server.dart';
import '../../fakes/fake_sync_service.dart';

const accountId = 'acct-1';
const account = Account(
  id: accountId,
  displayName: 'Test',
  email: 'me@example.test',
  username: 'me',
  imap: ImapEndpoint(host: 'imap.example.test', port: 993, security: ConnectionSecurity.tls),
  smtp: SmtpEndpoint(host: 'smtp.example.test', port: 465, security: ConnectionSecurity.tls),
);

/// Monotonic time follows [FakeAsync.elapsed]; wall time adds a fixed skew
/// so devices can disagree wildly about the date.
class FakeAsyncClock extends Clock {
  FakeAsyncClock(this._fa, {this.skew = Duration.zero, DateTime? base}) : _base = base ?? DateTime.utc(2026, 1, 1, 12);
  final FakeAsync _fa;
  final Duration skew;
  final DateTime _base;

  @override
  DateTime now() => _base.add(_fa.elapsed).add(skew);
  @override
  Duration monotonic() => _fa.elapsed;
}

class Device {
  Device({required this.identity, required this.db, required this.repo, required this.settings, required this.classifier, required this.sync, required this.service, required this.clock});
  final DeviceIdentity identity;
  final SortieDatabase db;
  final MemoryMessageRepository repo;
  final MemorySettingsRepository settings;
  final ScriptedClassifier classifier;
  final CoordFakeSyncService sync;
  final CoordinationService service;
  final FakeAsyncClock clock;

  String get id => identity.deviceId;
  CoordinationState get state => service.currentState;
  bool get isLeader => state == CoordinationState.leader;

  Future<Map<MessageKey, PendingBadge>> pending() => service.watchPending().first;
  Future<List<SortLogEntry>> log() => service.watchLog().first;
}

class Harness {
  Harness(this.fa, {FakeImapServer? server, this.timers = const LeaseTimers(), this.config = const SortConfig(mode: SortingMode.auto)})
      : server = server ?? FakeImapServer();

  final FakeAsync fa;
  final FakeImapServer server;
  final LeaseTimers timers;
  final SortConfig config;
  final devices = <Device>[];

  /// Device ids are padded to 16 chars so [DeviceIdentity.shortId] works;
  /// lexical order of short names is preserved.
  static String idOf(String short) => short.padRight(16, '0');

  static DeviceIdentity identity(String id, {int priority = LeaderPriority.desktop, DevicePlatform platform = DevicePlatform.linux}) =>
      DeviceIdentity(deviceId: idOf(id), displayName: 'Device $id', platform: platform, priority: priority);

  Device addDevice(
    String id, {
    int priority = LeaderPriority.desktop,
    DevicePlatform platform = DevicePlatform.linux,
    Duration skew = Duration.zero,
    bool Function()? mayLead,
    LeaseTimers? timers,
    SortConfig? config,
    ScriptedClassifier? classifier,
  }) {
    final clock = FakeAsyncClock(fa, skew: skew);
    final db = SortieDatabase(NativeDatabase.memory());
    final repo = MemoryMessageRepository();
    final settings = MemorySettingsRepository(sortConfig: config ?? this.config);
    final cls = classifier ?? ScriptedClassifier();
    final sync = CoordFakeSyncService(server: server, repo: repo, name: id);
    final me = identity(id, priority: priority, platform: platform);
    final service = CoordinationService(
      accountId: accountId,
      me: me,
      gatewayFactory: sync.gatewayFactory(accountId),
      password: () => sync.password(accountId),
      account: () => account,
      sync: sync,
      classifier: cls,
      messages: repo,
      settings: settings,
      db: db,
      clock: clock,
      timers: timers ?? this.timers,
      mayLead: mayLead,
    );
    final d = Device(identity: me, db: db, repo: repo, settings: settings, classifier: cls, sync: sync, service: service, clock: clock);
    devices.add(d);
    return d;
  }

  /// Advances fake time in 1 s steps, keeping the server clock in step.
  void elapse(Duration d, {Duration step = const Duration(seconds: 1)}) {
    var left = d;
    while (left > Duration.zero) {
      final s = left < step ? left : step;
      server.clock.advance(s);
      fa.elapse(s);
      left -= s;
    }
  }

  /// Lets pending async work settle without moving the server clock much.
  void settle([int ms = 50]) => fa.elapse(Duration(milliseconds: ms));

  /// Resolves a future synchronously under fakeAsync.
  T wait<T>(Future<T> f, {Duration timeout = const Duration(seconds: 5)}) {
    T? out;
    var done = false;
    Object? err;
    f.then((v) {
      out = v;
      done = true;
    }, onError: (Object e) {
      err = e;
      done = true;
    });
    var waited = Duration.zero;
    while (!done && waited < timeout) {
      fa.elapse(const Duration(milliseconds: 10));
      waited += const Duration(milliseconds: 10);
    }
    if (err != null) throw err!;
    if (!done) throw StateError('future did not complete within $timeout');
    return out as T;
  }

  void startAll() {
    for (final d in devices) {
      d.service.start();
    }
  }

  Future<void> disposeAll() async {
    for (final d in devices) {
      await d.service.stop(graceful: false);
      await d.db.close();
    }
  }

  // ------------------------------------------------------------- messages

  int _n = 0;

  MessageHeader header(String subject, {String from = 'sender@example.test', String? messageId, Set<String> flags = const {}, String? listId}) {
    final mid = messageId ?? '<msg-${++_n}@example.test>';
    return MessageHeader(
      accountId: accountId,
      folderPath: 'INBOX',
      uid: 0,
      uidValidity: 1,
      messageIdHash: messageIdHash(messageId: mid),
      messageId: mid,
      subject: subject,
      from: MailAddress(from),
      date: DateTime.utc(2026, 1, 1),
      flags: flags,
      listId: listId,
    );
  }

  /// Delivers to the server INBOX and tells every device's sync layer.
  MessageHeader deliver(String subject, {String from = 'sender@example.test', Set<String> flags = const {}, String? listId, Iterable<Device>? notify}) {
    final uid = server.deliver('INBOX', header(subject, from: from, flags: flags, listId: listId));
    final stored = server.mailboxes['INBOX']!.messages[uid]!.header.copyWith(flags: {...server.mailboxes['INBOX']!.messages[uid]!.flags});
    final h = MessageHeader(
      accountId: accountId,
      folderPath: 'INBOX',
      uid: uid,
      uidValidity: stored.uidValidity,
      messageIdHash: stored.messageIdHash,
      messageId: stored.messageId,
      subject: stored.subject,
      from: stored.from,
      date: stored.date,
      flags: stored.flags,
      listId: stored.listId,
    );
    for (final d in notify ?? devices) {
      d.repo.upsertHeaders([h]);
      d.sync.emitNew(accountId, [h]);
    }
    return h;
  }

  /// Marks `\Seen` on the server and reports the flag change to devices.
  void markSeen(MessageHeader h, {bool seen = true}) {
    server.externalSetFlags('INBOX', h.uid, add: seen ? {r'\Seen'} : {}, remove: seen ? {} : {r'\Seen'});
    final flags = {...server.mailboxes['INBOX']!.messages[h.uid]!.flags};
    final updated = h.copyWith(flags: flags);
    for (final d in devices) {
      d.repo.upsertHeaders([updated]);
      d.sync.emitFlags(accountId, updated, d.clock.now());
    }
  }

  /// Another client moves the message; the sync layers notice.
  void externalMove(MessageHeader h, String to) {
    server.externalMove('INBOX', h.uid, to);
    for (final d in devices) {
      d.repo.moveLocally(accountId, 'INBOX', [h.uid], to);
    }
  }

  Set<String> flagsOf(String folder, MessageHeader h) {
    for (final m in server.mailboxes[folder]?.messages.values ?? const <FakeStoredMessage>[]) {
      if (m.header.messageIdHash == h.messageIdHash) return {...m.flags};
    }
    return const {};
  }

  String? folderOf(MessageHeader h) {
    for (final mb in server.mailboxes.values) {
      if (mb.messages.values.any((m) => m.header.messageIdHash == h.messageIdHash)) return mb.path;
    }
    return null;
  }

  // -------------------------------------------------------- control folder

  FakeMailbox? get controlBox => server.mailboxes['Sortie'] ?? server.mailboxes['INBOX/Sortie'];

  List<ControlMessage> controlMessages() {
    final mb = controlBox;
    if (mb == null) return const [];
    return [
      for (final m in mb.messages.values)
        if (ImapControlFolder.parse(RawMessage(uid: m.uid, internalDate: m.internalDate, flags: m.flags, headers: m.headers)) case final c?) c,
    ]..sort((a, b) => a.uid.compareTo(b.uid));
  }

  List<ControlMessage> ofType(String type) => controlMessages().where((m) => m.type == type).toList();

  Iterable<String> commands(String pattern) => server.commandLog.where((c) => c.contains(pattern));
  int countCommands(String pattern) => commands(pattern).length;

  /// A raw control-folder connection for planting records by hand.
  Future<ImapControlFolder> rawControl(FakeAsyncClock clock) async {
    final f = ImapControlFolder(gateway: FakeImapGateway(server, name: 'raw'), account: account, password: 'x', clock: clock);
    await f.ensureExists();
    return f;
  }
}

/// Runs [body] inside fakeAsync with a harness, then disposes everything.
void coordinationTest(
  String name,
  void Function(Harness h) body, {
  FakeImapServer Function()? server,
  LeaseTimers timers = const LeaseTimers(),
  SortConfig config = const SortConfig(mode: SortingMode.auto),
}) {
  test(name, () {
    fakeAsync((fa) {
      final h = Harness(fa, server: server?.call(), timers: timers, config: config);
      body(h);
      h.disposeAll();
      h.settle(500);
    });
  });
}
