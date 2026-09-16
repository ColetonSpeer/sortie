import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../../data/mail/imap_gateway.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/services.dart';
import 'server_clock.dart';
import 'sort_journal.dart';

/// User actions execute on whichever device the user is on, over a short
/// lived ops connection, and are journaled so every device follows.
class UserActions {
  UserActions({
    required this.accountId,
    required DeviceIdentity me,
    required ImapGatewayFactory gatewayFactory,
    required Future<String> Function() password,
    required Account Function() account,
    required SortJournal journal,
    required MessageClassifier classifier,
    required MessageRepository messages,
    required ServerClock serverClock,
    required bool Function() customKeywords,
  })  : _me = me,
        _factory = gatewayFactory,
        _password = password,
        _account = account,
        _journal = journal,
        _classifier = classifier,
        _messages = messages,
        _clock = serverClock,
        _customKeywords = customKeywords;

  static final _log = Logger('sortie.coordination.actions');
  static const inbox = 'INBOX';

  final String accountId;
  final DeviceIdentity _me;
  final ImapGatewayFactory _factory;
  final Future<String> Function() _password;
  final Account Function() _account;
  final SortJournal _journal;
  final MessageClassifier _classifier;
  final MessageRepository _messages;
  final ServerClock _clock;
  final bool Function() _customKeywords;

  Future<T> _withOps<T>(Future<T> Function(ImapGateway gw) fn) async {
    final gw = _factory();
    await gw.connect(_account(), await _password());
    try {
      return await fn(gw);
    } finally {
      try {
        await gw.disconnect();
      } catch (_) {}
    }
  }

  /// Locates a message in [folder] by UID fast path, else by Message-ID.
  Future<MessageHeader?> _locate(ImapGateway gw, String folder, MessageKey key) async {
    await gw.select(folder);
    final uid = key.uid;
    if (uid != null) {
      final hs = await gw.fetchHeadersByUids([uid]);
      if (hs.isNotEmpty && hs.first.messageIdHash == key.messageIdHash) return hs.first;
    }
    final local = await _messages.byMessageIdHash(accountId, key.messageIdHash);
    var mid = local?.messageId;
    if (mid == null && local != null && local.folderPath == folder) {
      final hs = await gw.fetchHeadersByUids([local.uid]);
      if (hs.isNotEmpty && hs.first.messageIdHash == key.messageIdHash) return hs.first;
    }
    if (mid == null) return null;
    final uids = await gw.searchByMessageId(mid);
    for (final h in uids.isEmpty ? <MessageHeader>[] : await gw.fetchHeadersByUids(uids)) {
      if (h.messageIdHash == key.messageIdHash) return h;
    }
    return null;
  }

  Future<void> undo(String decisionId) async {
    final d = await _journal.store.decisionById(decisionId);
    if (d == null) throw ArgumentError.value(decisionId, 'decisionId', 'unknown decision');
    final dest = d.destination;
    MessageHeader? h;
    MoveResult? r;
    try {
      await _withOps((gw) async {
        h = await _locate(gw, dest, d.key);
        if (h != null) r = await gw.move([h!.uid], inbox);
      });
    } on ImapGatewayException catch (e) {
      _log.warning('undo $decisionId offline ($e); leader will execute');
    }
    if (h == null) {
      await _journal.recordUndo(key: d.key, decisionId: d.id, executed: false);
      return;
    }
    await _journal.recordUndo(key: d.key, decisionId: d.id, executed: true);
    await _journal.recordMoved([MovedItem(key: d.key, from: dest, to: inbox, cause: 'undo', decisionId: d.id, subject: h!.subject, fromAddress: h!.from?.email)]);
    await _messages.moveLocally(accountId, dest, [h!.uid], inbox, newUids: r?.uidMapping ?? const {});
    await _classifier.recordCorrection(_correction(CorrectionKind.undo, h, d.key, predicted: dest, actual: inbox, decisionId: d.id, weight: 1.0));
  }

