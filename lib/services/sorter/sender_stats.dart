import 'dart:math';

import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../data/local/database.dart' as db;
import '../../domain/entities/entities.dart';

enum StatKeyKind {
  listId('list_id'),
  fromAddr('from_addr'),
  fromDomain('from_domain');

  const StatKeyKind(this.dbName);
  final String dbName;
}

/// Result of the learned layer for one message.
class LearnedVerdict {
  const LearnedVerdict({
    required this.kind,
    required this.key,
    required this.folder,
    required this.effectiveN,
    required this.purity,
    required this.confidence,
    required this.deterministic,
    required this.hint,
    this.vetoed = false,
  });
  final StatKeyKind kind;
  final String key;
  final String folder;
  final double effectiveN;
  final double purity;
  final double confidence;

  /// True when stats alone decide (n >= 5, purity >= 0.9, no active veto).
  final bool deterministic;

  /// Rendered history line for the model when not deterministic.
  final String hint;
  final bool vetoed;

  String get matchedKey => '${kind.dbName}:$key';

  /// Strong history that should make a disagreeing low-confidence model
  /// answer a suggestion only.
  bool get isStrongHint => effectiveN >= 3 && purity >= 1.0;
}

/// Layer 1b: per-sender folder statistics with half-life decay.
/// `weighted_count` is stored as of `last_user_at`; decay is applied on read.
class SenderStatsService {
  SenderStatsService(this._db, this._clock, {Set<String> extraFreeMail = const {}}) : _extraFreeMail = extraFreeMail;
  final db.SortieDatabase _db;
  final Clock _clock;
  final Set<String> _extraFreeMail;

  static const halfLifeDays = 180.0;
  static const deterministicN = 5.0;
  static const deterministicPurity = 0.90;
  static const hintN = 2.0;
  static const vetoRecoveryFilings = 3;
  static const freeMailDomains = {
    'gmail.com', 'googlemail.com', 'outlook.com', 'hotmail.com', 'live.com', 'msn.com', 'icloud.com', 'me.com',
    'proton.me', 'protonmail.com', 'pm.me', 'aol.com', 'gmx.com', 'gmx.de', 'mail.com', 'yandex.com', 'zoho.com',
  };

  bool isFreeMail(String domain) {
    final d = domain.toLowerCase();
    return freeMailDomains.contains(d) || _extraFreeMail.contains(d) || d.startsWith('yahoo.') || d == 'ymail.com';
  }

  static double decayFactor(Duration age) => age.isNegative ? 1.0 : pow(0.5, age.inSeconds / 86400 / halfLifeDays).toDouble();

  double effectiveWeight(db.SenderStat row, DateTime now) {
    final ref = row.lastUserAt == null ? now : DateTime.fromMillisecondsSinceEpoch(row.lastUserAt!);
    return row.weightedCount * decayFactor(now.difference(ref));
  }

  /// Keys for a header in precedence order (list_id > from_addr > from_domain).
  List<(StatKeyKind, String)> keysFor(MessageHeader h) {
    final out = <(StatKeyKind, String)>[];
    final list = h.listId?.trim().toLowerCase();
    if (list != null && list.isNotEmpty) out.add((StatKeyKind.listId, list));
    final from = h.from?.email.trim().toLowerCase();
    if (from != null && from.isNotEmpty) {
      out.add((StatKeyKind.fromAddr, from));
      final domain = h.from!.domain;
      if (domain.isNotEmpty && !isFreeMail(domain)) out.add((StatKeyKind.fromDomain, domain));
    }
    return out;
  }

  Future<List<db.SenderStat>> rowsFor(String accountId, StatKeyKind kind, String key) => (_db.select(_db.senderStats)
        ..where((s) => s.accountId.equals(accountId) & s.keyKind.equals(kind.dbName) & s.key.equals(key)))
      .get();

