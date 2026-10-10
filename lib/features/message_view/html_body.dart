import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/entities.dart';
import '../../services/sorter/text_cleaner.dart';
import 'html/sanitizer.dart';
import 'plain_text_view.dart';

/// How the body is shown. [html] applies the contrast guard; [original]
/// renders the author's colours untouched (still on the white canvas);
/// [plainText] shows the text alternative.
enum BodyViewMode { html, original, plainText }

/// The text alternative of [body]: its `text/plain` part, or text derived
/// from the HTML when the mail has none.
String plainTextOf(MessageBody body) {
  if (body.text.trim().isNotEmpty) return body.text;
  final html = body.html;
  return html == null ? '' : TextCleaner.htmlToText(html);
}

/// Renders a [MessageBody]: sanitized HTML on a mail canvas, or plain text.
class MessageBodyView extends StatefulWidget {
  const MessageBodyView({
    super.key,
    required this.body,
    required this.allowRemoteImages,
    required this.onRemoteImagesBlocked,
    this.mode = BodyViewMode.html,
  });
  final MessageBody body;
  final bool allowRemoteImages;
  final BodyViewMode mode;

  /// Called (post-frame) with the number of blocked remote images.
  final ValueChanged<int> onRemoteImagesBlocked;

  @override
  State<MessageBodyView> createState() => _MessageBodyViewState();
}

class _MessageBodyViewState extends State<MessageBodyView> {
  /// Sanitising is not free; cache per (html, options, viewport bucket).
  String? _cacheKey;
  SanitizedHtml? _cached;

  SanitizedHtml _sanitize(String html, int viewport) {
    final key = '${widget.mode.name}|${widget.allowRemoteImages}|$viewport|${html.hashCode}|${html.length}';
    if (_cacheKey != key || _cached == null) {
      _cacheKey = key;
      _cached = HtmlSanitizer(viewportWidth: viewport, contrastGuard: widget.mode != BodyViewMode.original)
          .sanitize(html, inlineParts: widget.body.inlineParts, allowRemoteImages: widget.allowRemoteImages);
    }
    return _cached!;
  }

  @override
  Widget build(BuildContext context) {
    final body = widget.body;
    final html = body.html;
    if (widget.mode == BodyViewMode.plainText || html == null || html.trim().isEmpty) {
      return PlainTextBodyView(text: plainTextOf(body), onOpenUrl: (u) => openMailUrl(context, u));
    }
    return LayoutBuilder(builder: (context, constraints) {
      final viewport = constraints.maxWidth.isFinite ? constraints.maxWidth : 600.0;
      // Bucket the viewport so resizing by a few pixels does not re-sanitise.
      final result = _sanitize(html, (viewport / 50).ceil() * 50);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onRemoteImagesBlocked(result.blockedRemoteImages ? result.remoteImageCount : 0);
      });
      if (result.html.trim().isEmpty) {
        return PlainTextBodyView(text: plainTextOf(body), onOpenUrl: (u) => openMailUrl(context, u));
      }
      final wanted = result.contentWidth + 2 * MailCanvas.padding;
      final renderWidth = math.max(viewport, math.min(wanted.toDouble(), 1400.0));
      final canvas = MailCanvas(
        width: renderWidth,
        child: SelectionArea(
          child: HtmlWidget(
            result.html,
            renderMode: RenderMode.column,
            textStyle: MailCanvas.textStyle,
            onTapUrl: (url) => openMailUrl(context, url),
            onErrorBuilder: (_, _, _) => PlainTextBodyView(text: plainTextOf(body), onOpenUrl: (u) => openMailUrl(context, u)),
          ),
        ),
      );
      if (renderWidth <= viewport) return canvas;
      return SingleChildScrollView(scrollDirection: Axis.horizontal, child: canvas);
    });
  }
}

/// The white page every HTML mail is drawn on, regardless of app theme: the
/// defaults real mail clients use (white, near-black text, blue links, 15px
/// at 1.4 line height) so author colours mean what the author saw.
class MailCanvas extends StatelessWidget {
  const MailCanvas({super.key, required this.child, this.width});
  final Widget child;
  final double? width;

  static const canvasKey = ValueKey('mail-canvas');
  static const canvasColor = Color(0xFFFFFFFF);
  static const textColor = Color(0xFF1F1F1F);
  static const linkColor = Color(0xFF1A56C4);
  static const padding = 16;
  static const textStyle = TextStyle(color: textColor, fontSize: 15, height: 1.4);

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context);
    final light = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: linkColor, brightness: Brightness.light, primary: linkColor),
      textTheme: app.textTheme.apply(bodyColor: textColor, displayColor: textColor),
    );
    return Theme(
      data: light,
      child: DefaultTextStyle(
        style: textStyle,
        child: Material(
          key: canvasKey,
          color: canvasColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: app.colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: width,
            child: Padding(padding: const EdgeInsets.all(padding + 0.0), child: child),
          ),
        ),
      ),
    );
  }
}

/// Confirms, then opens an http(s)/mailto link from a mail body.
Future<bool> openMailUrl(BuildContext context, String url) async {
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
