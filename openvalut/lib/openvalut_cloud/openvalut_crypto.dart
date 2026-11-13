import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:argon2_ffi_base/argon2_ffi_base.dart';
import 'package:cryptography/cryptography.dart';
import 'package:openvalut/bloc/kdbx_argon2_ffi.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/macs/hmac.dart';

/// Thrown when an OpenValut Cloud blob cannot be decrypted/authenticated,
/// normally because the master password is wrong.
class openvalutDecryptionException implements Exception {
  openvalutDecryptionException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'openvalutDecryptionException: $message';
}

/// The user's X25519 identity used for sharing. The private key lives only
/// in memory (per app run); the public key is registered on the server so
/// others can wrap share keys to us.
class openvalutShareIdentity {
  openvalutShareIdentity({
    required this.privateKey,
    required this.publicKey,
  });

  final Uint8List privateKey;
  final Uint8List publicKey;
}

/// Serialized fields of a shared entry, encrypted with a random share key.
class openvalutSharedEntry {
  openvalutSharedEntry({required this.fields});

  final Map<String, String> fields;

  String? get label => fields['Title'];
  String? get username => fields['UserName'];
  String? get password => fields['Password'];
  String? get url => fields['URL'];
  String? get notes => fields['Notes'];

  Uint8List toBytes() => Uint8List.fromList(utf8.encode(json.encode(fields)));

  static openvalutSharedEntry fromBytes(Uint8List bytes) {
    final decoded = json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
    return openvalutSharedEntry(
      fields: decoded.map((key, value) => MapEntry(key, value as String)),
    );
  }
}

/// End-to-end encryption for OpenValut Cloud, matching the Go server
/// (`server/internal/crypto`). The server only ever stores ciphertext.
///
/// Parameters are shared with the Go implementation:
///  - KDF: Argon2id, 64 MiB, 3 iterations, 4 lanes, 32-byte output
///  - AEAD: AES-256-GCM, 12-byte random nonce, 128-bit tag
class openvalutCrypto {
  openvalutCrypto._();

  static const argonMemoryKib = 64 * 1024;
  static const argonIterations = 3;
  static const argonParallelism = 4;
  static const keyLength = 32;
  static const nonceLength = 12;
  // Argon2 type/version ids (2 = Argon2id, 0x13 = v1.3).
  static const _argon2Type = 2;
  static const _argon2Version = 0x13;

  /// Derives the 32-byte vault key from the master password and a per-vault
  /// salt. The password is never sent anywhere.
  static Future<Uint8List> deriveKey(String password, Uint8List salt) async {
    final args = Argon2Arguments(
      Uint8List.fromList(utf8.encode(password)),
      salt,
      argonMemoryKib,
      argonIterations,
      keyLength,
      argonParallelism,
      _argon2Type,
      _argon2Version,
    );
    return await argon2(arguments: args);
  }

  static Future<Uint8List> argon2({required Argon2Arguments arguments}) async {
    return await FlutterArgon2.singleton.argon2Async(arguments);
  }

  /// Encrypts [plaintext] with [key], returning (nonce, ciphertext).
  static (Uint8List, Uint8List) encrypt(Uint8List key, Uint8List plaintext) {
    final nonce = _randomBytes(nonceLength);
    return (nonce, _gcm(true, key, nonce, plaintext));
  }

  /// Decrypts and authenticates a (nonce, ciphertext) pair.
  static Uint8List decrypt(
    Uint8List key,
    Uint8List nonce,
    Uint8List ciphertext,
  ) {
    try {
      return _gcm(false, key, nonce, ciphertext);
    } on InvalidCipherTextException catch (e) {
      throw openvalutDecryptionException(
        'Unable to decrypt blob (wrong master password?)',
        e,
      );
    }
  }

