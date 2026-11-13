// ignore_for_file: omit_local_variable_types,unused_local_variable

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sinhala Sinhalese (`si`).
class AppLocalizationsSi extends AppLocalizations {
  AppLocalizationsSi([String locale = 'si']) : super(locale);

  @override
  String get okAction => 'OK';

  @override
  String get cloudAuthEmailOrSecretInvalid =>
      'Email or Secret Key is incorrect. Please check and try again.';

  @override
  String get cloudEmailAlreadyRegistered =>
      'This email is already registered. Sign in instead.';

  @override
  String cloudConnectFailed(Object error) {
    return 'Could not connect to the OpenValut Cloud service: $error';
  }

  @override
  String get cloudNoVaultTitle => 'This account has no vault yet';

  @override
  String get cloudNoVaultBody =>
      'A vault is created automatically during registration. Sign out and register to create one.';

  @override
  String get cloudWrongMasterPassword =>
      'Wrong master password. Could not unlock the vault.';

  @override
  String get cloudDecryptFailedMasterPassword =>
      'Cloud data could not be decrypted: the master password may be incorrect.';

  @override
  String cloudScanCreateFailed(Object error) {
    return 'Could not create the sign-in QR code: $error';
  }

  @override
  String get cloudScanExpired => 'The QR code expired. Refresh and try again.';

  @override
  String cloudScanSessionInvalid(Object message) {
    return 'The sign-in session expired ($message). Refresh the QR code.';
  }

  @override
  String cloudScanWaitingPhone(Object error) {
    return 'Waiting for the phone to confirm ($error)';
  }

  @override
  String get cloudRegisterNoSecretKey =>
      'Registration failed: no Secret Key was returned';

  @override
  String get cloudSaveSecretKeyTitle => 'Save your Secret Key';

  @override
  String get cloudSecretKeyDescription =>
      'This is the unique identity key (account UUID) for your OpenValut Cloud account. Signing in requires email + Secret Key + master password. This key cannot be recovered, so copy it now and keep it safe; you can also skip this step.';

  @override
  String get cloudSaveToFileAction => 'Save to local file';

  @override
  String get cloudCopyAction => 'Copy';

  @override
  String get cloudSkipAction => 'Skip';

  @override
  String get cloudSavedContinueAction => 'I\'ve saved it — continue';

  @override
  String get cloudSavedTitle => 'Saved';

  @override
  String get cloudSavedToFileBody =>
      'Secret Key saved to a local file. Keep it safe.';

  @override
  String get cloudSaveFailedTitle => 'Save failed';

  @override
  String cloudSaveFailedBody(Object error) {
    return 'Could not save the Secret Key: $error';
  }

  @override
  String cloudAccountLabel(Object email) {
    return 'Account: $email';
  }

  @override
  String get cloudLoginRequiresNote =>
      'To sign in you need: email + Secret Key + master password';

  @override
  String get cloudSecretKeepSafeNote =>
      'This key cannot be recovered — keep it safe.';

  @override
  String get cloudRegisterTitle => 'Register an OpenValut Cloud account';

  @override
  String get cloudLoginTitle => 'Sign in to OpenValut Cloud';

  @override
  String get cloudRegisterIntro =>
      'Registration only needs an email. The vault master password is only used on this device for encryption and is never uploaded.';

  @override
  String get cloudLoginIntroDesktop =>
      'Enter email, Secret Key and master password, or scan with the mobile app.';

  @override
  String get cloudLoginIntro =>
      'Enter email, Secret Key and master password to sign in.';

  @override
  String get cloudServerUrlLabel => 'Server URL';

  @override
  String get cloudServerUrlHelp =>
      'A default server is preconfigured; you can point it to your own domain.';

  @override
  String get cloudServerUrlRequired => 'Enter the server URL';

  @override
  String get cloudServerUrlInvalid =>
      'Server URL must start with http:// or https://';

  @override
  String get cloudEmailLabel => 'Email';

  @override
  String get cloudEmailRequired => 'Enter your email';

  @override
  String get cloudEmailNoSpaces => 'Email must not contain spaces';

  @override
  String get cloudEmailInvalid => 'Enter a valid email address';

  @override
  String get cloudSecretKeyLabel =>
      'Secret Key (the UUID saved at registration)';

  @override
  String get cloudSecretKeyRequired => 'Enter your Secret Key';

  @override
  String get cloudSecretKeyChars =>
      'Secret Key may only contain hex characters and - separators';

  @override
  String get cloudSecretKeyLength => 'Secret Key should be 32 hex characters';

  @override
  String get cloudMasterPasswordLabel => 'Vault master password';

  @override
  String get cloudMasterPasswordRequired => 'Enter the vault master password';

  @override
  String get cloudPasswordNoSpaces => 'Password must not contain spaces';

  @override
  String get cloudVaultNameLabel => 'Vault name';

  @override
  String get cloudVaultNameRequired => 'Enter a vault name';

  @override
  String get cloudVaultNameNoLeadingDigit => 'Name must not start with a digit';

  @override
  String get cloudVaultNameChars =>
      'Name may only contain Chinese, English letters and digits';

  @override
  String get cloudMasterPasswordMin6 =>
      'Master password must be at least 6 characters';

  @override
  String get cloudConfirmMasterPasswordLabel => 'Confirm master password';

  @override
  String get cloudPasswordMismatch => 'The two passwords do not match';

  @override
  String get cloudRegisterSubmit => 'Register and create vault';

  @override
  String get cloudLoginSubmit => 'Sign in';

  @override
  String get cloudSwitchToLogin => 'Already have an account? Sign in';

  @override
  String get cloudSwitchToRegister => 'No account? Register one';

  @override
  String get cloudUseQrLogin => 'Scan with the mobile app to sign in';

  @override
  String cloudServerInfo(Object server) {
    return 'Server: $server';
  }

  @override
  String get cloudQrLoginTitle => 'Scan to sign in to OpenValut Cloud';

  @override
  String get cloudQrLoginDescription =>
      'Use the mobile app signed in to OpenValut Cloud to scan the QR code below and confirm sign-in.';

  @override
  String get cloudScanWaiting => 'Waiting for the phone to confirm…';

  @override
  String get cloudRefreshQr => 'Refresh QR code';

  @override
  String get cloudBackToManual => 'Back to manual entry';

  @override
  String get myShareReceiveTitle => 'Receive share';

  @override
  String get myShareReceiveNeedVault =>
      'Open or create an OpenValut Cloud vault first to receive shares.';

  @override
  String myShareAutoSavedCount(Object count) {
    return 'Auto-saved $count shared entries into the vault';
  }

  @override
  String get myShareRevokeTitle => 'Revoke share';

  @override
  String myShareRevokeConfirm(Object entry) {
    return 'Revoke the share of \"$entry\"? The recipient will no longer be able to view it.';
  }

  @override
  String get myShareRevokeAction => 'Revoke';

  @override
  String get myShareRevokeFailed => 'Failed to revoke';

  @override
  String get myShareUrlField => 'URL';

  @override
  String get myShareNotesField => 'Notes';

  @override
  String get myShareUntitledEntry => 'Unnamed entry';

  @override
  String myShareFromOwner(Object owner) {
    return 'From $owner';
  }

  @override
  String myShareOutgoingSubtitle(Object date, Object recipient) {
    return 'Shared with $recipient · $date';
  }

  @override
  String myShareIncomingSubtitle(Object date, Object owner) {
    return 'From $owner · $date';
  }

  @override
  String myShareCopyFieldTooltip(Object field) {
    return 'Copy $field';
  }

  @override
  String myShareCopiedField(Object field) {
    return 'Copied $field';
  }

  @override
  String get myShareDeleteTitle => 'Delete share';

  @override
  String get myShareDeleteConfirm => 'Delete this share?';

  @override
  String get myShareDeleteFailed => 'Failed to delete';

  @override
  String get mySharesTitle => 'My shares';

  @override
  String get mySharesNeedLogin => 'Sign in to OpenValut Cloud first';

  @override
  String get mySharesRefresh => 'Refresh';

  @override
  String mySharesLoadFailed(Object error) {
    return 'Failed to load shares: $error';
  }

  @override
  String get mySharesEmpty => 'No shares yet';

  @override
  String get mySharesByMe => 'Shared by me';

  @override
  String get mySharesToMe => 'Shared with me';

  @override
  String get myShareDeletedEntry => 'Deleted entry';

  @override
  String get myShareGroupBadge => 'Group';

  @override
  String myShareGroupSubtitle(Object count, Object date, Object owner) {
    return 'Group · $count entries · From $owner · $date';
  }

