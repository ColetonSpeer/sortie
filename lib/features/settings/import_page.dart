import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../services/import/thunderbird/thunderbird_importer.dart';
import 'import_preview_widgets.dart';

/// Settings > Import from Thunderbird: locate profile -> preview -> import.
class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  List<TbProfile>? _profiles;
  String? _profilePath;
  ImportPreview? _preview;
  ImportSelection _selection = const ImportSelection();
  final _passwords = <String, TextEditingController>{};
  ImportResult? _result;
  bool _busy = false;
  String? _error;

  bool get _mobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    _discover();
  }

  @override
  void dispose() {
    for (final c in _passwords.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _discover() async {
    try {
      final found = await ref.read(thunderbirdImporterProvider).discoverProfiles();
      if (mounted) setState(() => _profiles = found);
    } catch (e) {
      if (mounted) setState(() => _profiles = const []);
    }
  }

  Future<void> _chooseFolder() async {
    final path = await FilePicker.getDirectoryPath(dialogTitle: 'Choose the Thunderbird profile folder');
    if (path == null) return;
    if (!await looksLikeProfile(Directory(path))) {
      setState(() => _error = 'No prefs.js in $path. Pick the profile folder itself (it contains prefs.js and ImapMail/).');
      return;
    }
    await _scan(path);
  }

  Future<void> _scan(String path) async {
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
      _preview = null;
    });
    try {
      final preview = await ref.read(thunderbirdImporterProvider).scan(Directory(path));
      for (final c in _passwords.values) {
        c.dispose();
      }
      _passwords.clear();
      for (final a in preview.accounts) {
        _passwords[a.key] = TextEditingController();
      }
      setState(() {
        _profilePath = path;
        _preview = preview;
        _selection = preview.selectAll();
      });
    } catch (e) {
      setState(() => _error = 'Could not read the profile: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final preview = _preview;
    if (preview == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final passwords = <String, String>{};
      for (final a in preview.accounts) {
        final pw = _passwords[a.key]?.text ?? '';
        if (pw.isNotEmpty) passwords[a.email.isEmpty ? a.key : a.email] = pw;
      }
      final result = await ref.read(thunderbirdImporterProvider).apply(preview, _selection, passwordsByAccountEmail: passwords);
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = 'Import failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _preview;
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Import from Thunderbird')),
      body: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
        if (_mobile)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              color: theme.colorScheme.secondaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Import needs a Thunderbird profile folder; copy it to this device or run the import on your desktop. '
                    'Accounts and sorting rules imported on the desktop reach this device through your mail account; '
                    'identities and signatures live per device, so import those here as well if you want them on this phone.'),
              ),
            ),
          ),
        _profileSection(theme),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(_error!, key: const Key('importError'), style: TextStyle(color: theme.colorScheme.error)),
          ),
        if (_busy) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        if (preview != null && result == null && !_busy) ...[
          ImportPreviewView(
            preview: preview,
            selection: _selection,
            onSelection: (s) => setState(() => _selection = s),
            passwords: _passwords,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: FilledButton.icon(
              key: const Key('importButton'),
              onPressed: _import,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Import'),
            ),
          ),
        ],
        if (result != null) ImportResultView(result: result),
      ]),
    );
  }

  Widget _profileSection(ThemeData theme) {
    final profiles = _profiles;
    return ImportSection(title: 'Thunderbird profile', children: [
      if (profiles == null) const ListTile(title: Text('Looking for profiles…')),
      if (profiles != null && profiles.isEmpty)
        const ListTile(
          leading: Icon(Icons.search_off_outlined),
          title: Text('No profile found automatically'),
          subtitle: Text('Use "Choose folder…" and pick the profile directory (contains prefs.js)'),
        ),
      if (profiles != null)
        for (final p in profiles)
          ListTile(
            key: Key('profile-${p.path}'),
            leading: Icon(p.path == _profilePath ? Icons.radio_button_checked : Icons.radio_button_off),
            title: Text(p.isDefault ? '${p.name} (default)' : p.name),
            subtitle: Text(p.path),
            onTap: _busy ? null : () => _scan(p.path),
          ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(children: [
          OutlinedButton.icon(
            key: const Key('chooseFolder'),
            onPressed: _busy ? null : _chooseFolder,
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('Choose folder…'),
          ),
          const SizedBox(width: 12),
          if (_profilePath != null) Expanded(child: Text(_profilePath!, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
        ]),
      ),
    ]);
  }
}
