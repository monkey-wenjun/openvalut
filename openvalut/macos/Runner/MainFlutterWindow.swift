import Cocoa
import Carbon.HIToolbox
import FlutterMacOS
import LocalAuthentication

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  private var windowChannel: FlutterMethodChannel?
  private var secureEventInputRequested = false
  private var secureEventInputEnabled = false

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.delegate = self

    RegisterGeneratedPlugins(registry: flutterViewController)

    let secureWindowChannel = FlutterMethodChannel(
      name: "app.openvalut/secureWindow",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    secureWindowChannel.setMethodCallHandler { [weak self] (call, result) in
      let secure =
        (call.arguments as? [String: Any])?["secure"] as? Bool ?? true
      switch call.method {
      case "setSecureWindow":
        self?.sharingType = secure ? .none : .readOnly
        result(nil)
      case "setSecureEventInput":
        self?.setSecureEventInputRequested(secure)
        result(nil)
      case "authenticate":
        let reason =
          (call.arguments as? [String: Any])?["reason"] as? String
          ?? "验证身份以访问 OpenValut"
        self?.authenticate(reason: reason, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    windowChannel = FlutterMethodChannel(
      name: "openvalut/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    windowChannel?.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(FlutterMethodNotImplemented)
        return
      }
      switch call.method {
      case "minimize":
        self.miniaturize(nil)
        result(nil)
      case "hide":
        self.orderOut(nil)
        result(nil)
      case "show":
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        result(nil)
      case "isVisible":
        result(self.isVisible)
      case "isMinimized":
        result(self.isMiniaturized)
      case "close":
        // Explicit quit (tray "退出" / "exit" close action). Since
        // applicationShouldTerminateAfterLastWindowClosed returns false, just
        // closing the window would leave the process alive, so terminate it.
        result(nil)
        NSApp.terminate(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()

    // Flutter's app lifecycle callback ordering can vary across macOS
    // releases. The window is guaranteed to be awake here, so use it as a
    // second initialization path for the persistent menu bar item.
    DispatchQueue.main.async {
      (NSApp.delegate as? AppDelegate)?.ensureStatusItem()
    }
  }

  private func authenticate(reason: String, result: @escaping FlutterResult) {
    let context = LAContext()
    var error: NSError?
    guard context.canEvaluatePolicy(
      .deviceOwnerAuthenticationWithBiometrics,
      error: &error
    ) else {
      result(
        FlutterError(
          code: "BIOMETRIC_UNAVAILABLE",
          message: error?.localizedDescription ?? "Biometric authentication unavailable",
          details: nil))
      return
    }
    context.evaluatePolicy(
      .deviceOwnerAuthenticationWithBiometrics,
      localizedReason: reason
    ) { success, _ in
      DispatchQueue.main.async {
        result(success)
      }
    }
  }

  private func setSecureEventInputRequested(_ secure: Bool) {
    secureEventInputRequested = secure
    updateSecureEventInput()
  }

  private func updateSecureEventInput() {
    let shouldEnable = secureEventInputRequested && isKeyWindow && NSApp.isActive
    guard shouldEnable != secureEventInputEnabled else { return }

    let status = shouldEnable
      ? EnableSecureEventInput()
      : DisableSecureEventInput()
    if status == noErr {
      secureEventInputEnabled = shouldEnable
    } else {
      NSLog(
        "OpenValut: unable to %@ Secure Event Input (OSStatus %d)",
        shouldEnable ? "enable" : "disable",
        status)
    }
  }

  func windowDidBecomeKey(_ notification: Notification) {
    updateSecureEventInput()
  }

  func windowDidResignKey(_ notification: Notification) {
    updateSecureEventInput()
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    // Never let AppKit close the window directly: ask Dart what the close
    // button should do (hide to tray / minimize / quit) and always veto the
    // native close. A real quit goes through the "close" channel method, which
    // calls NSApp.terminate.
    windowChannel?.invokeMethod("onWindowCloseRequested", arguments: nil)
    return false
  }

  deinit {
    if secureEventInputEnabled {
      DisableSecureEventInput()
    }
  }
}
