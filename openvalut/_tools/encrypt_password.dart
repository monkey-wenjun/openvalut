import 'dart:convert';
import 'dart:io';

import 'package:openvalut/utils/secure_auto_unlock.dart';

/// Command-line helper to create an encrypted auto-unlock password file.
/// Usage: dart run _tools/encrypt_password.dart "your master password"
/// Writes the base64 ciphertext to stdout and to openvalut.pw in the current
/// directory (overwriting any existing file).
void main(List<String> args) {
  final password = args.isNotEmpty
      ? args.first
      : _readPassword('Enter master password: ');
  if (password.isEmpty) {
    stderr.writeln('Password cannot be empty.');
    exit(1);
  }
  final encrypted = encryptAutoUnlockPassword(password);
  stdout.writeln(encrypted);
  File('openvalut.pw').writeAsStringSync(encrypted);
  stdout.writeln('Written to ./openvalut.pw');
}

String _readPassword(String prompt) {
  stdout.write(prompt);
  final line = stdin.readLineSync(encoding: utf8);
  return line ?? '';
}
