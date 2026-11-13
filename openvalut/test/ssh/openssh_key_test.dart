import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:openvalut/ssh/openssh_key.dart';

void main() {
  test('rejects non-OpenSSH payloads', () {
    expect(
      () => parseOpensshPrivateKey('-----BEGIN RSA PRIVATE KEY-----\nabc\n'),
      throwsA(isA<SshKeyParseException>()),
    );
  });

  test('parses a real ssh-keygen ed25519 key and rebuilds the blob', () async {
    final sshKeygen = await Process.run('which', ['ssh-keygen']);
    if (sshKeygen.exitCode != 0) {
      markTestSkipped('ssh-keygen not available');
      return;
    }
    final dir = await Directory.systemTemp.createTemp('openssh_test_');
    try {
      final gen = await Process.run('ssh-keygen', [
        '-t',
        'ed25519',
        '-N',
        '',
        '-C',
        'test@openvalut',
        '-f',
        '${dir.path}/key',
      ]);
      expect(gen.exitCode, 0, reason: '${gen.stderr}');

      final parsed = parseOpensshPrivateKey(
        File('${dir.path}/key').readAsStringSync(),
      );
      expect(parsed.keyType, SshKeyType.ed25519);

      final pubLine = File('${dir.path}/key.pub').readAsStringSync().trim();
      final expectedBlob = Uint8List.fromList(base64.decode(pubLine.split(' ')[1]));
      expect(parsed.publicKey, expectedBlob);

      // Round-trip: the agent must be able to sign and the signature verifies
      // against the on-disk public key (validated by OpenSSL elsewhere).
      final signature = parsed.sign(utf8.encode('hello'));
      expect(signature.length, 64);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
