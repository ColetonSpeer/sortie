import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../platform/fold/fold_geometry.dart';
import '../../router/app_router.dart';
import '../compose/open_compose.dart';
import '../mailbox/folder_list.dart';
import '../mailbox/message_list.dart';
import '../message_view/message_screen.dart';
import 'rail_header.dart';

/// Three-pane (>= 1000 dp), two-pane (600-999) or stacked (< 600) mail shell.
///
/// On a folding phone (iPhone Duo) the inner display is two-pane wide and
/// the panes follow the fold: list left of it, message right of it, and in
/// the laptop pose the message above it and the list below. Opening or
/// closing the device is only a resize; the open message, its scroll
/// position and its read-guard hold survive the layout change.
class AdaptiveScaffold extends ConsumerWidget {
  const AdaptiveScaffold({super.key, required this.accountId, required this.folderPath, this.uid, this.messageFolder, this.messageAccount});

  /// A real account id, or [Routes.allAccounts] for the unified inbox.
  final String accountId;
  final String folderPath;
  final int? uid;

  /// Folder of the open message when it differs from [folderPath] (a Sent
  /// reply opened from a thread in another folder).
  final String? messageFolder;

  /// Account of the open message when the list is All inboxes.
  final String? messageAccount;

  bool get isAll => accountId == Routes.allAccounts;

  static const compactBreakpoint = 600.0;
  static const expandedBreakpoint = 1000.0;
  static const railWidth = 260.0;
  static const listWidth = 400.0;

  /// The list pane's width in the two-pane layout when no fold dictates it.
  static const twoPaneListWidth = 340.0;

  /// Keyed per open message so the reader keeps its State (body, scroll
  /// position, view choices, read-guard hold) when a fold or a window resize
  /// moves it between the stacked and the two-pane layout.
  static final _messageKeys = <String, GlobalKey>{};
  static GlobalKey _messageKey(String id) {
    final k = _messageKeys.putIfAbsent(id, () => GlobalKey(debugLabel: id));
    while (_messageKeys.length > 16) {
      _messageKeys.remove(_messageKeys.keys.first);
    }
    return k;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the UI-only "current account" in sync with the route.
    if (!isAll && ref.read(selectedAccountIdProvider) != accountId) {
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
        selectedAccount: messageAccount ?? accountId,
        showMenuButton: showMenuButton,
      );

  Widget _view({required bool standalone}) => uid == null
      ? const _EmptyMessagePane()
      : MessageScreen(
          key: _messageKey('msg:$accountId:$folderPath|${messageAccount ?? accountId}:${messageFolder ?? folderPath}:$uid'),
          accountId: messageAccount ?? accountId,
          folderPath: messageFolder ?? folderPath,
          uid: uid!,
          standalone: standalone,
          listAccountId: accountId,
          listFolder: folderPath,
        );

  Widget _threePane(BuildContext context) => Scaffold(
        body: SafeArea(
            top: false,
            bottom: false,
            child: Row(children: [
          SizedBox(width: railWidth, child: _rail()),
          const VerticalDivider(width: 1),
          SizedBox(width: listWidth, child: _list(showMenuButton: false)),
          const VerticalDivider(width: 1),
          Expanded(child: _view(standalone: false)),
        ])),
      );

  Widget _twoPane(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // The iPhone Duo's inner display carries its status bar and camera in a
    // strip along one edge, reported as a left or right safe-area inset.
    // Scaffold does not keep its body out of horizontal insets, so the
    // panes are placed inside them here (once; the panes' own bars then
    // see no inset). Fold positions arrive in window coordinates, hence
    // the correction by the inset the row starts after.
    final pad = MediaQuery.paddingOf(context);
    final folds = FoldScope.of(context);
    final laptop = folds.activeHorizontalFoldIn(size);
    Widget inset(Widget child) => SafeArea(top: false, bottom: false, child: child);
    if (laptop != null) {
      // Laptop pose: read on the raised half, pick from the list on the
      // flat half; the crease itself stays empty.
      final top = laptop.bounds.top.clamp(160.0, size.height - 160.0);
      return Scaffold(
        drawer: Drawer(child: _rail()),
        body: inset(Column(children: [
          SizedBox(height: top, child: _view(standalone: false)),
          SizedBox(height: (laptop.bounds.bottom - top).clamp(0.0, size.height - top)),
          Expanded(child: _list(showMenuButton: true)),
        ])),
        floatingActionButton: _fabs(),
      );
    }
    final book = folds.verticalFoldIn(size);
    final usable = size.width - pad.left - pad.right;
    // Without a fold the list takes its usual width, less on a window only
    // just wide enough for two panes (the inner display held upright), so
    // the reader keeps room for its toolbar. A flat crease is only a seam:
    // the divider goes on it. A partially folded one is kept clear across
    // its whole reserved width.
    final listWidth = book == null
        ? math.min(twoPaneListWidth, usable * 0.45)
        : ((book.active ? book.bounds.left : book.bounds.center.dx) - pad.left).clamp(220.0, usable - 220.0);
    final gap = book != null && book.active ? (book.bounds.right - pad.left - listWidth).clamp(0.0, usable - listWidth) : 0.0;
    return Scaffold(
      drawer: Drawer(child: _rail()),
      body: inset(Row(children: [
        SizedBox(width: listWidth, child: _list(showMenuButton: true)),
        if (gap > 0) SizedBox(width: gap) else const VerticalDivider(width: 1),
        Expanded(child: _view(standalone: false)),
      ])),
      floatingActionButton: _fabs(),
    );
  }

  Widget _stacked(BuildContext context) {
    if (uid != null) return _view(standalone: true);
    return Scaffold(
      drawer: Drawer(child: _rail()),
      body: _list(showMenuButton: true),
      floatingActionButton: _fabs(),
    );
  }

  /// Compose and Blabber buttons for the layouts whose rail is a drawer
  /// (stacked and two-pane); the three-pane rail has them inline.
  Widget _fabs() => Consumer(
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
            key: const Key('composeFab'),
            heroTag: 'compose',
            tooltip: 'Compose',
            onPressed: () => openCompose(context, ref, accountId: accountId),
            child: const Icon(Icons.edit_outlined),
          ),
        ]),
      );
}

