import Cocoa
import FlutterMacOS
import LocalAuthentication

@main
class AppDelegate: FlutterAppDelegate {
  private var statusItem: NSStatusItem?
  private var trayMenu: NSMenu?
  private var restoreAuthenticationInProgress = false

  override func applicationWillFinishLaunching(_ notification: Notification) {
    super.applicationWillFinishLaunching(notification)
    configureApplication()
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    configureApplication()
    ensureStatusItem()
  }

  override func applicationDidBecomeActive(_ notification: Notification) {
    ensureStatusItem()
  }

  private func configureApplication() {
    // Keep OpenValut visible in the Dock even when its last window is hidden.
    NSApp.setActivationPolicy(.regular)
    if let appIcon = NSImage(named: NSImage.applicationIconName) {
      NSApp.applicationIconImage = appIcon
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Tray app: closing (or hiding) the main window must never terminate the
    // process. The window is only ever hidden to the tray on close; real quit
    // happens explicitly via NSApp.terminate from the window channel "close"
    // handler (tray "退出" / the "exit" close action).
    return false
  }

  override func applicationShouldHandleReopen(
    _ sender: NSApplication,
    hasVisibleWindows flag: Bool
  ) -> Bool {
    toggleMainWindowFromDock()
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  func ensureStatusItem() {
    if let statusItem {
      statusItem.isVisible = true
      return
    }

    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    item.autosaveName = "OpenValutStatusItem"
    statusItem = item
    item.isVisible = true

    guard let button = item.button else {
      NSLog("OpenValut: unable to create the menu bar button")
      NSStatusBar.system.removeStatusItem(item)
      statusItem = nil
      return
    }

    let image: NSImage?
    if #available(macOS 11.0, *) {
      image = NSImage(
        systemSymbolName: "lock.shield.fill",
        accessibilityDescription: "OpenValut")
    } else {
      image = loadTrayIcon() ?? NSImage(named: NSImage.applicationIconName)
    }
    if let image {
      image.size = NSSize(width: 18, height: 18)
      image.isTemplate = true
      button.image = image
      button.imagePosition = .imageOnly
      button.imageScaling = .scaleProportionallyDown
    } else {
      button.title = "OV"
    }
    button.toolTip = "OpenValut"
    button.setAccessibilityLabel("OpenValut")

    let menu = NSMenu()
    let showItem = NSMenuItem(
      title: "显示 OpenValut",
      action: #selector(authenticateAndShowMainWindow),
      keyEquivalent: "")
    showItem.target = self
    menu.addItem(showItem)
    menu.addItem(NSMenuItem.separator())
    let quitItem = NSMenuItem(
      title: "退出",
      action: #selector(quitApp),
      keyEquivalent: "q")
    quitItem.target = self
    menu.addItem(quitItem)
    trayMenu = menu

    button.target = self
    button.action = #selector(statusItemClicked)
    button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    NSLog("OpenValut: menu bar item installed")
  }

  private func loadTrayIcon() -> NSImage? {
    let appBundle = Bundle(identifier: "io.flutter.flutter.app")
    let assetURL = appBundle?.url(
      forResource: "logo_icon_tray",
      withExtension: "png",
      subdirectory: "flutter_assets/assets/images")
    guard let assetURL else {
      NSLog("OpenValut: menu bar asset was not found in App.framework")
      return nil
    }
    return NSImage(contentsOf: assetURL)
  }

  private func mainWindow() -> NSWindow? {
    return NSApp.windows.first(where: { $0 is MainFlutterWindow })
  }

  @objc private func statusItemClicked() {
    if NSApp.currentEvent?.type == .rightMouseUp {
      guard let menu = trayMenu, let button = statusItem?.button else { return }
      statusItem?.menu = menu
      button.performClick(nil)
      statusItem?.menu = nil
      return
    }

    guard let window = mainWindow() else { return }
    if window.isVisible {
      window.orderOut(nil)
    } else {
      authenticateAndShowMainWindow()
    }
  }

  @objc private func showMainWindow() {
    guard let window = mainWindow() else { return }
    if window.isMiniaturized {
      window.deminiaturize(nil)
    }
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  private func toggleMainWindowFromDock() {
    guard let window = mainWindow() else { return }
    if window.isVisible && !window.isMiniaturized {
      window.miniaturize(nil)
    } else {
      authenticateAndShowMainWindow()
    }
  }

  @objc private func authenticateAndShowMainWindow() {
    let defaults = UserDefaults.standard
    let fingerprintEnabled = defaults.bool(
      forKey: "flutter.fingerprint_unlock_enabled")
    let rememberDays = defaults.integer(
      forKey: "flutter.remember_unlock_days")
    guard fingerprintEnabled && rememberDays > 0 else {
      showMainWindow()
      return
    }
    guard !restoreAuthenticationInProgress else { return }

    let context = LAContext()
    var error: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
      NSLog(
        "OpenValut: system authentication unavailable before restore: %@",
        error?.localizedDescription ?? "unknown error")
      return
    }

    restoreAuthenticationInProgress = true
    context.evaluatePolicy(
      .deviceOwnerAuthentication,
      localizedReason: "验证身份以打开 OpenValut"
    ) { [weak self] success, authenticationError in
      DispatchQueue.main.async {
        guard let self else { return }
        self.restoreAuthenticationInProgress = false
        if success {
          self.showMainWindow()
        } else {
          NSLog(
            "OpenValut: authentication before restore failed: %@",
            authenticationError?.localizedDescription ?? "unknown error")
        }
      }
    }
  }

  @objc private func quitApp() {
    NSApp.terminate(nil)
  }
}
