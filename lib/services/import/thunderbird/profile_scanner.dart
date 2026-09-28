import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../domain/entities/entities.dart';
import '../calendar_import_sink.dart';
import 'filter_rules_parser.dart';
import 'import_models.dart';
import 'prefs_parser.dart';
import 'signature_text.dart';

/// Reads a Thunderbird profile directory (prefs.js + msgFilterRules.dat)
/// into an [ImportPreview]. Never touches key4.db / logins.json.
class ProfileScanner {
  const ProfileScanner();

  Future<ImportPreview> scan(Directory profile, {required List<Account> existing}) async {
    final prefsFile = File(p.join(profile.path, 'prefs.js'));
    if (!await prefsFile.exists()) throw ImportException('No prefs.js in ${profile.path}; is this a Thunderbird profile?');
    final prefs = parsePrefsJs(await prefsFile.readAsString());
    final skipped = <String>[];
    final accounts = <TbAccount>[];
    for (final key in prefs.list('mail.accountmanager.accounts')) {
      final a = await _account(key, prefs, profile, existing, skipped);
      if (a != null) accounts.add(a);
    }
    return ImportPreview(profilePath: profile.path, accounts: accounts, calendars: calendars(prefs), skipped: skipped);
  }

  Future<TbAccount?> _account(String key, Map<String, Object?> prefs, Directory profile, List<Account> existing, List<String> skipped) async {
    final serverKey = prefs.str('mail.account.$key.server');
    if (serverKey == null) return null;
    final s = 'mail.server.$serverKey';
    final type = prefs.str('$s.type') ?? '';
    final host = prefs.str('$s.hostname') ?? '';
    final name = prefs.str('$s.name') ?? host;
    if (type == 'none') return null; // Local Folders
    if (type != 'imap') {
      skipped.add('$name: $type accounts are not supported (Sortie needs IMAP)');
      return null;
    }
    if (host.isEmpty) {
      skipped.add('$name: no IMAP host');
      return null;
    }
    final username = prefs.str('$s.userName') ?? '';
    final notes = <String>[];
    if (prefs.integer('$s.authMethod') == 10) notes.add('Thunderbird used OAuth2 for this account; Sortie needs a password or app password');

    final imapSec = _security(prefs.integer('$s.socketType'));
    final imap = ImapEndpoint(host: host, port: prefs.integer('$s.port') ?? (imapSec == ConnectionSecurity.tls ? 993 : 143), security: imapSec);

    final identities = <TbIdentity>[];
    final ids = prefs.list('mail.account.$key.identities');
    for (var i = 0; i < ids.length; i++) {
      final id = await _identity(ids[i], prefs, profile, isDefault: i == 0);
      if (id != null) identities.add(id);
    }
    final email = identities.firstOrNull?.email ?? (username.contains('@') ? username : '');

    final smtpKey = identities.map((i) => prefs.str('mail.identity.${i.key}.smtpServer')).whereType<String>().firstOrNull ?? prefs.str('mail.smtp.defaultserver');
    final smtp = _smtp(smtpKey, prefs, fallbackHost: host);
    if (smtpKey == null || prefs.str('mail.smtpserver.$smtpKey.hostname') == null) notes.add('No SMTP server found; using ${smtp.$1.host}:${smtp.$1.port}');

    final filterFile = _filterFile(prefs, s, profile, host);
    var filters = const <TbFilter>[];
    if (filterFile != null && await File(filterFile).exists()) {
      try {
        filters = parseFilterRules(await File(filterFile).readAsString());
      } catch (e) {
        notes.add('Could not read filters: $e');
      }
    }

    final match = existing.where((a) => a.imap.host.toLowerCase() == host.toLowerCase() && a.username.toLowerCase() == username.toLowerCase()).firstOrNull;
    return TbAccount(
      key: key,
      displayName: name,
      email: email,
      username: username,
      imap: imap,
      smtp: smtp.$1,
      smtpUsername: smtp.$2 == null || smtp.$2 == username ? null : smtp.$2,
      identities: identities,
      filters: filters,
      filterFile: filterFile,
      existingAccountId: match?.id,
      notes: notes,
    );
  }

