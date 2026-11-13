import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

// ignore_for_file: non_constant_identifier_names

/// Result code: success.
const int openvalutOk = 0;

/// Result code: a null pointer was passed where it was not allowed.
const int openvalutErrorNull = -1;

/// Result code: invalid UTF-8 in a string argument.
const int openvalutErrorUtf8 = -2;

/// Result code: the output buffer is too small.
const int openvalutErrorBufferTooSmall = -3;

/// Result code: an internal core operation failed.
const int openvalutErrorCore = -4;

/// Result code: invalid argument.
const int openvalutErrorInvalidArg = -5;

/// Low-level FFI bindings for the OpenValut Rust core.
///
/// On Android the native library is bundled via jniLibs; on Linux we look for
/// a locally built .so so that unit tests can run on the host.
final class RustCore {
  static final DynamicLibrary _lib = _loadLibrary();

  static DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libopenvalut_mobile.so');
    }
    if (Platform.isLinux) {
      final candidates = [
        'target/debug/libopenvalut_mobile.so',
        '../target/debug/libopenvalut_mobile.so',
        '../../target/debug/libopenvalut_mobile.so',
        'crates/openvalut-mobile/target/debug/libopenvalut_mobile.so',
      ];
      for (final path in candidates) {
        if (File(path).existsSync()) {
          return DynamicLibrary.open(path);
        }
      }
    }
    throw UnsupportedError(
      'Platform ${Platform.operatingSystem} is not supported by openvalut-mobile',
    );
  }

  /// Flexible Argon2 hash matching the `Argon2Arguments` used by `kdbx.dart`.
  ///
  /// `type` is 0 for Argon2d, 1 for Argon2i, 2 for Argon2id. `version` is
  /// 0x10 (16) or 0x13 (19). Returns the hash as a [Uint8List] of length
  /// [hashLen].
  static Uint8List argon2Hash({
    required Uint8List password,
    required Uint8List salt,
    required int memory,
    required int iterations,
    required int parallelism,
    required int hashLen,
    required int type,
    required int version,
  }) {
    final passwordPtr = calloc<Uint8>(password.length);
    passwordPtr.asTypedList(password.length).setAll(0, password);
    final saltPtr = calloc<Uint8>(salt.length);
    saltPtr.asTypedList(salt.length).setAll(0, salt);
    final outPtr = calloc<Uint8>(hashLen);

    try {
      final native = _lib.lookupFunction<
          Int32 Function(
            Pointer<Uint8> password,
            Size passwordLen,
            Pointer<Uint8> salt,
            Size saltLen,
            Uint32 memory,
            Uint32 iterations,
            Uint32 parallelism,
            Size hashLen,
            Uint8 type,
            Uint32 version,
            Pointer<Uint8> out,
          ),
          int Function(
            Pointer<Uint8> password,
            int passwordLen,
            Pointer<Uint8> salt,
            int saltLen,
            int memory,
            int iterations,
            int parallelism,
            int hashLen,
            int type,
            int version,
            Pointer<Uint8> out,
          )>('openvalut_argon2_hash');

      final rc = native(
        passwordPtr,
        password.length,
        saltPtr,
        salt.length,
        memory,
        iterations,
        parallelism,
        hashLen,
        type,
        version,
        outPtr,
      );
      _throwOnError(rc, 'argon2_hash');

      return Uint8List.fromList(outPtr.asTypedList(hashLen));
    } finally {
      calloc.free(passwordPtr);
      calloc.free(saltPtr);
      calloc.free(outPtr);
    }
  }

  /// Derive a 32-byte key from [password] and [salt] using Argon2id with the
  /// fixed OpenValut cloud-sync parameters.
  static Uint8List argon2Derive({required String password, required Uint8List salt}) {
    final passwordPtr = password.toNativeUtf8(allocator: calloc);
    final saltPtr = calloc<Uint8>(salt.length);
    saltPtr.asTypedList(salt.length).setAll(0, salt);
    final outPtr = calloc<Uint8>(32);

    try {
      final native = _lib.lookupFunction<
          Int32 Function(Pointer<Utf8> password, Pointer<Uint8> salt, Size saltLen, Pointer<Uint8> out),
          int Function(Pointer<Utf8> password, Pointer<Uint8> salt, int saltLen, Pointer<Uint8> out)>('openvalut_argon2_derive');

      final rc = native(passwordPtr, saltPtr, salt.length, outPtr);
      _throwOnError(rc, 'argon2_derive');

      return Uint8List.fromList(outPtr.asTypedList(32));
    } finally {
      calloc.free(passwordPtr);
      calloc.free(saltPtr);
      calloc.free(outPtr);
    }
  }

  /// Create a new empty vault.
  static int vaultCreateNew({required String name}) {
    final namePtr = name.toNativeUtf8(allocator: calloc);
    final handlePtr = calloc<Uint64>();

    try {
      final native = _lib.lookupFunction<
          Int32 Function(Pointer<Utf8> name, Pointer<Uint64> outHandle),
          int Function(Pointer<Utf8> name, Pointer<Uint64> outHandle)>('openvalut_vault_create_new');
      final rc = native(namePtr, handlePtr);
      _throwOnError(rc, 'vault_create_new');
      return handlePtr.value;
    } finally {
      calloc.free(namePtr);
      calloc.free(handlePtr);
    }
  }

  /// Open a vault from [bytes] with [password].
  static int vaultOpen({required Uint8List bytes, required String password}) {
    final bytesPtr = calloc<Uint8>(bytes.length);
    bytesPtr.asTypedList(bytes.length).setAll(0, bytes);
    final passwordPtr = password.toNativeUtf8(allocator: calloc);
    final handlePtr = calloc<Uint64>();

    try {
      final native = _lib.lookupFunction<
          Int32 Function(Pointer<Uint8> bytes, Size len, Pointer<Utf8> password, Pointer<Uint64> outHandle),
          int Function(Pointer<Uint8> bytes, int len, Pointer<Utf8> password, Pointer<Uint64> outHandle)>('openvalut_vault_open');
      final rc = native(bytesPtr, bytes.length, passwordPtr, handlePtr);
      _throwOnError(rc, 'vault_open');
      return handlePtr.value;
    } finally {
      calloc.free(bytesPtr);
      calloc.free(passwordPtr);
      calloc.free(handlePtr);
    }
  }

  /// Open a vault from [bytes] with a 32-byte [transformedKey].
  static int vaultOpenWithTransformedKey({required Uint8List bytes, required Uint8List transformedKey}) {
    if (transformedKey.length != 32) {
      throw ArgumentError.value(transformedKey.length, 'transformedKey.length', 'must be 32');
    }
    final bytesPtr = calloc<Uint8>(bytes.length);
    bytesPtr.asTypedList(bytes.length).setAll(0, bytes);
    final keyPtr = calloc<Uint8>(32);
    keyPtr.asTypedList(32).setAll(0, transformedKey);
    final handlePtr = calloc<Uint64>();

    try {
      final native = _lib.lookupFunction<
          Int32 Function(Pointer<Uint8> bytes, Size len, Pointer<Uint8> transformedKey, Pointer<Uint64> outHandle),
          int Function(Pointer<Uint8> bytes, int len, Pointer<Uint8> transformedKey, Pointer<Uint64> outHandle)>('openvalut_vault_open_with_transformed_key');
      final rc = native(bytesPtr, bytes.length, keyPtr, handlePtr);
      _throwOnError(rc, 'vault_open_with_transformed_key');
      return handlePtr.value;
    } finally {
      calloc.free(bytesPtr);
      calloc.free(keyPtr);
      calloc.free(handlePtr);
    }
  }

  /// Serialize the vault back to KDBX bytes using [password].
  static Uint8List vaultSave({required int handle, required String password}) {
    final passwordPtr = password.toNativeUtf8(allocator: calloc);
    final bytesPtrPtr = calloc<Pointer<Uint8>>();
    final lenPtr = calloc<Size>();

    try {
      final native = _lib.lookupFunction<
          Int32 Function(Uint64 handle, Pointer<Utf8> password, Pointer<Pointer<Uint8>> outBytes, Pointer<Size> outLen),
          int Function(int handle, Pointer<Utf8> password, Pointer<Pointer<Uint8>> outBytes, Pointer<Size> outLen)>('openvalut_vault_save');
      final rc = native(handle, passwordPtr, bytesPtrPtr, lenPtr);
      _throwOnError(rc, 'vault_save');

      final len = lenPtr.value;
      final bytes = Uint8List.fromList(bytesPtrPtr.value.asTypedList(len));
      _freeBytes(bytesPtrPtr.value, len);
      return bytes;
    } finally {
      calloc.free(passwordPtr);
      calloc.free(bytesPtrPtr);
      calloc.free(lenPtr);
    }
  }

  /// List all entries as a JSON array string.
  static String vaultEntries({required int handle}) {
    final jsonPtrPtr = calloc<Pointer<Char>>();

    try {
      final native = _lib.lookupFunction<
          Int32 Function(Uint64 handle, Pointer<Pointer<Char>> outJson),
          int Function(int handle, Pointer<Pointer<Char>> outJson)>('openvalut_vault_entries');
      final rc = native(handle, jsonPtrPtr);
      _throwOnError(rc, 'vault_entries');

      final jsonPtr = jsonPtrPtr.value;
      final json = jsonPtr.cast<Utf8>().toDartString();
      _freeString(jsonPtr);
      return json;
    } finally {
      calloc.free(jsonPtrPtr);
    }
  }

  /// Read a single field value for an entry by UUID, or `null` if absent.
  static String? vaultEntryValue({required int handle, required String uuid, required String key}) {
    final uuidPtr = uuid.toNativeUtf8(allocator: calloc);
    final keyPtr = key.toNativeUtf8(allocator: calloc);
    final valuePtrPtr = calloc<Pointer<Char>>();

    try {
      final native = _lib.lookupFunction<
          Int32 Function(Uint64 handle, Pointer<Utf8> uuid, Pointer<Utf8> key, Pointer<Pointer<Char>> outValue),
          int Function(int handle, Pointer<Utf8> uuid, Pointer<Utf8> key, Pointer<Pointer<Char>> outValue)>('openvalut_vault_entry_value');
      final rc = native(handle, uuidPtr, keyPtr, valuePtrPtr);
      _throwOnError(rc, 'vault_entry_value');

      final valuePtr = valuePtrPtr.value;
      if (valuePtr == nullptr) {
        return null;
      }
      final value = valuePtr.cast<Utf8>().toDartString();
      _freeString(valuePtr);
      return value;
    } finally {
      calloc.free(uuidPtr);
      calloc.free(keyPtr);
      calloc.free(valuePtrPtr);
    }
  }

  /// Create a new entry and return its UUID.
  static String vaultCreateEntry({required int handle, required String json}) {
    final jsonPtr = json.toNativeUtf8(allocator: calloc);
    final uuidPtrPtr = calloc<Pointer<Char>>();

    try {
      final native = _lib.lookupFunction<
          Int32 Function(Uint64 handle, Pointer<Utf8> json, Pointer<Pointer<Char>> outUuid),
          int Function(int handle, Pointer<Utf8> json, Pointer<Pointer<Char>> outUuid)>('openvalut_vault_create_entry');
      final rc = native(handle, jsonPtr, uuidPtrPtr);
      _throwOnError(rc, 'vault_create_entry');

      final uuidPtr = uuidPtrPtr.value;
      final uuid = uuidPtr.cast<Utf8>().toDartString();
      _freeString(uuidPtr);
      return uuid;
    } finally {
      calloc.free(jsonPtr);
      calloc.free(uuidPtrPtr);
    }
  }

  /// Update an existing entry by UUID.
  static void vaultUpdateEntry({required int handle, required String uuid, required String json}) {
    final uuidPtr = uuid.toNativeUtf8(allocator: calloc);
    final jsonPtr = json.toNativeUtf8(allocator: calloc);

    try {
      final native = _lib.lookupFunction<
          Int32 Function(Uint64 handle, Pointer<Utf8> uuid, Pointer<Utf8> json),
          int Function(int handle, Pointer<Utf8> uuid, Pointer<Utf8> json)>('openvalut_vault_update_entry');
      final rc = native(handle, uuidPtr, jsonPtr);
      _throwOnError(rc, 'vault_update_entry');
    } finally {
      calloc.free(uuidPtr);
      calloc.free(jsonPtr);
    }
  }

  /// Delete an entry by UUID.
  static void vaultDeleteEntry({required int handle, required String uuid}) {
    final uuidPtr = uuid.toNativeUtf8(allocator: calloc);

    try {
      final native = _lib.lookupFunction<
          Int32 Function(Uint64 handle, Pointer<Utf8> uuid),
          int Function(int handle, Pointer<Utf8> uuid)>('openvalut_vault_delete_entry');
      final rc = native(handle, uuidPtr);
      _throwOnError(rc, 'vault_delete_entry');
    } finally {
      calloc.free(uuidPtr);
    }
  }

  /// Close a vault handle.
  static void vaultClose(int handle) {
    final native = _lib.lookupFunction<
        Int32 Function(Uint64 handle),
        int Function(int handle)>('openvalut_vault_close');
    native(handle);
  }

  static void _freeString(Pointer<Char> ptr) {
    final native = _lib.lookupFunction<Void Function(Pointer<Char>), void Function(Pointer<Char>)>('openvalut_vault_free_string');
    native(ptr);
  }

  static void _freeBytes(Pointer<Uint8> ptr, int len) {
    final native = _lib.lookupFunction<
        Void Function(Pointer<Uint8> ptr, Size len),
        void Function(Pointer<Uint8> ptr, int len)>('openvalut_vault_free_bytes');
    native(ptr, len);
  }

  static void _throwOnError(int rc, String operation) {
    if (rc == openvalutOk) {
      return;
    }
    final message = switch (rc) {
      openvalutErrorNull => 'null pointer',
      openvalutErrorUtf8 => 'invalid UTF-8',
      openvalutErrorBufferTooSmall => 'buffer too small',
      openvalutErrorCore => 'core operation failed',
      openvalutErrorInvalidArg => 'invalid argument',
      _ => 'unknown error $rc',
    };
    throw StateError('openvalut_$operation failed: $message');
  }
}
