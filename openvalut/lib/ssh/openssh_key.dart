import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/digests/sha512.dart';
import 'package:pointycastle/signers/rsa_signer.dart';

import 'ed25519.dart';

/// Parsed SSH private key material (OpenSSH "openssh-key-v1" format).
///
/// The agent keeps this in memory only while the vault is unlocked and signs
/// challenges itself; the private key never has to touch the filesystem.
class ParsedSshPrivateKey {
  ParsedSshPrivateKey.ed25519(this.seed, this.publicKey)
    : keyType = SshKeyType.ed25519,
      rsa = null;

  ParsedSshPrivateKey.rsa(
    this.rsa,
    this.publicKey,
  ) : keyType = SshKeyType.rsa,
      seed = null;

  final SshKeyType keyType;

  /// 32-byte ed25519 seed, or null for RSA keys.
  final Uint8List? seed;

  /// pointycastle RSA private key, or null for ed25519 keys.
  final RSAPrivateKey? rsa;

  /// The raw SSH public key blob (algorithm string + key material).
  final Uint8List publicKey;

  Uint8List sign(Uint8List data, {SshSignatureAlgorithm? rsaAlgorithm}) {
    switch (keyType) {
      case SshKeyType.ed25519:
        return Ed25519().sign(seed!, data);
      case SshKeyType.rsa:
        final identifier = rsaAlgorithm == SshSignatureAlgorithm.rsaSha2_512
            ? '0609608648016503040203'
            : '0609608648016503040201';
        final digest = rsaAlgorithm == SshSignatureAlgorithm.rsaSha2_512
            ? SHA512Digest()
            : SHA256Digest();
        final signer = RSASigner(digest, identifier);
        signer.init(true, PrivateKeyParameter<RSAPrivateKey>(rsa!));
        return signer.generateSignature(data).bytes;
    }
  }
}

enum SshKeyType { ed25519, rsa }

enum SshSignatureAlgorithm { rsaSha2_256, rsaSha2_512 }

/// Thrown when a vault entry's private key cannot be parsed.
class SshKeyParseException implements Exception {
  SshKeyParseException(this.message);

  final String message;

  @override
  String toString() => 'SshKeyParseException: $message';
}

/// Parses an OpenSSH private key (the `openssh-key-v1` blob inside the
/// `BEGIN OPENSSH PRIVATE KEY` armor). Only unencrypted ("none" cipher)
/// keys are supported — the vault itself is the encryption layer.
ParsedSshPrivateKey parseOpensshPrivateKey(String pem) {
  final body = _decodeArmored(pem);
  final reader = _Reader(body);

  final magic = reader.readBytes(15);
  // "openssh-key-v1" followed by a NUL terminator.
  if (utf8.decode(magic).replaceAll('\x00', '') != 'openssh-key-v1') {
    throw SshKeyParseException('not an OpenSSH private key');
  }
  final cipher = utf8.decode(reader.readString());
  if (cipher != 'none') {
    throw SshKeyParseException(
      'encrypted OpenSSH keys are not supported (cipher: $cipher)',
    );
  }
  reader.readString(); // kdfname
  reader.readString(); // kdfoptions
  final keyCount = reader.readUint32();
  if (keyCount != 1) {
    throw SshKeyParseException('expected exactly one key, got $keyCount');
  }
  final publicKey = reader.readString();
  final privateSection = reader.readString();
  final priv = _Reader(privateSection);
  final check1 = priv.readUint32();
  final check2 = priv.readUint32();
  if (check1 != check2) {
    throw SshKeyParseException('key check bytes mismatch');
  }

  final keyAlgorithm = _algorithmOf(publicKey);
  switch (keyAlgorithm) {
    case SshKeyType.ed25519:
      final privateAlgorithm = utf8.decode(priv.readString());
      if (privateAlgorithm != 'ssh-ed25519') {
        throw SshKeyParseException(
          'unexpected private algorithm: $privateAlgorithm',
        );
      }
      priv.readString(); // public key again (32 bytes)
      final private = priv.readString();
      if (private.length != 64) {
        throw SshKeyParseException(
          'unexpected ed25519 private key length ${private.length}',
        );
      }
      final seed = Uint8List.fromList(private.sublist(0, 32));
      return ParsedSshPrivateKey.ed25519(seed, publicKey);
    case SshKeyType.rsa:
      final privateAlgorithm = utf8.decode(priv.readString());
      if (privateAlgorithm != 'ssh-rsa') {
        throw SshKeyParseException(
          'unexpected private algorithm: $privateAlgorithm',
        );
      }
      final n = priv.readMpint();
      priv.readMpint(); // e
      final d = priv.readMpint();
      priv.readMpint(); // iqmp
      final p = priv.readMpint();
      final q = priv.readMpint();
      return ParsedSshPrivateKey.rsa(
        RSAPrivateKey(n, d, p, q),
        publicKey,
      );
  }
}