  /// Deterministic verdict, else the best available hint, else null.
  Future<LearnedVerdict?> lookup(String accountId, MessageHeader h, {required Set<String> allowedFolders}) async {
    final now = _clock.now();
    LearnedVerdict? hint;
    for (final (kind, key) in keysFor(h)) {
      final rows = (await rowsFor(accountId, kind, key)).where((r) => allowedFolders.contains(r.folderPath)).toList();
      if (rows.isEmpty) continue;
      final weights = {for (final r in rows) r.folderPath: effectiveWeight(r, now)};
      final total = weights.values.fold(0.0, (a, b) => a + b);
      if (total <= 0) continue;
      final top = rows.reduce((a, b) => weights[a.folderPath]! >= weights[b.folderPath]! ? a : b);
      final purity = weights[top.folderPath]! / total;
      final conf = min(0.99, purity * (1 - 1 / (total + 1)));
      final vetoed = top.countAgainst > 0 && await isVetoActive(accountId, kind, key, top.folderPath);
      final deterministic = total >= deterministicN && purity >= deterministicPurity && !vetoed;
      final v = LearnedVerdict(
        kind: kind,
        key: key,
        folder: top.folderPath,
        effectiveN: total,
        purity: purity,
        confidence: conf,
        deterministic: deterministic,
        vetoed: vetoed,
        hint: _renderHint(kind, weights, total),
      );
      if (deterministic) return v;
      if (hint == null && total >= hintN) hint = v;
    }
    return hint;
  }

  String _renderHint(StatKeyKind kind, Map<String, double> weights, double total) {
    final what = switch (kind) { StatKeyKind.listId => 'this list', StatKeyKind.fromAddr => 'this sender', StatKeyKind.fromDomain => 'this domain' };
    final parts = weights.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final shares = parts.take(3).map((e) => '${(e.value / total * 100).round()}% ${e.key}').join(', ');
    return 'Owner previously filed ~${total.round()} messages from $what: $shares';
  }

  /// A veto (undo/lateMove/badgeWrong/badgeDismiss against [folder]) blocks
  /// the deterministic path until 3 later user filings into that folder.
  Future<bool> isVetoActive(String accountId, StatKeyKind kind, String key, String folder) async {
    final rows = await (_db.select(_db.corrections)
          ..where((c) => c.accountId.equals(accountId) & _keyColumn(c, kind).equals(key)))
        .get();
    const vetoKinds = {'undo', 'lateMove', 'badgeWrong', 'badgeDismiss'};
    final vetoes = rows.where((c) => vetoKinds.contains(c.kind) && c.predictedFolder == folder).toList();
    if (vetoes.isEmpty) return false;
    final latest = vetoes.map((c) => c.createdAt).reduce(max);
    final after = rows.where((c) => c.actualFolder == folder && c.kind != 'badgeDismiss' && c.createdAt > latest).length;
    return after < vetoRecoveryFilings;
  }

  Expression<String> _keyColumn(db.$CorrectionsTable c, StatKeyKind kind) => switch (kind) {
        StatKeyKind.listId => c.listId,
        StatKeyKind.fromAddr => c.fromAddress,
        StatKeyKind.fromDomain => c.fromDomain,
      };

  /// Decay the stored weight to [at], then add [weight]. Only user-origin
  /// evidence may call this; the sorter's own moves never do.
  Future<void> addEvidence(String accountId, StatKeyKind kind, String key, String folder, double weight, DateTime at) async {
    final existing = await (_db.select(_db.senderStats)
          ..where((s) => s.accountId.equals(accountId) & s.keyKind.equals(kind.dbName) & s.key.equals(key) & s.folderPath.equals(folder)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.senderStats).insert(db.SenderStatsCompanion.insert(
            accountId: accountId,
            keyKind: kind.dbName,
            key: key,
            folderPath: folder,
            count: Value(weight),
            weightedCount: Value(weight),
            firstSeenAt: Value(at.millisecondsSinceEpoch),
            lastUserAt: Value(at.millisecondsSinceEpoch),
          ));
      return;
    }
    final ref = existing.lastUserAt == null ? at : DateTime.fromMillisecondsSinceEpoch(existing.lastUserAt!);
    final newRef = at.isAfter(ref) ? at : ref;
    final decayed = existing.weightedCount * decayFactor(newRef.difference(ref)) + weight * decayFactor(newRef.difference(at));
    await (_db.update(_db.senderStats)
          ..where((s) => s.accountId.equals(accountId) & s.keyKind.equals(kind.dbName) & s.key.equals(key) & s.folderPath.equals(folder)))
        .write(db.SenderStatsCompanion(
      count: Value(existing.count + weight),
      weightedCount: Value(decayed),
      lastUserAt: Value(newRef.millisecondsSinceEpoch),
    ));
  }

