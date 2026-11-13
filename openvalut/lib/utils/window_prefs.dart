import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// Desktop window preferences: what happens when the user clicks the window
/// close button — exit the app, minimize to the taskbar (dock), or hide to
/// the system tray.
class WindowPrefs {
  WindowPrefs._();

  static const _closeActionKey = 'window_close_action'; // NON-NLS
  static const _autoStartKey = 'window_auto_start'; // NON-NLS

  /// 'hide' = close button hides window to tray (default);
  /// 'minimize' = close button minimizes to taskbar;
  /// 'exit' = close app.
  static final ValueNotifier<String> closeAction = ValueNotifier('hide');

  /// Whether the app should start automatically when the user logs in.
  /// Currently implemented on Linux via ~/.config/autostart.
  static final ValueNotifier<bool> autoStart = ValueNotifier(false);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_closeActionKey);
    if (stored == 'exit' || stored == 'minimize' || stored == 'hide') {
      closeAction.value = stored!;
    }
    autoStart.value = await _isAutoStartEnabled();
  }

  static Future<void> setCloseAction(String value) async {
    if (value != 'exit' && value != 'minimize' && value != 'hide') {
      return;
    }
    closeAction.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_closeActionKey, value);
  }

  static Future<void> setAutoStart(bool enabled) async {
    if (Platform.isLinux) {
      await _setLinuxAutoStart(enabled);
    }
    autoStart.value = await _isAutoStartEnabled();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoStartKey, autoStart.value);
  }

  static Future<bool> _isAutoStartEnabled() async {
    if (!Platform.isLinux) {
      return false;
    }
    try {
      final file = File(_linuxAutoStartDesktopPath);
      return await file.exists();
    } on Exception catch (_) {
      return false;
    }
  }

  static String get _linuxAutoStartDesktopPath {
    final configHome = Platform.environment['XDG_CONFIG_HOME'] ??
        p.join(Platform.environment['HOME']!, '.config'); // NON-NLS
    return p.join(configHome, 'autostart', 'openvalut.desktop'); // NON-NLS
  }

  static Future<void> _setLinuxAutoStart(bool enabled) async {
    final desktopFile = File(_linuxAutoStartDesktopPath);
    if (enabled) {
      final exec = Platform.resolvedExecutable;
      final icon = p.join(p.dirname(exec), 'icon.png'); // NON-NLS
      final content = '''[Desktop Entry]
Type=Application
Name=OpenValut
Exec=env openvalut_START_HIDDEN=1 $exec
Icon=$icon
Comment=Password Manager
X-GNOME-Autostart-enabled=true
'''; // NON-NLS
      await desktopFile.parent.create(recursive: true);
      await desktopFile.writeAsString(content);
      // Best-effort make executable; not required for autostart but matches
      // common desktop file conventions.
      try {
        await Process.run('chmod', ['+x', desktopFile.path]); // NON-NLS
      } on Exception catch (_) {
        // ignore
      }
    } else {
      if (await desktopFile.exists()) {
        await desktopFile.delete();
      }
    }
  }
}
