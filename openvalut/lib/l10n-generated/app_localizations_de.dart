// ignore_for_file: omit_local_variable_types,unused_local_variable

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

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
  String get entryAddAttachment => 'Anhang anfügen';

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
  String get fieldUserName => 'Benutzer';

  @override
  String get fieldPassword => 'Passwort';

  @override
  String get fieldWebsite => 'Webseite';

  @override
  String get fieldTitle => 'Titel';

  @override
  String get fieldTotp => 'Einmalpasswort (Zeitbasiert)';

  @override
  String get english => 'Englisch';

  @override
  String get german => 'Deutsch';

  @override
  String get russian => 'Russisch';

  @override
  String get ukrainian => 'Ukrainisch';

  @override
  String get lithuanian => 'Litauisch';

  @override
  String get french => 'Französisch';

  @override
  String get spanish => 'Spanisch';

  @override
  String get indonesian => 'Indonesisch';

  @override
  String get turkish => 'Türkisch';

  @override
  String get hebrew => 'Hebräisch';

  @override
  String get italian => 'Italienisch';

  @override
  String get chineseSimplified => 'Vereinfachtes Chinesisch';

  @override
  String get chineseTraditional => 'Traditionelles Chinesisch';

  @override
  String get portugueseBrazilian => 'Portugiesisch, Brasilianisch';

  @override
  String get slovak => 'Slowakisch';

  @override
  String get dutch => 'Niederländisch';

  @override
  String get selectItem => 'Auswählen';

  @override
  String get selectKeepassFile => 'OpenValut - Wähle eine KeePass Datei';

  @override
  String get selectKeepassFileLabel =>
      'Bitte wähle eine KeePass (.kdbx) Datei.';

  @override
  String get createNewFile => 'Datei Erstellen';

  @override
  String get openLocalFile => 'Öffne\nLokale Datei';

  @override
  String get openFile => 'Datei öffnen';

  @override
  String get loadFromDropdownMenu => 'Lade von …';

  @override
  String get quickUnlockingFiles => 'Dateien schnell entsperren …';

  @override
  String openFileProgress(Object fileName, Object current, Object totalCount) {
    return 'Öffne $fileName … ($current / $totalCount)';
  }

  @override
  String loadFrom(String cloudStorageName) {
    return 'Lade von $cloudStorageName';
  }

  @override
  String get loadFromRemoteUrl => 'Lade von URL';

  @override
  String get createNewKeepass =>
      'KeePass noch nie verwendet?\nJetzt neue Passwort Datenbank erstellen';

  @override
  String get labelLastOpenFiles => 'Zuletzt geöffnete Dateien:';

  @override
  String get noFilesHaveBeenOpenYet => 'Keine Dateien bisher geöffnet.';

  @override
  String get preferenceSelectLanguage => 'Sprache wählen';

  @override
  String get preferenceLanguage => 'Sprache';

  @override
  String get preferenceTextScaleFactor => 'Text Skalierung';

  @override
  String get preferenceVisualDensity => 'Visuelle Dichte';

  @override
  String get preferenceTheme => 'Theme';

  @override
  String get preferenceThemeLight => 'Hell';

  @override
  String get preferenceThemeDark => 'Dunkel';

  @override
  String get preferenceSystemDefault => 'Geräte Standardeinstellung';

  @override
  String get preferenceDefault => 'Standard';

  @override
  String get lockAllFiles => 'Alle offenen Dateien schließen';

  @override
  String get preferenceAllowScreenshots => 'Screenshots der App zulassen';

  @override
  String get preferenceEnableAutoFill => 'Autofill aktivieren';

  @override
  String get enableAutofillSuggestionBanner =>
      'Sie können das Feld einer anderen Anwendung ausfüllen, indem Sie Autofill aktivieren!';

  @override
  String get dismissAutofillSuggestionBannerButton => 'Schließen';

  @override
  String get enableAutofillSuggestionBannerButton => 'Aktivieren!';

  @override
  String get preferenceAutoFillDescription =>
      'Wird nur auf ab Android Oreo (8.0) unterstützt.';

  @override
  String get preferenceTitle => 'Einstellungen';

  @override
  String get preferenceEnableSystemWideShortcuts =>
      'Aktiviere Systemweite Verknüpfungen';

  @override
  String get preferenceEnableSystemWideShortcutsHelp =>
      'Registriert Strg+alt+f als systemweite Verknüpfung um die Suche zu öffnen.';

  @override
  String get preferencesSearchFields => 'Suchfelder anpassen';

  @override
  String get preferencesSearchFieldPromptTitle => 'Suchfeld';

  @override
  String get preferencesSearchFieldPromptLabel =>
      'Kommagetrennte Liste von Feldern, die in der Passwortlistensuche verwendet werden sollen.';

  @override
  String preferencesSearchFieldPromptHelp(
    Object wildCardCharacter,
    Object defaultSearchFields,
  ) {
    return 'Verwende $wildCardCharacter für alle, lasse leer für Standard ($defaultSearchFields)';
  }

  @override
  String get aboutAppName => 'OpenValut';

  @override
  String get aboutLinkFeedback => 'Wir freuen uns über jede Art von Feedback!';

  @override
  String get aboutLinkVisitWebsite => 'Besuchen Sie auch unsere Website';

  @override
  String get aboutLinkGitHub => 'Und Open Source Projekt';

  @override
  String aboutLogFile(String logFilePath) {
    return 'Log-Datei: $logFilePath';
  }

  @override
  String get aboutLinkContributors => 'Mitwirkende anzeigen';

  @override
  String get unableToLaunchUrlTitle => 'Kann URL nicht öffnen';

  @override
  String unableToLaunchUrlDescription(Object url, Object openError) {
    return 'Fehler beim öffnen von $url: $openError';
  }

  @override
  String get unableToLaunchUrlNoHandler => 'Keine App für die URL gefunden.';

  @override
  String launchedUrl(Object url) {
    return 'URL $url geöffnet';
  }

  @override
  String get menuItemGeneratePassword => 'Passwort generieren';

  @override
  String get menuItemPreferences => 'Einstellungen';

  @override
  String get menuItemOpenAnotherFile => 'Weitere Datei öffnen';

  @override
  String get menuItemCheckForUpdates => 'Nach Updates suchen';

  @override
  String get menuItemSupport => 'Protokolle senden';

  @override
  String get menuItemSupportSubtitle => 'Protokolle per E-Mail senden';

  @override
  String get menuItemForum => 'Support Forum';

  @override
  String get menuItemForumSubtitle => 'Melde Probleme und erhalte Hilfe';

  @override
  String get menuItemHelp => 'Hilfe';

  @override
  String get menuItemHelpSubtitle => 'Dokumentation anzeigen';

  @override
  String get menuItemAbout => 'Über OpenValut';

  @override
  String get actionOpenUrl => 'URL Öffnen';

  @override
  String get passwordPlainText => 'Passwort anzeigen';

  @override
  String get generatorPassword => 'Passwort';

  @override
  String get generatePassword => 'Passwort generieren';

  @override
  String get doneButtonLabel => 'Fertig';

  @override
  String get useAsDefault => 'Als Standard speichern';

  @override
  String get characterSetLowerCase => 'Kleinbuchstaben (a-z)';

  @override
  String get characterSetUpperCase => 'Großbuchstaben (A-Z)';

  @override
  String get characterSetNumeric => 'Ziffern (0-9)';

  @override
  String get characterSetUmlauts => 'Umlaute (äöü)';

  @override
  String get characterSetSpecial => 'Sonderzeichen (@%+)';

  @override
  String get length => 'Länge';

  @override
  String get customLength => 'Andere Länge';

  @override
  String customLengthHelperText(Object customMinLength) {
    return 'Nur für > $customMinLength verwendet';
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
      other: '$numFilesString Dateien gespeichert: $files',
      one: 'Eine Datei gespeichert: $files',
    );
    return '$_temp0';
  }

  @override
  String get manageGroups => 'Gruppen verwalten';

  @override
  String get lockFiles => 'Dateien sperren/schließen';

  @override
  String get searchHint => 'Suchen';

  @override
  String get searchButtonLabel => 'Suchen';

  @override
  String get filterButtonLabel => 'Nach Gruppe filtern';

  @override
  String get clear => 'Löschen';

  @override
  String get autofillFilterPrefix => 'Filter:';

  @override
  String get autofillMatchPrefix => 'Matching entries for:';

  @override
  String get autofillPrompt => 'Wähle einen Passwort-Eintrag für Autofill.';

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
  String get copiedToClipboard => 'In die Zwischenablage kopiert.';

  @override
  String get noTitle => '(kein Titel)';

  @override
  String get noUsername => '(kein Benutzername)';

  @override
  String get filterCustomize => 'Anpassen …';

  @override
  String get swipeCopyPassword => 'Passwort kopieren';

  @override
  String get swipeCopyUsername => 'Benutzername kopieren';

  @override
  String get copyUsernameNotExists => 'Eintrag hat keinen Benutzernamen.';

  @override
  String get copyPasswordNotExists => 'Eintrag hat kein Passwort definiert.';

  @override
  String get doneCopiedPassword => 'Passwort in die Zwischenablage kopiert.';

  @override
  String get doneCopiedUsername =>
      'Benutzername in die Zwischenablage kopiert.';

  @override
  String get doneCopiedField => 'Kopiert.';

  @override
  String copiedFieldToClipboard(Object fieldName) {
    return '$fieldName kopiert.';
  }

  @override
  String copiedFieldEmpty(Object fieldName) {
    return '$fieldName ist leer.';
  }

  @override
  String get emptyPasswordVaultPlaceholder =>
      'Du hast noch keine Passworter in deiner Datenbank.';

  @override
  String get emptyPasswordVaultButtonLabel => 'Erstelle dein erstes Passwort';

  @override
  String get loading => 'Wird geladen';

  @override
  String get loadingFile => 'Datei wird geladen …';

  @override
  String get internalFile => 'Interne Dateien';

  @override
  String get internalFileSubtitle => 'Datenbank zuvor mit OpenValut erstellt';

  @override
  String get filePicker => 'File Picker';

  @override
  String get filePickerSubtitle => 'Datei vom lokalen Gerät öffnen.';

  @override
  String get credentialsAppBarTitle => 'Entschlüsselung';

  @override
  String get credentialLabel => 'Passwort eingeben für:';

  @override
  String get masterPasswordInputLabel => 'Passwort';

  @override
  String get masterPasswordEmptyValidator => 'Bitte gib dein Passwort ein.';

  @override
  String get masterPasswordIncorrectValidator => 'Ungültiges Passwort';

  @override
  String get useKeyFile => 'Schlüsseldatei verwenden';

  @override
  String get saveMasterPasswordBiometric =>
      'Passwort sicher speichern (mit biometrischen Schutz)?';

  @override
  String get close => 'Schließen';

  @override
  String get addNewPassword => 'Neues Passwort hinzufügen';

  @override
  String get errorOpenFileInvalidFileStructureTitle =>
      'Es wurde versucht, einen ungültigen Dateityp zu öffnen';

  @override
  String errorOpenFileInvalidFileStructureBody(Object fileName) {
    return 'Die Datei ($fileName) scheint keine gültige KDBX-Datei zu sein. Bitte wählen Sie entweder eine gültige KDBX-Datei oder erstellen Sie eine neue Passwortdatenbank.';
  }

  @override
  String get errorOpenFileAlreadyOpenTitle => 'Datei schon geöffnet';

  @override
  String errorOpenFileAlreadyOpenBody(
    Object databaseName,
    Object openFileSource,
    Object newFileSource,
  ) {
    return 'Die Datenbank $databaseName ist bereits von $openFileSource aus geöffnet. (Versuchte $newFileSource zu öffnen)';
  }

  @override
  String get loadFromUrl => 'Von der url herunterladen';

  @override
  String get loadFromUrlEnterUrl => 'URL eingeben';

  @override
  String get loadFromUrlErrorEnterFullUrl =>
      'Bitte geben Sie die vollständige URL ein, beginnend mit http:// oder https://';

  @override
  String get loadFromUrlErrorInvalidUrl => 'Bitte eine gültige URL eingeben.';

  @override
  String get linuxAppArmorWarning =>
      'OpenValut benötigt die Berechtigung, mit dem Geheimdienst zu kommunizieren, um Anmeldedaten für den Cloud-Speicher zu speichern.\nBitte führen Sie den folgenden Befehl aus:';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get errorLoadFileFromSourceTitle => 'Fehler beim öffnen der Datei.';

  @override
  String errorLoadFileFromSourceBody(Object source, Object error) {
    return '$source konnte nicht geöffnet werden.\n$error';
  }

  @override
  String get errorUnlockFileTitle => 'Datei kann nicht geöffnet werden';

  @override
  String errorUnlockFileBody(Object error) {
    return 'Unbekannter Fehler beim Öffnen der Datei. $error';
  }

  @override
  String get dialogContinue => 'Weiter';

  @override
  String get dialogSendErrorReport => 'Fehlerbericht senden';

  @override
  String get dialogReportErrorForum => 'Fehler im Forum melden/Hilfe';

  @override
  String get groupFilterDescription =>
      'Wähle Gruppen die (rekursiv) angezeigt werden sollen';

  @override
  String get groupFilterSelectAll => 'Alles auswählen';

  @override
  String get groupFilterDeselectAll => 'Auswahl aufheben';

  @override
  String get createSubgroup => 'Untergruppe erstellen';

  @override
  String get editAction => 'Bearbeiten';

  @override
  String get mailboxEnableLabel => '(erneut) aktivieren';

  @override
  String get mailboxEnableHint => 'E-Mails weiterhin empfangen';

  @override
  String get mailboxDisableLabel => 'Deaktivieren';

  @override
  String get mailboxDisableHint => 'Keine weiteren E-Mails empfangen';

  @override
  String get mailListNoMail => 'Sie haben noch keine Emails erhalten.';

  @override
  String mailboxLabelPrefixForEntry(Object entryLabel) {
    return 'Eintrag: $entryLabel';
  }

  @override
  String mailboxLabelPrefixUnknownEntry(Object entryUuid) {
    return 'Unbekannter Eintrag: $entryUuid';
  }

  @override
  String mailboxLabelPrefixCreatedAt(Object dateTime) {
    return 'Erstellt am: $dateTime';
  }

  @override
  String get masterPasswordDescription =>
      'Das Master-Passwort wird verwendet, um Ihre Passwortdatenbank sicher zu verschlüsseln. Denken Sie daran, bei Verlust ihres Master-Passwort können ihre Daten nicht wiederhergestellt werden.';

  @override
  String get unsavedChangesWarningTitle => 'Nicht gespeicherte Änderungen';

  @override
  String get unsavedChangesWarningBody =>
      'Es gibt noch ungespeicherte Änderungen. Möchten Sie die Änderungen verwerfen?';

  @override
  String get unsavedChangesDiscardActionLabel => 'Änderungen verwerfen';

  @override
  String get deletePermanentlyAction => 'Dauerhaft löschen';

  @override
  String get restoreFromRecycleBinAction => 'Wiederherstellen';

  @override
  String get deleteAction => 'Löschen';

  @override
  String get deletedEntry => 'Eintrag gelöscht.';

  @override
  String get successfullyDeletedGroup => 'Gruppe gelöscht.';

  @override
  String get undoButtonLabel => 'Rückgängig';

  @override
  String get saveButtonLabel => 'Speichern';

  @override
  String get webDavSettings => 'WebDAV Einstellungen';

  @override
  String get webDavUrlLabel => 'URL';

  @override
  String get webDavUrlHelperText => 'Basis-URL zu Ihrem WebDAV-Service.';

  @override
  String get webDavUrlValidatorError => 'Bitte eine URL eingeben';

  @override
  String get webDavUrlValidatorInvalidUrlError =>
      'Bitte geben Sie eine gültige URL mit http:// oder https:// ein';

  @override
  String get webDavAuthUser => 'Benutzername';

  @override
  String get webDavopenvalutword => 'Passwort';

  @override
  String get mergeSuccessDialogTitle =>
      'Passwortdatenbank erfolgreich verbunden';

  @override
  String mergeSuccessDialogMessage(Object fileName, Object mergeSummary) {
    return 'Konflikt beim Speichern von $fileName erkannt, wurde erfolgreich mit der entfernten Datei verbunden: \n\n$mergeSummary';
  }

  @override
  String forDetailsVisitUrl(Object url) {
    return 'Für weitere Informationen besuchen Sie $url';
  }

  @override
  String get openvalutCloudAuthEmailInputLabel =>
      'Geben Sie die E-Mail-Adresse ein, um sich zu registrieren oder anzumelden.';

  @override
  String get openvalutCloudAuthEmailInvalid =>
      'Bitte geben sie ein gültige Email-Adresse an.';

  @override
  String get openvalutCloudAuthConfirmEmailButtonLabel => 'Adresse Bestätigen';

  @override
  String get openvalutCloudAuthConfirmEmail =>
      'Bitte überprüfen sie ihre Email-Adresse um diese zu bestätigen.';

  @override
  String get openvalutCloudAuthConfirmEmailExplain =>
      'Bitte schließen Sie nicht diese Seite bevor Sie denn Link geöffnet haben den wir ihnen per Email geschickt haben.';

  @override
  String get openvalutCloudAuthResendExplain =>
      'Falls sie noch keine Email von uns geschickt bekommen haben, dann kontrollieren Sie ihren Spam Ordner. Andernfalls können sie versuchen einen neuen Bestätigungslink anzufordern.';

  @override
  String get openvalutCloudAuthResendButtonLabel =>
      'Einen neuen Bestätigungslink anfordern';

  @override
  String permanentlyDeleteEntryConfirm(Object title) {
    return 'Das führt zur permanenten Löschung des Passwordeintrag $title. Dies kann nicht Rückgänging gemacht werden. Wollen sie trotzdem fortfahren?';
  }

  @override
  String get permanentlyDeletedEntrySnackBar => 'Eintrag würde gelöscht.';

  @override
  String get initialNewGroupName => 'Neue Gruppe';

  @override
  String get deleteGroupErrorTitle => 'Gruppe kann nicht gelöscht werden';

  @override
  String get deleteGroupErrorBodyContainsGroup =>
      'Diese Gruppe enthält noch andere Gruppen. Sie können derzeit nur leere Gruppen löschen.';

  @override
  String get deleteGroupErrorBodyContainsEntries =>
      'Diese Gruppe enthält noch Passwort-Einträge. Sie können derzeit nur leere Gruppen löschen.';

  @override
  String get groupListAppBarTitle => 'Gruppen';

  @override
  String get groupListFilterAppbarTitle => 'Nach Gruppen filtern';

  @override
  String get clearQuickUnlock => 'Biometrischen Speicher löschen';

  @override
  String get clearQuickUnlockSubtitle =>
      'Lösche gespeicherte master Passwörter';

  @override
  String get unlock => 'Dateien entsperren';

  @override
  String get closePasswordFiles => 'schliesse Passwortdateien';

  @override
  String get clearQuickUnlockSuccess =>
      'Lösche gespeicherte master Passwörter vom biometrischen Speicher.';

  @override
  String get diacOptIn => 'In-App Neuigkeiten und Umfragen erhalten.';

  @override
  String get diacOptInSubtitle =>
      'Kann gelegentlich Internetanfragen um Neuigkeiten zu sammeln verursachen.';

  @override
  String browserAutofillThirdPartyModeTitle(String browserName) {
    return 'Enable AutoFill in $browserName';
  }

  @override
  String browserAutofillThirdPartyModeSubtitle(String browserName) {
    return '$browserName currently uses its own password manager. Tap to open its settings and select “Autofill using another service”, then restart $browserName.';
  }

  @override
  String get enableAutofillDebug => 'AutoFill: Debugging aktivieren';

  @override
  String get enableAutofillDebugSubtitle =>
      'Zeigt informationen für jedes Eingabefeld in einem overlay';

  @override
  String get createPasswordDatabase => 'Erstelle Passwort Datenbank';

  @override
  String get nameNewPasswordDatabase => 'Name der neuen Datenbank';

  @override
  String get validatorNameMissing =>
      'Bitte gib den namen der neuen Datenbank an';

  @override
  String get masterPasswordHelpText => 'Gib ein sicheres master Passwort an.';

  @override
  String get inputMasterPasswordText => 'Master Passwort';

  @override
  String get masterPasswordMissingCreate =>
      'Bitte gib ein sicheres Passwort an.';

  @override
  String get createDatabaseAction => 'Erstelle Datenbank';

  @override
  String get databaseExistsError => 'Datei exisiert bereits';

  @override
  String databaseExistsErrorDescription(Object filePath) {
    return 'Fehler beim versuch die Datenbank zu erstellen: $filePath. Die Datei exisitert bereits. Bitte wähle einen anderen Namen.';
  }

  @override
  String get databaseCreateDefaultName => 'PersönlichePasswörter';

  @override
  String get preferenceDynamicLoadIcons => 'Dynamisch Website icons laden';

  @override
  String preferenceDynamicLoadIconsSubtitle(Object urlFieldName) {
    return 'Macht abfragen auf $urlFieldName um Dynamisch Icons zu suchen.';
  }

  @override
  String passwordScore(Object score) {
    return 'Stärke: $score von 4';
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
  String get entryInfoFile => 'Datei:';

  @override
  String get entryInfoGroup => 'Gruppe:';

  @override
  String get entryInfoLastModified => 'Letzte Änderung:';

  @override
  String movedEntryToGroup(Object groupName) {
    return 'Eintrag verschoben nach $groupName';
  }

  @override
  String sizeBytesStoredopenvalutCloud(Object count) {
    return '$count Bytes, in der OpenValut Cloud gespeichert';
  }

  @override
  String sizeBytes(Object count) {
    return '$count Bytes';
  }

  @override
  String get entryAttachmentSizeWarning =>
      'Anhänge werden in der Passwort Datei gespeichert. Dies kann die Zeit zum öffnen der Passwörter stark erhöhen!';

  @override
  String get iconPngSizeWarning =>
      'Benutzerdefinierte Symbole werden in die Passwortdatei gespeichert. Dies kann die Zeit zum Öffnen und Speichern von Passwörtern erheblich erhöhen.';

  @override
  String get notPngError => 'Die gewählte Datei ist kein PNG.';

  @override
  String get entryAddField => 'Feld hinzufügen';

  @override
  String get entryCustomField => 'Benutzerdefiniertes Feld';

  @override
  String get entryCustomFieldTitle =>
      'Füge neues Benutzerdefiniertes Feld hinzu';

  @override
  String get entryCustomFieldInputLabel => 'Namen für Feld eingeben';

  @override
  String get swipeCopyField => 'Feld kopieren';

  @override
  String get fieldRename => 'Umbenennen';

  @override
  String get fieldGeneratePassword => 'Passwort generieren …';

  @override
  String get fieldProtect => 'Geschützter Wert';

  @override
  String get fieldUnprotect => 'Ungeschützter Wert';

  @override
  String get fieldPresent => 'Präsentieren';

  @override
  String get fieldGenerateEmail => 'Email generieren';

  @override
  String get onboardingBackToOnboarding => 'Führung';

  @override
  String get onboardingBackToOnboardingSubtitle => 'App tour neu erleben 😅️';

  @override
  String get onboardingHeadline => 'Lass uns deine Passwörter sicher machen!';

  @override
  String get onboardingQuestion =>
      'Hast du schon einen Passwort Manager benutzt?';

  @override
  String get onboardingYesOpenPasswords => 'Ja, öffne meine Passwörter';

  @override
  String get onboardingNoCreate => 'Ich bin neu. Lass uns loslegen!';

  @override
  String get backupButton => 'IN DER CLOUD SPEICHERN';

  @override
  String get dismissBackupButton => 'Schließen';

  @override
  String backupWarningMessage(Object databasename) {
    return 'Ihre Passwörter in $databasename sind nur lokal gespeichert!';
  }

  @override
  String get saveAs => 'Speichern in...';

  @override
  String get saving => 'Speichere';

  @override
  String get increaseValue => 'Vergrößern';

  @override
  String get decreaseValue => 'Verkleinern';

  @override
  String get resetValue => 'Zurücksetzen';

  @override
  String cloudStorageAppBarTitle(Object cloudStorageName) {
    return 'Cloud-Speicher - $cloudStorageName';
  }

  @override
  String get cloudStorageLogInCaption =>
      'Sie werden weitergeleitet, um OpenValut zu authentifizieren, um auf Ihre Daten zuzugreifen.';

  @override
  String get cloudStorageLogInCode => 'Code eingeben';

  @override
  String launchUrlError(Object url) {
    return 'Url kann nicht gestartet werden. Bitte besuchen Sie $url';
  }

  @override
  String cloudStorageLogInActionLabel(Object cloudStorageName) {
    return 'Anmelden bei $cloudStorageName';
  }

  @override
  String cloudStorageAuthCodeDialogTitle(Object cloudStorageName) {
    return '$cloudStorageName Authentifizierung';
  }

  @override
  String get cloudStorageAuthCodeLabel => 'Authentifizierungs-Code';

  @override
  String get cloudStorageAuthErrorTitle =>
      'Fehler während der Authentifizierung';

  @override
  String cloudStorageAuthErrorMessage(
    Object cloudStorageName,
    Object errorMessage,
  ) {
    return 'Fehler beim Versuch, sich bei $cloudStorageName zu authentifizieren: $errorMessage';
  }

  @override
  String get cloudStorageSearchBoxLabel => 'Suchanfrage';

  @override
  String cloudStorageItemsInFolder(Object itemCount) {
    return '$itemCount Einträge in diesem Ordner.';
  }

  @override
  String get mailSubject => 'Betreff';

  @override
  String get mailFrom => 'Von';

  @override
  String get mailDate => 'Datum';

  @override
  String get mailMailbox => 'Postfach';

  @override
  String get mailNoData => 'Keine Daten';

  @override
  String get mailMailboxesTitle => 'Postfächer';

  @override
  String get mailboxCreateButtonLabel => 'Erstellen';

  @override
  String get mailboxNameInputDialogTitle =>
      'Optionale Bezeichnung für neue Postfach';

  @override
  String get mailboxNameInputLabel => '(interne) Bezeichnung';

  @override
  String get mailScreenTitle => 'OpenValut E-Mail';

  @override
  String get mailTabBarTitleMailbox => 'Postfach';

  @override
  String get mailTabBarTitleMail => 'E-Mail';

  @override
  String get mailMailboxListEmpty => 'Sie haben noch keine Postfächer.';

  @override
  String mailMailboxAddressCopied(Object mailboxAddress) {
    return 'Mailbox-Adresse wurde in die Zwischenablage kopiert: $mailboxAddress';
  }

  @override
  String get errorWhileSavingTitle => 'Fehler beim Speichern';

  @override
  String errorWhileSavingBody(Object errorMessage) {
    return 'Datei konnte nicht gespeichert werden: $errorMessage';
  }

  @override
  String get databaseDoesNotSupportSaving =>
      'Entschuldigung, diese Datenbank unterstützt das Speichern nicht. Bitte öffnen Sie eine lokale Datenbankdatei. Oder verwenden Sie \"Speichern unter\".';

  @override
  String get otpInvalidKeyTitle => 'Ungültiger Schlüssel';

  @override
  String get otpInvalidKeyBody =>
      'Die angegebene Eingabe ist kein gültiger Base32 TOTP-Code. Bitte überprüfen Sie Ihre Eingabe.';

  @override
  String get otpUnsupportedMigrationTitle => 'Nicht unterstützt';

  @override
  String otpUnsupportedMigrationBody(Object uriCount) {
    return 'Momentan unterstützen wir nur Migration einzelner Tokens. Enthalten sind $uriCount';
  }

  @override
  String get otpPromptTitle => 'Zeitbasierte Authentifizierung';

  @override
  String get otpPromptHelperText =>
      'Bitte geben Sie einen zeitbasierten Schlüssel ein.';

  @override
  String otpErrorMessageGeneration(Object errorMessage) {
    return 'Fehler beim Generieren des Einladungscodes: $errorMessage';
  }

  @override
  String get otpCopySecretActionLabel => 'Geheimnis kopieren';

  @override
  String get otpEntryLabel => 'Einmal-Token';

  @override
  String get entryFieldProtected =>
      'Geschütztes Feld. Klicken, um zu enthüllen.';

  @override
  String get entryFieldActionRevealField => 'Geschütztes Feld anzeigen';

  @override
  String get entryAttachmentOpenActionLabel => 'Öffnen';

  @override
  String get entryAttachmentShareActionLabel => 'Teilen';

  @override
  String get entryAttachmentShareSubject => 'Anhang';

  @override
  String get entryAttachmentSaveActionLabel => 'Auf Gerät speichern';

  @override
  String get entryAttachmentRemoveActionLabel => 'Entfernen';

  @override
  String entryAttachmentRemoveConfirm(Object attachmentLabel) {
    return 'Wollen Sie $attachmentLabel wirklich löschen?';
  }

  @override
  String get entryRenameFieldPromptTitle => 'Feld umbenennen';

  @override
  String get removerecentfile => 'Verstecken';

  @override
  String get entryRenameFieldPromptLabel => 'Neuen Namen für das Feld eingeben';

  @override
  String get promptDialogPasteActionTooltip =>
      'Einfügen von der Zwischenablage';

  @override
  String get promptDialogPasteHint =>
      'Hinweis: Wenn sie etwas einfügen wollen, versuchen sie den Knopf zu ihrer linken ;-)';

  @override
  String get genericErrorDialogTitle => 'Fehler beim ausführen der Aktion';

  @override
  String genericErrorDialogBody(Object errorMessage) {
    return 'Es ist ein unerwarteter Fehler aufgetreten. $errorMessage';
  }

  @override
  String get saveAsEntryLocalFile => 'Speichern als Lokale Datei';

  @override
  String get fileTypePngs => 'Bilder (png)';

  @override
  String get selectIconDialogAction => 'WÄHLE ICON';

  @override
  String get retryDialogActionLabel => 'Erneut versuchen';

  @override
  String errorDuringNetworkCall(Object errorMessage) {
    return 'Fehler beim Api-Abfrage. $errorMessage';
  }

  @override
  String get passwordFilterHideDeleted => 'Gelöschte Einträge ausblenden';

  @override
  String get passwordFilterOnlyDeleted => 'Gelöschte Einträge';

  @override
  String passwordFilterPrefixForOneGroup(Object groupName) {
    return 'Gruppe: $groupName';
  }

  @override
  String passwordFilterPrefixForMultipleGroups(Object groupCount) {
    return 'Eigener Filter ($groupCount Gruppen)';
  }

  @override
  String get menuItemopenvalutCloudAuthenticate =>
      'Mit OpenValut Cloud authentifizieren';

  @override
  String get menuItemopenvalutCloudMailboxes => 'OpenValut Postfächer';

  @override
  String changesWithoutSaving(Object fileName) {
    return 'Sie haben Änderungen in \"$fileName\", die das Schreiben von Änderungen nicht unterstützen.';
  }

  @override
  String get changesSaveLocally => 'Lokal speichern';

  @override
  String get clearColor => 'Farbe löschen';

  @override
  String get databaseRenameInputLabel => 'Datenbank-Name eingeben';

  @override
  String get databasePath => 'Pfad';

  @override
  String get databaseColor => 'Farbe';

  @override
  String get databaseColorChoose =>
      'Wählen Sie eine Farbe um zwischen Dateien zu unterscheiden.';

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
  String get databaseKdbxVersion => 'KDBX Datei-Version';

  @override
  String databaseKdbxUpgradeVersion(Object versionName) {
    return 'Upgrade auf $versionName';
  }

  @override
  String get databaseKdbxUpgradeSuccessful =>
      'Datei erfolgreich aktualisiert und gespeichert.';

  @override
  String get databaseReload => 'Neuladen und Zusammenführen';

  @override
  String progressStatus(Object statusProgress) {
    return 'Status: $statusProgress';
  }

  @override
  String finishedMerge(Object status) {
    return 'Zusammenführung beendet $status';
  }

  @override
  String get closeAndLockFile => 'Schließen/Sperren';

  @override
  String get openvalutHomeScreenTagline =>
      'password manager, open source, verfügbar auf allen Plattformen.';

  @override
  String get addNewPasswordButtonLabel => 'Neues Passwort hinzufügen';

  @override
  String get unnamedEntryPlaceholder => '(Unbenannt)';

  @override
  String get unnamedGroupPlaceholder => '(Unbenannt)';

  @override
  String get unnamedFilePlaceholder => '(Unbenannt)';

  @override
  String get editGroupScreenTitle => 'Gruppe bearbeiten';

  @override
  String get editGroupGroupNameLabel => 'Name der Gruppe';

  @override
  String get files => 'Dateien';

  @override
  String get newGroupDialogTitle => 'Neue Gruppe';

  @override
  String get newGroupDialogInputLabel => 'Name für die neue Gruppe';

  @override
  String get groupActionShowPasswords => 'Passwörter anzeigen';

  @override
  String get groupActionDelete => 'Löschen';

  @override
  String get logoutTooltip => 'Abmelden';

  @override
  String get successfullyDeletedFileCloudStorage =>
      'Datei erfolgreich gelöscht.';

  @override
  String shareDialogTitle(Object fileName) {
    return 'Freigabe-Optionen für $fileName';
  }

  @override
  String get shareFileActionLabel => 'Teilen …';

  @override
  String get shareTokenListEmptyScreenPlaceholder =>
      'Datei noch nicht freigegeben.';

  @override
  String get shareTokenNoLabel => 'Keine Beschriftung';

  @override
  String get shareTokenReadWrite => 'Lesen/Schreiben';

  @override
  String get shareTokenReadOnly => 'Nur Lesen';

  @override
  String get shareCreateTokenDialogTitle => 'Datei teilen';

  @override
  String get shareCreateTokenReadOnly => 'Nur lesen';

  @override
  String get shareCreateTokenReadOnlyHelpText =>
      'Speichern von Änderungen nicht zulassen';

  @override
  String get shareCreateTokenLabelText => 'Beschreibung';

  @override
  String get shareCreateTokenLabelHint => 'Für meinen Freund freigeben';

  @override
  String get shareCreateTokenLabelHelp =>
      'Optionales Label zur Differenzierung von Share Code.';

  @override
  String get shareCreateTokenSuccess => 'Freigabecode erfolgreich erstellt.';

  @override
  String get sharePresentDialogTitle =>
      'Datei mit geheimem Freigabecode teilen';

  @override
  String get sharePresentDialogHelp =>
      'Benutzer des folgenden Freigabecodes können auf die Passwortdatei zugreifen. Sie benötigen zum Öffnen das Passwort und/oder die Schlüsseldatei.';

  @override
  String get sharePresentToken => 'Code teilen';

  @override
  String get sharePresentCopied => 'Code wurde in die Zwischenablage kopiert.';

  @override
  String get openvalutCloudOpenWithShareCodeTooltip =>
      'Mit Freigabecode öffnen';

  @override
  String get openvalutCloudShareFileActionLabel => 'Teilen';

  @override
  String get preferenceopenvalutCloudAttachmentTitle =>
      'OpenValut Cloud-Anhänge verwenden';

  @override
  String get preferenceopenvalutCloudAttachmentSubtitle =>
      'Anhänge speichern, die in OpenValut Cloud separat verschlüsselt werden.';

  @override
  String get shareCodeInputDialogTitle => 'Geheime Freigabe-Code eingeben';

  @override
  String get shareCodeInputDialogScan => 'Scan QR Code';

  @override
  String get shareCodeInputLabel => 'Geheime Freigabe-Code';

  @override
  String get shareCodeInputHelperText =>
      'Wenn Sie einen Teilcode erhalten haben, fügen Sie ihn bitte oben ein.';

  @override
  String get shareCodeOpen => 'Freigabecode für OpenValut Cloud erhalten?';

  @override
  String get shareCodeOpenScreenTitle => 'Datei mit Freigabecode wird geladen';

  @override
  String get shareCodeLoadingProgress => 'Datei wird geladen …';

  @override
  String get shareCodeOpenFileButtonLabel => 'Öffnen';

  @override
  String get shareCodeOpenInstallAppCaption =>
      'Möchten Sie diese Datei stattdessen mit einer unserer nativen Apps öffnen?';

  @override
  String get shareCodeOpenAnotherAppCaption =>
      'Möchten Sie diese Datei auf einem anderen Gerät öffnen?';

  @override
  String get shareCodeOpenInstallAppButtonLabel => 'App installieren';

  @override
  String get shareCodeOpenShowCodeButtonLabel => 'Freigabecode anzeigen';

  @override
  String get changeMasterPasswordActionLabel => 'Master-Passwort ändern';

  @override
  String get changeMasterPasswordFormSubmit => 'Mit neuem Passwort speichern';

  @override
  String get changeMasterPasswordSuccess =>
      'Master-Passwort erfolgreich gespeichert.';

  @override
  String get changeMasterPasswordScreenTitle => 'Master-Passwort ändern';

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
      'Ich habe eine Email erhalten und klickte auf denn Link';

  @override
  String get openvalutCloudAuthNotConfirmed =>
      'Die E-Mail-Adresse wurde noch nicht bestätigt. Bitte klicken Sie auf den Link in der erhaltenen E-Mail und lösen Sie das Captcha, um Ihre E-Mail-Adresse zu bestätigen.';

  @override
  String get getHelpButton => 'Erhalte Hilfe im Forum';

  @override
  String get shortcutCopyUsername => 'Benutzername kopieren';

  @override
  String get shortcutCopyPassword => 'Passwort kopieren';

  @override
  String get shortcutCopyTotp => 'TOTP kopieren';

  @override
  String get shortcutMoveUp => 'Vorheriges Passwort auswählen';

  @override
  String get shortcutMoveDown => 'Wählen Sie das nächste Passwort';

  @override
  String get shortcutGeneratePassword => 'Passwort generieren';

  @override
  String get shortcutCopyUrl => 'URL kopieren';

  @override
  String get shortcutOpenUrl => 'URL Öffnen';

  @override
  String get shortcutCancelSearch => 'Suche abbrechen';

  @override
  String get shortcutShortcutHelp => 'Hilfe zu dennTastenkombinationen';

  @override
  String get shortcutHelpTitle => 'Tastenkombinationen';

  @override
  String unexpectedError(String error) {
    return 'Unerwarteter Fehler: $error';
  }

  @override
  String get googleDriveMorePermissionsRequired =>
      'Additional permissions needed to access Google Drive.';

  @override
  String get googleDriveRequestPermissionButtonLabel => 'Request Permissions';

  @override
  String get scanQrCodeTitle => 'QR-Code Scannen.';
}
