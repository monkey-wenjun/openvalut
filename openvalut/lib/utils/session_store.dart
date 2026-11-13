/// Shared "unlocked" cache between the desktop app and `openvalut-cli`.
///
/// The real implementation lives in the `_io` file (Linux kernel user
/// keyring); the web/no-op stub keeps every other platform compiling.
library;

export 'package:openvalut/utils/session_store_stub.dart'
    if (dart.library.io) 'package:openvalut/utils/session_store_io.dart';