  @override
  String get myShareGroupSyncAction => 'Sync to my vault';

  @override
  String myShareGroupSyncedCount(Object count) {
    return 'Synced $count group shares to the vault';
  }

  @override
  String get myShareGroupEmpty => 'This group share has no entries yet.';

  @override
  String get importUntitledEntry => 'Unnamed entry';

  @override
  String importReadFailed(Object error) {
    return 'Failed to read: $error';
  }

  @override
  String get importCsvEmptyOrInvalid =>
      'The CSV file is empty or has an invalid format';

  @override
  String get importPasswordWrongTitle => 'Wrong password';

  @override
  String get importPasswordWrongBody =>
      'Wrong KDBX file password. Please try again.';

  @override
  String get importNeedCloudVault => 'Open an OpenValut Cloud vault first';

  @override
  String get importReadonlyVaultWarning =>
      'This vault was opened with a remembered key (read-only). Lock the app, reopen the vault with the master password, then import again.';

  @override
  String get importKdbxPasswordTitle => 'Enter KDBX file password';

  @override
  String importPasswordLabelForFile(Object fileName) {
    return 'Password ($fileName)';
  }

  @override
  String importDoneCount(Object count) {
    return 'Imported $count entries';
  }

  @override
  String importFailed(Object error) {
    return 'Import failed: $error';
  }

  @override
  String get importReselectAction => 'Choose again';

  @override
  String get importSourcePickerIntro =>
      'Choose a source. After reading it, select the entries to import into the currently open OpenValut Cloud vault.';

  @override
  String get importSource1PasswordCsvSubtitle =>
      'CSV file exported from 1Password';

  @override
  String get importSourceKdbxTitle => 'KDBX file';

  @override
  String get importSourceKdbxSubtitle =>
      '.kdbx exported from KeePass or other vaults';

  @override
  String get importReadingEllipsis => 'Reading…';

  @override
  String get importSelectFileAndRead => 'Choose file and read';

  @override
  String importSelectAllCount(Object count) {
    return 'Select all ($count entries)';
  }

  @override
  String importSelectedCount(Object count) {
    return '$count selected';
  }

  @override
  String get importImportingEllipsis => 'Importing…';

  @override
  String importImportSelectedCount(Object count) {
    return 'Import the $count selected entries';
  }

  @override
  String get fieldNotesLabel => 'Notes';

  @override
  String get masterChangeLockedFirst =>
      'Lock the vault and reopen it with the master password before changing it.';

  @override
  String get scanLoginNeedAccount =>
      'Sign in to your OpenValut Cloud account first, then use scan-to-sign-in.';

  @override
  String get scanLoginNotOpenvalutQr =>
      'Not an OpenValut sign-in QR code. Scan the QR code shown on the PC sign-in page.';

  @override
  String get scanLoginConfirmedNoKey =>
      'Confirmed. The PC will sign in automatically (no master password was sent; enter it on the PC).';

  @override
  String get scanLoginConfirmedUnlock =>
      'Confirmed. The PC will sign in and unlock the vault automatically.';

  @override
  String scanLoginConfirmFailed(Object error) {
    return 'Confirmation failed: $error';
  }

  @override
  String get scanLoginEnterMasterTitle => 'Enter the vault master password';

  @override
  String get scanLoginMasterLabel => 'Master password';

  @override
  String get scanLoginMasterHint => 'Used to authorize direct unlock on the PC';

  @override
  String get pickerSearchHint => 'Search app name or package';

  @override
  String get pickerNoMatchingApps => 'No matching apps found';

  @override
  String get twoFactorNoOpenVault => 'No vault is open';

  @override
  String get twoFactorNoUsername =>
      'Could not determine the current system username';

  @override
  String get twoFactorNoMachineId =>
      'Could not determine this computer\'s identifier';

  @override
  String get twoFactorEmptySudoPassword => 'sudo password cannot be empty';

  @override
  String get twoFactorTotpFileWriteFailed =>
      'Could not write the encrypted TOTP file (missing machine-id or home directory)';

  @override
  String twoFactorSystemSetupIncomplete(Object detail) {
    return 'System setup incomplete: $detail';
  }

  @override
  String get twoFactorConfiguredDone =>
      'Two-step verification for this computer is configured; sudo will now ask for a one-time code.';

  @override
  String twoFactorConfigFailed(Object error) {
    return 'Configuration failed: $error';
  }

  @override
  String get twoFactorIdentityMissing =>
      'Could not determine username/home directory/computer identifier';

  @override
  String get twoFactorUserCancelled =>
      'User cancelled or authentication failed';

  @override
  String twoFactorTotpFileDeleteFailed(Object localError, Object systemError) {
    return 'Could not delete the TOTP file ($localError), and system cleanup failed ($systemError)';
  }

  @override
  String get twoFactorDisabledPamFailed =>
      'Two-step verification is off (sudo no longer asks for a code), but the PAM line in /etc/pam.d/sudo could not be removed.';

  @override
  String get twoFactorDisabledDone =>
      'System two-step verification is off; sudo no longer asks for a one-time code.';

  @override
  String twoFactorAssetReadFailed(Object error) {
    return 'Could not read the bundled PAM module/askpass file: $error';
  }

  @override
  String twoFactorPkexecFailed(Object code, Object message) {
    return 'pkexec did not complete (exit code $code): $message';
  }

  @override
  String get sshKeysAlreadyImported =>
      'These SSH keys are already in the vault; no need to import them again.';

  @override
  String get sshSkippedAlreadyImported => 'Already imported, skipped';

  @override
  String get openFileFailedLabel => 'Failed to open file';

  @override
  String get untitledLabel => 'Unnamed';

  @override
  String get trayShowOpenvalut => 'Show OpenValut';

  @override
  String get trayQuit => 'Quit';

  @override
  String get appAlreadyRunningMessage =>
      'OpenValut is already running (it may be minimized to the tray). Right-click the tray icon and choose Quit, then try again.';

  @override
  String get lockedChooseAnotherVault => 'Choose another vault';

  @override
  String get offlineBannerTitle => 'You are currently offline';

  @override
  String get selectFileOpenLocalFile => 'Open local file';

  @override
  String get enableFingerprintQuestion => 'Enable fingerprint authentication?';

  @override
  String get enableFingerprintDescription =>
      'Once enabled, you can unlock vaults with your fingerprint instead of entering the master password.';

  @override
  String get enableFingerprintAction => 'Enable';

  @override
  String get cloudUnlockFailedTitle => 'Could not unlock the cloud vault';

  @override
  String get cloudUnlockFailedDescription =>
      'Cloud data could not be decrypted: the master password may be wrong, or the vault was created on another device with a different master password.';

  @override
  String get menuImportPasswords => 'Import passwords';

  @override
  String get menuExportCsv => 'Export CSV';

  @override
  String get menuScanLogin => 'Scan code to sign in';

  @override
  String get menuAboutOpenvalut => 'About OpenValut';

  @override
  String get menuAbout => 'About';

  @override
  String get menuAuthorName => 'OpenValut Contributors';

  @override
  String get menuEmailPrefix => 'Email: ';

  @override
  String get menuBlogPrefix => 'Blog: ';

  @override
  String get menuExportedCsvTitle => 'Exported';

  @override
  String get menuExportedAllCsv => 'All entries were exported as CSV.';

  @override
  String get menuExportFailedTitle => 'Export failed';

  @override
  String get copyUsernameAction => 'Copy username';

  @override
  String get renameEntryDialogTitle => 'Rename entry';

  @override
  String get newNameFieldLabel => 'New name';

  @override
  String get restoredSnack => 'Restored';

  @override
  String get deletedSnack => 'Deleted';

  @override
  String get undoAction => 'Undo';

  @override
  String get shareWithFamilyTitle => 'Share with family';

  @override
  String get shareRecipientEmailLabel => 'Recipient\'s OpenValut Cloud email';

  @override
  String get shareRecipientEmailHint => 'e.g. family@example.com';

  @override
  String get shareTargetLoginRequired =>
      'Please sign in to OpenValut Cloud first (Select Vault screen → OpenValut Cloud).';

  @override
  String get shareRequiresCloudVault =>
      'Only entries in an OpenValut Cloud vault can be shared.';

  @override
  String sharedToRecipient(Object recipient) {
    return 'Shared with $recipient';
  }

  @override
  String shareUserNotFound(Object recipient) {
    return 'Could not find user $recipient. Make sure they registered and signed in to OpenValut Cloud.';
  }

  @override
  String get shareFailed => 'Share failed';

  @override
  String shareFailedDetail(Object detail) {
    return 'Sharing failed: $detail';
  }

