import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/utils/constants.dart';
import 'package:openvalut/utils/platform.dart';
import 'package:tray_manager/tray_manager.dart' as tm;

final _logger = Logger('tray');

const _windowChannel = MethodChannel('openvalut/window'); // NON-NLS

/// System tray integration (desktop): the close button can hide the window
/// to the tray instead of exiting; the tray menu restores it or quits.
class TrayController {
  static bool _initialized = false;

  static Future<void> init() async {
    _logger.info(
      'Tray init start: isDesktop=${OpenValutPlatform.isDesktop}, '
      'initialized=$_initialized',
    );
    if (!OpenValutPlatform.isDesktop || _initialized) {
      _logger.info(
        'Tray init skipped: isDesktop=${OpenValutPlatform.isDesktop}, '
        'initialized=$_initialized',
      );
      return;
    }
    _initialized = true;

    // macOS handles the tray natively via NSStatusItem in MainFlutterWindow,
    // so we skip tray_manager on macOS entirely.
    if (OpenValutPlatform.isMacOS) {
      _logger.info('Tray: macOS uses native NSStatusItem (MainFlutterWindow).');
      return;
    }

    try {
      _logger.info('Tray: setting icon...');
      await _setIcon();
      _logger.info('Tray: icon set done.');
      // The tray_manager Linux plugin does not implement `setToolTip`, so skip
      // it there — otherwise the native side throws MissingPluginException and
      // aborts the rest of the tray setup (context menu + listener).
      if (!OpenValutPlatform.isLinux) {
        _logger.info('Tray: setting tooltip...');
        await tm.trayManager.setToolTip('OpenValut'); // NON-NLS
        _logger.info('Tray: tooltip set done.');
      }
      _logger.info('Tray: setting context menu...');
      // Native tray menus are created before the Flutter locale is resolved,
      // so they follow the OS language (restart to re-apply after switching
      // the language inside the app).
      final zh = (OpenValutPlatform.localeName ?? '').toLowerCase().startsWith(
        'zh',
      );
      await tm.trayManager.setContextMenu(
        tm.Menu(
          items: [
            tm.MenuItem(
              key: 'open',
              label: zh ? '显示 OpenValut' : 'Show OpenValut',
            ),
            tm.MenuItem(key: 'exit', label: zh ? '退出' : 'Quit'),
          ],
        ),
      );
      _logger.info('Tray: context menu set done.');
      _logger.info('Tray: adding listener...');
      tm.TrayManager.instance.addListener(_TrayListener());
      _logger.info('System tray initialized.');
    } catch (e, stackTrace) {
      _logger.warning('Unable to initialize system tray.', e, stackTrace);
    }
  }

  static Future<void> _setIcon() async {
    if (OpenValutPlatform.isWindows) {
      _logger.info(
        'Tray _setIcon: windows, path=${AssetConstants.logoIconWindows}',
      );
      await tm.trayManager.setIcon(AssetConstants.logoIconWindows);
      return;
    }
    if (OpenValutPlatform.isMacOS) {
      _logger.info('Tray _setIcon: macos, path=${AssetConstants.logoIcon}');
      await tm.trayManager.setIcon(AssetConstants.logoIcon);
      return;
    }
    // Linux: tray_manager builds the icon path as
    // dirname(Platform.resolvedExecutable)/data/flutter_assets/<iconPath>,
    // so we must pass the Flutter asset path here. Passing an absolute path
    // (e.g. /opt/openvalut/icon.png) would be reassembled into an invalid path
    // and the tray icon would silently not appear.
    // In sandboxed environments (Snap/Flatpak) the plugin expects a named icon.
    final iconPath = _isSandboxed() ? 'openvalut' : AssetConstants.logoIconTray;
    _logger.info(
      'Tray _setIcon: linux, sandboxed=${_isSandboxed()}, iconPath=$iconPath, '
      'resolvedExe=${Platform.resolvedExecutable}',
    );
    await tm.trayManager.setIcon(iconPath);
    _logger.info('Tray _setIcon: linux setIcon call returned.');
  }

