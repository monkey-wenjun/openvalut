import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:openvalut/ssh/machine_identity.dart';
import 'package:path/path.dart' as p;
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/digests/sha256.dart';

/// Helpers for writing the encrypted TOTP secret used by the experimental
/// `pam_openvalut` PAM module on Linux.
///
/// The file is stored at `~/.openvalut/totp/<machine-id>.enc` with 0600
/// permissions. It is encrypted with AES-256-GCM; the key is derived from
/// `/etc/machine-id` (or equivalent) and a fixed salt. This binds the TOTP
/// secret to the current machine so the PAM module can verify codes at login
/// time without needing the vault to be unlocked.
class PamTotpFile {
  PamTotpFile._();

  static const _salt = 'openvalut-pam-totp-v1';
  static const _totpDir = '.openvalut/totp';

  static String? get _machineId => MachineIdentity.machineId;

  static Future<String?> _homeDir() async {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'];
    return home;
  }

  static Future<String?> path() async {
    final mid = _machineId;
    final home = await _homeDir();
    if (mid == null || home == null || home.isEmpty) {
      return null;
    }
    return p.join(home, _totpDir, '$mid.enc');
  }

  static Uint8List _deriveKey(String machineId) {
    final digest = SHA256Digest();
    digest.update(Uint8List.fromList(machineId.codeUnits), 0, machineId.length);
    digest.update(Uint8List.fromList(_salt.codeUnits), 0, _salt.length);
    final out = Uint8List(32);
    digest.doFinal(out, 0);
    return out;
  }

  static Uint8List _encrypt(Uint8List plaintext, Uint8List key, Uint8List nonce) {
    final aes = AESEngine();
    final gcm = GCMBlockCipher(aes);
    final params = AEADParameters(
      KeyParameter(key),
      128,
      nonce,
      Uint8List(0),
    );
    gcm.init(true, params);
    final out = Uint8List(gcm.getOutputSize(plaintext.length));
    final len = gcm.processBytes(plaintext, 0, plaintext.length, out, 0);
    gcm.doFinal(out, len);
    return out;
  }

  static void _fillRandom(Uint8List buffer) {
    final random = Random.secure();
    for (var i = 0; i < buffer.length; i++) {
      buffer[i] = random.nextInt(256);
    }
  }

  /// Encrypts [totpSecret] (raw base32 secret) and writes it to the PAM TOTP
  /// file. Returns the written path or null if the machine id / home dir are
  /// unavailable.
  static Future<String?> write(String totpSecret) async {
    final mid = _machineId;
    final home = await _homeDir();
    if (mid == null || home == null || home.isEmpty) {
      return null;
    }
    final dir = Directory(p.join(home, _totpDir));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      await _chmod700(dir.path);
    }
    final key = _deriveKey(mid);
    final nonce = Uint8List(12);
    _fillRandom(nonce);
    final ciphertext = _encrypt(
      Uint8List.fromList(totpSecret.codeUnits),
      key,
      nonce,
    );
    final file = File(p.join(home, _totpDir, '$mid.enc'));
    final sink = file.openSync(mode: FileMode.writeOnly);
    try {
      sink.writeFromSync(nonce);
      sink.writeFromSync(ciphertext);
    } finally {
      sink.closeSync();
    }
    await _chmod600(file.path);
    return file.path;
  }

  static Future<void> _chmod700(String path) async {
    try {
      await Process.run('chmod', ['700', path]);
    } catch (_) {}
  }

  static Future<void> _chmod600(String path) async {
    try {
      await Process.run('chmod', ['600', path]);
    } catch (_) {}
  }
}
