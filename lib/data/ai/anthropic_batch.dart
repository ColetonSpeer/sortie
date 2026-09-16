import 'dart:convert';

import 'ai_provider.dart';
import 'anthropic_provider.dart';

/// Message Batches (`/v1/messages/batches`): 50% off, results as JSONL keyed
/// by `custom_id`, in any order.
class AnthropicBatchApi implements BatchApi {
  AnthropicBatchApi(this._p);
  final AnthropicProvider _p;

  @override
  Future<String> submit(List<({String customId, ChatJsonRequest req})> requests) async {
    final body = {
      'requests': [
        for (final r in requests) {'custom_id': r.customId, 'params': _p.buildBody(r.req)},
      ],
    };
    final json = await _p.request('POST', '/v1/messages/batches', body: body);
    return json['id'] as String;
  }

  Future<Map<String, dynamic>> _fetch(String batchId) => _p.request('GET', '/v1/messages/batches/$batchId');

  @override
  Future<BatchStatus> status(String batchId) async {
    final j = await _fetch(batchId);
    final counts = (j['request_counts'] as Map?) ?? const {};
    int n(String k) => (counts[k] as num?)?.toInt() ?? 0;
    return BatchStatus(
      id: j['id'] as String,
      ended: j['processing_status'] == 'ended',
      succeeded: n('succeeded'),
      errored: n('errored') + n('canceled') + n('expired'),
      processing: n('processing'),
    );
  }

  @override
  Stream<BatchResultItem> results(String batchId) async* {
    final j = await _fetch(batchId);
    final url = j['results_url'] as String?;
    if (url == null) throw const AiProviderException('Batch has no results yet');
    final text = await _p.getText(url);
    for (final line in const LineSplitter().convert(text)) {
      if (line.trim().isEmpty) continue;
      final item = jsonDecode(line);
      if (item is! Map<String, dynamic>) continue;
      final result = (item['result'] as Map?)?.cast<String, dynamic>() ?? const {};
      final type = (result['type'] as String?) ?? 'errored';
      yield BatchResultItem(
        customId: (item['custom_id'] as String?) ?? '',
        resultType: type,
        result: type == 'succeeded' && result['message'] is Map
            ? AnthropicProvider.parseMessage((result['message'] as Map).cast<String, dynamic>(), Duration.zero)
            : null,
      );
    }
  }

  @override
  Future<void> cancel(String batchId) async {
    await _p.request('POST', '/v1/messages/batches/$batchId/cancel');
  }
}
