import 'package:logging/logging.dart';

import '../../core/clock.dart';
import '../../data/mail/imap_gateway.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

class FolderSyncResult {
  const FolderSyncResult({
    required this.path,
    required this.select,
    this.newMessages = const [],
    this.flagChanges = const [],
    this.removedUids = const [],
    this.uidValidityChanged = false,
    this.initial = false,
    this.backfillRemaining = 0,
  });
  final String path;
  final SelectResult select;

  /// Headers not previously cached (includes the initial window).
  final List<MessageHeader> newMessages;

  /// Cached messages whose flags differ from the server now.
  final List<MessageHeader> flagChanges;
  final List<int> removedUids;
  final bool uidValidityChanged;
  final bool initial;

  /// Older UIDs on the server not yet cached; drained by [FolderSynchronizer.backfill].
  final int backfillRemaining;
}

/// Incremental synchronisation of one folder against an already connected
/// gateway. Stateless apart from the repositories; safe to call repeatedly.
class FolderSynchronizer {
  FolderSynchronizer({
    required this.accountId,
    required this.messages,
    required this.folders,
    required this.clock,
    this.initialWindow = 500,
    this.backfillPage = 200,
    this.flagWindow = 1000,
    this.fetchChunk = 200,
    Logger? log,
  }) : _log = log ?? Logger('sortie.sync.folder');

  final String accountId;
  final MessageRepository messages;
  final FolderRepository folders;
  final Clock clock;
  final int initialWindow;
  final int backfillPage;
  final int flagWindow;
  final int fetchChunk;
  final Logger _log;

  Future<FolderSyncResult> sync(ImapGateway gw, String path, {SelectResult? selected}) async {
    final folder = await folders.byPath(accountId, path) ?? Folder(accountId: accountId, path: path, name: _nameOf(path, gw.delimiter ?? '/'), delimiter: gw.delimiter ?? '/', specialUse: path.toUpperCase() == 'INBOX' ? SpecialUse.inbox : SpecialUse.none);
    final sel = selected ?? await gw.select(path, knownUidValidity: folder.uidValidity, knownModSeq: folder.highestModSeq);
    if (gw.selectedPath != path) await gw.select(path);

    FolderSyncResult result;
    if (folder.uidValidity == null) {
      result = await _initial(gw, folder, sel);
    } else if (folder.uidValidity != sel.uidValidity) {
      _log.warning('$accountId/$path UIDVALIDITY ${folder.uidValidity} -> ${sel.uidValidity}: relinking by Message-ID');
      result = await _uidValidityFlip(gw, folder, sel);
    } else {
      result = await _incremental(gw, folder, sel);
    }
    await folders.update(folder.copyWith(
      uidValidity: sel.uidValidity,
      uidNext: sel.uidNext,
      highestModSeq: sel.highestModSeq,
      messageCount: sel.exists,
      unseenCount: await _unseenCount(path),
    ));
    return result;
  }

  static String _nameOf(String path, String delim) => path.contains(delim) ? path.substring(path.lastIndexOf(delim) + 1) : path;

  Future<int> _unseenCount(String path) async {
    final list = await messages.list(MessageQuery(accountId: accountId, folderPath: path, limit: 5000));
    return list.where((h) => !h.isSeen).length;
  }

  List<MessageHeader> _own(Iterable<MessageHeader> hs, String path, int uidValidity) =>
      hs.map((h) => _withIds(h, path, uidValidity)).toList();

  MessageHeader _withIds(MessageHeader h, String path, int uidValidity) => MessageHeader(
        accountId: accountId,
        folderPath: path,
        uid: h.uid,
        uidValidity: uidValidity,
        messageIdHash: h.messageIdHash,
        messageId: h.messageId,
        subject: h.subject,
        from: h.from,
        to: h.to,
        cc: h.cc,
        replyTo: h.replyTo,
        date: h.date,
        internalDate: h.internalDate,
        listId: h.listId,
        inReplyTo: h.inReplyTo,
        references: h.references,
        precedence: h.precedence,
        autoSubmitted: h.autoSubmitted,
        hasListUnsubscribe: h.hasListUnsubscribe,
        flags: h.flags,
        size: h.size,
        snippet: h.snippet,
        attachments: h.attachments,
      );

  Future<List<MessageHeader>> _fetchByUids(ImapGateway gw, List<int> uids, String path, int uidValidity) async {
    final out = <MessageHeader>[];
    for (var i = 0; i < uids.length; i += fetchChunk) {
      final chunk = uids.sublist(i, i + fetchChunk > uids.length ? uids.length : i + fetchChunk);
      out.addAll(_own(await gw.fetchHeadersByUids(chunk), path, uidValidity));
    }
    return out;
  }

  Future<FolderSyncResult> _initial(ImapGateway gw, Folder folder, SelectResult sel) async {
    final all = await gw.allUids();
    final newest = all.length > initialWindow ? all.sublist(all.length - initialWindow) : all;
    final headers = await _fetchByUids(gw, newest, folder.path, sel.uidValidity);
    await messages.upsertHeaders(headers);
    _log.info('$accountId/${folder.path} initial sync: ${headers.length} of ${all.length} headers');
    return FolderSyncResult(path: folder.path, select: sel, newMessages: headers, initial: true, backfillRemaining: all.length - newest.length);
  }

