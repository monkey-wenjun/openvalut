import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/utils/clipboard_prefs.dart';

final _logger = Logger('clipboard_auto_clear');

/// Manages a delayed clear of the system clipboard for sensitive data.
///
/// Only clears the clipboard if its current contents still match the value
/// OpenValut copied, so user-copied content in between is not destroyed.
class ClipboardAutoClear {
  ClipboardAutoClear._();

  static Timer? _timer;
  static String? _lastCopiedText;

  /// Copy [text] to the clipboard and schedule an automatic clear after the
  /// configured number of seconds. If [seconds] is omitted, the current value
  /// of [ClipboardPrefs.autoClearSeconds] is used.
  static Future<void> copyWithAutoClear(
    String text, {
    int? seconds,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    scheduleClear(text: text, seconds: seconds ?? ClipboardPrefs.autoClearSeconds.value);
  }

  /// Schedule a clear of the clipboard after [seconds], but only if the
  /// clipboard still contains [text] at that time.
  static void scheduleClear({required String text, required int seconds}) {
    cancel();
    if (seconds <= 0) {
      return;
    }
    _lastCopiedText = text;
    _logger.fine('Scheduling clipboard clear in $seconds seconds.');
    _timer = Timer(Duration(seconds: seconds), () async {
      await _maybeClear();
    });
  }

  /// Cancel any pending clipboard clear without touching the clipboard.
  static void cancel() {
    _timer?.cancel();
    _timer = null;
    _lastCopiedText = null;
  }

  /// Immediately clear the clipboard if it still contains the last copied
  /// text, then cancel any pending clear.
  static Future<void> clearIfMatches() async {
    await _maybeClear();
    cancel();
  }

  static Future<void> _maybeClear() async {
    final expected = _lastCopiedText;
    _lastCopiedText = null;
    if (expected == null) {
      return;
    }
    try {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == expected) {
        await Clipboard.setData(const ClipboardData(text: ''));
        _logger.fine('Clipboard cleared automatically.');
      } else {
        _logger.fine('Clipboard content changed; skipping auto-clear.');
      }
    } on Exception catch (e, stackTrace) {
      _logger.warning('Failed to auto-clear clipboard.', e, stackTrace);
    }
  }
}
