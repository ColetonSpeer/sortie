/// Where a rule suggestion came from.
enum SuggestionSource { pattern, model }

enum SuggestionStatus { pending, accepted, dismissed }

/// A proposed sorting rule awaiting the owner's decision. `match` uses the
/// same JSON shape as `RuleMatch` (`from`, `fromDomain`, `listId`,
/// `subjectContains`, ...). Shared between devices inside the `rules`
/// journal section (pending ones only).
class RuleSuggestion {
  const RuleSuggestion({
    required this.id,
    required this.accountId,
    required this.match,
    required this.folderPath,
    required this.rationale,
    required this.confidence,
    required this.source,
    required this.evidenceCount,
    required this.examples,
    required this.createdAt,
    this.status = SuggestionStatus.pending,
    this.decidedAt,
    this.createsFolder = false,
  });

  final String id;
  final String accountId;
  final Map<String, dynamic> match;
  final String folderPath;
  final String rationale;
  final double confidence;
  final SuggestionSource source;

  /// [folderPath] does not exist yet; accepting creates it first.
  final bool createsFolder;

  /// Messages / moves that back this suggestion.
  final int evidenceCount;

  /// Up to three example subjects.
  final List<String> examples;
  final DateTime createdAt;
  final SuggestionStatus status;
  final DateTime? decidedAt;

  bool get isPending => status == SuggestionStatus.pending;

  /// `(kind, value)` of the single criterion, e.g. `('from', 'a@b.c')`.
  (String, String) get criterion {
    for (final k in const ['listId', 'from', 'fromDomain', 'subjectContains', 'fromContains', 'fromEndsWith', 'subjectIs', 'toContains']) {
      final v = match[k];
      if (v is String && v.isNotEmpty) return (k, v);
    }
    final e = match.entries.where((e) => e.value is String).firstOrNull;
    return e == null ? ('', '') : (e.key, e.value as String);
  }

  /// "Mail from a@b.c", "Mail from the domain b.c", "List news.b.c", ...
  String get matchLabel {
    final (k, v) = criterion;
    return switch (k) {
      'from' => 'Mail from $v',
      'fromDomain' => 'Mail from the domain $v',
      'listId' => 'Mailing list $v',
      'subjectContains' => 'Subject contains "$v"',
      'subjectIs' => 'Subject is "$v"',
      'fromContains' => 'Sender contains "$v"',
      'fromEndsWith' => 'Sender ends with $v',
      'toContains' => 'Recipient contains "$v"',
      _ => k.isEmpty ? 'Mail' : '$k $v',
    };
  }

  /// Stable key used to spot duplicates: canonical match + folder.
  String get dedupeKey => dedupeKeyFor(match, folderPath);

  static String dedupeKeyFor(Map<String, dynamic> match, String folderPath) {
    final keys = match.keys.where((k) => !k.startsWith('_')).toList()..sort();
    final parts = [for (final k in keys) '$k=${'${match[k]}'.toLowerCase()}'];
    return '${parts.join('&')}|$folderPath';
  }

  RuleSuggestion copyWith({
    Map<String, dynamic>? match,
    String? folderPath,
    String? rationale,
    double? confidence,
    int? evidenceCount,
    List<String>? examples,
    SuggestionStatus? status,
    DateTime? decidedAt,
  }) =>
      RuleSuggestion(
        id: id,
        accountId: accountId,
        match: match ?? this.match,
        folderPath: folderPath ?? this.folderPath,
        rationale: rationale ?? this.rationale,
        confidence: confidence ?? this.confidence,
        source: source,
        evidenceCount: evidenceCount ?? this.evidenceCount,
        examples: examples ?? this.examples,
        createdAt: createdAt,
        status: status ?? this.status,
        decidedAt: decidedAt ?? this.decidedAt,
      );

  /// Wire form for the journal (status is implied: only pending ones travel).
  Map<String, dynamic> toJson() => {
        'id': id,
        'match': match,
        'folder': folderPath,
        'rationale': rationale,
        'confidence': confidence,
        'source': source.name,
        'evidence': evidenceCount,
        'examples': examples,
        'createdAt': createdAt.toUtc().toIso8601String(),
        if (createsFolder) 'newFolder': true,
      };

  static RuleSuggestion fromJson(String accountId, Map<String, dynamic> j) => RuleSuggestion(
        id: j['id'] as String,
        accountId: accountId,
        match: ((j['match'] as Map?) ?? const {}).cast<String, dynamic>(),
        folderPath: j['folder'] as String,
        rationale: (j['rationale'] as String?) ?? '',
        confidence: ((j['confidence'] as num?) ?? 0).toDouble(),
        source: j['source'] == SuggestionSource.model.name ? SuggestionSource.model : SuggestionSource.pattern,
        evidenceCount: ((j['evidence'] as num?) ?? 0).toInt(),
        examples: ((j['examples'] as List?) ?? const []).map((e) => e.toString()).toList(),
        createdAt: DateTime.tryParse((j['createdAt'] as String?) ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        createsFolder: j['newFolder'] == true,
      );
}

/// Outcome of one advisor pass, for the settings snackbar.
class AdvisorRun {
  const AdvisorRun({this.patternSuggestions = 0, this.modelSuggestions = 0, this.costUsd = 0, this.skippedReason, this.modelRan = false});
  final int patternSuggestions;
  final int modelSuggestions;
  final double costUsd;

  /// Why the model pass did not run (null when it ran).
  final String? skippedReason;
  final bool modelRan;

  int get total => patternSuggestions + modelSuggestions;
}
