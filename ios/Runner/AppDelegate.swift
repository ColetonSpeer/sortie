import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // BGTaskScheduler requires every identifier to be registered before the
    // app finishes launching. With the implicit-engine template plugins are
    // registered later, so register Sortie's two tasks explicitly here.
    // Identifiers must match Info.plist BGTaskSchedulerPermittedIdentifiers and
    // lib/platform/background/ios_bg_refresh_runner.dart.
    WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: "com.sortie.sortie.processing")
    WorkmanagerPlugin.registerPeriodicTask(withIdentifier: "com.sortie.sortie.refresh", frequency: NSNumber(value: 15 * 60))
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
