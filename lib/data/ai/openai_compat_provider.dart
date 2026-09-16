import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import 'ai_provider.dart';
import 'ai_retry.dart';
import 'json_extract.dart';

/// Any `/v1/chat/completions` server: Ollama, LM Studio, vLLM, OpenAI...
/// JSON is requested with `response_format: json_object` and the schema is
/// embedded as text; extraction falls back to fences / first balanced object.
class OpenAiCompatProvider implements AiProvider {
  OpenAiCompatProvider({
    required String baseUrl,
    String? apiKey,
    required String model,
    int contextWindowTokens = 8192,
    Dio? dio,
    Sleeper sleep = realSleep,
    RetryPolicy retry = const RetryPolicy(),
  })  : _baseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), ''),
        _apiKey = apiKey,
        _model = model,
        _ctx = contextWindowTokens,
        _sleep = sleep,
        _retry = retry,
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(minutes: 5),
            )) {
    _dio.options.responseType = ResponseType.plain;
    _dio.options.validateStatus = (_) => true;
  }

  static final _log = Logger('sortie.ai.openai');

  final String _baseUrl;
  final String? _apiKey;
  final String _model;
  final int _ctx;
  final Dio _dio;
  final Sleeper _sleep;
  final RetryPolicy _retry;
  bool _responseFormatDisabled = false;
  bool _modelsEndpointMissing = false;

  bool get responseFormatEnabled => !_responseFormatDisabled;
  bool get modelsEndpointMissing => _modelsEndpointMissing;
  String get baseUrl => _baseUrl;

  @override
  String get modelId => _model;
  @override
  bool get isLocal => isLocalUrl(_baseUrl);
  @override
  bool get supportsPromptCaching => false;
  @override
  bool get supportsSchemaEnforcement => false;
  @override
  int get contextWindowTokens => _ctx;
  @override
  BatchApi? get batch => null;

  /// Same rule as `AiSettings.isLocal`: loopback, .local, RFC1918, link-local.
  static bool isLocalUrl(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    if (host == 'localhost' || host == '::1' || host == '[::1]' || host.endsWith('.local')) return true;
    final m = RegExp(r'^(\d+)\.(\d+)\.').firstMatch(host);
    if (m == null) return false;
    final a = int.parse(m.group(1)!), b = int.parse(m.group(2)!);
    return a == 10 || a == 127 || (a == 192 && b == 168) || (a == 172 && b >= 16 && b <= 31) || (a == 169 && b == 254);
  }

  Map<String, String> get _headers => {
        'content-type': 'application/json',
        if (_apiKey != null && _apiKey.isNotEmpty) 'authorization': 'Bearer $_apiKey',
      };

  static String schemaInstruction(Map<String, dynamic> schema) =>
      'Your reply must be a single JSON object matching this JSON schema exactly, with no other text:\n'
      '${jsonEncode(schema)}';

  Map<String, dynamic> buildBody(ChatJsonRequest req) {
    final system = [
      for (final b in req.system)
        if (b.text.isNotEmpty) b.text,
      schemaInstruction(req.jsonSchema),
    ].join('\n\n');
    final user = req.stricterRetryHint == null ? req.user : '${req.user}\n\n${req.stricterRetryHint}';
    return {
      'model': _model,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
      'temperature': 0,
      'max_tokens': req.maxOutputTokens,
      if (!_responseFormatDisabled) 'response_format': {'type': 'json_object'},
    };
  }

  @override
  Future<ChatJsonResult> completeJson(ChatJsonRequest req) async {
    final sw = Stopwatch()..start();
    Map<String, dynamic> json;
    try {
      json = await _retry.run(() => _post('/chat/completions', buildBody(req)), sleep: _sleep);
    } on AiProviderException catch (e) {
      final mentions = e.message.toLowerCase().contains('response_format') ||
          e.message.toLowerCase().contains('response format');
      if (e.statusCode == 400 && mentions && !_responseFormatDisabled) {
        _responseFormatDisabled = true;
        _log.info('Server rejected response_format; retrying without it');
        json = await _retry.run(() => _post('/chat/completions', buildBody(req)), sleep: _sleep);
      } else {
        rethrow;
      }
    }
    sw.stop();
    return parseCompletion(json, sw.elapsed);
  }

  static ChatJsonResult parseCompletion(Map<String, dynamic> j, Duration latency) {
    final choices = (j['choices'] as List?) ?? const [];
    final first = choices.isNotEmpty && choices.first is Map ? choices.first as Map : const <String, dynamic>{};
    final message = first['message'] is Map ? first['message'] as Map : const <String, dynamic>{};
    final content = message['content'];
    final text = content is String
        ? content
        : content is List
            ? content.whereType<Map>().map((p) => (p['text'] as String?) ?? '').join()
            : '';
    final usage = j['usage'] is Map ? j['usage'] as Map : const <String, dynamic>{};
    final details = usage['prompt_tokens_details'] is Map ? usage['prompt_tokens_details'] as Map : const <String, dynamic>{};
    final cached = (details['cached_tokens'] as num?)?.toInt() ?? 0;
    final prompt = (usage['prompt_tokens'] as num?)?.toInt() ?? 0;
    return ChatJsonResult(
      json: extractJsonObject(text),
      rawText: text,
      usage: TokenUsage(
        input: prompt - cached < 0 ? prompt : prompt - cached,
        cacheRead: cached,
        output: (usage['completion_tokens'] as num?)?.toInt() ?? 0,
      ),
      finishReason: (first['finish_reason'] as String?) ?? 'unknown',
      latency: latency,
    );
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) => _request('POST', path, body: body);

  Future<Map<String, dynamic>> _request(String method, String path, {Map<String, dynamic>? body}) async {
    Response<String> res;
    try {
      res = await _dio.request<String>(
        '$_baseUrl$path',
        data: body == null ? null : jsonEncode(body),
        options: Options(method: method, headers: _headers),
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
      _errorMessage(raw, status),
      statusCode: status,
      retryable: RetryPolicy.isRetryableStatus(status),
      retryAfter: parseRetryAfter(res.headers.value('retry-after')),
    );
  }

  static String _errorMessage(String raw, int status) {
    try {
      final j = jsonDecode(raw);
      if (j is Map) {
        final e = j['error'];
        if (e is Map && e['message'] != null) return e['message'].toString();
        if (e is String) return e;
        if (j['message'] != null) return j['message'].toString();
      }
    } on FormatException {
      // fall through
    }
    return raw.isNotEmpty && raw.length < 200 ? 'HTTP $status: $raw' : 'HTTP $status';
  }

  /// `GET /models`; an endpoint that 404s means "type the model name".
  @override
  Future<List<ModelInfo>> listModels() async {
    try {
      final j = await _retry.run(() => _request('GET', '/models'), sleep: _sleep);
      final data = (j['data'] as List?) ?? (j['models'] as List?) ?? const [];
      _modelsEndpointMissing = false;
      return data
          .whereType<Map>()
          .map((m) => ModelInfo(id: (m['id'] ?? m['name']).toString(), displayName: m['name'] as String?))
          .toList();
    } on AiProviderException catch (e) {
      if (e.statusCode == 404) {
        _modelsEndpointMissing = true;
        return const [];
      }
      rethrow;
    }
  }

  @override
  Future<ConnectionTestResult> testConnection() async {
    List<ModelInfo> models;
    try {
      models = await listModels();
    } on AiProviderException catch (e) {
      return ConnectionTestResult(
        reachable: e.statusCode != null,
        authOk: e.statusCode != 401 && e.statusCode != 403,
        modelFound: false,
        jsonValid: false,
        error: friendlyError(e),
      );
    }
    final found = _modelsEndpointMissing || models.any((m) => m.id == _model || m.id.startsWith('$_model:'));
    if (!found) {
      return ConnectionTestResult(
        reachable: true,
        authOk: true,
        modelFound: false,
        jsonValid: false,
        error: 'Model "$_model" not found. Available: ${models.map((m) => m.id).take(8).join(', ')}',
      );
    }
    try {
      final r = await completeJson(ChatJsonRequest(
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
        maxOutputTokens: 60,
      ));
      final warnings = [
        if (_modelsEndpointMissing) 'Server does not list models; using "$_model" as typed.',
        if (_responseFormatDisabled) 'Server rejected response_format; relying on prompt-only JSON.',
        if (r.json == null) 'Model did not answer with JSON.',
      ];
      return ConnectionTestResult(
        reachable: true,
        authOk: true,
        modelFound: true,
        jsonValid: r.json != null,
        latency: r.latency,
        estUsdPer1000: isLocal ? 0 : null,
        warning: warnings.isEmpty ? null : warnings.join(' '),
      );
    } on AiProviderException catch (e) {
      return ConnectionTestResult(
        reachable: e.statusCode != null,
        authOk: e.statusCode != 401 && e.statusCode != 403,
        modelFound: true,
        jsonValid: false,
        error: friendlyError(e),
      );
    }
  }

  String friendlyError(AiProviderException e) {
    final host = Uri.tryParse(_baseUrl)?.host ?? _baseUrl;
    return switch (e.statusCode) {
      401 || 403 => 'API key rejected by $host (${e.statusCode}).',
      404 => 'Endpoint not found at $_baseUrl - try adding /v1 to the base URL.',
      null => e.message.toLowerCase().contains('refused')
          ? 'Connection refused by $host - is Ollama (or your server) running?'
          : 'Cannot reach $host: ${e.message}',
      _ => 'HTTP ${e.statusCode} from $host: ${e.message}',
    };
  }

  @override
  Future<int> estimateInputTokens(ChatJsonRequest req) async {
    var chars = req.user.length + schemaInstruction(req.jsonSchema).length;
    for (final b in req.system) {
      chars += b.text.length;
    }
    return (chars / 4).ceil();
  }
}
