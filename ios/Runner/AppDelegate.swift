import AVFoundation
import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var settleTask: UIBackgroundTaskIdentifier = .invalid

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
    // Leaving the app: ask for the ~30 s of background time iOS grants so a
    // sort cycle that is under way can finish before the process is frozen.
    NotificationCenter.default.addObserver(self, selector: #selector(enteredBackground), name: UIScene.didEnterBackgroundNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(enteredForeground), name: UIScene.willEnterForegroundNotification, object: nil)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SortieBackground") else { return }
    let channel = FlutterMethodChannel(name: "com.sortie.sortie/background", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "keepAlive":
        if (call.arguments as? Bool) ?? false {
          BackgroundKeepAlive.shared.start()
        } else {
          BackgroundKeepAlive.shared.stop()
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  @objc private func enteredBackground() {
    endSettleTask()
    settleTask = UIApplication.shared.beginBackgroundTask(withName: "sortie-settle") { [weak self] in self?.endSettleTask() }
    DispatchQueue.main.asyncAfter(deadline: .now() + 25) { [weak self] in self?.endSettleTask() }
  }

  @objc private func enteredForeground() {
    endSettleTask()
  }

  private func endSettleTask() {
    if settleTask != .invalid {
      UIApplication.shared.endBackgroundTask(settleTask)
      settleTask = .invalid
    }
  }
}

/// Keeps the process running after the user leaves the app by playing
/// silence under the `audio` background mode, so the IMAP connections stay
/// up and this phone can keep sorting. Mixes with other audio; opt-out in
/// Settings > Devices ("Keep sorting in the background").
final class BackgroundKeepAlive: NSObject {
  static let shared = BackgroundKeepAlive()

  private var player: AVAudioPlayer?
  private var wanted = false
  private var observing = false

  func start() {
    wanted = true
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
      try session.setActive(true)
      if player == nil {
        let p = try AVAudioPlayer(data: BackgroundKeepAlive.silentWav(seconds: 2))
        p.numberOfLoops = -1
        p.prepareToPlay()
        player = p
      }
      player?.play()
      if !observing {
        observing = true
        NotificationCenter.default.addObserver(self, selector: #selector(interrupted(_:)), name: AVAudioSession.interruptionNotification, object: nil)
      }
    } catch {
      NSLog("Sortie keep-alive failed: \(error)")
    }
  }

  func stop() {
    wanted = false
    player?.stop()
    player = nil
    if observing {
      observing = false
      NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
    }
    try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
  }

  /// A phone call or another app's audio ended: resume the silence.
  @objc private func interrupted(_ n: Notification) {
    guard wanted,
          let raw = n.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: raw),
          type == .ended else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
      if self?.wanted == true { self?.start() }
    }
  }

  /// 8 kHz mono 16-bit PCM silence; tiny and loops seamlessly.
  static func silentWav(seconds: Int) -> Data {
    let rate: UInt32 = 8000
    let channels: UInt16 = 1
    let bits: UInt16 = 16
    let dataSize = UInt32(seconds) * rate * UInt32(channels) * UInt32(bits / 8)
    var d = Data()
    func u32(_ v: UInt32) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 4)) }
    func u16(_ v: UInt16) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 2)) }
    d.append("RIFF".data(using: .ascii)!)
    u32(36 + dataSize)
    d.append("WAVE".data(using: .ascii)!)
    d.append("fmt ".data(using: .ascii)!)
    u32(16)
    u16(1)
    u16(channels)
    u32(rate)
    u32(rate * UInt32(channels) * UInt32(bits / 8))
    u16(channels * bits / 8)
    u16(bits)
    d.append("data".data(using: .ascii)!)
    u32(dataSize)
    d.append(Data(count: Int(dataSize)))
    return d
  }
}
