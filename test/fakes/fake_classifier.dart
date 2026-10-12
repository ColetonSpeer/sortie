import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/domain/services/services.dart';
import 'package:uuid/uuid.dart';

/// Scripted classifier for coordination tests: destination chosen by a
/// substring match on the subject, `keep` otherwise. Records every call.
class ScriptedClassifier implements MessageClassifier {
  ScriptedClassifier({Map<String, String>? rules, this.mode = SortMode.moveAfterRead, this.confidence = 0.92, this.layer = SortLayer.model})
      : rules = rules ?? {'invoice': 'Finance', 'newsletter': 'Newsletters'};

  /// subject-substring -> destination folder.
  final Map<String, String> rules;
  SortMode mode;
  double confidence;

  /// Layer stamped on decisions; `rule` decisions bypass suggest-only mode.
  final SortLayer layer;
  final classified = <MessageHeader>[];
  final corrections = <Correction>[];
  final _uuid = const Uuid();

  @override
  Future<List<SortDecision>> classify(String accountId, List<ClassificationInput> inputs, SortConfig config, {bool dryRun = false}) async {
    final out = <SortDecision>[];
    for (final i in inputs) {
      final h = i.header;
      classified.add(h);
      String? dest;
      for (final e in rules.entries) {
        if (h.subject.toLowerCase().contains(e.key.toLowerCase())) dest = e.value;
      }
      out.add(SortDecision(
        id: _uuid.v4(),
        key: h.key,
        sourceFolder: h.folderPath,
        destination: dest ?? 'INBOX',
        confidence: dest == null ? 0.3 : confidence,
        reason: dest == null ? 'no rule' : 'subject matches',
        mode: dest == null ? SortMode.keep : mode,
        layer: layer,
        decidedAt: DateTime.utc(2026, 1, 1),
      ));
    }
    return out;
  }

  @override
  Future<void> recordCorrection(Correction c) async => corrections.add(c);

  @override
  Future<void> bootstrap(String accountId, SortConfig config, {void Function(String)? progress}) async {}

  @override
  Future<bool> isBootstrapped(String accountId) async => true;

  @override
  Future<double> accuracyReplay(String accountId, SortConfig config, {int sample = 200}) async => 1.0;

  @override
  Future<(double, double)> spend() async => (0.0, 0.0);

  @override
  Stream<String> get statusMessages => const Stream.empty();
}
