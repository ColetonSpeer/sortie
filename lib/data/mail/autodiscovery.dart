import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:enough_mail/enough_mail.dart' as em;
import 'package:logging/logging.dart';

import '../../domain/entities/entities.dart';
import 'imap_gateway.dart';
import 'smtp_gateway.dart';

/// One guess at how to reach an account.
class ServerCandidate {
  const ServerCandidate({required this.imap, required this.smtp, required this.username, required this.source});
  final ImapEndpoint imap;
  final SmtpEndpoint smtp;
  final String username;

  /// autoconfig | srv | pattern
  final String source;

  @override
  String toString() => '$source imap=${imap.host}:${imap.port}/${imap.security.name} smtp=${smtp.host}:${smtp.port}/${smtp.security.name} user=$username';
}

class ProbeResult {
  const ProbeResult({required this.candidate, required this.imapOk, required this.smtpOk, this.imapError, this.smtpError, this.capabilities});
  final ServerCandidate candidate;
  final bool imapOk;
  final bool smtpOk;
  final String? imapError;
  final String? smtpError;
  final ImapCapabilities? capabilities;
  bool get ok => imapOk && smtpOk;
}

/// Finds IMAP/SMTP endpoints for an address: enough_mail autoconfig, DNS SRV
/// (RFC 6186, via DNS-over-HTTPS since dart:io has no SRV lookup), then host
/// name patterns. Results are ordered most-likely first and de-duplicated.
class Autodiscovery {
  Autodiscovery({
    this.imapFactory,
    this.smtp,
    this.timeout = const Duration(seconds: 6),
    this.dohEndpoint = 'https://dns.google/resolve',
    HttpClient? httpClient,
  }) : _http = httpClient;

  /// Creates an unconnected gateway for [probe]; null disables IMAP probing.
  final ImapGateway Function()? imapFactory;

  /// Used by [probe] for the SMTP login test; null skips it.
  final SmtpGateway? smtp;
  final Duration timeout;
  final String dohEndpoint;
  final HttpClient? _http;
  final _log = Logger('sortie.autodiscovery');

  static String domainOf(String email) {
    final i = email.lastIndexOf('@');
    return i < 0 ? email.trim().toLowerCase() : email.substring(i + 1).trim().toLowerCase();
  }

  Future<List<ServerCandidate>> discover(String email, {bool includeInsecure = true}) async {
    final domain = domainOf(email);
    final out = <ServerCandidate>[];
    out.addAll(await _autoconfig(email));
    out.addAll(await _srv(domain, email));
    out.addAll(_patterns(domain, email, includeInsecure: includeInsecure));
    return _dedupe(out);
  }

  /// Tries a real IMAP login (and SMTP login when a gateway was given).
  Future<ProbeResult> probe(ServerCandidate c, String password, {String accountId = 'probe'}) async {
    final account = Account(id: accountId, displayName: c.username, email: c.username, username: c.username, imap: c.imap, smtp: c.smtp);
    var imapOk = false;
    String? imapErr;
    ImapCapabilities? caps;
    final factory = imapFactory;
    if (factory != null) {
      final gw = factory();
      try {
        caps = await gw.connect(account, password).timeout(timeout);
        imapOk = true;
      } catch (e) {
        imapErr = e is ImapGatewayException ? e.message : e.toString();
      } finally {
        try {
          await gw.disconnect();
        } catch (_) {}
      }
    }
    final smtp = this.smtp;
    var smtpOk = smtp == null;
    String? smtpErr;
    if (smtp != null) {
      try {
        await smtp.testLogin(account, password).timeout(timeout);
        smtpOk = true;
      } catch (e) {
        smtpErr = e is SmtpGatewayException ? e.message : e.toString();
      }
    }
    return ProbeResult(candidate: c, imapOk: imapOk, smtpOk: smtpOk, imapError: imapErr, smtpError: smtpErr, capabilities: caps);
  }

