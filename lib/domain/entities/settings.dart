enum AiProviderKind { none, anthropic, openAiCompat }

enum PrivacyLevel { full, snippet, headersOnly }

/// Which messages wait for `\Seen` before being moved.
enum LeaveUntilRead { none, personalOnly, all }

enum SortingMode { off, suggestOnly, auto }

class AiSettings {
  const AiSettings({
    this.kind = AiProviderKind.none,
    this.model = 'claude-sonnet-5',
    this.baseUrl = '',
    this.contextWindowTokens = 8192,
    this.privacy,
    this.redactSecrets,
    this.dailyCapUsd = 0.50,
    this.monthlyCapUsd = 5.00,
    this.paused = false,
  });

  final AiProviderKind kind;
  final String model;

  /// OpenAI-compatible base URL, e.g. `http://10.10.11.2:11434/v1`. Empty for Anthropic.
  final String baseUrl;
  final int contextWindowTokens;

  /// Null = default for the endpoint (snippet for cloud, full for local).
  final PrivacyLevel? privacy;
  final bool? redactSecrets;
  final double dailyCapUsd;
  final double monthlyCapUsd;
  final bool paused;

  bool get isLocal {
    if (kind != AiProviderKind.openAiCompat) return false;
    final host = Uri.tryParse(baseUrl)?.host ?? '';
    if (host == 'localhost' || host == '::1' || host.endsWith('.local')) return true;
    final m = RegExp(r'^(\d+)\.(\d+)\.').firstMatch(host);
    if (m == null) return false;
    final a = int.parse(m.group(1)!), b = int.parse(m.group(2)!);
    return a == 10 || a == 127 || (a == 192 && b == 168) || (a == 172 && b >= 16 && b <= 31) || (a == 169 && b == 254);
  }

  PrivacyLevel get effectivePrivacy => privacy ?? (isLocal ? PrivacyLevel.full : PrivacyLevel.snippet);
  bool get effectiveRedact => redactSecrets ?? !isLocal;

  AiSettings copyWith({
    AiProviderKind? kind,
    String? model,
    String? baseUrl,
    int? contextWindowTokens,
    PrivacyLevel? privacy,
    bool clearPrivacy = false,
    bool? redactSecrets,
    double? dailyCapUsd,
    double? monthlyCapUsd,
    bool? paused,
  }) =>
      AiSettings(
        kind: kind ?? this.kind,
        model: model ?? this.model,
        baseUrl: baseUrl ?? this.baseUrl,
        contextWindowTokens: contextWindowTokens ?? this.contextWindowTokens,
        privacy: clearPrivacy ? null : (privacy ?? this.privacy),
        redactSecrets: redactSecrets ?? this.redactSecrets,
        dailyCapUsd: dailyCapUsd ?? this.dailyCapUsd,
        monthlyCapUsd: monthlyCapUsd ?? this.monthlyCapUsd,
        paused: paused ?? this.paused,
      );

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'model': model,
        'baseUrl': baseUrl,
        'ctx': contextWindowTokens,
        'privacy': privacy?.name,
        'redact': redactSecrets,
        'dailyCap': dailyCapUsd,
        'monthlyCap': monthlyCapUsd,
        'paused': paused,
      };

  static AiSettings fromJson(Map<String, dynamic> j) => AiSettings(
        kind: AiProviderKind.values.byName((j['kind'] as String?) ?? 'none'),
        model: (j['model'] as String?) ?? 'claude-sonnet-5',
        baseUrl: (j['baseUrl'] as String?) ?? '',
        contextWindowTokens: (j['ctx'] as int?) ?? 8192,
        privacy: j['privacy'] == null ? null : PrivacyLevel.values.byName(j['privacy'] as String),
        redactSecrets: j['redact'] as bool?,
        dailyCapUsd: ((j['dailyCap'] as num?) ?? 0.5).toDouble(),
        monthlyCapUsd: ((j['monthlyCap'] as num?) ?? 5.0).toDouble(),
        paused: (j['paused'] as bool?) ?? false,
      );
}

/// Per-account sorting configuration. Shared between devices through the
/// control-folder journal (`config` record), last writer wins.
class SortConfig {
  const SortConfig({
    this.mode = SortingMode.suggestOnly,
    this.leaveUntilRead = LeaveUntilRead.all,
    this.graceMinutes = 7,
    this.moveThreshold = 0.80,
    this.suggestThreshold = 0.55,
    this.probationDays = 3,
    this.neverSortFolders = const {},
    this.folderDescriptions = const {},
    this.enabledAt,
  });

  final SortingMode mode;
  final LeaveUntilRead leaveUntilRead;
  final int graceMinutes;
  final double moveThreshold;
  final double suggestThreshold;
  final int probationDays;

  /// User-chosen exclusions in addition to the SPECIAL-USE defaults.
  final Set<String> neverSortFolders;

  /// User-edited folder descriptions (path -> text). Sticky over auto ones.
  final Map<String, String> folderDescriptions;
  final DateTime? enabledAt;

  Duration get grace => Duration(minutes: graceMinutes);

  bool get inProbation =>
      enabledAt != null && DateTime.now().toUtc().difference(enabledAt!.toUtc()).inDays < probationDays;