  static Uint8List _gcm(
    bool encrypting,
    Uint8List key,
    Uint8List nonce,
    Uint8List data,
  ) {
    final gcm = GCMBlockCipher(AESEngine());
    gcm.init(
      encrypting,
      AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)),
    );
    final out = Uint8List(gcm.getOutputSize(data.length));
    var len = gcm.processBytes(data, 0, data.length, out, 0);
    len += gcm.doFinal(out, len);
    // getOutputSize rounds up to the block size; only the first [len] bytes
    // are meaningful (plaintext for decrypt, plaintext+tag for encrypt).
    return Uint8List.sublistView(out, 0, len);
  }

  static final Random _random = Random.secure();

  /// Cryptographically random bytes (e.g. share keys).
  static Uint8List secureRandomBytes(int length) => _randomBytes(length);

  static Uint8List _randomBytes(int length) {
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = _random.nextInt(256);
    }
    return out;
  }

  // ---------------------------------------------------------------------
  // Sharing: X25519 key wrapping, compatible with server/internal/crypto.
  // Layout of a wrapped share key: ephemeral public key (32) || nonce (12)
  // || AES-256-GCM ciphertext of the 32-byte share key.
  // ---------------------------------------------------------------------

  // Wire-protocol identifiers shared with the deployed server. Keep stable:
  // changing them breaks key derivation between an old server and a new app.
  static const _shareHkdfInfo = 'openvalut-share-v1'; // NON-NLS
  static const _envelopeHkdfInfo = 'openvalut-envelope-v1'; // NON-NLS
  static const _x25519PubLength = 32;

  /// Encrypts [plaintext] to [recipientPublicKey] with an ephemeral X25519
  /// key (ECDH + HKDF-SHA256 + AES-256-GCM), same layout as the Go server:
  /// ephemeral public key (32) || nonce (12) || ciphertext.
  static Future<Uint8List> envelopeEncrypt({
    required Uint8List recipientPublicKey,
    required Uint8List plaintext,
  }) async {
    final algorithm = X25519();
    final ephemeral = await algorithm.newKeyPair();
    final ephemeralPublic = await ephemeral.extractPublicKey();
    final secret = await algorithm.sharedSecretKey(
      keyPair: ephemeral,
      remotePublicKey: SimplePublicKey(
        recipientPublicKey,
        type: KeyPairType.x25519,
      ),
    );
    final key = _hkdfSha256(
      Uint8List.fromList(await secret.extractBytes()),
      _envelopeHkdfInfo,
    );
    final (nonce, ciphertext) = openvalutCrypto.encrypt(key, plaintext);
    final out = Uint8List(_x25519PubLength + nonce.length + ciphertext.length);
    out.setRange(0, _x25519PubLength, ephemeralPublic.bytes);
    out.setRange(_x25519PubLength, _x25519PubLength + nonce.length, nonce);
    out.setRange(
      _x25519PubLength + nonce.length,
      out.length,
      ciphertext,
    );
    return out;
  }

  /// Opens an envelope blob with the recipient's private key.
  static Future<Uint8List> envelopeDecrypt({
    required Uint8List privateKey,
    required Uint8List blob,
  }) async {
    final nonceLength = openvalutCrypto.nonceLength;
    if (blob.length < _x25519PubLength + nonceLength + 16 + 1) {
      throw ArgumentError('envelope is too short');
    }
    final ephemeralPublic = blob.sublist(0, _x25519PubLength);
    final nonce = blob.sublist(
      _x25519PubLength,
      _x25519PubLength + nonceLength,
    );
    final ciphertext = blob.sublist(_x25519PubLength + nonceLength);
    final algorithm = X25519();
    final keyPair = await shareKeyPairFromPrivate(privateKey);
    final secret = await algorithm.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: SimplePublicKey(
        ephemeralPublic,
        type: KeyPairType.x25519,
      ),
    );
    final key = _hkdfSha256(
      Uint8List.fromList(await secret.extractBytes()),
      _envelopeHkdfInfo,
    );
    return openvalutCrypto.decrypt(key, nonce, ciphertext);
  }

  /// Signs a request: hex(HMAC-SHA256(userId, method\npath\ntimestamp\nnonce\n
  /// hex(sha256(body)))). The server verifies it with the user's UUID, so a
  /// captured request cannot be replayed outside the timestamp window or
  /// tampered with. The nonce must be unique per request to prevent replay.
  static String signRequest({
    required String userId,
    required String method,
    required String path,
    required String timestamp,
    required String nonce,
    required List<int> body,
  }) {
    final bodyHash = SHA256Digest().process(Uint8List.fromList(body));
    final msg =
        '$method\n$path\n$timestamp\n$nonce\n${_hexEncode(bodyHash)}'; // NON-NLS
    final mac = HMac(SHA256Digest(), 64);
    mac.init(KeyParameter(Uint8List.fromList(utf8.encode(userId))));
    final msgBytes = Uint8List.fromList(utf8.encode(msg));
    mac.update(msgBytes, 0, msgBytes.length);
    final out = Uint8List(32);
    mac.doFinal(out, 0);
    return _hexEncode(out);
  }

  static String _hexEncode(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Generates a cryptographically random 16-byte nonce as a hex string.
  static String generateNonce() =>
      _hexEncode(secureRandomBytes(16));

  /// Generates a fresh X25519 identity (private key kept in memory).
  static Future<openvalutShareIdentity> generateShareIdentity() async {
    final algorithm = X25519();
    final keyPair = await algorithm.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKey = await keyPair.extractPrivateKeyBytes();
    return openvalutShareIdentity(
      privateKey: Uint8List.fromList(privateKey),
      publicKey: Uint8List.fromList(publicKey.bytes),
    );
  }

  /// Rebuilds the key pair from a stored raw private key, so a session can
  /// unwrap incoming shares without regenerating its identity.
  static Future<SimpleKeyPair> shareKeyPairFromPrivate(
    Uint8List privateKey,
  ) async {
    if (privateKey.length != 32) {
      throw ArgumentError('X25519 private key must be 32 bytes');
    }
    return X25519().newKeyPairFromSeed(privateKey);
  }

  /// Wraps [shareKey] to [recipientPublicKey] (RFC 7748 X25519 + HKDF-SHA256
  /// + AES-256-GCM), producing the same layout as the Go server.
  static Future<Uint8List> wrapShareKey({
    required Uint8List recipientPublicKey,
    required Uint8List shareKey,
  }) async {
    final algorithm = X25519();
    final ephemeral = await algorithm.newKeyPair();
    final ephemeralPublic = await ephemeral.extractPublicKey();
    final secret = await algorithm.sharedSecretKey(
      keyPair: ephemeral,
      remotePublicKey: SimplePublicKey(
        recipientPublicKey,
        type: KeyPairType.x25519,
      ),
    );
    final key = _hkdfSha256(
      Uint8List.fromList(await secret.extractBytes()),
      _shareHkdfInfo,
    );
    final (nonce, ciphertext) = openvalutCrypto.encrypt(key, shareKey);
    final out = Uint8List(_x25519PubLength + nonce.length + ciphertext.length);
    out.setRange(0, _x25519PubLength, ephemeralPublic.bytes);
    out.setRange(_x25519PubLength, _x25519PubLength + nonce.length, nonce);
    out.setRange(
      _x25519PubLength + nonce.length,
      out.length,
      ciphertext,
    );
    return out;
  }

  /// Unwraps a wrapped share key with the recipient's private key.
  static Future<Uint8List> unwrapShareKey({
    required Uint8List privateKey,
    required Uint8List wrapped,
  }) async {
    final nonceLength = openvalutCrypto.nonceLength;
    if (wrapped.length < _x25519PubLength + nonceLength + 16 + 1) {
      throw ArgumentError('wrapped share key is too short');
    }
    final ephemeralPublic = wrapped.sublist(0, _x25519PubLength);
    final nonce = wrapped.sublist(
      _x25519PubLength,
      _x25519PubLength + nonceLength,
    );
    final ciphertext = wrapped.sublist(_x25519PubLength + nonceLength);
    final algorithm = X25519();
    final keyPair = await shareKeyPairFromPrivate(privateKey);
    final secret = await algorithm.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: SimplePublicKey(
        ephemeralPublic,
        type: KeyPairType.x25519,
      ),
    );
    final key = _hkdfSha256(
      Uint8List.fromList(await secret.extractBytes()),
      _shareHkdfInfo,
    );
    return openvalutCrypto.decrypt(key, nonce, ciphertext);
  }

  /// RFC 5869 HKDF-SHA256 matching Go's crypto/hkdf with a nil salt: the
  /// salt is HashLen (32) zero bytes.
  static Uint8List _hkdfSha256(Uint8List secret, String info) {
    final mac = HMac(SHA256Digest(), 64);

    // Extract: PRK = HMAC-SHA256(salt = 32 zero bytes, secret).
    mac.init(KeyParameter(Uint8List(32)));
    mac.update(secret, 0, secret.length);
    final prk = Uint8List(32);
    mac.doFinal(prk, 0);

    // Expand (single 32-byte block): OKM = HMAC-SHA256(PRK, info || 0x01).
    mac.reset();
    mac.init(KeyParameter(prk));
    final infoBytes = Uint8List.fromList(utf8.encode(info));
    mac.update(infoBytes, 0, infoBytes.length);
    mac.update(Uint8List.fromList([1]), 0, 1);
    final okm = Uint8List(32);
    mac.doFinal(okm, 0);
    return okm;
  }
}
