import '../../domain/entities/entities.dart';
import 'ai_provider.dart';
import 'anthropic_provider.dart';
import 'openai_compat_provider.dart';
import 'price_table.dart';

/// Builds the configured provider, or null when nothing usable is
/// configured (kind none, missing key, missing base URL). The sorter then
/// runs its deterministic layers only.
AiProvider? buildProvider(AiSettings s, String? apiKey, {PriceTable? prices}) {
  switch (s.kind) {
    case AiProviderKind.none:
      return null;
    case AiProviderKind.anthropic:
      if (apiKey == null || apiKey.trim().isEmpty || s.model.trim().isEmpty) return null;
      return AnthropicProvider(apiKey: apiKey.trim(), model: s.model.trim(), prices: prices);
    case AiProviderKind.openAiCompat:
      if (s.baseUrl.trim().isEmpty || s.model.trim().isEmpty) return null;
      return OpenAiCompatProvider(
        baseUrl: s.baseUrl,
        apiKey: apiKey,
        model: s.model.trim(),
        contextWindowTokens: s.contextWindowTokens,
      );
  }
}
