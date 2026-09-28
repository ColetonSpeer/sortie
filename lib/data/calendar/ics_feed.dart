import 'package:dio/dio.dart';

class IcsFeedResult {
  const IcsFeedResult({required this.notModified, this.body, this.etag});
  final bool notModified;
  final String? body;
  final String? etag;
}

/// Read-only ICS subscription fetch with `If-None-Match`.
class IcsFeedClient {
  IcsFeedClient(this._dio);
  final Dio _dio;

  static Uri normalize(String url) {
    var u = url.trim();
    if (u.startsWith('webcal://')) u = 'https://${u.substring(9)}';
    if (u.startsWith('webcals://')) u = 'https://${u.substring(10)}';
    return Uri.parse(u);
  }

  Future<IcsFeedResult> fetch(String url, {String? etag}) async {
    final r = await _dio.getUri<String>(
      normalize(url),
      options: Options(
        headers: {'If-None-Match': ?etag},
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      ),
    );
    if (r.statusCode == 304) return const IcsFeedResult(notModified: true);
    if (r.statusCode != 200) throw DioException(requestOptions: r.requestOptions, response: r, message: 'HTTP ${r.statusCode}');
    return IcsFeedResult(notModified: false, body: r.data ?? '', etag: r.headers.value('etag'));
  }
}
