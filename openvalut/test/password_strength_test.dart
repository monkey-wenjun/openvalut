import 'package:flutter_test/flutter_test.dart';
import 'package:openvalut/utils/password_strength.dart';

void main() {
  test('common passwords are weak', () {
    expect(isWeakPassword('password'), isTrue);
    expect(isWeakPassword('123456'), isTrue);
    expect(isWeakPassword('qwerty'), isTrue);
  });

  test('empty and missing passwords are not reported as weak', () {
    expect(isWeakPassword(null), isFalse);
    expect(isWeakPassword(''), isFalse);
  });

  test('long random password is not weak', () {
    expect(
      isWeakPassword(r'k8#mP2!vQ9$zR4@xW7&cN3'),
      isFalse,
    );
  });
}