  static bool _isSandboxed() {
    final env = Platform.environment;
    return env.containsKey('FLATPAK_ID') || // NON-NLS
        env.containsKey('SNAP') || // NON-NLS
        (env['container']?.isNotEmpty == true) || // NON-NLS
        File('/.dockerenv').existsSync();
  }

  /// Hides the window but keeps the process (and the tray icon) alive.
  static Future<void> hideToTray() async {
    _logger.info('hideToTray called.');
    try {
      await _windowChannel.invokeMethod('hide');
      _logger.info('hideToTray: native hide returned.');
    } catch (e, stackTrace) {
      _logger.warning('Unable to hide window to tray.', e, stackTrace);
    }
  }

  /// Minimizes the window to the taskbar/dock. The native side uses
  /// gtk_window_iconify, so the window stays visible in the taskbar and can be
  /// clicked to restore — it does not rely on the tray icon being available.
  static Future<void> minimizeToTaskbar() async {
    _logger.info('minimizeToTaskbar called.');
    try {
      await _windowChannel.invokeMethod('minimize');
      _logger.info('minimizeToTaskbar: native minimize returned.');
    } catch (e, stackTrace) {
      _logger.warning('Unable to minimize window to taskbar.', e, stackTrace);
    }
  }

  static Future<void> showFromTray() async {
    _logger.info('showFromTray called.');
    try {
      await _windowChannel.invokeMethod('show');
      _logger.info('showFromTray: native show returned.');
    } catch (e, stackTrace) {
      _logger.warning('Unable to restore window from tray.', e, stackTrace);
    }
  }

  /// Returns whether the main window is currently visible.
  static Future<bool> isWindowVisible() async {
    try {
      final visible = await _windowChannel.invokeMethod<bool>('isVisible');
      return visible ?? false;
    } catch (e, stackTrace) {
      _logger.warning('Unable to query window visibility.', e, stackTrace);
      return false;
    }
  }

  /// Returns whether the main window is currently minimized.
  static Future<bool> isWindowMinimized() async {
    try {
      final minimized = await _windowChannel.invokeMethod<bool>('isMinimized');
      return minimized ?? false;
    } catch (e, stackTrace) {
      _logger.warning('Unable to query window minimized state.', e, stackTrace);
      return false;
    }
  }

  /// Toggles the main window: hides it when it is visible and not minimized,
  /// otherwise shows/restores it. This is bound to left-clicking the tray icon.
  static Future<void> toggleTrayWindow() async {
    _logger.info('toggleTrayWindow called.');
    final visible = await isWindowVisible();
    final minimized = await isWindowMinimized();
    _logger.info(
      'toggleTrayWindow: visible=$visible minimized=$minimized',
    );
    if (visible && !minimized) {
      await hideToTray();
    } else {
      await showFromTray();
    }
  }

  /// Really quits the app (C side allows the close event through).
  static Future<void> quit() async {
    try {
      await _windowChannel.invokeMethod('close');
    } catch (e, stackTrace) {
      _logger.warning('Unable to quit from tray.', e, stackTrace);
    }
  }
}

class _TrayListener extends tm.TrayListener {
  @override
  void onTrayIconMouseDown() {
    _logger.info('Tray icon mouse down.');
    unawaited(TrayController.toggleTrayWindow());
  }

  @override
  void onTrayIconRightMouseDown() {
    // Linux / macOS pop the context menu up natively, but the Windows
    // implementation only reports the click and waits for this call — without
    // it a right-click on the tray icon does nothing.
    if (OpenValutPlatform.isWindows) {
      unawaited(tm.trayManager.popUpContextMenu(bringAppToFront: true));
    }
  }

  @override
  void onTrayMenuItemClick(tm.MenuItem menuItem) {
    _logger.info('Tray menu item clicked: ${menuItem.key}.');
    switch (menuItem.key) {
      case 'open':
        unawaited(TrayController.showFromTray());
      case 'exit':
        unawaited(TrayController.quit());
    }
  }
}
