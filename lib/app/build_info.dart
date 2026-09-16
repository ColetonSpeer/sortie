/// Compile-time build metadata. CI passes `--dart-define=SORTIE_VERSION=1.2.3+45`.
abstract final class BuildInfo {
  static const appName = 'Sortie';
  static const version = String.fromEnvironment('SORTIE_VERSION', defaultValue: 'dev');
}
