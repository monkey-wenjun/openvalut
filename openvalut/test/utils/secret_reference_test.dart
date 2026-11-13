import 'package:flutter_test/flutter_test.dart';
import 'package:openvalut/utils/secret_reference.dart';

void main() {
  group('SecretReference.parse', () {
    test('parses op://vault/item/field with Chinese values', () {
      final ref = SecretReference.parse('op://我的密码库/网易杭研邮箱/password');
      expect(ref, isNotNull);
      expect(ref!.vaultId, '我的密码库');
      expect(ref.entryId, '网易杭研邮箱');
      expect(ref.field, 'password');
    });

    test('parses op: percent-encoded Chinese item', () {
      final ref = SecretReference.parse(
        'op:33132e9c50aa499bb8a1462f3cff9b11/'
        '%E7%BD%91%E6%98%93%E6%9D%AD%E7%A0%94%E9%82%AE%E7%AE%B1/password',
      );
      expect(ref, isNotNull);
      expect(ref!.vaultId, '33132e9c50aa499bb8a1462f3cff9b11');
      expect(ref.entryId, '网易杭研邮箱');
      expect(ref.field, 'password');
    });

    test('parses ov:// with ASCII values', () {
      final ref = SecretReference.parse('ov://Personal/GitHub/password');
      expect(ref, isNotNull);
      expect(ref!.vaultId, 'personal'); // authority hosts are lowercased by Uri
      expect(ref.entryId, 'GitHub');
      expect(ref.field, 'password');
    });

    test('keeps slashes inside custom field keys', () {
      final ref = SecretReference.parse('op://Personal/Mail/custom/field');
      expect(ref, isNotNull);
      expect(ref!.field, 'custom/field');
    });

    test('rejects references with fewer than three segments', () {
      expect(SecretReference.parse('op://vault/item'), isNull);
      expect(SecretReference.parse('op://vault'), isNull);
      expect(SecretReference.parse('op:'), isNull);
    });

    test('rejects non ov/op schemes', () {
      expect(SecretReference.parse('https://vault/item/password'), isNull);
    });
  });

  group('SecretReference.generate', () {
    test('round-trips Chinese values', () {
      final ref = SecretReference.generate(
        vaultId: '我的密码库',
        entryId: '网易杭研邮箱',
        field: 'password',
      );
      final parsed = SecretReference.parse(ref);
      expect(parsed, isNotNull);
      expect(parsed!.vaultId, '我的密码库');
      expect(parsed.entryId, '网易杭研邮箱');
      expect(parsed.field, 'password');
    });

    test('round-trips custom field keys with slashes', () {
      final ref = SecretReference.generate(
        vaultId: 'Personal',
        entryId: 'GitHub',
        field: 'custom/field',
      );
      final parsed = SecretReference.parse(ref);
      expect(parsed, isNotNull);
      expect(parsed!.field, 'custom/field');
    });
  });
}