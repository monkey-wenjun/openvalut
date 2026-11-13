// Creates a OpenValut Cloud vault for an existing account (email-only login)
// using the exact same crypto as the app:
//   dart run tool/create_cloud_vault.dart <email> <master-password> <vault-name>
//
// KDBX is generated with the pure-Dart kdbx implementation, the vault blob
// key is Argon2id (64 MiB / 3 / 4) via the bundled libargon2_ffi_plugin.so,
// and the blob is AES-256-GCM encrypted with pointycastle.
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:http/http.dart' as http;
import 'package:kdbx/kdbx.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/api.dart';

/// 构建/运行环境变量注入（来自本地 .env），不硬编码私有域名。
const _server = String.fromEnvironment(
  'openvalut_CLOUD_URI',
  defaultValue: '',
);

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

Future<void> main(List<String> args) async {
  if (args.length < 3) {
    stderr.writeln('usage: create_cloud_vault <email> <master-password> <vault-name>');
    exit(1);
  }
  final email = args[0].trim().toLowerCase();
  final password = args[1];
  final vaultName = args[2];

  // 1. Email-only login.
  final loginRes = await http.post(
    Uri.parse('$_server/api/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': email}),
  );
  if (loginRes.statusCode != 200) {
    stderr.writeln('login failed: ${loginRes.body}');
    exit(1);
  }
  final token =
      (jsonDecode(loginRes.body) as Map<String, dynamic>)['token'] as String;

  // 2. Client-generated 32-char hex vault id (doubles as the KDF salt).
  final random = Random.secure();
  final vaultId = List.generate(
    16,
    (_) => random.nextInt(256),
  ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  // 3. KDBX bytes (master password, pure-Dart argon2 via kdbx package).
  final format = KdbxFormat();
  final credentials = Credentials(ProtectedValue.fromString(password));
  final file = format.create(credentials, vaultName, generator: 'OpenValut');
  final kdbxBytes = await file.saveTo<Uint8List>((b) async => b);
  print('KDBX bytes: ${kdbxBytes.length}');

  // 4. Argon2id vault key via the bundled FFI library.
  final so = Platform.environment['ARGON2_SO'] ??
      'build/linux/x64/release/bundle/lib/libargon2_ffi_plugin.so';
  final lib = DynamicLibrary.open(so);
  final hash = lib.lookupFunction<_HashNative, _Hash>('hp_argon2_hash');
  final keyPtr = _ptr(utf8.encode(password));
  final saltPtr = _ptr(utf8.encode(vaultId));
  final keyB64 = hash(
    keyPtr,
    password.length,
    saltPtr,
    vaultId.length,
    64 * 1024,
    3,
    4,
    32,
    2,
    0x13,
  );
  final key = base64.decode(keyB64.toDartString());

  // 5. AES-256-GCM encrypt the KDBX blob (same as openvalutCrypto.encrypt).
  final (nonce, ciphertext) = _encrypt(key, kdbxBytes);

  // 6. Upload.
  final res = await http.post(
    Uri.parse('$_server/api/vaults'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'id': vaultId,
      'name': vaultName,
      'nonce': base64.encode(nonce),
      'ciphertext': base64.encode(ciphertext),
    }),
  );
  if (res.statusCode != 201) {
    stderr.writeln('create vault failed: ${res.body}');
    exit(1);
  }
  print('VAULT CREATED: $vaultName (id=$vaultId)');
}

Pointer<Uint8> _ptr(List<int> bytes) {
  final ptr = calloc<Uint8>(bytes.length);
  ptr.asTypedList(bytes.length).setAll(0, bytes);
  return ptr;
}

(Uint8List, Uint8List) _encrypt(Uint8List key, Uint8List plaintext) {
  final nonce = Uint8List.fromList(
    List.generate(12, (_) => Random.secure().nextInt(256)),
  );
  final gcm = GCMBlockCipher(AESEngine());
  gcm.init(true, AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)));
  final out = Uint8List(gcm.getOutputSize(plaintext.length));
  var len = gcm.processBytes(plaintext, 0, plaintext.length, out, 0);
  len += gcm.doFinal(out, len);
  return (nonce, Uint8List.sublistView(out, 0, len));
}
