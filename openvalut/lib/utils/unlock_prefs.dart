import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferences for the "remember master password" grace period and the
/// optional biometric (fingerprint) quick unlock.
///
/// The grace period is expressed in days: 0 means disabled, and 7 / 14 / 30
/// are the offered options. Fingerprint unlock is an opt-in extra that gates
/// the stored credentials behind a biometric prompt on platforms that support
/// it (Android / iOS / macOS).
class UnlockPrefs {
  UnlockPrefs._();

  static const _rememberDaysKey = 'remember_unlock_days'; // NON-NLS
  static const _fingerprintKey = 'fingerprint_unlock_enabled'; // NON-NLS
  static const _quickUnlockBootIdKey = 'quick_unlock_boot_id'; // NON-NLS
  static const _showVaultStartPageKey = 'show_vault_start_page'; // NON-NLS
  static const _sshAgentEnabledKey = 'ssh_agent_enabled'; // NON-NLS
  static const _credentialServerEnabledKey =
      'credential_server_enabled'; // NON-NLS
  static const _autoConfigureComputer2faKey =
      'auto_configure_computer_2fa'; // NON-NLS

  static const defaultRememberDays = 30;

  /// Number of days the master password is remembered after the last entry.
  /// 0 means the password has to be entered every time.
  static final ValueNotifier<int> rememberUnlockDays = ValueNotifier(
    defaultRememberDays,
  );

  /// Whether fingerprint quick unlock is enabled.
  static final ValueNotifier<bool> fingerprintEnabled = ValueNotifier(false);

  /// Boot session the biometric quick-unlock store was last written in.
  ///
  /// Used as a cheap pre-check on startup: when the device rebooted the
  /// biometric store is not read at all (reading it would pop a fingerprint
  /// prompt that cannot unlock anything), the master password is required.
  static final ValueNotifier<String?> quickUnlockBootId = ValueNotifier(null);

  /// Whether the vault selection page is shown on every app start.
  ///
  /// When disabled the app skips straight to reopening the last vault (same
  /// boot session: system password / remembered unlock; otherwise it falls
  /// back to the selection page for the master password).
  static final ValueNotifier<bool> showVaultStartPage = ValueNotifier(true);

  /// Whether the SSH agent serves vault keys to `ssh` while unlocked.
  static final ValueNotifier<bool> sshAgentEnabled = ValueNotifier(true);

  /// Whether the credential server serves usernames/passwords/TOTP to
  /// `openvalut-cli` while unlocked.
  static final ValueNotifier<bool> credentialServerEnabled = ValueNotifier(
    true,
  );

  /// Whether the app auto-provisions the current computer's two-step
  /// verification (vault entry + PAM TOTP) when a vault is open.
  static final ValueNotifier<bool> autoConfigureComputer2fa = ValueNotifier(
    false,
  );

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    rememberUnlockDays.value = prefs.getInt(_rememberDaysKey) ??
        defaultRememberDays;
    fingerprintEnabled.value = prefs.getBool(_fingerprintKey) ?? false;
    quickUnlockBootId.value = prefs.getString(_quickUnlockBootIdKey);
    showVaultStartPage.value =
        prefs.getBool(_showVaultStartPageKey) ?? true;
    sshAgentEnabled.value = prefs.getBool(_sshAgentEnabledKey) ?? true;
    credentialServerEnabled.value =
        prefs.getBool(_credentialServerEnabledKey) ?? true;
    autoConfigureComputer2fa.value =
        prefs.getBool(_autoConfigureComputer2faKey) ?? false;
  }

  static Future<void> setRememberUnlockDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_rememberDaysKey, days);
    rememberUnlockDays.value = days;
  }

  static Future<void> setFingerprintEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fingerprintKey, value);
    fingerprintEnabled.value = value;
  }

  static Future<void> setQuickUnlockBootId(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_quickUnlockBootIdKey);
    } else {
      await prefs.setString(_quickUnlockBootIdKey, value);
    }
    quickUnlockBootId.value = value;
  }

  static Future<void> setShowVaultStartPage(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showVaultStartPageKey, value);
    showVaultStartPage.value = value;
  }

  static Future<void> setSshAgentEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sshAgentEnabledKey, value);
    sshAgentEnabled.value = value;
  }

  static Future<void> setCredentialServerEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_credentialServerEnabledKey, value);
    credentialServerEnabled.value = value;
  }

  static Future<void> setAutoConfigureComputer2fa(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoConfigureComputer2faKey, value);
    autoConfigureComputer2fa.value = value;
  }
}
