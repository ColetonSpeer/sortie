import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../core/clock.dart';
import '../../data/calendar/caldav_client.dart';
import '../../data/calendar/ics_feed.dart';
import '../../domain/entities/calendar.dart';
import '../../domain/repositories/calendar_repository.dart';
import 'ics.dart';

/// Thrown when a Google calendar has no signed-in account on this device.
class NeedsSignInException implements Exception {
  const NeedsSignInException(this.email);
  final String? email;
  @override
  String toString() => 'Sign in to Google${email == null ? '' : ' ($email)'} to sync this calendar';
}

/// Pull/push of one calendar source. Stateless apart from its collaborators;
/// [CalendarService] owns scheduling and status.
class CalendarSyncer {
  CalendarSyncer({
    required this.repo,
    required this.clock,
    required Dio Function() dio,
    required Future<CalDavAuth> Function(CalendarSource) authFor,
  })  : _dio = dio,
        _authFor = authFor;

  static final _log = Logger('calendar.sync');
  final CalendarRepository repo;
  final Clock clock;
  final Dio Function() _dio;
  final Future<CalDavAuth> Function(CalendarSource) _authFor;

  Future<CalDavClient> client(CalendarSource s) async => CalDavClient(dio: _dio(), auth: await _authFor(s));

  /// Pushes the local queue then pulls; returns the updated source.
  Future<CalendarSource> sync(CalendarSource src) async {
    switch (src.kind) {
      case CalendarKind.local:
        return src.copyWith(lastSyncAt: clock.now().toUtc(), clearError: true);
      case CalendarKind.ics:
        return _pullIcs(src);
      case CalendarKind.caldav:
        final c = await client(src);
        await pushQueue(src, c);
        return _pullCalDav(src, c);
    }
  }

  // ---------------------------------------------------------------- ICS

  Future<CalendarSource> _pullIcs(CalendarSource src) async {
    final r = await IcsFeedClient(_dio()).fetch(src.url, etag: src.etag);
    if (r.notModified) return src.copyWith(lastSyncAt: clock.now().toUtc(), clearError: true);
    final events = eventsFromIcs(r.body ?? '', calendarId: src.id, now: clock.now().toUtc());
    await repo.replaceEvents(src.id, events);
    return src.copyWith(etag: r.etag, lastSyncAt: clock.now().toUtc(), clearError: true);
  }

  // ------------------------------------------------------------- CalDAV

  Future<CalendarSource> _pullCalDav(CalendarSource src, CalDavClient c) async {
    final url = Uri.parse(src.url);
    final props = await c.calendarProps(url);
    var s = src;
    if (props.ctag != null && props.ctag == src.ctag && src.lastSyncAt != null) {
      return s.copyWith(lastSyncAt: clock.now().toUtc(), clearError: true);
    }
    var incremental = false;
    if (src.syncToken != null && props.syncToken != null) {
      try {
        final r = await c.syncCollection(url, src.syncToken!);
        await _applyChanges(src, c, url, r.changed);
        if (r.deleted.isNotEmpty) await repo.deleteByHrefs(src.id, r.deleted.map(url.resolve).map((u) => u.path).toList());
        s = s.copyWith(syncToken: r.token ?? props.syncToken);
        incremental = true;
      } on CalDavException catch (e) {
        if (e.status != 403 && e.status != 410 && e.status != 400) rethrow;
        _log.info('${src.name}: sync token rejected (${e.status}), full query');
      }
    }
    if (!incremental) {
      final items = await c.calendarQuery(url, now: clock.now());
      await _applyChanges(src, c, url, items);
      final known = await repo.etagsByHref(src.id);
      final present = items.map((i) => url.resolve(i.href).path).toSet();
      final gone = [for (final h in known.keys) if (!present.contains(h)) h];
      if (gone.isNotEmpty) await _deleteUnlessDirty(src, gone);
      s = s.copyWith(syncToken: props.syncToken, clearSyncToken: props.syncToken == null);
    }
    return s.copyWith(ctag: props.ctag, lastSyncAt: clock.now().toUtc(), clearError: true);
  }

  Future<void> _deleteUnlessDirty(CalendarSource src, List<String> hrefs) async {
    final dirty = (await repo.events(src.id, includeDeleted: true)).where((e) => e.dirty || e.deleted).map((e) => e.href).toSet();
    final safe = [for (final h in hrefs) if (!dirty.contains(h)) h];
    if (safe.isNotEmpty) await repo.deleteByHrefs(src.id, safe);
  }

