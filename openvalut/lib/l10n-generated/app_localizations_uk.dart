// ignore_for_file: omit_local_variable_types,unused_local_variable

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

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
  String get entryAddAttachment => 'Прикріпити файл';

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
  String get fieldUserName => 'Користувач';

  @override
  String get fieldPassword => 'Пароль';

  @override
  String get fieldWebsite => 'Сайт';

  @override
  String get fieldTitle => 'Найменування';

  @override
  String get fieldTotp => 'Одноразовий пароль (залежить від часу)';

  @override
  String get english => 'Англійська';

  @override
  String get german => 'Німецька';

  @override
  String get russian => 'російська';

  @override
  String get ukrainian => 'Українська';

  @override
  String get lithuanian => 'Литовська';

  @override
  String get french => 'Французька';

  @override
  String get spanish => 'Іспанська';

  @override
  String get indonesian => 'Indonesian';

  @override
  String get turkish => 'Турецька';

  @override
  String get hebrew => 'Іврит';

  @override
  String get italian => 'Італійська';

  @override
  String get chineseSimplified => 'Китайська (спрощена)';

  @override
  String get chineseTraditional => 'Китайська (традиційна)';

  @override
  String get portugueseBrazilian => 'Португальська, Бразилія';

  @override
  String get slovak => 'Словацька';

  @override
  String get dutch => 'Нідерландська';

  @override
  String get selectItem => 'Вибрати';

  @override
  String get selectKeepassFile => 'OpenValut - виберіть KeePass файл';

  @override
  String get selectKeepassFileLabel => 'Оберіть файл KeePass (.kdbx).';

  @override
  String get createNewFile => 'Створити новий файл';

  @override
  String get openLocalFile => 'Відкрити\nлокальний файл';

  @override
  String get openFile => 'Відкрити файл';

  @override
  String get loadFromDropdownMenu => 'Завантажити з …';

  @override
  String get quickUnlockingFiles => 'Швидке розблокування файлів …';

  @override
  String openFileProgress(Object fileName, Object current, Object totalCount) {
    return 'Відкриття $fileName … ($current / $totalCount)';
  }

  @override
  String loadFrom(String cloudStorageName) {
    return 'Завантажити з $cloudStorageName';
  }

  @override
  String get loadFromRemoteUrl => 'Відкрити kdbx з URL-адреси';

  @override
  String get createNewKeepass =>
      'Вперше у KeePass?\nСтворити нову базу паролів';

  @override
  String get labelLastOpenFiles => 'Останні відкриті файли:';

  @override
  String get noFilesHaveBeenOpenYet => 'Не було відкрито жодного файлу.';

  @override
  String get preferenceSelectLanguage => 'Оберіть мову';

  @override
  String get preferenceLanguage => 'Мова';

  @override
  String get preferenceTextScaleFactor => 'Коефіцієнт масштабування тексту';

  @override
  String get preferenceVisualDensity => 'Візуальна щільність';

  @override
  String get preferenceTheme => 'Тема';

  @override
  String get preferenceThemeLight => 'Світла';

  @override
  String get preferenceThemeDark => 'Темна';

  @override
  String get preferenceSystemDefault => 'Системні налаштування';

  @override
  String get preferenceDefault => 'Типово';

  @override
  String get lockAllFiles => 'Заблокувати всі відкриті файли';

  @override
  String get preferenceAllowScreenshots => 'Дозволити знімки екрану';

  @override
  String get preferenceEnableAutoFill => 'Увімкнути автозаповнення';

  @override
  String get enableAutofillSuggestionBanner =>
      'Ви можете заповнювати поля в інших додатках якщо включите автозаповнення!';

  @override
  String get dismissAutofillSuggestionBannerButton => 'ВІДХИЛИТИ';

  @override
  String get enableAutofillSuggestionBannerButton => 'ВВІМКНУТИ!';

  @override
  String get preferenceAutoFillDescription =>
      'Підтримується лише на Android Oreo (8.0) або новіше.';

  @override
  String get preferenceTitle => 'Налаштування';

  @override
  String get preferenceEnableSystemWideShortcuts =>
      'Ввімкнути гарячі клавіші всюди';

  @override
  String get preferenceEnableSystemWideShortcutsHelp =>
      'Реєструє ctrl+alt+f в усій системі для відкриття пошуку.';

  @override
  String get preferencesSearchFields => 'Налаштувати поля пошуку';

  @override
  String get preferencesSearchFieldPromptTitle => 'Поля пошуку';

  @override
  String get preferencesSearchFieldPromptLabel =>
      'Список полів за якими буде здійснюватися пошук паролів. Розділені комою.';

  @override
  String preferencesSearchFieldPromptHelp(
    Object wildCardCharacter,
    Object defaultSearchFields,
  ) {
    return 'Використовуйте $wildCardCharacter, щоб включити всі поля або залиште порожнім для використання полів за замовчуванням ($defaultSearchFields)';
  }

  @override
  String get aboutAppName => 'OpenValut';

  @override
  String get aboutLinkFeedback => 'Ми раді будь-яким відгукам!';

  @override
  String get aboutLinkVisitWebsite => 'Також не забудьте відвідати наш сайт';

  @override
  String get aboutLinkGitHub => 'І джерельний код програми';

  @override
  String aboutLogFile(String logFilePath) {
    return 'Файл журналу: $logFilePath';
  }

  @override
  String get aboutLinkContributors => 'Показати учасників проекту';

  @override
  String get unableToLaunchUrlTitle => 'Не вдалося відкрити URL-адресу';

  @override
  String unableToLaunchUrlDescription(Object url, Object openError) {
    return 'Не вдалося запустити $url: $openError';
  }

  @override
  String get unableToLaunchUrlNoHandler =>
      'Додаток для цієї URL-адреси не зареєстровано.';

  @override
  String launchedUrl(Object url) {
    return 'Відкрито посилання: $url';
  }

  @override
  String get menuItemGeneratePassword => 'Згенерувати пароль';

  @override
  String get menuItemPreferences => 'Налаштування';

  @override
  String get menuItemOpenAnotherFile => 'Відкрити інший файл';

  @override
  String get menuItemCheckForUpdates => 'Перевірити наявність оновлень';

  @override
  String get menuItemSupport => 'Надіслати логи';

  @override
  String get menuItemSupportSubtitle => 'Надіслати логи електронною поштою';

  @override
  String get menuItemForum => 'Форум підтримки';

  @override
  String get menuItemForumSubtitle =>
      'Повідомити про проблему й отримати допомогу';

  @override
  String get menuItemHelp => 'Допомога';

  @override
  String get menuItemHelpSubtitle => 'Показати документацію';

  @override
  String get menuItemAbout => 'Про програму';

  @override
  String get actionOpenUrl => 'Відкрити URL-адресу';

  @override
  String get passwordPlainText => 'Показати пароль';

  @override
  String get generatorPassword => 'Пароль';

  @override
  String get generatePassword => 'Згенерувати пароль';

  @override
  String get doneButtonLabel => 'Готово';

  @override
  String get useAsDefault => 'Використовувати за замовчуванням';

  @override
  String get characterSetLowerCase => 'Нижній регістр (а-я)';

  @override
  String get characterSetUpperCase => 'Верхній регістр (A-Я)';

  @override
  String get characterSetNumeric => 'Цифри (0-9)';

  @override
  String get characterSetUmlauts => 'Умляути (ä)';

  @override
  String get characterSetSpecial => 'Спеціальні символи (@%+)';

  @override
  String get length => 'Довжина';

  @override
  String get customLength => 'Особлива довжина';

  @override
  String customLengthHelperText(Object customMinLength) {
    return 'Використовується лише для довжини > $customMinLength';
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
      other: 'Всі файли збережено ($numFilesString): $files',
      one: 'Збережено один файл: $files',
    );
    return '$_temp0';
  }

  @override
  String get manageGroups => 'Керування групами';

  @override
  String get lockFiles => 'Блокування файлів';

  @override
  String get searchHint => 'Пошук';

  @override
  String get searchButtonLabel => 'Пошук';

  @override
  String get filterButtonLabel => 'Фільтрувати за групою';

  @override
  String get clear => 'Очистити';

  @override
  String get autofillFilterPrefix => 'Фільтр:';

  @override
  String get autofillMatchPrefix => 'Matching entries for:';

  @override
  String get autofillPrompt => 'Оберіть пароль для автозаповнення.';

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
  String get copiedToClipboard => 'Скопійовано до буфера обміну.';

  @override
  String get noTitle => '(нема заголовка)';

  @override
  String get noUsername => '(нема ім\'я користувача)';

  @override
  String get filterCustomize => 'Налаштувати …';

  @override
  String get swipeCopyPassword => 'Копіювати пароль';

  @override
  String get swipeCopyUsername => 'Копіювати ім\'я користувача';

  @override
  String get copyUsernameNotExists => 'Цей запис не має ім\'я користувача.';

  @override
  String get copyPasswordNotExists => 'Цей запис не має пароля.';

  @override
  String get doneCopiedPassword => 'Пароль скопійовано до буфера обміну.';

  @override
  String get doneCopiedUsername =>
      'Ім\'я користувача було скопійовано до буфера обміну.';

  @override
  String get doneCopiedField => 'Скопійовано.';

  @override
  String copiedFieldToClipboard(Object fieldName) {
    return '$fieldName зкопійовано.';
  }

  @override
  String copiedFieldEmpty(Object fieldName) {
    return 'Поле \"$fieldName\" порожнє.';
  }

  @override
  String get emptyPasswordVaultPlaceholder =>
      'Ви ще не маєте жодного пароля в базі даних.';

  @override
  String get emptyPasswordVaultButtonLabel => 'Створити свій перший пароль';

  @override
  String get loading => 'Завантаження';

  @override
  String get loadingFile => 'Завантаження файлу …';

  @override
  String get internalFile => 'Внутрішній файл';

  @override
  String get internalFileSubtitle =>
      'Попередня база паролів створена в OpenValut';

  @override
  String get filePicker => 'Вибір файлу';

  @override
  String get filePickerSubtitle => 'Відкрити файл з пристрою.';

  @override
  String get credentialsAppBarTitle => 'Облікові дані';

  @override
  String get credentialLabel => 'Введіть пароль для:';

  @override
  String get masterPasswordInputLabel => 'Пароль';

  @override
  String get masterPasswordEmptyValidator => 'Будь ласка, введіть ваш пароль.';

  @override
  String get masterPasswordIncorrectValidator => 'Невірний пароль';

  @override
  String get useKeyFile => 'Використати файл-ключ';

  @override
  String get saveMasterPasswordBiometric =>
      'Зберегти пароль із біометричним сховищем ключів?';

  @override
  String get close => 'Закрити';

  @override
  String get addNewPassword => 'Додати новий пароль';

  @override
  String get errorOpenFileInvalidFileStructureTitle =>
      'Спроба відкрити невірний тип файлу';

  @override
  String errorOpenFileInvalidFileStructureBody(Object fileName) {
    return 'Файл ($fileName) не є коректним файлом KDBX. Будь ласка, виберіть правильний файл KDBX або створіть нову базу паролів.';
  }

  @override
  String get errorOpenFileAlreadyOpenTitle => 'Цей файл вже відкритий';

  @override
  String errorOpenFileAlreadyOpenBody(
    Object databaseName,
    Object openFileSource,
    Object newFileSource,
  ) {
    return 'Обрана база даних $databaseName вже відкрита з $openFileSource (Спроба відкрити з $newFileSource)';
  }

  @override
  String get loadFromUrl => 'Завантажити з URL-адреси';

  @override
  String get loadFromUrlEnterUrl => 'Введіть URL-адресу';

  @override
  String get loadFromUrlErrorEnterFullUrl =>
      'Будь ласка, введіть повне посилання починаючи з http:// або https://';

  @override
  String get loadFromUrlErrorInvalidUrl =>
      'Будь ласка, введіть правильний URL.';

  @override
  String get linuxAppArmorWarning =>
      'OpenValut потребує дозволу на зв\'язок зі Службою Паролів для зберігання облікових даних для хмарного сховища.\nБудь ласка, виконайте наступну команду:';

  @override
  String get cancel => 'Скасувати';

  @override
  String get errorLoadFileFromSourceTitle => 'Помилка під час відкриття файлу.';

  @override
  String errorLoadFileFromSourceBody(Object source, Object error) {
    return 'Не вдалося відкрити $source.\n$error';
  }

  @override
  String get errorUnlockFileTitle => 'Не вдалося відкрити файл';

  @override
  String errorUnlockFileBody(Object error) {
    return 'Сталася невідома помилка під час спроби відкрити файл. $error';
  }

  @override
  String get dialogContinue => 'Продовжити';

  @override
  String get dialogSendErrorReport => 'Надіслати звіт про помилки';

  @override
  String get dialogReportErrorForum =>
      'Повідомити про помилку на форумі/центрі допомоги';

  @override
  String get groupFilterDescription =>
      'Виберіть, які групи показувати (рекурсивно)';

  @override
  String get groupFilterSelectAll => 'Обрати все';

  @override
  String get groupFilterDeselectAll => 'Зняти всі виділення';

  @override
  String get createSubgroup => 'Створити підгрупу';

  @override
  String get editAction => 'Редагувати';

  @override
  String get mailboxEnableLabel => 'ввімкнути (знову)';

  @override
  String get mailboxEnableHint => 'Продовжити отримувати листи';

  @override
  String get mailboxDisableLabel => 'Вимкнути';

  @override
  String get mailboxDisableHint => 'Більше не отримувати листів';

  @override
  String get mailListNoMail => 'Ви ще не отримували жодних листів.';

  @override
  String mailboxLabelPrefixForEntry(Object entryLabel) {
    return 'Запис: $entryLabel';
  }

  @override
  String mailboxLabelPrefixUnknownEntry(Object entryUuid) {
    return 'Невідомий запис: $entryUuid';
  }

  @override
  String mailboxLabelPrefixCreatedAt(Object dateTime) {
    return 'Створено: $dateTime';
  }

  @override
  String get masterPasswordDescription =>
      'Головний пароль використовується для безпечного шифрування бази паролів. Його неможливо відновити, тож переконайтеся що ви його пам\'ятаєте.';

  @override
  String get unsavedChangesWarningTitle => 'Не всі зміни збережено';

  @override
  String get unsavedChangesWarningBody =>
      'Дані ще не збережені. Ви бажаєте відхилити зміни?';

  @override
  String get unsavedChangesDiscardActionLabel => 'Скасувати зміни';

  @override
  String get deletePermanentlyAction => 'Видалити назавжди';

  @override
  String get restoreFromRecycleBinAction => 'Відновити';

  @override
  String get deleteAction => 'Видалити';

  @override
  String get deletedEntry => 'Вилучений запис.';

  @override
  String get successfullyDeletedGroup => 'Видалити групу.';

  @override
  String get undoButtonLabel => 'Скасувати';

  @override
  String get saveButtonLabel => 'Зберегти';

  @override
  String get webDavSettings => 'Налаштування WebDAV';

  @override
  String get webDavUrlLabel => 'URL-адреса';

  @override
  String get webDavUrlHelperText => 'Базове посилання на Вашу службу WebDAV.';

  @override
  String get webDavUrlValidatorError => 'Введіть URL-адресу';

  @override
  String get webDavUrlValidatorInvalidUrlError =>
      'Будь ласка, введіть повне посилання починаючи з http:// або https://';

  @override
  String get webDavAuthUser => 'Логін';

  @override
  String get webDavopenvalutword => 'Пароль';

  @override
  String get mergeSuccessDialogTitle => 'База паролів успішно об\'єднана';

  @override
  String mergeSuccessDialogMessage(Object fileName, Object mergeSummary) {
    return 'Виявлено конфлікт під час збереження $fileName, він був успішно об\'єднаний з віддаленим файлом: \n\n$mergeSummary';
  }

  @override
  String forDetailsVisitUrl(Object url) {
    return 'Переглянути деталі за посиланням: $url';
  }

  @override
  String get openvalutCloudAuthEmailInputLabel =>
      'Введіть адресу ел. пошти для реєстрації або входу.';

  @override
  String get openvalutCloudAuthEmailInvalid =>
      'Будь ласка, введіть правильну адресу електронної пошти.';

  @override
  String get openvalutCloudAuthConfirmEmailButtonLabel =>
      'Підтвердження адреси';

  @override
  String get openvalutCloudAuthConfirmEmail =>
      'Будь ласка, перевірте свою електронну скриньку, щоб підтвердити свою електронну адресу.';

  @override
  String get openvalutCloudAuthConfirmEmailExplain =>
      'Не закривайте цей екран поки не підтвердите адресу ел. пошти.';

  @override
  String get openvalutCloudAuthResendExplain =>
      'Якщо ви не отримали листа, перевірте теку зі спамом. Або ви можете запросити посилання для підтвердження ще раз.';

  @override
  String get openvalutCloudAuthResendButtonLabel =>
      'Запросити нове посилання для підтвердження';

  @override
  String permanentlyDeleteEntryConfirm(Object title) {
    return 'Це призведе до остаточного видалення запису пароля $title. Це не може бути скасовано. Ви хочете продовжити?';
  }

  @override
  String get permanentlyDeletedEntrySnackBar => 'Запис видалено назавжди.';

  @override
  String get initialNewGroupName => 'Нова група';

  @override
  String get deleteGroupErrorTitle => 'Не вдалося видалити групу';

  @override
  String get deleteGroupErrorBodyContainsGroup =>
      'Ця група містить підгрупи. Ви можете видаляти лише порожні групи.';

  @override
  String get deleteGroupErrorBodyContainsEntries =>
      'Ця група все ще містить збережені паролі. Видалити можна тільки порожні групи.';

  @override
  String get groupListAppBarTitle => 'Групи';

  @override
  String get groupListFilterAppbarTitle => 'Фільтрувати за групами';

  @override
  String get clearQuickUnlock => 'Очистити сховище біометричних даних';

  @override
  String get clearQuickUnlockSubtitle =>
      'Видалити збережені головні майстер-паролі';

  @override
  String get unlock => 'Розблокувати файли';

  @override
  String get closePasswordFiles => 'закрити файли паролів';

  @override
  String get clearQuickUnlockSuccess =>
      'Збережені майстер-паролі з біометричного сховища вилучено.';

  @override
  String get diacOptIn => 'Підпишіться на новини в додатку, опитування.';

  @override
  String get diacOptInSubtitle =>
      'Час від часу надсилатиме мережевий запит для отримання новин.';

  @override
  String browserAutofillThirdPartyModeTitle(String browserName) {
    return 'Enable AutoFill in $browserName';
  }

  @override
  String browserAutofillThirdPartyModeSubtitle(String browserName) {
    return '$browserName currently uses its own password manager. Tap to open its settings and select “Autofill using another service”, then restart $browserName.';
  }

  @override
  String get enableAutofillDebug =>
      'Автозаповнення: увімкнути налагодження (debug)';

  @override
  String get enableAutofillDebugSubtitle =>
      'Показує інформаційні шари для кожного поля введення';

  @override
  String get createPasswordDatabase => 'Створити базу паролів';

  @override
  String get nameNewPasswordDatabase => 'Назва нової бази паролів';

  @override
  String get validatorNameMissing =>
      'Будь ласка, введіть назву для нової бази даних.';

  @override
  String get masterPasswordHelpText =>
      'Виберіть надійний головний пароль. Запам\'ятайте його.';

  @override
  String get inputMasterPasswordText => 'Головний пароль';

  @override
  String get masterPasswordMissingCreate =>
      'Будь ласка, введіть надійний пароль, що легко запам\'ятовується.';

  @override
  String get createDatabaseAction => 'Створити базу даних';

  @override
  String get databaseExistsError => 'Файл вже існує';

  @override
  String databaseExistsErrorDescription(Object filePath) {
    return 'Помилка при спробі створити базу даних $filePath. Файл вже існує. Будь ласка, виберіть іншу назву.';
  }

  @override
  String get databaseCreateDefaultName => 'ОсобистіПаролі';

  @override
  String get preferenceDynamicLoadIcons => 'Завантажувати іконки динамічно';

  @override
  String preferenceDynamicLoadIconsSubtitle(Object urlFieldName) {
    return 'Буде робити http-запити зі значенням у полі $urlFieldName для завантаження іконок сайтів.';
  }

  @override
  String passwordScore(Object score) {
    return 'Міцність: $score з 4';
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
  String get entryInfoFile => 'Файл:';

  @override
  String get entryInfoGroup => 'Група:';

  @override
  String get entryInfoLastModified => 'Остання зміна:';

  @override
  String movedEntryToGroup(Object groupName) {
    return 'Переміщено запис до $groupName';
  }

  @override
  String sizeBytesStoredopenvalutCloud(Object count) {
    return '$count байт, що зберігаються в OpenValut Cloud';
  }

  @override
  String sizeBytes(Object count) {
    return '$count байт';
  }

  @override
  String get entryAttachmentSizeWarning =>
      'Прикріплені файли будуть вбудовані у файл паролів. Це може значно збільшити час, необхідний для відкриття/збереження паролів.';

  @override
  String get iconPngSizeWarning =>
      'У файл пароля будуть вбудовані користувацькі іконки. Це може значно збільшити час, необхідний для відкриття/збереження паролів.';

  @override
  String get notPngError => 'Обраний файл не є PNG.';

  @override
  String get entryAddField => 'Створити поле';

  @override
  String get entryCustomField => 'Власне поле';

  @override
  String get entryCustomFieldTitle => 'Додавання нового користувацького поля';

  @override
  String get entryCustomFieldInputLabel => 'Введіть нове ім\'я для поля';

  @override
  String get swipeCopyField => 'Копіювати поле';

  @override
  String get fieldRename => 'Перейменувати';

  @override
  String get fieldGeneratePassword => 'Згенерувати пароль …';

  @override
  String get fieldProtect => 'Захистити Значення';

  @override
  String get fieldUnprotect => 'Прибрати Захист';

  @override
  String get fieldPresent => 'QR код';

  @override
  String get fieldGenerateEmail => 'Згенерувати адресу електронної пошти';

  @override
  String get onboardingBackToOnboarding => 'Тур';

  @override
  String get onboardingBackToOnboardingSubtitle =>
      'Переживіть досвід першого запуску 😅️';

  @override
  String get onboardingHeadline => 'Зробимо ваші паролі безпечними!';

  @override
  String get onboardingQuestion =>
      'Чи користувалися ви раніше менеджером паролів?';

  @override
  String get onboardingYesOpenPasswords => 'Так, відкрити мої паролі';

  @override
  String get onboardingNoCreate => 'Я зовсім новачок! Нумо почнімо.';

  @override
  String get backupButton => 'ЗБЕРЕГТИ В КЛАУД';

  @override
  String get dismissBackupButton => 'ВІДХИЛИТИ';

  @override
  String backupWarningMessage(Object databasename) {
    return 'Ваші паролі в $databasename збережені тільки локально!';
  }

  @override
  String get saveAs => 'Зберегти В...';

  @override
  String get saving => 'Збереження';

  @override
  String get increaseValue => 'Збільшити';

  @override
  String get decreaseValue => 'Зменшити';

  @override
  String get resetValue => 'Скинути';

  @override
  String cloudStorageAppBarTitle(Object cloudStorageName) {
    return 'Хмарне сховище - $cloudStorageName';
  }

  @override
  String get cloudStorageLogInCaption =>
      'Вас буде перенаправлено на сторінку автентифікації OpenValut для доступу до ваших даних.';

  @override
  String get cloudStorageLogInCode => 'Введіть код';

  @override
  String launchUrlError(Object url) {
    return 'Не вдалося відкрити URL-адресу. Будь ласка, перейдіть за посиланням $url';
  }

  @override
  String cloudStorageLogInActionLabel(Object cloudStorageName) {
    return 'Увійти до $cloudStorageName';
  }

  @override
  String cloudStorageAuthCodeDialogTitle(Object cloudStorageName) {
    return '$cloudStorageName Автентифікація';
  }

  @override
  String get cloudStorageAuthCodeLabel => 'Код автентифікації';

  @override
  String get cloudStorageAuthErrorTitle => 'Помилка під час автентифікації';

  @override
  String cloudStorageAuthErrorMessage(
    Object cloudStorageName,
    Object errorMessage,
  ) {
    return 'Помилка при спробі автентифікації в $cloudStorageName: $errorMessage';
  }

  @override
  String get cloudStorageSearchBoxLabel => 'Пошуковий запит';

  @override
  String cloudStorageItemsInFolder(Object itemCount) {
    return '$itemCount елементів у цій теці.';
  }

  @override
  String get mailSubject => 'Тема';

  @override
  String get mailFrom => 'Від';

  @override
  String get mailDate => 'Дата';

  @override
  String get mailMailbox => 'Поштова скринька';

  @override
  String get mailNoData => 'Немає даних';

  @override
  String get mailMailboxesTitle => 'Поштові скриньки';

  @override
  String get mailboxCreateButtonLabel => 'Створити';

  @override
  String get mailboxNameInputDialogTitle =>
      'Назва поштової скриньки (не обовʼязково)';

  @override
  String get mailboxNameInputLabel => '(Внутрішня) Назва';

  @override
  String get mailScreenTitle => 'Електронна пошта OpenValut';

  @override
  String get mailTabBarTitleMailbox => 'Поштова скринька';

  @override
  String get mailTabBarTitleMail => 'Пошта';

  @override
  String get mailMailboxListEmpty => 'У вас поки що немає поштових скриньок.';

  @override
  String mailMailboxAddressCopied(Object mailboxAddress) {
    return 'Скопійовано адресу поштової скриньки: $mailboxAddress';
  }

  @override
  String get errorWhileSavingTitle => 'Помилка збереження';

  @override
  String errorWhileSavingBody(Object errorMessage) {
    return 'Неможливо зберегти файл: $errorMessage';
  }

  @override
  String get databaseDoesNotSupportSaving =>
      'На жаль, ця база даних не підтримує збереження. Будь ласка, відкрийте локальний файл бази даних. Або скористайтеся кнопкою \"Зберегти як\".';

  @override
  String get otpInvalidKeyTitle => 'Недійсний ключ';

  @override
  String get otpInvalidKeyBody =>
      'Введене значення не є коректним base32 TOTP кодом. Будь ласка, перевірте введені дані.';

  @override
  String get otpUnsupportedMigrationTitle => 'Непідтримувана міграція ОТР';

  @override
  String otpUnsupportedMigrationBody(Object uriCount) {
    return 'Наразі ми підтримуємо лише перенесення одного елемента. Отримано $uriCount';
  }

  @override
  String get otpPromptTitle => 'Автентифікація на основі часу';

  @override
  String get otpPromptHelperText =>
      'Будь ласка, введіть ключ, заснований на часі.';

  @override
  String otpErrorMessageGeneration(Object errorMessage) {
    return 'Помилка генерування коду запрошення: $errorMessage';
  }

  @override
  String get otpCopySecretActionLabel => 'Копіювати секрет';

  @override
  String get otpEntryLabel => 'Одноразовий Токен';

  @override
  String get entryFieldProtected => 'Захищене поле. Клацніть, щоб відкрити.';

  @override
  String get entryFieldActionRevealField => 'Показати захищене поле';

  @override
  String get entryAttachmentOpenActionLabel => 'Відкрити';

  @override
  String get entryAttachmentShareActionLabel => 'Поділитись';

  @override
  String get entryAttachmentShareSubject => 'Вкладення';

  @override
  String get entryAttachmentSaveActionLabel => 'Зберегти на пристрій';

  @override
  String get entryAttachmentRemoveActionLabel => 'Видалити';

  @override
  String entryAttachmentRemoveConfirm(Object attachmentLabel) {
    return 'Ви дійсно бажаєте вилучити $attachmentLabel?';
  }

  @override
  String get entryRenameFieldPromptTitle => 'Перейменування поля';

  @override
  String get removerecentfile => 'Приховати';

  @override
  String get entryRenameFieldPromptLabel => 'Введіть нове ім\'я для поля';

  @override
  String get promptDialogPasteActionTooltip => 'Вставити із буферу обміну';

  @override
  String get promptDialogPasteHint =>
      'Підказка: якщо потрібно вставити, спробуйте кнопку ліворуч ;-)';

  @override
  String get genericErrorDialogTitle => 'Помилка під час обробки дії';

  @override
  String genericErrorDialogBody(Object errorMessage) {
    return 'Виникла несподівана помилка. $errorMessage';
  }

  @override
  String get saveAsEntryLocalFile => 'Локальний Файл';

  @override
  String get fileTypePngs => 'Зображення (png)';

  @override
  String get selectIconDialogAction => 'ВИБРАТИ ІКОНКУ';

  @override
  String get retryDialogActionLabel => 'ПОВТОРИТИ';

  @override
  String errorDuringNetworkCall(Object errorMessage) {
    return 'Помилка під час виклику api. $errorMessage';
  }

  @override
  String get passwordFilterHideDeleted => 'Приховати вилучені записи';

  @override
  String get passwordFilterOnlyDeleted => 'Вилучені Записи';

  @override
  String passwordFilterPrefixForOneGroup(Object groupName) {
    return 'Група: $groupName';
  }

  @override
  String passwordFilterPrefixForMultipleGroups(Object groupCount) {
    return 'Власний фільтр ($groupCount груп(и))';
  }

  @override
  String get menuItemopenvalutCloudAuthenticate =>
      'Авторизуватись з OpenValut Cloud';

  @override
  String get menuItemopenvalutCloudMailboxes => 'Електронні скриньки OpenValut';

  @override
  String changesWithoutSaving(Object fileName) {
    return 'У вас є зміни в \"$fileName\", який не підтримує запис змін.';
  }

  @override
  String get changesSaveLocally => 'Зберегти локально';

  @override
  String get clearColor => 'Скинути колір';

  @override
  String get databaseRenameInputLabel => 'Введіть ім\'я бази даних';

  @override
  String get databasePath => 'Шлях до файлу';

  @override
  String get databaseColor => 'Колір';

  @override
  String get databaseColorChoose => 'Виберіть колір, щоб розрізняти файли.';

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
  String get databaseKdbxVersion => 'Версія файлу KDBX';

  @override
  String databaseKdbxUpgradeVersion(Object versionName) {
    return 'Оновити до $versionName';
  }

  @override
  String get databaseKdbxUpgradeSuccessful =>
      'Файл успішно оновлено та збережено.';

  @override
  String get databaseReload => 'Перезавантажити та злити';

  @override
  String progressStatus(Object statusProgress) {
    return 'Статус: $statusProgress';
  }

  @override
  String finishedMerge(Object status) {
    return 'Завершено злиття $status';
  }

  @override
  String get closeAndLockFile => 'Закрити/Заблокувати';

  @override
  String get openvalutHomeScreenTagline =>
      'менеджер паролів, з відкритим кодом, доступний на всіх платформах.';

  @override
  String get addNewPasswordButtonLabel => 'Додати новий пароль';

  @override
  String get unnamedEntryPlaceholder => '(Без назви)';

  @override
  String get unnamedGroupPlaceholder => '(Без назви)';

  @override
  String get unnamedFilePlaceholder => '(Без назви)';

  @override
  String get editGroupScreenTitle => 'Редагувати групу';

  @override
  String get editGroupGroupNameLabel => 'Назва групи';

  @override
  String get files => 'Файли';

  @override
  String get newGroupDialogTitle => 'Нова група';

  @override
  String get newGroupDialogInputLabel => 'Ім\'я для нової групи';

  @override
  String get groupActionShowPasswords => 'Показати паролі';

  @override
  String get groupActionDelete => 'Видалити';

  @override
  String get logoutTooltip => 'Вихід із системи';

  @override
  String get successfullyDeletedFileCloudStorage => 'Файл успішно видалено.';

  @override
  String shareDialogTitle(Object fileName) {
    return 'Параметри спільного доступу до $fileName';
  }

  @override
  String get shareFileActionLabel => 'Поділіться …';

  @override
  String get shareTokenListEmptyScreenPlaceholder =>
      'До файлу ще не надано доступ.';

  @override
  String get shareTokenNoLabel => 'Без мітки/опису';

  @override
  String get shareTokenReadWrite => 'Читання/запис';

  @override
  String get shareTokenReadOnly => 'Лише для читання';

  @override
  String get shareCreateTokenDialogTitle => 'Поділитися файлом';

  @override
  String get shareCreateTokenReadOnly => 'Тільки для читання';

  @override
  String get shareCreateTokenReadOnlyHelpText => 'Не дозволяти збереження змін';

  @override
  String get shareCreateTokenLabelText => 'Опис';

  @override
  String get shareCreateTokenLabelHint => 'Поширення для Залужного';

  @override
  String get shareCreateTokenLabelHelp =>
      'Необов\'язкова мітка для розрізнення коду спільного доступу.';

  @override
  String get shareCreateTokenSuccess => 'Код поширення успішно створено.';

  @override
  String get sharePresentDialogTitle =>
      'Поділитися файлом з секретним кодом поширення';

  @override
  String get sharePresentDialogHelp =>
      'Використовуючи наступний код доступу, користувачі можуть отримати доступ до файлу з паролями. Щоб відкрити його, їм знадобиться пароль та/або ключ-файл.';

  @override
  String get sharePresentToken => 'Код для поширення';

  @override
  String get sharePresentCopied => 'Скопійовано код поширення.';

  @override
  String get openvalutCloudOpenWithShareCodeTooltip =>
      'Відкрити за допомогою коду спільного доступу';

  @override
  String get openvalutCloudShareFileActionLabel => 'Поділитись';

  @override
  String get preferenceopenvalutCloudAttachmentTitle =>
      'Використовувати вкладення OpenValut Cloud';

  @override
  String get preferenceopenvalutCloudAttachmentSubtitle =>
      'Зберігати зашифровані вкладення в OpenValut Cloud окремо.';

  @override
  String get shareCodeInputDialogTitle =>
      'Введіть секретний код спільного доступу';

  @override
  String get shareCodeInputDialogScan => 'Проскануйте QR-код';

  @override
  String get shareCodeInputLabel => 'Секретний код поширення';

  @override
  String get shareCodeInputHelperText =>
      'Якщо ви отримали код поширення, будь ласка, вставте його вище.';

  @override
  String get shareCodeOpen => 'Отримали код доступу до OpenValut Cloud?';

  @override
  String get shareCodeOpenScreenTitle =>
      'Завантаження файлу за допомогою коду спільного доступу';

  @override
  String get shareCodeLoadingProgress => 'Завантаження файлу …';

  @override
  String get shareCodeOpenFileButtonLabel => 'ВІДКРИТИ';

  @override
  String get shareCodeOpenInstallAppCaption =>
      'Хочете відкрити цей файл за допомогою однієї з наших програм?';

  @override
  String get shareCodeOpenAnotherAppCaption =>
      'Хочете відкрити цей файл на іншому пристрої?';

  @override
  String get shareCodeOpenInstallAppButtonLabel => 'Встановити додаток';

  @override
  String get shareCodeOpenShowCodeButtonLabel => 'Показати код поширення';

  @override
  String get changeMasterPasswordActionLabel => 'Змінити головний пароль';

  @override
  String get changeMasterPasswordFormSubmit => 'Зберегти з новим паролем';

  @override
  String get changeMasterPasswordSuccess =>
      'Головний пароль успішно збережено.';

  @override
  String get changeMasterPasswordScreenTitle => 'Змінити головний пароль';

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
      'Я отримав листа і відкрив посилання';

  @override
  String get openvalutCloudAuthNotConfirmed =>
      'Адреса електронної пошти ще не підтверджена. Обов\'язково перейдіть за посиланням в отриманому листі та розгадайте капчу, щоб підтвердити свою електронну адресу.';

  @override
  String get getHelpButton => 'Отримати допомогу на форумі';

  @override
  String get shortcutCopyUsername => 'Копіювати ім\'я користувача';

  @override
  String get shortcutCopyPassword => 'Копіювати пароль';

  @override
  String get shortcutCopyTotp => 'Копіювати TOTP';

  @override
  String get shortcutMoveUp => 'Вибрати попередній пароль';

  @override
  String get shortcutMoveDown => 'Вибрати наступний пароль';

  @override
  String get shortcutGeneratePassword => 'Згенерувати пароль';

  @override
  String get shortcutCopyUrl => 'Копіювати URL-адресу';

  @override
  String get shortcutOpenUrl => 'Відкрити URL-адресу';

  @override
  String get shortcutCancelSearch => 'Скасувати пошук';

  @override
  String get shortcutShortcutHelp => 'Довідка по гарячих клавішах';

  @override
  String get shortcutHelpTitle => 'Гарячі Клавіші';

  @override
  String unexpectedError(String error) {
    return 'Неочікувана помилка: $error';
  }

  @override
  String get googleDriveMorePermissionsRequired =>
      'Additional permissions needed to access Google Drive.';

  @override
  String get googleDriveRequestPermissionButtonLabel => 'Request Permissions';

  @override
  String get scanQrCodeTitle => 'Сканувати QR-код.';
}
