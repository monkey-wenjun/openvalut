import 'package:kdbx/kdbx.dart';
import 'package:string_literal_finder_annotations/string_literal_finder_annotations.dart';

/// Reserved KDBX keys for SSH server profiles stored in vault entries.
///
/// A server entry looks like a normal entry in any group:
///   Title        -> host name / ssh alias (e.g. "root-server")
///   UserName     -> ssh login user
///   Password     -> ssh password (keyboard-interactive fallback)
///   OTP          -> TOTP secret for two-factor SSH
///   ssh-host     -> optional explicit host name when Title is only an alias
///   ssh-port     -> TCP port (default 22 when absent)
///   ssh-private-key / ssh-public-key -> key offered through the SSH agent
@NonNls
class SshProfileKeys {
  static const host = 'ssh-host'; // NON-NLS
  static const port = 'ssh-port'; // NON-NLS
  static const privateKey = 'ssh-private-key'; // NON-NLS
  static const publicKey = 'ssh-public-key'; // NON-NLS
  static const machine = 'ssh-machine'; // NON-NLS
}

/// Parsed SSH server profile of one vault entry, or null when the entry has
/// no ssh metadata (not a server entry).
class SshServerProfile {
  SshServerProfile({
    required this.host,
    required this.port,
    required this.user,
  });

  final String host;
  final int port;
  final String? user;

  /// Whether [entry] looks like an SSH server profile (explicit host or
  /// port metadata, or a dedicated key entry).
  static bool isServerEntry(KdbxEntry entry) {
    final host = entry.getString(KdbxKey(SshProfileKeys.host))?.getText();
    final port = entry.getString(KdbxKey(SshProfileKeys.port))?.getText();
    return (host != null && host.trim().isNotEmpty) ||
        (port != null && port.trim().isNotEmpty);
  }

  /// Parses [entry]; returns null for ordinary/local key entries.
  static SshServerProfile? fromEntry(KdbxEntry entry) {
    final explicitHost =
        entry.getString(KdbxKey(SshProfileKeys.host))?.getText()?.trim() ?? '';
    final portText =
        entry.getString(KdbxKey(SshProfileKeys.port))?.getText()?.trim() ?? '';
    final host = explicitHost.isNotEmpty
        ? explicitHost
        : (entry.label ?? '').trim();
    if (host.isEmpty && portText.isEmpty) {
      return null;
    }
    return SshServerProfile(
      host: host,
      port: int.tryParse(portText) ?? 22,
      user: entry.getString(KdbxKeyCommon.USER_NAME)?.getText()?.trim(),
    );
  }
}
