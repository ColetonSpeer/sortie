import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/data/ai/ai_provider.dart';
import 'package:sortie/data/ai/ai_provider_factory.dart';
import 'package:sortie/data/ai/anthropic_provider.dart';
import 'package:sortie/data/ai/fake_ai_provider.dart';
import 'package:sortie/data/ai/json_extract.dart';
import 'package:sortie/data/ai/openai_compat_provider.dart';
import 'package:sortie/data/ai/price_table.dart';
import 'package:sortie/domain/entities/entities.dart';

void main() {
  group('price table', () {
    final t = PriceTable.bundled;
    test('bundled prices and multipliers', () {
      expect(t.verifiedOn, DateTime.utc(2026, 9, 16));
      expect(t.cost(const TokenUsage(input: 1000000), 'claude-haiku-4-5'), 1.0);
      expect(t.cost(const TokenUsage(output: 1000000), 'claude-haiku-4-5'), 5.0);
      expect(t.cost(const TokenUsage(input: 1000000), 'claude-sonnet-5'), 2.0);
      expect(t.cost(const TokenUsage(output: 1000000), 'claude-sonnet-5'), 10.0);
      expect(t.cost(const TokenUsage(input: 1000000), 'claude-opus-5'), 5.0);
      expect(t.cost(const TokenUsage(output: 1000000), 'claude-opus-5'), 25.0);
      expect(t.cost(const TokenUsage(cacheRead: 1000000), 'claude-sonnet-5'), closeTo(0.2, 1e-9));
      expect(t.cost(const TokenUsage(cacheWrite: 1000000), 'claude-sonnet-5'), closeTo(2.5, 1e-9));
      expect(t.cost(const TokenUsage(input: 1000000), 'claude-sonnet-5', batch: true), 1.0);
      expect(t.cost(const TokenUsage(input: 1000000), 'claude-sonnet-5', local: true), 0);
    });
    test('prefix match and unknown fallback', () {
      expect(t.cost(const TokenUsage(input: 1000000), 'claude-opus-5-20261201'), 5.0);
      expect(t.isKnown('claude-mystery-9'), isFalse);
      expect(t.cost(const TokenUsage(input: 1000000), 'claude-mystery-9'), 2.0, reason: 'falls back to sonnet pricing');
    });
    test('user edits via copyWith', () {
      final edited = t.copyWith(prices: {...t.prices, 'claude-sonnet-5': const ModelPrice(inputPerMTok: 3, outputPerMTok: 15)});
      expect(edited.cost(const TokenUsage(input: 1000000), 'claude-sonnet-5'), 3.0);
    });
  });

  group('factory', () {
    test('returns null when nothing usable is configured', () {
      expect(buildProvider(const AiSettings(), 'key'), isNull);
      expect(buildProvider(const AiSettings(kind: AiProviderKind.anthropic), null), isNull);
      expect(buildProvider(const AiSettings(kind: AiProviderKind.anthropic), '  '), isNull);
      expect(buildProvider(const AiSettings(kind: AiProviderKind.openAiCompat, baseUrl: ''), null), isNull);
    });
    test('builds the right provider', () {
      final a = buildProvider(const AiSettings(kind: AiProviderKind.anthropic, model: 'claude-haiku-4-5'), 'sk');
      expect(a, isA<AnthropicProvider>());
      expect(a!.modelId, 'claude-haiku-4-5');
      expect(a.isLocal, isFalse);
      expect(a.contextWindowTokens, 200000);
      final o = buildProvider(const AiSettings(kind: AiProviderKind.openAiCompat, baseUrl: 'http://10.0.0.1:11434/v1', model: 'llama3', contextWindowTokens: 32768), null);
      expect(o, isA<OpenAiCompatProvider>());
      expect(o!.isLocal, isTrue);
      expect(o.contextWindowTokens, 32768);
    });
  });

  group('json extraction', () {
    test('strict, fenced, embedded, escaped', () {
      expect(extractJsonObject('{"a":1}'), {'a': 1});
      expect(extractJsonObject(' ```json\n{"a":1}\n``` '), {'a': 1});
      expect(extractJsonObject('text {"a":"}"} more'), {'a': '}'});
      expect(extractJsonObject(r'x {"a":"\"{"} y'), {'a': '"{'});
      expect(extractJsonObject('[1,2]'), isNull);
      expect(extractJsonObject('{"a":'), isNull);
      expect(extractJsonObject(''), isNull);
      expect(extractJsonObject('{bad} {"ok":true}'), {'ok': true});
    });
  });

  group('fake provider', () {
    test('records requests and answers from queue, script or default', () async {
      final f = FakeAiProvider();
      final req = ChatJsonRequest(system: const [], user: '<message id="m1"></message><message id="m2"></message>', jsonSchema: const {});
      var r = await f.completeJson(req);
      expect((r.json!['results'] as List).length, 2);
      f.queue.add('junk');
      r = await f.completeJson(req);
      expect(r.json, isNull);
      f.script = (r) => FakeAiProvider.table(r, {'m2': ('X', 0.7)});
      r = await f.completeJson(req);
      expect((r.json!['results'] as List)[1], {'id': 'm2', 'folder': 'X', 'confidence': 0.7, 'reason': 'scripted'});
      expect(f.callCount, 3);
    });
  });
}