/// Left pane: header (account, sync, coordination) + folder tree + nav links.
class FolderRail extends ConsumerWidget {
  const FolderRail({super.key, required this.accountId, required this.selectedFolder});
  final String accountId;
  final String selectedFolder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= AdaptiveScaffold.compactBreakpoint;
    final accounts = ref.watch(accountsProvider).asData?.value ?? const <Account>[];
    final isAll = accountId == Routes.allAccounts;
    // New mail from the unified view goes out through the first account.
    final composeAccount = isAll ? (accounts.firstOrNull?.id ?? accountId) : accountId;
    void go(String route) {
      if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) Navigator.of(context).pop();
      context.go(route);
    }

    final allRow = accounts.length > 1
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListTile(
              key: const Key('allInboxes'),
              dense: true,
              selected: isAll,
              selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              leading: const Icon(Icons.all_inbox_outlined, size: 20),
              title: Text('All inboxes', style: TextStyle(fontWeight: isAll ? FontWeight.w600 : null)),
              onTap: () => go(Routes.allInboxes),
            ),
          )
        : null;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SafeArea(
        child: Column(children: [
          RailHeader(accountId: accountId),
          if (wide)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                FilledButton.tonalIcon(
                  onPressed: () => openCompose(context, ref, accountId: composeAccount),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Compose'),
                ),
                const SizedBox(height: 6),
                FilledButton.tonalIcon(
                  key: const Key('blabberCompose'),
                  onPressed: () => openCompose(context, ref, accountId: composeAccount, blabber: true),
                  icon: const Icon(Icons.mic_none_outlined),
                  label: const Text('Blabber'),
                ),
              ]),
            ),
          Expanded(
            child: isAll
                // Every account's folders, each under its name.
                ? ListView(padding: const EdgeInsets.symmetric(vertical: 4), children: [
                    ?allRow,
                    for (final a in accounts) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
                        child: Text(a.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ),
                      FolderList(
                        accountId: a.id,
                        selectedPath: '',
                        embedded: true,
                        onSelect: (path) => go(Routes.mailbox(a.id, path)),
                      ),
                    ],
                  ])
                : Column(children: [
                    ?allRow,
                    Expanded(
                      child: FolderList(
                        accountId: accountId,
                        selectedPath: selectedFolder,
                        onSelect: (path) => go(Routes.mailbox(accountId, path)),
                      ),
                    ),
                  ]),
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
