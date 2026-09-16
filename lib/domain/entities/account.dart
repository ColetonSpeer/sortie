enum AuthMethod { password, oauth2 }

enum ConnectionSecurity { tls, starttls, none }

class ImapEndpoint {
  const ImapEndpoint({required this.host, required this.port, required this.security});
  final String host;
  final int port;
  final ConnectionSecurity security;
}

class SmtpEndpoint {
  const SmtpEndpoint({required this.host, required this.port, required this.security});
  final String host;
  final int port;
  final ConnectionSecurity security;
}

class Account {
  const Account({
    required this.id,
    required this.displayName,
    required this.email,
    required this.username,
    required this.imap,
    required this.smtp,
    this.auth = AuthMethod.password,
    this.smtpUsername,
    this.enabled = true,
  });

  final String id;
  final String displayName;
  final String email;
  final String username;
  final ImapEndpoint imap;
  final SmtpEndpoint smtp;
  final AuthMethod auth;

  /// Defaults to [username] when null.
  final String? smtpUsername;
  final bool enabled;

  Account copyWith({String? displayName, bool? enabled}) => Account(
        id: id,
        displayName: displayName ?? this.displayName,
        email: email,
        username: username,
        imap: imap,
        smtp: smtp,
        auth: auth,
        smtpUsername: smtpUsername,
        enabled: enabled ?? this.enabled,
      );
}
