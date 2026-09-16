import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/data/ai/ai_provider.dart';
import 'package:sortie/data/ai/ai_retry.dart';
import 'package:sortie/data/ai/anthropic_provider.dart';

import 'fake_http_adapter.dart';

void main() {
  late FakeHttpAdapter http;
  final sleeps = <Duration>[];
  Future<void> sleep(Duration d) async => sleeps.add(d);

  AnthropicProvider make({String model = 'claude-sonnet-5'}) => AnthropicProvider(apiKey: 'sk-ant-test', model: model, dio: fakeDio(http), sleep: sleep);

  final req = ChatJsonRequest(
    system: const [PromptBlock('stable instructions', cacheable: true), PromptBlock('few-shot', cacheable: true), PromptBlock('volatile')],
    user: 'Sort these',
    jsonSchema: const {'type': 'object', 'properties': {'results': {'type': 'array'}}, 'required': ['results'], 'additionalProperties': false},
    maxOutputTokens: 1000,
  );
  final answer = {'results': [{'id': 'm1', 'folder': 'A', 'confidence': 0.9, 'reason': 'r'}]};

  setUp(() {
    http = FakeHttpAdapter();
    sleeps.clear();
  });

  test('request shape: headers, cache_control on cacheable blocks, json_schema format, effort low, no temperature', () async {
    http.queue.add(FakeResponse.json(200, anthropicMessage(answer, cacheRead: 1200)));
    final r = await make().completeJson(req);
    final o = http.requests.single;
    expect(o.uri.toString(), 'https://api.anthropic.com/v1/messages');
    expect(o.method, 'POST');
    expect(o.headers['x-api-key'], 'sk-ant-test');
    expect(o.headers['anthropic-version'], '2023-06-01');
    final b = http.lastBody;
    expect(b['model'], 'claude-sonnet-5');
    expect(b['max_tokens'], 1000);
    expect(b.containsKey('temperature'), isFalse);
    expect(b.containsKey('top_p'), isFalse);
    expect(b.containsKey('stop_sequences'), isFalse);
    final system = b['system'] as List;
    expect(system.length, 3);
    expect(system[0], {'type': 'text', 'text': 'stable instructions', 'cache_control': {'type': 'ephemeral'}});
    expect(system[1]['cache_control'], {'type': 'ephemeral'});
    expect((system[2] as Map).containsKey('cache_control'), isFalse);
    expect(b['messages'], [{'role': 'user', 'content': 'Sort these'}]);
    expect(b['output_config'], {'format': {'type': 'json_schema', 'schema': req.jsonSchema}, 'effort': 'low'});
    expect(r.json, answer);
    expect(r.finishReason, 'end_turn');
    expect(r.usage.input, 500);
    expect(r.usage.cacheRead, 1200);
    expect(r.usage.output, 40);
  });

  test('effort only on sonnet/opus, never haiku; at most 4 cache breakpoints', () async {
    for (final (model, hasEffort) in [('claude-haiku-4-5', false), ('claude-opus-5', true), ('claude-sonnet-5-20261001', true)]) {
      http.queue.add(FakeResponse.json(200, anthropicMessage(answer)));
      await make(model: model).completeJson(req);
      expect((http.lastBody['output_config'] as Map).containsKey('effort'), hasEffort, reason: model);
    }
    http.queue.add(FakeResponse.json(200, anthropicMessage(answer)));
    await make().completeJson(ChatJsonRequest(system: [for (var i = 0; i < 6; i++) PromptBlock('b$i', cacheable: true)], user: 'u', jsonSchema: const {}));
    final marked = (http.lastBody['system'] as List).where((s) => (s as Map).containsKey('cache_control')).length;
    expect(marked, 4);
  });

  test('retry hint is appended to the user turn', () async {
    http.queue.add(FakeResponse.json(200, anthropicMessage(answer)));
    await make().completeJson(ChatJsonRequest(system: const [], user: 'u', jsonSchema: const {}, stricterRetryHint: 'ONLY JSON'));
    expect(http.lastBody['messages'][0]['content'], 'u\n\nONLY JSON');
    expect(http.lastBody.containsKey('system'), isFalse);
  });

  test('429 honours retry-after, 529/5xx back off exponentially, then succeeds', () async {
    http.queue.addAll([
      FakeResponse.json(429, {'error': {'type': 'rate_limit_error', 'message': 'slow down'}}, headers: {'retry-after': '7'}),
      FakeResponse.json(529, {'error': {'type': 'overloaded_error', 'message': 'busy'}}),
      FakeResponse.json(500, {'error': {'type': 'api_error', 'message': 'oops'}}),
      FakeResponse.json(200, anthropicMessage(answer)),
    ]);
    final r = await make().completeJson(req);
    expect(r.json, answer);
    expect(http.requests.length, 4);
    expect(sleeps, [const Duration(seconds: 7), const Duration(seconds: 4), const Duration(seconds: 8)]);
  });

  test('400/401/403 are never retried and surface the API message', () async {
    for (final code in [400, 401, 403, 404]) {
      http = FakeHttpAdapter()..queue.add(FakeResponse.json(code, {'error': {'type': 'invalid_request_error', 'message': 'bad $code'}}));
      await expectLater(make().completeJson(req), throwsA(isA<AiProviderException>().having((e) => e.statusCode, 'status', code).having((e) => e.retryable, 'retryable', false).having((e) => e.message, 'message', contains('bad $code'))));
      expect(http.requests.length, 1);
    }
    expect(sleeps, isEmpty);
  });

  test('gives up after 6 attempts', () async {
    http.handler = (_) => FakeResponse.json(503, {'error': {'type': 'api_error', 'message': 'down'}});
    await expectLater(make().completeJson(req), throwsA(isA<AiProviderException>().having((e) => e.statusCode, 'status', 503)));
    expect(http.requests.length, 6);
    expect(sleeps.length, 5);
    expect(sleeps.last, const Duration(seconds: 32));
  });

  test('transport errors are retryable', () async {
    http.refuseNext = true;
    http.queue.add(FakeResponse.json(200, anthropicMessage(answer)));
    final r = await make().completeJson(req);
    expect(r.json, answer);
    expect(http.requests.length, 2);
  });

  test('retry-after parsing accepts seconds and HTTP dates', () {
    expect(parseRetryAfter('3'), const Duration(seconds: 3));
    expect(parseRetryAfter('garbage'), isNull);
    final d = parseRetryAfter(HttpDate.parse('Wed, 16 Sep 2026 09:00:00 GMT').toString()) ?? Duration.zero;
    expect(d.isNegative, isFalse);
  });

  test('cache_control is dropped after 5 requests with zero cache reads, restored by a hit', () async {
    final p = make();
    for (var i = 0; i < 5; i++) {
      http.queue.add(FakeResponse.json(200, anthropicMessage(answer, cacheRead: 0)));
      await p.completeJson(req);
      expect((http.lastBody['system'] as List).any((s) => (s as Map).containsKey('cache_control')), isTrue, reason: 'request $i still tries');
    }
    expect(p.cachingActive, isFalse);
    http.queue.add(FakeResponse.json(200, anthropicMessage(answer, cacheRead: 0)));
    await p.completeJson(req);
    expect((http.lastBody['system'] as List).any((s) => (s as Map).containsKey('cache_control')), isFalse);

    final p2 = make();
    for (var i = 0; i < 4; i++) {
      http.queue.add(FakeResponse.json(200, anthropicMessage(answer, cacheRead: 0)));
      await p2.completeJson(req);
    }
    http.queue.add(FakeResponse.json(200, anthropicMessage(answer, cacheRead: 900)));
    await p2.completeJson(req);
    expect(p2.consecutiveCacheMisses, 0);
    expect(p2.cachingActive, isTrue);
  });

  test('malformed text comes back with json == null; stop reasons pass through', () async {
    http.queue.add(FakeResponse(200, jsonEncode({'content': [{'type': 'text', 'text': 'I refuse'}], 'stop_reason': 'refusal', 'usage': {'input_tokens': 5, 'output_tokens': 2}})));
    final r = await make().completeJson(req);
    expect(r.json, isNull);
    expect(r.rawText, 'I refuse');
    expect(r.finishReason, 'refusal');
    http.queue.add(FakeResponse(200, jsonEncode({'content': [{'type': 'text', 'text': '{"results": ['}], 'stop_reason': 'max_tokens', 'usage': <String, dynamic>{}})));
    expect((await make().completeJson(req)).finishReason, 'max_tokens');
  });

  test('listModels and testConnection', () async {
    http.queue.add(FakeResponse.json(200, {'data': [{'id': 'claude-sonnet-5', 'display_name': 'Claude Sonnet 5', 'max_input_tokens': 1000000, 'max_tokens': 128000}, {'id': 'claude-haiku-4-5', 'display_name': 'Haiku'}]}));
    final models = await make().listModels();
    expect(http.requests.single.uri.path, '/v1/models');
    expect(http.requests.single.method, 'GET');
    expect(models.first.id, 'claude-sonnet-5');
    expect(models.first.contextTokens, 1000000);
    expect(models.first.maxOutputTokens, 128000);

    http.queue.add(FakeResponse.json(200, {'data': [{'id': 'claude-sonnet-5'}]}));
    http.queue.add(FakeResponse.json(200, anthropicMessage({'category': 'invoice'})));
    final ok = await make().testConnection();
    expect(ok.ok, isTrue);
    expect(ok.schemaEnforced, isTrue);
    expect(ok.estUsdPer1000, closeTo(1.6, 1e-9));
    expect(http.requests.last.headers['x-api-key'], 'sk-ant-test');

    http.queue.add(FakeResponse.json(401, {'error': {'type': 'authentication_error', 'message': 'invalid x-api-key'}}));
    final bad = await make().testConnection();
    expect(bad.reachable, isTrue);
    expect(bad.authOk, isFalse);
    expect(bad.error, contains('API key rejected'));

    http.queue.add(FakeResponse.json(200, {'data': [{'id': 'claude-haiku-4-5'}]}));
    final missing = await make().testConnection();
    expect(missing.modelFound, isFalse);
    expect(missing.error, contains('not found'));
  });

  test('estimateInputTokens is chars/4', () async {
    final n = await make().estimateInputTokens(ChatJsonRequest(system: [PromptBlock('a' * 400)], user: 'b' * 200, jsonSchema: const {}));
    expect(n, ((600 + 2) / 4).ceil());
  });

  group('batches', () {
    test('submit sends custom_id + params, status and results parse', () async {
      final p = make();
      http.queue.add(FakeResponse.json(200, {'id': 'msgbatch_1', 'processing_status': 'in_progress'}));
      final id = await p.batch!.submit([(customId: 'b1', req: req), (customId: 'b2', req: req)]);
      expect(id, 'msgbatch_1');
      expect(http.requests.single.uri.path, '/v1/messages/batches');
      final reqs = http.lastBody['requests'] as List;
      expect(reqs.length, 2);
      expect(reqs[0]['custom_id'], 'b1');
      expect(reqs[0]['params']['model'], 'claude-sonnet-5');
      expect(reqs[0]['params']['output_config']['format']['type'], 'json_schema');

      http.queue.add(FakeResponse.json(200, {'id': 'msgbatch_1', 'processing_status': 'ended', 'request_counts': {'processing': 0, 'succeeded': 1, 'errored': 1, 'canceled': 0, 'expired': 0}, 'results_url': 'https://api.anthropic.com/v1/messages/batches/msgbatch_1/results'}));
      final st = await p.batch!.status('msgbatch_1');
      expect(st.ended, isTrue);
      expect(st.succeeded, 1);
      expect(st.errored, 1);

      http.queue.add(FakeResponse.json(200, {'id': 'msgbatch_1', 'processing_status': 'ended', 'results_url': 'https://api.anthropic.com/v1/messages/batches/msgbatch_1/results'}));
      http.queue.add(FakeResponse(200, [
        jsonEncode({'custom_id': 'b2', 'result': {'type': 'errored', 'error': {'type': 'invalid_request'}}}),
        jsonEncode({'custom_id': 'b1', 'result': {'type': 'succeeded', 'message': anthropicMessage(answer)}}),
      ].join('\n')));
      final items = await p.batch!.results('msgbatch_1').toList();
      expect(http.requests.last.uri.path, '/v1/messages/batches/msgbatch_1/results');
      expect(items.map((i) => i.customId), ['b2', 'b1']);
      expect(items[0].resultType, 'errored');
      expect(items[0].result, isNull);
      expect(items[1].result!.json, answer);

      http.queue.add(FakeResponse.json(200, {'id': 'msgbatch_1', 'processing_status': 'canceling'}));
      await p.batch!.cancel('msgbatch_1');
      expect(http.requests.last.uri.path, '/v1/messages/batches/msgbatch_1/cancel');
      expect(http.requests.last.method, 'POST');
    });
  });
}
