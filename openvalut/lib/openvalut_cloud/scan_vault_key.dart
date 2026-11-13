import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// 扫码自动解锁用的端到端加密。
///
/// PC 端生成一次性 RSA 密钥对，把公钥附在二维码里；手机确认登录时用该
/// 公钥加密主密码，服务器只中转密文（看不到明文），PC 拿到后用私钥解密，
/// 直接解锁密码库。

/// 把 RSA 公钥编码成适合放进二维码 URL 参数的紧凑文本（base64url 的
/// {n,e} JSON，去除 padding）。
String encodeScanPublicKey(RSAPublicKey publicKey) {
  final json = jsonEncode({
    'n': publicKey.modulus!.toRadixString(16),
    'e': publicKey.exponent!.toRadixString(16),
  });
  return base64Url.encode(utf8.encode(json)).replaceAll('=', '');
}

RSAPublicKey decodeScanPublicKey(String encoded) {
  final padded = encoded.padRight(
    encoded.length + ((4 - encoded.length % 4) % 4),
    '=',
  );
  final data = jsonDecode(utf8.decode(base64Url.decode(padded)));
  return RSAPublicKey(
    BigInt.parse(data['n'] as String, radix: 16),
    BigInt.parse(data['e'] as String, radix: 16),
  );
}

/// PC 端：生成一次性 RSA 密钥对，私钥只留在 PC 内存里。
({RSAPublicKey publicKey, RSAPrivateKey privateKey}) generateScanKeyPair() {
  final rng = FortunaRandom();
  final seedSource = Random.secure();
  final seed = Uint8List.fromList(
    List<int>.generate(32, (_) => seedSource.nextInt(256)),
  );
  rng.seed(KeyParameter(seed));
  final generator = RSAKeyGenerator()
    ..init(
      ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 12),
        rng,
      ),
    );
  final pair = generator.generateKeyPair();
  return (publicKey: pair.publicKey, privateKey: pair.privateKey);
}

/// 手机端：用二维码里的 PC 公钥加密主密码，返回 base64 密文。
String encryptVaultKeyForScan(String masterPassword, String encodedPublicKey) {
  final cipher = OAEPEncoding.withSHA256(RSAEngine())
    ..init(
      true,
      PublicKeyParameter<RSAPublicKey>(decodeScanPublicKey(encodedPublicKey)),
    );
  return base64.encode(cipher.process(utf8.encode(masterPassword)));
}

/// PC 端：解密手机转发的密文，还原主密码。
String decryptVaultKeyFromScan(String ciphertext, RSAPrivateKey privateKey) {
  final cipher = OAEPEncoding.withSHA256(RSAEngine())
    ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
  return utf8.decode(cipher.process(base64.decode(ciphertext)));
}