  @override
  String get shareGroupTitle => 'Share whole group';

  @override
  String get shareGroupActionLabel => 'Share whole group…';

  @override
  String get shareGroupRequiresCloudVault =>
      'Only groups in an OpenValut Cloud vault can be shared as a whole group.';

  @override
  String get shareGroupSelfNotAllowed =>
      'You cannot share a group with yourself.';

  @override
  String get shareGroupRecipientRequired =>
      'Enter the recipient\'s OpenValut Cloud email.';

  @override
  String shareGroupAlreadyShared(Object recipient) {
    return 'This group is already shared with $recipient.';
  }

  @override
  String sharedGroupToRecipient(Object group, Object recipient) {
    return 'Shared group \"$group\" with $recipient. Future changes stay in sync automatically.';
  }

  @override
  String get drawerAllEntries => 'All';

  @override
  String get drawerRecycleBin => 'Recycle bin';

  @override
  String get drawerMyShares => 'My shares';

  @override
  String get drawerGroupNameLabel => 'Group name';

  @override
  String get renameGroupDialogTitle => 'Rename group';

  @override
  String get cliReadAllowTitle => 'Allow CLI/script read access';

  @override
  String get cliReadAllowSubtitle =>
      'Entries in this group (including subgroups) are hidden from CLI/scripts by default. Allow all of them now.';

  @override
  String get cliReadDenyTitle => 'Deny CLI/script read access';

  @override
  String get cliReadDenySubtitle =>
      'Restore the default: entries in this group are hidden from CLI/scripts.';

  @override
  String get cliReadGroupAllAllowed =>
      'All entries in this group are now readable by CLI/scripts';

  @override
  String cliReadGroupAllowedCount(Object count) {
    return 'Allowed $count entries to be read by CLI/scripts (takes effect after saving)';
  }

  @override
  String get cliReadGroupAllDenied =>
      'All entries in this group are now hidden from CLI/scripts';

  @override
  String cliReadGroupDeniedCount(Object count) {
    return 'Denied CLI/script access to $count entries (takes effect after saving)';
  }

  @override
  String get organizeByCategoryTitle => 'Organize by category';

  @override
  String get organizeByCategoryDescription =>
      'Move root-level entries into Website / App / Other / Finance groups (created automatically if missing), then save to the server. Continue?';

  @override
  String get organizeAction => 'Organize';

  @override
  String organizeDoneCount(Object count) {
    return 'Organized $count entries';
  }

  @override
  String get groupListNewGroup => 'New group';

  @override
  String get weakPasswordsLabel => 'Weak passwords';

  @override
  String get allowCliRead => 'Allow CLI/script read access';

  @override
  String get denyCliRead => 'Deny CLI/script read access';

  @override
  String get entryAllowCliRead => 'Allow CLI/script read access';

  @override
  String get entryAllowCliReadDescription =>
      'Read access is denied by default. Enabling it lets openvalut-cli list/get and the local credential service read this entry.';

  @override
  String get entryAddWebsite => 'Add website';

  @override
  String get entryAddAttachment => 'ඇමුණුම එකතු කරන්න';

  @override
  String get entryAddSpecialField => 'Add field';

  @override
  String entryPasswordExpired(Object days) {
    return 'This password expired $days days ago. Change it soon.';
  }

  @override
  String entryPasswordExpires(Object remaining) {
    return 'This password expires in $remaining days. Change it soon.';
  }

  @override
  String get entryLinkApp => 'Associated app';

  @override
  String entryTargetWebsite(Object number) {
    return 'Target website $number';
  }

  @override
  String get entryPickAppTooltip => 'Choose the app to associate';

  @override
  String entryPasteReference(Object reference) {
    return 'Copied reference: $reference';
  }

  @override
  String get entryCopyReferenceTitle => 'Copy reference';

  @override
  String masterPasswordExpiredBanner(Object days) {
    return 'The master password expired $days days ago. Change it soon.';
  }

  @override
  String masterPasswordExpiresBanner(Object remaining) {
    return 'The master password expires in $remaining days. Change it soon.';
  }

  @override
  String get changeMasterPasswordAction => 'Change master password';

  @override
  String get remindLaterAction => 'Remind me later';

  @override
  String get prefDisablingSystem2fa =>
      'Disabling system two-step verification…';

  @override
  String get prefTwoFactorDisabled => 'Disabled';

  @override
  String get prefTwoFactorDisableFailed => 'Failed to disable';

  @override
  String get prefNeedUnlockedVaultForAutoConfig =>
      'Open and unlock a vault first, then enable automatic setup.';

  @override
  String get prefConfiguringSystem2fa =>
      'Configuring two-step verification for this computer…';

  @override
  String get prefTwoFactorConfigured => 'Setup complete';

  @override
  String get prefTwoFactorConfigFailed => 'Setup failed';

  @override
  String get prefSystemPasswordDialogTitle => 'Enter system login password';

  @override
  String get prefSudoPasswordLabel => 'sudo password';

  @override
  String get prefSudoPasswordHelper =>
      'Used to save a Computer entry and protect two-step verification';

  @override
  String get prefRememberMasterPasswordTitle => 'Remember master password';

  @override
  String get prefRememberOffEveryLogin =>
      'Off (enter the master password each time)';

  @override
  String prefDaysPlaceholder(Object days) {
    return '$days days';
  }

  @override
  String get prefCloudServiceNotConfigured =>
      'OpenValut Cloud service is not configured';

  @override
  String get prefUpToDate => 'You are up to date';

  @override
  String prefNewVersionAvailableTitle(Object versionName) {
    return 'New version $versionName available';
  }

  @override
  String get prefUpdateNowQuestion => 'A new version is available. Update now?';

  @override
  String get prefUpdateLaterAction => 'Later';

  @override
  String get prefUpdateNowAction => 'Update now';

  @override
  String get prefNewVersionDownloadedTitle => 'New version downloaded';

  @override
  String prefInstallManuallyBody(Object installHint, Object path) {
    return 'Installer saved to:\n$path\n\nInstall it manually from that folder.\nLinux example:\n$installHint';
  }

  @override
  String get prefGotItAction => 'Got it';

  @override
  String prefUpdateCheckFailedTitle(Object error) {
    return 'Failed to check for updates: $error';
  }

  @override
  String get prefClipboardAutoClearTitle => 'Clear clipboard automatically';

  @override
  String get prefClipboardAutoClearSubtitle =>
      'Clear the system clipboard after copying a password or username';

  @override
  String get prefOff => 'Off';

  @override
  String prefSecondsPlaceholder(Object seconds) {
    return '$seconds seconds';
  }

  @override
  String get prefZeroDisablesAutoClear => '0 disables automatic clearing';

  @override
  String get prefCloseWindowTitle => 'When closing the window';

  @override
  String get prefCloseWindowSubtitle => 'Choose what the close button does';

  @override
  String get prefHideToTrayRunning => 'Hide to tray (app keeps running)';

  @override
  String get prefMinimizeToTaskbarRunning =>
      'Minimize to taskbar (app keeps running)';

  @override
  String get prefQuitApplication => 'Quit app';

  @override
  String get prefHideToTray => 'Hide to tray';

  @override
  String get prefMinimizeToTaskbar => 'Minimize to taskbar';

  @override
  String get prefSshConfigAppendPreview =>
      'Appending to the end of ~/.ssh/config:\n\n';

  @override
  String get prefNotEnabledStatus => 'Not enabled';

  @override
  String prefReminderNoChangeDate(Object days) {
    return 'Remind every $days days (no change date recorded yet)';
  }

  @override
  String prefReminderExpired(Object days) {
    return 'Expired $days days ago — change it soon';
  }

  @override
  String prefReminderEvery(Object days, Object remaining) {
    return 'Remind every $days days, $remaining days left';
  }

  @override
  String get prefLoadingEllipsis => 'Loading…';

  @override
  String get prefAlwaysShowSidePanel => 'Always show side panel';

  @override
  String get prefAlwaysShowSidePanelSubtitle =>
      'Keep the category panel visible; when off it collapses when you click elsewhere';

  @override
  String get prefCheckForUpdatesSubtitle =>
      'Check for and download new OpenValut Cloud releases';

  @override
  String get prefRememberMasterPasswordSubtitle =>
      'Open vaults without re-entering the master password during this period';

  @override
  String get prefStartAtLogin => 'Start on login';

  @override
  String get prefStartAtLoginSubtitle =>
      'Start OpenValut and hide it to the tray after login';

  @override
  String get prefFingerprintUnlock => 'Unlock with fingerprint';

