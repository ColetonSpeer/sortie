import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

import '../../core/clock.dart';
import '../../data/ai/ai_provider.dart';
import '../../data/local/database.dart' as db;
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import 'cost_meter.dart';
import 'prompt_builder.dart';
import 'sender_stats.dart';

/// Evidence about one folder computed from the local cache.
class ProfileStats {
  const ProfileStats({
    required this.topSenders,
    required this.distinctSenders,
    required this.topListIds,
    required this.topDomains,
    required this.messageCount,
    required this.sampleSubjects,
    this.newest,
  });
  final List<(String, int)> topSenders;
  final int distinctSenders;
  final List<String> topListIds;
  final List<String> topDomains;
  final int messageCount;
  final List<String> sampleSubjects;
  final DateTime? newest;

  static const sendersShown = 5, listsShown = 3, domainsShown = 3, subjectsShown = 12;

  /// Strips Re:/Fwd:/[tags], digits -> #, collapses whitespace.
  static String normalizeSubject(String s) {
    var t = s.replaceAll(RegExp(r'^(\s*(re|fwd?|aw|wg|tr)\s*:\s*)+', caseSensitive: false), '');
    t = t.replaceAll(RegExp(r'\[[^\]]{1,40}\]'), ' ');
    t = t.replaceAll(RegExp(r'\d+'), '#');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.length > 80 ? '${t.substring(0, 80).trimRight()}…' : t;
  }

  static ProfileStats compute(List<MessageHeader> sample, {int? folderCount, Random? rng, SenderStatsService? stats}) {
    final senders = <String, int>{}, lists = <String, int>{}, domains = <String, int>{};
    DateTime? newest;
    for (final h in sample) {
      final from = h.from?.email.toLowerCase();
      if (from != null && from.isNotEmpty) senders[from] = (senders[from] ?? 0) + 1;
      final list = h.listId?.toLowerCase();
      if (list != null && list.isNotEmpty) lists[list] = (lists[list] ?? 0) + 1;
      final d = h.from?.domain ?? '';
      if (d.isNotEmpty && !(stats?.isFreeMail(d) ?? SenderStatsService.freeMailDomains.contains(d))) {
        domains[d] = (domains[d] ?? 0) + 1;
      }
      if (newest == null || h.date.isAfter(newest)) newest = h.date;
    }
    List<MapEntry<String, int>> top(Map<String, int> m, int n) =>
        (m.entries.toList()..sort((a, b) => b.value != a.value ? b.value.compareTo(a.value) : a.key.compareTo(b.key))).take(n).toList();
    final sorted = sample.toList()..sort((a, b) => b.date.compareTo(a.date));
    final seen = <String>{};
    final normalized = <String>[];
    for (final h in sorted) {
      final n = normalizeSubject(h.subject);
      if (n.isEmpty || !seen.add(n.toLowerCase())) continue;
      normalized.add(n);
    }
    final recent = normalized.take(subjectsShown ~/ 2).toList();
    final rest = normalized.skip(subjectsShown ~/ 2).toList()..shuffle(rng ?? Random(sample.length));
    final subjects = [...recent, ...rest.take(subjectsShown - recent.length)];
    return ProfileStats(
      topSenders: top(senders, sendersShown).map((e) => (e.key, e.value)).toList(),
      distinctSenders: senders.length,
      topListIds: top(lists, listsShown).map((e) => e.key).toList(),
      topDomains: top(domains, domainsShown).map((e) => e.key).toList(),
      messageCount: max(folderCount ?? 0, sample.length),
      sampleSubjects: subjects,
      newest: newest,
    );
  }

  String sendersJson() => jsonEncode({'top': [for (final (a, n) in topSenders) {'a': a, 'n': n}], 'distinct': distinctSenders});
  static (List<String>, int) parseSenders(String json) {
    try {
      final j = jsonDecode(json);
      if (j is Map) {
        final top = ((j['top'] as List?) ?? const []).whereType<Map>().map((e) => e['a'].toString()).toList();
        return (top, (j['distinct'] as num?)?.toInt() ?? top.length);
      }
      if (j is List) return (j.map((e) => e.toString()).toList(), j.length);
    } on FormatException {
      // ignore
    }
    return (const [], 0);
  }
}

/// Builds, refreshes and renders folder profiles (`folder_profiles` table).
class FolderProfileService {
  FolderProfileService(this._db, this._messages, this._clock, {required SenderStatsService stats, CostMeter? costs})
      : _stats = stats,
        _costs = costs;
  final db.SortieDatabase _db;
  final MessageRepository _messages;
  final Clock _clock;
  final SenderStatsService _stats;
  final CostMeter? _costs;
  static final _log = Logger('sortie.sorter.profiles');

