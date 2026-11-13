// ignore_for_file: omit_local_variable_types,unused_local_variable

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

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
  String get entryAddAttachment => 'Añadir archivo adjunto';

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
  String get fieldUserName => 'Usuario';

  @override
  String get fieldPassword => 'Contraseña';

  @override
  String get fieldWebsite => 'Sitio web';

  @override
  String get fieldTitle => 'Título';

  @override
  String get fieldTotp => 'Contraseña de una sola vez (basada en el tiempo)';

  @override
  String get english => 'Inglés';

  @override
  String get german => 'Alemán';

  @override
  String get russian => 'Ruso';

  @override
  String get ukrainian => 'Ucraniano';

  @override
  String get lithuanian => 'Lituano';

  @override
  String get french => 'Francés';

  @override
  String get spanish => 'Español';

  @override
  String get indonesian => 'Indonesio';

  @override
  String get turkish => 'Turco';

  @override
  String get hebrew => 'Hebreo';

  @override
  String get italian => 'italiano';

  @override
  String get chineseSimplified => 'Chino simplificado';

  @override
  String get chineseTraditional => 'Chino Tradicional';

  @override
  String get portugueseBrazilian => 'Portugués, Basilero';

  @override
  String get slovak => 'Eslovaco';

  @override
  String get dutch => 'Holandés';

  @override
  String get selectItem => 'Seleccionar';

  @override
  String get selectKeepassFile => 'OpenValut - Seleccionar archivo KeePass';

  @override
  String get selectKeepassFileLabel =>
      'Por favor seleccione un archivo KeePass (.kdbx).';

  @override
  String get createNewFile => 'Crear nuevo archivo';

  @override
  String get openLocalFile => 'Abrir archivo local';

  @override
  String get openFile => 'Abrir archivo';

  @override
  String get loadFromDropdownMenu => 'Cargar desde …';

  @override
  String get quickUnlockingFiles => 'Desbloqueo rápido de archivos…';

  @override
  String openFileProgress(Object fileName, Object current, Object totalCount) {
    return 'Abriendo $fileName … ($current / $totalCount)';
  }

  @override
  String loadFrom(String cloudStorageName) {
    return 'Cargar desde $cloudStorageName';
  }

  @override
  String get loadFromRemoteUrl => 'Abrir kdbx desde URL';

  @override
  String get createNewKeepass =>
      '¿Nuevo en KeePass?\nCrear nueva base de datos de contraseñas';

  @override
  String get labelLastOpenFiles => 'Últimos archivos abiertos:';

  @override
  String get noFilesHaveBeenOpenYet => 'Aún no se han abierto archivos.';

  @override
  String get preferenceSelectLanguage => 'Seleccionar Idioma';

  @override
  String get preferenceLanguage => 'Idioma';

  @override
  String get preferenceTextScaleFactor => 'Escala de texto';

  @override
  String get preferenceVisualDensity => 'Densidad visual';

  @override
  String get preferenceTheme => 'Tema';

  @override
  String get preferenceThemeLight => 'Claro';

  @override
  String get preferenceThemeDark => 'Oscuro';

  @override
  String get preferenceSystemDefault => 'Predeterminado del sistema';

  @override
  String get preferenceDefault => 'Predeterminado';

  @override
  String get lockAllFiles => 'Bloquear todos los archivos abiertos';

  @override
  String get preferenceAllowScreenshots =>
      'Permitir capturas de pantalla de la aplicación';

  @override
  String get preferenceEnableAutoFill => 'Habilitar autocompletar';

  @override
  String get enableAutofillSuggestionBanner =>
      '¡Puedes rellenar los espacios en otras aplicaciones habilitando el llenado automático!';

  @override
  String get dismissAutofillSuggestionBannerButton => 'DESCARTAR';

  @override
  String get enableAutofillSuggestionBannerButton => '¡HABILITAR!';

  @override
  String get preferenceAutoFillDescription =>
      'Sólo compatible con Android Oreo (8.0) o posterior.';

  @override
  String get preferenceTitle => 'Preferencias';

  @override
  String get preferenceEnableSystemWideShortcuts =>
      'Habilitar accesos directos del sistema';

  @override
  String get preferenceEnableSystemWideShortcutsHelp =>
      'Registra CTRL + ALT + F como un atajo general para abrir el buscador.';

  @override
  String get preferencesSearchFields => 'Personalizar campos de búsqueda';

  @override
  String get preferencesSearchFieldPromptTitle => 'Campos de búsqueda';

  @override
  String get preferencesSearchFieldPromptLabel =>
      'Lista de espacios separados por una coma para usar en la búsqueda de la lista de contraseñas.';

  @override
  String preferencesSearchFieldPromptHelp(
    Object wildCardCharacter,
    Object defaultSearchFields,
  ) {
    return 'Utilizar $wildCardCharacter para todo, dejar vacío por defecto ($defaultSearchFields)';
  }

  @override
  String get aboutAppName => 'OpenValut';

  @override
  String get aboutLinkFeedback => '¡Agradecemos cualquier tipo de comentarios!';

  @override
  String get aboutLinkVisitWebsite =>
      'También asegúrese de visitar nuestro sitio web';

  @override
  String get aboutLinkGitHub => 'Y el proyecto de Código Abierto';

  @override
  String aboutLogFile(String logFilePath) {
    return 'Archivo Log: $logFilePath';
  }

  @override
  String get aboutLinkContributors => 'Mostrar colaboradores';

  @override
  String get unableToLaunchUrlTitle => 'No se pudo abrir la Url';

  @override
  String unableToLaunchUrlDescription(Object url, Object openError) {
    return 'No se puede abrir $url: $openError';
  }

  @override
  String get unableToLaunchUrlNoHandler =>
      'Ninguna aplicación disponible para la url.';

  @override
  String launchedUrl(Object url) {
    return 'URL abierta: $url';
  }

  @override
  String get menuItemGeneratePassword => 'Generar contraseña';

  @override
  String get menuItemPreferences => 'Preferencias';

  @override
  String get menuItemOpenAnotherFile => 'Abrir otro archivo';

  @override
  String get menuItemCheckForUpdates => 'Buscar actualizaciones';

  @override
  String get menuItemSupport => 'Enviar bitácoras';

  @override
  String get menuItemSupportSubtitle =>
      'Enviar registros por correo electrónico';

  @override
  String get menuItemForum => 'Foro de Soporte';

  @override
  String get menuItemForumSubtitle => 'Reportar problemas y obtener ayuda';

  @override
  String get menuItemHelp => 'Ayuda';

  @override
  String get menuItemHelpSubtitle => 'Mostrar documentación';

  @override
  String get menuItemAbout => 'Acerca de';

  @override
  String get actionOpenUrl => 'Abrir URL';

  @override
  String get passwordPlainText => 'Mostrar contraseña';

  @override
  String get generatorPassword => 'Contraseña';

  @override
  String get generatePassword => 'Generar contraseña';

  @override
  String get doneButtonLabel => 'Listo';

  @override
  String get useAsDefault => 'Usar como predeterminado';

  @override
  String get characterSetLowerCase => 'Minúsculas (a-z)';

  @override
  String get characterSetUpperCase => 'Mayúsculas (A-Z)';

  @override
  String get characterSetNumeric => 'Numérico (0-9)';

  @override
  String get characterSetUmlauts => 'Umlaut (ä)';

  @override
  String get characterSetSpecial => 'Especial (@%+)';

  @override
  String get length => 'Longitud';

  @override
  String get customLength => 'Longitud personalizada';

  @override
  String customLengthHelperText(Object customMinLength) {
    return 'Solo usado para longitud > $customMinLength';
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
      other: '$numFilesString archivos guardados: $files',
      one: 'Un archivo guardado: $files',
    );
    return '$_temp0';
  }

  @override
  String get manageGroups => 'Gestionar Grupos';

  @override
  String get lockFiles => 'Bloquear Archivos';

  @override
  String get searchHint => 'Buscar';

  @override
  String get searchButtonLabel => 'Buscar';

  @override
  String get filterButtonLabel => 'Filtrar por grupo';

  @override
  String get clear => 'Borrar';

  @override
  String get autofillFilterPrefix => 'Filtro:';

  @override
  String get autofillMatchPrefix => 'Matching entries for:';

  @override
  String get autofillPrompt =>
      'Seleccione campo de contraseña para autollenado.';

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
  String get copiedToClipboard => 'Copiado al portapapeles.';

  @override
  String get noTitle => '(sin título)';

  @override
  String get noUsername => '(sin usuario)';

  @override
  String get filterCustomize => 'Personalizar …';

  @override
  String get swipeCopyPassword => 'Copiar contraseña';

  @override
  String get swipeCopyUsername => 'Copiar Usuario';

  @override
  String get copyUsernameNotExists => 'La entrada no tiene nombre de usuario.';

  @override
  String get copyPasswordNotExists => 'La entrada no tiene contraseña.';

  @override
  String get doneCopiedPassword => 'Contraseña copiada al portapapeles.';

  @override
  String get doneCopiedUsername => 'Usuario copiado al portapapeles.';

  @override
  String get doneCopiedField => 'Copiado.';

  @override
  String copiedFieldToClipboard(Object fieldName) {
    return '$fieldName copiado.';
  }

  @override
  String copiedFieldEmpty(Object fieldName) {
    return '$fieldName está vacío.';
  }

  @override
  String get emptyPasswordVaultPlaceholder =>
      'Aún no tienes ninguna contraseña en tu base de datos.';

  @override
  String get emptyPasswordVaultButtonLabel => 'Crea tu primera contraseña';

  @override
  String get loading => 'Cargando';

  @override
  String get loadingFile => 'Cargando archivo …';

  @override
  String get internalFile => 'Archivo interno';

  @override
  String get internalFileSubtitle =>
      'Base de datos previamente creada con OpenValut';

  @override
  String get filePicker => 'Selector de archivos';

  @override
  String get filePickerSubtitle => 'Abrir archivo desde el dispositivo.';

  @override
  String get credentialsAppBarTitle => 'Credenciales';

  @override
  String get credentialLabel => 'Introduzca la contraseña para:';

  @override
  String get masterPasswordInputLabel => 'Contraseña';

  @override
  String get masterPasswordEmptyValidator =>
      'Por favor, introduzca su contraseña.';

  @override
  String get masterPasswordIncorrectValidator => 'Contraseña inválida';

  @override
  String get useKeyFile => 'Usar archivo clave';

  @override
  String get saveMasterPasswordBiometric =>
      '¿Guardar contraseña con clave biométrica?';

  @override
  String get close => 'Cerrar';

  @override
  String get addNewPassword => 'Añadir nueva contraseña';

  @override
  String get errorOpenFileInvalidFileStructureTitle =>
      'Se intentó abrir un tipo de archivo inválido';

  @override
  String errorOpenFileInvalidFileStructureBody(Object fileName) {
    return 'El archivo ($fileName) parece no ser un archivo KDBX válido. Por favor, elija un archivo KDBX válido o cree una nueva base de datos para las contraseñas.';
  }

  @override
  String get errorOpenFileAlreadyOpenTitle => 'Archivo ya abierto';

  @override
  String errorOpenFileAlreadyOpenBody(
    Object databaseName,
    Object openFileSource,
    Object newFileSource,
  ) {
    return 'La base de datos seleccionada $databaseName ya está abierta desde $openFileSource (Se intentó abrir desde $newFileSource)';
  }

  @override
  String get loadFromUrl => 'Descargar desde URL';

  @override
  String get loadFromUrlEnterUrl => 'Introducir URL';

  @override
  String get loadFromUrlErrorEnterFullUrl =>
      'Por favor, introduzca una URL completa que comience con http:// o https://';

  @override
  String get loadFromUrlErrorInvalidUrl =>
      'Por favor, introduzca una url válida.';

  @override
  String get linuxAppArmorWarning =>
      'OpenValut requiere su permiso para comunicarse con el Servicio Secreto para almacenar las credenciales del almacenamiento en la nube.\n\nPor favor, ejecute el siguiente comando:';

  @override
  String get cancel => 'Cancelar';

  @override
  String get errorLoadFileFromSourceTitle => 'Error al abrir el archivo.';

  @override
  String errorLoadFileFromSourceBody(Object source, Object error) {
    return 'No se puede abrir $source.\n$error';
  }

  @override
  String get errorUnlockFileTitle => 'No se puede abrir el archivo';

  @override
  String errorUnlockFileBody(Object error) {
    return 'Error desconocido al intentar abrir el archivo. $error';
  }

  @override
  String get dialogContinue => 'Continuar';

  @override
  String get dialogSendErrorReport => 'Enviar Informe de Error';

  @override
  String get dialogReportErrorForum => 'Reportar error en el Foro/Ayuda';

  @override
  String get groupFilterDescription =>
      'Seleccione qué grupos mostrar (recursivamente)';

  @override
  String get groupFilterSelectAll => 'Seleccionar todo';

  @override
  String get groupFilterDeselectAll => 'Deseleccionar todo';

  @override
  String get createSubgroup => 'Crear subgrupo';

  @override
  String get editAction => 'Editar';

  @override
  String get mailboxEnableLabel => '(re)habilitar';

  @override
  String get mailboxEnableHint => 'Continuar recibiendo correos';

  @override
  String get mailboxDisableLabel => 'Deshabilitar';

  @override
  String get mailboxDisableHint => 'No recibir más correos';

  @override
  String get mailListNoMail => 'Aún no tienes ningún correo.';

  @override
  String mailboxLabelPrefixForEntry(Object entryLabel) {
    return 'Entrada: $entryLabel';
  }

  @override
  String mailboxLabelPrefixUnknownEntry(Object entryUuid) {
    return 'Entrada desconocida: $entryUuid';
  }

  @override
  String mailboxLabelPrefixCreatedAt(Object dateTime) {
    return 'Creado el: $dateTime';
  }

  @override
  String get masterPasswordDescription =>
      'La contraseña maestra se utiliza para cifrar de forma segura su base de datos. Asegúrese de recordarla, no puede ser restaurada.';

  @override
  String get unsavedChangesWarningTitle => 'Cambios sin guardar';

  @override
  String get unsavedChangesWarningBody =>
      'Todavía hay cambios sin guardar. ¿Desea descartar los cambios?';

  @override
  String get unsavedChangesDiscardActionLabel => 'Descartar cambios';

  @override
  String get deletePermanentlyAction => 'Eliminar Permanentemente';

  @override
  String get restoreFromRecycleBinAction => 'Restaurar';

  @override
  String get deleteAction => 'Eliminar';

  @override
  String get deletedEntry => 'Entrada eliminada.';

  @override
  String get successfullyDeletedGroup => 'Grupo eliminado.';

  @override
  String get undoButtonLabel => 'Deshacer';

  @override
  String get saveButtonLabel => 'Guardar';

  @override
  String get webDavSettings => 'Ajustes WebDAV';

  @override
  String get webDavUrlLabel => 'URL';

  @override
  String get webDavUrlHelperText => 'URL base para su servicio WebDAV.';

  @override
  String get webDavUrlValidatorError => 'Por favor, introduzca una URL';

  @override
  String get webDavUrlValidatorInvalidUrlError =>
      'Por favor, introduzca una URL válida con http:// o https://';

  @override
  String get webDavAuthUser => 'Usuario';

  @override
  String get webDavopenvalutword => 'Contraseña';

  @override
  String get mergeSuccessDialogTitle =>
      'Base de datos de contraseñas combinada con éxito';

  @override
  String mergeSuccessDialogMessage(Object fileName, Object mergeSummary) {
    return 'Conflicto detectado al guardar $fileName, se combinó con éxito con el archivo remoto: \n\n$mergeSummary';
  }

  @override
  String forDetailsVisitUrl(Object url) {
    return 'Para más información, visite $url';
  }

  @override
  String get openvalutCloudAuthEmailInputLabel =>
      'Introduzca una dirección de correo para registrarse o iniciar sesión.';

  @override
  String get openvalutCloudAuthEmailInvalid =>
      'Por favor, introduzca una dirección de correo válida.';

  @override
  String get openvalutCloudAuthConfirmEmailButtonLabel => 'Confirmar dirección';

  @override
  String get openvalutCloudAuthConfirmEmail =>
      'Por favor, compruebe su correo para confirmar la dirección.';

  @override
  String get openvalutCloudAuthConfirmEmailExplain =>
      'Mantenga esta pantalla abierta hasta que haya visitado el enlace recibido por correo.';

  @override
  String get openvalutCloudAuthResendExplain =>
      'Si no has recibido un correo electrónico, por favor revisa tu carpeta de spam. De lo contrario, puedes intentar solicitar un nuevo enlace de confirmación.';

  @override
  String get openvalutCloudAuthResendButtonLabel =>
      'Solicitar un nuevo enlace de confirmación';

  @override
  String permanentlyDeleteEntryConfirm(Object title) {
    return 'Esto eliminará permanentemente la entrada $title. Esto no se puede deshacer. ¿Desea continuar?';
  }

  @override
  String get permanentlyDeletedEntrySnackBar =>
      'Entrada eliminada permanentemente.';

  @override
  String get initialNewGroupName => 'Nuevo grupo';

  @override
  String get deleteGroupErrorTitle => 'No se puede eliminar el grupo';

  @override
  String get deleteGroupErrorBodyContainsGroup =>
      'Este grupo aún contiene otros grupos. Actualmente sólo puede eliminar grupos vacíos.';

  @override
  String get deleteGroupErrorBodyContainsEntries =>
      'Este grupo aún contiene entradas de contraseña. Actualmente sólo puede eliminar grupos vacíos.';

  @override
  String get groupListAppBarTitle => 'Grupos';

  @override
  String get groupListFilterAppbarTitle => 'Filtrar por grupos';

  @override
  String get clearQuickUnlock => 'Borrar almacenamiento biométrico';

  @override
  String get clearQuickUnlockSubtitle =>
      'Eliminar contraseñas maestras guardadas';

  @override
  String get unlock => 'Desbloquear archivos';

  @override
  String get closePasswordFiles => 'cerrar archivos de contraseñas';

  @override
  String get clearQuickUnlockSuccess =>
      'Eliminadas las contraseñas maestras guardadas del almacenamiento biométrico.';

  @override
  String get diacOptIn => 'Opte por las noticias en la aplicación, encuestas.';

  @override
  String get diacOptInSubtitle =>
      'Ocasionalmente enviará una solicitud de red para obtener noticias.';

  @override
  String browserAutofillThirdPartyModeTitle(String browserName) {
    return 'Enable AutoFill in $browserName';
  }

  @override
  String browserAutofillThirdPartyModeSubtitle(String browserName) {
    return '$browserName currently uses its own password manager. Tap to open its settings and select “Autofill using another service”, then restart $browserName.';
  }

  @override
  String get enableAutofillDebug => 'Autollenado: Habilitar depuración';

  @override
  String get enableAutofillDebugSubtitle =>
      'Muestra capas de información para cada campo de entrada';

  @override
  String get createPasswordDatabase => 'Crear base de datos de contraseñas';

  @override
  String get nameNewPasswordDatabase => 'Nombre de su nueva base de datos';

  @override
  String get validatorNameMissing =>
      'Por favor, introduzca un nombre para su nueva base de datos.';

  @override
  String get masterPasswordHelpText =>
      'Seleccione una contraseña maestra segura. Asegúrese de recordarla.';

  @override
  String get inputMasterPasswordText => 'Contraseña maestra';

  @override
  String get masterPasswordMissingCreate =>
      'Por favor, introduzca una contraseña segura y recordable.';

  @override
  String get createDatabaseAction => 'Crear base de datos';

  @override
  String get databaseExistsError => 'El archivo ya existe';

  @override
  String databaseExistsErrorDescription(Object filePath) {
    return 'Error al intentar crear la base de datos $filePath. El archivo ya existe. Por favor elija otro nombre.';
  }

  @override
  String get databaseCreateDefaultName => 'ContraseñasPersonales';

  @override
  String get preferenceDynamicLoadIcons => 'Cargar iconos dinámicamente';

  @override
  String preferenceDynamicLoadIconsSubtitle(Object urlFieldName) {
    return 'Hará solicitudes http con el valor en el campo $urlFieldName para cargar iconos del sitio web.';
  }

  @override
  String passwordScore(Object score) {
    return 'Fortaleza: $score de 4';
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
  String get entryInfoFile => 'Archivo:';

  @override
  String get entryInfoGroup => 'Grupo:';

  @override
  String get entryInfoLastModified => 'Última modificación:';

  @override
  String movedEntryToGroup(Object groupName) {
    return 'Entrada movida a $groupName';
  }

  @override
  String sizeBytesStoredopenvalutCloud(Object count) {
    return '$count bytes, almacenados en OpenValut Cloud';
  }

  @override
  String sizeBytes(Object count) {
    return '$count bytes';
  }

  @override
  String get entryAttachmentSizeWarning =>
      'Los archivos adjuntos serán incorporados en el archivo de contraseñas. Esto puede aumentar significativamente el tiempo necesario para abrir/guardar contraseñas.';

  @override
  String get iconPngSizeWarning =>
      'Los iconos personalizados se incorporarán en el archivo de contraseñas. Esto puede aumentar significativamente el tiempo necesario para abrir/guardar contraseñas.';

  @override
  String get notPngError => 'El archivo elegido no es PNG.';

  @override
  String get entryAddField => 'Añadir campo';

  @override
  String get entryCustomField => 'Campo personalizado';

  @override
  String get entryCustomFieldTitle => 'Añadir nuevo campo personalizado';

  @override
  String get entryCustomFieldInputLabel => 'Ingrese un nombre para el campo';

  @override
  String get swipeCopyField => 'Copiar campo';

  @override
  String get fieldRename => 'Renombrar';

  @override
  String get fieldGeneratePassword => 'Generar contraseña …';

  @override
  String get fieldProtect => 'Proteger Valor';

  @override
  String get fieldUnprotect => 'Desproteger Valor';

  @override
  String get fieldPresent => 'Presentar';

  @override
  String get fieldGenerateEmail => 'Generar Email';

  @override
  String get onboardingBackToOnboarding => 'Tour';

  @override
  String get onboardingBackToOnboardingSubtitle =>
      'Reviva la experiencia de la primera ejecución 😅';

  @override
  String get onboardingHeadline => '¡Hagamos que tus contraseñas sean seguras!';

  @override
  String get onboardingQuestion => '¿Ha usado un gestor de contraseñas antes?';

  @override
  String get onboardingYesOpenPasswords => 'Sí, abrir mis contraseñas';

  @override
  String get onboardingNoCreate => '¡Soy todo nuevo! Empecemos.';

  @override
  String get backupButton => 'GUARDAR EN LA NUBE';

  @override
  String get dismissBackupButton => 'DESCARTAR';

  @override
  String backupWarningMessage(Object databasename) {
    return '¡Tus contraseñas en $databasename solo se guardan localmente!';
  }

  @override
  String get saveAs => 'Guardar en...';

  @override
  String get saving => 'Guardando';

  @override
  String get increaseValue => 'Aumentar';

  @override
  String get decreaseValue => 'Reducir';

  @override
  String get resetValue => 'Reset';

  @override
  String cloudStorageAppBarTitle(Object cloudStorageName) {
    return 'Almacenamiento en la nube - $cloudStorageName';
  }

  @override
  String get cloudStorageLogInCaption =>
      'Será redirigido para autorizar a OpenValut para acceder a sus datos.';

  @override
  String get cloudStorageLogInCode => 'Introducir código';

  @override
  String launchUrlError(Object url) {
    return 'No se puede iniciar la URL. Por favor, visite $url';
  }

  @override
  String cloudStorageLogInActionLabel(Object cloudStorageName) {
    return 'Inicie sesión en $cloudStorageName';
  }

  @override
  String cloudStorageAuthCodeDialogTitle(Object cloudStorageName) {
    return 'Autenticación de $cloudStorageName';
  }

  @override
  String get cloudStorageAuthCodeLabel => 'Código de autenticación';

  @override
  String get cloudStorageAuthErrorTitle => 'Error al autenticar';

  @override
  String cloudStorageAuthErrorMessage(
    Object cloudStorageName,
    Object errorMessage,
  ) {
    return 'Error al intentar autenticar en $cloudStorageName: $errorMessage';
  }

  @override
  String get cloudStorageSearchBoxLabel => 'Búsqueda';

  @override
  String cloudStorageItemsInFolder(Object itemCount) {
    return '$itemCount elementos en esta carpeta.';
  }

  @override
  String get mailSubject => 'Asunto';

  @override
  String get mailFrom => 'De';

  @override
  String get mailDate => 'Fecha';

  @override
  String get mailMailbox => 'Buzón';

  @override
  String get mailNoData => 'Sin datos';

  @override
  String get mailMailboxesTitle => 'Buzones';

  @override
  String get mailboxCreateButtonLabel => 'Crear';

  @override
  String get mailboxNameInputDialogTitle =>
      'Etiqueta opcional para el nuevo buzón';

  @override
  String get mailboxNameInputLabel => '(Interno) Etiqueta';

  @override
  String get mailScreenTitle => 'Correo electrónico de OpenValut';

  @override
  String get mailTabBarTitleMailbox => 'Buzón';

  @override
  String get mailTabBarTitleMail => 'Correo';

  @override
  String get mailMailboxListEmpty => 'Todavía no tiene ningún buzón.';

  @override
  String mailMailboxAddressCopied(Object mailboxAddress) {
    return 'Dirección del buzón copiada al portapapeles: $mailboxAddress';
  }

  @override
  String get errorWhileSavingTitle => 'Error al guardar';

  @override
  String errorWhileSavingBody(Object errorMessage) {
    return 'No es posible guardar el archivo: $errorMessage';
  }

  @override
  String get databaseDoesNotSupportSaving =>
      'Lo sentimos, esta base de datos no se puede guardar. Por favor, abra una base de datos local o utilice \"Guardar como\".';

  @override
  String get otpInvalidKeyTitle => 'Clave inválida';

  @override
  String get otpInvalidKeyBody =>
      'La entrada no es un código TOTP base32 válido. Por favor, verifique lo introducido.';

  @override
  String get otpUnsupportedMigrationTitle => 'Unsupported OTP Migration';

  @override
  String otpUnsupportedMigrationBody(Object uriCount) {
    return 'We currently only support single item migrations. Got $uriCount';
  }

  @override
  String get otpPromptTitle => 'Autenticación basada en el tiempo';

  @override
  String get otpPromptHelperText =>
      'Por favor, introduzca la clave basada en el tiempo.';

  @override
  String otpErrorMessageGeneration(Object errorMessage) {
    return 'Error al generar el código de invitación: $errorMessage';
  }

  @override
  String get otpCopySecretActionLabel => 'Copiar Secreto';

  @override
  String get otpEntryLabel => 'Token de un solo uso';

  @override
  String get entryFieldProtected =>
      'Campo protegido. Haga clic para revelarlo.';

  @override
  String get entryFieldActionRevealField => 'Mostrar campo protegido';

  @override
  String get entryAttachmentOpenActionLabel => 'Abrir';

  @override
  String get entryAttachmentShareActionLabel => 'Compartir';

  @override
  String get entryAttachmentShareSubject => 'Archivo adjunto';

  @override
  String get entryAttachmentSaveActionLabel => 'Guardar en el dispositivo';

  @override
  String get entryAttachmentRemoveActionLabel => 'Eliminar';

  @override
  String entryAttachmentRemoveConfirm(Object attachmentLabel) {
    return '¿Está seguro de que desea eliminar $attachmentLabel?';
  }

  @override
  String get entryRenameFieldPromptTitle => 'Renombrar Campo';

  @override
  String get removerecentfile => 'Ocultar';

  @override
  String get entryRenameFieldPromptLabel =>
      'Introduzca el nuevo nombre para el campo';

  @override
  String get promptDialogPasteActionTooltip => 'Pegar desde el portapapeles';

  @override
  String get promptDialogPasteHint =>
      'Sugerencia: Si necesita pegar, pruebe el botón de la izquierda ;-)';

  @override
  String get genericErrorDialogTitle => 'Error al manejar la acción';

  @override
  String genericErrorDialogBody(Object errorMessage) {
    return 'Se encontró un error inesperado. $errorMessage';
  }

  @override
  String get saveAsEntryLocalFile => 'Archivo local';

  @override
  String get fileTypePngs => 'Imágenes (png)';

  @override
  String get selectIconDialogAction => 'SELECCIONAR ICON';

  @override
  String get retryDialogActionLabel => 'REINTENTAR';

  @override
  String errorDuringNetworkCall(Object errorMessage) {
    return 'Error durante la llamada a la API. $errorMessage';
  }

  @override
  String get passwordFilterHideDeleted => 'Ocultar entradas eliminadas';

  @override
  String get passwordFilterOnlyDeleted => 'Entradas eliminadas';

  @override
  String passwordFilterPrefixForOneGroup(Object groupName) {
    return 'Grupo: $groupName';
  }

  @override
  String passwordFilterPrefixForMultipleGroups(Object groupCount) {
    return 'Filtro personalizado ($groupCount grupos)';
  }

  @override
  String get menuItemopenvalutCloudAuthenticate =>
      'Autenticar con OpenValut Cloud';

  @override
  String get menuItemopenvalutCloudMailboxes => 'Buzones de OpenValut';

  @override
  String changesWithoutSaving(Object fileName) {
    return 'Has realizado cambios en \"$fileName\", que no soporta realizar cambios.';
  }

  @override
  String get changesSaveLocally => 'Guardar localmente';

  @override
  String get clearColor => 'Eliminar color';

  @override
  String get databaseRenameInputLabel =>
      'Introduce el nombre de la base de datos';

  @override
  String get databasePath => 'Ruta';

  @override
  String get databaseColor => 'Color';

  @override
  String get databaseColorChoose =>
      'Seleccione un color para distinguir entre archivos.';

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
  String get databaseKdbxVersion => 'Versión del archivo KDBX';

  @override
  String databaseKdbxUpgradeVersion(Object versionName) {
    return 'Actualizar a $versionName';
  }

  @override
  String get databaseKdbxUpgradeSuccessful =>
      'Archivo actualizado y guardado correctamente.';

  @override
  String get databaseReload => 'Recargar y fusionar';

  @override
  String progressStatus(Object statusProgress) {
    return 'Estado: $statusProgress';
  }

  @override
  String finishedMerge(Object status) {
    return 'Fusión finalizada $status';
  }

  @override
  String get closeAndLockFile => 'Cerrar/Bloquear';

  @override
  String get openvalutHomeScreenTagline =>
      'gestor de contraseñas, de código abierto, disponible en todas las plataformas.';

  @override
  String get addNewPasswordButtonLabel => 'Añadir nueva contraseña';

  @override
  String get unnamedEntryPlaceholder => '(Sin nombre)';

  @override
  String get unnamedGroupPlaceholder => '(Sin nombre)';

  @override
  String get unnamedFilePlaceholder => '(Sin nombre)';

  @override
  String get editGroupScreenTitle => 'Editar grupo';

  @override
  String get editGroupGroupNameLabel => 'Nombre del grupo';

  @override
  String get files => 'Archivos';

  @override
  String get newGroupDialogTitle => 'Nuevo grupo';

  @override
  String get newGroupDialogInputLabel => 'Nombre para el nuevo grupo';

  @override
  String get groupActionShowPasswords => 'Mostrar contraseñas';

  @override
  String get groupActionDelete => 'Eliminar';

  @override
  String get logoutTooltip => 'Cerrar sesión';

  @override
  String get successfullyDeletedFileCloudStorage =>
      'Archivo eliminado correctamente.';

  @override
  String shareDialogTitle(Object fileName) {
    return 'Opciones para compartir $fileName';
  }

  @override
  String get shareFileActionLabel => 'Compartir …';

  @override
  String get shareTokenListEmptyScreenPlaceholder =>
      'Archivo aún no compartido.';

  @override
  String get shareTokenNoLabel => 'Sin etiqueta/descripción';

  @override
  String get shareTokenReadWrite => 'Lectura/Escritura';

  @override
  String get shareTokenReadOnly => 'Sólo lectura';

  @override
  String get shareCreateTokenDialogTitle => 'Compartir archivo';

  @override
  String get shareCreateTokenReadOnly => 'Sólo lectura';

  @override
  String get shareCreateTokenReadOnlyHelpText => 'No permitir guardar cambios';

  @override
  String get shareCreateTokenLabelText => 'Descripción';

  @override
  String get shareCreateTokenLabelHint => 'Compartir a mi amigo';

  @override
  String get shareCreateTokenLabelHelp =>
      'Etiqueta opcional para diferenciar el código de compartir.';

  @override
  String get shareCreateTokenSuccess =>
      'Código para compartir creado con éxito.';

  @override
  String get sharePresentDialogTitle =>
      'Compartir archivo con código secreto compartido';

  @override
  String get sharePresentDialogHelp =>
      'Usando el siguiente código compartido los usuarios pueden acceder al archivo de contraseñas. Necesitarán la contraseña y/o el archivo de clave para abrirlo.';

  @override
  String get sharePresentToken => 'Código para compartir';

  @override
  String get sharePresentCopied =>
      'El código compartido se copió al portapapeles.';

  @override
  String get openvalutCloudOpenWithShareCodeTooltip =>
      'Abrir con Compartir Código';

  @override
  String get openvalutCloudShareFileActionLabel => 'Compartir';

  @override
  String get preferenceopenvalutCloudAttachmentTitle =>
      'Usar adjuntos en OpenValut Cloud';

  @override
  String get preferenceopenvalutCloudAttachmentSubtitle =>
      'Almacenar adjuntos encriptados en OpenValut Cloud por separado.';

  @override
  String get shareCodeInputDialogTitle =>
      'Introduzca el Código Secreto Compartido';

  @override
  String get shareCodeInputDialogScan => 'Escanear código QR';

  @override
  String get shareCodeInputLabel => 'Código Secreto Compartido';

  @override
  String get shareCodeInputHelperText =>
      'Si ha recibido un código para compartir, por favor pégalo arriba.';

  @override
  String get shareCodeOpen =>
      '¿Recibió un Código Compartido para OpenValut Cloud?';

  @override
  String get shareCodeOpenScreenTitle =>
      'Cargando archivo con código compartido';

  @override
  String get shareCodeLoadingProgress => 'Cargando archivo …';

  @override
  String get shareCodeOpenFileButtonLabel => 'ABRIR';

  @override
  String get shareCodeOpenInstallAppCaption =>
      '¿Desea abrir este archivo con una de nuestras aplicaciones nativas?';

  @override
  String get shareCodeOpenAnotherAppCaption =>
      '¿Desea abrir este archivo en otro dispositivo?';

  @override
  String get shareCodeOpenInstallAppButtonLabel => 'Instalar Aplicación';

  @override
  String get shareCodeOpenShowCodeButtonLabel => 'Mostrar código compartido';

  @override
  String get changeMasterPasswordActionLabel => 'Cambiar contraseña maestra';

  @override
  String get changeMasterPasswordFormSubmit => 'Guardar con nueva contraseña';

  @override
  String get changeMasterPasswordSuccess =>
      'Contraseña maestra guardada correctamente.';

  @override
  String get changeMasterPasswordScreenTitle => 'Cambiar contraseña maestra';

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
      'Recibí correo electrónico y he visitado el enlace';

  @override
  String get openvalutCloudAuthNotConfirmed =>
      'La dirección de correo electrónico aún no ha sido confirmada. Asegúrate de hacer clic en el enlace del correo electrónico que recibiste y resolver el captcha para confirmar tu dirección de correo electrónico.';

  @override
  String get getHelpButton => 'Obtener ayuda en el foro';

  @override
  String get shortcutCopyUsername => 'Copiar Usuario';

  @override
  String get shortcutCopyPassword => 'Copiar contraseña';

  @override
  String get shortcutCopyTotp => 'Copiar TOTP';

  @override
  String get shortcutMoveUp => 'Seleccione la contraseña anterior';

  @override
  String get shortcutMoveDown => 'Seleccione la siguiente contraseña';

  @override
  String get shortcutGeneratePassword => 'Generar contraseña';

  @override
  String get shortcutCopyUrl => 'Copiar URL';

  @override
  String get shortcutOpenUrl => 'Abrir URL';

  @override
  String get shortcutCancelSearch => 'Cancelar búsqueda';

  @override
  String get shortcutShortcutHelp => 'Ayuda de atajo de teclado';

  @override
  String get shortcutHelpTitle => 'Atajos de teclado';

  @override
  String unexpectedError(String error) {
    return 'Error inesperado: $error';
  }

  @override
  String get googleDriveMorePermissionsRequired =>
      'Additional permissions needed to access Google Drive.';

  @override
  String get googleDriveRequestPermissionButtonLabel => 'Request Permissions';

  @override
  String get scanQrCodeTitle => 'Scan QR Code.';
}
