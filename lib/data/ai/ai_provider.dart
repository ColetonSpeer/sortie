/// A block of system prompt. Cacheable blocks get a cache breakpoint on
/// providers that support prompt caching (Anthropic).
class PromptBlock {
  const PromptBlock(this.text, {this.cacheable = false});
  final String text;
  final bool cacheable;
}

class ChatJsonRequest {
  const ChatJsonRequest({
    required this.system,
    required this.user,
    required this.jsonSchema,
    this.maxOutputTokens = 1000,
    this.stricterRetryHint,
  });
  final List<PromptBlock> system;
  final String user;

  /// Enforced server-side on Anthropic, embedded as instructions elsewhere.
  final Map<String, dynamic> jsonSchema;
  final int maxOutputTokens;
  final String? stricterRetryHint;
}

class TokenUsage {
  const TokenUsage({this.input = 0, this.cacheRead = 0, this.cacheWrite = 0, this.output = 0});
  final int input;
  final int cacheRead;
  final int cacheWrite;
  final int output;
  TokenUsage operator +(TokenUsage o) => TokenUsage(
        input: input + o.input,
        cacheRead: cacheRead + o.cacheRead,
        cacheWrite: cacheWrite + o.cacheWrite,
        output: output + o.output,
      );
}

class ChatJsonResult {
  const ChatJsonResult({
    required this.json,
    required this.rawText,
    required this.usage,
    required this.finishReason,
    required this.latency,
  });

  /// Null when no JSON object could be extracted.
  final Map<String, dynamic>? json;
  final String rawText;
  final TokenUsage usage;

  /// end_turn | max_tokens | refusal | stop | length | unknown
  final String finishReason;
  final Duration latency;
}

class ModelInfo {
  const ModelInfo({required this.id, this.displayName, this.contextTokens, this.maxOutputTokens});
  final String id;
  final String? displayName;
  final int? contextTokens;
  final int? maxOutputTokens;
}

class ConnectionTestResult {
  const ConnectionTestResult({
    required this.reachable,
    required this.authOk,
    required this.modelFound,
    required this.jsonValid,
    this.schemaEnforced = false,
    this.cachingObserved,
    this.latency,
    this.warning,
    this.estUsdPer1000,
    this.error,
  });
  final bool reachable;
  final bool authOk;
  final bool modelFound;
  final bool jsonValid;
  final bool schemaEnforced;
  final bool? cachingObserved;
  final Duration? latency;
  final String? warning;
  final double? estUsdPer1000;
  final String? error;
  bool get ok => reachable && authOk && modelFound && jsonValid;
}

class BatchStatus {
  const BatchStatus({required this.id, required this.ended, this.succeeded = 0, this.errored = 0, this.processing = 0});
  final String id;
  final bool ended;
  final int succeeded;
  final int errored;
  final int processing;
}

class BatchResultItem {
  const BatchResultItem({required this.customId, required this.resultType, this.result});
  final String customId;

  /// succeeded | errored | canceled | expired
  final String resultType;
  final ChatJsonResult? result;
}

/// Anthropic Message Batches (50% off). Null on providers without it.
abstract class BatchApi {
  Future<String> submit(List<({String customId, ChatJsonRequest req})> requests);
  Future<BatchStatus> status(String batchId);
  Stream<BatchResultItem> results(String batchId);
  Future<void> cancel(String batchId);
}

class AiProviderException implements Exception {
  const AiProviderException(this.message, {this.statusCode, this.retryable = false, this.retryAfter});
  final String message;
  final int? statusCode;
  final bool retryable;
  final Duration? retryAfter;
  @override
  String toString() => 'AiProviderException($statusCode): $message';
}

abstract class AiProvider {
  String get modelId;
  bool get isLocal;
  bool get supportsPromptCaching;
  bool get supportsSchemaEnforcement;
  int get contextWindowTokens;
  BatchApi? get batch;

  Future<List<ModelInfo>> listModels();
  Future<ConnectionTestResult> testConnection();

  /// One chat completion that must answer with a JSON object. Throws
  /// [AiProviderException] for transport/HTTP failures; malformed output is
  /// returned with `json == null` so the caller can retry with a hint.
  Future<ChatJsonResult> completeJson(ChatJsonRequest req);

  /// Cheap estimate (chars/4 unless the provider offers a counter).
  Future<int> estimateInputTokens(ChatJsonRequest req);
}
