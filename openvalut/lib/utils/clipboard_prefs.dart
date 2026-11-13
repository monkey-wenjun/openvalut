import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferences for the clipboard auto-clear feature.
///
/// After copying a username or password, OpenValut can automatically clear the
/// system clipboard after a configurable number of seconds. A value of 0
/// disables auto-clear.
class ClipboardPrefs {
  ClipboardPrefs._();

  static const _autoClearSecondsKey = 'clipboard_auto_clear_seconds'; // NON-NLS

  static const defaultAutoClearSeconds = 10;
  static const maxAutoClearSeconds = 60;

  /// Number of seconds after which sensitive clipboard contents are cleared.
  /// 0 means the feature is disabled.
  static final ValueNotifier<int> autoClearSeconds = ValueNotifier(
    defaultAutoClearSeconds,
  );

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    autoClearSeconds.value =
        prefs.getInt(_autoClearSecondsKey) ?? defaultAutoClearSeconds;
  }

  static Future<void> setAutoClearSeconds(int value) async {
    final clamped = value.clamp(0, maxAutoClearSeconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoClearSecondsKey, clamped);
    autoClearSeconds.value = clamped;
  }
}
