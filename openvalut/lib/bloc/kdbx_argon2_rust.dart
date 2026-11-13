import 'package:argon2_ffi_base/argon2_ffi_base.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/rust_core/rust_core.dart';
import 'package:openvalut/utils/logging_utils.dart';

final _logger = Logger('kdbx_argon2_rust');

// ignore_for_file: non_constant_identifier_names

/// Rust-based Argon2 implementation for `kdbx.dart`.
///
/// This replaces the C-based `Argon2FfiFlutter` with a call into
/// `openvalut-core` via the `openvalut-mobile` FFI library.
class FlutterArgon2 extends Argon2 {
  FlutterArgon2._();

  static final singleton = FlutterArgon2._();

  @override
  bool get isFfi => true;

  @override
  bool get isImplemented => true;

  @override
  Uint8List argon2(Argon2Arguments args) {
    // The synchronous entry point is used when kdbx.dart offloads Argon2 to a
    // background isolate via compute(). Running the Rust implementation there
    // avoids blocking the UI thread while still being synchronous inside the
    // isolate.
    return _runArgon2(args);
  }

  @override
  Future<Uint8List> argon2Async(Argon2Arguments args) async {
    final started = Stopwatch()..start();
    try {
      _logger.finest('Starting argon2 (Rust)');
      return await compute(FlutterArgon2._runArgon2, args);
    } finally {
      _logger.fine('Finished argon2 (Rust) in ${started.elapsedMilliseconds}ms');
    }
  }

  static Uint8List _runArgon2(Argon2Arguments args) {
    LoggingUtils().setupLogging(fromMainIsolate: false);
    return RustCore.argon2Hash(
      password: args.key,
      salt: args.salt,
      memory: args.memory,
      iterations: args.iterations,
      parallelism: args.parallelism,
      hashLen: args.length,
      type: args.type,
      version: args.version,
    );
  }
}
