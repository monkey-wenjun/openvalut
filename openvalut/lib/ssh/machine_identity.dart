import 'dart:io';

/// Identity of the machine the app is currently running on.
///
/// The tag used to label imported SSH keys is derived from a hardware/OS
/// unique id (`/etc/machine-id` on Linux, IOPlatformUUID on macOS, the system
/// UUID on Windows) — hostnames are not unique and two machines may share the
/// same one. The *displayed* name stays the hostname.
class MachineIdentity {
  MachineIdentity._();

  static String? _cachedMachineId;

  /// Unique per machine/OS-install (machine-id or hardware UUID). Falls back
  /// to the hostname when the platform exposes nothing better.
  static String get machineId {
    if (_cachedMachineId != null) {
      return _cachedMachineId!;
    }
    _cachedMachineId = _readMachineId();
    return _cachedMachineId!;
  }

  static String _user() =>
      Platform.environment['USER'] ??
      Platform.environment['USERNAME'] ??
      '';

  /// Unique tag like `user@machineid` — stored in the `ssh-machine` field of
  /// imported SSH key entries.
  static String get tag {
    final user =
        Platform.environment['USER'] ??
        Platform.environment['USERNAME'] ??
        '';
    return user.isEmpty ? machineId : '$user@$machineId';
  }

  /// The old hostname-based tag (`user@hostname`) used by imports before the
  /// hardware id existed. Kept so existing entries still work on their
  /// original machine.
  static String get legacyTag {
    final user = _user();
    final host = Platform.localHostname.toLowerCase();
    return user.isEmpty ? host : '$user@$host';
  }

  /// Just the hostname, for display (`id_ed25519 (my-desktop)`).
  static String get hostname => Platform.localHostname;

  static String _readMachineId() {
    if (Platform.isLinux) {
      for (final path in ['/etc/machine-id', '/var/lib/dbus/machine-id']) {
        try {
          final id = File(path).readAsStringSync().trim();
          if (id.isNotEmpty) {
            return id;
          }
        } catch (_) {
          // Try the next location.
        }
      }
    } else if (Platform.isMacOS) {
      try {
        final result = Process.runSync('ioreg', [
          '-rd1',
          '-c',
          'IOPlatformExpertDevice',
        ]);
        final match = RegExp(
          r'IOPlatformUUID.*?"([^"]+)"',
        ).firstMatch(result.stdout.toString());
        if (match != null) {
          return match.group(1)!;
        }
      } catch (_) {
        // Fall through.
      }
    } else if (Platform.isWindows) {
      try {
        final result = Process.runSync('powershell', [
          '-NoProfile',
          '-Command',
          '(Get-CimInstance Win32_ComputerSystemProduct).UUID',
        ]);
        final value = result.stdout.toString().trim();
        if (value.isNotEmpty) {
          return value;
        }
      } catch (_) {
        // Fall through.
      }
    }
    // Last resort: hostname (not unique, but still distinguishes in the
    // common case).
    return Platform.localHostname.toLowerCase();
  }
}
