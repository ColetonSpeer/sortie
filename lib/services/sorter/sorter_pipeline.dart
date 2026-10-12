import 'dart:async';

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../../core/clock.dart';
import '../../data/ai/ai_provider.dart';
import '../../data/ai/price_table.dart';
import '../../data/local/database.dart' as db;
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/services.dart';
import 'accuracy_replay.dart';
import 'cost_meter.dart';
import 'decision_gates.dart';
import 'folder_profiles.dart';
import 'learning/correction_ingester.dart';
import 'output_validator.dart';
import 'prompt_builder.dart';
import 'rule_advisor.dart';
import 'rule_suggestions.dart';
import 'sender_stats.dart';
import 'sort_evidence.dart';
import 'text_cleaner.dart';
import 'user_rules.dart';

typedef ProviderGetter = AiProvider? Function();

class SorterTuning {
  const SorterTuning({
    this.batchSize = 10,
    this.backlogBatchSize = 20,
    this.backlogThreshold = 40,
    this.malformedCooldown = const Duration(hours: 1),
    this.malformedLimit = 3,
    this.queueMaxAge = const Duration(days: 7),
  });
  final int batchSize;
  final int backlogBatchSize;

  /// More inputs than this in one call = backlog run (K=20, suggestOnly).
  final int backlogThreshold;
  final Duration malformedCooldown;
  final int malformedLimit;
  final Duration queueMaxAge;
}

/// rules -> learned stats -> model, one [SortDecision] per input. Never
/// touches IMAP; the coordinator journals and executes.
class SorterService implements MessageClassifier {
  SorterService({
    required db.SortieDatabase database,
    required MessageRepository messages,
    required SettingsRepository settings,
    required ProviderGetter provider,
    required Clock clock,
    required String deviceId,
    PriceTable? prices,
    SorterTuning tuning = const SorterTuning(),
    Set<String> extraFreeMailDomains = const {},
  })  : _db = database,
        _messages = messages,
        _settings = settings,
        _provider = provider,
        _clock = clock,
        _deviceId = deviceId,
        _tuning = tuning {
    stats = SenderStatsService(_db, _clock, extraFreeMail: extraFreeMailDomains);
    costs = CostMeter(_db, _clock, prices: prices);
    profiles = FolderProfileService(_db, _messages, _clock, stats: stats, costs: costs);
    rules = UserRulesService(_db);
    evidence = SortEvidenceStore(_db, _clock, stats: stats);
    suggestions = RuleSuggestionStore(_db, rules: rules, evidence: evidence);
    learning = CorrectionIngester(_db, _clock, stats: stats, profiles: profiles, rules: rules, messages: _messages, deviceId: deviceId, evidence: evidence);
    advisor = RuleAdvisor(
      clock: _clock,
      settings: _settings,
      provider: _provider,
      profiles: profiles,
      rules: rules,
      stats: stats,
      costs: costs,
      evidence: evidence,
      suggestions: suggestions,
    );
    _replay = AccuracyReplay(messages: _messages, profiles: profiles);
  }

  static final _log = Logger('sortie.sorter');
  static const _uuid = Uuid();

  final db.SortieDatabase _db;
  final MessageRepository _messages;
  final SettingsRepository _settings;
  final ProviderGetter _provider;
  final Clock _clock;
  final _autoBootstrapped = <String>{};
  final String _deviceId;
  final SorterTuning _tuning;
  late final SenderStatsService stats;
  late final CostMeter costs;
  late final FolderProfileService profiles;
  late final UserRulesService rules;
  late final SortEvidenceStore evidence;
  late final RuleSuggestionStore suggestions;
  late final CorrectionIngester learning;
  late final RuleAdvisor advisor;
  late final AccuracyReplay _replay;

  final _status = StreamController<String>.broadcast();
  int _consecutiveMalformed = 0;
  Duration? _cooldownUntil;
  CapState _lastCap = CapState.ok;