  @override
  String get prefFingerprintUnlockSubtitle =>
      'Use a fingerprint to unlock quickly without the master password';

  @override
  String get prefAutoTwoFactorTitle =>
      'Automatically configure two-step verification';

  @override
  String get prefAutoTwoFactorSubtitle =>
      'Saves this computer\'s username/password/TOTP and configures two-step verification for sudo (PAM module, askpass and /etc/pam.d/sudo)';

  @override
  String get prefImportSshSubtitle =>
      'Import private keys from ~/.ssh into the vault and mark them for this computer';

  @override
  String prefImportedSshKeys(Object count) {
    return 'Imported $count SSH keys';
  }

  @override
  String get prefPasswordChangeReminderTitle => 'Password change reminder';

  @override
  String get fieldUserName => 'පරිශීලක';

  @override
  String get fieldPassword => 'මුරපදය';

  @override
  String get fieldWebsite => 'වියමන අඩවිය';

  @override
  String get fieldTitle => 'මාතෘකාව';

  @override
  String get fieldTotp => 'One Time Password (Time Based)';

  @override
  String get english => 'ඉංග්‍රීසි';

  @override
  String get german => 'ජර්මානු';

  @override
  String get russian => 'රුසියානු';

  @override
  String get ukrainian => 'Ukrainian';

  @override
  String get lithuanian => 'Lithuanian';

  @override
  String get french => 'ප්‍රංශ';

  @override
  String get spanish => 'ස්පාඤ්ඤ';

  @override
  String get indonesian => 'ඉන්දුනීසියානු';

  @override
  String get turkish => 'තුර්කි';

  @override
  String get hebrew => 'Hebrew';

  @override
  String get italian => 'ඉතාලි';

  @override
  String get chineseSimplified => 'සරල චීන';

  @override
  String get chineseTraditional => 'සාම්ප්‍රදායික චීන';

  @override
  String get portugueseBrazilian => 'Portuguese, Brazilian';

  @override
  String get slovak => 'Slovak';

  @override
  String get dutch => 'Dutch';

  @override
  String get selectItem => 'තෝරන්න';

  @override
  String get selectKeepassFile => 'OpenValut - Select KeePass File';

  @override
  String get selectKeepassFileLabel => 'Please select a KeePass (.kdbx) file.';

  @override
  String get createNewFile => 'නව ගොනුවක් සාදන්න';

  @override
  String get openLocalFile => 'ස්ථානීය ගොනුවක් \nවිවෘත කරන්න';

  @override
  String get openFile => 'ගොනුව විවෘත කරන්න';

  @override
  String get loadFromDropdownMenu => 'Load from …';

  @override
  String get quickUnlockingFiles => 'Quick unlocking files …';

  @override
  String openFileProgress(Object fileName, Object current, Object totalCount) {
    return 'Opening $fileName … ($current / $totalCount)';
  }

  @override
  String loadFrom(String cloudStorageName) {
    return '$cloudStorageName වෙතින් පුරන්න';
  }

  @override
  String get loadFromRemoteUrl => 'Open kdbx from URL';

  @override
  String get createNewKeepass =>
      'New to KeePass?\nCreate New Password Database';

  @override
  String get labelLastOpenFiles => 'අවසන්වරට විවෘත කළ ගොනු:';

  @override
  String get noFilesHaveBeenOpenYet => 'No files have been opened yet.';

  @override
  String get preferenceSelectLanguage => 'භාෂාව තෝරන්න';

  @override
  String get preferenceLanguage => 'භාෂාව';

  @override
  String get preferenceTextScaleFactor => 'Text Scale Factor';

  @override
  String get preferenceVisualDensity => 'Visual Density';

  @override
  String get preferenceTheme => 'තේමාව';

  @override
  String get preferenceThemeLight => 'දීප්ත';

  @override
  String get preferenceThemeDark => 'අඳුරු';

  @override
  String get preferenceSystemDefault => 'පද්ධතියේ පෙරනිමි';

  @override
  String get preferenceDefault => 'පෙරනිමි';

  @override
  String get lockAllFiles => 'සියලුම විවෘත ගොනු අගුලුලන්න';

  @override
  String get preferenceAllowScreenshots => 'Allow Screenshots of the App';

  @override
  String get preferenceEnableAutoFill => 'Enable autofill';

  @override
  String get enableAutofillSuggestionBanner =>
      'You can you can fill field of other application by enabling autofill!';

  @override
  String get dismissAutofillSuggestionBannerButton => 'DISMISS';

  @override
  String get enableAutofillSuggestionBannerButton => 'ENABLE!';

  @override
  String get preferenceAutoFillDescription =>
      'Only supported on Android Oreo (8.0) or later.';

  @override
  String get preferenceTitle => 'අභිප්‍රේත';

  @override
  String get preferenceEnableSystemWideShortcuts =>
      'Enable system wide shortcuts';

  @override
  String get preferenceEnableSystemWideShortcutsHelp =>
      'Registers ctrl+alt+f as system wide shortcut to open search.';

  @override
  String get preferencesSearchFields => 'Customize Search fields';

  @override
  String get preferencesSearchFieldPromptTitle => 'Search fields';

  @override
  String get preferencesSearchFieldPromptLabel =>
      'Comma separated list of fields to use in the password list search.';

  @override
  String preferencesSearchFieldPromptHelp(
    Object wildCardCharacter,
    Object defaultSearchFields,
  ) {
    return 'Use $wildCardCharacter for all, leave empty for default ($defaultSearchFields)';
  }

  @override
  String get aboutAppName => 'OpenValut';

  @override
  String get aboutLinkFeedback => 'We welcome any kind of feedback!';

  @override
  String get aboutLinkVisitWebsite => 'Also make sure to visit our website';

  @override
  String get aboutLinkGitHub => 'සහ විවෘත මූලාශ්‍ර ව්‍යාපෘතියකි';

  @override
  String aboutLogFile(String logFilePath) {
    return 'Log File: $logFilePath';
  }

  @override
  String get aboutLinkContributors => 'Show Contributors';

  @override
  String get unableToLaunchUrlTitle => 'Unable to open Url';

  @override
  String unableToLaunchUrlDescription(Object url, Object openError) {
    return 'Unable to launch $url: $openError';
  }

  @override
  String get unableToLaunchUrlNoHandler => 'No application available for url.';

  @override
  String launchedUrl(Object url) {
    return 'විවෘත කළ ඒ.ස.නි.: $url';
  }

  @override
  String get menuItemGeneratePassword => 'Generate Password';

  @override
  String get menuItemPreferences => 'අභිප්‍රේත';

  @override
  String get menuItemOpenAnotherFile => 'Open another File';

  @override
  String get menuItemCheckForUpdates => 'Check for updates';

  @override
  String get menuItemSupport => 'සටහන් යවන්න';

  @override
  String get menuItemSupportSubtitle => 'Send logs by email';

  @override
  String get menuItemForum => 'සහාය සංසදය';

  @override
  String get menuItemForumSubtitle => 'Report Problems and get help';

  @override
  String get menuItemHelp => 'උදව්';

  @override
  String get menuItemHelpSubtitle => 'Show documentation';

  @override
  String get menuItemAbout => 'පිළිබඳව';

  @override
  String get actionOpenUrl => 'Open URL';

  @override
  String get passwordPlainText => 'Reveal password';

  @override
  String get generatorPassword => 'මුරපදය';

  @override
  String get generatePassword => 'Generate Password';

  @override
  String get doneButtonLabel => 'අවසන්';

  @override
  String get useAsDefault => 'Use as Default';

  @override
  String get characterSetLowerCase => 'Lowercase (a-z)';

  @override
  String get characterSetUpperCase => 'Uppercase (A-Z)';

  @override
  String get characterSetNumeric => 'Numeric (0-9)';

  @override
  String get characterSetUmlauts => 'Umlauts (ä)';

  @override
  String get characterSetSpecial => 'විශේෂ (@%+)';

  @override
  String get length => 'Length';

  @override
  String get customLength => 'Custom Length';

  @override
  String customLengthHelperText(Object customMinLength) {
    return 'Only used for length > $customMinLength';
  }

  @override
  String savedFiles(int numFiles, Object files) {
    final intl.NumberFormat numFilesNumberFormat =
        intl.NumberFormat.compactLong(
          locale: localeName,
        );
    final String numFilesString = numFilesNumberFormat.format(numFiles);

    String _temp0 = intl.Intl.pluralLogic(
      numFiles,
      locale: localeName,
      other: '$numFilesString files saved: $files',
      one: 'One file saved: $files',
    );
    return '$_temp0';
  }

