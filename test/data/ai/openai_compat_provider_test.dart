import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/data/ai/ai_provider.dart';
import 'package:sortie/data/ai/ai_retry.dart';
import 'package:sortie/data/ai/openai_compat_provider.dart';

import 'fake_http_adapter.dart';

void main() {
  late FakeHttpAdapter http;
  final sleeps = <Duration>[];
  Future<void> sleep(Duration d) async => sleeps.add(d);

  OpenAiCompatProvider make({String base = 'http://10.10.11.2:11434/v1', String? key, String model = 'llama3'}) =>
      OpenAiCompatProvider(baseUrl: base, apiKey: key, model: model, dio: fakeDio(http), sleep: sleep);

  final req = ChatJsonRequest(
    system: const [PromptBlock('instructions', cacheable: true), PromptBlock('few-shot', cacheable: true)],
    user: 'Sort these',
    jsonSchema: const {'type': 'object', 'properties': {'results': {'type': 'array'}}},
    maxOutputTokens: 900,
  );
  const answer = '{"results":[{"id":"m1","folder":"A","confidence":0.9,"reason":"r"}]}';

  setUp(() {
    http = FakeHttpAdapter();
    sleeps.clear();
  });

  test('request shape: chat/completions, system+user, schema embedded, temperature 0, response_format json_object', () async {
    http.queue.add(FakeResponse.json(200, openAiCompletion(answer)));
    final r = await make(key: 'k1').completeJson(req);
    final o = http.requests.single;
    expect(o.uri.toString(), 'http://10.10.11.2:11434/v1/chat/completions');
    expect(o.headers['authorization'], 'Bearer k1');
    final b = http.lastBody;
    expect(b['model'], 'llama3');
    expect(b['temperature'], 0);
    expect(b['max_tokens'], 900);
    expect(b['response_format'], {'type': 'json_object'});
    final msgs = b['messages'] as List;
    expect(msgs[0]['role'], 'system');
    expect(msgs[0]['content'], startsWith('instructions\n\nfew-shot\n\nYour reply must be a single JSON object matching this JSON schema'));
    expect(msgs[0]['content'], contains('"results"'));
    expect(msgs[1], {'role': 'user', 'content': 'Sort these'});
    expect(r.json!['results'], isA<List>());
    expect(r.finishReason, 'stop');
    expect(r.usage.input, 300);
    expect(r.usage.output, 20);
  });

  test('no Authorization header without a key; trailing slash trimmed', () async {
    http.queue.add(FakeResponse.json(200, openAiCompletion(answer)));
    await make(base: 'http://localhost:1234/v1/').completeJson(req);
    expect(http.requests.single.headers.containsKey('authorization'), isFalse);
    expect(http.requests.single.uri.toString(), 'http://localhost:1234/v1/chat/completions');
  });

  test('response_format is dropped after a 400 mentioning it, for this and later requests', () async {
    http.queue.add(FakeResponse.json(400, {'error': {'message': "'response_format' is not supported by this model", 'type': 'invalid_request_error'}}));
    http.queue.add(FakeResponse.json(200, openAiCompletion(answer)));
    final p = make();
    final r = await p.completeJson(req);
    expect(r.json, isNotNull);
    expect(http.requests.length, 2);
    expect(http.bodyOf(0).containsKey('response_format'), isTrue);
    expect(http.bodyOf(1).containsKey('response_format'), isFalse);
    expect(p.responseFormatEnabled, isFalse);
    http.queue.add(FakeResponse.json(200, openAiCompletion(answer)));
    await p.completeJson(req);
    expect(http.bodyOf(2).containsKey('response_format'), isFalse);
    expect(sleeps, isEmpty);
  });

  test('other 400s are not retried', () async {
    http.queue.add(FakeResponse.json(400, {'error': {'message': 'context length exceeded'}}));
    await expectLater(make().completeJson(req), throwsA(isA<AiProviderException>().having((e) => e.statusCode, 'status', 400)));
    expect(http.requests.length, 1);
  });

  test('extracts JSON from prose and fences', () async {
    http.queue.add(FakeResponse.json(200, openAiCompletion('Sure! Here is the result:\n```json\n$answer\n```\nHope that helps.')));
    expect((await make().completeJson(req)).json!['results'], isA<List>());
    http.queue.add(FakeResponse.json(200, openAiCompletion('The answer is {"a": {"b": "}"}, "c": "\\"{"} and that is all {')));
    expect((await make().completeJson(req)).json, {'a': {'b': '}'}, 'c': '"{'});
    http.queue.add(FakeResponse.json(200, openAiCompletion('no json here', finish: 'length')));
    final r = await make().completeJson(req);
    expect(r.json, isNull);
    expect(r.finishReason, 'length');
  });

  test('retries 5xx with backoff, cached_tokens map to cacheRead', () async {
    http.queue.add(FakeResponse(502, 'Bad Gateway'));
    http.queue.add(FakeResponse.json(200, {
      'choices': [{'finish_reason': 'stop', 'message': {'content': answer}}],
      'usage': {'prompt_tokens': 1000, 'completion_tokens': 5, 'prompt_tokens_details': {'cached_tokens': 600}},
    }));
    final r = await make().completeJson(req);
    expect(sleeps, [const Duration(seconds: 2)]);
    expect(r.usage.input, 400);
    expect(r.usage.cacheRead, 600);
  });

  test('/models parses, and 404 falls back to free-text model', () async {
    http.queue.add(FakeResponse.json(200, {'data': [{'id': 'llama3:latest', 'object': 'model'}, {'id': 'mistral'}]}));
    final p = make();
    final models = await p.listModels();
    expect(http.requests.single.uri.toString(), 'http://10.10.11.2:11434/v1/models');
    expect(models.map((m) => m.id), ['llama3:latest', 'mistral']);
    expect(p.modelsEndpointMissing, isFalse);

    http.queue.add(FakeResponse(404, '404 page not found'));
    expect(await p.listModels(), isEmpty);
    expect(p.modelsEndpointMissing, isTrue);

    http.queue.add(FakeResponse(404, 'nope'));
    http.queue.add(FakeResponse.json(200, openAiCompletion('{"category":"invoice"}')));
    final t = await p.testConnection();
    expect(t.ok, isTrue);
    expect(t.warning, contains('does not list models'));
    expect(t.estUsdPer1000, 0);
  });

  test('friendly connection-test errors', () async {
    http.queue.add(FakeResponse.json(401, {'error': {'message': 'bad key'}}));
    var t = await make(base: 'https://api.openai.com/v1', key: 'x').testConnection();
    expect(t.authOk, isFalse);
    expect(t.error, contains('API key rejected'));

    http.queue.add(FakeResponse(200, '{"data": []}'));
    t = await make(base: 'http://10.10.11.2:11434').testConnection();
    expect(t.modelFound, isFalse);

    http.queue.add(FakeResponse.json(200, {'data': [{'id': 'llama3'}]}));
    http.queue.add(FakeResponse(404, 'not found'));
    t = await make(base: 'http://10.10.11.2:11434').testConnection();
    expect(t.error, contains('try adding /v1'));

    http.refuseNext = true;
    http.handler = (_) => throw StateError('should not reach');
    final p = OpenAiCompatProvider(baseUrl: 'http://10.10.11.2:11434/v1', model: 'llama3', dio: fakeDio(http), sleep: sleep, retry: const RetryPolicyOnce());
    t = await p.testConnection();
    expect(t.reachable, isFalse);
    expect(t.error, contains('is Ollama'));
  });

  test('isLocal follows the host', () {
    for (final (url, local) in [
      ('http://localhost:11434/v1', true),
      ('http://127.0.0.1:8080', true),
      ('http://10.10.11.2:11434/v1', true),
      ('http://192.168.1.5/v1', true),
      ('http://172.20.0.3/v1', true),
      ('http://172.32.0.3/v1', false),
      ('http://mini.local:1234/v1', true),
      ('https://api.openai.com/v1', false),
      ('https://api.groq.com/openai/v1', false),
    ]) {
      expect(OpenAiCompatProvider.isLocalUrl(url), local, reason: url);
      expect(make(base: url).isLocal, local);
    }
    expect(make().supportsPromptCaching, isFalse);
    expect(make().supportsSchemaEnforcement, isFalse);
    expect(make().batch, isNull);
  });
}

class RetryPolicyOnce extends RetryPolicy {
  const RetryPolicyOnce() : super(maxAttempts: 1);
}
