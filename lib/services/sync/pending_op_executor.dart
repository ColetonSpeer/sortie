import 'dart:io';

import 'package:logging/logging.dart';

import '../../core/clock.dart';
import '../../data/mail/imap_gateway.dart';
import '../../data/mail/smtp_gateway.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

/// Thrown when an op cannot be completed now but should be retried later.
class PendingOpRetry implements Exception {
  const PendingOpRetry(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Drains the offline queue for one account over a connected command
/// connection. Every op is idempotent: re-running after a lost response never
/// duplicates a move, a flag or a sent message.
class PendingOpExecutor {
  PendingOpExecutor({
    required this.ops,
    required this.messages,
    required this.folders,
    required this.accounts,
    required this.credentials,
    required this.smtp,
    required this.clock,
    Future<List<int>> Function(String path)? readFile,
    Future<void> Function(String path)? deleteFile,
    Logger? log,
  })  : _readFile = readFile ?? ((p) => File(p).readAsBytes()),
        _deleteFile = deleteFile ??
            ((p) async {
              try {
                await File(p).delete();
              } catch (_) {}
            }),
        _log = log ?? Logger('sortie.sync.ops');

  final PendingOpRepository ops;
  final MessageRepository messages;
  final FolderRepository folders;
  final AccountRepository accounts;
  final CredentialStore credentials;
  final SmtpGateway smtp;
  final Clock clock;
  final Future<List<int>> Function(String path) _readFile;
  final Future<void> Function(String path) _deleteFile;
  final Logger _log;

  /// Executes all runnable ops FIFO. Stops (rethrows) on connection loss or
  /// auth failure so the session can reconnect; other failures are recorded
  /// with a retry time and the next op proceeds. Returns the number done.
  /// Folders whose contents changed server-side since the last [takeTouched]
  /// (Sent after a send, Drafts after a save): the session re-reads them at
  /// once instead of on the slow other-folders cadence, so a reply shows in
  /// its thread right after sending.
  final touchedFolders = <String>{};

  Set<String> takeTouched() {
    final t = Set<String>.of(touchedFolders);
    touchedFolders.clear();
    return t;
  }

  Future<int> drain(String accountId, ImapGateway gw) async {
    var done = 0;
    for (final op in await ops.pending(accountId)) {
      try {
        await execute(op, gw);
        await ops.markDone(op.id);
        done++;
      } on ImapGatewayException catch (e) {
        if (e.isConnectionLost || e.isAuthFailure) rethrow;
        _log.warning('op ${op.id} (${op.runtimeType}) failed: ${e.message}');
        await ops.markFailed(op.id, e.message);
      } on PendingOpRetry catch (e) {
        _log.info('op ${op.id} deferred: ${e.message}');
        await ops.markFailed(op.id, e.message);
      } catch (e, s) {
        _log.warning('op ${op.id} (${op.runtimeType}) failed: $e', e, s);
        await ops.markFailed(op.id, e.toString());
      }
    }
    return done;
  }

  Future<void> execute(PendingOp op, ImapGateway gw) => switch (op) {
        final SetFlagsOp o => _setFlags(o, gw),
        final MoveOp o => _move(o, gw),
        final DeleteOp o => _delete(o, gw),
        final AppendOp o => _append(o, gw),
        final SendOp o => _send(o, gw),
      };

  // ---------------------------------------------------------------- helpers

  /// Resolves current UIDs in the selected folder for the op's messages.
  /// Uses the recorded UIDs when UIDVALIDITY still matches, otherwise
  /// re-finds each message by Message-ID. Messages no longer present are
  /// silently dropped (already moved/deleted elsewhere).
  Future<List<int>> _resolveUids(ImapGateway gw, String accountId, SelectResult sel, int recordedUidValidity, List<int> uids, List<String> hashes) async {
    if (sel.uidValidity == recordedUidValidity && uids.isNotEmpty) {
      final present = (await gw.fetchFlags(UidRange.fromTo(uids.reduce((a, b) => a < b ? a : b), uids.reduce((a, b) => a > b ? a : b)))).keys.toSet();
      final still = uids.where(present.contains).toList();
      if (still.length == uids.length) return still;
      // Some vanished: fall back to Message-ID for those.
      final missingIdx = <int>[for (var i = 0; i < uids.length; i++) if (!present.contains(uids[i])) i];
      final found = <int>[...still];
      for (final i in missingIdx) {
        if (i < hashes.length) found.addAll(await _findByHash(gw, accountId, hashes[i]));
      }
      return found.toSet().toList();
    }
    final out = <int>{};
    for (final h in hashes) {
      out.addAll(await _findByHash(gw, accountId, h));
    }
    return out.toList();
  }

  Future<List<int>> _findByHash(ImapGateway gw, String accountId, String hash) async {
    final header = await messages.byMessageIdHash(accountId, hash);
    final mid = header?.messageId;
    if (mid == null || mid.isEmpty) return const [];
    return gw.searchByMessageId(mid);
  }

  Future<SelectResult> _select(ImapGateway gw, String path) => gw.select(path);

  Future<Folder?> _special(String accountId, SpecialUse use) async {
    final all = await folders.all(accountId);
    return all.where((f) => f.specialUse == use).firstOrNull;
  }

  // ---------------------------------------------------------------- ops

  Future<void> _setFlags(SetFlagsOp o, ImapGateway gw) async {
    final sel = await _select(gw, o.folderPath);
    final uids = await _resolveUids(gw, o.accountId, sel, o.uidValidity, o.uids, o.messageIdHashes);
    if (uids.isEmpty) return;
    // Keywords pass through as plain strings (`$SortiePending`).
    await gw.store(uids, add: o.add, remove: o.remove);
  }

  Future<void> _move(MoveOp o, ImapGateway gw) async {
    final sel = await _select(gw, o.fromFolder);
    final uids = await _resolveUids(gw, o.accountId, sel, o.uidValidity, o.uids, o.messageIdHashes);
    if (uids.isEmpty) {
      _log.fine('move ${o.id}: nothing left to move (already moved elsewhere)');
      return;
    }
    MoveResult res;
    try {
      res = await gw.move(uids, o.toFolder);
    } on ImapGatewayException catch (e) {
      if (e.isConnectionLost || e.isAuthFailure) rethrow;
      if (RegExp(r'TRYCREATE|does not exist|no such|not found', caseSensitive: false).hasMatch(e.message)) {
        await gw.createFolder(o.toFolder);
        await _select(gw, o.fromFolder);
        res = await gw.move(uids, o.toFolder);
      } else {
        rethrow;
      }
    }
    // Relink destination UIDs when COPYUID told us; otherwise the next sync
    // of the destination folder upserts by hash.
    if (res.uidMapping.isNotEmpty) {
      final dest = await folders.byPath(o.accountId, o.toFolder);
      final destUv = dest?.uidValidity;
      final srcByUid = <int, String>{for (var i = 0; i < o.uids.length && i < o.messageIdHashes.length; i++) o.uids[i]: o.messageIdHashes[i]};
      for (final e in res.uidMapping.entries) {
        final hash = srcByUid[e.key];
        if (hash == null) continue;
        if (destUv != null) {
          await messages.relinkUid(o.accountId, o.toFolder, hash, e.value, destUv);
        }
      }
    }
  }

  Future<void> _delete(DeleteOp o, ImapGateway gw) async {
    final sel = await _select(gw, o.folderPath);
    final uids = {...await _resolveUids(gw, o.accountId, sel, o.uidValidity, o.uids, o.messageIdHashes)};
    for (final mid in o.messageIds) {
      uids.addAll(await gw.searchByMessageId(mid));
    }
    if (uids.isEmpty) return;
    if (!o.permanent) {
      final trash = await _special(o.accountId, SpecialUse.trash);
      if (trash != null && trash.path != o.folderPath) {
        await gw.move(uids.toList(), trash.path);
        return;
      }
    }
    await gw.expunge(uids.toList());
  }

  /// Expunges every copy of [messageId] in [path]; a no-op when absent.
  Future<void> _expungeByMessageId(ImapGateway gw, String path, String messageId) async {
    await _select(gw, path);
    final uids = await gw.searchByMessageId(messageId);
    if (uids.isNotEmpty) await gw.expunge(uids);
  }

  Future<String?> _messageIdOf(List<int> raw) async {
    final headers = parseHeaderBlock(raw);
    return headers['message-id'];
  }

  Future<bool> _alreadyAppended(ImapGateway gw, String path, List<int> raw) async {
    final mid = await _messageIdOf(raw);
    if (mid == null) return false;
    await _select(gw, path);
    return (await gw.searchByMessageId(mid)).isNotEmpty;
  }

  Future<void> _append(AppendOp o, ImapGateway gw) async {
    final raw = await _readFile(o.rawMessagePath);
    if (!await _alreadyAppended(gw, o.folderPath, raw)) {
      try {
        await gw.append(o.folderPath, raw, flags: o.flags);
      } on ImapGatewayException catch (e) {
        if (e.isConnectionLost && await _alreadyAppended(gw, o.folderPath, raw)) {
          // Response lost after the server stored it.
        } else {
          rethrow;
        }
      }
    }
    if (o.supersedesMessageId != null) await _expungeByMessageId(gw, o.folderPath, o.supersedesMessageId!);
    touchedFolders.add(o.folderPath);
    await _deleteFile(o.rawMessagePath);
  }

  Future<void> _send(SendOp o, ImapGateway gw) async {
    final raw = await _readFile(o.rawMessagePath);
    final account = await accounts.byId(o.accountId);
    if (account == null) throw StateError('account ${o.accountId} gone');
    final identity = (await accounts.identities(o.accountId)).where((i) => i.id == o.identityId).firstOrNull ??
        Identity(id: o.identityId, accountId: o.accountId, name: account.displayName, email: account.email);
    if (!o.smtpAccepted) {
      final password = await credentials.read(CredentialStore.accountPassword(o.accountId));
      if (password == null) throw const PendingOpRetry('no password stored');
      try {
        final r = await smtp.send(account, password, identity, o.recipients, raw);
        if (!r.accepted) throw PendingOpRetry('SMTP did not accept: ${r.response}');
      } on SmtpGatewayException catch (e) {
        if (e.isAuthFailure) throw PendingOpRetry('SMTP auth failed: ${e.message}');
        throw PendingOpRetry(e.message);
      }
      // From here on the message is out; never resend.
      await ops.markSmtpAccepted(o.id);
    }
    final sent = await _special(o.accountId, SpecialUse.sent);
    if (sent == null) {
      _log.info('no Sent folder known; skipping Sent copy for ${o.id}');
    } else if (!await _alreadyAppended(gw, sent.path, raw)) {
      try {
        await gw.append(sent.path, raw, flags: {r'\Seen'});
      } on ImapGatewayException catch (e) {
        if (!(e.isConnectionLost && await _alreadyAppended(gw, sent.path, raw))) rethrow;
      }
      touchedFolders.add(sent.path);
    }
    if (o.draftMessageId != null) {
      final drafts = await _special(o.accountId, SpecialUse.drafts);
      if (drafts != null) await _expungeByMessageId(gw, drafts.path, o.draftMessageId!);
    }
    await _deleteFile(o.rawMessagePath);
  }

  /// Parses the header block of an RFC 5322 message into lower-cased
  /// name -> first value, unfolding continuation lines.
  static Map<String, String> parseHeaderBlock(List<int> raw) {
    final s = String.fromCharCodes(raw.length > 65536 ? raw.sublist(0, 65536) : raw);
    var end = s.indexOf('\r\n\r\n');
    var sep = '\r\n';
    if (end < 0) {
      end = s.indexOf('\n\n');
      sep = '\n';
    }
    final head = end < 0 ? s : s.substring(0, end);
    final out = <String, String>{};
    String? name;
    final buf = StringBuffer();
    void flush() {
      final n = name;
      if (n != null) out.putIfAbsent(n.toLowerCase(), () => buf.toString().trim());
      buf.clear();
    }
    for (final line in head.split(sep)) {
      if (line.startsWith(' ') || line.startsWith('\t')) {
        buf.write(' ${line.trim()}');
        continue;
      }
      flush();
      final i = line.indexOf(':');
      if (i <= 0) {
        name = null;
        continue;
      }
      name = line.substring(0, i);
      buf.write(line.substring(i + 1));
    }
    flush();
    return out;
  }
}
