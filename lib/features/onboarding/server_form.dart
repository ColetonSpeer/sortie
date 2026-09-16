import 'package:flutter/material.dart';

import '../../domain/entities/entities.dart';

/// Editable IMAP/SMTP endpoints. Emits a fresh value on every change.
class ServerSettings {
  const ServerSettings({
    required this.imapHost,
    required this.imapPort,
    required this.imapSecurity,
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpSecurity,
    required this.username,
    this.smtpUsername = '',
  });

  final String imapHost;
  final int imapPort;
  final ConnectionSecurity imapSecurity;
  final String smtpHost;
  final int smtpPort;
  final ConnectionSecurity smtpSecurity;
  final String username;
  final String smtpUsername;

  static ServerSettings guess(String email) {
    final domain = email.contains('@') ? email.split('@').last : '';
    return ServerSettings(
      imapHost: 'mail.$domain',
      imapPort: 993,
      imapSecurity: ConnectionSecurity.tls,
      smtpHost: 'mail.$domain',
      smtpPort: 587,
      smtpSecurity: ConnectionSecurity.starttls,
      username: email,
    );
  }

  ImapEndpoint get imap => ImapEndpoint(host: imapHost.trim(), port: imapPort, security: imapSecurity);
  SmtpEndpoint get smtp => SmtpEndpoint(host: smtpHost.trim(), port: smtpPort, security: smtpSecurity);

  ServerSettings copyWith({
    String? imapHost,
    int? imapPort,
    ConnectionSecurity? imapSecurity,
    String? smtpHost,
    int? smtpPort,
    ConnectionSecurity? smtpSecurity,
    String? username,
    String? smtpUsername,
  }) =>
      ServerSettings(
        imapHost: imapHost ?? this.imapHost,
        imapPort: imapPort ?? this.imapPort,
        imapSecurity: imapSecurity ?? this.imapSecurity,
        smtpHost: smtpHost ?? this.smtpHost,
        smtpPort: smtpPort ?? this.smtpPort,
        smtpSecurity: smtpSecurity ?? this.smtpSecurity,
        username: username ?? this.username,
        smtpUsername: smtpUsername ?? this.smtpUsername,
      );
}

class ServerForm extends StatefulWidget {
  const ServerForm({super.key, required this.initial, required this.onChanged, required this.formKey});
  final ServerSettings initial;
  final ValueChanged<ServerSettings> onChanged;
  final GlobalKey<FormState> formKey;

  @override
  State<ServerForm> createState() => _ServerFormState();
}

class _ServerFormState extends State<ServerForm> {
  late ServerSettings _s = widget.initial;

  void _update(ServerSettings next) {
    setState(() => _s = next);
    widget.onChanged(next);
  }

  int _defaultPort(bool imap, ConnectionSecurity sec) => imap
      ? (sec == ConnectionSecurity.tls ? 993 : 143)
      : switch (sec) { ConnectionSecurity.tls => 465, ConnectionSecurity.starttls => 587, ConnectionSecurity.none => 25 };

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Incoming (IMAP)', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _endpoint(
          host: _s.imapHost,
          port: _s.imapPort,
          security: _s.imapSecurity,
          onHost: (v) => _update(_s.copyWith(imapHost: v)),
          onPort: (v) => _update(_s.copyWith(imapPort: v)),
          onSecurity: (v) => _update(_s.copyWith(imapSecurity: v, imapPort: _defaultPort(true, v))),
          imap: true,
        ),
        const SizedBox(height: 16),
        Text('Outgoing (SMTP)', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _endpoint(
          host: _s.smtpHost,
          port: _s.smtpPort,
          security: _s.smtpSecurity,
          onHost: (v) => _update(_s.copyWith(smtpHost: v)),
          onPort: (v) => _update(_s.copyWith(smtpPort: v)),
          onSecurity: (v) => _update(_s.copyWith(smtpSecurity: v, smtpPort: _defaultPort(false, v))),
          imap: false,
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const Key('username'),
          initialValue: _s.username,
          decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
          onChanged: (v) => _update(_s.copyWith(username: v)),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: _s.smtpUsername,
          decoration: const InputDecoration(labelText: 'SMTP username (if different)', border: OutlineInputBorder()),
          onChanged: (v) => _update(_s.copyWith(smtpUsername: v)),
        ),
      ]),
    );
  }

  Widget _endpoint({
    required String host,
    required int port,
    required ConnectionSecurity security,
    required ValueChanged<String> onHost,
    required ValueChanged<int> onPort,
    required ValueChanged<ConnectionSecurity> onSecurity,
    required bool imap,
  }) {
    final prefix = imap ? 'imap' : 'smtp';
    return Column(children: [
      Row(children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            key: Key('$prefix.host'),
            initialValue: host,
            decoration: const InputDecoration(labelText: 'Server', border: OutlineInputBorder()),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
            onChanged: onHost,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            key: Key('$prefix.port.$port'),
            initialValue: '$port',
            decoration: const InputDecoration(labelText: 'Port', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            validator: (v) {
              final n = int.tryParse(v ?? '');
              return n == null || n < 1 || n > 65535 ? '1-65535' : null;
            },
            onChanged: (v) {
              final n = int.tryParse(v);
              if (n != null) onPort(n);
            },
          ),
        ),
      ]),
      const SizedBox(height: 8),
      SegmentedButton<ConnectionSecurity>(
        segments: const [
          ButtonSegment(value: ConnectionSecurity.tls, label: Text('SSL/TLS')),
          ButtonSegment(value: ConnectionSecurity.starttls, label: Text('STARTTLS')),
          ButtonSegment(value: ConnectionSecurity.none, label: Text('None')),
        ],
        selected: {security},
        onSelectionChanged: (s) => onSecurity(s.first),
      ),
    ]);
  }
}
