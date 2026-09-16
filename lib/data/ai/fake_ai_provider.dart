import 'ai_provider.dart';

/// Scripted provider for tests. Responses come from [script] (a function of
/// the request), or from a FIFO [queue]; with neither, every `<message id>`
/// in the user turn gets `INBOX` at confidence 0. Records every request.
class FakeAiProvider implements AiProvider {
  FakeAiProvider({
    this.modelId = 'fake-model',
    this.isLocal = true,
    this.contextWindowTokens = 8192,
    this.supportsPromptCaching = false,
    this.supportsSchemaEnforcement = false,
    this.script,
    this.usage = const TokenUsage(input: 500, output: 60),
    this.latency = const Duration(milliseconds: 5),
  });

  @override
  final String modelId;
  @override
  final bool isLocal;
  @override
  final int contextWindowTokens;
  @override
  final bool supportsPromptCaching;
  @override
  final bool supportsSchemaEnforcement;
  @override
  BatchApi? get batch => null;

  /// Returns the JSON object to answer with, or a [String] for raw
  /// (possibly malformed) text, or throws to simulate a transport error.
  Object? Function(ChatJsonRequest req)? script;
  final List<Object?> queue = [];
  final List<ChatJsonRequest> requests = [];
  TokenUsage usage;
  Duration latency;
  String finishReason = 'end_turn';

  ChatJsonRequest get lastRequest => requests.last;
  int get callCount => requests.length;

  /// Ids `m1..mK` present in the user turn.
  static List<String> messageIds(ChatJsonRequest req) =>
      RegExp(r'<message id="([^"]+)"').allMatches(req.user).map((m) => m.group(1)!).toList();

  /// Convenience: a results object mapping every id to [folder].
  static Map<String, dynamic> allTo(ChatJsonRequest req, String folder, {double confidence = 0.95, String reason = 'scripted'}) => {
        'results': [
          for (final id in messageIds(req)) {'id': id, 'folder': folder, 'confidence': confidence, 'reason': reason},
        ],
      };

  /// Convenience: results from a per-message-id table; ids absent from the
  /// table get INBOX at 0.
  static Map<String, dynamic> table(ChatJsonRequest req, Map<String, (String, double)> byId) => {
        'results': [
          for (final id in messageIds(req))
            if (byId.containsKey(id))
              {'id': id, 'folder': byId[id]!.$1, 'confidence': byId[id]!.$2, 'reason': 'scripted'}
            else
              {'id': id, 'folder': 'INBOX', 'confidence': 0, 'reason': 'no match'},
        ],
      };

  @override
  Future<ChatJsonResult> completeJson(ChatJsonRequest req) async {
    requests.add(req);
    Object? answer;
    if (queue.isNotEmpty) {
      answer = queue.removeAt(0);
    } else if (script != null) {
      answer = script!(req);
    } else {
      answer = allTo(req, 'INBOX', confidence: 0, reason: 'default');
    }
    if (answer is Exception) throw answer;
    if (answer is String) {
      return ChatJsonResult(json: null, rawText: answer, usage: usage, finishReason: finishReason, latency: latency);
    }
    final map = answer as Map<String, dynamic>?;
    return ChatJsonResult(
      json: map,
      rawText: map == null ? '' : map.toString(),
      usage: usage,
      finishReason: finishReason,
      latency: latency,
    );
  }

  @override
  Future<int> estimateInputTokens(ChatJsonRequest req) async {
    var chars = req.user.length;
    for (final b in req.system) {
      chars += b.text.length;
    }
    return (chars / 4).ceil();
  }

  @override
  Future<List<ModelInfo>> listModels() async => [ModelInfo(id: modelId, displayName: 'Fake')];

  @override
  Future<ConnectionTestResult> testConnection() async =>
      const ConnectionTestResult(reachable: true, authOk: true, modelFound: true, jsonValid: true);
}
