import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../../../core/clock.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';
import '../database.dart' as d;
import 'pending_op_codec.dart';

class DriftPendingOpRepository implements PendingOpRepository {
  DriftPendingOpRepository(this.db, {Clock? clock, this.maxAttempts = 50}) : clock = clock ?? SystemClock();
  final d.SortieDatabase db;
  final Clock clock;

  /// After this many failures the op is parked as `failed` and no longer
  /// returned by [pending]; the UI can surface and discard it.
  final int maxAttempts;

  static const statusPending = 'pending';
  static const statusFailed = 'failed';

  PendingOp _toEntity(d.PendingOp r) => PendingOpCodec.decode(
        id: r.id,
        accountId: r.accountId,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt, isUtc: true),
        type: r.type,
        payloadJson: r.payloadJson,
      );

  @override
  Future<void> enqueue(PendingOp op) => db.into(db.pendingOps).insertOnConflictUpdate(d.PendingOpsCompanion(
        id: Value(op.id),
        accountId: Value(op.accountId),
        type: Value(PendingOpCodec.typeOf(op)),
        payloadJson: Value(PendingOpCodec.encode(op)),
        createdAt: Value(op.createdAt.toUtc().millisecondsSinceEpoch),
        status: const Value(statusPending),
      ));

  /// FIFO by creation time; ops in a retry cool-down are skipped.
  @override
  Future<List<PendingOp>> pending(String accountId) async {
    final now = clock.now().toUtc().millisecondsSinceEpoch;
    final rows = await (db.select(db.pendingOps)
          ..where((t) => t.accountId.equals(accountId) & t.status.equals(statusPending) & (t.nextAttemptAt.isNull() | t.nextAttemptAt.isSmallerOrEqualValue(now)))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt), (t) => OrderingTerm.asc(t.id)]))
        .get();
    final out = <PendingOp>[];
    for (final r in rows) {
      try {
        out.add(_toEntity(r));
      } on FormatException catch (e) {
        await markFailed(r.id, 'undecodable: $e', nextAttemptAt: null);
        await (db.update(db.pendingOps)..where((t) => t.id.equals(r.id))).write(const d.PendingOpsCompanion(status: Value(statusFailed)));
      }
    }
    return out;
  }

  /// All ops (any status) for diagnostics.
  Future<List<PendingOp>> allIncludingFailed(String accountId) async {
    final rows = await (db.select(db.pendingOps)..where((t) => t.accountId.equals(accountId))..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> markDone(String id) => (db.delete(db.pendingOps)..where((t) => t.id.equals(id))).go();

  /// Records a failure. Without [nextAttemptAt] an exponential schedule is
  /// used: 30 s · 2^attempts capped at 1 h.
  @override
  Future<void> markFailed(String id, String error, {DateTime? nextAttemptAt}) async {
    final row = await (db.select(db.pendingOps)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    final attempts = row.attempts + 1;
    final delaySec = min(3600, 30 * pow(2, min(attempts - 1, 10)).toInt());
    final next = nextAttemptAt ?? clock.now().toUtc().add(Duration(seconds: delaySec));
    await (db.update(db.pendingOps)..where((t) => t.id.equals(id))).write(d.PendingOpsCompanion(
      attempts: Value(attempts),
      lastError: Value(error.length > 500 ? error.substring(0, 500) : error),
      nextAttemptAt: Value(next.millisecondsSinceEpoch),
      status: Value(attempts >= maxAttempts ? statusFailed : statusPending),
    ));
  }

  @override
  Future<void> markSmtpAccepted(String id) async {
    final row = await (db.select(db.pendingOps)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null || row.type != 'send') return;
    final j = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    j['smtpAccepted'] = true;
    await (db.update(db.pendingOps)..where((t) => t.id.equals(id))).write(d.PendingOpsCompanion(
      payloadJson: Value(jsonEncode(j)),
      // SMTP succeeded: retry the Sent-APPEND promptly.
      nextAttemptAt: const Value(null),
      attempts: const Value(0),
    ));
  }

  @override
  Stream<int> watchCount(String accountId) {
    final count = db.pendingOps.id.count();
    final q = db.selectOnly(db.pendingOps)
      ..addColumns([count])
      ..where(db.pendingOps.accountId.equals(accountId) & db.pendingOps.status.equals(statusPending));
    return q.watchSingle().map((r) => r.read(count) ?? 0);
  }
}
