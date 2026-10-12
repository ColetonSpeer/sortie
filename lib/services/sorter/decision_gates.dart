import '../../domain/entities/entities.dart';
import 'sender_stats.dart';

/// Inputs to the mode table for one candidate decision.
class GateInput {
  const GateInput({
    required this.layer,
    required this.confidence,
    required this.destination,
    required this.header,
    required this.config,
    this.userFiledCount,
    this.inProbation = false,
    this.backlog = false,
    this.hint,
  });
  final SortLayer layer;
  final double confidence;
  final String destination;
  final MessageHeader header;
  final SortConfig config;

  /// User filings into [destination]; null when unknown (treated as new).
  final int? userFiledCount;
  final bool inProbation;
  final bool backlog;
  final LearnedVerdict? hint;
}

/// The mode table from the design doc. Pure function; the pipeline feeds it.
abstract final class DecisionGates {
  static const newFolderFilings = 5;

  static SortMode resolve(GateInput g) {
    if (g.destination.toUpperCase() == 'INBOX') return SortMode.keep;
    final cfg = g.config;
    if (cfg.mode == SortingMode.off) return SortMode.keep;
    if (g.confidence < cfg.suggestThreshold) return SortMode.keep;
    if (g.confidence < cfg.moveThreshold) return SortMode.suggestOnly;
    // Suggest-only applies to AI and learned decisions; the user's own rules
    // always execute (like Thunderbird filters).
    if (cfg.mode == SortingMode.suggestOnly && g.layer != SortLayer.rule) return SortMode.suggestOnly;
    if (g.backlog) return SortMode.suggestOnly;
    if (g.layer == SortLayer.model) {
      if ((g.userFiledCount ?? 0) < newFolderFilings) return SortMode.suggestOnly;
      if (g.inProbation) return SortMode.suggestOnly;
      final h = g.hint;
      if (h != null && h.isStrongHint && h.folder != g.destination && g.confidence < 0.9) return SortMode.suggestOnly;
    }
    return readPolicyMode(cfg.leaveUntilRead, g.header);
  }

  /// none -> moveNow; personalOnly -> bulk moveNow else moveAfterRead; all -> moveAfterRead.
  static SortMode readPolicyMode(LeaveUntilRead policy, MessageHeader h) => switch (policy) {
        LeaveUntilRead.none => SortMode.moveNow,
        LeaveUntilRead.personalOnly => h.isBulk ? SortMode.moveNow : SortMode.moveAfterRead,
        LeaveUntilRead.all => SortMode.moveAfterRead,
      };

  static bool inProbation(SortConfig cfg, DateTime now) =>
      cfg.enabledAt != null && now.toUtc().difference(cfg.enabledAt!.toUtc()).inDays < cfg.probationDays;
}
