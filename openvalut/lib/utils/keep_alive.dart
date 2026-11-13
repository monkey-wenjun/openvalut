import 'package:flutter/services.dart';

/// Starts/stops the Android foreground service that keeps the app process
/// alive while the vault is unlocked.
///
/// Without it, aggressive ROMs kill the backgrounded app while the user is in
/// another app, forcing them to unlock again when they return. With it, the
/// already-unlocked vault stays in memory.
/// Named SessionKeepAlive to avoid clashing with Flutter's [KeepAlive] widget.
class SessionKeepAlive {
  SessionKeepAlive._();

  static const _channel = MethodChannel('app.openvalut/misc');

  static Future<void> start() async {
    try {
      await _channel.invokeMethod<void>('startKeepAlive');
    } catch (e) {
      // Non-fatal: without the service, the user falls back to the normal
      // unlock flow (quick unlock / master password).
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stopKeepAlive');
    } catch (_) {
      // Ignore.
    }
  }
}
