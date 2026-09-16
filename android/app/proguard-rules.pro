# Flutter / plugins keep rules are provided by the plugins themselves.
-keep class io.flutter.** { *; }

# Flutter's deferred-components manager references Play Core, which Sortie does not ship.
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
