import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/utils/app_locale.dart';
import 'package:openvalut/utils/platform.dart';

final _logger = Logger('system_auth');

const _miscChannel = MethodChannel('app.openvalut/misc'); // NON-NLS

/// Implemented by the Windows runner (`windows/runner/flutter_window.cpp`).
///
/// Windows has no `pkexec` equivalent that mirrors the Linux PAM prompt, so the
/// runner exposes Windows Hello (PIN / fingerprint / face) through this channel
/// instead.
const _userPresenceChannel = MethodChannel(
  'app.openvalut/userPresence', // NON-NLS
);

Future<String?>? _cachedBootId;

/// A stable identifier for the current boot session, or null when the
/// platform does not expose one.
///
/// The remembered-unlock store is tagged with this id so the master password
/// is only skipped while the machine keeps running: after a reboot the tag
/// no longer matches and the master password has to be entered again.
Future<String?> currentBootId() => _cachedBootId ??= _readBootId();

Future<String?> _readBootId() async {
  if (OpenValutPlatform.isAndroid) {
    // Android does not expose /proc/sys/kernel/random/boot_id to apps; the
    // platform side reports the system boot counter instead.
    try {
      final bootId = await _miscChannel.invokeMethod<String>('getBootId');
      if (bootId != null && bootId.isNotEmpty) {
        return bootId;
      }
    } on MissingPluginException {
      _logger.fine('Boot id channel is not available on this Android build.');
    } catch (e, stackTrace) {
      _logger.fine('Unable to read Android boot id.', e, stackTrace);
    }
    return null;
  }
  if (OpenValutPlatform.isLinux) {
    try {
      return File('/proc/sys/kernel/random/boot_id').readAsStringSync().trim();
    } catch (e, stackTrace) {
      _logger.fine('Unable to read Linux boot id.', e, stackTrace);
    }
    return null;
  }
  if (OpenValutPlatform.isMacOS) {
    try {
      final result = await Process.run('sysctl', ['-n', 'kern.boottime']);
      if (result.exitCode == 0) {
        final match = RegExp(r'sec\s*=\s*(\d+)')
            .firstMatch(result.stdout.toString());
        if (match != null) {
          return 'mac-${match.group(1)}';
        }
      }
    } catch (e, stackTrace) {
      _logger.fine('Unable to read macOS boot time.', e, stackTrace);
    }
    return null;
  }
  if (OpenValutPlatform.isWindows) {
    try {
      final result = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          '(Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToFileTimeUtc()',
        ],
      );
      if (result.exitCode == 0) {
        final value = result.stdout.toString().trim();
        if (value.isNotEmpty) {
          return 'win-$value';
        }
      }
    } catch (e, stackTrace) {
      _logger.fine('Unable to read Windows boot time.', e, stackTrace);
    }
    return null;
  }
  return null;
}

/// Asks the user to authenticate with their system (OS login) password.
///
/// On Linux this uses `pkexec`, which triggers the desktop's polkit agent to
/// show the native system authentication dialog and verifies the password via
/// PAM. Returns true only when the user authenticated successfully.
///
/// On platforms without a system gate it returns true so callers can proceed
/// with their own unlock mechanism.
Future<bool> authenticateWithSystemPassword() async {
  if (!OpenValutPlatform.isLinux) {
    return true;
  }
  try {
    final result = await Process.run('pkexec', ['/usr/bin/true']);
    if (result.exitCode == 0) {
      _logger.fine('System password authentication succeeded.');
      return true;
    }
    _logger.fine(
      'System password authentication failed (exit ${result.exitCode}).',
    );
    return false;
  } catch (e, stackTrace) {
    _logger.warning('Unable to run system authentication.', e, stackTrace);
    return false;
  }
}

/// Asks Windows Hello (PIN or biometric) to verify the current user.
///
/// Returns false when the check cannot run (Windows Hello not configured, the
/// channel is missing, or the user cancelled) so callers fall back to the
/// master password instead of silently releasing a remembered one.
Future<bool> verifyWindowsUserPresence() async {
  if (!OpenValutPlatform.isWindows) {
    return true;
  }
  _logger.finer('Windows Hello: requesting user verification.');
  try {
    final ok = await _userPresenceChannel.invokeMethod<bool>(
      'verifyUserPresence', // NON-NLS
      {
        'prompt': AppLocale.isChinese
            ? '验证身份以解锁 OpenValut'
            : 'Verify your identity to unlock OpenValut',
      },
    );
    if (ok != true) {
      _logger.warning(
        'Windows Hello did not confirm the user; '
        'the master password is required.',
      );
      return false;
    }
    _logger.fine('Windows Hello verified the user.');
    return true;
  } on MissingPluginException {
    _logger.warning(
      'Windows Hello channel is unavailable; the master password is required.',
    );
    return false;
  } on PlatformException catch (e, stackTrace) {
    // The runner reports every non-`Verified` outcome (cancel, no PIN
    // configured, no Hello device, retries exhausted, disabled by policy) as
    // this error, with the `UserConsentVerificationResult` name in the
    // message, so the log tells why the master password is being asked for.
    _logger.warning(
      'Windows Hello verification failed '
      '(${e.code}: ${e.message}); the master password is required.',
      e,
      stackTrace,
    );
    return false;
  } catch (e, stackTrace) {
    _logger.warning(
      'Windows Hello verification failed; the master password is required.',
      e,
      stackTrace,
    );
    return false;
  }
}

/// Performs the platform's user-presence check that guards the remembered
/// master password before a vault is reopened without it.
///
/// * Linux: the system (PAM) password prompt via `pkexec`.
/// * Windows: Windows Hello (PIN / fingerprint / face).
/// * Everything else: no gate (the platform has no equivalent prompt), which
///   matches the previous behaviour.
///
/// Passwords are *not* stored less securely because of this gate: the
/// remembered master password still lives in the platform keystore. The check
/// only makes sure the person at the keyboard is there before it is released,
/// exactly like the Linux `pkexec` prompt.
Future<bool> authenticateForRememberedUnlock() async {
  if (OpenValutPlatform.isLinux) {
    return authenticateWithSystemPassword();
  }
  if (OpenValutPlatform.isWindows) {
    return verifyWindowsUserPresence();
  }
  _logger.finer(
    'No user-presence check on this platform; releasing the remembered '
    'credentials.',
  );
  return true;
}
