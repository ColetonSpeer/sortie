/// One validated model result.
class ValidatedResult {
  const ValidatedResult({required this.id, required this.folder, required this.confidence, required this.reason, required this.resolved});
  final String id;

  /// Resolved exact folder path, or `INBOX`.
  final String folder;
  final double confidence;
  final String reason;

  /// False when the model named an unknown or never-sort folder.
  final bool resolved;
}

class ValidationOutcome {
  const ValidationOutcome({required this.results, required this.missingIds, required this.malformed, this.unknownIds = const []});
  final Map<String, ValidatedResult> results;
  final List<String> missingIds;

  /// No `results` list at all (or not an object). Distinct from missing ids.
  final bool malformed;
  final List<String> unknownIds;
}

/// Client-side validation of the model's JSON: one result per expected id,
/// folder resolved case-insensitively by path then by unique leaf name,
/// never-sort/unknown -> INBOX, confidence clamped, reason trimmed.
class OutputValidator {
  OutputValidator({required Iterable<String> allowedFolders, Iterable<String> neverSort = const []})
      : _neverSort = {for (final p in neverSort) p.toLowerCase()} {
    final leafCounts = <String, int>{};
    for (final p in allowedFolders) {
      _byPath[p.toLowerCase()] = p;
      final leaf = _leaf(p).toLowerCase();
      leafCounts[leaf] = (leafCounts[leaf] ?? 0) + 1;
      _byLeaf[leaf] = p;
    }
    for (final e in leafCounts.entries) {
      if (e.value > 1) _byLeaf.remove(e.key);
    }
  }

  final _byPath = <String, String>{};
  final _byLeaf = <String, String>{};
  final Set<String> _neverSort;

  static const maxReasonWords = 15;
  static const maxReasonChars = 120;
  static const unknownFolderReason = '[unknown folder]';

  static String _leaf(String path) {
    final i = path.lastIndexOf(RegExp(r'[/.]'));
    return i < 0 ? path : path.substring(i + 1);
  }

  /// Exact path for the model's folder string, or null.
  String? resolveFolder(Object? raw) {
    if (raw is! String) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    if (s.toUpperCase() == 'INBOX') return 'INBOX';
    final lower = s.toLowerCase();
    if (_neverSort.contains(lower)) return null;
    return _byPath[lower] ?? _byLeaf[lower] ?? _byLeaf[_leaf(lower)];
  }

  static double clampConfidence(Object? raw) {
    double v;
    if (raw is num) {
      v = raw.toDouble();
    } else if (raw is String) {
      v = double.tryParse(raw.trim()) ?? 0;
    } else {
      return 0;
    }
    if (v.isNaN || v.isInfinite) return 0;
    return v.clamp(0.0, 1.0);
  }

  static String cleanReason(Object? raw) {
    if (raw is! String) return '';
    var r = raw.replaceAll(RegExp(r'[\r\n\t]+'), ' ').replaceAll(RegExp(' {2,}'), ' ').trim();
    final words = r.split(' ');
    if (words.length > maxReasonWords) r = words.take(maxReasonWords).join(' ');
    if (r.length > maxReasonChars) r = r.substring(0, maxReasonChars).trimRight();
    return r;
  }

  ValidationOutcome validate(Map<String, dynamic>? json, List<String> expectedIds) {
    final expected = expectedIds.toSet();
    final results = <String, ValidatedResult>{};
    final unknown = <String>[];
    final list = json?['results'];
    if (json == null || list is! List) {
      return ValidationOutcome(results: const {}, missingIds: expectedIds, malformed: true);
    }
    for (final item in list) {
      if (item is! Map) continue;
      final id = item['id'];
      if (id is! String || !expected.contains(id)) {
        if (id != null) unknown.add(id.toString());
        continue;
      }
      if (results.containsKey(id)) continue;
      final folder = resolveFolder(item['folder']);
      results[id] = folder == null
          ? ValidatedResult(id: id, folder: 'INBOX', confidence: 0, reason: unknownFolderReason, resolved: false)
          : ValidatedResult(
              id: id,
              folder: folder,
              confidence: clampConfidence(item['confidence']),
              reason: cleanReason(item['reason']),
              resolved: true,
            );
    }
    final missing = expectedIds.where((id) => !results.containsKey(id)).toList();
    return ValidationOutcome(results: results, missingIds: missing, malformed: false, unknownIds: unknown);
  }
}
