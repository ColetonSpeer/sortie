import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../shell/format.dart';

/// From / To / Cc / date block plus the attachment chips.
class MessageHeaderView extends ConsumerWidget {
  const MessageHeaderView({super.key, required this.header});
  final MessageHeader header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    String people(List<MailAddress> l) => l.map((a) => a.toString()).join(', ');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(header.subject.isEmpty ? '(no subject)' : header.subject, style: theme.textTheme.headlineSmall),
      const SizedBox(height: 12),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 20, child: Text(Fmt.initials(Fmt.sender(header)))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SelectableText(header.from?.toString() ?? '(unknown sender)', style: theme.textTheme.titleSmall),
            if (header.to.isNotEmpty) _line(context, 'To', people(header.to)),
            if (header.cc.isNotEmpty) _line(context, 'Cc', people(header.cc)),
            if (header.replyTo != null && header.replyTo!.email != header.from?.email)
              _line(context, 'Reply-To', header.replyTo.toString()),
            Text(Fmt.fullDate(header.date), style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ]),
        ),
      ]),
      if (header.attachments.isNotEmpty) ...[
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final a in header.attachments)
            ActionChip(
              avatar: Icon(_iconFor(a.mimeType), size: 18),
              label: Text('${a.fileName} · ${Fmt.bytes(a.size)}'),
              tooltip: 'Save ${a.fileName}',
              onPressed: () => _save(context, ref, a),
            ),
        ]),
      ],
    ]);
  }

  Widget _line(BuildContext context, String label, String value) => Text.rich(
        TextSpan(children: [
          TextSpan(text: '$label: ', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          TextSpan(text: value),
        ]),
        style: Theme.of(context).textTheme.bodySmall,
      );

  static IconData _iconFor(String mime) {
    if (mime.startsWith('image/')) return Icons.image_outlined;
    if (mime == 'application/pdf') return Icons.picture_as_pdf_outlined;
    if (mime.startsWith('audio/')) return Icons.audiotrack_outlined;
    if (mime.startsWith('video/')) return Icons.videocam_outlined;
    if (mime.contains('zip') || mime.contains('compressed')) return Icons.folder_zip_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Future<void> _save(BuildContext context, WidgetRef ref, AttachmentInfo a) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final bytes = await ref.read(mailSyncServiceProvider).attachment(header.accountId, header.folderPath, header.uid, a.partId);
      final path = await FilePicker.saveFile(dialogTitle: 'Save attachment', fileName: a.fileName, bytes: Uint8List.fromList(bytes));
      if (path != null) messenger?.showSnackBar(SnackBar(content: Text('Saved ${a.fileName}')));
    } catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text('Could not save attachment: $e')));
    }
  }
}