  @override
  Stream<String> get statusMessages => _status.stream;

  void _say(String msg) {
    _log.info(msg);
    if (_status.hasListener) _status.add(msg);
  }

  bool get inCooldown => _cooldownUntil != null && _clock.monotonic() < _cooldownUntil!;

  @override
  Future<(double, double)> spend() => costs.spend();

  @override
  Future<bool> isBootstrapped(String accountId) => profiles.isBootstrapped(accountId);

  @override
  Future<void> bootstrap(String accountId, SortConfig config, {void Function(String)? progress}) async {
    final ai = await _settings.ai();
    final provider = _provider();
    final useModel = provider != null && !ai.paused && ai.usage != AiUsageMode.off && await costs.capState(ai) != CapState.exceeded;
    await profiles.bootstrap(accountId, config, provider: useModel ? provider : null, progress: progress);
  }

  @override
  Future<void> recordCorrection(Correction c) async => learning.ingest(c, await _settings.sortConfig(c.key.accountId));

  @override
  Future<double> accuracyReplay(String accountId, SortConfig config, {int sample = 200}) =>
      _replay.run(accountId, config, (inputs) => classify(accountId, inputs, config, dryRun: true), sample: sample);

  @override
  Future<List<SortDecision>> classify(String accountId, List<ClassificationInput> inputs, SortConfig config, {bool dryRun = false}) async {
    if (inputs.isEmpty) return const [];
    final now = _clock.now();
    final ai = await _settings.ai();
    var allProfiles = await profiles.all(accountId);
    if (allProfiles.isEmpty && !_autoBootstrapped.contains(accountId)) {
      // No AI bootstrap has run yet (none is needed for rules): build the
      // folder list from the mailbox so rules and learned stats have targets.
      _autoBootstrapped.add(accountId);
      try {
        await profiles.bootstrap(accountId, config, provider: null, seedStats: true);
        allProfiles = await profiles.all(accountId);
      } catch (e) {
        _log.warning('automatic folder bootstrap failed', e);
      }
    }
    final sortable = allProfiles.where((p) => profiles.isSortable(p, config)).toList();
    final allowed = {for (final p in sortable) p.path};
    final neverSort = {for (final p in allProfiles) if (!allowed.contains(p.path)) p.path};
    final userFiled = {for (final p in sortable) p.path: p.userFiledCount};
    final ruleList = await rules.load(accountId);
    final decided = dryRun ? const <String>{} : await _alreadyDecided(accountId, inputs);
    final expired = dryRun ? const <String>{} : await _expiredInQueue(accountId, inputs, now);

    final decisions = List<SortDecision?>.filled(inputs.length, null);
    final pending = <int>[];
    final hints = <int, LearnedVerdict>{};
    for (var i = 0; i < inputs.length; i++) {
      final h = inputs[i].header;
      if (!dryRun && h.folderPath.toUpperCase() != 'INBOX') {
        decisions[i] = _keep(h, '[not in INBOX]', now);
      } else if (h.hasSortieDone) {
        decisions[i] = _keep(h, '[already sorted once]', now);
      } else if (decided.contains(h.messageIdHash)) {
        decisions[i] = _keep(h, '[already decided]', now);
      } else if (config.mode == SortingMode.off) {
        decisions[i] = _keep(h, '[sorting off]', now);
      }
      if (decisions[i] != null) continue;

      final rule = rules.firstMatch(ruleList, h, bodyText: inputs[i].bodyText);
      if (rule != null) {
        if (!dryRun) unawaited(rules.recordHit(rule.id));
        if (rule.action == RuleAction.moveTo && rule.folderPath != null && allowed.contains(rule.folderPath)) {
          final mode = DecisionGates.resolve(GateInput(layer: SortLayer.rule, confidence: 1.0, destination: rule.folderPath!, header: h, config: config));
          decisions[i] = _decision(h, rule.folderPath!, 1.0, 'rule ${rule.id}', mode, SortLayer.rule, now, matchedKey: 'rule:${rule.id}');
        } else {
          decisions[i] = _keep(h, 'rule ${rule.id}: ${rule.action.name}', now, layer: SortLayer.rule, matchedKey: 'rule:${rule.id}');
        }
        continue;
      }
      if (allowed.isEmpty) {
        decisions[i] = _keep(h, '[no sortable folders]', now);
        continue;
      }
      final v = await stats.lookup(accountId, h, allowedFolders: allowed);
      if (v != null && v.deterministic) {
        final mode = DecisionGates.resolve(GateInput(layer: SortLayer.learned, confidence: v.confidence, destination: v.folder, header: h, config: config, userFiledCount: userFiled[v.folder]));
        decisions[i] = _decision(h, v.folder, v.confidence, 'learned: ${v.kind.dbName} ${v.key}', mode, SortLayer.learned, now, matchedKey: v.matchedKey);
        continue;
      }
      if (v != null) hints[i] = v;
      if (expired.contains(h.messageIdHash)) {
        decisions[i] = _keep(h, '[left model queue after 7 days]', now);
        continue;
      }
      pending.add(i);
    }

    if (pending.isNotEmpty) {
      final provider = _provider();
      final skip = await _modelSkipReason(ai, provider, allowed);
      if (skip != null) {
        for (final i in pending) {
          decisions[i] = _keep(inputs[i].header, skip, now);
          // Advisor / off mode: what could not be placed is evidence for the
          // rule advisor, never a model call.
          if (skip == noRuleReason && !dryRun) await evidence.recordUnsorted(accountId, inputs[i].header);
        }
      } else {
        await _runModel(accountId, inputs, pending, config, ai, provider!, sortable, allowed, neverSort, userFiled, hints, decisions, dryRun, now);
      }
    }
    return [for (var i = 0; i < inputs.length; i++) decisions[i] ?? _keep(inputs[i].header, '[no decision]', now)];
  }

