// ignore_for_file: omit_local_variable_types,unused_local_variable

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

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
  String get entryAddAttachment => 'Add Attachment';

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
  String get fieldUserName => 'Usuário';

  @override
  String get fieldPassword => 'Palavra-passe';

  @override
  String get fieldWebsite => 'Website';

  @override
  String get fieldTitle => 'Título';

  @override
  String get fieldTotp => 'Senha Única (Baseado no Tempo)';

  @override
  String get english => 'Inglês';

  @override
  String get german => 'Alemão';

  @override
  String get russian => 'Russo';

  @override
  String get ukrainian => 'Ucraniano';

  @override
  String get lithuanian => 'Lituano';

  @override
  String get french => 'Francês';

  @override
  String get spanish => 'Espanhol';

  @override
  String get indonesian => 'Indonésio';

  @override
  String get turkish => 'Turco';

  @override
  String get hebrew => 'Hebraico';

  @override
  String get italian => 'Italiano';

  @override
  String get chineseSimplified => 'Chinês simplificado';

  @override
  String get chineseTraditional => 'Chinês tradicional';

  @override
  String get portugueseBrazilian => 'Português brasileiro';

  @override
  String get slovak => 'Eslovaco';

  @override
  String get dutch => 'Holandês';

  @override
  String get selectItem => 'Selecionar';

  @override
  String get selectKeepassFile => 'OpenValut - Selecionar arquivo KeePass';

  @override
  String get selectKeepassFileLabel =>
      'Por favor, selecione um arquivo KeePass (.kdbx)';

  @override
  String get createNewFile => 'Criar novo arquivo';

  @override
  String get openLocalFile => 'Abrir\nArquivo Local';

  @override
  String get openFile => 'Abrir arquivo';

  @override
  String get loadFromDropdownMenu => 'Carregar de …';

  @override
  String get quickUnlockingFiles => 'Desbloqueio rápido de arquivos …';

  @override
  String openFileProgress(Object fileName, Object current, Object totalCount) {
    return 'Abrindo $fileName … ($current / $totalCount)';
  }

  @override
  String loadFrom(String cloudStorageName) {
    return 'Carregar de $cloudStorageName';
  }

  @override
  String get loadFromRemoteUrl => 'Abrir kdbx de URL';

  @override
  String get createNewKeepass =>
      'Novo no KeePass?\nCriar nova base de dados de senhas';

  @override
  String get labelLastOpenFiles => 'Últimos arquivos abertos:';

  @override
  String get noFilesHaveBeenOpenYet => 'Nenhum arquivo foi aberto ainda.';

  @override
  String get preferenceSelectLanguage => 'Selecione o idioma';

  @override
  String get preferenceLanguage => 'Língua';

  @override
  String get preferenceTextScaleFactor => 'Fator de Escala de Texto';

  @override
  String get preferenceVisualDensity => 'Densidade visual';

  @override
  String get preferenceTheme => 'Tema';

  @override
  String get preferenceThemeLight => 'Claro';

  @override
  String get preferenceThemeDark => 'Escuro';

  @override
  String get preferenceSystemDefault => 'Padrão do Sistema';

  @override
  String get preferenceDefault => 'Predefinição';

  @override
  String get lockAllFiles => 'Bloquear todos os arquivos abertos';

  @override
  String get preferenceAllowScreenshots => 'Permitir capturas de tela do App';

  @override
  String get preferenceEnableAutoFill => 'Ativar preenchimento automático';

  @override
  String get enableAutofillSuggestionBanner =>
      'Você pode preencher o campo de outra aplicação ativando o preenchimento automático!';

  @override
  String get dismissAutofillSuggestionBannerButton => 'Dispensar';

  @override
  String get enableAutofillSuggestionBannerButton => 'ATIVAR!';

  @override
  String get preferenceAutoFillDescription =>
      'Suportado somente no Android Oreo (8.0) ou superior.';

  @override
  String get preferenceTitle => 'Preferências';

  @override
  String get preferenceEnableSystemWideShortcuts =>
      'Enable system wide shortcuts';

  @override
  String get preferenceEnableSystemWideShortcutsHelp =>
      'Registers ctrl+alt+f as system wide shortcut to open search.';

  @override
  String get preferencesSearchFields => 'Personalizar os Campos de Pesquisa';

  @override
  String get preferencesSearchFieldPromptTitle => 'Campos de pesquisa';

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
  String get aboutLinkGitHub => 'And Open Source Project';

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
    return 'Opened URL: $url';
  }

  @override
  String get menuItemGeneratePassword => 'Generate Password';

  @override
  String get menuItemPreferences => 'Preferences';

  @override
  String get menuItemOpenAnotherFile => 'Open another File';

  @override
  String get menuItemCheckForUpdates => 'Check for updates';

  @override
  String get menuItemSupport => 'Send logs';

  @override
  String get menuItemSupportSubtitle => 'Send logs by email';

  @override
  String get menuItemForum => 'Support Forum';

  @override
  String get menuItemForumSubtitle => 'Report Problems and get help';

  @override
  String get menuItemHelp => 'Help';

  @override
  String get menuItemHelpSubtitle => 'Show documentation';

  @override
  String get menuItemAbout => 'Sobre';

  @override
  String get actionOpenUrl => 'Abrir URL';

  @override
  String get passwordPlainText => 'Mostrar senha';

  @override
  String get generatorPassword => 'Senha';

  @override
  String get generatePassword => 'Gerar Senha';

  @override
  String get doneButtonLabel => 'Concluído';

  @override
  String get useAsDefault => 'Usar como Padrão';

  @override
  String get characterSetLowerCase => 'Minúsculas (a-z)';

  @override
  String get characterSetUpperCase => 'Maiúsculas (A-Z)';

  @override
  String get characterSetNumeric => 'Números (0-9)';

  @override
  String get characterSetUmlauts => 'Trema (ä)';

  @override
  String get characterSetSpecial => 'Caracteres especiais (@%+)';

  @override
  String get length => 'Tamanho';

  @override
  String get customLength => 'Tamanho personalizado';

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
  String get manageGroups => 'Gerenciar Grupos';

  @override
  String get lockFiles => 'Bloquear Arquivos';

  @override
  String get searchHint => 'Pesquisar';

  @override
  String get searchButtonLabel => 'Pesquisar';

  @override
  String get filterButtonLabel => 'Filtrar por grupo';

  @override
  String get clear => 'Limpar';

  @override
  String get autofillFilterPrefix => 'Filtro:';

  @override
  String get autofillMatchPrefix => 'Matching entries for:';

  @override
  String get autofillPrompt =>
      'Selecione a senha para preenchimento automático.';

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
  String get copiedToClipboard => 'Copiado para a área de transferência.';

  @override
  String get noTitle => '(sem título)';

  @override
  String get noUsername => '(sem nome)';

  @override
  String get filterCustomize => 'Personalizar …';

  @override
  String get swipeCopyPassword => 'Copiar Senha';

  @override
  String get swipeCopyUsername => 'Copiar Usuário';

  @override
  String get copyUsernameNotExists =>
      'Entrada não possui um nome de usuário definido.';

  @override
  String get copyPasswordNotExists =>
      'Entrada não possui um nome de usuário definido.';

  @override
  String get doneCopiedPassword => 'Senha copiada para área de transferência.';

  @override
  String get doneCopiedUsername => 'Senha copiada para área de transferência.';

  @override
  String get doneCopiedField => 'Copiado.';

  @override
  String copiedFieldToClipboard(Object fieldName) {
    return '$fieldName copiado.';
  }

  @override
  String copiedFieldEmpty(Object fieldName) {
    return '$fieldName está vazio.';
  }

  @override
  String get emptyPasswordVaultPlaceholder =>
      'Você ainda não tem nenhuma senha no seu banco de dados.';

  @override
  String get emptyPasswordVaultButtonLabel => 'Crie sua primeira senha';

  @override
  String get loading => 'Carregando...';

  @override
  String get loadingFile => 'Carregando arquivo …';

  @override
  String get internalFile => 'Arquivo interno';

  @override
  String get internalFileSubtitle => 'Banco de dados criado com o OpenValut';

  @override
  String get filePicker => 'Selecionador de Arquivo';

  @override
  String get filePickerSubtitle => 'Abrir arquivo a partir do dispositivo.';

  @override
  String get credentialsAppBarTitle => 'Credenciais';

  @override
  String get credentialLabel => 'Digite a senha para:';

  @override
  String get masterPasswordInputLabel => 'Palavra-passe';

  @override
  String get masterPasswordEmptyValidator => 'Por favor, digite sua senha.';

  @override
  String get masterPasswordIncorrectValidator => 'Senha inválida';

  @override
  String get useKeyFile => 'Usar o arquivo chave';

  @override
  String get saveMasterPasswordBiometric =>
      'Salvar senha com armazenamento de chave biométrica?';

  @override
  String get close => 'Fechar';

  @override
  String get addNewPassword => 'Adicionar nova senha';

  @override
  String get errorOpenFileInvalidFileStructureTitle =>
      'Tentou abrir arquivo inválido';

  @override
  String errorOpenFileInvalidFileStructureBody(Object fileName) {
    return 'O arquivo ($fileName) parece não ser um arquivo KDBX válido. Por favor escolha um arquivo KDBX válido ou crie um novo banco de dados de senhas.';
  }

  @override
  String get errorOpenFileAlreadyOpenTitle => 'Arquivo já aberto';

  @override
  String errorOpenFileAlreadyOpenBody(
    Object databaseName,
    Object openFileSource,
    Object newFileSource,
  ) {
    return 'O banco de dados $databaseName já está aberto a partir de $openFileSource (Tentativa de abrir a partir de $newFileSource)';
  }

  @override
  String get loadFromUrl => 'Baixar do Url';

  @override
  String get loadFromUrlEnterUrl => 'Inserir URL';

  @override
  String get loadFromUrlErrorEnterFullUrl =>
      'Por favor, insira a url completa, começando com http:// ou https://';

  @override
  String get loadFromUrlErrorInvalidUrl => 'Por favor, insira uma URL válida.';

  @override
  String get linuxAppArmorWarning =>
      'OpenValut requer permissão para se comunicar com o Serviço Secreto para armazenar credenciais de armazenamento em nuvem.\nPor favor, execute o seguinte comando:';

  @override
  String get cancel => 'Cancelar';

  @override
  String get errorLoadFileFromSourceTitle => 'Erro ao abrir o arquivo.';

  @override
  String errorLoadFileFromSourceBody(Object source, Object error) {
    return 'Não é possível abrir $source.\n$error';
  }

  @override
  String get errorUnlockFileTitle => 'Não foi possível abrir o arquivo';

  @override
  String errorUnlockFileBody(Object error) {
    return 'Erro desconhecido ao tentar abrir o arquivo. $error';
  }

  @override
  String get dialogContinue => 'Continuar';

  @override
  String get dialogSendErrorReport => 'Enviar relatório de erro';

  @override
  String get dialogReportErrorForum => 'Relatar erro no Fórum/Ajuda';

  @override
  String get groupFilterDescription =>
      'Selecionar quais grupos a exibir (recursivamente)';

  @override
  String get groupFilterSelectAll => 'Selecionar todos';

  @override
  String get groupFilterDeselectAll => 'Deselect all';

  @override
  String get createSubgroup => 'Create Subgroup';

  @override
  String get editAction => 'Edit';

  @override
  String get mailboxEnableLabel => '(re)enable';

  @override
  String get mailboxEnableHint => 'Continue receiving emails';

  @override
  String get mailboxDisableLabel => 'Disable';

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
  String get undoButtonLabel => 'Undo';

  @override
  String get saveButtonLabel => 'Save';

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
  String get webDavopenvalutword => 'Password';

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
  String get initialNewGroupName => 'New Group';

  @override
  String get deleteGroupErrorTitle => 'Unable to delete group';

  @override
  String get deleteGroupErrorBodyContainsGroup =>
      'This group still contains other groups. You can currently only delete empty groups.';

  @override
  String get deleteGroupErrorBodyContainsEntries =>
      'This group still contains password entries. You can currently only delete empty groups.';

  @override
  String get groupListAppBarTitle => 'Groups';

  @override
  String get groupListFilterAppbarTitle => 'Filter by groups';

  @override
  String get clearQuickUnlock => 'Clear Biometric Storage';

  @override
  String get clearQuickUnlockSubtitle => 'Remove saved master passwords';

  @override
  String get unlock => 'Desbloquear arquivos';

  @override
  String get closePasswordFiles => 'fechar arquivos de senha';

  @override
  String get clearQuickUnlockSuccess =>
      'Senha mestra salva do armazenamento biométrico.';

  @override
  String get diacOptIn =>
      'Opte por receber notícias do aplicativo, Inquéritos.';

  @override
  String get diacOptInSubtitle =>
      'Às vezes, enviará uma solicitação de rede para buscar notícias.';

  @override
  String browserAutofillThirdPartyModeTitle(String browserName) {
    return 'Enable AutoFill in $browserName';
  }

  @override
  String browserAutofillThirdPartyModeSubtitle(String browserName) {
    return '$browserName currently uses its own password manager. Tap to open its settings and select “Autofill using another service”, then restart $browserName.';
  }

  @override
  String get enableAutofillDebug => 'Preenchimento automático: Ativar debug';

  @override
  String get enableAutofillDebugSubtitle =>
      'Mostra camadas de informações para cada campo de entrada';

  @override
  String get createPasswordDatabase => 'Criar banco de dados de senha';

  @override
  String get nameNewPasswordDatabase => 'Nome do seu novo banco de dados';

  @override
  String get validatorNameMissing =>
      'Please enter a name for your new database.';

  @override
  String get masterPasswordHelpText =>
      'Select a secure master Password. Make sure to remember it.';

  @override
  String get inputMasterPasswordText => 'Master Password';

  @override
  String get masterPasswordMissingCreate =>
      'Please enter a secure, rememberable password.';

  @override
  String get createDatabaseAction => 'Create Database';

  @override
  String get databaseExistsError => 'File Exists';

  @override
  String databaseExistsErrorDescription(Object filePath) {
    return 'Error while trying to create database $filePath. File already exists. Please choose another name.';
  }

  @override
  String get databaseCreateDefaultName => 'PersonalPasswords';

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
  String get entryInfoFile => 'File:';

  @override
  String get entryInfoGroup => 'Group:';

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
  String get fieldRename => 'Rename';

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
  String get onboardingYesOpenPasswords => 'Yes, open my passwords';

  @override
  String get onboardingNoCreate => 'I\'m all new! Get me started.';

  @override
  String get backupButton => 'SAVE TO CLOUD';

  @override
  String get dismissBackupButton => 'DISMISS';

  @override
  String backupWarningMessage(Object databasename) {
    return 'Your passwords in $databasename are only saved locally!';
  }

  @override
  String get saveAs => 'Save In...';

  @override
  String get saving => 'Saving';

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
  String get newGroupDialogTitle => 'New Group';

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
  String get shareCodeLoadingProgress => 'Loading file …';

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
  String get shortcutCopyUsername => 'Copy Username';

  @override
  String get shortcutCopyPassword => 'Copy Password';

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
  String get shortcutShortcutHelp => 'Keyboard Shortcut Help';

  @override
  String get shortcutHelpTitle => 'Keyboard Shortcuts';

  @override
  String unexpectedError(String error) {
    return 'Unexpected Error: $error';
  }

  @override
  String get googleDriveMorePermissionsRequired =>
      'Additional permissions needed to access Google Drive.';

  @override
  String get googleDriveRequestPermissionButtonLabel => 'Request Permissions';

  @override
  String get scanQrCodeTitle => 'Scan QR Code.';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get entryAddAttachment => 'Adicionar Anexo';

  @override
  String get fieldUserName => 'Usuário';

  @override
  String get fieldPassword => 'Senha';

  @override
  String get fieldWebsite => 'Site';

  @override
  String get fieldTitle => 'Título';

  @override
  String get fieldTotp => 'Senha Única (Baseado no Tempo)';

  @override
  String get english => 'Inglês';

  @override
  String get german => 'Alemão';

  @override
  String get russian => 'Russo';

  @override
  String get ukrainian => 'Ucraniano';

  @override
  String get lithuanian => 'Lituano';

  @override
  String get french => 'Francês';

  @override
  String get spanish => 'Espanhol';

  @override
  String get indonesian => 'Indonésio';

  @override
  String get turkish => 'Turco';

  @override
  String get hebrew => 'Hebraico';

  @override
  String get italian => 'Italiano';

  @override
  String get chineseSimplified => 'Chinês Simplificado';

  @override
  String get chineseTraditional => 'Chinês Tradicional';

  @override
  String get portugueseBrazilian => 'Português (Brasil)';

  @override
  String get slovak => 'Eslovaco';

  @override
  String get dutch => 'Holandês';

  @override
  String get selectItem => 'Selecione';

  @override
  String get selectKeepassFile => 'OpenValut - Selecionar Arquivo do KeePass';

  @override
  String get selectKeepassFileLabel =>
      'Selecione um arquivo do KeePass (.kdbx).';

  @override
  String get createNewFile => 'Criar Novo Arquivo';

  @override
  String get openLocalFile => 'Abrir\nArquivo Local';

  @override
  String get openFile => 'Abrir Arquivo';

  @override
  String get loadFromDropdownMenu => 'Carregar a partir de…';

  @override
  String get quickUnlockingFiles => 'Desbloqueio rápido de arquivos…';

  @override
  String openFileProgress(Object fileName, Object current, Object totalCount) {
    return 'Abrindo $fileName … ($current / $totalCount)';
  }

  @override
  String loadFrom(String cloudStorageName) {
    return 'Carregar de $cloudStorageName';
  }

  @override
  String get loadFromRemoteUrl => 'Abrir kdbx da URL';

  @override
  String get createNewKeepass =>
      'Novo no KeePass?\nCriar Novo Banco de Dados de Senhas';

  @override
  String get labelLastOpenFiles => 'Últimos arquivos abertos:';

  @override
  String get noFilesHaveBeenOpenYet => 'Nenhum arquivo foi aberto ainda.';

  @override
  String get preferenceSelectLanguage => 'Selecionar Idioma';

  @override
  String get preferenceLanguage => 'Idioma';

  @override
  String get preferenceTextScaleFactor => 'Tamanho do Texto';

  @override
  String get preferenceVisualDensity => 'Densidade Visual';

  @override
  String get preferenceTheme => 'Tema';

  @override
  String get preferenceThemeLight => 'Claro';

  @override
  String get preferenceThemeDark => 'Escuro';

  @override
  String get preferenceSystemDefault => 'Padrão do Sistema';

  @override
  String get preferenceDefault => 'Padrão';

  @override
  String get lockAllFiles => 'Bloquear todos os arquivos abertos';

  @override
  String get preferenceAllowScreenshots =>
      'Permitir Capturas de Tela do Aplicativo';

  @override
  String get preferenceEnableAutoFill => 'Habilitar preenchimento automático';

  @override
  String get enableAutofillSuggestionBanner =>
      'Você pode preencher as credenciais de outros aplicativos ativando o preenchimento automático!';

  @override
  String get dismissAutofillSuggestionBannerButton => 'DISPENSAR';

  @override
  String get enableAutofillSuggestionBannerButton => 'ATIVE!';

  @override
  String get preferenceAutoFillDescription =>
      'Somente suportado em Android Oreo (8.0) ou posterior.';

  @override
  String get preferenceTitle => 'Preferências';

  @override
  String get preferenceEnableSystemWideShortcuts =>
      'Ative os atalhos do sistema';

  @override
  String get preferenceEnableSystemWideShortcutsHelp =>
      'Registre ctrl+alt+f como atalho do sistema para abrir a pesquisa.';

  @override
  String get preferencesSearchFields => 'Customizar campos de pesquisa';

  @override
  String get preferencesSearchFieldPromptTitle => 'Campos de pesquisa';

  @override
  String get preferencesSearchFieldPromptLabel =>
      'Lista de campos separados por vírgula para usar na lista de busca de senhas.';

  @override
  String preferencesSearchFieldPromptHelp(
    Object wildCardCharacter,
    Object defaultSearchFields,
  ) {
    return 'Use $wildCardCharacter para todos, deixe em branco por padrão ($defaultSearchFields)';
  }

  @override
  String get aboutAppName => 'OpenValut';

  @override
  String get aboutLinkFeedback => 'Qualquer tipo de feedback é bem-vindo!';

  @override
  String get aboutLinkVisitWebsite =>
      'Lembre-se também de visitar o nosso site';

  @override
  String get aboutLinkGitHub => 'Um Projeto de Código Aberto';

  @override
  String aboutLogFile(String logFilePath) {
    return 'Arquivo de Log: $logFilePath';
  }

  @override
  String get aboutLinkContributors => 'Mostrar Colaboradores';

  @override
  String get unableToLaunchUrlTitle => 'Não foi possível abrir a URL';

  @override
  String unableToLaunchUrlDescription(Object url, Object openError) {
    return 'Não foi possível iniciar $url: $openError';
  }

  @override
  String get unableToLaunchUrlNoHandler =>
      'Nenhum aplicativo disponível para URL.';

  @override
  String launchedUrl(Object url) {
    return 'URL Aberta: $url';
  }

  @override
  String get menuItemGeneratePassword => 'Gerar Senha';

  @override
  String get menuItemPreferences => 'Preferências';

  @override
  String get menuItemOpenAnotherFile => 'Abrir outro Arquivo';

  @override
  String get menuItemCheckForUpdates => 'Verificar por atualizações';

  @override
  String get menuItemSupport => 'Enviar registros';

  @override
  String get menuItemSupportSubtitle => 'Enviar registros por e-mail';

  @override
  String get menuItemForum => 'Fórum de Suporte';

  @override
  String get menuItemForumSubtitle => 'Relatar problemas e obter ajuda';

  @override
  String get menuItemHelp => 'Ajuda';

  @override
  String get menuItemHelpSubtitle => 'Mostrar documentação';

  @override
  String get menuItemAbout => 'Sobre';

  @override
  String get actionOpenUrl => 'Abrir URL';

  @override
  String get passwordPlainText => 'Mostrar senha';

  @override
  String get generatorPassword => 'Senha';

  @override
  String get generatePassword => 'Gerar Senha';

  @override
  String get doneButtonLabel => 'Concluído';

  @override
  String get useAsDefault => 'Usar como Padrão';

  @override
  String get characterSetLowerCase => 'Minúsculas (a-z)';

  @override
  String get characterSetUpperCase => 'Maiúsculas (A-Z)';

  @override
  String get characterSetNumeric => 'Numérico (0-9)';

  @override
  String get characterSetUmlauts => 'Metafonia (ä)';

  @override
  String get characterSetSpecial => 'Especial (@%+)';

  @override
  String get length => 'Comprimento';

  @override
  String get customLength => 'Comprimento Personalizado';

  @override
  String customLengthHelperText(Object customMinLength) {
    return 'Usado apenas para comprimento > $customMinLength';
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
      other: '$numFilesString arquivos salvos: $files',
      one: 'Um arquivo salvo: $files',
    );
    return '$_temp0';
  }

  @override
  String get manageGroups => 'Gerenciar Grupos';

  @override
  String get lockFiles => 'Bloquear Arquivos';

  @override
  String get searchHint => 'Pesquisar';

  @override
  String get searchButtonLabel => 'Pesquisar';

  @override
  String get filterButtonLabel => 'Filtrar por grupos';

  @override
  String get clear => 'Limpar';

  @override
  String get autofillFilterPrefix => 'Filtro:';

  @override
  String get autofillPrompt =>
      'Selecione a senha para preenchimento automático.';

  @override
  String get copiedToClipboard => 'Copiado para a área de transferência.';

  @override
  String get noTitle => '(sem título)';

  @override
  String get noUsername => '(sem nome)';

  @override
  String get filterCustomize => 'Personalizar …';

  @override
  String get swipeCopyPassword => 'Copiar Senha';

  @override
  String get swipeCopyUsername => 'Copiar Usuário';

  @override
  String get copyUsernameNotExists =>
      'Entrada não tem nenhum nome de usuário definido.';

  @override
  String get copyPasswordNotExists =>
      'A entrada não possui uma senha definida.';

  @override
  String get doneCopiedPassword => 'Senha copiada para área de transferência.';

  @override
  String get doneCopiedUsername =>
      'Nome de usuário copiado para área de transferência.';

  @override
  String get doneCopiedField => 'Copiado.';

  @override
  String copiedFieldToClipboard(Object fieldName) {
    return '$fieldName copiado.';
  }

  @override
  String copiedFieldEmpty(Object fieldName) {
    return '$fieldName está vazio.';
  }

  @override
  String get emptyPasswordVaultPlaceholder =>
      'Você ainda não possui nenhuma senha no seu banco de dados.';

  @override
  String get emptyPasswordVaultButtonLabel => 'Crie a sua primeira Senha';

  @override
  String get loading => 'Carregando...';

  @override
  String get loadingFile => 'Carregando arquivo …';

  @override
  String get internalFile => 'Arquivo interno';

  @override
  String get internalFileSubtitle =>
      'Banco de dados previamente criado com o OpenValut';

  @override
  String get filePicker => 'Selecionar Arquivo';

  @override
  String get filePickerSubtitle => 'Abrir arquivo a partir do dispositivo.';

  @override
  String get credentialsAppBarTitle => 'Credenciais';

  @override
  String get credentialLabel => 'Digite a senha para:';

  @override
  String get masterPasswordInputLabel => 'Senha';

  @override
  String get masterPasswordEmptyValidator => 'Por favor, digite sua senha.';

  @override
  String get masterPasswordIncorrectValidator => 'Senha inválida';

  @override
  String get useKeyFile => 'Usar Arquivo Chave';

  @override
  String get saveMasterPasswordBiometric =>
      'Salvar Senha com armazenamento de chave biométrica?';

  @override
  String get close => 'Fechar';

  @override
  String get addNewPassword => 'Adicionar nova senha';

  @override
  String get errorOpenFileInvalidFileStructureTitle =>
      'Tentou abrir um tipo de arquivo inválido';

  @override
  String errorOpenFileInvalidFileStructureBody(Object fileName) {
    return 'O arquivo ($fileName) parece não ser um arquivo KDBX válido. Por favor, escolha um arquivo KDBX válido ou crie um novo banco de senhas.';
  }

  @override
  String get errorOpenFileAlreadyOpenTitle => 'Arquivo já aberto';

  @override
  String errorOpenFileAlreadyOpenBody(
    Object databaseName,
    Object openFileSource,
    Object newFileSource,
  ) {
    return 'O banco de dados $databaseName já está aberto a partir de $openFileSource (Tentativa de abrir a partir de $newFileSource)';
  }

  @override
  String get loadFromUrl => 'Baixar da URL';

  @override
  String get loadFromUrlEnterUrl => 'Insira a URL';

  @override
  String get loadFromUrlErrorEnterFullUrl =>
      'Por favor, insira a URL completa, começando com http:// ou https://';

  @override
  String get loadFromUrlErrorInvalidUrl => 'Por favor, insira uma URL válida.';

  @override
  String get linuxAppArmorWarning =>
      'OpenValut requer permissão para se comunicar com o Serviço Secreto para armazenar credenciais na nuvem.\nPor favor, execute o seguinte comando:';

  @override
  String get cancel => 'Cancelar';

  @override
  String get errorLoadFileFromSourceTitle =>
      'Ocorreu um erro ao abrir arquivo.';

  @override
  String errorLoadFileFromSourceBody(Object source, Object error) {
    return 'Não é possível abrir $source.\n$error';
  }

  @override
  String get errorUnlockFileTitle => 'Não foi possível abrir o arquivo';

  @override
  String errorUnlockFileBody(Object error) {
    return 'Erro desconhecido ao tentar abrir o arquivo. $error';
  }

  @override
  String get dialogContinue => 'Continuar';

  @override
  String get dialogSendErrorReport => 'Enviar Relatório de Erro/Ajuda';

  @override
  String get dialogReportErrorForum => 'Relatar erro no Fórum/Ajuda';

  @override
  String get groupFilterDescription =>
      'Selecione quais Grupos exibir (recursivamente)';

  @override
  String get groupFilterSelectAll => 'Selecionar todos';

  @override
  String get groupFilterDeselectAll => 'Desmarcar todos';

  @override
  String get createSubgroup => 'Criar Subgrupo';

  @override
  String get editAction => 'Editar';

  @override
  String get mailboxEnableLabel => '(re)ativar';

  @override
  String get mailboxEnableHint => 'Continuar recebendo e-mails';

  @override
  String get mailboxDisableLabel => 'Desativar';

  @override
  String get mailboxDisableHint => 'Não receber mais e-mails';

  @override
  String get mailListNoMail => 'Você ainda não tem nenhum e-mail.';

  @override
  String mailboxLabelPrefixForEntry(Object entryLabel) {
    return 'Entrada: $entryLabel';
  }

  @override
  String mailboxLabelPrefixUnknownEntry(Object entryUuid) {
    return 'Entrada desconhecida: $entryUuid';
  }

  @override
  String mailboxLabelPrefixCreatedAt(Object dateTime) {
    return 'Criado em: $dateTime';
  }

  @override
  String get masterPasswordDescription =>
      'A senha mestra é usada para criptografar com segurança seu banco de senhas. Certifique-se de lembrá-la, ela não pode ser restaurada.';

  @override
  String get unsavedChangesWarningTitle => 'Mudanças não salvas';

  @override
  String get unsavedChangesWarningBody =>
      'Ainda existem mudanças não salvas. Você deseja descartar as mudanças?';

  @override
  String get unsavedChangesDiscardActionLabel => 'Descartar Alterações';

  @override
  String get deletePermanentlyAction => 'Excluir permanentemente';

  @override
  String get restoreFromRecycleBinAction => 'Restaurar';

  @override
  String get deleteAction => 'Apagar';

  @override
  String get deletedEntry => 'Entrada excluída.';

  @override
  String get successfullyDeletedGroup => 'Grupo apagado.';

  @override
  String get undoButtonLabel => 'Desfazer';

  @override
  String get saveButtonLabel => 'Salvar';

  @override
  String get webDavSettings => 'Configurações WebDAV';

  @override
  String get webDavUrlLabel => 'URL';

  @override
  String get webDavUrlHelperText => 'URL de base para seu serviço WebDAV.';

  @override
  String get webDavUrlValidatorError => 'Por favor, insira uma URL';

  @override
  String get webDavUrlValidatorInvalidUrlError =>
      'Digite uma URL válida com http:// ou https://';

  @override
  String get webDavAuthUser => 'Usuário';

  @override
  String get webDavopenvalutword => 'Senha';

  @override
  String get mergeSuccessDialogTitle => 'Dados de senhas mesclados com sucesso';

  @override
  String mergeSuccessDialogMessage(Object fileName, Object mergeSummary) {
    return 'Conflito detectado ao salvar $fileName, ele foi mesclado com sucesso com o arquivo remoto: \n\n$mergeSummary';
  }

  @override
  String forDetailsVisitUrl(Object url) {
    return 'Para mais detalhes visite $url';
  }

  @override
  String get openvalutCloudAuthEmailInputLabel =>
      'Insira o endereço de e-mail para registrar-se ou fazer login.';

  @override
  String get openvalutCloudAuthEmailInvalid =>
      'Por favor, insira um endereço de e-mail válido.';

  @override
  String get openvalutCloudAuthConfirmEmailButtonLabel =>
      'Confirmar endereço de e-mail';

  @override
  String get openvalutCloudAuthConfirmEmail =>
      'Por favor, verifique seus e-mails para confirmar seu endereço de e-mail.';

  @override
  String get openvalutCloudAuthConfirmEmailExplain =>
      'Mantenha essa tela aberta até você ter aberto o link que recebeu por e-mail.';

  @override
  String get openvalutCloudAuthResendExplain =>
      'Se você não recebeu um e-mail, por favor, verifique sua pasta de spam. Caso contrário, você pode tentar solicitar um novo link de confirmação.';

  @override
  String get openvalutCloudAuthResendButtonLabel =>
      'Solicitar um novo link de confirmação';

  @override
  String permanentlyDeleteEntryConfirm(Object title) {
    return 'Isto irá excluir permanentemente a senha $title. Isso não pode ser desfeito. Você quer continuar?';
  }

  @override
  String get permanentlyDeletedEntrySnackBar =>
      'Entrada excluída permanentemente.';

  @override
  String get initialNewGroupName => 'Novo Grupo';

  @override
  String get deleteGroupErrorTitle => 'Não é possível excluir o grupo';

  @override
  String get deleteGroupErrorBodyContainsGroup =>
      'Este grupo ainda contém outros grupos. No momento, você só pode excluir grupos vazios.';

  @override
  String get deleteGroupErrorBodyContainsEntries =>
      'Este grupo ainda contém entradas de senha. Você atualmente só pode excluir grupos vazios.';

  @override
  String get groupListAppBarTitle => 'Grupos';

  @override
  String get groupListFilterAppbarTitle => 'Filtrar por grupos';

  @override
  String get clearQuickUnlock => 'Limpar Armazenamento Biométrico';

  @override
  String get clearQuickUnlockSubtitle => 'Remover senhas mestres salvas';

  @override
  String get unlock => 'Desbloquear Arquivos';

  @override
  String get closePasswordFiles => 'fechar arquivos de senha';

  @override
  String get clearQuickUnlockSuccess =>
      'Removidas as senhas mestres salvas do armazenamento biométrico.';

  @override
  String get diacOptIn => 'Opte por Notícias no aplicativo, Pesquisas.';

  @override
  String get diacOptInSubtitle =>
      'Às vezes, será enviado uma solicitação de rede para buscar notícias.';

  @override
  String get enableAutofillDebug =>
      'Preenchimento Automático: Ativar depuração';

  @override
  String get enableAutofillDebugSubtitle =>
      'Mostra camadas de informações para cada campo de entrada';

  @override
  String get createPasswordDatabase => 'Criar Banco de Dados de Senhas';

  @override
  String get nameNewPasswordDatabase => 'Nome do seu novo Banco de Dados';

  @override
  String get validatorNameMissing =>
      'Por favor, digite um nome para o novo banco de dados.';

  @override
  String get masterPasswordHelpText =>
      'Selecione uma senha mestra segura. Certifique-se de lembrá-la.';

  @override
  String get inputMasterPasswordText => 'Senha Mestra';

  @override
  String get masterPasswordMissingCreate =>
      'Por favor, digite uma senha segura e fácil de ser lembrada.';

  @override
  String get createDatabaseAction => 'Criar Banco de Dados';

  @override
  String get databaseExistsError => 'O Arquivo Existe';

  @override
  String databaseExistsErrorDescription(Object filePath) {
    return 'Erro ao tentar criar o banco de dados $filePath. Já existe um arquivo. Escolha outro nome.';
  }

  @override
  String get databaseCreateDefaultName => 'Senhas_Pessoais';

  @override
  String get preferenceDynamicLoadIcons => 'Carregar ícones dinamicamente';

  @override
  String preferenceDynamicLoadIconsSubtitle(Object urlFieldName) {
    return 'Irá fazer solicitações http com o valor no campo $urlFieldName para carregar ícones de site.';
  }

  @override
  String passwordScore(Object score) {
    return 'Força: $score de 4';
  }

  @override
  String get entryInfoFile => 'Arquivo:';

  @override
  String get entryInfoGroup => 'Grupo:';

  @override
  String get entryInfoLastModified => 'Última Modificação:';

  @override
  String movedEntryToGroup(Object groupName) {
    return 'Entrada movida para $groupName';
  }

  @override
  String sizeBytesStoredopenvalutCloud(Object count) {
    return '$count bytes, armazenados no OpenValut Cloud';
  }

  @override
  String sizeBytes(Object count) {
    return '$count bytes';
  }

  @override
  String get entryAttachmentSizeWarning =>
      'Arquivos anexados serão incorporados no arquivo de senha. Isto pode aumentar significativamente o tempo necessário para abrir/salvar senhas.';

  @override
  String get iconPngSizeWarning =>
      'Ícones personalizados serão incorporados no arquivo de senha. Isto pode aumentar significativamente o tempo necessário para abrir/salvar senhas.';

  @override
  String get notPngError => 'O arquivo escolhido não é um PNG.';

  @override
  String get entryAddField => 'Adicionar Campo';

  @override
  String get entryCustomField => 'Campo Personalizado';

  @override
  String get entryCustomFieldTitle => 'Adicionando novo campo personalizado';

  @override
  String get entryCustomFieldInputLabel => 'Digite um nome para o campo';

  @override
  String get swipeCopyField => 'Copiar Campo';

  @override
  String get fieldRename => 'Renomear';

  @override
  String get fieldGeneratePassword => 'Gerar Senha …';

  @override
  String get fieldProtect => 'Proteger Valor';

  @override
  String get fieldUnprotect => 'Desproteger Valor';

  @override
  String get fieldPresent => 'Exibir';

  @override
  String get fieldGenerateEmail => 'Gerar E-mail';

  @override
  String get onboardingBackToOnboarding => 'Demonstração';

  @override
  String get onboardingBackToOnboardingSubtitle =>
      'Reviva a primeira experiência de execução 😅';

  @override
  String get onboardingHeadline => 'Vamos tornar suas Senhas Seguras!';

  @override
  String get onboardingQuestion =>
      'Você já usou um gerenciador de senhas antes?';

  @override
  String get onboardingYesOpenPasswords => 'Sim, abrir minhas senhas';

  @override
  String get onboardingNoCreate => 'Sou novo! Vou começar.';

  @override
  String get backupButton => 'SALVAR NA NUVEM';

  @override
  String get dismissBackupButton => 'DISPENSAR';

  @override
  String backupWarningMessage(Object databasename) {
    return 'Suas senhas em $databasename são salvas somente localmente!';
  }

  @override
  String get saveAs => 'Salvar em...';

  @override
  String get saving => 'Salvando';

  @override
  String get increaseValue => 'Aumentar';

  @override
  String get decreaseValue => 'Diminuir';

  @override
  String get resetValue => 'Reset';

  @override
  String cloudStorageAppBarTitle(Object cloudStorageName) {
    return 'Armazenamento em nuvem - $cloudStorageName';
  }

  @override
  String get cloudStorageLogInCaption =>
      'Você será redirecionado para autenticar o OpenValut para acessar seus dados.';

  @override
  String get cloudStorageLogInCode => 'Insira o código';

  @override
  String launchUrlError(Object url) {
    return 'Não é possível iniciar a URL. Por favor, visite $url';
  }

  @override
  String cloudStorageLogInActionLabel(Object cloudStorageName) {
    return 'Acessar $cloudStorageName';
  }

  @override
  String cloudStorageAuthCodeDialogTitle(Object cloudStorageName) {
    return 'Autenticação no $cloudStorageName';
  }

  @override
  String get cloudStorageAuthCodeLabel => 'Código de Autenticação';

  @override
  String get cloudStorageAuthErrorTitle => 'Erro durante a autenticação';

  @override
  String cloudStorageAuthErrorMessage(
    Object cloudStorageName,
    Object errorMessage,
  ) {
    return 'Erro ao tentar autenticar em $cloudStorageName: $errorMessage';
  }

  @override
  String get cloudStorageSearchBoxLabel => 'Consulta de Pesquisa';

  @override
  String cloudStorageItemsInFolder(Object itemCount) {
    return '$itemCount itens nesta pasta.';
  }

  @override
  String get mailSubject => 'Assunto';

  @override
  String get mailFrom => 'De';

  @override
  String get mailDate => 'Data';

  @override
  String get mailMailbox => 'Caixa de Entrada';

  @override
  String get mailNoData => 'Não há dados';

  @override
  String get mailMailboxesTitle => 'Caixa de Entrada';

  @override
  String get mailboxCreateButtonLabel => 'Criar';

  @override
  String get newGroupDialogTitle => 'Novo Grupo';

  @override
  String get groupActionDelete => 'Apagar';

  @override
  String get shareCodeLoadingProgress => 'Carregando arquivo …';

  @override
  String get shortcutCopyUsername => 'Copiar Usuário';

  @override
  String get shortcutCopyPassword => 'Copiar Senha';

  @override
  String get shortcutGeneratePassword => 'Gerar Senha';

  @override
  String get shortcutOpenUrl => 'Abrir URL';

  @override
  String unexpectedError(String error) {
    return 'Erro Inesperado: $error';
  }
}