  @override
  String get manageGroups => 'Manage Groups';

  @override
  String get lockFiles => 'Lock Files';

  @override
  String get searchHint => 'සොයන්න';

  @override
  String get searchButtonLabel => 'සොයන්න';

  @override
  String get filterButtonLabel => 'සමූහය අනුව පෙරන්න';

  @override
  String get clear => 'හිස් කරන්න';

  @override
  String get autofillFilterPrefix => 'පෙරහන:';

  @override
  String get autofillMatchPrefix => 'Matching entries for:';

  @override
  String get autofillPrompt => 'Select password entry for autofill.';

  @override
  String get autofillNoMatches => 'No matching entries found for this page.';

  @override
  String get autofillNoOpenVault =>
      'No unlocked password database. Open one in OpenValut first, then return to the browser and trigger autofill again.';

  @override
  String get androidAutofillSection => 'Android autofill';

  @override
  String get prefAutofillIgnoredAppsTitle => 'Never autofill in these apps';

  @override
  String get prefAutofillIgnoredAppsSubtitle =>
      'OpenValut offers nothing in the selected apps, even when they show a password or a verification-code field. Login pages a web view hosts inside such an app are silenced too. The keyboard\'s autofill key stays where it is — tapping it just yields nothing.';

  @override
  String get prefAutofillIgnoredAppsNone => 'None';

  @override
  String prefAutofillIgnoredAppsCount(int count) {
    return '$count apps';
  }

  @override
  String get prefAutofillIgnoredAppsPickerTitle => 'Apps to ignore';

  @override
  String get prefAutofillIgnoredAppsDone => 'Done';

  @override
  String get prefAutofillIgnoredAppsRemoveAll => 'Remove all';

  @override
  String get prefAutofillIgnoreBrowserTitle => 'Ignore this browser?';

  @override
  String prefAutofillIgnoreBrowserBody(String app) {
    return '$app is a browser: while it is ignored, OpenValut will not fill any website in it. This is usually not what you want.';
  }

  @override
  String get prefAutofillIgnoreBrowserConfirm => 'Ignore anyway';

  @override
  String get showVaultStartPage => 'Show this page every time OpenValut opens';

  @override
  String get securityCategoryLabel => 'Security';

  @override
  String get weakPasswordsEmpty => 'No weak passwords detected. Nice.';

  @override
  String get generateSshKeyPair => 'Generate SSH key pair';

  @override
  String get sshKeyNameLabel => 'Key name';

  @override
  String get sshKeyGenerated => 'SSH key pair generated';

  @override
  String get sshKeyGenerationFailedTitle => 'SSH key generation failed';

  @override
  String get sshKeysGroupName => 'SSH Keys';

  @override
  String get fieldSshPrivateKey => 'SSH private key';

  @override
  String get fieldSshPublicKey => 'SSH public key';

  @override
  String get fieldSshPort => 'SSH port';

  @override
  String get fieldAccessKey => 'Access Key ID';

  @override
  String get fieldSecretKey => 'Secret Access Key';

  @override
  String get entryAddAkskCredential => 'AK/SK credential';

  @override
  String get addSpecialField => 'Add field';

  @override
  String get addTotpField => 'One-time password';

  @override
  String get totpSecretPromptTitle => 'Add one-time password';

  @override
  String get totpSecretPromptLabel => 'otpauth:// link or base32 secret';

  @override
  String get localServicesSection => 'Local services';

  @override
  String get sshAgentSetting => 'SSH Agent';

  @override
  String get sshAgentSettingHelp =>
      'While the vault is unlocked, ssh can use vault keys through IdentityAgent. No private key ever touches disk.';

  @override
  String get credentialServerSetting => 'Credential server (openvalut-cli)';

  @override
  String get credentialServerSettingHelp =>
      'While the vault is unlocked, openvalut-cli can read usernames, passwords and TOTP codes.';

  @override
  String get importSshKeys => 'Import local SSH keys';

  @override
  String get importSshKeysNoneFound =>
      'No importable SSH keys were found in ~/.ssh.';

  @override
  String get importButton => 'Import';

  @override
  String get importSshKeysDeleteTitle => 'Delete the local originals?';

  @override
  String get importSshKeysDeleteBody =>
      'The keys were imported into the vault. Delete the original files under ~/.ssh? After deletion they are only usable through the SSH Agent while the vault is unlocked.';

  @override
  String get keep => 'Keep';

  @override
  String get delete => 'Delete';

  @override
  String get sshConfigSnippet => 'SSH config';

  @override
  String get writeSshConfig => 'Write to ~/.ssh/config';

  @override
  String get writeSshConfigDone => 'SSH config updated.';

  @override
  String get sshConfigExternalIdentityAgent =>
      'Found an existing IdentityAgent in ~/.ssh/config. ssh uses the first matching value, so the OpenValut reference may not take effect.';

  @override
  String get sshConfigRemoved =>
      'Removed the OpenValut SSH Agent reference from ~/.ssh/config.';

  @override
  String get sshConfigAlreadyPresent =>
      'The OpenValut SSH Agent reference is already present.';

  @override
  String get copiedToClipboard => 'Copied to clipboard.';

  @override
  String get noTitle => '(මාතෘකාවක් නැත)';

  @override
  String get noUsername => '(පරිශීලක නාමයක් නැත)';

  @override
  String get filterCustomize => 'රිසිකරණය …';

  @override
  String get swipeCopyPassword => 'මුරපදය පිටපත්';

  @override
  String get swipeCopyUsername => 'පරිශීලක නාමය පිටපත්';

  @override
  String get copyUsernameNotExists => 'Entry has no username defined.';

  @override
  String get copyPasswordNotExists => 'Entry has no password defined.';

  @override
  String get doneCopiedPassword => 'Copied password to clipboard.';

  @override
  String get doneCopiedUsername => 'Copied username to clipboard.';

  @override
  String get doneCopiedField => 'Copied.';

  @override
  String copiedFieldToClipboard(Object fieldName) {
    return '$fieldName copied.';
  }

  @override
  String copiedFieldEmpty(Object fieldName) {
    return '$fieldName is empty.';
  }

  @override
  String get emptyPasswordVaultPlaceholder =>
      'You do not have any password in your database yet.';

  @override
  String get emptyPasswordVaultButtonLabel => 'ඔබගේ පළමු මුරපදය සාදන්න';

  @override
  String get loading => 'පූරණය වෙමින්';

  @override
  String get loadingFile => 'ගොනුව පූරණය වෙමින්…';

  @override
  String get internalFile => 'අභ්‍යන්තර ගොනුව';

  @override
  String get internalFileSubtitle =>
      'Database previously created with OpenValut';

  @override
  String get filePicker => 'File Picker';

  @override
  String get filePickerSubtitle => 'Open file from the device.';

  @override
  String get credentialsAppBarTitle => 'අක්තපත්‍ර';

  @override
  String get credentialLabel => 'Enter the password for:';

  @override
  String get masterPasswordInputLabel => 'මුරපදය';

  @override
  String get masterPasswordEmptyValidator => 'ඔබගේ මුරපදය ඇතුළත් කරන්න.';

  @override
  String get masterPasswordIncorrectValidator => 'වලංගු නොවන මුරපදයකි';

  @override
  String get useKeyFile => 'යතුරු ගොනුව භාවිතා කරන්න';

  @override
  String get saveMasterPasswordBiometric =>
      'Save Password with biometric key store?';

  @override
  String get close => 'වසන්න';

  @override
  String get addNewPassword => 'නව මුරපදයක් එකතු කරන්න';

  @override
  String get errorOpenFileInvalidFileStructureTitle =>
      'Tried to open invalid file type';

  @override
  String errorOpenFileInvalidFileStructureBody(Object fileName) {
    return 'The file ($fileName) does not appear to be a valid KDBX file. Please either choose a valid KDBX file or create a new password database.';
  }

  @override
  String get errorOpenFileAlreadyOpenTitle => 'ගොනුව දැනටමත් විවෘතයි';

  @override
  String errorOpenFileAlreadyOpenBody(
    Object databaseName,
    Object openFileSource,
    Object newFileSource,
  ) {
    return 'The selected database $databaseName is already open from $openFileSource (Tried to open from $newFileSource)';
  }

  @override
  String get loadFromUrl => 'ඒ.ස.නි. වෙතින් බාගන්න';

  @override
  String get loadFromUrlEnterUrl => 'ඒ.ස.නි. යොදන්න';

  @override
  String get loadFromUrlErrorEnterFullUrl =>
      'Please enter full url starting with http:// or https://';