  static const newFolderMessages = 3;
  static const descriptionsPerCall = 8;
  static const inactiveDays = 365;
  static const neverSortSpecialUse = {'sent', 'drafts', 'trash', 'junk', 'archive', 'all', 'flagged', 'inbox'};
  static const neverSortNames = {
    'sent', 'sent items', 'sent mail', 'sent messages', 'drafts', 'draft', 'trash', 'deleted items', 'deleted messages', 'bin',
    'junk', 'junk e-mail', 'junk email', 'spam', 'archive', 'archives', 'all mail', 'notes', 'outbox', 'starred', 'important',
    'sortie',
  };

  static bool defaultNeverSort({required String path, required String name, String specialUse = 'none'}) {
    if (path.toUpperCase() == 'INBOX') return true;
    if (neverSortSpecialUse.contains(specialUse.toLowerCase())) return true;
    if (path.startsWith('[Gmail]') || path.startsWith('[Google Mail]')) return true;
    return neverSortNames.contains(name.toLowerCase()) || neverSortNames.contains(path.toLowerCase());
  }

  Future<bool> isBootstrapped(String accountId) async {
    final row = await (_db.select(_db.folderProfiles)..where((p) => p.accountId.equals(accountId))..limit(1)).getSingleOrNull();
    return row != null;
  }

  Future<List<db.FolderProfile>> all(String accountId) =>
      (_db.select(_db.folderProfiles)..where((p) => p.accountId.equals(accountId))..orderBy([(p) => OrderingTerm.asc(p.path)])).get();

  bool isSortable(db.FolderProfile p, SortConfig config) => !p.neverSort && !config.neverSortFolders.contains(p.path);

  Future<List<db.FolderProfile>> sortable(String accountId, SortConfig config) async =>
      (await all(accountId)).where((p) => isSortable(p, config)).toList();

  Future<Map<String, db.FolderProfile>> byPath(String accountId) async => {for (final p in await all(accountId)) p.path: p};

  Future<void> bootstrap(String accountId, SortConfig config, {AiProvider? provider, void Function(String)? progress, bool seedStats = true}) async {
    final folders = await (_db.select(_db.folders)..where((f) => f.accountId.equals(accountId))).get();
    progress?.call('Scanning ${folders.length} folders');
    final now = _clock.now();
    final seeds = <MessageHeader>[];
    final allowed = <String>{};
    for (final f in folders) {
      final never = defaultNeverSort(path: f.path, name: f.name, specialUse: f.specialUse) || config.neverSortFolders.contains(f.path) || !f.selectable;
      ProfileStats? st;
      if (!never) {
        final sample = await _messages.sample(accountId, f.path, limit: 200);
        st = ProfileStats.compute(sample, folderCount: f.messageCount, stats: _stats);
        seeds.addAll(sample);
        allowed.add(f.path);
      }
      await _upsert(accountId, f.path, f.name, f.specialUse, never, st, now, keepDescription: true);
    }
    if (seedStats) {
      progress?.call('Learning ${seeds.length} filed messages');
      await _stats.seedBootstrap(accountId, seeds, allowed);
    }
    if (provider != null) await generateDescriptions(accountId, config, provider, progress: progress);
    await _rerenderAll(accountId, config);
    progress?.call('Folder profiles ready');
  }

  Future<void> _upsert(String accountId, String path, String name, String specialUse, bool never, ProfileStats? st, DateTime now,
      {required bool keepDescription}) async {
    final existing = await (_db.select(_db.folderProfiles)..where((p) => p.accountId.equals(accountId) & p.path.equals(path))).getSingleOrNull();
    await _db.into(_db.folderProfiles).insertOnConflictUpdate(db.FolderProfilesCompanion.insert(
          accountId: accountId,
          path: path,
          name: name,
          specialUse: Value(specialUse),
          neverSort: Value(never),
          neverSortSource: Value(existing?.neverSortSource ?? 'default'),
          description: Value(keepDescription ? existing?.description : null),
          descriptionSource: Value(existing?.descriptionSource ?? 'auto'),
          topSendersJson: Value(st?.sendersJson() ?? '{"top":[],"distinct":0}'),
          topListIdsJson: Value(jsonEncode(st?.topListIds ?? const [])),
          topDomainsJson: Value(jsonEncode(st?.topDomains ?? const [])),
          sampleSubjectsJson: Value(jsonEncode(st?.sampleSubjects ?? const [])),
          messageCount: Value(st?.messageCount ?? 0),
          userFiledCount: Value(max(existing?.userFiledCount ?? 0, st?.messageCount ?? 0)),
          lastUserFiledAt: Value(st?.newest?.millisecondsSinceEpoch ?? existing?.lastUserFiledAt),
          profileVersion: Value(existing?.profileVersion ?? 1),
          renderedText: Value(existing?.renderedText),
          updatedAt: now.millisecondsSinceEpoch,
        ));
  }

