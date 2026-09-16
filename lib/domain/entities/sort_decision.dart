import 'message.dart';

/// How a decision is applied. `moveAfterRead` waits for `\Seen` + grace.
enum SortMode { moveNow, moveAfterRead, suggestOnly, keep }

/// Which layer produced the decision.
enum SortLayer { rule, learned, model }

enum DecisionStatus { pending, suggested, applied, accepted, kept, undone, corrected, resolved, skipped, failed }

class SortDecision {
  const SortDecision({
    required this.id,
    required this.key,
    required this.sourceFolder,
    required this.destination,
    required this.confidence,
    required this.reason,
    required this.mode,
    required this.layer,
    required this.decidedAt,
    this.matchedKey,
    this.modelId,
    this.folderProfileVersion,
    this.status = DecisionStatus.pending,
    this.deviceId,
    this.epoch,
  });

  final String id;
  final MessageKey key;
  final String sourceFolder;

  /// Destination folder path. `INBOX` means keep (log only).
  final String destination;
  final double confidence;
  final String reason;
  final SortMode mode;
  final SortLayer layer;
  final DateTime decidedAt;
  final String? matchedKey;
  final String? modelId;
  final int? folderProfileVersion;
  final DecisionStatus status;
  final String? deviceId;
  final int? epoch;

  bool get isKeep => mode == SortMode.keep || destination.toUpperCase() == 'INBOX';

  SortDecision copyWith({DecisionStatus? status, SortMode? mode, String? deviceId, int? epoch}) => SortDecision(
        id: id,
        key: key,
        sourceFolder: sourceFolder,
        destination: destination,
        confidence: confidence,
        reason: reason,
        mode: mode ?? this.mode,
        layer: layer,
        decidedAt: decidedAt,
        matchedKey: matchedKey,
        modelId: modelId,
        folderProfileVersion: folderProfileVersion,
        status: status ?? this.status,
        deviceId: deviceId ?? this.deviceId,
        epoch: epoch ?? this.epoch,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'mid': key.messageIdHash,
        'uid': key.uid,
        'uv': key.uidValidity,
        'from': sourceFolder,
        'dest': destination,
        'conf': confidence,
        'reason': reason,
        'mode': mode.name,
        'layer': layer.name,
        'at': decidedAt.toUtc().toIso8601String(),
        if (matchedKey != null) 'key': matchedKey,
        if (modelId != null) 'model': modelId,
        if (folderProfileVersion != null) 'fpv': folderProfileVersion,
        'status': status.name,
      };

  static SortDecision fromJson(String accountId, Map<String, dynamic> j) => SortDecision(
        id: j['id'] as String,
        key: MessageKey(
          accountId: accountId,
          messageIdHash: j['mid'] as String,
          uid: j['uid'] as int?,
          uidValidity: j['uv'] as int?,
        ),
        sourceFolder: (j['from'] as String?) ?? 'INBOX',
        destination: j['dest'] as String,
        confidence: (j['conf'] as num).toDouble(),
        reason: (j['reason'] as String?) ?? '',
        mode: SortMode.values.byName(j['mode'] as String),
        layer: SortLayer.values.byName((j['layer'] as String?) ?? 'model'),
        decidedAt: DateTime.parse(j['at'] as String),
        matchedKey: j['key'] as String?,
        modelId: j['model'] as String?,
        folderProfileVersion: j['fpv'] as int?,
        status: DecisionStatus.values.byName((j['status'] as String?) ?? 'pending'),
      );
}

/// Why a user action counts as feedback for the sorter.
enum CorrectionKind { undo, lateMove, manualFile, badgeWrong, badgeDismiss, badgeRight, externalMove, bootstrap }

class Correction {
  const Correction({
    required this.id,
    required this.key,
    required this.kind,
    required this.weight,
    required this.actualFolder,
    required this.at,
    this.predictedFolder,
    this.decisionId,
    this.fromAddress,
    this.fromDomain,
    this.listId,
    this.subjectNorm,
    this.deviceId,
  });

  final String id;
  final MessageKey key;
  final CorrectionKind kind;
  final double weight;
  final String? predictedFolder;
  final String actualFolder;
  final DateTime at;
  final String? decisionId;
  final String? fromAddress;
  final String? fromDomain;
  final String? listId;
  final String? subjectNorm;
  final String? deviceId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mid': key.messageIdHash,
        'kind': kind.name,
        'w': weight,
        if (predictedFolder != null) 'pred': predictedFolder,
        'actual': actualFolder,
        'at': at.toUtc().toIso8601String(),
        if (decisionId != null) 'dec': decisionId,
        if (fromAddress != null) 'from': fromAddress,
        if (fromDomain != null) 'dom': fromDomain,
        if (listId != null) 'list': listId,
        if (subjectNorm != null) 'subj': subjectNorm,
      };

  static Correction fromJson(String accountId, Map<String, dynamic> j) => Correction(
        id: j['id'] as String,
        key: MessageKey(accountId: accountId, messageIdHash: j['mid'] as String),
        kind: CorrectionKind.values.byName(j['kind'] as String),
        weight: (j['w'] as num).toDouble(),
        predictedFolder: j['pred'] as String?,
        actualFolder: j['actual'] as String,
        at: DateTime.parse(j['at'] as String),
        decisionId: j['dec'] as String?,
        fromAddress: j['from'] as String?,
        fromDomain: j['dom'] as String?,
        listId: j['list'] as String?,
        subjectNorm: j['subj'] as String?,
      );
}