  @override
  String get loadFromUrlErrorInvalidUrl => 'Please enter a valid url.';

  @override
  String get linuxAppArmorWarning =>
      'OpenValut requires permission to communicate with Secret Service to store credentials for cloud storage.\nPlease run the following command:';

  @override
  String get cancel => 'Cancel';

  @override
  String get errorLoadFileFromSourceTitle => 'Error while opening file.';

  @override
  String errorLoadFileFromSourceBody(Object source, Object error) {
    return 'Unable to open $source.\n$error';
  }

  @override
  String get errorUnlockFileTitle => 'Unable to open File';

  @override
  String errorUnlockFileBody(Object error) {
    return 'Unknown error while trying to open file. $error';
  }

  @override
  String get dialogContinue => 'ඉදිරියට';

  @override
  String get dialogSendErrorReport => 'Send Error Report';

  @override
  String get dialogReportErrorForum => 'Report Error in Forum/Help';

  @override
  String get groupFilterDescription =>
      'Select which Groups to show (recursively)';

  @override
  String get groupFilterSelectAll => 'සියල්ල තෝරන්න';

  @override
  String get groupFilterDeselectAll => 'සියල්ල නොතෝරන්න';

  @override
  String get createSubgroup => 'Create Subgroup';

  @override
  String get editAction => 'සංස්කරණය';

  @override
  String get mailboxEnableLabel => '(re)enable';

  @override
  String get mailboxEnableHint => 'Continue receiving emails';

  @override
  String get mailboxDisableLabel => 'අබල කරන්න';

  @override
  String get mailboxDisableHint => 'Receive no more emails';

  @override
  String get mailListNoMail => 'You do not have any emails yet.';

  @override
  String mailboxLabelPrefixForEntry(Object entryLabel) {
    return 'Entry: $entryLabel';
  }

  @override
  String mailboxLabelPrefixUnknownEntry(Object entryUuid) {
    return 'Unknown Entry: $entryUuid';
  }

  @override
  String mailboxLabelPrefixCreatedAt(Object dateTime) {
    return 'Created at: $dateTime';
  }

  @override
  String get masterPasswordDescription =>
      'The master password is used to securely encrypt your password database. Make sure to remember it, it can not be restored.';

  @override
  String get unsavedChangesWarningTitle => 'Unsaved Changes';

  @override
  String get unsavedChangesWarningBody =>
      'There are still unsaved changes. Do you want to discard changes?';

  @override
  String get unsavedChangesDiscardActionLabel => 'Discard Changes';

  @override
  String get deletePermanentlyAction => 'Delete Permanently';

  @override
  String get restoreFromRecycleBinAction => 'Restore';

  @override
  String get deleteAction => 'Delete';

  @override
  String get deletedEntry => 'Deleted entry.';

  @override
  String get successfullyDeletedGroup => 'Deleted group.';

  @override
  String get undoButtonLabel => 'පෙරසේ';

  @override
  String get saveButtonLabel => 'සුරකින්න';

  @override
  String get webDavSettings => 'WebDAV Settings';

  @override
  String get webDavUrlLabel => 'URL';

  @override
  String get webDavUrlHelperText => 'Base Url to your WebDAV service.';

  @override
  String get webDavUrlValidatorError => 'Please enter a URL';

  @override
  String get webDavUrlValidatorInvalidUrlError =>
      'Please enter a valid url with http:// or https://';

  @override
  String get webDavAuthUser => 'Username';

  @override
  String get webDavopenvalutword => 'මුරපදය';

  @override
  String get mergeSuccessDialogTitle => 'Successfully merged password database';

  @override
  String mergeSuccessDialogMessage(Object fileName, Object mergeSummary) {
    return 'Conflict detected while saving $fileName, it was merged successfully with the remote file: \n\n$mergeSummary';
  }

  @override
  String forDetailsVisitUrl(Object url) {
    return 'For details visit $url';
  }

  @override
  String get openvalutCloudAuthEmailInputLabel =>
      'Enter email address to register or sign in.';

  @override
  String get openvalutCloudAuthEmailInvalid =>
      'Please enter a valid email address.';

  @override
  String get openvalutCloudAuthConfirmEmailButtonLabel => 'Confirm Address';

  @override
  String get openvalutCloudAuthConfirmEmail =>
      'Please check your emails to confirm your email address.';

  @override
  String get openvalutCloudAuthConfirmEmailExplain =>
      'Keep this screen open until you visited the link you received by email.';

  @override
  String get openvalutCloudAuthResendExplain =>
      'If you have not received an email, please check your spam folder. Otherwise you can try to request a new confirmation link.';

  @override
  String get openvalutCloudAuthResendButtonLabel =>
      'Request a new confirmation link';

  @override
  String permanentlyDeleteEntryConfirm(Object title) {
    return 'This will permanently delete the password entry $title. This can not be undone. Do you want to continue?';
  }

  @override
  String get permanentlyDeletedEntrySnackBar => 'Permanently deleted entry.';

  @override
  String get initialNewGroupName => 'නව සමූහය';

  @override
  String get deleteGroupErrorTitle => 'Unable to delete group';

  @override
  String get deleteGroupErrorBodyContainsGroup =>
      'This group still contains other groups. You can currently only delete empty groups.';

  @override
  String get deleteGroupErrorBodyContainsEntries =>
      'This group still contains password entries. You can currently only delete empty groups.';

  @override
  String get groupListAppBarTitle => 'සමූහ';

  @override
  String get groupListFilterAppbarTitle => 'සමූහ අනුව පෙරන්න';

  @override
  String get clearQuickUnlock => 'Clear Biometric Storage';

  @override
  String get clearQuickUnlockSubtitle => 'Remove saved master passwords';

  @override
  String get unlock => 'Unlock Files';

  @override
  String get closePasswordFiles => 'මුරපද ගොනු වසන්න';

  @override
  String get clearQuickUnlockSuccess =>
      'Removed saved master passwords from biometric storage.';

  @override
  String get diacOptIn => 'Opt in to In-App News, Surveys.';

  @override
  String get diacOptInSubtitle =>
      'Will occasionally send a network request to fetch news.';

  @override
  String browserAutofillThirdPartyModeTitle(String browserName) {
    return 'Enable AutoFill in $browserName';
  }

  @override
  String browserAutofillThirdPartyModeSubtitle(String browserName) {
    return '$browserName currently uses its own password manager. Tap to open its settings and select “Autofill using another service”, then restart $browserName.';
  }

  @override
  String get enableAutofillDebug => 'AutoFill: Enable debug';

  @override
  String get enableAutofillDebugSubtitle =>
      'Shows information overlays for every input field';

  @override
  String get createPasswordDatabase => 'මුරපද දත්තසමුදායක් සාදන්න';

  @override
  String get nameNewPasswordDatabase => 'ඔබගේ නව දත්තසමුදාය නම් කරන්න';

  @override
  String get validatorNameMissing =>
      'ඔබගේ නව දත්තසමුදාය සඳහා නමක් ඇතුළත් කරන්න.';

  @override
  String get masterPasswordHelpText =>
      'Select a secure master Password. Make sure to remember it.';

  @override
  String get inputMasterPasswordText => 'Master Password';

  @override
  String get masterPasswordMissingCreate =>
      'Please enter a secure, rememberable password.';

  @override
  String get createDatabaseAction => 'දත්තසමුදාය සාදන්න';

  @override
  String get databaseExistsError => 'ගොනුව පවතී';

  @override
  String databaseExistsErrorDescription(Object filePath) {
    return 'Error while trying to create database $filePath. File already exists. Please choose another name.';
  }

  @override
  String get databaseCreateDefaultName => 'පුද්ගලික මුරපද';

  @override
  String get preferenceDynamicLoadIcons => 'Dynamically load Icons';

  @override
  String preferenceDynamicLoadIconsSubtitle(Object urlFieldName) {
    return 'Will make http requests with the value in $urlFieldName field to load website icons.';
  }

  @override
  String passwordScore(Object score) {
    return 'Strength: $score of 4';
  }

  @override
  String get passwordStrengthVeryWeak => 'Very weak';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthFair => 'Fair';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get passwordStrengthVeryStrong => 'Very strong';

  @override
  String get passwordStrengthHintVeryWeak =>
      'Too short or too common. Use more characters and mix letters, numbers and symbols.';

  @override
  String get passwordStrengthHintWeak =>
      'Still weak. Add a few more characters or avoid common words.';

  @override
  String get passwordStrengthHintFair =>
      'Decent, but could be stronger with an uncommon phrase.';

  @override
  String get passwordStrengthHintStrong => 'Strong password.';

