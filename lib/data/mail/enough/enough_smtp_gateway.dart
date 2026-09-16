import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:enough_mail/enough_mail.dart' as em;
import 'package:logging/logging.dart';

import '../../../domain/entities/entities.dart';
import '../smtp_gateway.dart';

/// [SmtpGateway] over enough_mail's [em.SmtpClient]. Stateless: each send
/// opens, authenticates, submits and quits.
class EnoughSmtpGateway implements SmtpGateway {
  EnoughSmtpGateway({
    this.connectTimeout = const Duration(seconds: 20),
    this.clientDomain = 'sortie.local',
    this.onBadCertificate,
    this.protocolLog = false,
  });

  final Duration connectTimeout;
  final String clientDomain;
  final bool Function(X509Certificate)? onBadCertificate;
  final bool protocolLog;
  final _log = Logger('sortie.smtp');

  @override
  Future<SmtpSendResult> send(Account account, String password, Identity identity, List<String> recipients, List<int> raw) async {
    if (recipients.isEmpty) throw const SmtpGatewayException('no recipients');
    final client = await _open(account, password);
    try {
      final from = em.MailAddress(identity.name, identity.email);
      final to = recipients.map((r) => em.MailAddress(null, r.trim())).toList();
      final text = utf8.decode(raw, allowMalformed: true);
      final supports8bit = client.serverInfo.supports('8BITMIME');
      final resp = await client.sendMessageText(text, from, to, use8BitEncoding: supports8bit);
      if (resp.isFailedStatus) {
        throw SmtpGatewayException('server rejected message: ${resp.errorMessage}');
      }
      _log.info('sent message from ${identity.email} to ${recipients.length} recipient(s): ${resp.code}');
      return SmtpSendResult(accepted: true, response: '${resp.code} ${resp.message ?? ''}'.trim());
    } on SmtpGatewayException {
      rethrow;
    } catch (e) {
      throw _map(e, 'send failed');
    } finally {
      await _quit(client);
    }
  }

  @override
  Future<void> testLogin(Account account, String password) async {
    final client = await _open(account, password);
    await _quit(client);
  }

  Future<em.SmtpClient> _open(Account account, String password) async {
    final ep = account.smtp;
    final client = em.SmtpClient(clientDomain, isLogEnabled: protocolLog, onBadCertificate: onBadCertificate);
    try {
      await client.connectToServer(ep.host, ep.port, isSecure: ep.security == ConnectionSecurity.tls, timeout: connectTimeout);
      await client.ehlo();
      if (ep.security == ConnectionSecurity.starttls) {
        final r = await client.startTls();
        if (r.isFailedStatus) throw SmtpGatewayException('STARTTLS refused: ${r.errorMessage}');
      } else if (ep.security == ConnectionSecurity.none && client.serverInfo.supports('STARTTLS')) {
        // Opportunistic upgrade even when the account says plain.
        try {
          await client.startTls();
        } catch (e) {
          _log.fine('opportunistic STARTTLS failed: $e');
        }
      }
    } on SmtpGatewayException {
      await _quit(client);
      rethrow;
    } catch (e) {
      await _quit(client);
      throw _map(e, 'connect to ${ep.host}:${ep.port} failed');
    }
    final user = account.smtpUsername ?? account.username;
    try {
      final mech = client.serverInfo.supportsAuth(em.AuthMechanism.plain)
          ? em.AuthMechanism.plain
          : client.serverInfo.supportsAuth(em.AuthMechanism.login)
              ? em.AuthMechanism.login
              : em.AuthMechanism.plain;
      final r = await client.authenticate(user, password, mech);
      if (r.isFailedStatus) {
        throw SmtpGatewayException('authentication failed: ${r.errorMessage}', isAuthFailure: true);
      }
    } on SmtpGatewayException {
      await _quit(client);
      rethrow;
    } catch (e) {
      await _quit(client);
      throw _map(e, 'authentication failed', authHint: true);
    }
    return client;
  }

  Future<void> _quit(em.SmtpClient client) async {
    try {
      if (client.isConnected) await client.quit().timeout(const Duration(seconds: 5));
    } catch (_) {}
    try {
      await client.disconnect();
    } catch (_) {}
  }

  static SmtpGatewayException _map(Object e, String prefix, {bool authHint = false}) {
    String text;
    var auth = authHint;
    if (e is em.SmtpException) {
      final code = e.response.code ?? 0;
      text = e.response.errorMessage.isEmpty ? (e.message ?? e.toString()) : e.response.errorMessage;
      auth = auth && (code == 535 || code == 534 || code == 530 || code == 501);
      if (code == 535) auth = true;
    } else {
      text = e.toString();
      auth = false;
    }
    text = text.replaceAll(RegExp(r'AUTH PLAIN \S+'), 'AUTH PLAIN ****');
    return SmtpGatewayException('$prefix: $text', isAuthFailure: auth, cause: e);
  }
}
