import 'package:flutter_test/flutter_test.dart';
import 'package:openvalut/computer/computer_two_factor_setup.dart';
import 'package:openvalut/utils/base32utils.dart';
import 'package:openvalut/utils/otpauth.dart';

void main() {
  group('ComputerTwoFactorSetup.buildOtpUri', () {
    test('produces a parseable otpauth URI carrying the same secret', () {
      final secret = base32Decode('JBSWY3DPEHPK3PXP');
      final uri = ComputerTwoFactorSetup.buildOtpUri(
        user: 'octocat',
        host: 'example-host',
        secret: secret,
      );

      expect(uri, startsWith('otpauth://totp/'));
      final parsed = OtpAuth.fromUri(Uri.parse(uri));
      expect(base32Encode(parsed.secret), 'JBSWY3DPEHPK3PXP');
      expect(parsed.digits, 6);
      expect(parsed.period, 30);
      expect(Uri.parse(uri).queryParameters['issuer'], 'OpenValut');
    });
  });

  group('ComputerTwoFactorSetup.extractBase32Secret', () {
    test('extracts from an otpauth:// URI', () {
      const raw = 'otpauth://totp/OpenValut:octocat@example-host'
          '?secret=JBSWY3DPEHPK3PXP&issuer=OpenValut&algorithm=SHA1'
          '&digits=6&period=30';
      expect(
        ComputerTwoFactorSetup.extractBase32Secret(raw),
        'JBSWY3DPEHPK3PXP',
      );
    });

    test('normalizes a bare base32 secret (uppercase, no padding)', () {
      expect(
        ComputerTwoFactorSetup.extractBase32Secret('jbswy3dpehpk3pxp'),
        'JBSWY3DPEHPK3PXP',
      );
    });

    test('accepts a KeeOTP query string', () {
      expect(
        ComputerTwoFactorSetup.extractBase32Secret('key=JBSWY3DPEHPK3PXP'),
        'JBSWY3DPEHPK3PXP',
      );
    });
  });
}
