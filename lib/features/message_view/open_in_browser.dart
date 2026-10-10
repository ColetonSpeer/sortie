import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/entities.dart';
import 'html/sanitizer.dart';

/// The mail canvas styles shared by the in-app view and the browser export.
const kMailCanvasCss =
    'body{margin:0;padding:16px;background:#ffffff;color:#1f1f1f;font:15px/1.4 -apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif}'
    'a{color:#1a56c4}img{max-width:100%;height:auto}';

/// Builds a self-contained HTML document from [body]: sanitised markup with
/// inline (`cid:`) images embedded as `data:` URIs.
String buildStandaloneHtml(MessageBody body, {required bool allowRemoteImages, String title = ''}) {
  final html = body.html;
  final content = html == null || html.trim().isEmpty
      ? '<pre style="white-space:pre-wrap;font:inherit">${_escape(body.text)}</pre>'
      : const HtmlSanitizer(contrastGuard: false).sanitize(html, inlineParts: body.inlineParts, allowRemoteImages: allowRemoteImages).html;
  return '<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width">'
      '<title>${_escape(title)}</title><style>$kMailCanvasCss</style></head><body>$content</body></html>';
}

/// Writes [body] to a temp file and opens it with the system browser.
/// Returns null on success, otherwise a short error message.
Future<String?> openMessageInBrowser(MessageBody body, {required bool allowRemoteImages, String title = ''}) async {
  try {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}sortie-mail-${DateTime.now().millisecondsSinceEpoch}.html');
    await file.writeAsString(buildStandaloneHtml(body, allowRemoteImages: allowRemoteImages, title: title));
    final ok = await launchUrl(Uri.file(file.path), mode: LaunchMode.externalApplication);
    return ok ? null : 'No browser could open the file.';
  } catch (e) {
    return 'Could not open in browser: $e';
  }
}

String _escape(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