  Future<void> addAgainst(String accountId, StatKeyKind kind, String key, String folder) async {
    final existing = await (_db.select(_db.senderStats)
          ..where((s) => s.accountId.equals(accountId) & s.keyKind.equals(kind.dbName) & s.key.equals(key) & s.folderPath.equals(folder)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.senderStats).insert(db.SenderStatsCompanion.insert(
            accountId: accountId,
            keyKind: kind.dbName,
            key: key,
            folderPath: folder,
            countAgainst: const Value(1),
            firstSeenAt: Value(_clock.now().millisecondsSinceEpoch),
          ));
      return;
    }
    await (_db.update(_db.senderStats)
          ..where((s) => s.accountId.equals(accountId) & s.keyKind.equals(kind.dbName) & s.key.equals(key) & s.folderPath.equals(folder)))
        .write(db.SenderStatsCompanion(countAgainst: Value(existing.countAgainst + 1)));
  }

  /// Seed from cached mail in sortable folders (kind=bootstrap, weight 1 per
  /// message, decayed by message age). Replaces existing rows for the account.
  Future<void> seedBootstrap(String accountId, Iterable<MessageHeader> messages, Set<String> allowedFolders) async {
    final groups = <(StatKeyKind, String, String), List<DateTime>>{};
    for (final h in messages) {
      if (!allowedFolders.contains(h.folderPath)) continue;
      for (final (kind, key) in keysFor(h)) {
        groups.putIfAbsent((kind, key, h.folderPath), () => []).add(h.date);
      }
    }
    await _db.transaction(() async {
      await (_db.delete(_db.senderStats)..where((s) => s.accountId.equals(accountId))).go();
      for (final e in groups.entries) {
        final (kind, key, folder) = e.key;
        final newest = e.value.reduce((a, b) => a.isAfter(b) ? a : b);
        final oldest = e.value.reduce((a, b) => a.isBefore(b) ? a : b);
        final weighted = e.value.fold(0.0, (sum, d) => sum + decayFactor(newest.difference(d)));
        await _db.into(_db.senderStats).insert(db.SenderStatsCompanion.insert(
              accountId: accountId,
              keyKind: kind.dbName,
              key: key,
              folderPath: folder,
              count: Value(e.value.length.toDouble()),
              weightedCount: Value(weighted),
              firstSeenAt: Value(oldest.millisecondsSinceEpoch),
              lastUserAt: Value(newest.millisecondsSinceEpoch),
            ));
      }
    });
  }

  /// Nightly: drop rows whose decayed weight is dust and carry nothing else.
  Future<int> nightly(String accountId) async {
    final now = _clock.now();
    final rows = await (_db.select(_db.senderStats)..where((s) => s.accountId.equals(accountId))).get();
    var removed = 0;
    for (final r in rows) {
      if (r.countAgainst == 0 && effectiveWeight(r, now) < 0.05) {
        await (_db.delete(_db.senderStats)
              ..where((s) => s.accountId.equals(accountId) & s.keyKind.equals(r.keyKind) & s.key.equals(r.key) & s.folderPath.equals(r.folderPath)))
            .go();
        removed++;
      }
    }
    return removed;
  }
}
