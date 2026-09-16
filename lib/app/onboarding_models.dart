import '../domain/entities/entities.dart';

/// One discovered IMAP/SMTP pairing for an email address.
class ServerCandidate {
  const ServerCandidate({required this.imap, required this.smtp, required this.username, this.source = ''});
  final ImapEndpoint imap;
  final SmtpEndpoint smtp;
  final String username;

  /// Human label for where this came from (autoconfig, SRV, guess, manual).
  final String source;

  String get imapLabel => '${imap.host}:${imap.port} (${imap.security.name})';
  String get smtpLabel => '${smtp.host}:${smtp.port} (${smtp.security.name})';
}
