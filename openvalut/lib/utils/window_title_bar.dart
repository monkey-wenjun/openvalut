import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/utils/platform.dart';

final _logger = Logger('window_title_bar');

/// Keeps the native window frame in sync with the app theme.
///
/// On Windows the title bar is drawn by the OS outside of Flutter, so it stays
/// light in dark mode unless the app asks for the immersive dark frame
/// (DWMWA_USE_IMMERSIVE_DARK_MODE) explicitly.
class WindowTitleBar {
  WindowTitleBar._();

  static const _channel = MethodChannel('openvalut/window'); // NON-NLS

  static bool? _lastDark;

  static Future<void> syncDark(bool dark) async {
    if (!OpenValutPlatform.isWindows || _lastDark == dark) {
      return;
    }
    _lastDark = dark;
    try {
      await _channel.invokeMethod<void>('setDarkTitleBar', {'dark': dark});
    } catch (e) {
      _logger.fine('Unable to set dark title bar: $e');
    }
  }
}
