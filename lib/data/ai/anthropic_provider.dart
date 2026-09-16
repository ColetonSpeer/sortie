import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import 'ai_provider.dart';
import 'ai_retry.dart';
import 'anthropic_batch.dart';
import 'json_extract.dart';
import 'price_table.dart';

export 'anthropic_batch.dart' show AnthropicBatchApi;

const anthropicVersion = '2023-06-01';

/// Anthropic Messages API (`POST /v1/messages`) with prompt caching,
/// `output_config.format` JSON schema and the shared retry policy.
class AnthropicProvider implements AiProvider {
  AnthropicProvider({
    required String apiKey,
    required String model,
    String baseUrl = 'https://api.anthropic.com',
    Dio? dio,
    PriceTable? prices,
    Sleeper sleep = realSleep,
    RetryPolicy retry = const RetryPolicy(),
  })  : _apiKey = apiKey,
        _model = model,
        _prices = prices ?? PriceTable.bundled,
        _sleep = sleep,
        _retry = retry,
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 120),
            )) {
    _dio.options.baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');
    _dio.options.responseType = ResponseType.plain;
    _dio.options.validateStatus = (_) => true;
  }

  static final _log = Logger('sortie.ai.anthropic');

  /// Consecutive requests with cache markers but no cache reads before we stop
  /// paying the write premium.
  static const cacheMissLimit = 5;
  static const maxCacheBreakpoints = 4;

  final String _apiKey;
  final String _model;
  final Dio _dio;
  final PriceTable _prices;
  final Sleeper _sleep;
  final RetryPolicy _retry;
  int _cacheMisses = 0;
  bool _cachingDisabled = false;

  /// Still adding `cache_control` markers.
  bool get cachingActive => !_cachingDisabled;
  int get consecutiveCacheMisses => _cacheMisses;

  @override
  String get modelId => _model;
  @override
  bool get isLocal => false;
  @override
  bool get supportsPromptCaching => true;
  @override
  bool get supportsSchemaEnforcement => true;
  @override
  int get contextWindowTokens => _model.startsWith('claude-haiku') ? 200000 : 1000000;
  @override
  BatchApi? get batch => AnthropicBatchApi(this);

  /// `effort: low` is accepted on Sonnet 5 / Opus 5 only; Haiku rejects it.
  static bool supportsEffort(String model) => model.startsWith('claude-sonnet') || model.startsWith('claude-opus');

  Map<String, String> get headers => {
        'x-api-key': _apiKey,
        'anthropic-version': anthropicVersion,
        'content-type': 'application/json',
      };

  /// Request body shared by `/v1/messages` and batch params.
  Map<String, dynamic> buildBody(ChatJsonRequest req, {bool allowCache = true}) {
    final system = <Map<String, dynamic>>[];
    var breakpoints = 0;
    for (final b in req.system) {
      if (b.text.isEmpty) continue;
      final block = <String, dynamic>{'type': 'text', 'text': b.text};
      if (allowCache && !_cachingDisabled && b.cacheable && breakpoints < maxCacheBreakpoints) {
        block['cache_control'] = {'type': 'ephemeral'};
        breakpoints++;
      }
      system.add(block);
    }
    final userText = req.stricterRetryHint == null ? req.user : '${req.user}\n\n${req.stricterRetryHint}';
    final outputConfig = <String, dynamic>{
      'format': {'type': 'json_schema', 'schema': req.jsonSchema},
      if (supportsEffort(_model)) 'effort': 'low',
    };
    return {
      'model': _model,
      'max_tokens': req.maxOutputTokens,
      if (system.isNotEmpty) 'system': system,
      'messages': [
        {'role': 'user', 'content': userText},
      ],
      'output_config': outputConfig,
    };
  }

  bool _hasCacheMarkers(Map<String, dynamic> body) {
    final sys = body['system'];
    return sys is List && sys.any((b) => b is Map && b.containsKey('cache_control'));
  }

  @override
  Future<ChatJsonResult> completeJson(ChatJsonRequest req) async {
    final body = buildBody(req);
    final sw = Stopwatch()..start();
    final json = await _retry.run(() => _post('/v1/messages', body), sleep: _sleep);
    sw.stop();
    final result = parseMessage(json, sw.elapsed);
    if (_hasCacheMarkers(body)) _trackCache(result.usage);
    return result;
  }

  void _trackCache(TokenUsage u) {
    if (u.cacheRead > 0) {
      _cacheMisses = 0;
      return;
    }
    _cacheMisses++;
    if (_cacheMisses >= cacheMissLimit && !_cachingDisabled) {
      _cachingDisabled = true;
      _log.info('No cache reads in $_cacheMisses requests; disabling cache_control markers');
    }
  }

  /// Parses one Messages API response (also used for batch results).
  static ChatJsonResult parseMessage(Map<String, dynamic> m, Duration latency) {
    final content = (m['content'] as List?) ?? const [];
    final text = content
        .whereType<Map>()
        .where((b) => b['type'] == 'text')
        .map((b) => (b['text'] as String?) ?? '')
        .join();
    final usage = parseUsage(m['usage']);
    final stop = (m['stop_reason'] as String?) ?? 'unknown';
    return ChatJsonResult(
      json: extractJsonObject(text),
      rawText: text,
      usage: usage,
      finishReason: stop,
      latency: latency,
    );
  }

  static TokenUsage parseUsage(Object? u) {
    if (u is! Map) return const TokenUsage();
    int n(String k) => (u[k] as num?)?.toInt() ?? 0;
    return TokenUsage(
      input: n('input_tokens'),
      cacheRead: n('cache_read_input_tokens'),
      cacheWrite: n('cache_creation_input_tokens'),
      output: n('output_tokens'),
    );
  }

  /// One HTTP round trip, mapped to [AiProviderException] on failure.
  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) =>
      request('POST', path, body: body);

  Future<Map<String, dynamic>> request(String method, String path, {Map<String, dynamic>? body}) async {
    Response<String> res;
    try {
      res = await _dio.request<String>(
        path,
        data: body == null ? null : jsonEncode(body),
        options: Options(method: method, headers: headers),
      );
    } on DioException catch (e) {
      throw transportException(e);
    }
    final status = res.statusCode ?? 0;
    final raw = res.data ?? '';
    if (status >= 200 && status < 300) {
      final decoded = raw.isEmpty ? <String, dynamic>{} : jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const AiProviderException('Unexpected response shape');
    }
    throw AiProviderException(
      errorMessage(raw, status),
      statusCode: status,
      retryable: RetryPolicy.isRetryableStatus(status),
      retryAfter: parseRetryAfter(res.headers.value('retry-after')),
    );
  }

  /// Raw GET returning the body text (batch results JSONL).
  Future<String> getText(String url) async {
    try {
      final res = await _dio.get<String>(url, options: Options(headers: headers));
      final status = res.statusCode ?? 0;
      if (status >= 200 && status < 300) return res.data ?? '';
      throw AiProviderException(errorMessage(res.data ?? '', status),
          statusCode: status, retryable: RetryPolicy.isRetryableStatus(status));
    } on DioException catch (e) {
      throw transportException(e);
    }
  }

  static String errorMessage(String raw, int status) {
    try {
      final j = jsonDecode(raw);
      if (j is Map && j['error'] is Map) {
        final e = j['error'] as Map;
        return '${e['type'] ?? 'error'}: ${e['message'] ?? 'HTTP $status'}';
      }
    } on FormatException {
      // fall through
    }
    return 'HTTP $status';
  }

  @override
  Future<List<ModelInfo>> listModels() async {
    final json = await _retry.run(() => request('GET', '/v1/models?limit=100'), sleep: _sleep);
    final data = (json['data'] as List?) ?? const [];
    return data
        .whereType<Map>()
        .map((m) => ModelInfo(
              id: m['id'] as String,
              displayName: m['display_name'] as String?,
              contextTokens: (m['max_input_tokens'] as num?)?.toInt(),
              maxOutputTokens: (m['max_tokens'] as num?)?.toInt(),
            ))
        .toList();
  }

  @override
  Future<ConnectionTestResult> testConnection() async {
    List<ModelInfo> models;
    try {
      models = await listModels();
    } on AiProviderException catch (e) {
      final reachable = e.statusCode != null;
      final authOk = e.statusCode != 401 && e.statusCode != 403;
      return ConnectionTestResult(
        reachable: reachable,
        authOk: authOk,
        modelFound: false,
        jsonValid: false,
        error: !reachable
            ? 'Cannot reach api.anthropic.com: ${e.message}'
            : (!authOk ? 'API key rejected (${e.statusCode})' : e.message),
      );
    }
    final found = models.any((m) => m.id == _model);
    if (!found) {
      return ConnectionTestResult(
        reachable: true,
        authOk: true,
        modelFound: false,
        jsonValid: false,
        error: 'Model "$_model" not found. Available: ${models.map((m) => m.id).take(8).join(', ')}',
      );
    }
    final probe = ChatJsonRequest(
      system: const [PromptBlock('You classify short notes. Reply with JSON only.')],
      user: 'Classify: "Your invoice #4821 is attached." Categories: invoice, personal.',
      jsonSchema: const {
        'type': 'object',
        'properties': {
          'category': {'type': 'string', 'enum': ['invoice', 'personal']},
        },
        'required': ['category'],
        'additionalProperties': false,
      },
      maxOutputTokens: 50,
    );
    try {
      final r = await completeJson(probe);
      final valid = r.json != null && r.json!['category'] is String;
      return ConnectionTestResult(
        reachable: true,
        authOk: true,
        modelFound: true,
        jsonValid: valid,
        schemaEnforced: true,
        latency: r.latency,
        estUsdPer1000: _prices.cost(const TokenUsage(input: 600, output: 40), _model) * 1000,
        warning: valid ? null : 'Model answered but not with the expected JSON',
      );
    } on AiProviderException catch (e) {
      return ConnectionTestResult(
        reachable: true,
        authOk: e.statusCode != 401 && e.statusCode != 403,
        modelFound: true,
        jsonValid: false,
        error: e.message,
      );
    }
  }

  @override
  Future<int> estimateInputTokens(ChatJsonRequest req) async {
    var chars = req.user.length + jsonEncode(req.jsonSchema).length;
    for (final b in req.system) {
      chars += b.text.length;
    }
    return (chars / 4).ceil();
  }
}
