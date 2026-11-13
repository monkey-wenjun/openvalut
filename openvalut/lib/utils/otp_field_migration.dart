import 'package:kdbx/kdbx.dart';

/// One-time migration that brings legacy OTP fields into the single canonical
/// `OTPAuth` key.
///
/// KeePassXC-imported entries store the secret under lowercase `otp` (and older
/// KeeWeb used `TOTP Seed`). Renaming them to `OTPAuth` means the whole app,
/// the credential server and the native host read exactly one field name
/// instead of branching per alias. Idempotent: entries that already carry
/// `OTPAuth` are left untouched, so this is safe to run on every open.
void migrateLegacyOtpFieldsInFile(KdbxFile file) {
  const otpAuthKey = KdbxKeyCommon.OTP;
  for (final entry in file.body.rootGroup.getAllEntries()) {
    if (entry.isInRecycleBin()) {
      continue;
    }
    if (entry.getString(otpAuthKey) != null) {
      // Already canonical; leave it alone.
      continue;
    }
    // Prefer the self-contained KeePassXC `otp` field over the older
    // `TOTP Seed` (which needs a separate settings field).
    KdbxKey? legacyKey;
    final otpValue = entry.getString(KdbxKey('otp'))?.getText() ?? '';
    final seedValue = entry.getString(KdbxKey('TOTP Seed'))?.getText() ?? '';
    if (otpValue.isNotEmpty) {
      legacyKey = KdbxKey('otp');
    } else if (seedValue.isNotEmpty) {
      legacyKey = KdbxKey('TOTP Seed');
    }
    if (legacyKey != null) {
      entry.renameKey(legacyKey, otpAuthKey);
    }
  }
}
