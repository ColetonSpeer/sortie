import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:multiview_desktop/multiview_desktop.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app/bootstrap.dart';
import 'app/composition_root.dart';
import 'app/demo_overrides.dart';
import 'core/logging.dart';
import 'platform/desktop/compose_window.dart';
import 'platform/desktop/window_service.dart';
import 'platform/device_info.dart';

/// `--dart-define=SORTIE_DEMO=true` runs the UI against in-memory fakes.
const bool kDemo = bool.fromEnvironment('SORTIE_DEMO');

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final logFile = FileLogSink(p.join((await getApplicationSupportDirectory()).path, 'sortie.log'));
  initLogging(level: kDebugMode ? Level.FINE : Level.INFO, sink: (line) {
    logFile(line);
    if (kDebugMode) debugPrint(line);
  });
  final log = Logger('main');

  if (isDesktop) {
    if (!await WindowService.instance.acquireSingleInstance()) {
      log.info('another Sortie instance is running; exiting');
      exit(0);
    }
  }

  final List<Override> overrides;
  SortieServices? services;
  if (kDemo) {
    overrides = demoOverrides();
  } else {
    services = await SortieServices.build();
    overrides = services.overrides();
    if (isDesktop) {
      WindowService.instance.onQuit = () => services!.stop();
    }
  }

  final container = ProviderContainer(overrides: overrides);
  if (isDesktop) {
    // One engine, several OS windows: the main window and any compose
    // windows all share this provider container.
    runMultiApp(
      home: (_, _) => const SortieBootstrap(),
      globalScope: (child) => UncontrolledProviderScope(container: container, child: child),
      config: MultiAppConfig(
        generalParams: const MultiPlatformParams(closeMode: CloseMode.none, closeAppAfterLastWindowClosed: false),
        mainWindowOptions: const WindowOptions(
          title: 'Sortie',
          size: Size(1280, 800),
          minimumSize: Size(900, 600),
          alignment: Alignment.center,
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(WindowService.instance.init()));
  } else {
    runApp(UncontrolledProviderScope(container: container, child: const SortieBootstrap()));
  }
  unawaited(services?.start());

  // `sortie --compose`: open a new message for the first account right away
  // (desktop launcher action).
  if (args.contains('--compose') && services != null && isDesktop) {
    unawaited(_composeFromCli(services));
  }
}

Future<void> _composeFromCli(SortieServices services) async {
  // A second view attached before the main window is mapped crashes in the
  // GTK embedder's draw path, so wait for the main window to be visible.
  for (var i = 0; i < 50; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    try {
      if (MultiViewDesktop.main.isVisible()) break;
    } catch (_) {}
  }
  await Future<void>.delayed(const Duration(milliseconds: 500));
  final account = (await services.accounts.all()).firstOrNull;
  if (account == null) return;
  await openComposeWindow(ComposeWindowArgs(accountId: account.id));
}
