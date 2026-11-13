import 'package:flutter_test/flutter_test.dart';
import 'package:kdbx/kdbx.dart';
import 'package:openvalut/utils/otp_field_migration.dart';

void main() {
  KdbxFile makeFile() {
    final format = KdbxFormat();
    return format.create(Credentials(ProtectedValue.fromString('p')), 'T');
  }

  KdbxEntry addEntry(KdbxFile file) {
    final entry = KdbxEntry.create(file, file.body.rootGroup);
    file.body.rootGroup.addEntry(entry);
    return entry;
  }

  test('migrates lowercase otp to OTPAuth', () {
    final file = makeFile();
    final entry = addEntry(file);
    entry.setString(
      KdbxKey('otp'),
      PlainValue(
        'otpauth://totp/GitHub?secret=JBSWY3DPEHPK3PXP',
      ),
    );

    migrateLegacyOtpFieldsInFile(file);

    expect(
      entry.getString(KdbxKeyCommon.OTP)?.getText(),
      'otpauth://totp/GitHub?secret=JBSWY3DPEHPK3PXP',
    );
    expect(entry.getString(KdbxKey('otp')), isNull);
  });

  test('migrates TOTP Seed to OTPAuth', () {
    final file = makeFile();
    final entry = addEntry(file);
    entry.setString(
      KdbxKey('TOTP Seed'),
      PlainValue('JBSWY3DPEHPK3PXP'),
    );

    migrateLegacyOtpFieldsInFile(file);

    expect(
      entry.getString(KdbxKeyCommon.OTP)?.getText(),
      'JBSWY3DPEHPK3PXP',
    );
    expect(entry.getString(KdbxKey('TOTP Seed')), isNull);
  });

  test('leaves entries that already carry OTPAuth untouched', () {
    final file = makeFile();
    final entry = addEntry(file);
    entry.setString(
      KdbxKeyCommon.OTP,
      PlainValue(
        'otpauth://totp/GitHub?secret=JBSWY3DPEHPK3PXP&period=30',
      ),
    );

    migrateLegacyOtpFieldsInFile(file);

    expect(
      entry.getString(KdbxKeyCommon.OTP)?.getText(),
      'otpauth://totp/GitHub?secret=JBSWY3DPEHPK3PXP&period=30',
    );
    expect(entry.getString(KdbxKey('otp')), isNull);
  });
}