  @override
  String get passwordStrengthHintVeryStrong => 'Excellent password.';

  @override
  String get entryInfoFile => 'ගොනුව:';

  @override
  String get entryInfoGroup => 'සමූහය:';

  @override
  String get entryInfoLastModified => 'Last Modified:';

  @override
  String movedEntryToGroup(Object groupName) {
    return 'Moved entry into $groupName';
  }

  @override
  String sizeBytesStoredopenvalutCloud(Object count) {
    return '$count bytes, stored on OpenValut Cloud';
  }

  @override
  String sizeBytes(Object count) {
    return '$count bytes';
  }

  @override
  String get entryAttachmentSizeWarning =>
      'Attached files will be embedded in password file. This can significantly increase time required to open/save passwords.';

  @override
  String get iconPngSizeWarning =>
      'Custom icons will be embedded in password file. This can significantly increase time required to open/save passwords.';

  @override
  String get notPngError => 'Chosen file is not a PNG.';

  @override
  String get entryAddField => 'Add Field';

  @override
  String get entryCustomField => 'Custom Field';

  @override
  String get entryCustomFieldTitle => 'Adding new custom Field';

  @override
  String get entryCustomFieldInputLabel => 'Enter a name for the field';

  @override
  String get swipeCopyField => 'Copy Field';

  @override
  String get fieldRename => 'යලි නම් කරන්න';

  @override
  String get fieldGeneratePassword => 'Generate Password …';

  @override
  String get fieldProtect => 'Protect Value';

  @override
  String get fieldUnprotect => 'Unprotect Value';

  @override
  String get fieldPresent => 'Present';

  @override
  String get fieldGenerateEmail => 'Generate Email';

  @override
  String get onboardingBackToOnboarding => 'Tour';

  @override
  String get onboardingBackToOnboardingSubtitle =>
      'Relive the first run experience 😅️';

  @override
  String get onboardingHeadline => 'Let\'s make your Passwords Secure!';

  @override
  String get onboardingQuestion => 'Have you used a password manager before?';

  @override
  String get onboardingYesOpenPasswords => 'ඔව්, මාගේ මුරපද විවෘත කරන්න';

  @override
  String get onboardingNoCreate => 'I\'m all new! Get me started.';

  @override
  String get backupButton => 'මේඝයට සුරකින්න';

  @override
  String get dismissBackupButton => 'DISMISS';

  @override
  String backupWarningMessage(Object databasename) {
    return 'Your passwords in $databasename are only saved locally!';
  }

  @override
  String get saveAs => 'Save In...';

  @override
  String get saving => 'සුරකිමින්';

  @override
  String get increaseValue => 'Increase';

  @override
  String get decreaseValue => 'Decrease';

  @override
  String get resetValue => 'Reset';

  @override
  String cloudStorageAppBarTitle(Object cloudStorageName) {
    return 'CloudStorage - $cloudStorageName';
  }

  @override
  String get cloudStorageLogInCaption =>
      'You will be redirected to authenticate OpenValut to access your data.';

  @override
  String get cloudStorageLogInCode => 'Enter code';

  @override
  String launchUrlError(Object url) {
    return 'Unable to launch url. Please visit $url';
  }

  @override
  String cloudStorageLogInActionLabel(Object cloudStorageName) {
    return 'Login to $cloudStorageName';
  }

  @override
  String cloudStorageAuthCodeDialogTitle(Object cloudStorageName) {
    return '$cloudStorageName Authentication';
  }

  @override
  String get cloudStorageAuthCodeLabel => 'Authentication Code';

  @override
  String get cloudStorageAuthErrorTitle => 'Error while authenticating';

  @override
  String cloudStorageAuthErrorMessage(
    Object cloudStorageName,
    Object errorMessage,
  ) {
    return 'Error while trying to authenticate to $cloudStorageName: $errorMessage';
  }

  @override
  String get cloudStorageSearchBoxLabel => 'Search Query';

  @override
  String cloudStorageItemsInFolder(Object itemCount) {
    return '$itemCount items in this folder.';
  }

  @override
  String get mailSubject => 'Subject';

  @override
  String get mailFrom => 'From';

  @override
  String get mailDate => 'Date';

  @override
  String get mailMailbox => 'Mailbox';

  @override
  String get mailNoData => 'No Data';

  @override
  String get mailMailboxesTitle => 'Mailboxes';

  @override
  String get mailboxCreateButtonLabel => 'Create';

  @override
  String get mailboxNameInputDialogTitle => 'Optionally label for new mailbox';

  @override
  String get mailboxNameInputLabel => '(Internal) Label';

  @override
  String get mailScreenTitle => 'OpenValut Mail';

  @override
  String get mailTabBarTitleMailbox => 'Mailbox';

  @override
  String get mailTabBarTitleMail => 'Mail';

  @override
  String get mailMailboxListEmpty => 'You do not have any mailboxes yet.';

  @override
  String mailMailboxAddressCopied(Object mailboxAddress) {
    return 'Copied mailbox address to clipboard: $mailboxAddress';
  }

  @override
  String get errorWhileSavingTitle => 'Error while saving';

  @override
  String errorWhileSavingBody(Object errorMessage) {
    return 'Unable to save file: $errorMessage';
  }

  @override
  String get databaseDoesNotSupportSaving =>
      'Sorry this database does not support saving. Please open a local database file. Or use \"Save As\".';

  @override
  String get otpInvalidKeyTitle => 'Invalid Key';

  @override
  String get otpInvalidKeyBody =>
      'Given input is not a valid base32 TOTP code. Please verify your input.';

  @override
  String get otpUnsupportedMigrationTitle => 'Unsupported OTP Migration';

  @override
  String otpUnsupportedMigrationBody(Object uriCount) {
    return 'We currently only support single item migrations. Got $uriCount';
  }

  @override
  String get otpPromptTitle => 'Time Based Authentication';

  @override
  String get otpPromptHelperText => 'Please enter time based key.';

  @override
  String otpErrorMessageGeneration(Object errorMessage) {
    return 'Error generating invite code: $errorMessage';
  }

  @override
  String get otpCopySecretActionLabel => 'Copy Secret';

  @override
  String get otpEntryLabel => 'One Time Token';

  @override
  String get entryFieldProtected => 'Protected field. Click to reveal.';

  @override
  String get entryFieldActionRevealField => 'Show protected field';

  @override
  String get entryAttachmentOpenActionLabel => 'Open';

  @override
  String get entryAttachmentShareActionLabel => 'Share';

  @override
  String get entryAttachmentShareSubject => 'Attachment';

  @override
  String get entryAttachmentSaveActionLabel => 'Save to device';

  @override
  String get entryAttachmentRemoveActionLabel => 'Remove';

  @override
  String entryAttachmentRemoveConfirm(Object attachmentLabel) {
    return 'Do you really want to delete $attachmentLabel?';
  }

  @override
  String get entryRenameFieldPromptTitle => 'Renaming field';

  @override
  String get removerecentfile => 'Hide';

  @override
  String get entryRenameFieldPromptLabel => 'Enter the new name for the field';

  @override
  String get promptDialogPasteActionTooltip => 'Paste from Clipboard';

  @override
  String get promptDialogPasteHint =>
      'Hint: If you need to paste, try the button to the left ;-)';

  @override
  String get genericErrorDialogTitle => 'Error while handling action';

  @override
  String genericErrorDialogBody(Object errorMessage) {
    return 'Encountered an unexpected error. $errorMessage';
  }

  @override
  String get saveAsEntryLocalFile => 'Local File';

  @override
  String get fileTypePngs => 'Images (png)';

  @override
  String get selectIconDialogAction => 'SELECT ICON';

  @override
  String get retryDialogActionLabel => 'RETRY';

  @override
  String errorDuringNetworkCall(Object errorMessage) {
    return 'Error during api call. $errorMessage';
  }

  @override
  String get passwordFilterHideDeleted => 'Hide Deleted Entries';

  @override
  String get passwordFilterOnlyDeleted => 'Deleted Entries';

  @override
  String passwordFilterPrefixForOneGroup(Object groupName) {
    return 'Group: $groupName';
  }

  @override
  String passwordFilterPrefixForMultipleGroups(Object groupCount) {
    return 'Custom Filter ($groupCount Groups)';
  }

  @override
  String get menuItemopenvalutCloudAuthenticate =>
      'Authenticate with OpenValut Cloud';

  @override
  String get menuItemopenvalutCloudMailboxes => 'OpenValut Mailboxes';

  @override
  String changesWithoutSaving(Object fileName) {
    return 'You have changes in \"$fileName\", which does not support writing of changes.';
  }