  Future<TbIdentity?> _identity(String key, Map<String, Object?> prefs, Directory profile, {required bool isDefault}) async {
    final i = 'mail.identity.$key';
    final email = prefs.str('$i.useremail') ?? '';
    if (email.isEmpty) return null;
    final notes = <String>[];
    var text = '';
    String? html;
    final inline = prefs.str('$i.htmlSigText') ?? '';
    final attachFile = prefs.boolean('$i.attach_signature') ?? false;
    final sigFile = prefs.str('$i.sig_file');
    if (attachFile && sigFile != null && sigFile.isNotEmpty) {
      final f = File(sigFile);
      if (await f.exists()) {
        final content = await f.readAsString();
        final isHtml = RegExp(r'\.x?html?$', caseSensitive: false).hasMatch(sigFile) || looksLikeHtml(content);
        if (isHtml) {
          html = content;
          text = htmlSignatureToText(content);
        } else {
          text = content.trimRight();
        }
      } else {
        notes.add('Signature file not found: $sigFile');
      }
    }
    if (text.isEmpty && inline.isNotEmpty) {
      if (prefs.boolean('$i.htmlSigFormat') ?? false) {
        html = inline;
        text = htmlSignatureToText(inline);
      } else {
        text = inline;
      }
    }
    return TbIdentity(
      key: key,
      name: prefs.str('$i.fullName') ?? '',
      email: email,
      replyTo: _blankToNull(prefs.str('$i.reply_to')),
      organization: _blankToNull(prefs.str('$i.organization')),
      signature: text,
      signatureHtml: html,
      isDefault: isDefault,
      notes: notes,
    );
  }

  (SmtpEndpoint, String?) _smtp(String? key, Map<String, Object?> prefs, {required String fallbackHost}) {
    final k = key == null ? null : 'mail.smtpserver.$key';
    final host = k == null ? null : prefs.str('$k.hostname');
    if (k == null || host == null || host.isEmpty) {
      return (SmtpEndpoint(host: fallbackHost, port: 587, security: ConnectionSecurity.starttls), null);
    }
    final sec = _security(prefs.integer('$k.try_ssl'));
    final port = prefs.integer('$k.port') ?? (sec == ConnectionSecurity.tls ? 465 : 587);
    return (SmtpEndpoint(host: host, port: port, security: sec), _blankToNull(prefs.str('$k.username')));
  }

  /// `directory-rel` (`[ProfD]ImapMail/host`) is preferred over the absolute
  /// `directory` because the profile may have been copied from another machine.
  String? _filterFile(Map<String, Object?> prefs, String s, Directory profile, String host) {
    final rel = prefs.str('$s.directory-rel');
    String? dir;
    if (rel != null && rel.startsWith('[ProfD]')) {
      dir = p.join(profile.path, rel.substring('[ProfD]'.length).replaceAll(r'\', '/'));
    } else if (rel != null && !rel.startsWith('[')) {
      dir = rel;
    } else {
      final abs = prefs.str('$s.directory');
      dir = abs != null && Directory(abs).existsSync() ? abs : p.join(profile.path, 'ImapMail', host);
    }
    return p.join(dir, 'msgFilterRules.dat');
  }

  static ConnectionSecurity _security(int? socketType) => switch (socketType) {
        3 => ConnectionSecurity.tls,
        2 => ConnectionSecurity.starttls,
        _ => ConnectionSecurity.none,
      };

  static String? _blankToNull(String? s) => s == null || s.trim().isEmpty ? null : s;

  /// `calendar.registry.<uuid>.*`, ordered by `calendar.list.sortOrder`.
  static List<ImportedCalendar> calendars(Map<String, Object?> prefs) {
    final ids = <String>{};
    for (final k in prefs.keys) {
      final m = RegExp(r'^calendar\.registry\.([^.]+)\.').firstMatch(k);
      if (m != null) ids.add(m.group(1)!);
    }
    final order = (prefs.str('calendar.list.sortOrder') ?? '').split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    final sorted = [...order.where(ids.contains), ...ids.where((i) => !order.contains(i))];
    return [
      for (final id in sorted)
        ImportedCalendar(
          id: id,
          name: prefs.str('calendar.registry.$id.name') ?? id,
          type: prefs.str('calendar.registry.$id.type') ?? 'storage',
          uri: prefs.str('calendar.registry.$id.uri') ?? '',
          username: _blankToNull(prefs.str('calendar.registry.$id.username')),
          color: _blankToNull(prefs.str('calendar.registry.$id.color')),
          disabled: prefs.boolean('calendar.registry.$id.disabled') ?? false,
          readOnly: prefs.boolean('calendar.registry.$id.readOnly') ?? false,
        ),
    ];
  }
}

class ImportException implements Exception {
  const ImportException(this.message);
  final String message;
  @override
  String toString() => message;
}