  /// Keep-reason used when rules and learned stats could not place a message
  /// and the model is not allowed to classify (advisor / off mode).
  static const noRuleReason = '[no rule]';

  Future<String?> _modelSkipReason(AiSettings ai, AiProvider? provider, Set<String> allowed) async {
    if (!ai.modelClassifies) return noRuleReason;
    if (provider == null) return '[no AI provider configured]';
    if (ai.paused) return '[AI sorting paused]';
    if (allowed.isEmpty) return '[folder profiles not built]';
    if (inCooldown) return '[model cooling down after invalid replies]';
    final cap = await costs.capState(ai);
    if (cap != _lastCap) {
      _lastCap = cap;
      if (cap == CapState.warning) _say('AI spend has reached 80% of a cap');
      if (cap == CapState.exceeded) _say('AI spend cap reached; model sorting paused, rules and learned sorting continue');
    }
    if (cap == CapState.exceeded) return '[spend cap reached]';
    return null;
  }

  Future<void> _runModel(
    String accountId,
    List<ClassificationInput> inputs,
    List<int> pending,
    SortConfig config,
    AiSettings ai,
    AiProvider provider,
    List<db.FolderProfile> sortable,
    Set<String> allowed,
    Set<String> neverSort,
    Map<String, int> userFiled,
    Map<int, LearnedVerdict> hints,
    List<SortDecision?> decisions,
    bool dryRun,
    DateTime now,
  ) async {
    final backlog = inputs.length > _tuning.backlogThreshold;
    final builder = PromptBuilder(privacy: ai.effectivePrivacy, redact: ai.effectiveRedact, contextWindowTokens: provider.contextWindowTokens);
    final renderCache = <ProfileCut, String>{};
    String renderProfiles(ProfileCut cut) => renderCache.putIfAbsent(cut, () => profiles.renderAll(sortable, config, cut: cut, now: now));
    final fewShot = await learning.fewShotText(accountId);
    final validator = OutputValidator(allowedFolders: allowed, neverSort: neverSort);
    final probation = DecisionGates.inProbation(config, now);
    final version = sortable.fold<int>(0, (m, p) => p.profileVersion > m ? p.profileVersion : m);
    final sortedFolders = allowed.toList()..sort();

    var k = backlog ? _tuning.backlogBatchSize : _tuning.batchSize;
    final queue = List<int>.from(pending);
    String? abortReason;
    while (queue.isNotEmpty) {
      if (abortReason != null) {
        for (final i in queue) {
          decisions[i] = _keep(inputs[i].header, abortReason, now);
        }
        break;
      }
      final batch = queue.take(k).toList();
      final msgs = <BatchMessage>[];
      for (var j = 0; j < batch.length; j++) {
        final input = inputs[batch[j]];
        msgs.add(BatchMessage(id: 'm${j + 1}', header: input.header, bodyText: await _bodyFor(accountId, input, ai), hint: hints[batch[j]]?.hint));
      }
      final corrections = await learning.relevantFor(accountId, msgs.map((m) => m.header));
      ChatJsonRequest req = builder.build(renderProfiles: renderProfiles, fewShot: fewShot, messages: msgs, corrections: corrections, allowedFolders: sortedFolders, today: now);

      ChatJsonResult result;
      try {
        result = await provider.completeJson(req);
        await _record(provider, result, dryRun);
        final truncated = result.finishReason == 'max_tokens' || result.finishReason == 'length';
        if (truncated && k > 1) {
          k = (k / 2).ceil();
          continue;
        }
        var outcome = validator.validate(result.json, msgs.map((m) => m.id).toList());
        if (outcome.malformed || truncated) {
          req = builder.build(renderProfiles: renderProfiles, fewShot: fewShot, messages: msgs, corrections: corrections, allowedFolders: sortedFolders, today: now, retryHint: PromptBuilder.malformedRetryHint);
          result = await provider.completeJson(req);
          await _record(provider, result, dryRun);
          outcome = validator.validate(result.json, msgs.map((m) => m.id).toList());
        }
        if (outcome.malformed) {
          _consecutiveMalformed++;
          for (final i in batch) {
            decisions[i] = _keep(inputs[i].header, '[model reply was not valid JSON]', now);
          }
          if (_consecutiveMalformed >= _tuning.malformedLimit) {
            _cooldownUntil = _clock.monotonic() + _tuning.malformedCooldown;
            _say('Model returned invalid output $_consecutiveMalformed times; pausing model sorting for an hour');
            abortReason = '[model cooling down after invalid replies]';
          }
        } else {
          _consecutiveMalformed = 0;
          for (var j = 0; j < batch.length; j++) {
            final i = batch[j];
            final h = inputs[i].header;
            final r = outcome.results[msgs[j].id];
            if (r == null) {
              decisions[i] = _keep(h, '[no answer for this message]', now);
              if (!dryRun) await _requeueOnce(accountId, h, now);
            } else if (!r.resolved) {
              decisions[i] = _keep(h, OutputValidator.unknownFolderReason, now);
            } else {
              final mode = DecisionGates.resolve(GateInput(
                layer: SortLayer.model,
                confidence: r.confidence,
                destination: r.folder,
                header: h,
                config: config,
                userFiledCount: userFiled[r.folder],
                inProbation: probation,
                backlog: backlog,
                hint: hints[i],
              ));
              decisions[i] = _decision(h, r.folder, r.confidence, r.reason, mode, SortLayer.model, now, modelId: provider.modelId, version: version, matchedKey: hints[i]?.matchedKey);
            }
          }
        }
        if (await costs.capState(ai) == CapState.exceeded) abortReason = '[spend cap reached]';
      } on AiProviderException catch (e) {
        _say('AI request failed: ${e.message}');
        abortReason = '[model unavailable]';
        for (final i in batch) {
          decisions[i] = _keep(inputs[i].header, abortReason, now);
        }
      }
      queue.removeRange(0, batch.length);
    }
  }