SshKeyType _algorithmOf(Uint8List publicKey) {
  final length = _readStringLength(publicKey, 0);
  final algorithm = utf8.decode(publicKey.sublist(4, 4 + length));
  switch (algorithm) {
    case 'ssh-ed25519':
      return SshKeyType.ed25519;
    case 'ssh-rsa':
      return SshKeyType.rsa;
    default:
      throw SshKeyParseException('unsupported key algorithm: $algorithm');
  }
}

/// Wraps a raw signature in the SSH signature blob format
/// (`string algorithm || string signature`).
Uint8List sshSignatureBlob(
  ParsedSshPrivateKey key,
  Uint8List signature, {
  SshSignatureAlgorithm? rsaAlgorithm,
}) {
  final algorithm = switch (key.keyType) {
    SshKeyType.ed25519 => 'ssh-ed25519',
    SshKeyType.rsa => rsaAlgorithm == SshSignatureAlgorithm.rsaSha2_512
        ? 'rsa-sha2-512'
        : 'rsa-sha2-256',
  };
  return Uint8List.fromList([
    ..._encodeString(utf8.encode(algorithm)),
    ..._encodeString(signature),
  ]);
}

Uint8List _decodeArmored(String pem) {
  final lines = pem
      .split('\n')
      .map((line) => line.trim())
      .where(
        (line) =>
            line.isNotEmpty &&
            !line.startsWith('-----BEGIN') &&
            !line.startsWith('-----END'),
      )
      .join();
  try {
    return base64.decode(lines);
  } on FormatException catch (_) {
    throw SshKeyParseException('invalid base64 in private key');
  }
}

int _readStringLength(Uint8List bytes, int offset) {
  if (offset + 4 > bytes.length) {
    throw SshKeyParseException('truncated key blob');
  }
  final byteData = ByteData.sublistView(bytes);
  return byteData.getUint32(offset);
}

Uint8List _encodeString(List<int> bytes) {
  final out = ByteData(4 + bytes.length);
  out.setUint32(0, bytes.length);
  for (var i = 0; i < bytes.length; i++) {
    out.setUint8(4 + i, bytes[i]);
  }
  return out.buffer.asUint8List();
}

class _Reader {
  _Reader(this.bytes) : _pos = 0;

  final Uint8List bytes;
  int _pos;

  Uint8List readBytes(int length) {
    if (_pos + length > bytes.length) {
      throw SshKeyParseException('truncated key data');
    }
    final out = Uint8List.fromList(bytes.sublist(_pos, _pos + length));
    _pos += length;
    return out;
  }

  int readUint32() {
    final value = ByteData.sublistView(bytes).getUint32(_pos);
    _pos += 4;
    return value;
  }

  Uint8List readString() {
    final length = readUint32();
    return readBytes(length);
  }

  BigInt readMpint() {
    final length = readUint32();
    final raw = readBytes(length);
    if (raw.isEmpty) {
      return BigInt.zero;
    }
    var value = BigInt.zero;
    for (final byte in raw) {
      value = (value << 8) | BigInt.from(byte);
    }
    // OpenSSH mpint is two's complement big-endian.
    if (raw[0] & 0x80 != 0) {
      value -= BigInt.one << (8 * raw.length);
    }
    return value;
  }
}