  Future<void> moveNow(MessageKey key) async {
    final d = await _journal.store.decisionForMid(key.messageIdHash, openOnly: true);
    if (d == null) throw StateError('no open decision for $key');
    await _withOps((gw) async {
      final h = await _locate(gw, inbox, key);
      if (h == null) throw StateError('message $key not in INBOX');
      if (_customKeywords()) await gw.store([h.uid], add: {SortieKeywords.done}, remove: {SortieKeywords.pending});
      final r = await gw.move([h.uid], d.destination);
      await _journal.recordMoved([MovedItem(key: key, from: inbox, to: d.destination, cause: 'manual', decisionId: d.id, subject: h.subject, fromAddress: h.from?.email)]);
      await _messages.moveLocally(accountId, inbox, [h.uid], d.destination, newUids: r.uidMapping);
    });
  }

  Future<void> keepInInbox(MessageKey key) async {
    final d = await _journal.store.decisionForMid(key.messageIdHash, openOnly: true);
    MessageHeader? h;
    try {
      await _withOps((gw) async {
        h = await _locate(gw, inbox, key);
        if (h != null && _customKeywords()) await gw.store([h!.uid], add: {SortieKeywords.done}, remove: {SortieKeywords.pending});
      });
    } on ImapGatewayException catch (e) {
      _log.fine('keepInInbox: keyword update skipped ($e)');
    }
    await _journal.recordResolved(key: key, why: 'keep');
    if (d != null) {
      final c = _correction(CorrectionKind.badgeDismiss, h, key, predicted: d.destination, actual: inbox, decisionId: d.id, weight: 0.5);
      await _journal.recordCorrection(c);
      await _classifier.recordCorrection(c);
    }
  }

  Future<void> changeDestination(MessageKey key, String folderPath) async {
    final d = await _journal.store.decisionForMid(key.messageIdHash, openOnly: true);
    await _withOps((gw) async {
      final h = await _locate(gw, inbox, key);
      if (h == null) throw StateError('message $key not in INBOX');
      if (_customKeywords()) await gw.store([h.uid], add: {SortieKeywords.done}, remove: {SortieKeywords.pending});
      final r = await gw.move([h.uid], folderPath);
      final c = _correction(d == null ? CorrectionKind.manualFile : CorrectionKind.badgeWrong, h, key,
          predicted: d?.destination, actual: folderPath, decisionId: d?.id, weight: 1.0);
      await _journal.recordCorrection(c);
      await _journal.recordMoved([MovedItem(key: key, from: inbox, to: folderPath, cause: 'correction', decisionId: d?.id, subject: h.subject, fromAddress: h.from?.email)]);
      await _messages.moveLocally(accountId, inbox, [h.uid], folderPath, newUids: r.uidMapping);
      await _classifier.recordCorrection(c);
    });
  }

  Future<void> markRight(MessageKey key) async {
    final d = await _journal.store.decisionForMid(key.messageIdHash);
    if (d == null) return;
    final h = await _messages.byMessageIdHash(accountId, key.messageIdHash);
    final c = _correction(CorrectionKind.badgeRight, h, key, predicted: d.destination, actual: d.destination, decisionId: d.id, weight: 0.5);
    await _journal.recordCorrection(c);
    await _classifier.recordCorrection(c);
  }

  Correction _correction(CorrectionKind kind, MessageHeader? h, MessageKey key,
      {String? predicted, required String actual, String? decisionId, required double weight}) {
    final now = _clock.nowOrNull() ?? DateTime.now().toUtc();
    return Correction(
      id: const Uuid().v4(),
      key: key,
      kind: kind,
      weight: weight,
      predictedFolder: predicted,
      actualFolder: actual,
      at: now,
      decisionId: decisionId,
      fromAddress: h?.from?.email,
      fromDomain: h?.from?.domain,
      listId: h?.listId,
      subjectNorm: h?.subject,
      deviceId: _me.deviceId,
    );
  }
}
