import 'dart:async';

import 'package:logging/logging.dart';

import '../../core/clock.dart';
import '../../data/mail/imap_gateway.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/services.dart';
import 'backoff.dart';
import 'folder_synchronizer.dart';
import 'pending_op_executor.dart';

/// Timing knobs; tests shrink them.
class SyncTuning {
  const SyncTuning({
    this.idleRenew = const Duration(minutes: 25),
    this.keepalive = const Duration(minutes: 5),
    this.pollInterval = const Duration(seconds: 60),
    this.otherFoldersEvery = const Duration(minutes: 15),
    this.eventDebounce = const Duration(milliseconds: 300),
    this.authRetry = const Duration(minutes: 10),
    this.backoffMin = const Duration(seconds: 1),
    this.backoffMax = const Duration(seconds: 300),
  });
  final Duration idleRenew;
  final Duration keepalive;
  final Duration pollInterval;
  final Duration otherFoldersEvery;
  final Duration eventDebounce;
  final Duration authRetry;
  final Duration backoffMin;
  final Duration backoffMax;
}

class _Request {
  _Request(this.kind, [this.path]);
  final String kind; // sync | folders | drain | others
  final String? path;
  final completer = Completer<void>();
}

/// One account's connections and state machine:
/// connecting -> authenticating -> capabilityProbe -> foldersRefresh ->
/// selectingInbox -> idling, with backoff on failure. Two connections
/// (`idleConn` on INBOX IDLE, `cmdConn` for everything else); degrades to a
/// single polled connection when the second login is refused.
class AccountSyncSession {
  AccountSyncSession({
    required this.account,
    required Future<String> Function() password,
    required ImapGatewayFactory gatewayFactory,
    required this.folderSync,
    required this.executor,
    required this.folders,
    required this.messages,
    required this.clock,
    this.tuning = const SyncTuning(),
    Backoff? backoff,
    Logger? log,
  })  : _password = password,
        _factory = gatewayFactory,
        _backoff = backoff ?? Backoff(min: tuning.backoffMin, max: tuning.backoffMax),
        _log = log ?? Logger('sortie.sync.${account.id}');

  final Account account;
  final Future<String> Function() _password;
  final ImapGatewayFactory _factory;
  final FolderSynchronizer folderSync;
  final PendingOpExecutor executor;
  final FolderRepository folders;
  final MessageRepository messages;
  final Clock clock;
  final SyncTuning tuning;
  final Backoff _backoff;
  final Logger _log;

  final _status = StreamController<AccountSyncStatus>.broadcast();
  final _newInbox = StreamController<List<MessageHeader>>.broadcast();
  final _arrivals = StreamController<List<MessageHeader>>.broadcast();
  final _flags = StreamController<FlagsObservation>.broadcast();
  final _requests = <_Request>[];
  Completer<void> _wake = Completer<void>();
  Future<void> _cmdChain = Future.value();
  Future<void>? _runDone;
  bool _stopped = true;
  bool _degraded = false;
  ImapGateway? _cmd;
  ImapCapabilities? _caps;
  int _backfillRemaining = 0;
  /// Null until the first pass: Sent, Drafts and the rest are read right
  /// after start, then every [SyncTuning.otherFoldersEvery].
  Duration? _lastOthers;
  late AccountSyncStatus _current = AccountSyncStatus(accountId: account.id, state: AccountSyncState.idle);

  Stream<AccountSyncStatus> get status => _status.stream;
  AccountSyncStatus get currentStatus => _current;
  Stream<List<MessageHeader>> get newInbox => _newInbox.stream;

  /// Like [newInbox] but only for mail that arrived while this session was
  /// already caught up: the initial window and UIDVALIDITY resyncs are not
  /// arrivals. Feeds notifications.
  Stream<List<MessageHeader>> get arrivals => _arrivals.stream;
  Stream<FlagsObservation> get flagChanges => _flags.stream;
  ImapCapabilities? get capabilities => _caps;
  bool get isDegraded => _degraded;
  bool get isRunning => !_stopped;

  // ---------------------------------------------------------------- control

