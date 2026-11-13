// Standalone check (no Flutter/FFI): create a KDBX with a password, save it,
// reopen it with the same password, and confirm the unlock works. Run with
// `dart run tool/kdbx_roundtrip_check.dart` from the openvalut/ directory.
import 'dart:typed_data';

import 'package:kdbx/kdbx.dart';

Future<void> main() async {
  const password = 'my-test-master-password';
  final format = KdbxFormat();
  final credentials = Credentials(ProtectedValue.fromString(password));
  final file = format.create(credentials, '我的密码', generator: 'OpenValut');

  final bytes = await file.saveTo<Uint8List>((bytes) async => bytes);
  print('KDBX bytes: ${bytes.length}');

  // Reopen exactly like CredentialsScreen does: Credentials.composite.
  final reopened = await format.read(
    bytes,
    Credentials.composite(ProtectedValue.fromString(password), null),
  );
  print('UNLOCK OK: ${reopened.body.meta.databaseName.get()}');

  // A wrong password must fail.
  var failed = false;
  try {
    await format.read(
      bytes,
      Credentials.composite(ProtectedValue.fromString('wrong-password'), null),
    );
  } on KdbxInvalidKeyException {
    failed = true;
  }
  print('WRONG PASSWORD REJECTED: $failed');
}