  /// Convenience: first candidate whose IMAP (and SMTP) login succeeds.
  Future<ProbeResult?> discoverAndProbe(String email, String password, {void Function(ServerCandidate)? onTrying}) async {
    for (final c in await discover(email)) {
      onTrying?.call(c);
      final r = await probe(c, password);
      if (r.ok) return r;
      if (r.imapOk && !r.smtpOk) {
        // Right IMAP host; try the other SMTP guesses for the same domain.
        for (final alt in _patterns(domainOf(email), email).where((p) => p.smtp != c.smtp)) {
          final merged = ServerCandidate(imap: c.imap, smtp: alt.smtp, username: c.username, source: 'mixed');
          final r2 = await probe(merged, password);
          if (r2.ok) return r2;
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------- sources

  Future<List<ServerCandidate>> _autoconfig(String email) async {
    try {
      final cfg = await em.Discover.discover(email).timeout(timeout);
      final imap = cfg?.preferredIncomingImapServer;
      final smtp = cfg?.preferredOutgoingSmtpServer;
      if (cfg == null || imap == null || smtp == null) return const [];
      final user = switch (imap.usernameType) {
        em.UsernameType.emailLocalPart => email.substring(0, email.indexOf('@')),
        _ => email,
      };
      return [
        ServerCandidate(
          imap: ImapEndpoint(host: imap.hostname, port: imap.port, security: _sec(imap.socketType, imap.port)),
          smtp: SmtpEndpoint(host: smtp.hostname, port: smtp.port, security: _sec(smtp.socketType, smtp.port)),
          username: user,
          source: 'autoconfig',
        ),
      ];
    } catch (e) {
      _log.fine('autoconfig failed: $e');
      return const [];
    }
  }

  static ConnectionSecurity _sec(em.SocketType t, int port) => switch (t) {
        em.SocketType.ssl => ConnectionSecurity.tls,
        em.SocketType.starttls => ConnectionSecurity.starttls,
        em.SocketType.plain => port == 993 || port == 465 ? ConnectionSecurity.tls : ConnectionSecurity.starttls,
        _ => port == 993 || port == 465 ? ConnectionSecurity.tls : ConnectionSecurity.starttls,
      };

  Future<List<ServerCandidate>> _srv(String domain, String email) async {
    try {
      final imaps = await _lookupSrv('_imaps._tcp.$domain');
      final imap = imaps.isEmpty ? await _lookupSrv('_imap._tcp.$domain') : const <_Srv>[];
      final submission = await _lookupSrv('_submission._tcp.$domain');
      final smtps = submission.isEmpty ? await _lookupSrv('_submissions._tcp.$domain') : const <_Srv>[];
      final imapEp = imaps.isNotEmpty
          ? ImapEndpoint(host: imaps.first.host, port: imaps.first.port, security: ConnectionSecurity.tls)
          : imap.isNotEmpty
              ? ImapEndpoint(host: imap.first.host, port: imap.first.port, security: ConnectionSecurity.starttls)
              : null;
      final smtpEp = submission.isNotEmpty
          ? SmtpEndpoint(host: submission.first.host, port: submission.first.port, security: submission.first.port == 465 ? ConnectionSecurity.tls : ConnectionSecurity.starttls)
          : smtps.isNotEmpty
              ? SmtpEndpoint(host: smtps.first.host, port: smtps.first.port, security: ConnectionSecurity.tls)
              : null;
      if (imapEp == null) return const [];
      final smtp = smtpEp ?? SmtpEndpoint(host: imapEp.host, port: 587, security: ConnectionSecurity.starttls);
      return [ServerCandidate(imap: imapEp, smtp: smtp, username: email, source: 'srv')];
    } catch (e) {
      _log.fine('SRV lookup failed: $e');
      return const [];
    }
  }

  Future<List<_Srv>> _lookupSrv(String name) async {
    final client = _http ?? HttpClient();
    client.connectionTimeout = timeout;
    try {
      final uri = Uri.parse(dohEndpoint).replace(queryParameters: {'name': name, 'type': 'SRV'});
      final req = await client.getUrl(uri).timeout(timeout);
      req.headers.set(HttpHeaders.acceptHeader, 'application/dns-json');
      final resp = await req.close().timeout(timeout);
      if (resp.statusCode != 200) return const [];
      final body = jsonDecode(await resp.transform(utf8.decoder).join()) as Map<String, dynamic>;
      final answers = (body['Answer'] as List?) ?? const [];
      final out = <_Srv>[];
      for (final a in answers.cast<Map<String, dynamic>>()) {
        if (a['type'] != 33) continue;
        final parts = (a['data'] as String).trim().split(RegExp(r'\s+'));
        if (parts.length < 4) continue;
        final host = parts[3].replaceAll(RegExp(r'\.$'), '');
        if (host.isEmpty || host == '.') continue;
        out.add(_Srv(priority: int.tryParse(parts[0]) ?? 0, weight: int.tryParse(parts[1]) ?? 0, port: int.tryParse(parts[2]) ?? 0, host: host));
      }
      out.sort((a, b) => a.priority != b.priority ? a.priority.compareTo(b.priority) : b.weight.compareTo(a.weight));
      return out;
    } finally {
      if (_http == null) client.close(force: true);
    }
  }

  List<ServerCandidate> _patterns(String domain, String email, {bool includeInsecure = true}) {
    final imapHosts = ['imap.$domain', 'mail.$domain', domain];
    final smtpHosts = ['smtp.$domain', 'mail.$domain', domain];
    final out = <ServerCandidate>[];
    for (var i = 0; i < imapHosts.length; i++) {
      final smtpHost = smtpHosts[i];
      for (final imapPort in [993, if (includeInsecure) 143]) {
        for (final smtpPort in [587, 465]) {
          out.add(ServerCandidate(
            imap: ImapEndpoint(host: imapHosts[i], port: imapPort, security: imapPort == 993 ? ConnectionSecurity.tls : ConnectionSecurity.starttls),
            smtp: SmtpEndpoint(host: smtpHost, port: smtpPort, security: smtpPort == 465 ? ConnectionSecurity.tls : ConnectionSecurity.starttls),
            username: email,
            source: 'pattern',
          ));
        }
      }
    }
    return out;
  }

  static List<ServerCandidate> _dedupe(List<ServerCandidate> list) {
    final seen = <String>{};
    return [
      for (final c in list)
        if (seen.add('${c.imap.host}:${c.imap.port}:${c.imap.security.name}|${c.smtp.host}:${c.smtp.port}:${c.smtp.security.name}|${c.username}')) c,
    ];
  }
}

class _Srv {
  const _Srv({required this.priority, required this.weight, required this.port, required this.host});
  final int priority;
  final int weight;
  final int port;
  final String host;
}
