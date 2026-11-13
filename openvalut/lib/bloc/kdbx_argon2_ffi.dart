import 'dart:io';

import 'package:argon2_ffi_base/argon2_ffi_base.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/bloc/kdbx_argon2_rust.dart' as rust;
import 'package:openvalut/utils/logging_utils.dart';

final _logger = Logger('kdbx_argon2_ffi');

// ignore_for_file: non_constant_identifier_names

/// Argon2 provider used by `kdbx.dart`.
///
/// On Android this delegates to the Rust implementation in `openvalut-core`;
/// on all other platforms it keeps the previous C-based FFI implementation.
class FlutterArgon2 extends Argon2 {
  FlutterArgon2._();

  factory FlutterArgon2() => singleton;

  static final FlutterArgon2 singleton = FlutterArgon2._();

  static final Argon2 _delegate = Platform.isAndroid
      ? rust.FlutterArgon2.singleton
      : Argon2FfiFlutter();

  @override
  Uint8List argon2(Argon2Arguments args) {
    throw StateError('Use [argon2Async]');
  }

  @override
  Future<Uint8List> argon2Async(Argon2Arguments args) async {
    final started = Stopwatch()..start();
    try {
      _logger.finest('Starting argon2');
      return await compute(FlutterArgon2._runArgon2, args);
    } finally {
      _logger.fine('Finished argon2 in ${started.elapsedMilliseconds}ms');
    }
  }

  static Uint8List _runArgon2(Argon2Arguments args) {
    LoggingUtils().setupLogging(fromMainIsolate: false);
    return _delegate.argon2(args);
  }

  @override
  bool get isFfi => _delegate.isFfi;

  @override
  bool get isImplemented => _delegate.isImplemented;
}
