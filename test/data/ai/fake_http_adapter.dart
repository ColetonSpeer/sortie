import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class FakeResponse {
  const FakeResponse(this.status, this.body, {this.headers = const {}});
  FakeResponse.json(this.status, Map<String, dynamic> json, {this.headers = const {}}) : body = jsonEncode(json);
  final int status;
  final String body;
  final Map<String, String> headers;
}

/// Dio adapter that replays scripted responses and records requests.
class FakeHttpAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final List<FakeResponse> queue = [];
  FakeResponse Function(RequestOptions o)? handler;

  /// Throw a connection error on the next request instead of answering.
  bool refuseNext = false;

  Map<String, dynamic> bodyOf(int i) => jsonDecode(requests[i].data as String) as Map<String, dynamic>;
  Map<String, dynamic> get lastBody => bodyOf(requests.length - 1);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    if (refuseNext) {
      refuseNext = false;
      throw DioException.connectionError(requestOptions: options, reason: 'Connection refused');
    }
    final r = queue.isNotEmpty ? queue.removeAt(0) : handler!(options);
    return ResponseBody.fromString(
      r.body,
      r.status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        for (final e in r.headers.entries) e.key: [e.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio fakeDio(FakeHttpAdapter adapter) => Dio()..httpClientAdapter = adapter;

Map<String, dynamic> anthropicMessage(Map<String, dynamic> json, {String stop = 'end_turn', int cacheRead = 0, int input = 500, int output = 40}) => {
      'id': 'msg_1',
      'type': 'message',
      'role': 'assistant',
      'model': 'claude-sonnet-5',
      'content': [
        {'type': 'text', 'text': jsonEncode(json)}
      ],
      'stop_reason': stop,
      'usage': {'input_tokens': input, 'output_tokens': output, 'cache_read_input_tokens': cacheRead, 'cache_creation_input_tokens': 0},
    };

Map<String, dynamic> openAiCompletion(String content, {String finish = 'stop'}) => {
      'id': 'chatcmpl-1',
      'choices': [
        {'index': 0, 'finish_reason': finish, 'message': {'role': 'assistant', 'content': content}}
      ],
      'usage': {'prompt_tokens': 300, 'completion_tokens': 20},
    };