  SortConfig copyWith({
    SortingMode? mode,
    LeaveUntilRead? leaveUntilRead,
    int? graceMinutes,
    double? moveThreshold,
    double? suggestThreshold,
    int? probationDays,
    Set<String>? neverSortFolders,
    Map<String, String>? folderDescriptions,
    DateTime? enabledAt,
  }) =>
      SortConfig(
        mode: mode ?? this.mode,
        leaveUntilRead: leaveUntilRead ?? this.leaveUntilRead,
        graceMinutes: graceMinutes ?? this.graceMinutes,
        moveThreshold: moveThreshold ?? this.moveThreshold,
        suggestThreshold: suggestThreshold ?? this.suggestThreshold,
        probationDays: probationDays ?? this.probationDays,
        neverSortFolders: neverSortFolders ?? this.neverSortFolders,
        folderDescriptions: folderDescriptions ?? this.folderDescriptions,
        enabledAt: enabledAt ?? this.enabledAt,
      );

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'leaveUntilRead': leaveUntilRead.name,
        'grace': graceMinutes,
        'moveThreshold': moveThreshold,
        'suggestThreshold': suggestThreshold,
        'probationDays': probationDays,
        'neverSort': neverSortFolders.toList()..sort(),
        'descriptions': Map.fromEntries(folderDescriptions.entries.toList()..sort((a, b) => a.key.compareTo(b.key))),
        'enabledAt': enabledAt?.toUtc().toIso8601String(),
      };

  static SortConfig fromJson(Map<String, dynamic> j) => SortConfig(
        mode: SortingMode.values.byName((j['mode'] as String?) ?? 'suggestOnly'),
        leaveUntilRead: LeaveUntilRead.values.byName((j['leaveUntilRead'] as String?) ?? 'all'),
        graceMinutes: (j['grace'] as int?) ?? 7,
        moveThreshold: ((j['moveThreshold'] as num?) ?? 0.8).toDouble(),
        suggestThreshold: ((j['suggestThreshold'] as num?) ?? 0.55).toDouble(),
        probationDays: (j['probationDays'] as int?) ?? 3,
        neverSortFolders: ((j['neverSort'] as List?) ?? const []).cast<String>().toSet(),
        folderDescriptions: ((j['descriptions'] as Map?) ?? const {}).cast<String, String>(),
        enabledAt: j['enabledAt'] == null ? null : DateTime.parse(j['enabledAt'] as String),
      );
}

/// Device-local preferences that are not shared.
class DeviceSettings {
  const DeviceSettings({
    this.mayLead = true,
    this.preferThisDevice = false,
    this.androidForegroundService = false,
    this.minimizeToTray = true,
    this.launchAtStartup = false,
    this.notifyNewMail = true,
    this.loadRemoteImages = false,
    this.themeMode = 'system',
    this.threadedView = true,
    this.htmlMailMode = 'auto',
  });
  final bool mayLead;
  final bool preferThisDevice;
  final bool androidForegroundService;
  final bool minimizeToTray;
  final bool launchAtStartup;
  final bool notifyNewMail;
  final bool loadRemoteImages;
  final String themeMode;

  /// Group the message list by conversation (References / In-Reply-To).
  final bool threadedView;

  /// How HTML mail opens by default: `auto` (rendered HTML) or `plainText`.
  final String htmlMailMode;

  DeviceSettings copyWith({
    bool? mayLead,
    bool? preferThisDevice,
    bool? androidForegroundService,
    bool? minimizeToTray,
    bool? launchAtStartup,
    bool? notifyNewMail,
    bool? loadRemoteImages,
    String? themeMode,
    bool? threadedView,
    String? htmlMailMode,
  }) =>
      DeviceSettings(
        mayLead: mayLead ?? this.mayLead,
        preferThisDevice: preferThisDevice ?? this.preferThisDevice,
        androidForegroundService: androidForegroundService ?? this.androidForegroundService,
        minimizeToTray: minimizeToTray ?? this.minimizeToTray,
        launchAtStartup: launchAtStartup ?? this.launchAtStartup,
        notifyNewMail: notifyNewMail ?? this.notifyNewMail,
        loadRemoteImages: loadRemoteImages ?? this.loadRemoteImages,
        themeMode: themeMode ?? this.themeMode,
        threadedView: threadedView ?? this.threadedView,
        htmlMailMode: htmlMailMode ?? this.htmlMailMode,
      );

  Map<String, dynamic> toJson() => {
        'mayLead': mayLead,
        'prefer': preferThisDevice,
        'fgService': androidForegroundService,
        'tray': minimizeToTray,
        'autostart': launchAtStartup,
        'notify': notifyNewMail,
        'remoteImages': loadRemoteImages,
        'theme': themeMode,
        'threaded': threadedView,
        'htmlMode': htmlMailMode,
      };

  static DeviceSettings fromJson(Map<String, dynamic> j) => DeviceSettings(
        mayLead: (j['mayLead'] as bool?) ?? true,
        preferThisDevice: (j['prefer'] as bool?) ?? false,
        androidForegroundService: (j['fgService'] as bool?) ?? false,
        minimizeToTray: (j['tray'] as bool?) ?? true,
        launchAtStartup: (j['autostart'] as bool?) ?? false,
        notifyNewMail: (j['notify'] as bool?) ?? true,
        loadRemoteImages: (j['remoteImages'] as bool?) ?? false,
        themeMode: (j['theme'] as String?) ?? 'system',
        threadedView: (j['threaded'] as bool?) ?? true,
        htmlMailMode: (j['htmlMode'] as String?) ?? 'auto',
      );
}
