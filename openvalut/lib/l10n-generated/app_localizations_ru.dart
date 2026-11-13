// ignore_for_file: omit_local_variable_types,unused_local_variable

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

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
  String get menuAuthorName => 'Awen';

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
  String get entryAddAttachment => 'Добавить вложение';

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
  String get fieldUserName => 'Пользователь';

  @override
  String get fieldPassword => 'Пароль';

  @override
  String get fieldWebsite => 'Сайт';

  @override
  String get fieldTitle => 'Название';

  @override
  String get fieldTotp => 'Одноразовый пароль (основанный на времени)';

  @override
  String get english => 'English';

  @override
  String get german => 'Немецкий';

  @override
  String get russian => 'Русский';

  @override
  String get ukrainian => 'Украинский';

  @override
  String get lithuanian => 'Литовский';

  @override
  String get french => 'Французский';

  @override
  String get spanish => 'Испанский';

  @override
  String get indonesian => 'Индонезийский';

  @override
  String get turkish => 'Турецкий';

  @override
  String get hebrew => 'Иврит';

  @override
  String get italian => 'итальянский';

  @override
  String get chineseSimplified => 'Китайский упрощённый';

  @override
  String get chineseTraditional => 'Китайский традиционный';

  @override
  String get portugueseBrazilian => 'Португальский, бразильский';

  @override
  String get slovak => 'Словацкий';

  @override
  String get dutch => 'Голландский';

  @override
  String get selectItem => 'Выбрать';

  @override
  String get selectKeepassFile => 'OpenValut - выберите KeePass файл';

  @override
  String get selectKeepassFileLabel => 'Выберите файл KeePass (.kdbx).';

  @override
  String get createNewFile => 'Создать новый файл';

  @override
  String get openLocalFile => 'Открыть\nлокальный файл';

  @override
  String get openFile => 'Открыть файл';

  @override
  String get loadFromDropdownMenu => 'Загрузить из …';

  @override
  String get quickUnlockingFiles => 'Быстрая разблокировка файлов…';

  @override
  String openFileProgress(Object fileName, Object current, Object totalCount) {
    return 'Открывается $fileName… ($current / $totalCount)';
  }

  @override
  String loadFrom(String cloudStorageName) {
    return 'Загрузить из $cloudStorageName';
  }

  @override
  String get loadFromRemoteUrl => 'Открыть kdbx из URL-адреса';

  @override
  String get createNewKeepass =>
      'Впервые в KeePass?\nСоздать новую базу данных паролей';

  @override
  String get labelLastOpenFiles => 'Последние открытые файлы:';

  @override
  String get noFilesHaveBeenOpenYet => 'Файлы ещё не были открыты.';

  @override
  String get preferenceSelectLanguage => 'Выберите язык';

  @override
  String get preferenceLanguage => 'Язык';

  @override
  String get preferenceTextScaleFactor => 'Коэффициент размера текста';

  @override
  String get preferenceVisualDensity => 'Плотность';

  @override
  String get preferenceTheme => 'Тема';

  @override
  String get preferenceThemeLight => 'Светлая';

  @override
  String get preferenceThemeDark => 'Тёмная';

  @override
  String get preferenceSystemDefault => 'Системные настройки';

  @override
  String get preferenceDefault => 'По умолчанию';

  @override
  String get lockAllFiles => 'Заблокировать все открытые файлы';

  @override
  String get preferenceAllowScreenshots =>
      'Разрешить делать скриншоты приложения';

  @override
  String get preferenceEnableAutoFill => 'Включить автозаполнение';

  @override
  String get enableAutofillSuggestionBanner =>
      'Вы можете заполнить поле другого приложения, включив автозаполнение!';

  @override
  String get dismissAutofillSuggestionBannerButton => 'ОТКЛЮЧИТЬ';

  @override
  String get enableAutofillSuggestionBannerButton => 'Включить!';

  @override
  String get preferenceAutoFillDescription =>
      'Поддерживается с Android Oreo (8.0) или более поздней версии.';

  @override
  String get preferenceTitle => 'Настройки';

  @override
  String get preferenceEnableSystemWideShortcuts =>
      'Включить общесистемные ярлыки';

  @override
  String get preferenceEnableSystemWideShortcutsHelp =>
      'Регистрирует сочетание клавиш ctrl+alt+f в качестве общесистемного ярлыка для открытия поиска.';

  @override
  String get preferencesSearchFields => 'Настройка полей поиска';

  @override
  String get preferencesSearchFieldPromptTitle => 'Поля поиска';

  @override
  String get preferencesSearchFieldPromptLabel =>
      'Список полей, разделенных запятыми, для использования в поиске по списку паролей.';

  @override
  String preferencesSearchFieldPromptHelp(
    Object wildCardCharacter,
    Object defaultSearchFields,
  ) {
    return 'Используйте $wildCardCharacter для всех, оставьте пустым по умолчанию ($defaultSearchFields)';
  }

  @override
  String get aboutAppName => 'OpenValut';

  @override
  String get aboutLinkFeedback => 'Мы рады любым отзывам!';

  @override
  String get aboutLinkVisitWebsite => 'Не забудьте посетить наш сайт';

  @override
  String get aboutLinkGitHub => 'И исходный код проекта';

  @override
  String aboutLogFile(String logFilePath) {
    return 'Файл журнала: $logFilePath';
  }

  @override
  String get aboutLinkContributors => 'Показать участников';

  @override
  String get unableToLaunchUrlTitle => 'Не удается открыть Url';

  @override
  String unableToLaunchUrlDescription(Object url, Object openError) {
    return 'Не удалось запустить $url: $openError';
  }

  @override
  String get unableToLaunchUrlNoHandler => 'Нет доступных приложений для url.';

  @override
  String launchedUrl(Object url) {
    return 'Открытый URL: $url';
  }

  @override
  String get menuItemGeneratePassword => 'Сгенерировать пароль';

  @override
  String get menuItemPreferences => 'Настройки';

  @override
  String get menuItemOpenAnotherFile => 'Открыть другой файл';

  @override
  String get menuItemCheckForUpdates => 'Проверить обновления';

  @override
  String get menuItemSupport => 'Отправить журнал';

  @override
  String get menuItemSupportSubtitle =>
      'Отправлять журналы по электронной почте';

  @override
  String get menuItemForum => 'Форум поддержки';

  @override
  String get menuItemForumSubtitle => 'Сообщить о проблемах и получить помощь';

  @override
  String get menuItemHelp => 'Помощь';

  @override
  String get menuItemHelpSubtitle => 'Показать документацию';

  @override
  String get menuItemAbout => 'О программе';

  @override
  String get actionOpenUrl => 'Открыть URL-адрес';

  @override
  String get passwordPlainText => 'Показать пароль';

  @override
  String get generatorPassword => 'Пароль';

  @override
  String get generatePassword => 'Сгенерировать пароль';

  @override
  String get doneButtonLabel => 'Готово';

  @override
  String get useAsDefault => 'По умолчанию';

  @override
  String get characterSetLowerCase => 'Строчные буквы (а-я)';

  @override
  String get characterSetUpperCase => 'Прописные буквы (А-Я)';

  @override
  String get characterSetNumeric => 'Числа (0-9)';

  @override
  String get characterSetUmlauts => 'Умляуты (ä)';

  @override
  String get characterSetSpecial => 'Специальные (@%+)';

  @override
  String get length => 'Длина';

  @override
  String get customLength => 'Своя длина';

  @override
  String customLengthHelperText(Object customMinLength) {
    return 'Только для длины > $customMinLength';
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
      other: '$numFilesString файлов сохранено: $files',
      one: 'Сохранён один файл: $files',
    );
    return '$_temp0';
  }

  @override
  String get manageGroups => 'Управление группами';

  @override
  String get lockFiles => 'Заблокировать';

  @override
  String get searchHint => 'Поиск';

  @override
  String get searchButtonLabel => 'Поиск';

  @override
  String get filterButtonLabel => 'Фильтр по группе';

  @override
  String get clear => 'Очистить';

  @override
  String get autofillFilterPrefix => 'Фильтр:';

  @override
  String get autofillMatchPrefix => 'Matching entries for:';

  @override
  String get autofillPrompt => 'Выберите пароль для автозаполнения.';

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
  String get copiedToClipboard => 'Скопировано в буфер обмена.';

  @override
  String get noTitle => '(без заголовка)';

  @override
  String get noUsername => '(без имени пользователя)';

  @override
  String get filterCustomize => 'Настройка …';

  @override
  String get swipeCopyPassword => 'Копировать пароль';

  @override
  String get swipeCopyUsername => 'Копировать имя пользователя';

  @override
  String get copyUsernameNotExists => 'Имя пользователя не определено.';

  @override
  String get copyPasswordNotExists => 'Пароль не определен.';

  @override
  String get doneCopiedPassword => 'Пароль скопирован в буфер обмена.';

  @override
  String get doneCopiedUsername =>
      'Имя пользователя скопировано в буфер обмена.';

  @override
  String get doneCopiedField => 'Скопировано.';

  @override
  String copiedFieldToClipboard(Object fieldName) {
    return '$fieldName скопировано.';
  }

  @override
  String copiedFieldEmpty(Object fieldName) {
    return '$fieldName пустое.';
  }

  @override
  String get emptyPasswordVaultPlaceholder =>
      'У Вас ещё нет паролей в вашей базе данных.';

  @override
  String get emptyPasswordVaultButtonLabel => 'Создайте ваш первый Пароль';

  @override
  String get loading => 'Загрузка';

  @override
  String get loadingFile => 'Загрузка файла …';

  @override
  String get internalFile => 'Локальный файл';

  @override
  String get internalFileSubtitle => 'База данных ранее созданная с OpenValut';

  @override
  String get filePicker => 'Выбор Файла';

  @override
  String get filePickerSubtitle => 'Откройте файл с устройства.';

  @override
  String get credentialsAppBarTitle => 'Учетные данные';

  @override
  String get credentialLabel => 'Введите пароль для:';

  @override
  String get masterPasswordInputLabel => 'Пароль';

  @override
  String get masterPasswordEmptyValidator => 'Пожалуйста, введите Ваш пароль.';

  @override
  String get masterPasswordIncorrectValidator => 'Неверный пароль';

  @override
  String get useKeyFile => 'Использовать файл Ключа';

  @override
  String get saveMasterPasswordBiometric =>
      'Сохранить пароль с биометрической разблокировкой?';

  @override
  String get close => 'Закрыть';

  @override
  String get addNewPassword => 'Добавить Новый Пароль';

  @override
  String get errorOpenFileInvalidFileStructureTitle =>
      'Попытка открыть файл неверного типа';

  @override
  String errorOpenFileInvalidFileStructureBody(Object fileName) {
    return 'Кажется, файл ($fileName) не является валидным файлом KDBX. Пожалуйста, выберите валидный файл KDBX, или создайте новую базу данных паролей.';
  }

  @override
  String get errorOpenFileAlreadyOpenTitle => 'Файл уже открыт';

  @override
  String errorOpenFileAlreadyOpenBody(
    Object databaseName,
    Object openFileSource,
    Object newFileSource,
  ) {
    return 'Выбранная база данных $databaseName уже открыта через $openFileSource (Была попытка открыть её через $newFileSource)';
  }

  @override
  String get loadFromUrl => 'Скачать через URL';

  @override
  String get loadFromUrlEnterUrl => 'Введите URL';

  @override
  String get loadFromUrlErrorEnterFullUrl =>
      'Пожалуйста, введиье полный url начинающийся с http:// или http://';

  @override
  String get loadFromUrlErrorInvalidUrl =>
      'Пожалуйста, введите правильный url.';

  @override
  String get linuxAppArmorWarning =>
      'OpenValut нужны разрешения для взаимодействия с Сервисом Паролей для сохранения учётных данных для облачных хранилищ.\nПожалуйста, введите следующую комманду:';

  @override
  String get cancel => 'Отмена';

  @override
  String get errorLoadFileFromSourceTitle => 'Ошибка во время открытия файла.';

  @override
  String errorLoadFileFromSourceBody(Object source, Object error) {
    return 'Не удалось открыть $source.\n$error';
  }

  @override
  String get errorUnlockFileTitle => 'Не удается открыть файл';

  @override
  String errorUnlockFileBody(Object error) {
    return 'Неизвестная ошибка при попытке открыть файл. $error';
  }

  @override
  String get dialogContinue => 'Продолжить';

  @override
  String get dialogSendErrorReport => 'Отправить отчет об ошибке';

  @override
  String get dialogReportErrorForum => 'Сообщить об ошибке на форум/справка';

  @override
  String get groupFilterDescription =>
      'Выберите, какие группы показывать (рекурсивно)';

  @override
  String get groupFilterSelectAll => 'Выбрать все';

  @override
  String get groupFilterDeselectAll => 'Отменить выбор';

  @override
  String get createSubgroup => 'Создать подгруппу';

  @override
  String get editAction => 'Редактирование';

  @override
  String get mailboxEnableLabel => '(повторно) включить';

  @override
  String get mailboxEnableHint => 'Продолжить получение писем';

  @override
  String get mailboxDisableLabel => 'Отключить';

  @override
  String get mailboxDisableHint => 'Больше не получать электронные письма';

  @override
  String get mailListNoMail => 'У вас пока нет ни одного письма.';

  @override
  String mailboxLabelPrefixForEntry(Object entryLabel) {
    return 'Вход: $entryLabel';
  }

  @override
  String mailboxLabelPrefixUnknownEntry(Object entryUuid) {
    return 'Неизвестная запись: $entryUuid';
  }

  @override
  String mailboxLabelPrefixCreatedAt(Object dateTime) {
    return 'Создано: $dateTime';
  }

  @override
  String get masterPasswordDescription =>
      'Мастер-пароль используется для безопасного шифрования базы данных паролей. Обязательно запомните его, восстановить его будет невозможно.';

  @override
  String get unsavedChangesWarningTitle => 'Несохраненные изменения';

  @override
  String get unsavedChangesWarningBody =>
      'Есть все еще несохраненные изменения. Вы хотите отменить изменения?';

  @override
  String get unsavedChangesDiscardActionLabel => 'Отменить изменения';

  @override
  String get deletePermanentlyAction => 'Удалить навсегда';

  @override
  String get restoreFromRecycleBinAction => 'Восстановить';

  @override
  String get deleteAction => 'Удалить';

  @override
  String get deletedEntry => 'Запись удалена.';

  @override
  String get successfullyDeletedGroup => 'Группа удалена.';

  @override
  String get undoButtonLabel => 'Отменить';

  @override
  String get saveButtonLabel => 'Сохранить';

  @override
  String get webDavSettings => 'Настройки WebDAV';

  @override
  String get webDavUrlLabel => 'URL-адрес';

  @override
  String get webDavUrlHelperText => 'Базовый Url-адрес вашего сервиса WebDAV.';

  @override
  String get webDavUrlValidatorError => 'Пожалуйста, введите URL';

  @override
  String get webDavUrlValidatorInvalidUrlError =>
      'Пожалуйста, введите правильный url с http:// или https://';

  @override
  String get webDavAuthUser => 'Имя пользователя';

  @override
  String get webDavopenvalutword => 'Пароль';

  @override
  String get mergeSuccessDialogTitle =>
      'База данных паролей успешно объединена';

  @override
  String mergeSuccessDialogMessage(Object fileName, Object mergeSummary) {
    return 'Конфликт при сохранении $fileName, он был успешно объединён с удаленным файлом: \n\n$mergeSummary';
  }

  @override
  String forDetailsVisitUrl(Object url) {
    return 'Для получения подробной информации посетите $url';
  }

  @override
  String get openvalutCloudAuthEmailInputLabel =>
      'Введите адрес электронной почты для регистрации или входа.';

  @override
  String get openvalutCloudAuthEmailInvalid =>
      'Пожалуйста, введите правильный адрес электронной почты.';

  @override
  String get openvalutCloudAuthConfirmEmailButtonLabel => 'Подтвердите адрес';

  @override
  String get openvalutCloudAuthConfirmEmail =>
      'Пожалуйста, проверьте вашу электронную почту, чтобы подтвердить ваш адрес электронной почты.';

  @override
  String get openvalutCloudAuthConfirmEmailExplain =>
      'Держите этот экран открытым, пока вы не перешли по ссылке, которую вы получили по электронной почте.';

  @override
  String get openvalutCloudAuthResendExplain =>
      'Если вы не получили электронное письмо, пожалуйста, проверьте папку со спамом. В противном случае вы можете попробовать запросить новую ссылку для подтверждения.';

  @override
  String get openvalutCloudAuthResendButtonLabel =>
      'Запросить новую ссылку для подтверждения';

  @override
  String permanentlyDeleteEntryConfirm(Object title) {
    return 'Это навсегда удалит запись с паролем $title. Это действие не может быть отменено. Вы хотите продолжить?';
  }

  @override
  String get permanentlyDeletedEntrySnackBar => 'Запись окончательно удалена.';

  @override
  String get initialNewGroupName => 'Новая группа';

  @override
  String get deleteGroupErrorTitle => 'Не удается удалить группу';

  @override
  String get deleteGroupErrorBodyContainsGroup =>
      'Эта группа все еще содержит другие группы. Вы можете удалить только пустые группы.';

  @override
  String get deleteGroupErrorBodyContainsEntries =>
      'Эта группа по-прежнему содержит записи с паролем. Вы можете удалить только пустые группы.';

  @override
  String get groupListAppBarTitle => 'Группы';

  @override
  String get groupListFilterAppbarTitle => 'Фильтр по группам';

  @override
  String get clearQuickUnlock => 'Очистить Биометрическое Хранилище';

  @override
  String get clearQuickUnlockSubtitle => 'Удалить сохраненные мастер-пароли';

  @override
  String get unlock => 'Разблокировать';

  @override
  String get closePasswordFiles => 'закрыть базу';

  @override
  String get clearQuickUnlockSuccess =>
      'Сохраненные мастер-пароли удалены из биометрического хранилища.';

  @override
  String get diacOptIn => 'Подпишитесь на Новости о приложении, Опросы.';

  @override
  String get diacOptInSubtitle =>
      'Время от времени будет отправлять сетевой запрос для получения новостей.';

  @override
  String browserAutofillThirdPartyModeTitle(String browserName) {
    return 'Enable AutoFill in $browserName';
  }

  @override
  String browserAutofillThirdPartyModeSubtitle(String browserName) {
    return '$browserName currently uses its own password manager. Tap to open its settings and select “Autofill using another service”, then restart $browserName.';
  }

  @override
  String get enableAutofillDebug => 'Автозаполнение: Включить отладку';

  @override
  String get enableAutofillDebugSubtitle =>
      'Показывает информационные слои для каждого поля ввода';

  @override
  String get createPasswordDatabase => 'Создать базу данных паролей';

  @override
  String get nameNewPasswordDatabase => 'Имя вашей новой базы данных';

  @override
  String get validatorNameMissing =>
      'Пожалуйста, введите имя для вашей новой базы данных.';

  @override
  String get masterPasswordHelpText =>
      'Выберите мастер-пароль. Не забудьте его запомнить.';

  @override
  String get inputMasterPasswordText => 'Мастер-пароль';

  @override
  String get masterPasswordMissingCreate =>
      'Пожалуйста, введите безопасный, запоминающийся пароль.';

  @override
  String get createDatabaseAction => 'Создать базу данных';

  @override
  String get databaseExistsError => 'Файл уже существует';

  @override
  String databaseExistsErrorDescription(Object filePath) {
    return 'Ошибка во время создания базы данных $filePath. Файл уже существует. Пожалуйста, выберите другое имя.';
  }

  @override
  String get databaseCreateDefaultName => 'Личные Пароли';

  @override
  String get preferenceDynamicLoadIcons => 'Динамически загружать иконки';

  @override
  String preferenceDynamicLoadIconsSubtitle(Object urlFieldName) {
    return 'Будут посылаться http запросы со значением поля $urlFieldName для загрузки иконок сайтов.';
  }

  @override
  String passwordScore(Object score) {
    return 'Надежность: $score из 4';
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
  String get entryInfoGroup => 'Группа:';

  @override
  String get entryInfoLastModified => 'Последняя дата изменения:';

  @override
  String movedEntryToGroup(Object groupName) {
    return 'Перемещена запись в $groupName';
  }

  @override
  String sizeBytesStoredopenvalutCloud(Object count) {
    return '$count байт, сохранено в облаке OpenValut';
  }

  @override
  String sizeBytes(Object count) {
    return '$count байтов';
  }

  @override
  String get entryAttachmentSizeWarning =>
      'Вложенные файлы будут встроены в файл пароля. Это может значительно увеличить время необходимое для открытия/сохранения паролей.';

  @override
  String get iconPngSizeWarning =>
      'Пользовательские значки будут встроены в файл пароля. Это может значительно увеличить время, необходимое для открытия/сохранения паролей.';

  @override
  String get notPngError => 'Выбранный файл не является PNG.';

  @override
  String get entryAddField => 'Добавить поле';

  @override
  String get entryCustomField => 'Настраиваемое поле';

  @override
  String get entryCustomFieldTitle => 'Добавление нового настраиваемого поля';

  @override
  String get entryCustomFieldInputLabel => 'Введите имя поля';

  @override
  String get swipeCopyField => 'Скопировать поле';

  @override
  String get fieldRename => 'Переименовать';

  @override
  String get fieldGeneratePassword => 'Сгенерировать пароль …';

  @override
  String get fieldProtect => 'Защитить значение';

  @override
  String get fieldUnprotect => 'Не защищать значение';

  @override
  String get fieldPresent => 'Показать';

  @override
  String get fieldGenerateEmail => 'Сгенерировать почту';

  @override
  String get onboardingBackToOnboarding => 'Тур';

  @override
  String get onboardingBackToOnboardingSubtitle =>
      'Переживите опыт первого запуска 😅️';

  @override
  String get onboardingHeadline => 'Давайте обезопасим Ваши пароли!';

  @override
  String get onboardingQuestion => 'Вы использовали менеджер паролей раньше?';

  @override
  String get onboardingYesOpenPasswords => 'Да, открыть мои пароли';

  @override
  String get onboardingNoCreate => 'Я новичок! Научите меня.';

  @override
  String get backupButton => 'СОХРАНИТЬ В ОБЛАКО';

  @override
  String get dismissBackupButton => 'ОТКЛОНИТЬ';

  @override
  String backupWarningMessage(Object databasename) {
    return 'Ваши пароли в $databasename сохранены только локально!';
  }

  @override
  String get saveAs => 'Сохранить в...';

  @override
  String get saving => 'Сохранение';

  @override
  String get increaseValue => 'Увеличить';

  @override
  String get decreaseValue => 'Уменьшить';

  @override
  String get resetValue => 'Сбросить';

  @override
  String cloudStorageAppBarTitle(Object cloudStorageName) {
    return 'Облачное Хранилище - $cloudStorageName';
  }

  @override
  String get cloudStorageLogInCaption =>
      'Вы будете перенаправлены чтобы авторизовать OpenValut для доступа к вашим данным.';

  @override
  String get cloudStorageLogInCode => 'Введите код';

  @override
  String launchUrlError(Object url) {
    return 'Невозможно открыть url. Пожалуйста, откройте $url';
  }

  @override
  String cloudStorageLogInActionLabel(Object cloudStorageName) {
    return 'Войдите в $cloudStorageName';
  }

  @override
  String cloudStorageAuthCodeDialogTitle(Object cloudStorageName) {
    return 'Аутентификация $cloudStorageName';
  }

  @override
  String get cloudStorageAuthCodeLabel => 'Код аутентификации';

  @override
  String get cloudStorageAuthErrorTitle => 'Ошибка при аутентификации';

  @override
  String cloudStorageAuthErrorMessage(
    Object cloudStorageName,
    Object errorMessage,
  ) {
    return 'Ошибка при попытке аутентификации в $cloudStorageName: $errorMessage';
  }

  @override
  String get cloudStorageSearchBoxLabel => 'Поисковый запрос';

  @override
  String cloudStorageItemsInFolder(Object itemCount) {
    return '$itemCount элементов в этой папке.';
  }

  @override
  String get mailSubject => 'Тема';

  @override
  String get mailFrom => 'Из';

  @override
  String get mailDate => 'Дата';

  @override
  String get mailMailbox => 'Почтовый ящик';

  @override
  String get mailNoData => 'Нет данных';

  @override
  String get mailMailboxesTitle => 'Почтовые ящики';

  @override
  String get mailboxCreateButtonLabel => 'Создать';

  @override
  String get mailboxNameInputDialogTitle =>
      'При необходимости метка для нового почтового ящика';

  @override
  String get mailboxNameInputLabel => '(внутренняя) Метка';

  @override
  String get mailScreenTitle => 'Почта OpenValut';

  @override
  String get mailTabBarTitleMailbox => 'Почтовый ящик';

  @override
  String get mailTabBarTitleMail => 'Почта';

  @override
  String get mailMailboxListEmpty => 'У вас еще нет почтовых ящиков.';

  @override
  String mailMailboxAddressCopied(Object mailboxAddress) {
    return 'Адрес почтового ящика скопирован в буфер обмена: $mailboxAddress';
  }

  @override
  String get errorWhileSavingTitle => 'Ошибка при сохранении';

  @override
  String errorWhileSavingBody(Object errorMessage) {
    return 'Не удалось сохранить файл: $errorMessage';
  }

  @override
  String get databaseDoesNotSupportSaving =>
      'Извините, эта база данных не поддерживает сохранение. Пожалуйста, откройте локальный файл базы данных. Или используйте \"Сохранить как\".';

  @override
  String get otpInvalidKeyTitle => 'Неверный ключ';

  @override
  String get otpInvalidKeyBody =>
      'Данный ввод не является допустимым кодом TOTP base32. Пожалуйста, проверьте введённые данные.';

  @override
  String get otpUnsupportedMigrationTitle => 'Unsupported OTP Migration';

  @override
  String otpUnsupportedMigrationBody(Object uriCount) {
    return 'We currently only support single item migrations. Got $uriCount';
  }

  @override
  String get otpPromptTitle => 'Аутентификация на основе времени';

  @override
  String get otpPromptHelperText =>
      'Пожалуйста, введите ключ, основанный на времени.';

  @override
  String otpErrorMessageGeneration(Object errorMessage) {
    return 'Ошибка при создании кода приглашения: $errorMessage';
  }

  @override
  String get otpCopySecretActionLabel => 'Копировать секрет';

  @override
  String get otpEntryLabel => 'Одноразовый токен';

  @override
  String get entryFieldProtected => 'Защищенное поле. Нажмите, чтобы открыть.';

  @override
  String get entryFieldActionRevealField => 'Показать защищённое поле';

  @override
  String get entryAttachmentOpenActionLabel => 'Открыть';

  @override
  String get entryAttachmentShareActionLabel => 'Поделиться';

  @override
  String get entryAttachmentShareSubject => 'Вложение';

  @override
  String get entryAttachmentSaveActionLabel => 'Сохранить на устройство';

  @override
  String get entryAttachmentRemoveActionLabel => 'Удалить';

  @override
  String entryAttachmentRemoveConfirm(Object attachmentLabel) {
    return 'Вы действительно хотите удалить $attachmentLabel?';
  }

  @override
  String get entryRenameFieldPromptTitle => 'Переименование поля';

  @override
  String get removerecentfile => 'Скрыть';

  @override
  String get entryRenameFieldPromptLabel => 'Введите новое имя для поля';

  @override
  String get promptDialogPasteActionTooltip => 'Вставить из буфера обмена';

  @override
  String get promptDialogPasteHint =>
      'Подсказка: Если вам нужно вставить, попробуйте кнопку слева ;-)';

  @override
  String get genericErrorDialogTitle => 'Ошибка при обработке действия';

  @override
  String genericErrorDialogBody(Object errorMessage) {
    return 'Произошла непредвиденная ошибка. $errorMessage';
  }

  @override
  String get saveAsEntryLocalFile => 'Локальный файл';

  @override
  String get fileTypePngs => 'Изображения (png)';

  @override
  String get selectIconDialogAction => 'ВЫБЕРИТЕ ЗНАЧОК';

  @override
  String get retryDialogActionLabel => 'Повторить';

  @override
  String errorDuringNetworkCall(Object errorMessage) {
    return 'Ошибка во время api вызова. $errorMessage';
  }

  @override
  String get passwordFilterHideDeleted => 'Скрыть удалённые записи';

  @override
  String get passwordFilterOnlyDeleted => 'Удалённые записи';

  @override
  String passwordFilterPrefixForOneGroup(Object groupName) {
    return 'Группа: $groupName';
  }

  @override
  String passwordFilterPrefixForMultipleGroups(Object groupCount) {
    return 'Кастомный фильтр ($groupCount групп)';
  }

  @override
  String get menuItemopenvalutCloudAuthenticate =>
      'Авторизоваться с OpenValut Cloud';

  @override
  String get menuItemopenvalutCloudMailboxes => 'Почтовые ящики OpenValut';

  @override
  String changesWithoutSaving(Object fileName) {
    return 'У вас есть изменения в \"$fileName\", которые не поддерживают запись изменений.';
  }

  @override
  String get changesSaveLocally => 'Сохранить локально';

  @override
  String get clearColor => 'Очистить цвет';

  @override
  String get databaseRenameInputLabel => 'Введите имя базы данных';

  @override
  String get databasePath => 'Путь';

  @override
  String get databaseColor => 'Цвет';

  @override
  String get databaseColorChoose =>
      'Выберите цвет, чтобы отличать среди файлов.';

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
  String get databaseKdbxVersion => 'Версия файла KDBX';

  @override
  String databaseKdbxUpgradeVersion(Object versionName) {
    return 'Обновите до $versionName';
  }

  @override
  String get databaseKdbxUpgradeSuccessful =>
      'Файл успешно обновлён и сохранён.';

  @override
  String get databaseReload => 'Обновить и слить';

  @override
  String progressStatus(Object statusProgress) {
    return 'Статус: $statusProgress';
  }

  @override
  String finishedMerge(Object status) {
    return 'Закончено слитие $status';
  }

  @override
  String get closeAndLockFile => 'Закрыть/заблокровать';

  @override
  String get openvalutHomeScreenTagline =>
      'менеджер паролей, с открым исходных кодом, доступный на всех платформах.';

  @override
  String get addNewPasswordButtonLabel => 'Добавить новый пароль';

  @override
  String get unnamedEntryPlaceholder => '(Безымянный)';

  @override
  String get unnamedGroupPlaceholder => '(Безымянный)';

  @override
  String get unnamedFilePlaceholder => '(Безымянный)';

  @override
  String get editGroupScreenTitle => 'Редактировать группу';

  @override
  String get editGroupGroupNameLabel => 'Имя группы';

  @override
  String get files => 'Файлы';

  @override
  String get newGroupDialogTitle => 'Новая группа';

  @override
  String get newGroupDialogInputLabel => 'Имя новой группы';

  @override
  String get groupActionShowPasswords => 'Показать пароли';

  @override
  String get groupActionDelete => 'Удалить';

  @override
  String get logoutTooltip => 'Выйти';

  @override
  String get successfullyDeletedFileCloudStorage => 'Файл успешно удалён.';

  @override
  String shareDialogTitle(Object fileName) {
    return 'Опции общего доступа для $fileName';
  }

  @override
  String get shareFileActionLabel => 'Поделиться …';

  @override
  String get shareTokenListEmptyScreenPlaceholder =>
      'Вы ещё не поделились файлом.';

  @override
  String get shareTokenNoLabel => 'Нет метки/описания';

  @override
  String get shareTokenReadWrite => 'Чтение/запись';

  @override
  String get shareTokenReadOnly => 'Только чтение';

  @override
  String get shareCreateTokenDialogTitle => 'Поделиться файлом';

  @override
  String get shareCreateTokenReadOnly => 'Только чтение';

  @override
  String get shareCreateTokenReadOnlyHelpText =>
      'Не разрешать сохранение изменений';

  @override
  String get shareCreateTokenLabelText => 'Описание';

  @override
  String get shareCreateTokenLabelHint => 'Поделиться с моим другом';

  @override
  String get shareCreateTokenLabelHelp =>
      'Не обязательная метка чтобы различать код общего доступа.';

  @override
  String get shareCreateTokenSuccess => 'Успешно создан код общего доступа.';

  @override
  String get sharePresentDialogTitle =>
      'Поделиться файлом используя код общего доступа';

  @override
  String get sharePresentDialogHelp =>
      'Используя этот код общего доступа пользователи могут иметь доступ к файлу паролей. Им нужен будет пароль и/или файл ключа чтобы открыть его.';

  @override
  String get sharePresentToken => 'Код доступа';

  @override
  String get sharePresentCopied => 'Код доступа скопирован в буфер обмена.';

  @override
  String get openvalutCloudOpenWithShareCodeTooltip =>
      'Открыть с помощью кода общего доступа';

  @override
  String get openvalutCloudShareFileActionLabel => 'Поделиться';

  @override
  String get preferenceopenvalutCloudAttachmentTitle =>
      'Использовать облачные вложения OpenValut';

  @override
  String get preferenceopenvalutCloudAttachmentSubtitle =>
      'Хранить вложения, зашифрованные в облаке OpenValut, отдельно.';

  @override
  String get shareCodeInputDialogTitle => 'Ввести секретный код доступа';

  @override
  String get shareCodeInputDialogScan => 'Сканировать QR-код';

  @override
  String get shareCodeInputLabel => 'Секретный код доступа';

  @override
  String get shareCodeInputHelperText =>
      'Если вы получили код доступа, вставьте его выше.';

  @override
  String get shareCodeOpen => 'Получен код доступа для OpenValut Cloud?';

  @override
  String get shareCodeOpenScreenTitle => 'Загрузка файла с кодом доступа';

  @override
  String get shareCodeLoadingProgress => 'Загрузка файла …';

  @override
  String get shareCodeOpenFileButtonLabel => 'Открыть';

  @override
  String get shareCodeOpenInstallAppCaption =>
      'Хотите вместо этого открыть этот файл с помощью одного из наших собственных приложений?';

  @override
  String get shareCodeOpenAnotherAppCaption =>
      'Хотите открыть этот файл на другом устройстве?';

  @override
  String get shareCodeOpenInstallAppButtonLabel => 'Установить приложение';

  @override
  String get shareCodeOpenShowCodeButtonLabel => 'Показать код общего доступа';

  @override
  String get changeMasterPasswordActionLabel => 'Изменить мастер-пароль';

  @override
  String get changeMasterPasswordFormSubmit => 'Сохранить с новым паролем';

  @override
  String get changeMasterPasswordSuccess => 'Пароль успешно сохранен.';

  @override
  String get changeMasterPasswordScreenTitle => 'Изменить мастер-пароль';

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
      'Я получил электронную почту и посетил ссылку';

  @override
  String get openvalutCloudAuthNotConfirmed =>
      'Адрес электронной почты еще не подтвержден. Обязательно нажмите ссылку в полученном электронном письме и введите код, чтобы подтвердить свой адрес электронной почты.';

  @override
  String get getHelpButton => 'Получить помощь на форуме';

  @override
  String get shortcutCopyUsername => 'Копировать имя пользователя';

  @override
  String get shortcutCopyPassword => 'Копировать пароль';

  @override
  String get shortcutCopyTotp => 'Копировать TOTP';

  @override
  String get shortcutMoveUp => 'Выбрать предыдущий пароль';

  @override
  String get shortcutMoveDown => 'Выбрать следующий пароль';

  @override
  String get shortcutGeneratePassword => 'Сгенерировать пароль';

  @override
  String get shortcutCopyUrl => 'Копировать URL';

  @override
  String get shortcutOpenUrl => 'Открыть URL-адрес';

  @override
  String get shortcutCancelSearch => 'Отменить поиск';

  @override
  String get shortcutShortcutHelp => 'Справка по сочетанию клавиш';

  @override
  String get shortcutHelpTitle => 'Горячие клавиши';

  @override
  String unexpectedError(String error) {
    return 'Неожиданная ошибка: $error';
  }

  @override
  String get googleDriveMorePermissionsRequired =>
      'Additional permissions needed to access Google Drive.';

  @override
  String get googleDriveRequestPermissionButtonLabel => 'Request Permissions';

  @override
  String get scanQrCodeTitle => 'Scan QR Code.';
}