  /// Recompute stats; regenerate auto descriptions only when the sender mix
  /// changed a lot (Jaccard < 0.5) and not more than weekly.
  Future<void> refresh(String accountId, SortConfig config, {AiProvider? provider, bool force = false}) async {
    final now = _clock.now();
    final folders = {for (final f in await (_db.select(_db.folders)..where((f) => f.accountId.equals(accountId))).get()) f.path: f};
    final stale = <String>[];
    for (final p in await all(accountId)) {
      final f = folders[p.path];
      if (f == null) {
        await (_db.delete(_db.folderProfiles)..where((x) => x.accountId.equals(accountId) & x.path.equals(p.path))).go();
        continue;
      }
      if (!isSortable(p, config)) continue;
      final sample = await _messages.sample(accountId, p.path, limit: 200);
      final st = ProfileStats.compute(sample, folderCount: f.messageCount, stats: _stats);
      final (oldTop, _) = ProfileStats.parseSenders(p.topSendersJson);
      final jaccard = _jaccard(oldTop.toSet(), st.topSenders.map((e) => e.$1).toSet());
      final weekOld = now.millisecondsSinceEpoch - p.updatedAt > const Duration(days: 7).inMilliseconds;
      if (p.descriptionSource == 'auto' && (force || (jaccard < 0.5 && weekOld))) stale.add(p.path);
      await _upsert(accountId, p.path, f.name, f.specialUse, false, st, now, keepDescription: true);
    }
    for (final f in folders.values) {
      if (!(await byPath(accountId)).containsKey(f.path)) {
        final never = defaultNeverSort(path: f.path, name: f.name, specialUse: f.specialUse) || config.neverSortFolders.contains(f.path);
        await _upsert(accountId, f.path, f.name, f.specialUse, never, null, now, keepDescription: false);
      }
    }
    if (provider != null && stale.isNotEmpty) await generateDescriptions(accountId, config, provider, only: stale.toSet());
    await _rerenderAll(accountId, config);
  }

  static double _jaccard(Set<String> a, Set<String> b) => a.isEmpty && b.isEmpty ? 1 : a.intersection(b).length / a.union(b).length;

