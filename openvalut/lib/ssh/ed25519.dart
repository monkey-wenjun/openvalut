import 'dart:typed_data';

import 'package:pointycastle/digests/sha512.dart';

/// Pure-Dart Ed25519 (RFC 8032) key pair derivation and signing.
///
/// The SSH agent needs to sign challenges with private keys that live only in
/// the unlocked vault, so the signing must happen in-process. pointycastle
/// does not ship Ed25519, hence this compact implementation. It is verified
/// against the RFC 8032 test vectors and against OpenSSL in the test suite.
///
/// The implementation is deliberately simple (BigInt field arithmetic with
/// projective coordinates); signing an SSH handshake takes a few milliseconds,
/// which is invisible to the user.
class Ed25519 {
  static final _p = BigInt.parse(
    '57896044618658097711785492504343953926634992332820282019728792003956564819949',
  );
  static final _l = BigInt.parse(
    '7237005577332262213973186563042994240857116359379907606001950938285454250989',
  );

  // d = -121665 / 121666 (mod p)
  static final _d = (_p - BigInt.from(121665)) *
      BigInt.from(121666).modInverse(_p) %
      _p;

  // Base point: y = 4/5 (mod p), x is the even square root.
  static final _bY = BigInt.from(4) * BigInt.from(5).modInverse(_p) % _p;
  static final _bX = _recoverX(_bY);

  static final _sha512 = SHA512Digest();

  /// Derives the 32-byte public key for a 32-byte private [seed].
  Uint8List publicKeyFromSeed(Uint8List seed) {
    final h = _sha512.process(seed);
    final a = _decodeLittleEndian(_clamp(h.sublist(0, 32)));
    final point = _scalarMult(_bX, _bY, a);
    return _encodePoint(point);
  }

  /// Signs [message] with a 32-byte private [seed].
  Uint8List sign(Uint8List seed, Uint8List message) {
    final h = _sha512.process(seed);
    final a = _decodeLittleEndian(_clamp(h.sublist(0, 32)));
    final prefix = h.sublist(32);
    final publicKey = publicKeyFromSeed(seed);

    final r = _reduceModL(
      _sha512.process(Uint8List.fromList([...prefix, ...message])),
    );
    final rPoint = _scalarMult(_bX, _bY, r);
    final rEncoded = _encodePoint(rPoint);

    final hram = _reduceModL(
      _sha512.process(
        Uint8List.fromList([...rEncoded, ...publicKey, ...message]),
      ),
    );
    final s = (r + hram * a) % _l;

    return Uint8List.fromList([...rEncoded, ..._littleEndian32(s)]);
  }

  static Uint8List _clamp(Uint8List bytes) {
    final b = Uint8List.fromList(bytes);
    b[0] &= 248;
    b[31] &= 127;
    b[31] |= 64;
    return b;
  }

  static BigInt _decodeLittleEndian(Uint8List bytes) {
    var n = BigInt.zero;
    for (var i = 0; i < bytes.length; i++) {
      n |= BigInt.from(bytes[i]) << (8 * i);
    }
    return n;
  }

  static Uint8List _littleEndian32(BigInt n) {
    final out = Uint8List(32);
    var v = n;
    for (var i = 0; i < 32; i++) {
      // BigInt.toInt() clamps values that do not fit in 64 bits, so mask each
      // byte down to a small value before converting.
      out[i] = (v & BigInt.from(0xff)).toInt();
      v = v >> 8;
    }
    return out;
  }

  static BigInt _reduceModL(Uint8List bytes) => _decodeLittleEndian(bytes) % _l;

  static BigInt _recoverX(BigInt y) {
    // x^2 = (y^2 - 1) / (d y^2 + 1)
    final y2 = y * y % _p;
    final numerator = (y2 - BigInt.one) % _p;
    final denominator = (_d * y2 + BigInt.one) % _p;
    final n = numerator * denominator.modInverse(_p) % _p;
    var x = n;
    // x = x^((p+3)/8); if x^2 != numerator, x *= sqrt(-1)
    final exp = (_p + BigInt.from(3)) ~/ BigInt.from(8);
    x = _modPow(x, exp);
    if (x * x % _p != n) {
      x = x * _sqrtM1 % _p;
    }
    // RFC 8032: the base point and public keys use the even x root.
    if (!x.isEven) {
      x = _p - x;
    }
    return x;
  }

  static final _sqrtM1 = _modPow(
    BigInt.from(2),
    (_p - BigInt.one) ~/ BigInt.from(4),
  );

  static BigInt _modPow(BigInt base, BigInt exp) {
    var result = BigInt.one;
    var b = base % _p;
    var e = exp;
    while (e > BigInt.zero) {
      if (e.isOdd) {
        result = result * b % _p;
      }
      b = b * b % _p;
      e = e >> 1;
    }
    return result;
  }

  /// Projective point (X, Y, Z, T = X*Y/Z).
  static List<BigInt> _point(BigInt x, BigInt y) =>
      [x, y, BigInt.one, x * y % _p];

  static List<BigInt> _add(List<BigInt> p1, List<BigInt> p2) {
    final a = (p1[1] - p1[0]) * (p2[1] - p2[0]) % _p;
    final b = (p1[1] + p1[0]) * (p2[1] + p2[0]) % _p;
    final c = BigInt.two * _d * p1[3] % _p * p2[3] % _p;
    final dd = BigInt.two * p1[2] % _p * p2[2] % _p;
    final e = (b - a) % _p;
    final f = (dd - c) % _p;
    final g = (dd + c) % _p;
    final h = (b + a) % _p;
    final x3 = e * f % _p;
    final y3 = g * h % _p;
    final t3 = e * h % _p;
    final z3 = f * g % _p;
    return [x3, y3, z3, t3];
  }

  static List<BigInt> _double(List<BigInt> p) {
    final a = p[0] * p[0] % _p;
    final b = p[1] * p[1] % _p;
    final c = BigInt.two * p[2] % _p * p[2] % _p;
    final dd = (_p - a) % _p;
    final e = ((p[0] + p[1]) * (p[0] + p[1]) - a - b) % _p;
    final g = (dd + b) % _p;
    final f = (g - c) % _p;
    final h = (dd - b) % _p;
    final x3 = e * f % _p;
    final y3 = g * h % _p;
    final t3 = e * h % _p;
    final z3 = f * g % _p;
    return [x3, y3, z3, t3];
  }

  static List<BigInt> _scalarMult(BigInt x, BigInt y, BigInt scalar) {
    var result = _point(BigInt.zero, BigInt.one);
    var addend = _point(x, y);
    var s = scalar;
    while (s > BigInt.zero) {
      if (s.isOdd) {
        result = _add(result, addend);
      }
      addend = _double(addend);
      s = s >> 1;
    }
    return result;
  }

  static Uint8List _encodePoint(List<BigInt> point) {
    final zInv = point[2].modInverse(_p);
    final x = point[0] * zInv % _p;
    final y = point[1] * zInv % _p;
    final out = _littleEndian32(y);
    if (x.isOdd) {
      out[31] |= 0x80;
    }
    return out;
  }
}
