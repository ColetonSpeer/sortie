import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app/bootstrap.dart';
import 'app/composition_root.dart';
import 'app/demo_overrides.dart';
import 'core/logging.dart';
import 'platform/desktop/window_service.dart';
import 'platform/device_info.dart';

/// `--dart-define=SORTIE_DEMO=true` runs the UI against in-memory fakes.
const bool kDemo = bool.fromEnvironment('SORTIE_DEMO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logFile = FileLogSink(p.join((await getApplicationSupportDirectory()).path, 'sortie.log'));
  initLogging(level: kDebugMode ? Level.FINE : Level.INFO, sink: (line) {
    logFile(line);
    if (kDebugMode) debugPrint(line);
  });
  final log = Logger('main');

  if (isDesktop) {
    final w = WindowService.instance;
    if (!await w.acquireSingleInstance()) {
      log.info('another Sortie instance is running; exiting');
      exit(0);
    }
    await w.init();
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

  runApp(ProviderScope(overrides: overrides, child: const SortieBootstrap()));
  unawaited(services?.start());
}
