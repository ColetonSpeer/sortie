import 'dart:async';

import 'package:logging/logging.dart';

import '../../core/clock.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import 'importance.dart';

/// Where new-mail notifications go. [NotificationService] implements it; tests
/// use a recording fake.
abstract class NewMailSink {
  Future<void> init();
  Future<void> notifyNewMail(MessageHeader h);
  Future<void> notifyNewMailSummary(String accountId, List<MessageHeader> headers);
}

/// Turns INBOX arrivals into notifications according to the device's
/// [NotifyMode]: every unread message, or only the ones [ImportanceJudge]
/// accepts. Already-read mail (read on another device first), the owner's own
/// copies, mail older than [maxAge] and anything already announced are
/// skipped. Large bursts collapse into one summary.
class NewMailNotifier {
  NewMailNotifier({
    required Stream<List<Account>> accounts,
    required Stream<List<MessageHeader>> Function(String accountId) arrivals,
    required NewMailSink sink,
    required NotifyMode Function() mode,
    required Future<ImportanceJudge> Function(String accountId) judge,
    required Clock clock,
    this.maxAge = const Duration(hours: 24),
    this.summaryAbove = 8,
  })  : _accounts = accounts,
        _arrivals = arrivals,
        _sink = sink,
        _mode = mode,
        _judge = judge,
        _clock = clock;

  static final _log = Logger('notifier');
  static const _remembered = 1000;

  final Stream<List<Account>> _accounts;
  final Stream<List<MessageHeader>> Function(String accountId) _arrivals;
  final NewMailSink _sink;
  final NotifyMode Function() _mode;
  final Future<ImportanceJudge> Function(String accountId) _judge;
  final Clock _clock;
  final Duration maxAge;
  final int summaryAbove;

  final _announced = <String>{};
  final _subs = <String, StreamSubscription<List<MessageHeader>>>{};
  StreamSubscription<List<Account>>? _accountsSub;
  Future<void> _chain = Future.value();

  void start() {
    _accountsSub ??= _accounts.listen(_onAccounts);
  }

  Future<void> stop() async {
    await _accountsSub?.cancel();
    _accountsSub = null;
    for (final s in _subs.values) {
      await s.cancel();
    }
    _subs.clear();
  }

  void _onAccounts(List<Account> list) {
    final ids = {for (final a in list) a.id};
    for (final id in ids) {
      _subs.putIfAbsent(id, () => _arrivals(id).listen((hs) => _serial(() => handle(id, hs))));
    }
    for (final id in _subs.keys.toList()) {
      if (!ids.contains(id)) unawaited(_subs.remove(id)?.cancel());
    }
  }

  Future<void> _serial(Future<void> Function() job) {
    final next = _chain.then((_) => job()).catchError((Object e, StackTrace st) => _log.warning('notification failed', e, st));
    _chain = next;
    return next;
  }

  /// Process one arrival batch. Public for tests; normally driven by the
  /// per-account arrival streams.
  Future<void> handle(String accountId, List<MessageHeader> headers) async {
    final mode = _mode();
    if (mode == NotifyMode.off || headers.isEmpty) return;
    final now = _clock.now();
    var fresh = headers.where((h) {
      if (h.isSeen || _announced.contains(h.messageIdHash)) return false;
      final at = h.internalDate ?? h.date;
      return now.difference(at) <= maxAge;
    }).toList();
    if (fresh.isEmpty) return;

    final judge = await _judge(accountId);
    fresh = fresh.where((h) => !judge.isOwn(h)).toList();
    if (mode == NotifyMode.important) fresh = fresh.where(judge.isImportant).toList();
    for (final h in fresh) {
      _remember(h.messageIdHash);
    }
    if (fresh.isEmpty) return;

    await _sink.init();
    if (fresh.length > summaryAbove) {
      await _sink.notifyNewMailSummary(accountId, fresh);
    } else {
      for (final h in fresh) {
        await _sink.notifyNewMail(h);
      }
    }
  }

  void _remember(String hash) {
    _announced.add(hash);
    while (_announced.length > _remembered) {
      _announced.remove(_announced.first);
    }
  }
}

/// Builds an [ImportanceJudge] from the local stores: identity addresses plus
/// everyone found in Sent folders and in answered INBOX mail. Cached per
/// account for [ttl].
class ImportanceContext {
  ImportanceContext({
    required AccountRepository accounts,
    required FolderRepository folders,
    required MessageRepository messages,
    required Clock clock,
    this.ttl = const Duration(minutes: 15),
  })  : _accounts = accounts,
        _folders = folders,
        _messages = messages,
        _clock = clock;

  final AccountRepository _accounts;
  final FolderRepository _folders;
  final MessageRepository _messages;
  final Clock _clock;
  final Duration ttl;
  final _cache = <String, (Duration, ImportanceJudge)>{};

  Future<ImportanceJudge> judge(String accountId) async {
    final now = _clock.monotonic();
    final hit = _cache[accountId];
    if (hit != null && now - hit.$1 < ttl) return hit.$2;
    final j = await _build(accountId);
    _cache[accountId] = (now, j);
    return j;
  }

  void invalidate([String? accountId]) => accountId == null ? _cache.clear() : _cache.remove(accountId);

  Future<ImportanceJudge> _build(String accountId) async {
    final mine = <String>{};
    for (final i in await _accounts.identities(accountId)) {
      if (i.email.isNotEmpty) mine.add(i.email.toLowerCase());
    }
    final people = <String>{};
    for (final f in await _folders.all(accountId)) {
      if (f.specialUse != SpecialUse.sent) continue;
      for (final h in await _messages.list(MessageQuery(accountId: accountId, folderPath: f.path, limit: 2000))) {
        for (final a in [...h.to, ...h.cc]) {
          final e = a.email.toLowerCase();
          if (e.isNotEmpty && !mine.contains(e)) people.add(e);
        }
      }
    }
    for (final h in await _messages.list(MessageQuery(accountId: accountId, folderPath: 'INBOX', limit: 2000))) {
      final e = h.from?.email.toLowerCase() ?? '';
      if (h.isAnswered && e.isNotEmpty && !mine.contains(e)) people.add(e);
    }
    return ImportanceJudge(myAddresses: mine, correspondents: people);
  }
}
