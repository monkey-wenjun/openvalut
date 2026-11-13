import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openvalut/ssh/import_ssh_keys.dart';
import 'package:openvalut/ssh/machine_identity.dart';

void main() {
  test('machine identity tag is non-empty and contains a host', () {
    expect(MachineIdentity.tag, isNotEmpty);
    expect(MachineIdentity.hostname, isNotEmpty);
  });

  test('scanLocalSshKeys finds keys and skips config/known_hosts', () async {
    final sshKeygen = await Process.run('which', ['ssh-keygen']);
    if (sshKeygen.exitCode != 0) {
      markTestSkipped('ssh-keygen not available');
      return;
    }
    final dir = await Directory.systemTemp.createTemp('ssh_import_test_');
    try {
      for (final name in ['id_ed25519', 'id_rsa']) {
        final type = name == 'id_ed25519' ? 'ed25519' : 'rsa';
        await Process.run('ssh-keygen', [
          '-t',
          type,
          '-N',
          '',
          '-C',
          '$name@test',
          '-f',
          '${dir.path}/$name',
        ]);
      }
      File('${dir.path}/config').writeAsStringSync('Host *\n');
      File('${dir.path}/known_hosts').writeAsStringSync('example.com ssh-ed25519 AAAA\n');

      final found = await scanLocalSshKeys(dir.path);
      expect(found.map((c) => c.path).toList(), hasLength(2));
      expect(
        found.any((c) => c.path.endsWith('id_ed25519')),
        isTrue,
      );
      expect(
        found.any((c) => c.path.endsWith('id_rsa')),
        isTrue,
      );
      // The .pub companion is found via the private key, not as a separate key.
      expect(
        found.any((c) => c.path.endsWith('.pub')),
        isFalse,
      );
      final ed = found.firstWhere((c) => c.path.endsWith('id_ed25519'));
      expect(ed.publicKeyLine, startsWith('ssh-ed25519 '));
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
