import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import '../../core/clock.dart';
import '../../core/hashing.dart' show sha256Hex;
import '../../domain/entities/entities.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../sorter/rule_suggestions.dart';
import '../sorter/user_rules.dart';
import 'control_messages.dart';

/// Local stores the shared sections are read from and materialised into.
class SharedConfigDeps {
  const SharedConfigDeps({required this.accounts, required this.rules, required this.calendars, required this.settings, this.suggestions});
  final AccountRepository accounts;
  final SyncableRuleStore rules;
  final CalendarRepository calendars;
  final SettingsRepository settings;

  /// Pending rule suggestions travel inside the `rules` section
  /// (`suggestions` list, additive). Null = this device ignores them.
  final SyncableSuggestionStore? suggestions;
}

/// A section applied from the journal (or a snapshot) on this device.
class SharedConfigSyncEvent {
  const SharedConfigSyncEvent({required this.section, required this.at, this.deviceId});
  final String section;
  final DateTime at;

  /// Writer of the record; null when it came out of a snapshot.
  final String? deviceId;
}

/// Appends a journal record of [type] with [body] (bound to the live
/// [SortJournal] by the coordinator while connected).
typedef SectionAppender = Future<void> Function(String type, Map<String, dynamic> body);

/// Cross-device config sync for one account (protocol "Shared config").
///
/// Four journal sections, each last-writer-wins by UID: `identities`,
/// `rules`, `calendars` (global, mirrored in every account's journal) and
/// `prefs` (AI settings plus the shareable device preferences). Secrets never
/// enter a body: every section is built from `toJson()` forms that exclude
/// them.
///
/// Echo rule: per section this keeps the content hash last seen from the
/// journal (applied) or published. Local changes are debounced and published
/// only when their hash differs from that; applying a record stores its hash
/// before writing locally, so the local watcher that fires afterwards sees an
/// equal hash and stays quiet. The hash is persisted so a restart does not
/// republish. First run: local content with no journal section is published;
/// an empty/default local section is not (so a fresh device never clobbers).
class SharedConfigSync {
  SharedConfigSync({required this.accountId, required SharedConfigDeps deps, required Clock clock, this.debounce = const Duration(seconds: 2)})
      : _deps = deps,
        _clock = clock;

  static final _log = Logger('sortie.coordination.sharedconfig');
  static const sections = [ControlTypes.identities, ControlTypes.rules, ControlTypes.calendars, ControlTypes.prefs];

  final String accountId;
  final Duration debounce;
  final SharedConfigDeps _deps;
  final Clock _clock;

  final _lastHash = <String, String?>{};
  Future<void>? _loading;
  SectionAppender? _append;
  final _subs = <StreamSubscription<void>>[];
  Timer? _debounce;
  final _dirty = <String>{};
  Future<void> _serial = Future.value();
  final _events = StreamController<SharedConfigSyncEvent?>.broadcast();
  SharedConfigSyncEvent? _last;

  SharedConfigSyncEvent? get lastEvent => _last;
  Stream<SharedConfigSyncEvent?> get events async* {
    yield _last;
    yield* _events.stream;
  }

  /// Hash last seen for [section]; null when the journal never carried it.
  String? lastHash(String section) => _lastHash[section];

  // ------------------------------------------------------------ lifecycle

  /// Binds the journal writer, publishes sections whose local content
  /// differs from what the journal last had (offline edits), then follows
  /// the local stores.
  Future<void> attach(SectionAppender append) async {
    _append = append;
    await _ensureLoaded();
    for (final s in sections) {
      await _run(() => _publishIfChanged(s));
    }
    if (_append != append) return; // detached meanwhile
    void mark(String s) => _markDirty(s);
    _subs.addAll([
      _deps.accounts.watchIdentities(accountId).listen((_) => mark(ControlTypes.identities), onError: (Object e) => _log.fine('identities watch: $e')),
      _deps.rules.watch(accountId).listen((_) => mark(ControlTypes.rules), onError: (Object e) => _log.fine('rules watch: $e')),
      if (_deps.suggestions != null)
        _deps.suggestions!.watchPending(accountId).listen((_) => mark(ControlTypes.rules), onError: (Object e) => _log.fine('suggestions watch: $e')),
      _deps.calendars.watchSources().listen((_) => mark(ControlTypes.calendars), onError: (Object e) => _log.fine('calendars watch: $e')),
      _deps.settings.watchAi().listen((_) => mark(ControlTypes.prefs), onError: (Object e) => _log.fine('ai watch: $e')),
      _deps.settings.watchDevice().listen((_) => mark(ControlTypes.prefs), onError: (Object e) => _log.fine('device watch: $e')),
    ]);
  }

