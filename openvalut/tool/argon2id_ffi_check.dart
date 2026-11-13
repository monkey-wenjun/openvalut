// Verifies that the bundled libargon2_ffi_plugin.so now implements Argon2id
// (type=2) correctly by comparing against the Go reference vector:
// Argon2id("test-password", salt "0123456789abcdef", 64 MiB, 3 iters, 4 lanes)
// -> d774d399883c545c11b8dc7253c37ce196dca2c3234964b8dc91f39ef894871c
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

typedef _HashNative = Pointer<Utf8> Function(
  Pointer<Uint8> key,
  Uint32 keyLen,
  Pointer<Uint8> salt,
  Uint32 saltLen,
  Uint32 mCost,
  Uint32 tCost,
  Uint32 parallelism,
  Uint32 hashLen,
  Uint8 type,
  Int32 version,
);

typedef _Hash = Pointer<Utf8> Function(
  Pointer<Uint8>,
  int,
  Pointer<Uint8>,
  int,
  int,
  int,
  int,
  int,
  int,
  int,
);

void main() {
  final so = Platform.environment['ARGON2_SO'] ??
      'build/linux/x64/release/bundle/lib/libargon2_ffi_plugin.so';
  final lib = DynamicLibrary.open(so);
  final hash = lib.lookupFunction<_HashNative, _Hash>('hp_argon2_hash');

  final password = 'test-password'.codeUnits;
  final salt = '0123456789abcdef'.codeUnits;
  final keyPtr = _toPtr(password);
  final saltPtr = _toPtr(salt);
  final out = hash(
    keyPtr,
    password.length,
    saltPtr,
    salt.length,
    64 * 1024, // 64 MiB
    3,
    4,
    32,
    2, // Argon2id
    0x13,
  );
  final result = base64.decode(out.toDartString());
  final hex = [for (final b in result) b.toRadixString(16).padLeft(2, '0')].join();
  print('DERIVED: $hex');
  print(
    'MATCHES GO: '
    '${hex == 'd774d399883c545c11b8dc7253c37ce196dca2c3234964b8dc91f39ef894871c'}',
  );
}

Pointer<Uint8> _toPtr(List<int> bytes) {
  final ptr = calloc<Uint8>(bytes.length);
  final list = ptr.asTypedList(bytes.length);
  list.setAll(0, bytes);
  return ptr;
}
