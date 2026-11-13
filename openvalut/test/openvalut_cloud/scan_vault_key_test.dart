import 'package:flutter_test/flutter_test.dart';
import 'package:openvalut/openvalut_cloud/scan_vault_key.dart';

void main() {
  test('scan vault key encrypts to the PC and decrypts back', () {
    const masterPassword = 'correct horse battery staple';
    final pair = generateScanKeyPair();
    final encoded = encodeScanPublicKey(pair.publicKey);

    // 手机端加密
    final ciphertext = encryptVaultKeyForScan(masterPassword, encoded);
    expect(ciphertext, isNotEmpty);
    expect(ciphertext, isNot(contains(masterPassword)));

    // PC 端解密
    final decrypted = decryptVaultKeyFromScan(ciphertext, pair.privateKey);
    expect(decrypted, masterPassword);
  });
}
