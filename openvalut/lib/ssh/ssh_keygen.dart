import 'dart:io';

import 'package:logging/logging.dart';

final _logger = Logger('ssh_keygen');

/// A freshly generated SSH key pair.
class SshGeneratedKey {
  SshGeneratedKey({required this.privateKey, required this.publicKey});

  /// OpenSSH private key text (unencrypted; the vault is the encryption).
  final String privateKey;

  /// One-line public key (`ssh-ed25519 AAAA… comment`).
  final String publicKey;
}

/// Generates an ed25519 key pair using the system `ssh-keygen`.
///
/// The authoritative OpenSSH implementation is used instead of a Dart
/// re-implementation, because these are real credentials. The key is written
/// to a temporary directory (Linux: `XDG_RUNTIME_DIR`/`/dev/shm` when
/// available, so it stays on tmpfs), read back immediately and the files are
/// removed — only the vault copy survives.
Future<SshGeneratedKey> generateSshKeyPair({
  required String comment,
}) async {
  final directory = await Directory.systemTemp.createTemp('openvalut-ssh-');
  final keyPath = '${directory.path}/id_ed25519';
  try {
    final result = await Process.run('ssh-keygen', [
      '-t',
      'ed25519',
      '-N',
      '',
      '-C',
      comment,
      '-f',
      keyPath,
    ]);
    if (result.exitCode != 0) {
      throw StateError(
        'ssh-keygen failed (${result.exitCode}): ${result.stderr}',
      );
    }
    final privateKey = File(keyPath).readAsStringSync();
    final publicKey = File('$keyPath.pub').readAsStringSync().trim();
    return SshGeneratedKey(
      privateKey: privateKey,
      publicKey: publicKey,
    );
  } finally {
    try {
      await directory.delete(recursive: true);
    } catch (e, stackTrace) {
      _logger.fine('Unable to remove temporary SSH key files.', e, stackTrace);
    }
  }
}