  void detach() {
    _append = null;
    _debounce?.cancel();
    _debounce = null;
    _dirty.clear();
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
  }

  Future<void> dispose() async {
    detach();
    await _events.close();
  }

  void _markDirty(String section) {
    if (_append == null) return;
    _dirty.add(section);
    _debounce?.cancel();
    _debounce = Timer(debounce, () {
      final todo = _dirty.toList();
      _dirty.clear();
      for (final s in todo) {
        unawaited(_run(() => _publishIfChanged(s)));
      }
    });
  }

  Future<T> _run<T>(Future<T> Function() fn) {
    final next = _serial.then((_) => fn());
    _serial = next.then((_) {}, onError: (Object e, StackTrace st) => _log.warning('shared config sync failed', e, st));
    return next;
  }

  Future<void> _ensureLoaded() => _loading ??= () async {
        for (final s in sections) {
          _lastHash[s] = await _deps.settings.getString(_hashKey(s));
        }
      }();

  String _hashKey(String section) => 'sharedConfig.$accountId.$section';

  Future<void> _setLastHash(String section, String? h) async {
    _lastHash[section] = h;
    await _deps.settings.setString(_hashKey(section), h);
  }

  // -------------------------------------------------------------- publish

  Future<void> _publishIfChanged(String section) async {
    final append = _append;
    if (append == null) return;
    final body = await localBody(section);
    final h = hashOf(section, body);
    final last = _lastHash[section];
    if (h == last) return;
    if (last == null && isDefaultBody(section, body)) return;
    await _setLastHash(section, h);
    try {
      await append(section, body);
      _log.fine('$accountId: published $section');
    } catch (e) {
      await _setLastHash(section, last); // retry on the next attach / change
      rethrow;
    }
  }

  // ---------------------------------------------------------------- apply

  /// Materialises a journal/snapshot section. Returns false when the body
  /// has no usable content (older app version) or matches what is already
  /// here. The hash is stored before the local write (echo suppression).
  Future<bool> applyRecord(String section, Map<String, dynamic> body, {String? deviceId, DateTime? at}) => _run(() async {
        await _ensureLoaded();
        if (!_usable(section, body)) {
          _log.fine('$accountId: ignoring $section record without content');
          return false;
        }
        final h = hashOf(section, body);
        if (h == _lastHash[section]) return false;
        await _setLastHash(section, h);
        switch (section) {
          case ControlTypes.identities:
            await _applyIdentities(_items(body));
          case ControlTypes.rules:
            await _applyRules(_items(body), body['suggestions'], at: at);
          case ControlTypes.calendars:
            await _applyCalendars(_items(body));
          case ControlTypes.prefs:
            await _applyPrefs(body);
        }
        _last = SharedConfigSyncEvent(section: section, at: at ?? _clock.now(), deviceId: deviceId);
        if (!_events.isClosed) _events.add(_last);
        return true;
      });

  static bool _usable(String section, Map<String, dynamic> body) =>
      section == ControlTypes.prefs ? body['ai'] is Map || body['device'] is Map : body['items'] is List;

  static List<Map<String, dynamic>> _items(Map<String, dynamic> body) =>
      [for (final i in (body['items'] as List?) ?? const []) if (i is Map) i.cast<String, dynamic>()];

  Future<void> _applyIdentities(List<Map<String, dynamic>> items) async {
    final keep = <String>{};
    for (final j in items) {
      try {
        final i = Identity.fromJson({...j, 'accountId': accountId});
        keep.add(i.id);
        await _deps.accounts.upsertIdentity(i);
      } catch (e) {
        _log.warning('$accountId: bad identity record skipped: $e');
      }
    }
    for (final i in await _deps.accounts.identities(accountId)) {
      if (!keep.contains(i.id)) await _deps.accounts.deleteIdentity(i.id);
    }
  }

  Future<void> _applyRules(List<Map<String, dynamic>> items, Object? suggestions, {DateTime? at}) async {
    final rules = <SortRule>[];
    for (final j in items) {
      try {
        rules.add(SortRule.fromJson({...j, 'accountId': accountId}));
      } catch (e) {
        _log.warning('$accountId: bad rule record skipped: $e');
      }
    }
    await _deps.rules.replaceAll(accountId, rules, now: _clock.now());
    // Older writers send no `suggestions` key at all: leave local ones alone.
    final store = _deps.suggestions;
    if (store == null || suggestions is! List) return;
    final parsed = <RuleSuggestion>[];
    for (final j in suggestions) {
      if (j is! Map) continue;
      try {
        parsed.add(RuleSuggestion.fromJson(accountId, j.cast<String, dynamic>()));
      } catch (e) {
        _log.warning('$accountId: bad suggestion record skipped: $e');
      }
    }
    await store.mergeRemote(accountId, parsed, at: at);
  }

