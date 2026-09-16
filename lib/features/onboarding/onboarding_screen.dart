import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/onboarding_models.dart';
import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../router/app_router.dart';
import 'server_form.dart';

enum _Step { welcome, credentials, discovering, manual, testing }

/// Welcome -> email/password -> autodiscovery -> (manual) -> test -> save.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _Step _step = _Step.welcome;
  final _credsKey = GlobalKey<FormState>();
  final _serverKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  ServerSettings? _server;
  List<ServerCandidate> _candidates = const [];
  String? _error;
  String _status = '';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _hasAccounts => (ref.read(accountsProvider).asData?.value ?? const []).isNotEmpty;

  Future<void> _discover() async {
    setState(() {
      _step = _Step.discovering;
      _error = null;
      _status = 'Finding your server…';
    });
    try {
      _candidates = await ref.read(autodiscoveryProvider)(_email.text.trim());
    } catch (e) {
      _candidates = const [];
      _error = 'Autodiscovery failed: $e';
    }
    if (!mounted) return;
    if (_candidates.isEmpty) {
      setState(() {
        _server = ServerSettings.guess(_email.text.trim());
        _step = _Step.manual;
        _error ??= 'Could not find server settings automatically. Please check them below.';
      });
      return;
    }
    final c = _candidates.first;
    _server = ServerSettings(
      imapHost: c.imap.host,
      imapPort: c.imap.port,
      imapSecurity: c.imap.security,
      smtpHost: c.smtp.host,
      smtpPort: c.smtp.port,
      smtpSecurity: c.smtp.security,
      username: c.username,
    );
    await _test();
  }

  Account _buildAccount(String id) {
    final s = _server!;
    final email = _email.text.trim();
    return Account(
      id: id,
      displayName: _name.text.trim().isEmpty ? email : _name.text.trim(),
      email: email,
      username: s.username.trim(),
      imap: s.imap,
      smtp: s.smtp,
      smtpUsername: s.smtpUsername.trim().isEmpty ? null : s.smtpUsername.trim(),
    );
  }

  Future<void> _test() async {
    setState(() {
      _step = _Step.testing;
      _error = null;
      _status = 'Checking login on ${_server!.imapHost}…';
    });
    final id = const Uuid().v4();
    final account = _buildAccount(id);
    try {
      await ref.read(loginProbeProvider)(account, _password.text);
      await _save(account);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Login failed: $e';
        _step = _Step.manual;
      });
    }
  }

  Future<void> _save(Account account) async {
    setState(() => _status = 'Saving account…');
    await ref.read(credentialStoreProvider).write(CredentialStore.accountPassword(account.id), _password.text);
    await ref.read(accountRepositoryProvider).upsert(account);
    await ref.read(accountRepositoryProvider).upsertIdentity(Identity(
          id: const Uuid().v4(),
          accountId: account.id,
          name: account.displayName == account.email ? account.email.split('@').first : account.displayName,
          email: account.email,
          isDefault: true,
        ));
    try {
      await ref.read(mailSyncServiceProvider).startAccount(account.id);
    } catch (e) {
      // Sync failures surface in the shell's status indicator; do not block onboarding.
      debugPrint('startAccount failed: $e');
    }
    if (mounted) context.go(Routes.mailbox(account.id, 'INBOX'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: _hasAccounts ? AppBar(title: const Text('Add account')) : null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(key: ValueKey(_step), child: _body(theme)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(ThemeData theme) => switch (_step) {
        _Step.welcome => _welcome(theme),
        _Step.credentials => _credentials(theme),
        _Step.discovering || _Step.testing => _progress(theme),
        _Step.manual => _manual(theme),
      };

  Widget _welcome(ThemeData theme) => Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.mark_email_unread_outlined, size: 72, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text('Sortie', style: theme.textTheme.displaySmall),
        const SizedBox(height: 8),
        Text('An email client that sorts itself.', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          'Connect any IMAP account. Sortie learns your folders and, when you want, files mail for you — never while you are reading it.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          key: const Key('getStarted'),
          onPressed: () => setState(() => _step = _Step.credentials),
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Get started'),
        ),
      ]);

  Widget _credentials(ThemeData theme) => Form(
        key: _credsKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text('Your account', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('name'),
            controller: _name,
            decoration: const InputDecoration(labelText: 'Your name (optional)', border: OutlineInputBorder()),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('email'),
            controller: _email,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Email address', border: OutlineInputBorder()),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            validator: (v) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email address',
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('password'),
            controller: _password,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _showPassword ? 'Hide' : 'Show',
                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            autofillHints: const [AutofillHints.password],
            validator: (v) => (v ?? '').isEmpty ? 'Password is required' : null,
            onFieldSubmitted: (_) => _submitCreds(),
          ),
          const SizedBox(height: 24),
          Row(children: [
            TextButton(onPressed: () => setState(() => _step = _Step.welcome), child: const Text('Back')),
            const Spacer(),
            FilledButton(key: const Key('continue'), onPressed: _submitCreds, child: const Text('Continue')),
          ]),
        ]),
      );

  void _submitCreds() {
    if (_credsKey.currentState?.validate() ?? false) _discover();
  }

  Widget _progress(ThemeData theme) => Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(_status, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(_email.text, style: theme.textTheme.bodySmall),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => setState(() {
            _server ??= ServerSettings.guess(_email.text.trim());
            _step = _Step.manual;
          }),
          child: const Text('Enter server settings manually'),
        ),
      ]);

  Widget _manual(ThemeData theme) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        Text('Server settings', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(_email.text, style: theme.textTheme.bodySmall),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer))),
              ]),
            ),
          ),
        ],
        if (_candidates.length > 1) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<ServerCandidate>(
            decoration: const InputDecoration(labelText: 'Discovered configurations', border: OutlineInputBorder()),
            items: [for (final c in _candidates) DropdownMenuItem(value: c, child: Text('${c.imapLabel} · ${c.smtpLabel}', overflow: TextOverflow.ellipsis))],
            onChanged: (c) {
              if (c == null) return;
              setState(() => _server = ServerSettings(
                    imapHost: c.imap.host,
                    imapPort: c.imap.port,
                    imapSecurity: c.imap.security,
                    smtpHost: c.smtp.host,
                    smtpPort: c.smtp.port,
                    smtpSecurity: c.smtp.security,
                    username: c.username,
                  ));
            },
          ),
        ],
        const SizedBox(height: 16),
        ServerForm(
          key: ValueKey(_server),
          formKey: _serverKey,
          initial: _server!,
          onChanged: (s) => _server = s,
        ),
        const SizedBox(height: 24),
        Row(children: [
          TextButton(onPressed: () => setState(() => _step = _Step.credentials), child: const Text('Back')),
          const Spacer(),
          FilledButton.icon(
            key: const Key('testAndSave'),
            onPressed: () {
              if (_serverKey.currentState?.validate() ?? false) _test();
            },
            icon: const Icon(Icons.login),
            label: const Text('Test & save'),
          ),
        ]),
      ]);
}