  Future<FolderSyncResult> _uidValidityFlip(ImapGateway gw, Folder folder, SelectResult sel) async {
    final before = (await messages.list(MessageQuery(accountId: accountId, folderPath: folder.path, limit: 100000))).map((h) => h.messageIdHash).toSet();
    await messages.invalidateUids(accountId, folder.path);
    final all = await gw.allUids();
    final newest = all.length > initialWindow ? all.sublist(all.length - initialWindow) : all;
    final headers = await _fetchByUids(gw, newest, folder.path, sel.uidValidity);
    // upsert relinks rows keyed by (account, hash, folder) with the new UIDs.
    await messages.upsertHeaders(headers);
    await messages.deleteOrphans(accountId, folder.path);
    final fresh = headers.where((h) => !before.contains(h.messageIdHash)).toList();
    return FolderSyncResult(path: folder.path, select: sel, newMessages: fresh, uidValidityChanged: true, backfillRemaining: all.length - newest.length);
  }

  Future<FolderSyncResult> _incremental(ImapGateway gw, Folder folder, SelectResult sel) async {
    final path = folder.path;
    final known = await messages.knownUids(accountId, path);
    final knownSet = known.toSet();
    final maxKnown = known.isEmpty ? 0 : known.last;

    // 1. New mail: UID FETCH uidNext:*
    final from = (folder.uidNext ?? (maxKnown + 1)).clamp(1, 1 << 62);
    final fresh = <MessageHeader>[];
    if (sel.uidNext > from || sel.exists > known.length) {
      final fetched = _own(await gw.fetchHeaders(UidRange.since(from)), path, sel.uidValidity);
      fresh.addAll(fetched.where((h) => !knownSet.contains(h.uid)));
      if (fresh.isNotEmpty) await messages.upsertHeaders(fresh);
    }

    // 2. Deletions: QRESYNC VANISHED, else UID SEARCH ALL diff.
    List<int> removed;
    List<int>? serverUids;
    if (sel.vanishedUids.isNotEmpty) {
      removed = sel.vanishedUids.where(knownSet.contains).toList();
    } else {
      serverUids = await gw.allUids();
      final onServer = serverUids.toSet();
      removed = known.where((u) => !onServer.contains(u)).toList();
    }
    if (removed.isNotEmpty) await messages.removeByUids(accountId, path, removed);
    final removedSet = removed.toSet();

    // 3. Flags: CHANGEDSINCE when CONDSTORE, else re-fetch over the window.
    final flagChanges = <MessageHeader>[];
    final window = known.where((u) => !removedSet.contains(u)).toList();
    if (window.isNotEmpty) {
      final lo = window.length > flagWindow ? window[window.length - flagWindow] : window.first;
      final hi = window.last;
      Map<int, Set<String>> serverFlags;
      final modSeq = folder.highestModSeq;
      if (sel.highestModSeq != null && modSeq != null) {
        if (sel.highestModSeq == modSeq) {
          serverFlags = const {};
        } else {
          serverFlags = await gw.fetchFlags(UidRange.fromTo(lo, hi), changedSince: modSeq);
        }
      } else {
        serverFlags = await gw.fetchFlags(UidRange.fromTo(lo, hi));
      }
      if (serverFlags.isNotEmpty) {
        final local = await messages.list(MessageQuery(accountId: accountId, folderPath: path, limit: 100000));
        final byUid = {for (final h in local) h.uid: h};
        final changed = <int, Set<String>>{};
        for (final e in serverFlags.entries) {
          final h = byUid[e.key];
          if (h == null || removedSet.contains(e.key)) continue;
          if (!_sameFlags(h.flags, e.value)) {
            changed[e.key] = e.value;
            flagChanges.add(h.copyWith(flags: e.value));
          }
        }
        if (changed.isNotEmpty) await messages.updateFlags(accountId, path, changed);
      }
    }

    // 4. Gaps: messages present on server but never cached inside the window
    //    (e.g. delivered while offline after uidNext advanced elsewhere).
    if (serverUids != null) {
      final cached = knownSet..addAll(fresh.map((h) => h.uid));
      final missing = serverUids.where((u) => !cached.contains(u) && u < from).toList();
      final take = missing.length > backfillPage ? missing.sublist(missing.length - backfillPage) : missing;
      if (take.isNotEmpty) {
        final gap = await _fetchByUids(gw, take, path, sel.uidValidity);
        await messages.upsertHeaders(gap);
        fresh.addAll(gap);
      }
    }

    if (fresh.isNotEmpty || removed.isNotEmpty || flagChanges.isNotEmpty) {
      _log.fine('$accountId/$path: +${fresh.length} -${removed.length} ~${flagChanges.length}');
    }
    return FolderSyncResult(path: path, select: sel, newMessages: fresh, flagChanges: flagChanges, removedUids: removed);
  }

  static bool _sameFlags(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);

  /// Fetches up to [pages] pages of older headers not yet cached.
  /// Returns how many headers were fetched (0 when the folder is complete).
  Future<int> backfill(ImapGateway gw, String path, {int pages = 1}) async {
    final folder = await folders.byPath(accountId, path);
    final sel = gw.selectedPath == path ? null : await gw.select(path);
    final uidValidity = sel?.uidValidity ?? folder?.uidValidity ?? 0;
    final all = await gw.allUids();
    final known = (await messages.knownUids(accountId, path)).toSet();
    final missing = all.where((u) => !known.contains(u)).toList();
    if (missing.isEmpty) return 0;
    final take = missing.length > backfillPage * pages ? missing.sublist(missing.length - backfillPage * pages) : missing;
    final headers = await _fetchByUids(gw, take, path, uidValidity);
    await messages.upsertHeaders(headers);
    _log.fine('$accountId/$path backfill: ${headers.length} (${missing.length - take.length} left)');
    return headers.length;
  }
}
