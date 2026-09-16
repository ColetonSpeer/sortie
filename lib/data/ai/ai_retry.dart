import 'dart:math';

import 'package:dio/dio.dart';

import 'ai_provider.dart';

/// Sleep hook so tests can run the retry loop without waiting.
typedef Sleeper = Future<void> Function(Duration d);

Future<void> realSleep(Duration d) => Future<void>.delayed(d);

/// Retry policy shared by the HTTP providers: 408/409/429/529/5xx and
/// transport errors retry with exponential backoff 2 s -> 5 min (6 attempts),
/// honouring `retry-after`. 400/401/403/404 never retry.
class RetryPolicy {
  const RetryPolicy({
    this.maxAttempts = 6,
    this.baseDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(minutes: 5),
  });
  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;

  static bool isRetryableStatus(int? code) =>
      code == 408 || code == 409 || code == 429 || code == 529 || (code != null && code >= 500 && code < 600);

  Duration delayFor(int attempt, Duration? retryAfter) {
    if (retryAfter != null) return retryAfter > maxDelay ? maxDelay : retryAfter;
    final ms = baseDelay.inMilliseconds * pow(2, attempt).toInt();
    return Duration(milliseconds: min(ms, maxDelay.inMilliseconds));
  }

  Future<T> run<T>(Future<T> Function() op, {Sleeper sleep = realSleep}) async {
    for (var attempt = 0;; attempt++) {
      try {
        return await op();
      } on AiProviderException catch (e) {
        if (!e.retryable || attempt + 1 >= maxAttempts) rethrow;
        await sleep(delayFor(attempt, e.retryAfter));
      }
    }
  }
}

/// Parses `Retry-After` (seconds or HTTP-date).
Duration? parseRetryAfter(String? v) {
  if (v == null || v.isEmpty) return null;
  final secs = int.tryParse(v.trim());
  if (secs != null) return Duration(seconds: max(0, secs));
  try {
    final when = HttpDate.parse(v);
    final d = when.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  } on Object {
    return null;
  }
}

/// Wraps a Dio transport failure (no HTTP status) into a retryable exception.
AiProviderException transportException(DioException e) {
  final t = e.type;
  final msg = switch (t) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout =>
      'Timed out talking to ${e.requestOptions.uri.host}',
    DioExceptionType.connectionError => 'Connection refused by ${e.requestOptions.uri.host}',
    _ => e.message ?? 'Network error',
  };
  return AiProviderException(msg, retryable: true);
}

/// Minimal HTTP-date parser (RFC 7231 IMF-fixdate) without dart:io.
abstract final class HttpDate {
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static DateTime parse(String s) {
    final m = RegExp(r'^\w{3}, (\d{2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$').firstMatch(s.trim());
    if (m == null) throw FormatException('Not an HTTP date', s);
    final month = _months.indexOf(m.group(2)!) + 1;
    if (month == 0) throw FormatException('Bad month', s);
    return DateTime.utc(int.parse(m.group(3)!), month, int.parse(m.group(1)!), int.parse(m.group(4)!),
        int.parse(m.group(5)!), int.parse(m.group(6)!));
  }
}
