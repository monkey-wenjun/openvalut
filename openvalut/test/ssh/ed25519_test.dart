import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:openvalut/ssh/ed25519.dart';

Uint8List _hex(String s) => Uint8List.fromList(
  List.generate(
    s.length ~/ 2,
    (i) => int.parse(s.substring(i * 2, i * 2 + 2), radix: 16),
  ),
);

String _toHex(List<int> bytes) =>
    [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();

void main() {
  final ed = Ed25519();

  test('RFC 8032 test vector 1', () {
    final seed = _hex(
      '9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60',
    );
    expect(
      _toHex(ed.publicKeyFromSeed(seed)),
      'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
    );
    expect(
      _toHex(ed.sign(seed, Uint8List(0))),
      'e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e06522490155'
      '5fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b',
    );
  });

  test('RFC 8032 test vector 2', () {
    final seed = _hex(
      '4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb',
    );
    expect(
      _toHex(ed.publicKeyFromSeed(seed)),
      '3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c',
    );
    expect(
      _toHex(ed.sign(seed, _hex('72'))),
      '92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69d'
      'a085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00',
    );
  });

  test('signature verifies with OpenSSL (independent implementation)', () async {
    final openssl = await Process.run('which', ['openssl']);
    if (openssl.exitCode != 0) {
      markTestSkipped('openssl not available');
      return;
    }
    final seed = _hex(
      '9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60',
    );
    final publicKey = ed.publicKeyFromSeed(seed);
    final message = 'one-pass ssh agent test'.codeUnits;
    final signature = ed.sign(seed, Uint8List.fromList(message));

    final dir = await Directory.systemTemp.createTemp('ed25519_test_');
    try {
      // Build a DER SPKI (ed25519 OID 1.3.101.112) for openssl.
      final oid = <int>[0x06, 0x03, 0x2b, 0x65, 0x70];
      final inner = <int>[0x30, oid.length, ...oid];
      final bit = <int>[0x03, publicKey.length + 1, 0x00, ...publicKey];
      final spki = <int>[0x30, inner.length + bit.length, ...inner, ...bit];
      final pubFile = File('${dir.path}/pub.der')..writeAsBytesSync(spki);
      final dataFile = File('${dir.path}/data.bin')
        ..writeAsBytesSync(Uint8List.fromList(message));
      final sigFile = File('${dir.path}/sig.bin')
        ..writeAsBytesSync(signature);

      final verify = await Process.run('openssl', [
        'pkeyutl',
        '-verify',
        '-pubin',
        '-inkey',
        pubFile.path,
        '-keyform',
        'DER',
        '-rawin',
        '-in',
        dataFile.path,
        '-sigfile',
        sigFile.path,
      ]);
      expect(verify.exitCode, 0, reason: '${verify.stderr}');
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
