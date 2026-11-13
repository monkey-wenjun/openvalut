// ignore_for_file: omit_local_variable_types,unused_local_variable

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

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
  String get entryAddAttachment => 'Lisää Liite';

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
  String get fieldUserName => 'Käyttäjä';

  @override
  String get fieldPassword => 'Salasana';

  @override
  String get fieldWebsite => 'Verkkosivusto';

  @override
  String get fieldTitle => 'Otsikko';

  @override
  String get fieldTotp => 'Kertakäyttöinen salasana (Ajan perusteella)';

  @override
  String get english => 'Englanti';

  @override
  String get german => 'Saksa';

  @override
  String get russian => 'Venäjä';

  @override
  String get ukrainian => 'Ukraina';

  @override
  String get lithuanian => 'Liettua';

  @override
  String get french => 'Ranska';

  @override
  String get spanish => 'Espanja';

  @override
  String get indonesian => 'Indonesia';

  @override
  String get turkish => 'Turkki';

  @override
  String get hebrew => 'Heprea';

  @override
  String get italian => 'Italia';

  @override
  String get chineseSimplified => 'Kiina Yksinkertaistettu';

  @override
  String get chineseTraditional => 'Kiina Perinteinen';

  @override
  String get portugueseBrazilian => 'Portugali, Brasilia';

  @override
  String get slovak => 'Slovakia';

  @override
  String get dutch => 'Hollanti';

  @override
  String get selectItem => 'Valitse';

  @override
  String get selectKeepassFile => 'OpenValut - Valitse KeePass tiedosto';

  @override
  String get selectKeepassFileLabel => 'Valitse KeePass (.kdbx) tiedosto.';

  @override
  String get createNewFile => 'Luo uusi tiedosto';

  @override
  String get openLocalFile => 'Avaa\npaikallinen tiedosto';

  @override
  String get openFile => 'Avaa tiedosto';

  @override
  String get loadFromDropdownMenu => 'Lataa osoitteesta …';

  @override
  String get quickUnlockingFiles => 'Nopea tiedostojen lukituksen avaaminen …';

  @override
  String openFileProgress(Object fileName, Object current, Object totalCount) {
    return 'Avataan $fileName … ($current / $totalCount)';
  }

  @override
  String loadFrom(String cloudStorageName) {
    return 'Lataa osoitteesta $cloudStorageName';
  }

  @override
  String get loadFromRemoteUrl => 'Avaa kdbx URL-osoitteesta';

  @override
  String get createNewKeepass =>
      'Uusi KeePass käyttäjä?\nLuo uusi salasanatietokanta';

  @override
  String get labelLastOpenFiles => 'Viimeksi avatut tiedostot:';

  @override
  String get noFilesHaveBeenOpenYet => 'Yhtään tiedostoa ei ole vielä avattu.';

  @override
  String get preferenceSelectLanguage => 'Valitse kieli';

  @override
  String get preferenceLanguage => 'Kieli';

  @override
  String get preferenceTextScaleFactor => 'Tekstin skaalauskerroin';

  @override
  String get preferenceVisualDensity => 'Näkyvä tiheys';

  @override
  String get preferenceTheme => 'Teema';

  @override
  String get preferenceThemeLight => 'Vaalea';

  @override
  String get preferenceThemeDark => 'Tumma';

  @override
  String get preferenceSystemDefault => 'Järjestelmän oletus';

  @override
  String get preferenceDefault => 'Oletus';

  @override
  String get lockAllFiles => 'Lukitse kaikki avoimet tiedostot';

  @override
  String get preferenceAllowScreenshots => 'Salli sovelluksen kuvakaappaukset';

  @override
  String get preferenceEnableAutoFill => 'Käytä automaattista täyttöä';

  @override
  String get enableAutofillSuggestionBanner =>
      'Voit täyttää toisen sovelluksen kentän ottamalla automaattisen täytön käyttöön!';

  @override
  String get dismissAutofillSuggestionBannerButton => 'HYLKÄÄ';

  @override
  String get enableAutofillSuggestionBannerButton => 'OTA KÄYTTÖÖN!';

  @override
  String get preferenceAutoFillDescription =>
      'Tuettu vain Android Oreo (8.0) tai uudempi.';

  @override
  String get preferenceTitle => 'Asetukset';

  @override
  String get preferenceEnableSystemWideShortcuts =>
      'Ota käyttöön järjestelmän leveät pikakuvakkeet';

  @override
  String get preferenceEnableSystemWideShortcutsHelp =>
      'Rekisteröi ctrl+alt+f järjestelmän pikanäppäimenä avoimeen hakuun.';

  @override
  String get preferencesSearchFields => 'Muokkaa hakukenttiä';

  @override
  String get preferencesSearchFieldPromptTitle => 'Haku kentät';

  @override
  String get preferencesSearchFieldPromptLabel =>
      'Pilkulla erotettu luettelo kentistä, joita käytetään salasanaluettelon hakuun.';

  @override
  String preferencesSearchFieldPromptHelp(
    Object wildCardCharacter,
    Object defaultSearchFields,
  ) {
    return 'Käytä $wildCardCharacter kaikille, jätä tyhjäksi oletukseksi ($defaultSearchFields)';
  }

  @override
  String get aboutAppName => 'OpenValut';

  @override
  String get aboutLinkFeedback =>
      'Toivotamme tervetulleeksi kaikenlaisen palautteen!';

  @override
  String get aboutLinkVisitWebsite => 'Muista myös vierailla sivuillamme';

  @override
  String get aboutLinkGitHub => 'Ja Avoimen Lähdekoodin Projekti';

  @override
  String aboutLogFile(String logFilePath) {
    return 'Lokitiedosto: $logFilePath';
  }

  @override
  String get aboutLinkContributors => 'Näytä Avustajat';

  @override
  String get unableToLaunchUrlTitle => 'Url-osoitetta ei voi avata';

  @override
  String unableToLaunchUrlDescription(Object url, Object openError) {
    return 'Ei voida käynnistää $url: $openError';
  }

  @override
  String get unableToLaunchUrlNoHandler =>
      'Url-osoitteelle ei ole saatavilla sovellusta.';

  @override
  String launchedUrl(Object url) {
    return 'Avattu URL-osoite: $url';
  }

  @override
  String get menuItemGeneratePassword => 'Luo Salasana';

  @override
  String get menuItemPreferences => 'Asetukset';

  @override
  String get menuItemOpenAnotherFile => 'Avaa toinen tiedosto';

  @override
  String get menuItemCheckForUpdates => 'Tarkista päivitykset';

  @override
  String get menuItemSupport => 'Lähetä lokitiedot';

  @override
  String get menuItemSupportSubtitle => 'Lähetä lokitiedot sähköpostitse';

  @override
  String get menuItemForum => 'Tuki Foorumi';

  @override
  String get menuItemForumSubtitle => 'Ilmoita ongelmista ja saa apua';

  @override
  String get menuItemHelp => 'Ohje';

  @override
  String get menuItemHelpSubtitle => 'Näytä dokumentaatio';

  @override
  String get menuItemAbout => 'Tietoja';

  @override
  String get actionOpenUrl => 'Avaa URL-osoite';

  @override
  String get passwordPlainText => 'Näytä salasana';

  @override
  String get generatorPassword => 'Salasana';

  @override
  String get generatePassword => 'Luo Salasana';

  @override
  String get doneButtonLabel => 'Valmis';

  @override
  String get useAsDefault => 'Käytä oletuksena';

  @override
  String get characterSetLowerCase => 'Pienet kirjaimet (a-z)';

  @override
  String get characterSetUpperCase => 'Isot kirjaimet (A-Z)';

  @override
  String get characterSetNumeric => 'Numerot (0-9)';

  @override
  String get characterSetUmlauts => 'Umlautit (ä)';

  @override
  String get characterSetSpecial => 'Erikois (@%+)';

  @override
  String get length => 'Pituus';

  @override
  String get customLength => 'Muokattu Pituus';

  @override
  String customLengthHelperText(Object customMinLength) {
    return 'Käytetään vain pituudeltaan > $customMinLength';
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
      other: '$numFilesString tiedostot tallennettu: $files',
      one: 'Yksi tiedosto tallennettu: $files',
    );
    return '$_temp0';
  }

  @override
  String get manageGroups => 'Hallitse Ryhmiä';

  @override
  String get lockFiles => 'Lukitse Tiedostot';

  @override
  String get searchHint => 'Etsi';

  @override
  String get searchButtonLabel => 'Etsi';

  @override
  String get filterButtonLabel => 'Suodata ryhmän mukaan';

  @override
  String get clear => 'Tyhjennä';

  @override
  String get autofillFilterPrefix => 'Suodatin:';

  @override
  String get autofillMatchPrefix => 'Matching entries for:';

  @override
  String get autofillPrompt =>
      'Valitse salasanan syöttö automaattista täyttöä varten.';

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
  String get copiedToClipboard => 'Kopioitu leikepöydälle.';

  @override
  String get noTitle => '(ei otsikkoa)';

  @override
  String get noUsername => '(ei käyttäjänimeä)';

  @override
  String get filterCustomize => 'Muokkaa …';

  @override
  String get swipeCopyPassword => 'Kopioi Salasana';

  @override
  String get swipeCopyUsername => 'Kopioi Käyttäjänimi';

  @override
  String get copyUsernameNotExists => 'Käyttäjänimeä ei ole määritelty.';

  @override
  String get copyPasswordNotExists =>
      'Merkinnässä ei ole määritetty salasanaa.';

  @override
  String get doneCopiedPassword => 'Salasana kopioitu leikepöydälle.';

  @override
  String get doneCopiedUsername => 'Käyttäjätunnus kopioitu leikepöydälle.';

  @override
  String get doneCopiedField => 'Kopioitu.';

  @override
  String copiedFieldToClipboard(Object fieldName) {
    return '$fieldName kopioitu.';
  }

  @override
  String copiedFieldEmpty(Object fieldName) {
    return '$fieldName on tyhjä.';
  }

  @override
  String get emptyPasswordVaultPlaceholder =>
      'Sinulla ei ole vielä salasanaa tietokannassasi.';

  @override
  String get emptyPasswordVaultButtonLabel => 'Luo ensimmäinen salasanasi';

  @override
  String get loading => 'Ladataan';

  @override
  String get loadingFile => 'Ladataan tiedostoa…';

  @override
  String get internalFile => 'Sisäinen tiedosto';

  @override
  String get internalFileSubtitle => 'Aiemmin OpenValutilla luotu tietokanta';

  @override
  String get filePicker => 'Tiedoston valitsin';

  @override
  String get filePickerSubtitle => 'Avaa tiedosto laitteesta.';

  @override
  String get credentialsAppBarTitle => 'Valtuustiedot';

  @override
  String get credentialLabel => 'Anna salasana:';

  @override
  String get masterPasswordInputLabel => 'Salasana';

  @override
  String get masterPasswordEmptyValidator => 'Syötä salasanasi.';

  @override
  String get masterPasswordIncorrectValidator => 'Väärä salasana';

  @override
  String get useKeyFile => 'Käytä avaintiedostoa';

  @override
  String get saveMasterPasswordBiometric =>
      'Tallennetaanko salasana biometrisellä avaimella?';

  @override
  String get close => 'Sulje';

  @override
  String get addNewPassword => 'Luo Uusi Salasana';

  @override
  String get errorOpenFileInvalidFileStructureTitle =>
      'Yritettiin avata virheellinen tiedostotyyppi';

  @override
  String errorOpenFileInvalidFileStructureBody(Object fileName) {
    return 'Tiedosto ($fileName) ei näytä olevan kelvollinen KDBX- tiedosto. Valitse joko kelvollinen KDBX-tiedosto tai luo uusi salasanan tietokanta.';
  }

  @override
  String get errorOpenFileAlreadyOpenTitle => 'Tiedosto on jo auki';

  @override
  String errorOpenFileAlreadyOpenBody(
    Object databaseName,
    Object openFileSource,
    Object newFileSource,
  ) {
    return 'Valittu tietokanta $databaseName on jo avoinna $openFileSource (Yritettiin avata $newFileSource)';
  }

  @override
  String get loadFromUrl => 'Lataa osoitteesta Url';

  @override
  String get loadFromUrlEnterUrl => 'Kirjoita URL-osoite';

  @override
  String get loadFromUrlErrorEnterFullUrl =>
      'Anna koko Url-osoite, joka alkaa http:// tai https://';

  @override
  String get loadFromUrlErrorInvalidUrl => 'Anna kelvollinen Url-osoite.';

  @override
  String get linuxAppArmorWarning =>
      'OpenValut vaatii luvan kommunikoida Secret Servicen kanssa, jotta se voi tallentaa valtakirjat pilvitallennusta varten.\nSuorita seuraava komento:';

  @override
  String get cancel => 'Peruuta';

  @override
  String get errorLoadFileFromSourceTitle => 'Virhe tiedostoa avattaessa.';

  @override
  String errorLoadFileFromSourceBody(Object source, Object error) {
    return 'Ei voitu avata $source.\n$error';
  }

  @override
  String get errorUnlockFileTitle => 'Tiedostoa ei voi avata';

  @override
  String errorUnlockFileBody(Object error) {
    return 'Tuntematon virhe avattaessa tiedostoa. $error';
  }

  @override
  String get dialogContinue => 'Jatka';

  @override
  String get dialogSendErrorReport => 'Lähetä Virheraportti';

  @override
  String get dialogReportErrorForum => 'Ilmoita virheestä foorumissa/ohjeessa';

  @override
  String get groupFilterDescription =>
      'Valitse, mitkä ryhmät näytetään (rekursiivisesti)';

  @override
  String get groupFilterSelectAll => 'Valitse kaikki';

  @override
  String get groupFilterDeselectAll => 'Poista kaikki valinnat';

  @override
  String get createSubgroup => 'Luo alaryhmä';

  @override
  String get editAction => 'Muokkaa';

  @override
  String get mailboxEnableLabel => '(uudelleen)käyttöönotto';

  @override
  String get mailboxEnableHint => 'Jatka sähköpostien vastaanottamista';

  @override
  String get mailboxDisableLabel => 'Poista Käytöstä';

  @override
  String get mailboxDisableHint => 'Älä enää vastaanota sähköposteja';

  @override
  String get mailListNoMail => 'Sinulla ei ole vielä yhtään sähköpostia.';

  @override
  String mailboxLabelPrefixForEntry(Object entryLabel) {
    return 'Sisäänkirjautuminen: $entryLabel';
  }

  @override
  String mailboxLabelPrefixUnknownEntry(Object entryUuid) {
    return 'Tuntematon kirjautuminen: $entryUuid';
  }

  @override
  String mailboxLabelPrefixCreatedAt(Object dateTime) {
    return 'Luotu osoitteessa: $dateTime';
  }

  @override
  String get masterPasswordDescription =>
      'Pääsalasanaa käytetään salaamaan turvallisesti salasanatietokantasi. Varmista, että muistat sen, sitä ei voi palauttaa.';

  @override
  String get unsavedChangesWarningTitle => 'Tallentamattomat Muutokset';

  @override
  String get unsavedChangesWarningBody =>
      'Tallentamattomia muutoksia on edelleen. Haluatko hylätä muutokset?';

  @override
  String get unsavedChangesDiscardActionLabel => 'Hylkää Muutokset';

  @override
  String get deletePermanentlyAction => 'Poista Pysyvästi';

  @override
  String get restoreFromRecycleBinAction => 'Palauta';

  @override
  String get deleteAction => 'Poista';

  @override
  String get deletedEntry => 'Poistettu merkintä.';

  @override
  String get successfullyDeletedGroup => 'Poistettu ryhmä.';

  @override
  String get undoButtonLabel => 'Kumoa';

  @override
  String get saveButtonLabel => 'Tallenna';

  @override
  String get webDavSettings => 'WebDAV asetukset';

  @override
  String get webDavUrlLabel => 'URL-osoite';

  @override
  String get webDavUrlHelperText => 'WebDAV palvelun Url-osoite.';

  @override
  String get webDavUrlValidatorError => 'Anna URL-osoite';

  @override
  String get webDavUrlValidatorInvalidUrlError =>
      'Syötä kelvollinen Url-osoite http:// tai http://';

  @override
  String get webDavAuthUser => 'Käyttäjätunnus';

  @override
  String get webDavopenvalutword => 'Salasana';

  @override
  String get mergeSuccessDialogTitle =>
      'Salasanan tietokanta yhdistetty onnistuneesti';

  @override
  String mergeSuccessDialogMessage(Object fileName, Object mergeSummary) {
    return 'Ristiriita havaittu tallennettaessa $fileName, se yhdistettiin onnistuneesti etätiedostoon: \n\n$mergeSummary';
  }

  @override
  String forDetailsVisitUrl(Object url) {
    return 'Tarkemmat tiedot $url';
  }

  @override
  String get openvalutCloudAuthEmailInputLabel =>
      'Anna sähköpostiosoite rekisteröityäksesi tai kirjautuaksesi sisään.';

  @override
  String get openvalutCloudAuthEmailInvalid =>
      'Ole hyvä ja syötä toimiva sähköpostiosoite.';

  @override
  String get openvalutCloudAuthConfirmEmailButtonLabel => 'Vahvista osoite';

  @override
  String get openvalutCloudAuthConfirmEmail =>
      'Tarkista sähköpostisi ja vahvista sähköpostiosoitteesi.';

  @override
  String get openvalutCloudAuthConfirmEmailExplain =>
      'Pidä tämä näyttö auki, kunnes vierailet sähköpostissa saamassasi linkissä.';

  @override
  String get openvalutCloudAuthResendExplain =>
      'Jos et ole saanut sähköpostia, tarkista roskapostikansio. Muussa tapauksessa voit yrittää pyytää uuden vahvistuslinkin.';

  @override
  String get openvalutCloudAuthResendButtonLabel =>
      'Pyydä uusi vahvistuslinkki';

  @override
  String permanentlyDeleteEntryConfirm(Object title) {
    return 'Tämä poistaa salasanan merkinnän $title pysyvästi. Tätä ei voi perua. Haluatko jatkaa?';
  }

  @override
  String get permanentlyDeletedEntrySnackBar => 'Poistettu pysyvästi.';

  @override
  String get initialNewGroupName => 'Uusi Ryhmä';

  @override
  String get deleteGroupErrorTitle => 'Ryhmää ei voi poistaa';

  @override
  String get deleteGroupErrorBodyContainsGroup =>
      'Tämä ryhmä sisältää edelleen muita ryhmiä. Voit tällä hetkellä poistaa vain tyhjiä ryhmiä.';

  @override
  String get deleteGroupErrorBodyContainsEntries =>
      'Tämä ryhmä sisältää edelleen salasanamerkintöjä. Tällä hetkellä voit poistaa vain tyhjiä ryhmiä.';

  @override
  String get groupListAppBarTitle => 'Ryhmät';

  @override
  String get groupListFilterAppbarTitle => 'Suodata ryhmien mukaan';

  @override
  String get clearQuickUnlock => 'Tyhjennä Biometrinen Tallennustila';

  @override
  String get clearQuickUnlockSubtitle => 'Poista tallennetut pääsalasanat';

  @override
  String get unlock => 'Lukitse Tiedostot';

  @override
  String get closePasswordFiles => 'sulje salasanatiedostot';

  @override
  String get clearQuickUnlockSuccess =>
      'Tallennetut pääsalasanat poistettiin biometrisesta tallennustilasta.';

  @override
  String get diacOptIn => 'Valitse sovelluksen sisäiset uutiset, kyselyt.';

  @override
  String get diacOptInSubtitle =>
      'Lähettää toisinaan verkkopyynnön noutaakseen uutisia.';

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
      'Automaattinen täyttö: Ota virheenkorjaus käyttöön';

  @override
  String get enableAutofillDebugSubtitle =>
      'Näyttää kaikkien syöttökenttien tiedot';

  @override
  String get createPasswordDatabase => 'Luo salasanatietokanta';

  @override
  String get nameNewPasswordDatabase => 'Uuden tietokannan nimi';

  @override
  String get validatorNameMissing =>
      'Ole hyvä ja syötä nimi uudelle tietokannalle.';

  @override
  String get masterPasswordHelpText =>
      'Valitse turvallinen pääsalasana. Varmista, että muistat sen.';

  @override
  String get inputMasterPasswordText => 'Pääsalasana';

  @override
  String get masterPasswordMissingCreate =>
      'Anna turvallinen, muistettava salasana.';

  @override
  String get createDatabaseAction => 'Luo Tietokanta';

  @override
  String get databaseExistsError => 'Tiedosto On Olemassa';

  @override
  String databaseExistsErrorDescription(Object filePath) {
    return 'Virhe luotaessa tietokantaa $filePath. Tiedosto on jo olemassa. Valitse toinen nimi.';
  }

  @override
  String get databaseCreateDefaultName => 'Henkilökohtaiset salasanat';

  @override
  String get preferenceDynamicLoadIcons => 'Lataa kuvakkeet dynaamisesti';

  @override
  String preferenceDynamicLoadIconsSubtitle(Object urlFieldName) {
    return 'Tehdään http pyyntöjä, joiden arvo on $urlFieldName kentässä, ladataksesi verkkosivujen kuvakkeet.';
  }

  @override
  String passwordScore(Object score) {
    return 'Vahvuus: $score / 4';
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
  String get entryInfoFile => 'Tiedosto:';

  @override
  String get entryInfoGroup => 'Ryhmä:';

  @override
  String get entryInfoLastModified => 'Viimeksi Muokattu:';

  @override
  String movedEntryToGroup(Object groupName) {
    return 'Siirretty sisäänkirjaus kohteeseen $groupName';
  }

  @override
  String sizeBytesStoredopenvalutCloud(Object count) {
    return '$count tavua, tallennettu openvalut-pilveen';
  }

  @override
  String sizeBytes(Object count) {
    return '$count tavua';
  }

  @override
  String get entryAttachmentSizeWarning =>
      'Liitetiedostot upotetaan salasanatiedostoon. Tämä voi merkittävästi pidentää salasanojen avaamiseen/tallennukseen tarvittavaa aikaa.';

  @override
  String get iconPngSizeWarning =>
      'Mukautetut kuvakkeet upotetaan salasanatiedostoon. Tämä voi merkittävästi pidentää salasanojen avaamiseen/tallennukseen tarvittavaa aikaa.';

  @override
  String get notPngError => 'Valittu tiedosto ei ole PNG.';

  @override
  String get entryAddField => 'Lisää Kenttä';

  @override
  String get entryCustomField => 'Muokattu Kenttä';

  @override
  String get entryCustomFieldTitle => 'Uuden mukautetun kentän lisääminen';

  @override
  String get entryCustomFieldInputLabel => 'Anna kentälle nimi';

  @override
  String get swipeCopyField => 'Kopioi Kenttä';

  @override
  String get fieldRename => 'Uudelleennimeä';

  @override
  String get fieldGeneratePassword => 'Luo Salasana…';

  @override
  String get fieldProtect => 'Suojaa Arvo';

  @override
  String get fieldUnprotect => 'Suojausarvon poistaminen';

  @override
  String get fieldPresent => 'Esittää';

  @override
  String get fieldGenerateEmail => 'Luo sähköpostiosoite';

  @override
  String get onboardingBackToOnboarding => 'Kierros';

  @override
  String get onboardingBackToOnboardingSubtitle =>
      'Koe uudelleen ensimmäinen kokemus: grinning_face_with_hikinen';

  @override
  String get onboardingHeadline => 'Tehdään salasanasi turvallisiksi!';

  @override
  String get onboardingQuestion =>
      'Oletko aiemmin käyttänyt salasanojen hallintaa?';

  @override
  String get onboardingYesOpenPasswords => 'Kyllä, avaa salasanani';

  @override
  String get onboardingNoCreate => 'Olen uusi! Aloita.';

  @override
  String get backupButton => 'TALLENNA PILVEEN';

  @override
  String get dismissBackupButton => 'HYLKÄÄ';

  @override
  String backupWarningMessage(Object databasename) {
    return 'Salasanasi $databasename tallennetaan vain paikallisesti!';
  }

  @override
  String get saveAs => 'Tallenna kohteeseen...';

  @override
  String get saving => 'Tallennetaan';

  @override
  String get increaseValue => 'Lisää';

  @override
  String get decreaseValue => 'Vähennä';

  @override
  String get resetValue => 'Nollaa';

  @override
  String cloudStorageAppBarTitle(Object cloudStorageName) {
    return 'Pilvitallennustila - $cloudStorageName';
  }

  @override
  String get cloudStorageLogInCaption =>
      'Sinut ohjataan uudelleen todentamaan OpenValut jotta voit käyttää tietojasi.';

  @override
  String get cloudStorageLogInCode => 'Syötä koodi';

  @override
  String launchUrlError(Object url) {
    return 'URL-osoitetta ei voitu avata. Käy osoitteessa $url';
  }

  @override
  String cloudStorageLogInActionLabel(Object cloudStorageName) {
    return 'Kirjaudu sisään $cloudStorageName';
  }

  @override
  String cloudStorageAuthCodeDialogTitle(Object cloudStorageName) {
    return '$cloudStorageName Tunnistautuminen';
  }

  @override
  String get cloudStorageAuthCodeLabel => 'Todennuskoodi';

  @override
  String get cloudStorageAuthErrorTitle => 'Virhe todennuksen aikana';

  @override
  String cloudStorageAuthErrorMessage(
    Object cloudStorageName,
    Object errorMessage,
  ) {
    return 'Virhe, kun yritetään tunnistautua $cloudStorageName: $errorMessage';
  }

  @override
  String get cloudStorageSearchBoxLabel => 'Hakukysely';

  @override
  String cloudStorageItemsInFolder(Object itemCount) {
    return '$itemCount kohdetta tässä kansiossa.';
  }

  @override
  String get mailSubject => 'Aihe';

  @override
  String get mailFrom => 'Alkaen';

  @override
  String get mailDate => 'Päivämäärä';

  @override
  String get mailMailbox => 'Sähköpostilaatikko';

  @override
  String get mailNoData => 'Ei Dataa';

  @override
  String get mailMailboxesTitle => 'Sähköpostilaatikko';

  @override
  String get mailboxCreateButtonLabel => 'Luo';

  @override
  String get mailboxNameInputDialogTitle =>
      'Valinnainen merkintä uudelle postilaatikolle';

  @override
  String get mailboxNameInputLabel => '(Sisäinen) Merkki';

  @override
  String get mailScreenTitle => 'OpenValut Sähköposti';

  @override
  String get mailTabBarTitleMailbox => 'Sähköpostilaatikko';

  @override
  String get mailTabBarTitleMail => 'Sähköposti';

  @override
  String get mailMailboxListEmpty =>
      'Sinulla ei ole vielä yhtään sähköpostipostilaatikkoa.';

  @override
  String mailMailboxAddressCopied(Object mailboxAddress) {
    return 'Kopioi postilaatikon osoite leikepöydälle: $mailboxAddress';
  }

  @override
  String get errorWhileSavingTitle => 'Virhe tallennettaessa';

  @override
  String errorWhileSavingBody(Object errorMessage) {
    return 'Tiedostoa ei voi tallentaa: $errorMessage';
  }

  @override
  String get databaseDoesNotSupportSaving =>
      'Valitettavasti tämä tietokanta ei tue tallennusta. Avaa paikallinen tietokantatiedosto. Tai käytä \"Tallenna nimellä\".';

  @override
  String get otpInvalidKeyTitle => 'Virheellinen Avain';

  @override
  String get otpInvalidKeyBody =>
      'Annettu syöte ei ole kelvollinen base32 TOTP koodi. Tarkista syötteesi.';

  @override
  String get otpUnsupportedMigrationTitle => 'Unsupported OTP Migration';

  @override
  String otpUnsupportedMigrationBody(Object uriCount) {
    return 'We currently only support single item migrations. Got $uriCount';
  }

  @override
  String get otpPromptTitle => 'Aikaperusteinen Todennus';

  @override
  String get otpPromptHelperText => 'Ole hyvä ja syötä aikaperusteinen avain.';

  @override
  String otpErrorMessageGeneration(Object errorMessage) {
    return 'Virhe luotaessa kutsukoodia: $errorMessage';
  }

  @override
  String get otpCopySecretActionLabel => 'Kopioi Salaus';

  @override
  String get otpEntryLabel => 'Kertakäyttöinen merkki';

  @override
  String get entryFieldProtected => 'Suojattu kenttä. Napsauta paljastaaksesi.';

  @override
  String get entryFieldActionRevealField => 'Näytä suojattu kenttä';

  @override
  String get entryAttachmentOpenActionLabel => 'Avaa';

  @override
  String get entryAttachmentShareActionLabel => 'Jaa';

  @override
  String get entryAttachmentShareSubject => 'Liite';

  @override
  String get entryAttachmentSaveActionLabel => 'Tallenna laitteeseen';

  @override
  String get entryAttachmentRemoveActionLabel => 'Poista';

  @override
  String entryAttachmentRemoveConfirm(Object attachmentLabel) {
    return 'Haluatko varmasti poistaa $attachmentLabel?';
  }

  @override
  String get entryRenameFieldPromptTitle => 'Nimetään kenttä uudelleen';

  @override
  String get removerecentfile => 'Piilota';

  @override
  String get entryRenameFieldPromptLabel => 'Kirjoita kentälle uusi nimi';

  @override
  String get promptDialogPasteActionTooltip => 'Liitä leikepöydältä';

  @override
  String get promptDialogPasteHint =>
      'Vinkki: Jos haluat liittää, kokeile vasemmalla olevaa painiketta ;-)';

  @override
  String get genericErrorDialogTitle => 'Virhe toimintoa käsiteltäessä';

  @override
  String genericErrorDialogBody(Object errorMessage) {
    return 'Tapahtui odottamaton virhe. $errorMessage';
  }

  @override
  String get saveAsEntryLocalFile => 'Paikallinen Tiedosto';

  @override
  String get fileTypePngs => 'Kuvat (png)';

  @override
  String get selectIconDialogAction => 'VALITSE ICON';

  @override
  String get retryDialogActionLabel => 'PALAUTA';

  @override
  String errorDuringNetworkCall(Object errorMessage) {
    return 'Virhe api puhelun aikana. $errorMessage';
  }

  @override
  String get passwordFilterHideDeleted => 'Piilota Poistetut Merkinnät';

  @override
  String get passwordFilterOnlyDeleted => 'Poistetut Merkinnät';

  @override
  String passwordFilterPrefixForOneGroup(Object groupName) {
    return 'Ryhmä: $groupName';
  }

  @override
  String passwordFilterPrefixForMultipleGroups(Object groupCount) {
    return 'Mukautettu Suodatin ($groupCount Ryhmää)';
  }

  @override
  String get menuItemopenvalutCloudAuthenticate =>
      'Todennus OpenValut Cloudilla';

  @override
  String get menuItemopenvalutCloudMailboxes => 'OpenValut Postilaatikot';

  @override
  String changesWithoutSaving(Object fileName) {
    return 'Sinulla on muutoksia kohteessa \"$fileName\", joka ei tue muutosten kirjoittamista.';
  }

  @override
  String get changesSaveLocally => 'Tallenna paikallisesti';

  @override
  String get clearColor => 'Tyhjennä Väri';

  @override
  String get databaseRenameInputLabel => 'Anna tietokannan nimi';

  @override
  String get databasePath => 'Polku';

  @override
  String get databaseColor => 'Väri';

  @override
  String get databaseColorChoose =>
      'Valitse väri, joka erottaa tiedostot toisistaan.';

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
  String get databaseKdbxVersion => 'Kdbx- Tiedostoversio';

  @override
  String databaseKdbxUpgradeVersion(Object versionName) {
    return 'Päivitä $versionName';
  }

  @override
  String get databaseKdbxUpgradeSuccessful =>
      'Tiedosto päivitettiin onnistuneesti ja tallennettu.';

  @override
  String get databaseReload => 'Päivitä ja yhdistä';

  @override
  String progressStatus(Object statusProgress) {
    return 'Tila: $statusProgress';
  }

  @override
  String finishedMerge(Object status) {
    return 'Yhdistäminen valmis $status';
  }

  @override
  String get closeAndLockFile => 'Sulje/Lukitse';

  @override
  String get openvalutHomeScreenTagline =>
      'salasanojen hallinta, avoin lähdekoodi, saatavilla kaikilla alustoilla.';

  @override
  String get addNewPasswordButtonLabel => 'Luo Uusi Salasana';

  @override
  String get unnamedEntryPlaceholder => '(Nimetön)';

  @override
  String get unnamedGroupPlaceholder => '(Nimetön)';

  @override
  String get unnamedFilePlaceholder => '(Nimetön)';

  @override
  String get editGroupScreenTitle => 'Muokkaa Ryhmää';

  @override
  String get editGroupGroupNameLabel => 'Ryhmän Nimi';

  @override
  String get files => 'Tiedostot';

  @override
  String get newGroupDialogTitle => 'Uusi Ryhmä';

  @override
  String get newGroupDialogInputLabel => 'Uuden ryhmän nimi';

  @override
  String get groupActionShowPasswords => 'Näytä salasanat';

  @override
  String get groupActionDelete => 'Poista';

  @override
  String get logoutTooltip => 'Kirjaudu Ulos';

  @override
  String get successfullyDeletedFileCloudStorage =>
      'Tiedosto poistettiin onnistuneesti.';

  @override
  String shareDialogTitle(Object fileName) {
    return 'Jakamisen vaihtoehdot kohteelle $fileName';
  }

  @override
  String get shareFileActionLabel => 'Jaa …';

  @override
  String get shareTokenListEmptyScreenPlaceholder =>
      'Tiedostoa ei ole vielä jaettu.';

  @override
  String get shareTokenNoLabel => 'Ei Tunnusta/Kuvausta';

  @override
  String get shareTokenReadWrite => 'Luettu/Kirjoitettu';

  @override
  String get shareTokenReadOnly => 'Vain luku';

  @override
  String get shareCreateTokenDialogTitle => 'Jaa tiedosto';

  @override
  String get shareCreateTokenReadOnly => 'Vain luku';

  @override
  String get shareCreateTokenReadOnlyHelpText =>
      'Älä salli muutosten tallentamista';

  @override
  String get shareCreateTokenLabelText => 'Kuvaus';

  @override
  String get shareCreateTokenLabelHint => 'Jaa ystäväni kanssa';

  @override
  String get shareCreateTokenLabelHelp =>
      'Valinnainen tunniste jakamiskoodin erottamiseksi.';

  @override
  String get shareCreateTokenSuccess => 'Jakamiskoodin luominen onnistui.';

  @override
  String get sharePresentDialogTitle =>
      'Jaa tiedosto salaisella jakamiskoodilla';

  @override
  String get sharePresentDialogHelp =>
      'Seuraavan jakamiskoodin avulla käyttäjät voivat käyttää salasanatiedostoa. He tarvitsevat salasanan ja/tai avaintiedoston avatakseen sen.';

  @override
  String get sharePresentToken => 'Jaa Koodi';

  @override
  String get sharePresentCopied => 'Jakamiskoodi kopioitu leikepöydälle.';

  @override
  String get openvalutCloudOpenWithShareCodeTooltip => 'Avaa jakamiskoodilla';

  @override
  String get openvalutCloudShareFileActionLabel => 'Jaa';

  @override
  String get preferenceopenvalutCloudAttachmentTitle =>
      'Käytä OpenValut Cloud -liitteitä';

  @override
  String get preferenceopenvalutCloudAttachmentSubtitle =>
      'Tallenna Liitteet salattuna OpenValut Cloudiin erikseen.';

  @override
  String get shareCodeInputDialogTitle => 'Syötä salainen jakamiskoodi';

  @override
  String get shareCodeInputDialogScan => 'Skannaa QR-koodi';

  @override
  String get shareCodeInputLabel => 'Salainen jakamiskoodi';

  @override
  String get shareCodeInputHelperText =>
      'Jos olet saanut jakamiskoodin, liitä se yllä.';

  @override
  String get shareCodeOpen => 'Saitko OpenValut Cloudin jakamiskoodin?';

  @override
  String get shareCodeOpenScreenTitle => 'Ladataan tiedostoa jakamiskoodilla';

  @override
  String get shareCodeLoadingProgress => 'Ladataan tiedostoa…';

  @override
  String get shareCodeOpenFileButtonLabel => 'AVAA';

  @override
  String get shareCodeOpenInstallAppCaption =>
      'Haluatko avata tämän tiedoston jollakin natiivilla sovelluksellamme?';

  @override
  String get shareCodeOpenAnotherAppCaption =>
      'Haluatko avata tämän tiedoston toisella laitteella?';

  @override
  String get shareCodeOpenInstallAppButtonLabel => 'Asenna Sovellus';

  @override
  String get shareCodeOpenShowCodeButtonLabel => 'Näytä Jakamiskoodi';

  @override
  String get changeMasterPasswordActionLabel => 'Vaihda Pääsalasana';

  @override
  String get changeMasterPasswordFormSubmit => 'Tallenna uudella salasanalla';

  @override
  String get changeMasterPasswordSuccess => 'Pääsalasanan tallennus onnistui.';

  @override
  String get changeMasterPasswordScreenTitle => 'Vaihda Pääsalasana';

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
      'Sain sähköpostiviestin ja kävin linkistä';

  @override
  String get openvalutCloudAuthNotConfirmed =>
      'Sähköpostiosoitetta ei ole vielä vahvistettu. Varmista, että napsautat saamassasi sähköpostissa olevaa linkkiä ja vahvista sähköpostiosoitteesi ratkaisemalla captcha.';

  @override
  String get getHelpButton => 'Hanki apua foorumilla';

  @override
  String get shortcutCopyUsername => 'Kopioi Käyttäjänimi';

  @override
  String get shortcutCopyPassword => 'Kopioi Salasana';

  @override
  String get shortcutCopyTotp => 'Kopioi TOTP';

  @override
  String get shortcutMoveUp => 'Valitse edellinen salasana';

  @override
  String get shortcutMoveDown => 'Valitse seuraava salasana';

  @override
  String get shortcutGeneratePassword => 'Luo Salasana';

  @override
  String get shortcutCopyUrl => 'Kopioi URL-osoite';

  @override
  String get shortcutOpenUrl => 'Avaa URL-osoite';

  @override
  String get shortcutCancelSearch => 'Keskeytä Haku';

  @override
  String get shortcutShortcutHelp => 'Pikanäppäimen Ohje';

  @override
  String get shortcutHelpTitle => 'Pikanäppäimet';

  @override
  String unexpectedError(String error) {
    return 'Odottamaton virhe: $error';
  }

  @override
  String get googleDriveMorePermissionsRequired =>
      'Additional permissions needed to access Google Drive.';

  @override
  String get googleDriveRequestPermissionButtonLabel => 'Request Permissions';

  @override
  String get scanQrCodeTitle => 'Scan QR Code.';
}
