import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../features/accounts/accounts_screen.dart';
import '../features/accounts/identities_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/calendar/calendar_settings_page.dart';
import '../features/compose/compose_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/ai_settings_page.dart';
import '../features/settings/devices_page.dart';
import '../features/settings/diagnostics_page.dart';
import '../features/settings/folders_page.dart';
import '../features/settings/import_page.dart';
import '../features/settings/notifications_page.dart';
import '../features/settings/privacy_page.dart';
import '../features/settings/rules_page.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/sorting_page.dart';
import '../features/shell/adaptive_scaffold.dart';
import '../features/sort_log/sort_log_screen.dart';

/// Route helpers so features never hand-build paths.
abstract final class Routes {
  static const onboarding = '/onboarding';
  static const accounts = '/accounts';
  static const compose = '/compose';
  static const sortLog = '/sort-log';
  static const settings = '/settings';
  static const calendar = '/calendar';
  static const settingsImport = '/settings/import';

  static String identities(String accountId) => '/accounts/${Uri.encodeComponent(accountId)}/identities';
  static String mailbox(String accountId, String folder) =>
      '/mail/${Uri.encodeComponent(accountId)}/${Uri.encodeComponent(folder)}';
  static String message(String accountId, String folder, int uid) => '${mailbox(accountId, folder)}/message/$uid';
  static String composeWith({
    required String accountId,
    String? reply,
    String? replyAll,
    String? forward,
    String? draft,
    String? folder,
  }) {
    final q = <String, String>{'accountId': accountId};
    if (reply != null) q['reply'] = reply;
    if (replyAll != null) q['replyAll'] = replyAll;
    if (forward != null) q['forward'] = forward;
    if (draft != null) q['draft'] = draft;
    if (folder != null) q['folder'] = folder;
    return Uri(path: compose, queryParameters: q).toString();
  }

  static String settingsPage(String sub) => '/settings/$sub';
}

/// Notifies go_router whenever the account list changes so the
/// "no accounts -> onboarding" redirect re-evaluates.
class _AccountsListenable extends ChangeNotifier {
  void poke() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = _AccountsListenable();
  ref.listen(accountsProvider, (_, _) => listenable.poke());
  ref.onDispose(listenable.dispose);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: listenable,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final accounts = ref.read(accountsProvider);
      final loc = state.uri.path;
      if (accounts.isLoading && !accounts.hasValue) return loc == '/' ? null : '/';
      final list = accounts.asData?.value ?? const [];
      if (list.isEmpty) return loc == Routes.onboarding ? null : Routes.onboarding;
      if (loc == '/') return Routes.mailbox(list.first.id, 'INBOX');
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const _Splash()),
      GoRoute(path: Routes.onboarding, builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: Routes.accounts, builder: (_, _) => const AccountsScreen()),
      GoRoute(
        path: '/accounts/:id/identities',
        builder: (_, s) => IdentitiesScreen(accountId: Uri.decodeComponent(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/mail/:accountId/:folder',
        pageBuilder: (context, s) => _mailPage(context, s, uid: null),
        routes: [
          GoRoute(
            path: 'message/:uid',
            pageBuilder: (context, s) => _mailPage(context, s, uid: int.tryParse(s.pathParameters['uid'] ?? '')),
          ),
        ],
      ),
      GoRoute(
        path: Routes.compose,
        builder: (_, s) {
          final q = s.uri.queryParameters;
          return ComposeScreen(
            accountId: q['accountId'] ?? '',
            replyUid: int.tryParse(q['reply'] ?? ''),
            replyAllUid: int.tryParse(q['replyAll'] ?? ''),
            forwardUid: int.tryParse(q['forward'] ?? ''),
            draftUid: int.tryParse(q['draft'] ?? ''),
            sourceFolder: q['folder'],
          );
        },
      ),
      GoRoute(path: Routes.sortLog, builder: (_, _) => const SortLogScreen()),
      GoRoute(path: Routes.calendar, builder: (_, _) => const CalendarScreen()),
      GoRoute(
        path: Routes.settings,
        builder: (_, _) => const SettingsScreen(),
        routes: [
          GoRoute(path: 'ai', builder: (_, _) => const AiSettingsPage()),
          GoRoute(path: 'sorting', builder: (_, _) => const SortingPage()),
          GoRoute(path: 'rules', builder: (_, _) => const RulesPage()),
          GoRoute(path: 'privacy', builder: (_, _) => const PrivacyPage()),
          GoRoute(path: 'folders', builder: (_, _) => const FoldersPage()),
          GoRoute(path: 'devices', builder: (_, _) => const DevicesPage()),
          GoRoute(path: 'notifications', builder: (_, _) => const NotificationsPage()),
          GoRoute(path: 'diagnostics', builder: (_, _) => const DiagnosticsPage()),
          GoRoute(path: 'import', builder: (_, _) => const ImportPage()),
          GoRoute(path: 'calendar', builder: (_, _) => const CalendarSettingsPage()),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

Page<void> _mailPage(BuildContext context, GoRouterState s, {required int? uid}) {
  final accountId = Uri.decodeComponent(s.pathParameters['accountId']!);
  final folder = Uri.decodeComponent(s.pathParameters['folder']!);
  final child = AdaptiveScaffold(accountId: accountId, folderPath: folder, uid: uid);
  final wide = MediaQuery.sizeOf(context).width >= AdaptiveScaffold.compactBreakpoint;
  // Wide layouts keep the shell on screen; only the panes change, so no slide.
  return wide ? NoTransitionPage(key: s.pageKey, child: child) : MaterialPage(key: s.pageKey, child: child);
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
