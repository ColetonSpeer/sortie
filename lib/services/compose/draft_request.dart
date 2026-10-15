import '../../app/compose_models.dart';
import 'message_composer.dart' as mc;

/// Turns the UI's [ComposeDraft] into a composer request. The signature is
/// already in the body text, so the composer must not add it again.
mc.ComposeRequest requestForDraft(ComposeDraft d) => mc.ComposeRequest(
      identity: d.identity,
      mode: d.inReplyTo != null ? mc.ComposeMode.reply : mc.ComposeMode.newMessage,
      to: d.to.map((a) => a.toString()).toList(),
      cc: d.cc.map((a) => a.toString()).toList(),
      bcc: d.bcc.map((a) => a.toString()).toList(),
      subject: d.subject,
      text: d.bodyText,
      attachments: [for (final a in d.attachments) mc.ComposeAttachment(name: a.fileName, mimeType: a.mimeType, bytes: a.bytes)],
      inReplyTo: d.inReplyTo,
      references: d.references,
      includeSignature: false,
    );
