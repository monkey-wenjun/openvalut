import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Hard-coded AES-256 key derived from a fixed passphrase via PBKDF2.
/// This is intentionally not dynamic: the APK contains the key, so the
/// password file only protects against casual inspection, not a determined
/// reverse-engineer.
final _key = base64.decode('EFHwdY+P8HkzxYNVt42e5R5ZnTojQ7mpKRFUln802AY=');

const _tagBitLength = 128;
const _nonceByteLength = 12;

Uint8List _deriveKey(List<int> password, List<int> salt) {
  final params = Pbkdf2Parameters(Uint8List.fromList(salt), 100000, 32);
  final kdf = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
  kdf.init(params);
  return kdf.process(Uint8List.fromList(password));
}

/// Sanity-check that the compiled key matches a fresh derivation from the
/// passphrase. This catches accidental edits to the hard-coded key.
bool _verifyKey() {
  const password = 'OpenValutSecureUnlock2024!';
  const salt = 'openvalut-auto-unlock-salt';
  final derived = _deriveKey(utf8.encode(password), utf8.encode(salt));
  return derived.length == _key.length &&
      derived.indexed.every((e) => e.$2 == _key[e.$1]);
}

/// Encrypts [plaintext] with AES-256-GCM and returns base64(nonce||ciphertext||tag).
String encryptAutoUnlockPassword(String plaintext) {
  final nonce = Uint8List.fromList(
    List.generate(_nonceByteLength, (_) => Random.secure().nextInt(256)),
  );
  final cipher = GCMBlockCipher(AESEngine())
    ..init(
      true,
      AEADParameters(
        KeyParameter(_key),
        _tagBitLength,
        nonce,
        Uint8List(0),
      ),
    );
  final ciphertext = cipher.process(Uint8List.fromList(utf8.encode(plaintext)));
  final combined = Uint8List(nonce.length + ciphertext.length)
    ..setRange(0, nonce.length, nonce)
    ..setRange(nonce.length, nonce.length + ciphertext.length, ciphertext);
  return base64.encode(combined);
}

/// Decrypts a base64(nonce||ciphertext||tag) payload created by
/// [encryptAutoUnlockPassword]. Returns null if decoding or decryption fails.
String? decryptAutoUnlockPassword(String encoded) {
  if (!_verifyKey()) {
    throw StateError('Hard-coded auto-unlock key does not match derivation.');
  }
  try {
    final combined = base64.decode(encoded);
    if (combined.length < _nonceByteLength) {
      return null;
    }
    final nonce = Uint8List.view(combined.buffer, 0, _nonceByteLength);
    final ciphertext = Uint8List.view(
      combined.buffer,
      _nonceByteLength,
      combined.length - _nonceByteLength,
    );
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(
          KeyParameter(_key),
          _tagBitLength,
          nonce,
          Uint8List(0),
        ),
      );
    final plaintext = cipher.process(ciphertext);
    return utf8.decode(plaintext);
  } catch (e, stackTrace) {
    // ignore: avoid_print
    print('Failed to decrypt auto-unlock password: $e\n$stackTrace');
    return null;
  }
}