  @override
  String get changesSaveLocally => 'Save locally';

  @override
  String get clearColor => 'Clear Color';

  @override
  String get databaseRenameInputLabel => 'Enter database name';

  @override
  String get databasePath => 'Path';

  @override
  String get databaseColor => 'Color';

  @override
  String get databaseColorChoose =>
      'Select a color to distinguish between files.';

  @override
  String get databaseAutofill => 'AutoFill';

  @override
  String get databaseAutofillSubtitle =>
      'Offer this database\'s entries when apps and websites ask for a password.';

  @override
  String get databaseAutofillCopyWarning =>
      'An encrypted copy of this database is kept for AutoFill until you switch it off, or close the database.';

  @override
  String get databaseAutofillNeedsKdbx4 =>
      'AutoFill needs KDBX 4. Upgrade this database below to use it.';

  @override
  String get databaseAutofillSystemHint =>
      'Also turn OpenValut on in Settings › General › AutoFill & Passwords.';

  @override
  String get databaseKdbxVersion => 'KDBX File Version';

  @override
  String databaseKdbxUpgradeVersion(Object versionName) {
    return 'Upgrade to $versionName';
  }

  @override
  String get databaseKdbxUpgradeSuccessful =>
      'Successfully upgraded file and saved.';

  @override
  String get databaseReload => 'Reload and Merge';

  @override
  String progressStatus(Object statusProgress) {
    return 'Status: $statusProgress';
  }

  @override
  String finishedMerge(Object status) {
    return 'Finished Merge $status';
  }

  @override
  String get closeAndLockFile => 'Close/Lock';

  @override
  String get openvalutHomeScreenTagline =>
      'password manager, open source, available on all platforms.';

  @override
  String get addNewPasswordButtonLabel => 'Add new Password';

  @override
  String get unnamedEntryPlaceholder => '(Unnamed)';

  @override
  String get unnamedGroupPlaceholder => '(Unnamed)';

  @override
  String get unnamedFilePlaceholder => '(Unnamed)';

  @override
  String get editGroupScreenTitle => 'Edit Group';

  @override
  String get editGroupGroupNameLabel => 'Group Name';

  @override
  String get files => 'Files';

  @override
  String get newGroupDialogTitle => 'නව සමූහය';

  @override
  String get newGroupDialogInputLabel => 'Name for the new group';

  @override
  String get groupActionShowPasswords => 'Show passwords';

  @override
  String get groupActionDelete => 'Delete';

  @override
  String get logoutTooltip => 'Logout';

  @override
  String get successfullyDeletedFileCloudStorage =>
      'Successfully deleted file.';

  @override
  String shareDialogTitle(Object fileName) {
    return 'Sharing Options for $fileName';
  }

  @override
  String get shareFileActionLabel => 'Share …';

  @override
  String get shareTokenListEmptyScreenPlaceholder => 'File not shared yet.';

  @override
  String get shareTokenNoLabel => 'No Label/Description';

  @override
  String get shareTokenReadWrite => 'Read/Write';

  @override
  String get shareTokenReadOnly => 'Read only';

  @override
  String get shareCreateTokenDialogTitle => 'Share file';

  @override
  String get shareCreateTokenReadOnly => 'Read only';

  @override
  String get shareCreateTokenReadOnlyHelpText =>
      'Do not allow saving of changes';

  @override
  String get shareCreateTokenLabelText => 'Description';

  @override
  String get shareCreateTokenLabelHint => 'Share for my friend';

  @override
  String get shareCreateTokenLabelHelp =>
      'Optional label to differentiate share code.';

  @override
  String get shareCreateTokenSuccess => 'Successfully created share code.';

  @override
  String get sharePresentDialogTitle => 'Share file with secret share code';

  @override
  String get sharePresentDialogHelp =>
      'Using the following share code users can access the password file. They will need the password and/or key file to open it.';

  @override
  String get sharePresentToken => 'Share Code';

  @override
  String get sharePresentCopied => 'Copied share code to clipboard.';

  @override
  String get openvalutCloudOpenWithShareCodeTooltip => 'Open with Share Code';

  @override
  String get openvalutCloudShareFileActionLabel => 'Share';

  @override
  String get preferenceopenvalutCloudAttachmentTitle =>
      'Use OpenValut Cloud Attachments';

  @override
  String get preferenceopenvalutCloudAttachmentSubtitle =>
      'Store Attachments encrypted on OpenValut Cloud separately.';

  @override
  String get shareCodeInputDialogTitle => 'Input Secret Share Code';

  @override
  String get shareCodeInputDialogScan => 'Scan QR Code';

  @override
  String get shareCodeInputLabel => 'Secret Share Code';

  @override
  String get shareCodeInputHelperText =>
      'If you have received a share code, please paste it above.';

  @override
  String get shareCodeOpen => 'Received a Share Code for OpenValut Cloud?';

  @override
  String get shareCodeOpenScreenTitle => 'Loading file with share code';

  @override
  String get shareCodeLoadingProgress => 'ගොනුව පූරණය වෙමින්…';

  @override
  String get shareCodeOpenFileButtonLabel => 'OPEN';

  @override
  String get shareCodeOpenInstallAppCaption =>
      'Want to open this file with one of our native Apps instead?';

  @override
  String get shareCodeOpenAnotherAppCaption =>
      'Want to open this file on another device?';

  @override
  String get shareCodeOpenInstallAppButtonLabel => 'Install App';

  @override
  String get shareCodeOpenShowCodeButtonLabel => 'Show Share Code';

  @override
  String get changeMasterPasswordActionLabel => 'Change Master Password';

  @override
  String get changeMasterPasswordFormSubmit => 'Save with new password';

  @override
  String get changeMasterPasswordSuccess =>
      'Successfully saved master password.';

  @override
  String get changeMasterPasswordScreenTitle => 'Change Master Password';

  @override
  String get changeMasterPasswordConfirmLabel => 'Repeat new password';

  @override
  String get changeMasterPasswordCleanupTitle =>
      'Password changed — one more step';

  @override
  String get changeMasterPasswordCleanupDevices =>
      '• Other devices: lock the vault and unlock it again with the new master password. Sessions remembered with the old password can no longer decrypt the vault.';

  @override
  String get changeMasterPasswordCleanupBackups =>
      '• Backups and exported copies made before the change are still encrypted with the old password — open and re-save them, or delete them.';

  @override
  String get changeMasterPasswordCleanupQuickUnlock =>
      '• On this device, quick unlock and remembered passwords were cleared; the new password will be required at the next unlock.';

  @override
  String get changeMasterPasswordRotationFailedTitle =>
      'Could not re-encrypt the cloud vault';

  @override
  String changeMasterPasswordRotationFailedBody(Object error) {
    return 'The master password was changed on this device, but re-encrypting the vault on the server failed: $error. Open \"Change Master Password\" again and enter the same new password once more to retry.';
  }

  @override
  String finishedReload(Object status) {
    return 'Finished Reload $status';
  }

  @override
  String get openvalutCloudAuthClickedLink =>
      'I received email and visited link';

  @override
  String get openvalutCloudAuthNotConfirmed =>
      'Email address was not yet confirmed. Make sure to click the link in the email you received and solve the captcha to confirm your email address.';

  @override
  String get getHelpButton => 'Get help in the forum';

  @override
  String get shortcutCopyUsername => 'පරිශීලක නාමය පිටපත්';

  @override
  String get shortcutCopyPassword => 'මුරපදය පිටපත්';

  @override
  String get shortcutCopyTotp => 'Copy TOTP';

  @override
  String get shortcutMoveUp => 'Select the previous password';

  @override
  String get shortcutMoveDown => 'Select the next password';

  @override
  String get shortcutGeneratePassword => 'Generate Password';

  @override
  String get shortcutCopyUrl => 'Copy URL';

  @override
  String get shortcutOpenUrl => 'Open URL';

  @override
  String get shortcutCancelSearch => 'Cancel Search';

  @override
  String get shortcutShortcutHelp => 'යතුරුපුවරුවේ කෙටිමං උදව්';

  @override
  String get shortcutHelpTitle => 'යතුරුපුවරුවේ කෙටිමං';

  @override
  String unexpectedError(String error) {
    return 'අනපේක්ෂිත දෝෂයකි: $error';
  }

  @override
  String get googleDriveMorePermissionsRequired =>
      'Additional permissions needed to access Google Drive.';

  @override
  String get googleDriveRequestPermissionButtonLabel => 'Request Permissions';

  @override
  String get scanQrCodeTitle => 'Scan QR Code.';
}