  static const descriptionSchema = {
    'type': 'object',
    'properties': {
      'descriptions': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {'path': {'type': 'string'}, 'description': {'type': 'string'}},
          'required': ['path', 'description'],
          'additionalProperties': false,
        },
      },
    },
    'required': ['descriptions'],
    'additionalProperties': false,
  };

  /// One model call per 8 folders; folders with < 3 messages get a stock line.
  Future<void> generateDescriptions(String accountId, SortConfig config, AiProvider provider, {Set<String>? only, void Function(String)? progress}) async {
    final targets = (await sortable(accountId, config))
        .where((p) => (only == null || only.contains(p.path)) && p.descriptionSource == 'auto' && !config.folderDescriptions.containsKey(p.path))
        .toList();
    final needModel = <db.FolderProfile>[];
    for (final p in targets) {
      if (p.messageCount < newFolderMessages) {
        await _setDescription(accountId, p.path, '(new folder - no history yet)', 'auto');
      } else {
        needModel.add(p);
      }
    }
    for (var i = 0; i < needModel.length; i += descriptionsPerCall) {
      final chunk = needModel.sublist(i, min(i + descriptionsPerCall, needModel.length));
      progress?.call('Describing folders ${i + 1}-${i + chunk.length} of ${needModel.length}');
      final user = StringBuffer('Write one sentence (max 20 words) describing what the owner files in each folder, based only on this evidence.\n');
      for (final p in chunk) {
        user.writeln('\n### ${p.path}');
        user.writeln(_renderEvidence(p, ProfileCut.none, _clock.now()));
      }
      try {
        final r = await provider.completeJson(ChatJsonRequest(
          system: const [PromptBlock('You describe email folders for a mail sorter. Reply with the JSON object only.')],
          user: user.toString(),
          jsonSchema: descriptionSchema,
          maxOutputTokens: 120 * chunk.length + 100,
        ));
        await _costs?.record(kind: 'bootstrap', modelId: provider.modelId, usage: r.usage, local: provider.isLocal);
        final list = (r.json?['descriptions'] as List?) ?? const [];
        final paths = {for (final p in chunk) p.path};
        for (final d in list.whereType<Map>()) {
          final path = d['path'], desc = d['description'];
          if (path is String && desc is String && paths.contains(path)) {
            await _setDescription(accountId, path, desc.replaceAll(RegExp(r'\s+'), ' ').trim(), 'auto');
          }
        }
      } on AiProviderException catch (e) {
        _log.warning('Description generation failed: ${e.message}');
        return;
      }
    }
  }

  Future<void> _setDescription(String accountId, String path, String text, String source) async {
    await (_db.update(_db.folderProfiles)..where((p) => p.accountId.equals(accountId) & p.path.equals(path)))
        .write(db.FolderProfilesCompanion(description: Value(text), descriptionSource: Value(source)));
  }

  /// User edits stick (`descriptionSource = user`).
  Future<void> setUserDescription(String accountId, String path, String text) => _setDescription(accountId, path, text, 'user');

  Future<void> setNeverSort(String accountId, String path, bool never) async {
    await (_db.update(_db.folderProfiles)..where((p) => p.accountId.equals(accountId) & p.path.equals(path)))
        .write(db.FolderProfilesCompanion(neverSort: Value(never), neverSortSource: const Value('user')));
  }

  Future<void> incrementUserFiled(String accountId, String path, DateTime at) async {
    await _db.customUpdate(
      'UPDATE folder_profiles SET user_filed_count = user_filed_count + 1, last_user_filed_at = ? WHERE account_id = ? AND path = ?',
      variables: [Variable.withInt(at.millisecondsSinceEpoch), Variable.withString(accountId), Variable.withString(path)],
      updates: {_db.folderProfiles},
    );
  }

  Future<void> _rerenderAll(String accountId, SortConfig config) async {
    final now = _clock.now();
    for (final p in await sortable(accountId, config)) {
      final text = render(p, config, now: now);
      if (text == p.renderedText) continue;
      final version = p.renderedText == null ? p.profileVersion : p.profileVersion + 1;
      await (_db.update(_db.folderProfiles)..where((x) => x.accountId.equals(accountId) & x.path.equals(p.path)))
          .write(db.FolderProfilesCompanion(renderedText: Value(text), profileVersion: Value(version), updatedAt: Value(now.millisecondsSinceEpoch)));
      await _db.into(_db.folderProfileHistory).insertOnConflictUpdate(db.FolderProfileHistoryCompanion.insert(
            accountId: accountId,
            path: p.path,
            profileVersion: version,
            renderedText: text,
            createdAt: now.millisecondsSinceEpoch,
          ));
    }
  }

  String description(db.FolderProfile p, SortConfig config) {
    final user = config.folderDescriptions[p.path]?.trim();
    if (user != null && user.isNotEmpty) return user;
    final d = p.description?.trim();
    if (d != null && d.isNotEmpty) return d;
    return p.messageCount < newFolderMessages ? '(new folder - no history yet)' : '(no description yet)';
  }

  String _renderEvidence(db.FolderProfile p, ProfileCut cut, DateTime now) {
    final (senders, distinct) = ProfileStats.parseSenders(p.topSendersJson);
    final lists = (jsonDecode(p.topListIdsJson) as List).cast<String>();
    final subjects = (jsonDecode(p.sampleSubjectsJson) as List).cast<String>();
    final nSenders = cut.index >= ProfileCut.fewerSenders.index ? 3 : ProfileStats.sendersShown;
    final nSubjects = cut.index >= ProfileCut.fewerSubjects.index ? 4 : ProfileStats.subjectsShown;
    final shownSenders = senders.take(nSenders).toList();
    final more = distinct - shownSenders.length;
    final b = StringBuffer();
    b.writeln('Senders: ${shownSenders.isEmpty ? '-' : '${shownSenders.join(', ')}${more > 0 ? ' (+$more)' : ''}'}');
    b.writeln('Lists: ${lists.isEmpty ? '-' : lists.join(', ')}');
    if (subjects.isNotEmpty) b.writeln('Subjects: ${subjects.take(nSubjects).map((s) => '"$s"').join(' · ')}');
    return b.toString().trimRight();
  }

  /// ~100-140 tokens per folder; deterministic for a given profile row.
  String render(db.FolderProfile p, SortConfig config, {ProfileCut cut = ProfileCut.none, DateTime? now}) {
    final t = now ?? _clock.now();
    final inactive = p.lastUserFiledAt != null && t.millisecondsSinceEpoch - p.lastUserFiledAt! > const Duration(days: inactiveDays).inMilliseconds;
    if (cut == ProfileCut.inactiveNamesOnly && inactive) return '### ${p.path}\n(inactive)';
    return '### ${p.path}\n${description(p, config)}\n${_renderEvidence(p, cut, t)}';
  }

  String renderAll(List<db.FolderProfile> profiles, SortConfig config, {ProfileCut cut = ProfileCut.none, DateTime? now}) {
    final sorted = profiles.toList()..sort((a, b) => a.path.compareTo(b.path));
    return sorted.map((p) => render(p, config, cut: cut, now: now)).join('\n\n');
  }
}