  Future<void> start() async {
    if (!_stopped) return;
    _stopped = false;
    _runDone = _run();
  }

  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;
    _poke();
    await _runDone;
    for (final r in _requests) {
      if (!r.completer.isCompleted) r.completer.completeError(StateError('sync stopped'));
    }
    _requests.clear();
    _set(AccountSyncState.idle);
  }

  Future<void> dispose() async {
    await stop();
    await _status.close();
    await _newInbox.close();
    await _arrivals.close();
    await _flags.close();
  }

  /// Syncs [folderPath] (INBOX by default) as soon as the connection allows.
  Future<void> syncNow({String? folderPath}) => _enqueue(_Request('sync', folderPath ?? 'INBOX'));

  Future<void> refreshFolders() => _enqueue(_Request('folders'));

  /// Drain the offline queue now.
  Future<void> drainPendingOps() => _enqueue(_Request('drain'));

  void requestDrain() {
    _requests.add(_Request('drain'));
    _poke();
  }

  Future<void> _enqueue(_Request r) {
    _requests.add(r);
    _poke();
    return r.completer.future;
  }

  /// Runs [fn] on the command connection, serialised with the sync work.
  Future<T> withCommand<T>(Future<T> Function(ImapGateway gw) fn) {
    final gw = _cmd;
    if (gw == null || !gw.isConnected) {
      return Future.error(const ImapGatewayException('not connected', isConnectionLost: true));
    }
    final completer = Completer<T>();
    _cmdChain = _cmdChain.then((_) async {
      try {
        completer.complete(await fn(gw));
      } catch (e, s) {
        completer.completeError(e, s);
      }
    });
    return completer.future;
  }

  void _poke() {
    if (!_wake.isCompleted) _wake.complete();
  }

  Future<bool> _waitWake([Duration? timeout]) async {
    if (_wake.isCompleted) _wake = Completer<void>();
    final woke = await Future.any<bool>([
      _wake.future.then((_) => true),
      if (timeout != null) Future<void>.delayed(timeout).then((_) => false),
    ]);
    if (_wake.isCompleted) _wake = Completer<void>();
    return woke;
  }

  void _set(AccountSyncState state, {String? error, DateTime? nextRetryAt}) {
    _current = AccountSyncStatus(accountId: account.id, state: state, error: error, nextRetryAt: nextRetryAt);
    if (!_status.isClosed) _status.add(_current);
  }

  // ---------------------------------------------------------------- main loop

  Future<void> _run() async {
    while (!_stopped) {
      ImapGateway? idleConn;
      ImapGateway? cmdConn;
      try {
        _set(AccountSyncState.connecting);
        final pw = await _password();
        idleConn = _factory();
        _caps = await idleConn.connect(account, pw);
        _set(AccountSyncState.syncing);
        try {
          cmdConn = _factory();
          await cmdConn.connect(account, pw);
        } catch (e) {
          _log.warning('second connection refused, degrading to single-connection polling: $e');
          try {
            await cmdConn?.disconnect();
          } catch (_) {}
          cmdConn = null;
        }
        _degraded = cmdConn == null;
        _cmd = cmdConn ?? idleConn;
        await _refreshFolders();
        final r = await _syncFolder('INBOX');
        _backfillRemaining = r.backfillRemaining;
        await _drain();
        await _handleRequests();
        // First pass over Sent, Drafts and the rest now, not after the first
        // inbox event: a reply sent before a restart must show in its thread.
        await _housekeeping();
        _backoff.reset();
        if (_degraded || !(_caps?.idle ?? false)) {
          await _pollLoop();
        } else {
          await _idleLoop(idleConn);
        }
      } on ImapGatewayException catch (e) {
        _failRequests(e);
        if (e.isAuthFailure) {
          _log.warning('authentication failed: ${e.message}');
          _set(AccountSyncState.authFailed, error: e.message, nextRetryAt: clock.now().add(tuning.authRetry));
          await _cleanup(idleConn, cmdConn);
          idleConn = cmdConn = null;
          if (!_stopped) await _waitWake(tuning.authRetry);
        } else {
          await _cleanup(idleConn, cmdConn);
          idleConn = cmdConn = null;
          await _backoffWait(e.message);
        }
      } catch (e, s) {
        _log.severe('sync loop error', e, s);
        _failRequests(e);
        await _cleanup(idleConn, cmdConn);
        idleConn = cmdConn = null;
        await _backoffWait(e.toString());
      } finally {
        await _cleanup(idleConn, cmdConn);
      }
    }
  }

  Future<void> _cleanup(ImapGateway? a, ImapGateway? b) async {
    _cmd = null;
    for (final gw in [a, b]) {
      if (gw == null) continue;
      try {
        await gw.disconnect().timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
  }

  void _failRequests(Object e) {
    for (final r in _requests) {
      if (!r.completer.isCompleted) r.completer.completeError(e);
    }
    _requests.clear();
  }

  Future<void> _backoffWait(String error) async {
    if (_stopped) return;
    final d = _backoff.next();
    _log.info('reconnecting in ${d.inSeconds}s (attempt ${_backoff.attempt}): $error');
    _set(AccountSyncState.backoff, error: error, nextRetryAt: clock.now().add(d));
    await _waitWake(d);
  }

  // ---------------------------------------------------------------- idle / poll

  Future<void> _idleLoop(ImapGateway idle) async {
    await idle.select('INBOX');
    while (!_stopped) {
      _set(AccountSyncState.idling);
      if (_wake.isCompleted) _wake = Completer<void>();
      final wake = _wake;
      final stop = Completer<void>();
      void finishIdle() {
        if (!stop.isCompleted) stop.complete();
      }
      unawaited(wake.future.then((_) => finishIdle()));
      final renew = Timer(tuning.idleRenew, finishIdle);
      final keep = Timer.periodic(tuning.keepalive, (_) {
        withCommand((gw) => gw.noop()).catchError((Object e) {
          _log.fine('keepalive failed: $e');
          finishIdle();
        });
      });
      Timer? debounce;
      Object? lost;
      var dirty = false;
      Future<void>? inflight;
      try {
        await for (final ev in idle.idle(stop: stop.future)) {
          if (ev is ConnectionLostEvent) {
            lost = ev.error ?? 'idle connection lost';
            finishIdle();
            continue;
          }
          dirty = true;
          debounce?.cancel();
          debounce = Timer(tuning.eventDebounce, () {
            dirty = false;
            inflight = _syncFolder('INBOX').then((_) {}, onError: (Object e) {
              _log.fine('event-triggered sync failed: $e');
              lost ??= e;
              finishIdle();
            });
          });
        }
      } finally {
        renew.cancel();
        keep.cancel();
        debounce?.cancel();
      }
      if (inflight != null) await inflight;
      if (lost != null) throw ImapGatewayException('idle connection lost: $lost', isConnectionLost: true);
      if (_stopped) break;
      if (dirty) await _syncFolder('INBOX');
      await _handleRequests();
      await _housekeeping();
    }
  }

  Future<void> _pollLoop() async {
    while (!_stopped) {
      _set(AccountSyncState.idling);
      await _waitWake(tuning.pollInterval);
      if (_stopped) break;
      await _syncFolder('INBOX');
      await _handleRequests();
      await _housekeeping();
    }
  }

  // ---------------------------------------------------------------- work

  Future<void> _handleRequests() async {
    while (_requests.isNotEmpty && !_stopped) {
      final r = _requests.removeAt(0);
      try {
        switch (r.kind) {
          case 'sync':
            await _syncFolder(r.path ?? 'INBOX');
          case 'folders':
            await _refreshFolders();
          case 'drain':
            await _drain();
          case 'others':
            await _syncOtherFolders();
        }
        if (!r.completer.isCompleted) r.completer.complete();
      } catch (e, s) {
        if (!r.completer.isCompleted) r.completer.completeError(e, s);
        rethrow;
      }
    }
    // Any user action implies queued ops.
    await _drain();
  }

  Future<void> _housekeeping() async {
    if (_backfillRemaining > 0) {
      final n = await withCommand((gw) => folderSync.backfill(gw, 'INBOX'));
      _backfillRemaining = n == 0 ? 0 : (_backfillRemaining - n).clamp(0, 1 << 40);
      if (_backfillRemaining > 0) _poke();
    }
    final now = clock.monotonic();
    final last = _lastOthers;
    if (last == null || now - last >= tuning.otherFoldersEvery) {
      _lastOthers = now;
      await _syncOtherFolders();
    }
  }

  Future<FolderSyncResult> _syncFolder(String path) async {
    final r = await withCommand((gw) => folderSync.sync(gw, path));
    if (path == 'INBOX' && r.newMessages.isNotEmpty && !_newInbox.isClosed) _newInbox.add(r.newMessages);
    if (path == 'INBOX' && r.newMessages.isNotEmpty && !r.initial && !r.uidValidityChanged && !_arrivals.isClosed) _arrivals.add(r.newMessages);
    if (r.flagChanges.isNotEmpty && !_flags.isClosed) {
      final at = clock.now();
      for (final h in r.flagChanges) {
        _flags.add(FlagsObservation(accountId: account.id, folderPath: path, header: h, observedAt: at));
      }
    }
    return r;
  }

  Future<void> _syncOtherFolders() async {
    final all = await folders.all(account.id);
    for (final f in all) {
      if (_stopped) return;
      if (f.isInbox || !f.selectable || f.isControlFolder) continue;
      try {
        await _syncFolder(f.path);
      } on ImapGatewayException catch (e) {
        if (e.isConnectionLost || e.isAuthFailure) rethrow;
        _log.fine('sync of ${f.path} failed: ${e.message}');
      }
    }
  }

  Future<void> _refreshFolders() async {
    final listed = await withCommand((gw) => gw.listFolders());
    await folders.replaceAll(account.id, [
      for (final f in listed)
        Folder(
          accountId: account.id,
          path: f.path,
          name: f.name,
          delimiter: f.delimiter,
          specialUse: f.specialUse,
          uidValidity: f.uidValidity,
          uidNext: f.uidNext,
          highestModSeq: f.highestModSeq,
          messageCount: f.messageCount,
          unseenCount: f.unseenCount,
          subscribed: f.subscribed,
          selectable: f.selectable,
        ),
    ]);
  }

  Future<void> _drain() async {
    await withCommand((gw) => executor.drain(account.id, gw));
    // A sent reply or a saved draft lives in Sent / Drafts now: read those
    // folders back right away so threads and the drafts list show it.
    for (final path in executor.takeTouched()) {
      if (path == 'INBOX') continue;
      try {
        await _syncFolder(path);
      } catch (e) {
        _log.fine('post-op sync of $path failed: $e');
      }
    }
  }
}
