import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// Result of sanitizing an HTML mail body.
class SanitizedHtml {
  const SanitizedHtml({required this.html, required this.blockedRemoteImages, required this.remoteImageCount});
  final String html;

  /// True when remote images were present and replaced by placeholders.
  final bool blockedRemoteImages;
  final int remoteImageCount;
}

/// Defensive HTML sanitizer for mail bodies. Pure Dart so it runs everywhere.
///
/// - removes script / iframe / object / embed / form / applet / link / base /
///   meta refresh / style-with-remote-urls
/// - drops every `on*` attribute and any `javascript:`/`vbscript:`/`data:`
///   (non-image) URL
/// - inlines `cid:` images from [inlineParts] as data URIs
/// - replaces remote images with a placeholder unless [allowRemoteImages]
class HtmlSanitizer {
  const HtmlSanitizer();

  static const _dropElements = {
    'script', 'iframe', 'frame', 'frameset', 'object', 'embed', 'applet', 'form', 'input', 'button',
    'select', 'textarea', 'link', 'base', 'noscript', 'template', 'audio', 'video', 'source', 'track',
  };
  static const _urlAttrs = {'href', 'src', 'background', 'action', 'poster', 'formaction', 'xlink:href', 'srcset'};

  SanitizedHtml sanitize(
    String input, {
    Map<String, List<int>> inlineParts = const {},
    bool allowRemoteImages = false,
    Map<String, String> inlineMimeTypes = const {},
  }) {
    final doc = html_parser.parse(input);
    var remote = 0;

    void walk(dom.Element el) {
      final name = el.localName?.toLowerCase() ?? '';
      if (_dropElements.contains(name)) {
        el.remove();
        return;
      }
      if (name == 'meta') {
        final eq = (el.attributes['http-equiv'] ?? '').toLowerCase();
        if (eq == 'refresh' || eq == 'set-cookie') el.remove();
        return;
      }
      if (name == 'style') {
        el.text = _scrubCss(el.text, allowRemoteImages);
      }

      // Attributes: copy keys first because we mutate the map.
      for (final key in el.attributes.keys.toList()) {
        final k = key.toString().toLowerCase();
        final v = el.attributes[key] ?? '';
        if (k.startsWith('on') || k == 'ping' || k == 'srcdoc') {
          el.attributes.remove(key);
          continue;
        }
        if (k == 'style') {
          el.attributes[key] = _scrubCss(v, allowRemoteImages);
          continue;
        }
        if (_urlAttrs.contains(k)) {
          final scheme = _scheme(v);
          if (scheme == 'javascript' || scheme == 'vbscript' || scheme == 'file' || k == 'srcset' || k == 'action' || k == 'formaction') {
            el.attributes.remove(key);
          } else if (scheme == 'data' && !(name == 'img' && v.toLowerCase().startsWith('data:image/'))) {
            el.attributes.remove(key);
          }
        }
      }

      if (name == 'img') {
        final src = el.attributes['src'] ?? '';
        final scheme = _scheme(src);
        if (scheme == 'cid') {
          final cid = src.substring(4).replaceAll(RegExp(r'^<|>$'), '');
          final bytes = inlineParts[cid] ?? inlineParts['<$cid>'];
          if (bytes != null) {
            final mime = inlineMimeTypes[cid] ?? _guessMime(bytes);
            el.attributes['src'] = 'data:$mime;base64,${base64Encode(bytes)}';
          } else {
            el.replaceWith(_placeholder(doc, 'missing image'));
            return;
          }
        } else if (scheme == 'http' || scheme == 'https' || (scheme.isEmpty && src.startsWith('//'))) {
          remote++;
          if (!allowRemoteImages) {
            el.replaceWith(_placeholder(doc, el.attributes['alt']?.isNotEmpty == true ? el.attributes['alt']! : 'remote image'));
            return;
          }
        } else if (scheme != 'data' && scheme.isNotEmpty) {
          el.remove();
          return;
        }
      }
      if (name == 'a') {
        el.attributes['target'] = '_blank';
        el.attributes['rel'] = 'noopener noreferrer';
      }

      for (final child in el.children.toList()) {
        walk(child);
      }
    }

    final root = doc.body ?? doc.documentElement;
    if (root != null) {
      for (final child in root.children.toList()) {
        walk(child);
      }
    }
    return SanitizedHtml(
      html: doc.body?.innerHtml ?? '',
      blockedRemoteImages: remote > 0 && !allowRemoteImages,
      remoteImageCount: remote,
    );
  }

  static dom.Element _placeholder(dom.Document doc, String label) {
    final span = doc.createElement('span');
    span.attributes['style'] = 'display:inline-block;padding:2px 6px;border:1px dashed #999;border-radius:4px;font-size:11px;color:#666;';
    span.text = '[$label]';
    return span;
  }

  static String _scheme(String url) {
    final m = RegExp(r'^\s*([a-zA-Z][a-zA-Z0-9+.-]*):').firstMatch(url.replaceAll(RegExp(r'[\x00-\x20]'), ''));
    return m == null ? '' : m.group(1)!.toLowerCase();
  }

  /// Removes `expression(`, `javascript:` and (unless allowed) remote `url(...)`.
  static String _scrubCss(String css, bool allowRemote) {
    var out = css.replaceAll(RegExp(r'expression\s*\(', caseSensitive: false), 'blocked(');
    out = out.replaceAll(RegExp(r'javascript\s*:', caseSensitive: false), 'blocked:');
    out = out.replaceAll(RegExp(r'@import[^;]*;?', caseSensitive: false), '');
    if (!allowRemote) {
      out = out.replaceAllMapped(RegExp(r'url\(\s*([^)]*)\)', caseSensitive: false), (m) {
        final target = m.group(1)!.replaceAll(RegExp('''["']'''), '').trim();
        return target.startsWith('data:image/') ? m.group(0)! : 'none';
      });
    }
    return out;
  }

  static String _guessMime(List<int> b) {
    if (b.length > 3 && b[0] == 0x89 && b[1] == 0x50) return 'image/png';
    if (b.length > 2 && b[0] == 0xFF && b[1] == 0xD8) return 'image/jpeg';
    if (b.length > 3 && b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46) return 'image/gif';
    if (b.length > 11 && b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) return 'image/webp';
    return 'image/png';
  }
}