  Future<void> _record(AiProvider provider, ChatJsonResult r, bool dryRun) => costs.record(
        kind: dryRun ? 'accuracy' : 'sort',
        modelId: provider.modelId,
        usage: r.usage,
        provider: provider.isLocal ? 'local' : 'anthropic',
        local: provider.isLocal,
      );

  Future<String?> _bodyFor(String accountId, ClassificationInput input, AiSettings ai) async {
    if (ai.effectivePrivacy == PrivacyLevel.headersOnly) return null;
    var text = input.bodyText;
    String? html;
    if (text == null || text.trim().isEmpty) {
      final body = await _messages.cachedBody(accountId, input.header.messageIdHash);
      text = body?.text;
      html = body?.html;
      if ((text == null || text.trim().isEmpty) && html == null) text = input.header.snippet;
    }
    final cleaned = TextCleaner.clean(text, html: html);
    return cleaned.isEmpty ? null : cleaned;
  }

  Future<Set<String>> _alreadyDecided(String accountId, List<ClassificationInput> inputs) async {
    final hashes = inputs.map((i) => i.header.messageIdHash).toList();
    final rows = await (_db.select(_db.sortDecisions)
          ..where((d) => d.accountId.equals(accountId) & d.messageIdHash.isIn(hashes) & d.dryRun.equals(false) & d.status.isNotIn(const ['failed', 'skipped', 'resolved'])))
        .get();
    return {for (final r in rows) r.messageIdHash};
  }

