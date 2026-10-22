import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../compose/open_compose.dart';
import '../../router/app_router.dart';
import '../mailbox/folder_list.dart';
import '../mailbox/message_list.dart';
import '../message_view/message_screen.dart';
import 'rail_header.dart';

/// Three-pane (>= 1000 dp), two-pane (600-999) or stacked (< 600) mail shell.
class AdaptiveScaffold extends ConsumerWidget {
  const AdaptiveScaffold({super.key, required this.accountId, required this.folderPath, this.uid, this.messageFolder});

  final String accountId;
  final String folderPath;
  final int? uid;

  /// Folder of the open message when it differs from [folderPath] (a Sent
  /// reply opened from a thread in another folder).
  final String? messageFolder;

  static const compactBreakpoint = 600.0;
  static const expandedBreakpoint = 1000.0;
  static const railWidth = 260.0;
  static const listWidth = 400.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the UI-only "current account" in sync with the route.
    if (ref.read(selectedAccountIdProvider) != accountId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) ref.read(selectedAccountIdProvider.notifier).state = accountId;
      });
    }
    final width = MediaQuery.sizeOf(context).width;
    if (width >= expandedBreakpoint) return _threePane(context);
    if (width >= compactBreakpoint) return _twoPane(context);
    return _stacked(context);
  }

  Widget _rail() => FolderRail(accountId: accountId, selectedFolder: folderPath);

  Widget _list({required bool showMenuButton}) => MessageListPane(
        key: PageStorageKey('list:$accountId:$folderPath'),
        accountId: accountId,
        folderPath: folderPath,
        selectedUid: uid,
        selectedFolder: messageFolder ?? folderPath,
        showMenuButton: showMenuButton,
      );

  Widget _view({required bool standalone}) => uid == null
      ? const _EmptyMessagePane()
      : MessageScreen(
          key: ValueKey('msg:$accountId:${messageFolder ?? folderPath}:$uid'),
          accountId: accountId,
          folderPath: messageFolder ?? folderPath,
          uid: uid!,
          standalone: standalone,
        );

  Widget _threePane(BuildContext context) => Scaffold(
        body: Row(children: [
          SizedBox(width: railWidth, child: _rail()),
          const VerticalDivider(width: 1),
          SizedBox(width: listWidth, child: _list(showMenuButton: false)),
          const VerticalDivider(width: 1),
          Expanded(child: _view(standalone: false)),
        ]),
      );

  Widget _twoPane(BuildContext context) => Scaffold(
        drawer: Drawer(child: _rail()),
        body: Row(children: [
          SizedBox(width: 340, child: _list(showMenuButton: true)),
          const VerticalDivider(width: 1),
          Expanded(child: _view(standalone: false)),
        ]),
      );

  Widget _stacked(BuildContext context) {
    if (uid != null) return _view(standalone: true);
    return Scaffold(
      drawer: Drawer(child: _rail()),
      body: _list(showMenuButton: true),
      floatingActionButton: Consumer(
        builder: (context, ref, _) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
          FloatingActionButton.small(
            key: const Key('blabberFab'),
            heroTag: 'blabber',
            tooltip: 'Blabber: talk, get an email',
            onPressed: () => openCompose(context, ref, accountId: accountId, blabber: true),
            child: const Icon(Icons.mic_none_outlined),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'compose',
            tooltip: 'Compose',
            onPressed: () => openCompose(context, ref, accountId: accountId),
            child: const Icon(Icons.edit_outlined),
          ),
        ]),
      ),
    );
  }
}

/// Left pane: header (account, sync, coordination) + folder tree + nav links.
class FolderRail extends ConsumerWidget {
  const FolderRail({super.key, required this.accountId, required this.selectedFolder});
  final String accountId;
  final String selectedFolder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= AdaptiveScaffold.compactBreakpoint;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SafeArea(
        child: Column(children: [
          RailHeader(accountId: accountId),
          if (wide)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => openCompose(context, ref, accountId: accountId),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Compose'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  key: const Key('blabberCompose'),
                  onPressed: () => openCompose(context, ref, accountId: accountId, blabber: true),
                  icon: const Icon(Icons.mic_none_outlined),
                  label: const Text('Blabber'),
                ),
              ]),
            ),
          Expanded(
            child: FolderList(
              accountId: accountId,
              selectedPath: selectedFolder,
              onSelect: (path) {
                if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) Navigator.of(context).pop();
                context.go(Routes.mailbox(accountId, path));
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Calendar'),
            onTap: () => context.push(Routes.calendar),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.history_outlined),
            title: const Text('Sort log'),
            onTap: () => context.push(Routes.sortLog),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () => context.push(Routes.settings),
          ),
        ]),
      ),
    );
  }
}

class _EmptyMessagePane extends StatelessWidget {
  const _EmptyMessagePane();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.mark_email_read_outlined, size: 56, color: cs.outline),
          const SizedBox(height: 12),
          Text('Select a message', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.outline)),
        ]),
      ),
    );
  }
}