  Future<void> _applyCalendars(List<Map<String, dynamic>> items) async {
    final sources = <CalendarSource>[];
    for (final j in items) {
      try {
        sources.add(CalendarSource.fromJson(j));
      } catch (e) {
        _log.warning('$accountId: bad calendar record skipped: $e');
      }
    }
    final keep = {for (final s in sources) s.id};
    await _deps.calendars.upsertSources(sources);
    for (final s in await _deps.calendars.sources()) {
      if (!keep.contains(s.id)) await _deps.calendars.deleteSource(s.id);
    }
  }

  Future<void> _applyPrefs(Map<String, dynamic> body) async {
    final ai = body['ai'];
    if (ai is Map) {
      try {
        await _deps.settings.saveAi(AiSettings.fromJson(ai.cast<String, dynamic>()));
      } catch (e) {
        _log.warning('$accountId: bad ai prefs skipped: $e');
      }
    }
    final dev = body['device'];
    if (dev is Map) {
      final d = await _deps.settings.device();
      await _deps.settings.saveDevice(d.copyWith(
        threadedView: dev['threaded'] as bool?,
        notifyNewMail: dev['notify'] as bool?,
        loadRemoteImages: dev['remoteImages'] as bool?,
        themeMode: dev['theme'] as String?,
      ));
    }
  }

  // ------------------------------------------------------------- content

  /// Wire body of [section] built from the local stores.
  Future<Map<String, dynamic>> localBody(String section) async => switch (section) {
        ControlTypes.identities => {'items': [for (final i in await _deps.accounts.identities(accountId)) i.toJson()]},
        ControlTypes.rules => {
            'items': [for (final r in await _deps.rules.load(accountId)) r.toJson()],
            if (_deps.suggestions != null) 'suggestions': [for (final s in await _deps.suggestions!.pending(accountId)) s.toJson()],
          },
        ControlTypes.calendars => {'items': [for (final s in await _deps.calendars.sources()) s.toJson()]},
        ControlTypes.prefs => prefsBody(await _deps.settings.ai(), await _deps.settings.device()),
        _ => throw ArgumentError.value(section, 'section'),
      };

  /// `{ai, device}`; only the device fields that are not per-device.
  static Map<String, dynamic> prefsBody(AiSettings ai, DeviceSettings d) => {
        'ai': ai.toJson(),
        'device': {'threaded': d.threadedView, 'notify': d.notifyNewMail, 'remoteImages': d.loadRemoteImages, 'theme': d.themeMode},
      };

  /// Sections for a snapshot: only those the journal has carried, so a
  /// snapshot never turns "never shared" into "shared as empty".
  Future<Map<String, Map<String, dynamic>>> snapshotSections() async {
    await _ensureLoaded();
    return {for (final s in sections) if (_lastHash[s] != null) s: await localBody(s)};
  }

  /// True for an empty list or default prefs: nothing worth seeding.
  static bool isDefaultBody(String section, Map<String, dynamic> body) => section == ControlTypes.prefs
      ? hashOf(section, body) == hashOf(section, prefsBody(const AiSettings(), const DeviceSettings()))
      : ((body['items'] as List?) ?? const []).isEmpty && ((body['suggestions'] as List?) ?? const []).isEmpty;

  /// Content hash over a canonical form: keys sorted recursively, list
  /// sections sorted by `id`, and `accountId` dropped (it differs between
  /// devices for the same mail account). The `rules` section also hashes
  /// its pending `suggestions` (absent and empty hash alike).
  static String hashOf(String section, Map<String, dynamic> body) {
    Object? norm;
    if (section == ControlTypes.prefs) {
      norm = {'ai': body['ai'], 'device': body['device']};
    } else {
      final items = _items(body).map((j) => {...j}..remove('accountId')).toList()
        ..sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));
      final suggestions = [for (final s in (body['suggestions'] as List?) ?? const []) if (s is Map) s.cast<String, dynamic>()]
        ..sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));
      norm = section == ControlTypes.rules && suggestions.isNotEmpty ? {'items': items, 'suggestions': suggestions} : items;
    }
    return sha256Hex(jsonEncode(_canonical(norm)));
  }

  static Object? _canonical(Object? v) {
    if (v is Map) {
      final keys = v.keys.map((k) => k.toString()).toList()..sort();
      return {for (final k in keys) k: _canonical(v[k])};
    }
    if (v is List) return [for (final e in v) _canonical(e)];
    return v;
  }
}