  Future<void> _applyChanges(CalendarSource src, CalDavClient c, Uri base, List<DavItem> items) async {
    final known = await repo.etagsByHref(src.id);
    final dirtyHrefs = (await repo.events(src.id, includeDeleted: true)).where((e) => e.dirty || e.deleted).map((e) => e.href).toSet();
    final need = <DavItem>[];
    for (final i in items) {
      final path = base.resolve(i.href).path;
      if (dirtyHrefs.contains(path)) continue; // local edit wins until pushed
      if (known.containsKey(path) && known[path] != null && known[path] == i.etag) continue;
      need.add(i);
    }
    final withData = <DavItem>[...need.where((i) => i.data != null && i.data!.isNotEmpty)];
    final missing = need.where((i) => i.data == null || i.data!.isEmpty).map((i) => i.href).toList();
    for (var i = 0; i < missing.length; i += 50) {
      withData.addAll(await c.multiget(base, missing.sublist(i, i + 50 > missing.length ? missing.length : i + 50)));
    }
    final events = <CalendarEvent>[];
    final replacedUids = <String>{};
    for (final item in withData) {
      final path = base.resolve(item.href).path;
      final parsed = eventsFromIcs(item.data ?? '', calendarId: src.id, href: path, etag: item.etag, now: clock.now().toUtc());
      for (final e in parsed) {
        replacedUids.add(e.uid);
        events.add(e);
      }
    }
    if (events.isEmpty) return;
    // A resource holds one UID (master + overrides): drop stale overrides.
    for (final uid in replacedUids) {
      final old = await repo.eventsByUid(src.id, uid);
      final keep = events.where((e) => e.uid == uid).map((e) => e.id).toSet();
      final stale = [for (final o in old) if (!keep.contains(o.id)) o.id];
      if (stale.isNotEmpty) await repo.deleteEvents(stale);
    }
    await repo.upsertEvents(events);
  }

  // --------------------------------------------------------------- push

  Future<void> pushQueue(CalendarSource src, CalDavClient c) async {
    for (final op in await repo.pendingOps(calendarId: src.id)) {
      try {
        await pushOp(src, c, op);
        await repo.completeOp(op.id);
      } on CalDavConflictException {
        await _resolveConflict(src, c, op);
        await repo.completeOp(op.id);
      } on CalDavAuthException {
        rethrow;
      } catch (e) {
        _log.warning('${src.name}: push ${op.kind.name} ${op.uid} failed', e);
        await repo.failOp(op.id, e.toString());
      }
    }
  }

  Uri hrefFor(CalendarSource src, CalendarSyncOp op) {
    final base = Uri.parse(src.url.endsWith('/') ? src.url : '${src.url}/');
    return op.href != null ? base.resolve(op.href!) : base.resolve('${Uri.encodeComponent(op.uid)}.ics');
  }

  Future<void> pushOp(CalendarSource src, CalDavClient c, CalendarSyncOp op) async {
    final href = hrefFor(src, op);
    switch (op.kind) {
      case CalendarSyncOpKind.delete:
        try {
          await c.delete(href, etag: op.etag);
        } on CalDavException catch (e) {
          if (e.status != 404) rethrow;
        }
        final tomb = (await repo.events(src.id, includeDeleted: true)).where((e) => e.uid == op.uid && e.deleted).map((e) => e.id).toList();
        if (tomb.isNotEmpty) await repo.deleteEvents(tomb);
      case CalendarSyncOpKind.create:
      case CalendarSyncOpKind.update:
        final events = await repo.eventsByUid(src.id, op.uid);
        if (events.isEmpty) return;
        final etag = op.kind == CalendarSyncOpKind.create ? null : (op.etag ?? events.firstWhere((e) => !e.isOverride, orElse: () => events.first).etag);
        final newEtag = await c.put(href, icsFromEvents(events, now: clock.now()), etag: etag);
        await repo.upsertEvents([
          for (final e in events) e.copyWith(href: href.path, etag: newEtag, clearEtag: newEtag == null, dirty: false, conflicted: false)
        ]);
        if (newEtag == null) {
          // Servers that omit the ETag: learn it from the next pull.
          final g = await c.get(href);
          if (g.etag != null) await repo.upsertEvents([for (final e in events) e.copyWith(href: href.path, etag: g.etag, dirty: false)]);
        }
    }
  }

  /// 412: the server copy moved on. Keep the server version and flag it so
  /// the UI can show that a local edit was discarded.
  Future<void> _resolveConflict(CalendarSource src, CalDavClient c, CalendarSyncOp op) async {
    final href = hrefFor(src, op);
    final local = (await repo.events(src.id, includeDeleted: true)).where((e) => e.uid == op.uid).map((e) => e.id).toList();
    try {
      final g = await c.get(href);
      final server = eventsFromIcs(g.data ?? '', calendarId: src.id, href: href.path, etag: g.etag, now: clock.now().toUtc());
      if (local.isNotEmpty) await repo.deleteEvents(local);
      await repo.upsertEvents([for (final e in server) e.copyWith(conflicted: true)]);
      _log.info('${src.name}: conflict on ${op.uid}, kept server version');
    } on CalDavException catch (e) {
      if (e.status != 404) rethrow;
      if (local.isNotEmpty) await repo.deleteEvents(local); // deleted on the server
    }
  }
}
