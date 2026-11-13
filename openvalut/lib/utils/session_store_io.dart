import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:logging/logging.dart';

final _logger = Logger('session_store');

/// Shared "unlocked" cache in the Linux kernel *user* keyring (`@u`).
///
/// The keyring is per-UID and lives in kernel memory only: the desktop app, a
/// fresh terminal and an SSH login of the same user all resolve the same key,
/// and it disappears when the machine reboots (nothing is written to disk).
///
/// `openvalut-cli unlock` writes the very same key, so unlocking on either side
/// unlocks the other: the CLI reads what the app published, and the app
/// auto-unlocks from what the CLI published.
///
/// Everything here is best-effort: on non-Linux, on a kernel/seccomp policy
/// that blocks `add_key(2)`, or when `libkeyutils` is missing, the store is
/// simply unavailable and the caller falls back to asking for the password.
class SessionStore {
  /// Must match `openvalut-cli`'s `SessionKeyStore` key description.
  static const _masterPasswordKey = 'openvalut:master-password';

  /// `KEY_SPEC_USER_KEYRING` — the per-UID user keyring.
  static const _userKeyring = -4;

  /// `KEY_USR_ALL`: `add_key(2)` creates the key without user *read*, so a
  /// later process has to be granted read explicitly.
  static const _usrAll = 0x003f0000;

  static _Keyutils? _lib;
  static bool _unavailable = false;

  static _Keyutils? _open() {
    if (_unavailable) {
      return null;
    }
    if (_lib != null) {
      return _lib;
    }
    if (!Platform.isLinux) {
      _unavailable = true;
      return null;
    }
    try {
      _lib = _Keyutils(DynamicLibrary.open('libkeyutils.so.1'));
    } catch (e, stackTrace) {
      _logger.info(
        'Kernel keyring unavailable; shared app/CLI unlock disabled.',
        e,
        stackTrace,
      );
      _unavailable = true;
    }
    return _lib;
  }

  /// The master password stored by the app or the CLI, or null when none is.
  static String? read() {
    final lib = _open();
    if (lib == null) {
      return null;
    }
    final serial = _search(lib, _masterPasswordKey);
    if (serial <= 0) {
      return null;
    }
    final size = lib.read(serial, nullptr, 0);
    if (size <= 0) {
      return null;
    }
    final buffer = calloc<Uint8>(size);
    try {
      final read = lib.read(serial, buffer, size);
      if (read <= 0) {
        return null;
      }
      return utf8.decode(buffer.asTypedList(read));
    } on FormatException catch (e) {
      _logger.warning('Shared unlock value is not valid UTF-8.', e);
      return null;
    } finally {
      calloc.free(buffer);
    }
  }

  /// Publishes [masterPassword] for the other side (and later SSH logins).
  static void save(String masterPassword) {
    if (masterPassword.isEmpty) {
      return;
    }
    final lib = _open();
    if (lib == null) {
      return;
    }
    final type = 'user'.toNativeUtf8();
    final description = _masterPasswordKey.toNativeUtf8();
    final payload = masterPassword.toNativeUtf8();
    try {
      final serial = lib.addKey(
        type,
        description,
        payload.cast<Uint8>(),
        payload.length,
        _userKeyring,
      );
      if (serial <= 0) {
        _logger.warning('Unable to store the shared unlock key.');
        return;
      }
      // Grant same-UID read so the CLI (a different process) finds it.
      lib.setPerm(serial, _usrAll);
    } finally {
      calloc.free(type);
      calloc.free(description);
      calloc.free(payload);
    }
  }

  /// Forgets the shared master password (used by the explicit lock action).
  static void clear() {
    final lib = _open();
    if (lib == null) {
      return;
    }
    final serial = _search(lib, _masterPasswordKey);
    if (serial > 0) {
      lib.unlink(serial, _userKeyring);
    }
  }

  static int _search(_Keyutils lib, String description) {
    final type = 'user'.toNativeUtf8();
    final desc = description.toNativeUtf8();
    try {
      return lib.search(_userKeyring, type, desc, 0);
    } finally {
      calloc.free(type);
      calloc.free(desc);
    }
  }
}

// `libkeyutils` (a Debian/Ubuntu runtime dependency of the `keyutils` package)
// exposes non-variadic wrappers, which is what `dart:ffi` can bind to.
typedef _AddKeyNative =
    Int32 Function(
      Pointer<Utf8> type,
      Pointer<Utf8> description,
      Pointer<Uint8> payload,
      IntPtr payloadLength,
      Int32 keyring,
    );
typedef _AddKeyDart =
    int Function(
      Pointer<Utf8> type,
      Pointer<Utf8> description,
      Pointer<Uint8> payload,
      int payloadLength,
      int keyring,
    );

typedef _SearchNative =
    Int64 Function(
      Int32 keyring,
      Pointer<Utf8> type,
      Pointer<Utf8> description,
      Int32 destinationKeyring,
    );
typedef _SearchDart =
    int Function(
      int keyring,
      Pointer<Utf8> type,
      Pointer<Utf8> description,
      int destinationKeyring,
    );

typedef _ReadNative =
    Int64 Function(
      Int32 key,
      Pointer<Uint8> buffer,
      IntPtr bufferLength,
    );
typedef _ReadDart =
    int Function(int key, Pointer<Uint8> buffer, int bufferLength);

typedef _SetPermNative = Int64 Function(Int32 key, Uint32 permissions);
typedef _SetPermDart = int Function(int key, int permissions);

typedef _UnlinkNative = Int64 Function(Int32 key, Int32 keyring);
typedef _UnlinkDart = int Function(int key, int keyring);

class _Keyutils {
  _Keyutils(DynamicLibrary library)
    : addKey = library.lookupFunction<_AddKeyNative, _AddKeyDart>('add_key'),
      search = library.lookupFunction<_SearchNative, _SearchDart>(
        'keyctl_search',
      ),
      read = library.lookupFunction<_ReadNative, _ReadDart>('keyctl_read'),
      setPerm = library.lookupFunction<_SetPermNative, _SetPermDart>(
        'keyctl_setperm',
      ),
      unlink = library.lookupFunction<_UnlinkNative, _UnlinkDart>(
        'keyctl_unlink',
      );

  final _AddKeyDart addKey;
  final _SearchDart search;
  final _ReadDart read;
  final _SetPermDart setPerm;
  final _UnlinkDart unlink;
}