  Future<Set<String>> _expiredInQueue(String accountId, List<ClassificationInput> inputs, DateTime now) async {
    final hashes = inputs.map((i) => i.header.messageIdHash).toList();
    final cutoff = now.subtract(_tuning.queueMaxAge).millisecondsSinceEpoch;
    final rows = await (_db.select(_db.sortQueue)..where((q) => q.accountId.equals(accountId) & q.messageIdHash.isIn(hashes) & q.enqueuedAt.isSmallerThanValue(cutoff))).get();
    return {for (final r in rows) r.messageIdHash};
  }

  /// A message the model skipped goes back on the queue once.
  Future<void> _requeueOnce(String accountId, MessageHeader h, DateTime now) async {
    final existing = await (_db.select(_db.sortQueue)..where((q) => q.accountId.equals(accountId) & q.messageIdHash.equals(h.messageIdHash))).getSingleOrNull();
    if (existing != null) return;
    await _db.into(_db.sortQueue).insert(db.SortQueueCompanion.insert(
          accountId: accountId,
          messageIdHash: h.messageIdHash,
          uid: Value(h.uid),
          enqueuedAt: now.millisecondsSinceEpoch,
          attempts: const Value(1),
          lastError: const Value('no answer from model'),
        ));
  }

  SortDecision _keep(MessageHeader h, String reason, DateTime now, {SortLayer layer = SortLayer.model, String? matchedKey}) =>
      _decision(h, 'INBOX', 0, reason, SortMode.keep, layer, now, matchedKey: matchedKey);

  SortDecision _decision(MessageHeader h, String dest, double conf, String reason, SortMode mode, SortLayer layer, DateTime now,
          {String? matchedKey, String? modelId, int? version}) =>
      SortDecision(
        id: _uuid.v4(),
        key: h.key,
        sourceFolder: h.folderPath,
        destination: dest,
        confidence: conf,
        reason: reason,
        mode: mode,
        layer: layer,
        decidedAt: now,
        matchedKey: matchedKey,
        modelId: modelId,
        folderProfileVersion: version,
        deviceId: _deviceId,
      );

  Future<void> dispose() => _status.close();
}
