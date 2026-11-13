// ignore_for_file: omit_local_variable_types,unused_local_variable

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

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
  String get entryAddAttachment => 'Aggiungi Allegato';

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
  String get fieldUserName => 'Nome Utente';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldWebsite => 'Sito web';

  @override
  String get fieldTitle => 'Nome';

  @override
  String get fieldTotp => 'Password monouso (varia nel tempo)';

  @override
  String get english => 'Inglese';

  @override
  String get german => 'Tedesco';

  @override
  String get russian => 'Russo';

  @override
  String get ukrainian => 'Ucraino';

  @override
  String get lithuanian => 'Lituano';

  @override
  String get french => 'Francese';

  @override
  String get spanish => 'Spagnolo';

  @override
  String get indonesian => 'Indonesiano';

  @override
  String get turkish => 'Turco';

  @override
  String get hebrew => 'Ebraico';

  @override
  String get italian => 'italiano';

  @override
  String get chineseSimplified => 'Cinese Semplificato';

  @override
  String get chineseTraditional => 'Cinese Tradizionale';

  @override
  String get portugueseBrazilian => 'Portoghese, Brasiliano';

  @override
  String get slovak => 'Slovacco';

  @override
  String get dutch => 'Olandese';

  @override
  String get selectItem => 'Seleziona';

  @override
  String get selectKeepassFile => 'OpenValut - Seleziona il File KeePass';

  @override
  String get selectKeepassFileLabel => 'Seleziona un file KeePass ( .kdbx).';

  @override
  String get createNewFile => 'Crea un Nuovo File';

  @override
  String get openLocalFile => 'Apri\nFile Locale';

  @override
  String get openFile => 'Apri File';

  @override
  String get loadFromDropdownMenu => 'Carica da …';

  @override
  String get quickUnlockingFiles => 'Sblocco rapido dei file…';

  @override
  String openFileProgress(Object fileName, Object current, Object totalCount) {
    return 'Apertura $fileName … ($current / $totalCount)';
  }

  @override
  String loadFrom(String cloudStorageName) {
    return 'Carica da $cloudStorageName';
  }

  @override
  String get loadFromRemoteUrl => 'Apri kdbx da URL';

  @override
  String get createNewKeepass =>
      'Nuovo su KeePass?\nCrea un Nuovo Database per le tue Password';

  @override
  String get labelLastOpenFiles => 'File recenti:';

  @override
  String get noFilesHaveBeenOpenYet => 'Nessun file è stato ancora aperto.';

  @override
  String get preferenceSelectLanguage => 'Seleziona la lingua';

  @override
  String get preferenceLanguage => 'Linguaggio';

  @override
  String get preferenceTextScaleFactor => 'Dimensione Testo';

  @override
  String get preferenceVisualDensity => 'Densità Testo';

  @override
  String get preferenceTheme => 'Tema';

  @override
  String get preferenceThemeLight => 'Chiaro';

  @override
  String get preferenceThemeDark => 'Scuro';

  @override
  String get preferenceSystemDefault => 'Predefinito Di Sistema';

  @override
  String get preferenceDefault => 'Predefinito';

  @override
  String get lockAllFiles => 'Blocca tutti i file aperti';

  @override
  String get preferenceAllowScreenshots => 'Consenti screenshot dell\'app';

  @override
  String get preferenceEnableAutoFill => 'Abilita riempimento automatico';

  @override
  String get enableAutofillSuggestionBanner =>
      'Puoi riempire il campo di altre applicazioni abilitando l\'auto-riempimento!';

  @override
  String get dismissAutofillSuggestionBannerButton => 'NASCONDI';

  @override
  String get enableAutofillSuggestionBannerButton => 'ABILITA!';

  @override
  String get preferenceAutoFillDescription =>
      'Supportato solo su Android Oreo (8.0) o versioni successive.';

  @override
  String get preferenceTitle => 'Impostazioni';

  @override
  String get preferenceEnableSystemWideShortcuts =>
      'Abilita le scorciatoie di sistema';

  @override
  String get preferenceEnableSystemWideShortcutsHelp =>
      'Registra ctrl+alt+f come scorciatoia di sistema per aprire la ricerca.';

  @override
  String get preferencesSearchFields => 'Personalizza i campi di ricerca';

  @override
  String get preferencesSearchFieldPromptTitle => 'Cerca i campi';

  @override
  String get preferencesSearchFieldPromptLabel =>
      'Elenco di campi separati da virgole da usare nella ricerca di una lista di password.';

  @override
  String preferencesSearchFieldPromptHelp(
    Object wildCardCharacter,
    Object defaultSearchFields,
  ) {
    return 'Usa $wildCardCharacter per tutti, lascia vuoto per impostazione predefinita ($defaultSearchFields)';
  }

  @override
  String get aboutAppName => 'OpenValut';

  @override
  String get aboutLinkFeedback => 'Siamo aperti a qualsiasi suggerimento!';

  @override
  String get aboutLinkVisitWebsite => 'Assicurati di visitare il nostro sito';

  @override
  String get aboutLinkGitHub => 'E supportare il progetto su GitHub';

  @override
  String aboutLogFile(String logFilePath) {
    return 'File di log: $logFilePath';
  }

  @override
  String get aboutLinkContributors => 'Mostra collaboratori';

  @override
  String get unableToLaunchUrlTitle => 'Impossibile aprire l\'URL';

  @override
  String unableToLaunchUrlDescription(Object url, Object openError) {
    return 'Impossibile aprire $url: $openError';
  }

  @override
  String get unableToLaunchUrlNoHandler =>
      'Nessuna applicazione disponibile per l\'URL.';

  @override
  String launchedUrl(Object url) {
    return 'URL aperto: $url';
  }

  @override
  String get menuItemGeneratePassword => 'Genera una Password';

  @override
  String get menuItemPreferences => 'Impostazioni';

  @override
  String get menuItemOpenAnotherFile => 'Apri un altro file';

  @override
  String get menuItemCheckForUpdates => 'Verifica aggiornamenti';

  @override
  String get menuItemSupport => 'Invia i log';

  @override
  String get menuItemSupportSubtitle => 'Invia i log via email';

  @override
  String get menuItemForum => 'Forum di supporto';

  @override
  String get menuItemForumSubtitle => 'Segnala problemi e ottieni assistenza';

  @override
  String get menuItemHelp => 'Aiuto';

  @override
  String get menuItemHelpSubtitle => 'Visualizza la documentazione';

  @override
  String get menuItemAbout => 'Informazioni';

  @override
  String get actionOpenUrl => 'Apri URL';

  @override
  String get passwordPlainText => 'Mostra password';

  @override
  String get generatorPassword => 'Password';

  @override
  String get generatePassword => 'Genera una Password';

  @override
  String get doneButtonLabel => 'Fatto';

  @override
  String get useAsDefault => 'Usa come Predefinito';

  @override
  String get characterSetLowerCase => 'Minuscole (a-z)';

  @override
  String get characterSetUpperCase => 'Maiuscole (A-Z)';

  @override
  String get characterSetNumeric => 'Numerici (0-9)';

  @override
  String get characterSetUmlauts => 'Accenti (ä)';

  @override
  String get characterSetSpecial => 'Speciali (@%+)';

  @override
  String get length => 'Lunghezza';

  @override
  String get customLength => 'Lunghezza Personalizzata';

  @override
  String customLengthHelperText(Object customMinLength) {
    return 'Valore utilizzato solo se la lunghezza è > $customMinLength';
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
      other: '$numFilesString file salvati: $files',
      one: 'Un file salvato: $files',
    );
    return '$_temp0';
  }

  @override
  String get manageGroups => 'Gestisci I Gruppi';

  @override
  String get lockFiles => 'Nascondi i file';

  @override
  String get searchHint => 'Cerca';

  @override
  String get searchButtonLabel => 'Cerca';

  @override
  String get filterButtonLabel => 'Filtra per gruppo';

  @override
  String get clear => 'Rimuovi';

  @override
  String get autofillFilterPrefix => 'Filtro:';

  @override
  String get autofillMatchPrefix => 'Matching entries for:';

  @override
  String get autofillPrompt => 'Seleziona la password per l\'auto-riempimento.';

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
  String get copiedToClipboard => 'Copiato negli appunti.';

  @override
  String get noTitle => '(nome password)';

  @override
  String get noUsername => '(nome utente)';

  @override
  String get filterCustomize => 'Personalizza …';

  @override
  String get swipeCopyPassword => 'Copia la Password';

  @override
  String get swipeCopyUsername => 'Copia il Nome Utente';

  @override
  String get copyUsernameNotExists =>
      'La voce non ha alcun nome utente definito.';

  @override
  String get copyPasswordNotExists =>
      'La voce non ha alcuna password definita.';

  @override
  String get doneCopiedPassword => 'Password copiata negli appunti.';

  @override
  String get doneCopiedUsername => 'Nome utente copiato negli appunti.';

  @override
  String get doneCopiedField => 'Copiato.';

  @override
  String copiedFieldToClipboard(Object fieldName) {
    return '$fieldName copiato.';
  }

  @override
  String copiedFieldEmpty(Object fieldName) {
    return '$fieldName è vuoto.';
  }

  @override
  String get emptyPasswordVaultPlaceholder =>
      'Non hai alcuna password nel tuo database.';

  @override
  String get emptyPasswordVaultButtonLabel => 'Crea la tua prima password';

  @override
  String get loading => 'Caricamento';

  @override
  String get loadingFile => 'Caricamento del file …';

  @override
  String get internalFile => 'File interno';

  @override
  String get internalFileSubtitle =>
      'Database creato in precedenza con OpenValut';

  @override
  String get filePicker => 'Sfoglia';

  @override
  String get filePickerSubtitle => 'Apri il file dal dispositivo.';

  @override
  String get credentialsAppBarTitle => 'Credenziali';

  @override
  String get credentialLabel => 'Inserisci la password per:';

  @override
  String get masterPasswordInputLabel => 'Password';

  @override
  String get masterPasswordEmptyValidator => 'Inserisci la password.';

  @override
  String get masterPasswordIncorrectValidator => 'Password errata';

  @override
  String get useKeyFile => 'Usa file autenticazione';

  @override
  String get saveMasterPasswordBiometric =>
      'Salvare la password nella memoria ad accesso biometrico?';

  @override
  String get close => 'Chiudi';

  @override
  String get addNewPassword => 'Aggiungi nuova password';

  @override
  String get errorOpenFileInvalidFileStructureTitle =>
      'Tentato di aprire un tipo di file non valido';

  @override
  String errorOpenFileInvalidFileStructureBody(Object fileName) {
    return 'Il file ($fileName) non sembra essere un file KDBX valido. Scegliere un file KDBX valido o creare un nuovo database di password.';
  }

  @override
  String get errorOpenFileAlreadyOpenTitle => 'File già aperto';

  @override
  String errorOpenFileAlreadyOpenBody(
    Object databaseName,
    Object openFileSource,
    Object newFileSource,
  ) {
    return 'Il database selezionato $databaseName è già aperto da $openFileSource (Si è tentato di aprire da $newFileSource)';
  }

  @override
  String get loadFromUrl => 'Scarica da Url';

  @override
  String get loadFromUrlEnterUrl => 'Inserisci URL';

  @override
  String get loadFromUrlErrorEnterFullUrl =>
      'Per favore inserisci l\'Url completo, a partire da http:// o https://';

  @override
  String get loadFromUrlErrorInvalidUrl =>
      'Per favore inserisci un Url valido.';

  @override
  String get linuxAppArmorWarning =>
      'OpenValut richiede il permesso di comunicare con il Servizio Segreto e di memorizzare le credenziali per l\'archiviazione cloud.\nPer favore, esegui il seguente comando:';

  @override
  String get cancel => 'Elimina';

  @override
  String get errorLoadFileFromSourceTitle => 'Errore nell\'apertura del file.';

  @override
  String errorLoadFileFromSourceBody(Object source, Object error) {
    return 'Impossibile aprire $source.\n$error';
  }

  @override
  String get errorUnlockFileTitle => 'Impossibile aprire il File';

  @override
  String errorUnlockFileBody(Object error) {
    return 'Errore sconosciuto durante l\'apertura del file. $error';
  }

  @override
  String get dialogContinue => 'Continua';

  @override
  String get dialogSendErrorReport => 'Invia Report Errore';

  @override
  String get dialogReportErrorForum => 'Segnala errore nel Forum/Aiuto';

  @override
  String get groupFilterDescription =>
      'Seleziona quali Gruppi mostrare (e relativi sottogruppi)';

  @override
  String get groupFilterSelectAll => 'Seleziona tutto';

  @override
  String get groupFilterDeselectAll => 'Deseleziona tutto';

  @override
  String get createSubgroup => 'Crea Un Sottogruppo';

  @override
  String get editAction => 'Modifica';

  @override
  String get mailboxEnableLabel => '(ri)abilita';

  @override
  String get mailboxEnableHint => 'Continua a ricevere e-mail';

  @override
  String get mailboxDisableLabel => 'Disabilita';

  @override
  String get mailboxDisableHint => 'Non ricevere più email';

  @override
  String get mailListNoMail => 'Non hai ancora nessuna email.';

  @override
  String mailboxLabelPrefixForEntry(Object entryLabel) {
    return 'Voce: $entryLabel';
  }

  @override
  String mailboxLabelPrefixUnknownEntry(Object entryUuid) {
    return 'Voce sconosciuta: $entryUuid';
  }

  @override
  String mailboxLabelPrefixCreatedAt(Object dateTime) {
    return 'Creato il: $dateTime';
  }

  @override
  String get masterPasswordDescription =>
      'La password principale viene utilizzata per crittografare in modo sicuro il tuo database delle password. Assicurati di ricordarla, non può essere ripristinata.';

  @override
  String get unsavedChangesWarningTitle => 'Modifiche Non Salvate';

  @override
  String get unsavedChangesWarningBody =>
      'Ci sono ancora modifiche non salvate. Vuoi annullare le modifiche?';

  @override
  String get unsavedChangesDiscardActionLabel => 'Annulla Modifiche';

  @override
  String get deletePermanentlyAction => 'Elimina definitivamente';

  @override
  String get restoreFromRecycleBinAction => 'Ripristina';

  @override
  String get deleteAction => 'Elimina';

  @override
  String get deletedEntry => 'Voce eliminata.';

  @override
  String get successfullyDeletedGroup => 'Gruppo eliminato.';

  @override
  String get undoButtonLabel => 'Annulla';

  @override
  String get saveButtonLabel => 'Salva';

  @override
  String get webDavSettings => 'Impostazioni WebDAV';

  @override
  String get webDavUrlLabel => 'URL';

  @override
  String get webDavUrlHelperText => 'Base Url al tuo servizio WebDAV.';

  @override
  String get webDavUrlValidatorError => 'Per favore inserisci un URL';

  @override
  String get webDavUrlValidatorInvalidUrlError =>
      'Per favore inserisci un Url valido con http:// o https://';

  @override
  String get webDavAuthUser => 'Nome Utente';

  @override
  String get webDavopenvalutword => 'Password';

  @override
  String get mergeSuccessDialogTitle =>
      'Database di password unito con successo';

  @override
  String mergeSuccessDialogMessage(Object fileName, Object mergeSummary) {
    return 'Conflitto rilevato durante il salvataggio di $fileName, è stato unito con successo con il file remoto: \n\n$mergeSummary';
  }

  @override
  String forDetailsVisitUrl(Object url) {
    return 'Per i dettagli visita $url';
  }

  @override
  String get openvalutCloudAuthEmailInputLabel =>
      'Inserisci l\'indirizzo email per registrarti o accedere.';

  @override
  String get openvalutCloudAuthEmailInvalid =>
      'Inserisci un indirizzo email valido.';

  @override
  String get openvalutCloudAuthConfirmEmailButtonLabel =>
      'Conferma l\'indirizzo';

  @override
  String get openvalutCloudAuthConfirmEmail =>
      'Controlla le tue email per confermare il tuo indirizzo email.';

  @override
  String get openvalutCloudAuthConfirmEmailExplain =>
      'Mantieni aperta questa schermata finché non avrai visitato il link che hai ricevuto via email.';

  @override
  String get openvalutCloudAuthResendExplain =>
      'Se non hai ricevuto un\'email, controlla la cartella spam. Altrimenti puoi provare a richiedere un nuovo link di conferma.';

  @override
  String get openvalutCloudAuthResendButtonLabel =>
      'Richiedi un nuovo link di conferma';

  @override
  String permanentlyDeleteEntryConfirm(Object title) {
    return 'Questo eliminerà definitivamente la voce di password $title. Questo non può essere annullato. Vuoi continuare?';
  }

  @override
  String get permanentlyDeletedEntrySnackBar =>
      'Voce eliminata definitivamente.';

  @override
  String get initialNewGroupName => 'Crea Gruppo';

  @override
  String get deleteGroupErrorTitle => 'Impossibile eliminare il gruppo';

  @override
  String get deleteGroupErrorBodyContainsGroup =>
      'Questo gruppo contiene ancora altri gruppi. Al momento puoi eliminare solo gruppi vuoti.';

  @override
  String get deleteGroupErrorBodyContainsEntries =>
      'Questo gruppo contiene delle password. Al momento puoi eliminare solo gruppi vuoti.';

  @override
  String get groupListAppBarTitle => 'Gruppi';

  @override
  String get groupListFilterAppbarTitle => 'Filtra per gruppi';

  @override
  String get clearQuickUnlock => 'Cancella Archivio Biometrico';

  @override
  String get clearQuickUnlockSubtitle => 'Rimuovi la Master Password salvata';

  @override
  String get unlock => 'Mostra i file';

  @override
  String get closePasswordFiles => 'chiudi i file contenenti le password';

  @override
  String get clearQuickUnlockSuccess =>
      'Password principale rimossa dalla memoria biometrica.';

  @override
  String get diacOptIn => 'Attiva per News e Sondaggi In-App.';

  @override
  String get diacOptInSubtitle =>
      'Periodicamente verrà inviata una richiesta alla rete per recuperare notizie.';

  @override
  String browserAutofillThirdPartyModeTitle(String browserName) {
    return 'Enable AutoFill in $browserName';
  }

  @override
  String browserAutofillThirdPartyModeSubtitle(String browserName) {
    return '$browserName currently uses its own password manager. Tap to open its settings and select “Autofill using another service”, then restart $browserName.';
  }

  @override
  String get enableAutofillDebug => 'Autocompletamento: Abilita il debug';

  @override
  String get enableAutofillDebugSubtitle =>
      'Mostra informazioni in sovrimpressione per ogni campo';

  @override
  String get createPasswordDatabase => 'Crea un Nuovo Database';

  @override
  String get nameNewPasswordDatabase => 'Dai un Nome al tuo Database';

  @override
  String get validatorNameMissing =>
      'Inserisci un nome per il tuo nuovo database.';

  @override
  String get masterPasswordHelpText =>
      'Inserisci una Master Password. ASSICURATI DI RICORDARLA.';

  @override
  String get inputMasterPasswordText => 'Master Password';

  @override
  String get masterPasswordMissingCreate =>
      'Inserisci una password sicura che puoi ricordarti.';

  @override
  String get createDatabaseAction => 'Crea Un Database';

  @override
  String get databaseExistsError => 'Il File è già Esistente';

  @override
  String databaseExistsErrorDescription(Object filePath) {
    return 'Errore durante la creazione del database $filePath. Il file esiste già. scegliere un altro nome.';
  }

  @override
  String get databaseCreateDefaultName => 'MiePassword';

  @override
  String get preferenceDynamicLoadIcons => 'Carica Icone dal Web';

  @override
  String preferenceDynamicLoadIconsSubtitle(Object urlFieldName) {
    return 'L\'applicazione farà una richiesta http tramite i valori nell\'Url del $urlFieldName per caricare le icone dai siti.';
  }

  @override
  String passwordScore(Object score) {
    return 'Sicurezza: $score su 4';
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
  String get entryInfoFile => 'File:';

  @override
  String get entryInfoGroup => 'Gruppo:';

  @override
  String get entryInfoLastModified => 'Ultima Modifica:';

  @override
  String movedEntryToGroup(Object groupName) {
    return 'Elemento spostato in $groupName';
  }

  @override
  String sizeBytesStoredopenvalutCloud(Object count) {
    return '$count byte, archiviati su OpenValut Cloud';
  }

  @override
  String sizeBytes(Object count) {
    return '$count byte';
  }

  @override
  String get entryAttachmentSizeWarning =>
      'I file allegati saranno incorporati nel file di password. Questo può aumentare significativamente il tempo necessario per aprire/salvare le password.';

  @override
  String get iconPngSizeWarning =>
      'Le icone personalizzate saranno incorporate nel file delle password. Questo può aumentare significativamente il tempo necessario per aprire/salvare le password.';

  @override
  String get notPngError => 'Il file scelto non è nel formato PNG.';

  @override
  String get entryAddField => 'Aggiungi Campo';

  @override
  String get entryCustomField => 'Campo Personalizzato';

  @override
  String get entryCustomFieldTitle => 'Aggiungi un campo personalizzato';

  @override
  String get entryCustomFieldInputLabel => 'Inserisci un nome per il campo';

  @override
  String get swipeCopyField => 'Copia';

  @override
  String get fieldRename => 'Rinomina';

  @override
  String get fieldGeneratePassword => 'Genera una Password…';

  @override
  String get fieldProtect => 'Valore protetto';

  @override
  String get fieldUnprotect => 'Valore non protetto';

  @override
  String get fieldPresent => 'Mostra (QR Code)';

  @override
  String get fieldGenerateEmail => 'Genera Email';

  @override
  String get onboardingBackToOnboarding => 'Tour';

  @override
  String get onboardingBackToOnboardingSubtitle => 'Rivivi i primi passi 😅️';

  @override
  String get onboardingHeadline => 'Rendi sicure le tue Password!';

  @override
  String get onboardingQuestion => 'Hai mai usato un Password Manager?';

  @override
  String get onboardingYesOpenPasswords => 'Si, accedi alle mie password';

  @override
  String get onboardingNoCreate => 'Sono nuovo! guidami.';

  @override
  String get backupButton => 'SALVA IN UN CLOUD';

  @override
  String get dismissBackupButton => 'NASCONDI';

  @override
  String backupWarningMessage(Object databasename) {
    return 'Le tue password in $databasename sono salvate solo sul dispositivo!';
  }

  @override
  String get saveAs => 'Salva In...';

  @override
  String get saving => 'Salvataggio in Corso';

  @override
  String get increaseValue => 'Aumenta';

  @override
  String get decreaseValue => 'Riduci';

  @override
  String get resetValue => 'Reset';

  @override
  String cloudStorageAppBarTitle(Object cloudStorageName) {
    return 'CloudStorage - $cloudStorageName';
  }

  @override
  String get cloudStorageLogInCaption =>
      'Sarai reindirizzato all\'autenticazione OpenValut per accedere ai tuoi dati.';

  @override
  String get cloudStorageLogInCode => 'Inserisci il codice';

  @override
  String launchUrlError(Object url) {
    return 'Impossibile lanciare l\'url. Visita $url';
  }

  @override
  String cloudStorageLogInActionLabel(Object cloudStorageName) {
    return 'Accedi a $cloudStorageName';
  }

  @override
  String cloudStorageAuthCodeDialogTitle(Object cloudStorageName) {
    return '$cloudStorageName Autenticazione';
  }

  @override
  String get cloudStorageAuthCodeLabel => 'Codice Di Autenticazione';

  @override
  String get cloudStorageAuthErrorTitle => 'Errore durante l\'autenticazione';

  @override
  String cloudStorageAuthErrorMessage(
    Object cloudStorageName,
    Object errorMessage,
  ) {
    return 'Errore durante il tentativo di autenticazione su $cloudStorageName: $errorMessage';
  }

  @override
  String get cloudStorageSearchBoxLabel => 'Query di ricerca';

  @override
  String cloudStorageItemsInFolder(Object itemCount) {
    return '$itemCount oggetti in questa cartella.';
  }

  @override
  String get mailSubject => 'Oggetto';

  @override
  String get mailFrom => 'Da';

  @override
  String get mailDate => 'Data';

  @override
  String get mailMailbox => 'Casella postale';

  @override
  String get mailNoData => 'Nessun Dato';

  @override
  String get mailMailboxesTitle => 'Caselle postali';

  @override
  String get mailboxCreateButtonLabel => 'Crea';

  @override
  String get mailboxNameInputDialogTitle =>
      'Etichetta opzionale per la nuova casella';

  @override
  String get mailboxNameInputLabel => 'Etichetta (Interna)';

  @override
  String get mailScreenTitle => 'Mail OpenValut';

  @override
  String get mailTabBarTitleMailbox => 'Casella postale';

  @override
  String get mailTabBarTitleMail => 'Mail';

  @override
  String get mailMailboxListEmpty => 'Non hai ancora nessuna casella di posta.';

  @override
  String mailMailboxAddressCopied(Object mailboxAddress) {
    return 'Indirizzo della casella postale copiato negli appunti: $mailboxAddress';
  }

  @override
  String get errorWhileSavingTitle => 'Errore durante il salvataggio';

  @override
  String errorWhileSavingBody(Object errorMessage) {
    return 'Impossibile salvare il file: $errorMessage';
  }

  @override
  String get databaseDoesNotSupportSaving =>
      'Spiacenti, questo database non supporta il salvataggio. Apri un file di database locale. Oppure usa \"Salva come\".';

  @override
  String get otpInvalidKeyTitle => 'Chiave Non Valida';

  @override
  String get otpInvalidKeyBody =>
      'L\'input inserito non è un codice TOTP base32 valido. Verifica il tuo input.';

  @override
  String get otpUnsupportedMigrationTitle => 'Unsupported OTP Migration';

  @override
  String otpUnsupportedMigrationBody(Object uriCount) {
    return 'We currently only support single item migrations. Got $uriCount';
  }

  @override
  String get otpPromptTitle => 'Autenticazione A Tempo';

  @override
  String get otpPromptHelperText => 'Inserisci la chiave a tempo.';

  @override
  String otpErrorMessageGeneration(Object errorMessage) {
    return 'Errore nella generazione del codice di invito: $errorMessage';
  }

  @override
  String get otpCopySecretActionLabel => 'Copia Segreto';

  @override
  String get otpEntryLabel => 'Token monouso';

  @override
  String get entryFieldProtected => 'Campo protetto. Clicca per rivelare.';

  @override
  String get entryFieldActionRevealField => 'Mostra il campo protetto';

  @override
  String get entryAttachmentOpenActionLabel => 'Apri';

  @override
  String get entryAttachmentShareActionLabel => 'Condividi';

  @override
  String get entryAttachmentShareSubject => 'Allegato';

  @override
  String get entryAttachmentSaveActionLabel => 'Salva sul dispositivo';

  @override
  String get entryAttachmentRemoveActionLabel => 'Rimuovi';

  @override
  String entryAttachmentRemoveConfirm(Object attachmentLabel) {
    return 'Vuoi davvero rimuovere $attachmentLabel?';
  }

  @override
  String get entryRenameFieldPromptTitle => 'Rinomina il campo';

  @override
  String get removerecentfile => 'Nascondi';

  @override
  String get entryRenameFieldPromptLabel => 'Inserisci il nuovo nome del campo';

  @override
  String get promptDialogPasteActionTooltip => 'Incolla dagli appunti';

  @override
  String get promptDialogPasteHint =>
      'Suggerimento: Se hai bisogno di incollare, prova il pulsante a sinistra ;-)';

  @override
  String get genericErrorDialogTitle => 'Errore nella gestione dell\'azione';

  @override
  String genericErrorDialogBody(Object errorMessage) {
    return 'Hai riscontrato un errore imprevisto. $errorMessage';
  }

  @override
  String get saveAsEntryLocalFile => 'File Locale';

  @override
  String get fileTypePngs => 'Immagini (png)';

  @override
  String get selectIconDialogAction => 'SELEZIONA ICONA';

  @override
  String get retryDialogActionLabel => 'RIPROVA';

  @override
  String errorDuringNetworkCall(Object errorMessage) {
    return 'Errore durante la chiamata Api. $errorMessage';
  }

  @override
  String get passwordFilterHideDeleted => 'Nascondi Voci Eliminate';

  @override
  String get passwordFilterOnlyDeleted => 'Voci Eliminate';

  @override
  String passwordFilterPrefixForOneGroup(Object groupName) {
    return 'Gruppo: $groupName';
  }

  @override
  String passwordFilterPrefixForMultipleGroups(Object groupCount) {
    return 'Filtro Personalizzato ($groupCount Gruppi)';
  }

  @override
  String get menuItemopenvalutCloudAuthenticate =>
      'Autenticati con OpenValut Cloud';

  @override
  String get menuItemopenvalutCloudMailboxes => 'Mailbox OpenValut';

  @override
  String changesWithoutSaving(Object fileName) {
    return 'Sono presenti modifiche in \"$fileName\", che non supporta la scrittura delle modifiche.';
  }

  @override
  String get changesSaveLocally => 'Salva in locale';

  @override
  String get clearColor => 'Elimina Colore';

  @override
  String get databaseRenameInputLabel => 'Inserisci il nome del database';

  @override
  String get databasePath => 'Percorso';

  @override
  String get databaseColor => 'Colore';

  @override
  String get databaseColorChoose =>
      'Selezionare un colore per distinguere i file.';

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
  String get databaseKdbxVersion => 'Versione File KDBX';

  @override
  String databaseKdbxUpgradeVersion(Object versionName) {
    return 'Aggiorna a $versionName';
  }

  @override
  String get databaseKdbxUpgradeSuccessful =>
      'File aggiornato e salvato con successo.';

  @override
  String get databaseReload => 'Ricarica e unisci';

  @override
  String progressStatus(Object statusProgress) {
    return 'Stato: $statusProgress';
  }

  @override
  String finishedMerge(Object status) {
    return 'Unione completata $status';
  }

  @override
  String get closeAndLockFile => 'Chiudi/Blocca';

  @override
  String get openvalutHomeScreenTagline =>
      'password manager, open source, disponibile su tutte le piattaforme.';

  @override
  String get addNewPasswordButtonLabel => 'Aggiungi una nuova password';

  @override
  String get unnamedEntryPlaceholder => '(Senza Nome)';

  @override
  String get unnamedGroupPlaceholder => '(Senza Nome)';

  @override
  String get unnamedFilePlaceholder => '(Senza Nome)';

  @override
  String get editGroupScreenTitle => 'Modifica Gruppo';

  @override
  String get editGroupGroupNameLabel => 'Nome Del Gruppo';

  @override
  String get files => 'File';

  @override
  String get newGroupDialogTitle => 'Crea Gruppo';

  @override
  String get newGroupDialogInputLabel => 'Nome del nuovo gruppo';

  @override
  String get groupActionShowPasswords => 'Mostra le password';

  @override
  String get groupActionDelete => 'Elimina';

  @override
  String get logoutTooltip => 'Disconnetti';

  @override
  String get successfullyDeletedFileCloudStorage =>
      'File eliminato con successo.';

  @override
  String shareDialogTitle(Object fileName) {
    return 'Opzioni di condivisione di $fileName';
  }

  @override
  String get shareFileActionLabel => 'Condividi …';

  @override
  String get shareTokenListEmptyScreenPlaceholder =>
      'File non ancora condiviso.';

  @override
  String get shareTokenNoLabel => 'Nessuna Etichetta/Descrizione';

  @override
  String get shareTokenReadWrite => 'Lettura/Scrittura';

  @override
  String get shareTokenReadOnly => 'Sola lettura';

  @override
  String get shareCreateTokenDialogTitle => 'Condividi file';

  @override
  String get shareCreateTokenReadOnly => 'Sola lettura';

  @override
  String get shareCreateTokenReadOnlyHelpText =>
      'Non consentire il salvataggio delle modifiche';

  @override
  String get shareCreateTokenLabelText => 'Descrizione';

  @override
  String get shareCreateTokenLabelHint => 'Condividi con il mio amico';

  @override
  String get shareCreateTokenLabelHelp =>
      'Etichetta facoltativa per differenziare il codice di condivisione.';

  @override
  String get shareCreateTokenSuccess =>
      'Codice di condivisione creato con successo.';

  @override
  String get sharePresentDialogTitle =>
      'Condividi il file con il codice di condivisione segreto';

  @override
  String get sharePresentDialogHelp =>
      'Utilizzando il seguente codice di condivisione gli utenti possono accedere al file di password. Avranno bisogno della password e/o del file chiave per aprirlo.';

  @override
  String get sharePresentToken => 'Condividi Il Codice';

  @override
  String get sharePresentCopied =>
      'Codice di condivisione copiato negli appunti.';

  @override
  String get openvalutCloudOpenWithShareCodeTooltip =>
      'Apri con il codice di condivisione';

  @override
  String get openvalutCloudShareFileActionLabel => 'Condividi';

  @override
  String get preferenceopenvalutCloudAttachmentTitle =>
      'Usa Gli Allegati Cloud OpenValut';

  @override
  String get preferenceopenvalutCloudAttachmentSubtitle =>
      'Memorizza gli allegati crittografati separatamente su OpenValut Cloud.';

  @override
  String get shareCodeInputDialogTitle =>
      'Inserisci Codice Segreto Di Condivisione';

  @override
  String get shareCodeInputDialogScan => 'Scansiona il codice QR';

  @override
  String get shareCodeInputLabel => 'Codice Di Condivisione Segreto';

  @override
  String get shareCodeInputHelperText =>
      'Se hai ricevuto un codice di condivisione, incollalo sopra.';

  @override
  String get shareCodeOpen =>
      'Hai ricevuto un codice di condivisione per OpenValut Cloud?';

  @override
  String get shareCodeOpenScreenTitle =>
      'Caricamento file con codice di condivisione';

  @override
  String get shareCodeLoadingProgress => 'Caricamento del file …';

  @override
  String get shareCodeOpenFileButtonLabel => 'APRI';

  @override
  String get shareCodeOpenInstallAppCaption =>
      'Vuoi aprire questo file con una delle nostre applicazioni native?';

  @override
  String get shareCodeOpenAnotherAppCaption =>
      'Vuoi aprire questo file su un altro dispositivo?';

  @override
  String get shareCodeOpenInstallAppButtonLabel => 'Installa App';

  @override
  String get shareCodeOpenShowCodeButtonLabel =>
      'Mostra Codice Di Condivisione';

  @override
  String get changeMasterPasswordActionLabel => 'Cambia Password Principale';

  @override
  String get changeMasterPasswordFormSubmit => 'Salva con nuova password';

  @override
  String get changeMasterPasswordSuccess =>
      'Password principale salvata con successo.';

  @override
  String get changeMasterPasswordScreenTitle => 'Cambia Password Principale';

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
      'Ho ricevuto l\'email e visitato il link';

  @override
  String get openvalutCloudAuthNotConfirmed =>
      'L\'indirizzo email non è stato ancora confermato. Assicurati di fare clic sul link nell\'email che hai ricevuto e di risolvere il captcha per confermare il tuo indirizzo email.';

  @override
  String get getHelpButton => 'Ottieni aiuto nel forum';

  @override
  String get shortcutCopyUsername => 'Copia il Nome Utente';

  @override
  String get shortcutCopyPassword => 'Copia la Password';

  @override
  String get shortcutCopyTotp => 'Copia TOTP';

  @override
  String get shortcutMoveUp => 'Seleziona la password precedente';

  @override
  String get shortcutMoveDown => 'Seleziona la password successiva';

  @override
  String get shortcutGeneratePassword => 'Genera una Password';

  @override
  String get shortcutCopyUrl => 'Copia URL';

  @override
  String get shortcutOpenUrl => 'Apri URL';

  @override
  String get shortcutCancelSearch => 'Annulla Ricerca';

  @override
  String get shortcutShortcutHelp => 'Guida Scorciatoia Tastiera';

  @override
  String get shortcutHelpTitle => 'Scorciatoie da tastiera';

  @override
  String unexpectedError(String error) {
    return 'Errore imprevisto: $error';
  }

  @override
  String get googleDriveMorePermissionsRequired =>
      'Additional permissions needed to access Google Drive.';

  @override
  String get googleDriveRequestPermissionButtonLabel => 'Request Permissions';

  @override
  String get scanQrCodeTitle => 'Scan QR Code.';
}
