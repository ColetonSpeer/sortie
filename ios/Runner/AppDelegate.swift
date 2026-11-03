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
    // Background tasks run in their own Flutter engine; without this the
    // plugins (path_provider, secure storage, sqlite) are missing there and
    // the cycle cannot even open the database.
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    // Leaving the app: ask for the ~30 s of background time iOS grants so a
    // sort cycle that is under way can finish before the process is frozen.
    NotificationCenter.default.addObserver(self, selector: #selector(enteredBackground), name: UIScene.didEnterBackgroundNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(enteredForeground), name: UIScene.willEnterForegroundNotification, object: nil)
    // iPhone Duo: once the scene is on screen, watch the fold from inside
    // Flutter's view (reserved regions are per view).
    NotificationCenter.default.addObserver(self, selector: #selector(sceneActivated(_:)), name: UIScene.didActivateNotification, object: nil)
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
    FoldReporter.shared.register(with: registrar.messenger())
  }

  @objc private func sceneActivated(_ n: Notification) {
    guard let scene = n.object as? UIWindowScene,
          let root = (scene.keyWindow ?? scene.windows.first)?.rootViewController?.view else { return }
    FoldReporter.shared.attach(to: root)
  }

  @objc private func enteredBackground() {
    BackgroundKeepAlive.shared.reassert()
    endSettleTask()
    settleTask = UIApplication.shared.beginBackgroundTask(withName: "sortie-settle") { [weak self] in self?.endSettleTask() }
    DispatchQueue.main.asyncAfter(deadline: .now() + 25) { [weak self] in self?.endSettleTask() }
  }

  @objc private func enteredForeground() {
    endSettleTask()
    // Dictation, a phone call or Siri may have left the session inactive.
    BackgroundKeepAlive.shared.reassert()
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
  private var watchdog: Timer?

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
    } catch {
      // Typically the dictation plugin still owns the session; the watchdog
      // tries again shortly.
      NSLog("Sortie keep-alive failed: \(error)")
    }
    if !observing {
      observing = true
      let nc = NotificationCenter.default
      nc.addObserver(self, selector: #selector(interrupted(_:)), name: AVAudioSession.interruptionNotification, object: nil)
      nc.addObserver(self, selector: #selector(mediaReset), name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
    }
    if watchdog == nil {
      // The player can stop without an interruption notification (another
      // app's session change, dictation deactivating the shared session);
      // a stopped player means iOS freezes the process within seconds of
      // leaving the app. While the process is alive, keep it playing.
      watchdog = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in self?.reassert() }
    }
  }

  func stop() {
    wanted = false
    watchdog?.invalidate()
    watchdog = nil
    player?.stop()
    player = nil
    if observing {
      observing = false
      let nc = NotificationCenter.default
      nc.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
      nc.removeObserver(self, name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
    }
    try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
  }

  /// Restarts the silence when it should be playing and is not.
  func reassert() {
    guard wanted else { return }
    if player?.isPlaying != true { start() }
  }

  /// The media server crashed: every player and session is gone.
  @objc private func mediaReset() {
    player = nil
    if wanted { start() }
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

/// iPhone Duo (iOS 27.1+): tells Dart where the fold is, as
/// `{folds: [{x, y, w, h, active}]}` in Flutter's logical coordinates, over
/// the `com.sortie.sortie/fold` event channel. UIKit describes the fold as a
/// "division" reserved region: absent on the outer display, inactive while
/// the device lies fully open (the crease is only a seam), active while it
/// is partially folded. Flutter leaves `MediaQuery.displayFeatures` empty
/// on iOS, so without this bridge dialogs would open across the crease and
/// the mail panes could not line up with it. Needs the iOS 27.1 SDK
/// (Xcode 27.1) to compile.
final class FoldReporter: NSObject, FlutterStreamHandler {
  static let shared = FoldReporter()

  private var sink: FlutterEventSink?
  private var last: [String: Any] = ["folds": [[String: Any]]()]
  private var probe: UIView?

  func register(with messenger: FlutterBinaryMessenger) {
    FlutterEventChannel(name: "com.sortie.sortie/fold", binaryMessenger: messenger).setStreamHandler(self)
  }

  /// Adds the (invisible, non-interactive) probe view to Flutter's view once.
  func attach(to root: UIView) {
    guard probe == nil else { return }
    if #available(iOS 27.1, *) {
      let p = FoldProbeView(frame: root.bounds)
      p.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      p.onChange = { [weak self] folds in self?.publish(folds) }
      root.addSubview(p)
      probe = p
    }
  }

  private func publish(_ folds: [[String: Any]]) {
    last = ["folds": folds]
    sink?(last)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    events(last)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }
}

/// Fills Flutter's view, draws nothing and takes no touches; it exists so
/// that `reservedRegions` can be read in the same coordinate space Flutter
/// lays out in. UIKit re-runs `updateConstraints()` whenever the regions
/// read there change (fold, unfold, rotate, Split View).
@available(iOS 27.1, *)
final class FoldProbeView: UIView {
  var onChange: (([[String: Any]]) -> Void)?
  private var signature = ""

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    isAccessibilityElement = false
    backgroundColor = .clear
    isOpaque = false
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

  override class var requiresConstraintBasedLayout: Bool { true }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    setNeedsUpdateConstraints()
    report()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    report()
  }

  override func updateConstraints() {
    report()
    super.updateConstraints()
  }

  private func report() {
    guard window != nil else { return }
    let regions = reservedRegions(kind: .division, options: .includeInactive)
    let folds: [[String: Any]] = regions.map { r in
      [
        "x": Double(r.frame.origin.x),
        "y": Double(r.frame.origin.y),
        "w": Double(r.frame.width),
        "h": Double(r.frame.height),
        "active": r.isActive,
      ]
    }
    let sig = regions.map { r in "\(r.frame.origin.x),\(r.frame.origin.y),\(r.frame.width),\(r.frame.height),\(r.isActive)" }.joined(separator: ";")
    if sig == signature { return }
    signature = sig
    onChange?(folds)
  }
}
