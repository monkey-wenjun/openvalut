import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _logger = Logger('secure_window');

/// Toggles OS-level "exclude this window from screen capture" on desktop
/// platforms that support it.
///
/// Windows uses `SetWindowDisplayAffinity(WDA_EXCLUDEFROMCAPTURE)`, macOS uses
/// `NSWindow.sharingType = .none`. Linux has no standard API for excluding a
/// window from screen capture, so this call is simply never made there.
class SecureWindow {
  SecureWindow._();

  static const _channel = MethodChannel('app.openvalut/secureWindow');

  static Future<void> setSecure(bool secure) async {
    try {
      await _channel.invokeMethod<void>(
        'setSecureWindow',
        {'secure': secure},
      );
    } catch (e) {
      // Non-fatal: on platforms without a native handler screenshots simply
      // cannot be blocked.
      _logger.fine('Secure window not supported: $e');
    }
  }

  /// Prevents other ordinary processes from observing keyboard events while
  /// a password field has focus. Currently implemented by macOS using Secure
  /// Event Input; unsupported platforms safely ignore the request.
  static Future<void> setSecureEventInput(bool secure) async {
    try {
      await _channel.invokeMethod<void>(
        'setSecureEventInput',
        {'secure': secure},
      );
    } catch (e) {
      _logger.fine('Secure event input not supported: $e');
    }
  }

  /// Requests native biometric authentication before a sensitive desktop
  /// operation. Unsupported or failed authentication is denied.
  static Future<bool> authenticate(String reason) async {
    try {
      return await _channel.invokeMethod<bool>(
            'authenticate',
            {'reason': reason},
          ) ??
          false;
    } catch (e) {
      _logger.warning('System authentication failed: $e');
      return false;
    }
  }
}
