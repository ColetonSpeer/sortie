import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/ai_models.dart';
import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import 'settings_common.dart';

/// Provider kind, API key, base URL, model, caps, pause, privacy.
class AiSettingsPage extends ConsumerStatefulWidget {
  const AiSettingsPage({super.key});

  @override
  ConsumerState<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends ConsumerState<AiSettingsPage> {
  final _apiKey = TextEditingController();
  final _baseUrl = TextEditingController();
  final _model = TextEditingController();
  AiProviderKind? _loadedKeyFor;
  bool _keyVisible = false;
  List<String> _models = const [];
  bool _busy = false;
  ConnectionTestSummary? _test;

  @override
  void dispose() {
    _apiKey.dispose();
    _baseUrl.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadKey(AiProviderKind kind) async {
    if (_loadedKeyFor == kind || kind == AiProviderKind.none) return;
    _loadedKeyFor = kind;
    final v = await ref.read(credentialStoreProvider).read(CredentialStore.aiApiKey(kind));
    if (mounted) setState(() => _apiKey.text = v ?? '');
  }

  Future<void> _saveKey(AiProviderKind kind) async {
    final store = ref.read(credentialStoreProvider);
    final v = _apiKey.text.trim();
    v.isEmpty ? await store.delete(CredentialStore.aiApiKey(kind)) : await store.write(CredentialStore.aiApiKey(kind), v);
  }

  Future<void> _fetchModels(AiSettings s) async {
    setState(() => _busy = true);
    try {
      final key = _apiKey.text.trim();
      _models = await ref.read(listModelsProvider)(s, key.isEmpty ? null : key);
      if (_models.isEmpty) _snack('No models returned.');
    } catch (e) {
      _snack('Could not list models: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _testConnection(AiSettings s) async {
    setState(() {
      _busy = true;
      _test = null;
    });
    try {
      await _saveKey(s.kind);
      final key = _apiKey.text.trim();
      _test = await ref.read(testAiConnectionProvider)(s, key.isEmpty ? null : key);
    } catch (e) {
      _test = ConnectionTestSummary(ok: false, message: '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(aiSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('AI backend')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (s) {
          _loadKey(s.kind);
          if (_baseUrl.text != s.baseUrl && !_baseUrlFocus.hasFocus) _baseUrl.text = s.baseUrl;
          if (_model.text != s.model && !_modelFocus.hasFocus) _model.text = s.model;
          final theme = Theme.of(context);
          final cloud = s.kind == AiProviderKind.anthropic || (s.kind == AiProviderKind.openAiCompat && !s.isLocal);
          return ListView(padding: const EdgeInsets.only(bottom: 32), children: [
            RadioGroup<AiProviderKind>(
              groupValue: s.kind,
              onChanged: (v) {
                if (v == null) return;
                saveAiSettings(ref, (a) => a.copyWith(kind: v, model: v == AiProviderKind.anthropic && a.model.isEmpty ? 'claude-sonnet-5' : null));
                setState(() {
                  _models = const [];
                  _test = null;
                });
              },
              child: const Column(children: [
                RadioListTile(value: AiProviderKind.none, title: Text('None'), subtitle: Text('Rules and learned patterns only')),
                RadioListTile(value: AiProviderKind.anthropic, title: Text('Anthropic'), subtitle: Text('Claude via api.anthropic.com')),
                RadioListTile(value: AiProviderKind.openAiCompat, title: Text('OpenAI-compatible'), subtitle: Text('Ollama, LM Studio, vLLM, OpenAI…')),
              ]),
            ),
            if (s.kind != AiProviderKind.none) ...[
              const Divider(),
              if (s.kind == AiProviderKind.openAiCompat)
                _pad(TextField(
                  controller: _baseUrl,
                  focusNode: _baseUrlFocus,
                  decoration: const InputDecoration(labelText: 'Base URL', hintText: 'http://10.10.11.2:11434/v1', border: OutlineInputBorder()),
                  onSubmitted: (v) => saveAiSettings(ref, (a) => a.copyWith(baseUrl: v.trim())),
                  onTapOutside: (_) => saveAiSettings(ref, (a) => a.copyWith(baseUrl: _baseUrl.text.trim())),
                )),
              _pad(TextField(
                key: const Key('apiKey'),
                controller: _apiKey,
                obscureText: !_keyVisible,
                decoration: InputDecoration(
                  labelText: cloud ? 'API key' : 'API key (optional for local servers)',
                  border: const OutlineInputBorder(),
                  helperText: 'Stored in the system keychain, never in the database',
                  suffixIcon: IconButton(icon: Icon(_keyVisible ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _keyVisible = !_keyVisible)),
                ),
                onSubmitted: (_) => _saveKey(s.kind),
                onTapOutside: (_) => _saveKey(s.kind),
              )),
              _pad(Row(children: [
                Expanded(
                  child: _models.isEmpty
                      ? TextField(
                          controller: _model,
                          focusNode: _modelFocus,
                          decoration: const InputDecoration(labelText: 'Model', border: OutlineInputBorder()),
                          onSubmitted: (v) => saveAiSettings(ref, (a) => a.copyWith(model: v.trim())),
                          onTapOutside: (_) => saveAiSettings(ref, (a) => a.copyWith(model: _model.text.trim())),
                        )
                      : DropdownButtonFormField<String>(
                          initialValue: _models.contains(s.model) ? s.model : null,
                          decoration: const InputDecoration(labelText: 'Model', border: OutlineInputBorder()),
                          items: [for (final m in _models) DropdownMenuItem(value: m, child: Text(m))],
                          onChanged: (v) {
                            if (v != null) saveAiSettings(ref, (a) => a.copyWith(model: v));
                          },
                        ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _fetchModels(s),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Fetch models'),
                ),
              ])),
              _pad(Row(children: [
                FilledButton.tonalIcon(
                  key: const Key('testConnection'),
                  onPressed: _busy ? null : () => _testConnection(s),
                  icon: _busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.network_check),
                  label: const Text('Test connection'),
                ),
                const SizedBox(width: 12),
                if (_test != null)
                  Expanded(
                    child: Row(children: [
                      Icon(_test!.ok ? Icons.check_circle : Icons.error, color: _test!.ok ? theme.colorScheme.primary : theme.colorScheme.error, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _test!.estUsdPer1000 == null ? _test!.message : '${_test!.message} ≈ \$${_test!.estUsdPer1000!.toStringAsFixed(2)} per 1000 messages',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ]),
                  ),
              ])),
              const Divider(),
              ListTile(title: Text('How the AI is used', style: theme.textTheme.titleSmall)),
              AiUsageModeSelector(settings: s),
              const Divider(),
              ListTile(title: Text('Spending caps', style: theme.textTheme.titleSmall)),
              _capSlider('Daily cap', s.dailyCapUsd, 5, (v) => saveAiSettings(ref, (a) => a.copyWith(dailyCapUsd: v))),
              _capSlider('Monthly cap', s.monthlyCapUsd, 50, (v) => saveAiSettings(ref, (a) => a.copyWith(monthlyCapUsd: v))),
              SwitchListTile(
                title: const Text('Pause AI classification'),
                subtitle: const Text('Rules and learned patterns keep working'),
                value: s.paused,
                onChanged: (v) => saveAiSettings(ref, (a) => a.copyWith(paused: v)),
              ),
              const Divider(),
              ListTile(title: Text('Privacy', style: theme.textTheme.titleSmall)),
              PrivacySection(settings: s),
            ],
          ]);
        },
      ),
    );
  }

  final _baseUrlFocus = FocusNode();
  final _modelFocus = FocusNode();

  Widget _pad(Widget w) => Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: w);

  Widget _capSlider(String label, double value, double max, ValueChanged<double> onChanged) => ListTile(
        title: Text('$label: \$${value.toStringAsFixed(2)}'),
        subtitle: Slider(
          value: value.clamp(0, max),
          min: 0,
          max: max,
          divisions: (max * 4).round(),
          label: '\$${value.toStringAsFixed(2)}',
          onChanged: onChanged,
        ),
      );
}
