import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'router/app_router.dart';

/// Root widget: Material 3, indigo seed, theme mode from DeviceSettings.
class SortieApp extends ConsumerWidget {
  const SortieApp({super.key});

  static ThemeData theme(Brightness b) => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: b),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
        cardTheme: const CardThemeData(margin: EdgeInsets.zero),
      );

  static ThemeMode modeFrom(String s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final mode = ref.watch(deviceSettingsProvider).asData?.value.themeMode ?? 'system';
    return MaterialApp.router(
      title: 'Sortie',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: modeFrom(mode),
      routerConfig: router,
    );
  }
}
