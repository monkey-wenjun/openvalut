@TestOn('linux || android')

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:openvalut/rust_core/rust_core.dart';
import 'package:openvalut/rust_core/rust_vault.dart';

void main() {
  test('argon2Hash produces deterministic output', () {
    final result = RustCore.argon2Hash(
      password: Uint8List.fromList('demopass'.codeUnits),
      salt: Uint8List.fromList('somesalt'.codeUnits),
      memory: 64 * 1024,
      iterations: 3,
      parallelism: 4,
      hashLen: 32,
      type: 2, // Argon2id
      version: 0x13,
    );
    expect(result, isA<Uint8List>());
    expect(result.length, 32);
    // Deterministic: same input must produce same output.
    final result2 = RustCore.argon2Hash(
      password: Uint8List.fromList('demopass'.codeUnits),
      salt: Uint8List.fromList('somesalt'.codeUnits),
      memory: 64 * 1024,
      iterations: 3,
      parallelism: 4,
      hashLen: 32,
      type: 2,
      version: 0x13,
    );
    expect(result2, result);
  });

  test('argon2Derive produces 32 bytes', () {
    final result = RustCore.argon2Derive(
      password: 'demopass',
      salt: Uint8List.fromList('somesalt'.codeUnits),
    );
    expect(result, isA<Uint8List>());
    expect(result.length, 32);
  });

  test('invalid Argon2 type throws', () {
    expect(
      () => RustCore.argon2Hash(
        password: Uint8List.fromList('x'.codeUnits),
        salt: Uint8List.fromList('y'.codeUnits),
        memory: 8,
        iterations: 1,
        parallelism: 1,
        hashLen: 32,
        type: 99,
        version: 0x13,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('RustVault create-save-reopen-read round trip', () {
    const password = 'vaultpassword';

    final vault = RustVault.createNew(name: 'Test');
    try {
      final uuid = vault.createEntry(
        const RustEntry(
          title: 'GitHub',
          username: 'alice',
          password: 's3cret',
          url: 'https://github.com',
          group: 'Work',
        ),
      );
      expect(uuid, isNotEmpty);

      final bytes = vault.save(password: password);
      expect(bytes, isNotEmpty);

      vault.close();

      final reopened = RustVault.open(bytes: bytes, password: password);
      try {
        final entries = reopened.entries();
        expect(entries.length, 1);
        expect(entries.single.title, 'GitHub');
        expect(entries.single.username, 'alice');
        expect(entries.single.password, 's3cret');
        expect(entries.single.url, 'https://github.com');
        expect(entries.single.group, 'Work');

        expect(reopened.entryValue(uuid: uuid, key: 'UserName'), 'alice');
        expect(reopened.entryValue(uuid: uuid, key: 'Password'), 's3cret');
        expect(reopened.entryValue(uuid: uuid, key: 'URL'), 'https://github.com');
        expect(reopened.entryValue(uuid: uuid, key: 'Title'), 'GitHub');
      } finally {
        reopened.close();
      }
    } finally {
      vault.close();
    }
  });

  test('RustVault update and delete entry', () {
    const password = 'vaultpassword2';

    final vault = RustVault.createNew(name: 'Test2');
    try {
      final uuid = vault.createEntry(
        const RustEntry(
          title: 'Old',
          username: 'olduser',
          password: 'oldpass',
          url: '',
        ),
      );

      vault.updateEntry(
        uuid: uuid,
        entry: const RustEntry(
          title: 'New',
          username: 'newuser',
          password: 'newpass',
          url: 'https://example.com',
        ),
      );

      var entries = vault.entries();
      expect(entries.single.title, 'New');
      expect(entries.single.username, 'newuser');

      vault.deleteEntry(uuid);
      entries = vault.entries();
      expect(entries, isEmpty);
    } finally {
      vault.close();
    }
  });
}
