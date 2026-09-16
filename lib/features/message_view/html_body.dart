import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/entities.dart';
import 'html/sanitizer.dart';

/// Renders a [MessageBody]: sanitized HTML when present, plain text otherwise.
class MessageBodyView extends StatelessWidget {
  const MessageBodyView({super.key, required this.body, required this.allowRemoteImages, required this.onRemoteImagesBlocked});
  final MessageBody body;
  final bool allowRemoteImages;

  /// Called (post-frame) with the number of blocked remote images.
  final ValueChanged<int> onRemoteImagesBlocked;

  @override
  Widget build(BuildContext context) {
    final html = body.html;
    if (html == null || html.trim().isEmpty) return _PlainText(body.text);

    final result = const HtmlSanitizer().sanitize(html, inlineParts: body.inlineParts, allowRemoteImages: allowRemoteImages);
    WidgetsBinding.instance.addPostFrameCallback((_) => onRemoteImagesBlocked(result.blockedRemoteImages ? result.remoteImageCount : 0));
    if (result.html.trim().isEmpty) return _PlainText(body.text);

    return SelectionArea(
      child: HtmlWidget(
        result.html,
        renderMode: RenderMode.column,
        textStyle: Theme.of(context).textTheme.bodyMedium,
        onTapUrl: (url) => _openUrl(context, url),
        onErrorBuilder: (_, _, _) => _PlainText(body.text),
      ),
    );
  }

  static Future<bool> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'mailto')) return false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Open link?'),
        content: Text(url, maxLines: 6, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Open')),
        ],
      ),
    );
    if (ok != true) return true;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _PlainText extends StatelessWidget {
  const _PlainText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => SelectionArea(
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4)),
      );
}
