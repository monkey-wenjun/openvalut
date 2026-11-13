// ignore_for_file: omit_local_variable_types,unused_local_variable

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

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
  String get entryAddAttachment => 'Bijlage toevoegen';

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
  String get fieldUserName => 'Gebruiker';

  @override
  String get fieldPassword => 'Wachtwoord';

  @override
  String get fieldWebsite => 'Website';

  @override
  String get fieldTitle => 'Titel';

  @override
  String get fieldTotp => 'Eenmalig wachtwoord (Tijd gebaseerd)';

  @override
  String get english => 'Engels';

  @override
  String get german => 'Duits';

  @override
  String get russian => 'Russisch';

  @override
  String get ukrainian => 'Oekraïens';

  @override
  String get lithuanian => 'Litouws';

  @override
  String get french => 'Frans';

  @override
  String get spanish => 'Spaans';

  @override
  String get indonesian => 'Indonesisch';

  @override
  String get turkish => 'Turks';

  @override
  String get hebrew => 'Hebreeuws';

  @override
  String get italian => 'Italiaans';

  @override
  String get chineseSimplified => 'Chinees, vereenvoudigd';

  @override
  String get chineseTraditional => 'Chinees, traditioneel';

  @override
  String get portugueseBrazilian => 'Portugees, Braziliaans';

  @override
  String get slovak => 'Slowaaks';

  @override
  String get dutch => 'Nederlands';

  @override
  String get selectItem => 'Selecteer';

  @override
  String get selectKeepassFile => 'OpenValut - Selecteer KeePass Bestand';

  @override
  String get selectKeepassFileLabel => 'Selecteer een KeePass (.kdbx) bestand.';

  @override
  String get createNewFile => 'Maak nieuw bestand';

  @override
  String get openLocalFile => 'Open\nlokaal bestand';

  @override
  String get openFile => 'Open bestand';

  @override
  String get loadFromDropdownMenu => 'Laden uit …';

  @override
  String get quickUnlockingFiles => 'Bestanden snel ontgrendelen …';

  @override
  String openFileProgress(Object fileName, Object current, Object totalCount) {
    return 'Openen $fileName … ($current / $totalCount)';
  }

  @override
  String loadFrom(String cloudStorageName) {
    return 'Laad van $cloudStorageName';
  }

  @override
  String get loadFromRemoteUrl => 'Open kdbx vanaf URL';

  @override
  String get createNewKeepass =>
      'Nieuw bij KeePass?\nNieuw wachtwoord database aanmaken';

  @override
  String get labelLastOpenFiles => 'Laatste geopende bestanden:';

  @override
  String get noFilesHaveBeenOpenYet => 'Nog geen bestanden geopend.';

  @override
  String get preferenceSelectLanguage => 'Selecteer Taal';

  @override
  String get preferenceLanguage => 'Taal';

  @override
  String get preferenceTextScaleFactor => 'Tekst schaalfactor';

  @override
  String get preferenceVisualDensity => 'Visuele dichtheid';

  @override
  String get preferenceTheme => 'Thema';

  @override
  String get preferenceThemeLight => 'Licht';

  @override
  String get preferenceThemeDark => 'Donker';

  @override
  String get preferenceSystemDefault => 'Systeem standaard';

  @override
  String get preferenceDefault => 'Standaard';

  @override
  String get lockAllFiles => 'Vergrendel alle geopende bestanden';

  @override
  String get preferenceAllowScreenshots =>
      'Schermafbeeldingen in de App toestaan';

  @override
  String get preferenceEnableAutoFill => 'Automatisch aanvullen inschakelen';

  @override
  String get enableAutofillSuggestionBanner =>
      'Je kunt het velden invullen van andere programma\'s aanzetten door automatisch aanvullen in te schakelen!';

  @override
  String get dismissAutofillSuggestionBannerButton => 'AFWIJZEN';

  @override
  String get enableAutofillSuggestionBannerButton => 'INSCHAKELEN!';

  @override
  String get preferenceAutoFillDescription =>
      'Alleen ondersteund op Android Oreo (8.0) of later.';

  @override
  String get preferenceTitle => 'Voorkeuren';

  @override
  String get preferenceEnableSystemWideShortcuts =>
      'Activeer systeem brede snelkoppelingen';

  @override
  String get preferenceEnableSystemWideShortcutsHelp =>
      'Registreert ctrl + alt+f als systeem brede snelkoppeling om te zoeken.';

  @override
  String get preferencesSearchFields => 'Zoekvelden aanpassen';

  @override
  String get preferencesSearchFieldPromptTitle => 'Zoekvelden';

  @override
  String get preferencesSearchFieldPromptLabel =>
      'Komma\'s gescheiden lijst van velden om te gebruiken bij het zoeken in wachtwoordlijsten.';

  @override
  String preferencesSearchFieldPromptHelp(
    Object wildCardCharacter,
    Object defaultSearchFields,
  ) {
    return 'Gebruik $wildCardCharacter voor iedereen, laat leeg voor standaard ($defaultSearchFields)';
  }

  @override
  String get aboutAppName => 'OpenValut';

  @override
  String get aboutLinkFeedback => 'Wij verwelkomen elke vorm van feedback!';

  @override
  String get aboutLinkVisitWebsite => 'Kijk ook op onze website';

  @override
  String get aboutLinkGitHub => 'En Open Source Project';

  @override
  String aboutLogFile(String logFilePath) {
    return 'Logbestand: $logFilePath';
  }

  @override
  String get aboutLinkContributors => 'Toon bijdragers';

  @override
  String get unableToLaunchUrlTitle => 'Kan URL niet openen';

  @override
  String unableToLaunchUrlDescription(Object url, Object openError) {
    return 'Kan $url niet open: $openError';
  }

  @override
  String get unableToLaunchUrlNoHandler =>
      'Geen toepassing beschikbaar voor URL.';

  @override
  String launchedUrl(Object url) {
    return 'Geopende URL: $url';
  }

  @override
  String get menuItemGeneratePassword => 'Wachtwoord genereren';

  @override
  String get menuItemPreferences => 'Voorkeuren';

  @override
  String get menuItemOpenAnotherFile => 'Open een ander bestand';

  @override
  String get menuItemCheckForUpdates => 'Controleer op updates';

  @override
  String get menuItemSupport => 'Verstuur logs';

  @override
  String get menuItemSupportSubtitle => 'Verstuur logs via e-mail';

  @override
  String get menuItemForum => 'Ondersteuningsforum';

  @override
  String get menuItemForumSubtitle => 'Rapporteer problemen en hulp vragen';

  @override
  String get menuItemHelp => 'Help';

  @override
  String get menuItemHelpSubtitle => 'Documentatie weergeven';

  @override
  String get menuItemAbout => 'Over';

  @override
  String get actionOpenUrl => 'Open URL';

  @override
  String get passwordPlainText => 'Wachtwoord tonen';

  @override
  String get generatorPassword => 'Wachtwoord';

  @override
  String get generatePassword => 'Wachtwoord genereren';

  @override
  String get doneButtonLabel => 'Voltooid';

  @override
  String get useAsDefault => 'Gebruik als standaard';

  @override
  String get characterSetLowerCase => 'Kleine letters (a-z)';

  @override
  String get characterSetUpperCase => 'Hoofdletters (A-Z)';

  @override
  String get characterSetNumeric => 'Numeriek (0-9)';

  @override
  String get characterSetUmlauts => 'Umlauts (ä)';

  @override
  String get characterSetSpecial => 'Speciaal (@%+)';

  @override
  String get length => 'Lengte';

  @override
  String get customLength => 'Aangepaste lengte';

  @override
  String customLengthHelperText(Object customMinLength) {
    return 'Alleen gebruikt voor lengte > $customMinLength';
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
      other: '$numFilesString bestanden opgeslagen: $files',
      one: 'Eén bestand opgeslagen: $files',
    );
    return '$_temp0';
  }

  @override
  String get manageGroups => 'Groepen beheren';

  @override
  String get lockFiles => 'Bestanden vergrendelen';

  @override
  String get searchHint => 'Zoeken';

  @override
  String get searchButtonLabel => 'Zoeken';

  @override
  String get filterButtonLabel => 'Filteren op groepen';

  @override
  String get clear => 'Leegmaken';

  @override
  String get autofillFilterPrefix => 'Filter:';

  @override
  String get autofillMatchPrefix => 'Matching entries for:';

  @override
  String get autofillPrompt =>
      'Selecteer wachtwoord invoer voor Automatisch aanvullen.';

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
  String get copiedToClipboard => 'Gekopieerd naar klembord.';

  @override
  String get noTitle => '(geen titel)';

  @override
  String get noUsername => '(geen gebruikersnaam)';

  @override
  String get filterCustomize => 'Aanpassen …';

  @override
  String get swipeCopyPassword => 'Wachtwoord kopiëren';

  @override
  String get swipeCopyUsername => 'Gebruikersnaam kopiëren';

  @override
  String get copyUsernameNotExists =>
      'Item heeft geen gebruikersnaam ingesteld.';

  @override
  String get copyPasswordNotExists =>
      'Item heeft geen wachtwoord gedefinieerd.';

  @override
  String get doneCopiedPassword => 'Wachtwoord gekopieerd naar klembord.';

  @override
  String get doneCopiedUsername => 'Gebruikersnaam gekopieerd naar klembord.';

  @override
  String get doneCopiedField => 'Gekopieerd.';

  @override
  String copiedFieldToClipboard(Object fieldName) {
    return '$fieldName gekopieerd.';
  }

  @override
  String copiedFieldEmpty(Object fieldName) {
    return '$fieldName is leeg.';
  }

  @override
  String get emptyPasswordVaultPlaceholder =>
      'Je hebt nog geen wachtwoord in je database.';

  @override
  String get emptyPasswordVaultButtonLabel => 'Maak je eerste wachtwoord aan';

  @override
  String get loading => 'Laden';

  @override
  String get loadingFile => 'Bestand laden …';

  @override
  String get internalFile => 'Intern bestand';

  @override
  String get internalFileSubtitle => 'Database eerder aangemaakt met OpenValut';

  @override
  String get filePicker => 'Bestandskiezer';

  @override
  String get filePickerSubtitle => 'Open bestand op het apparaat.';

  @override
  String get credentialsAppBarTitle => 'Aanmeldgegevens';

  @override
  String get credentialLabel => 'Vul het wachtwoord in voor:';

  @override
  String get masterPasswordInputLabel => 'Wachtwoord';

  @override
  String get masterPasswordEmptyValidator => 'Voer je wachtwoord in.';

  @override
  String get masterPasswordIncorrectValidator => 'Ongeldig wachtwoord';

  @override
  String get useKeyFile => 'Gebruik sleutelbestand';

  @override
  String get saveMasterPasswordBiometric =>
      'Wachtwoord opslaan met biometrische sleutelopslag?';

  @override
  String get close => 'Sluiten';

  @override
  String get addNewPassword => 'Voeg nieuw wachtwoord toe';

  @override
  String get errorOpenFileInvalidFileStructureTitle =>
      'Geprobeerd om een ongeldig bestandstype te openen';

  @override
  String errorOpenFileInvalidFileStructureBody(Object fileName) {
    return 'Het bestand ($fileName) lijkt geen geldig KDBX bestand te zijn. Selecteer een geldig KDBX-bestand of maak een nieuwe wachtwoorddatabase.';
  }

  @override
  String get errorOpenFileAlreadyOpenTitle => 'Bestand al geopend';

  @override
  String errorOpenFileAlreadyOpenBody(
    Object databaseName,
    Object openFileSource,
    Object newFileSource,
  ) {
    return 'De geselecteerde database $databaseName is al geopend vanuit $openFileSource (Geprobeerd om te openen vanuit $newFileSource)';
  }

  @override
  String get loadFromUrl => 'Download vanaf URL';

  @override
  String get loadFromUrlEnterUrl => 'Voer URL in';

  @override
  String get loadFromUrlErrorEnterFullUrl =>
      'Voer de volledige URL in die begint met http:// of https://';

  @override
  String get loadFromUrlErrorInvalidUrl => 'Voer een geldige URL in.';

  @override
  String get linuxAppArmorWarning =>
      'OpenValut vereist toestemming om te communiceren met de Secrets Service om referenties op te slaan voor cloud opslag.\nVoer het volgende commando uit:';

  @override
  String get cancel => 'Annuleer';

  @override
  String get errorLoadFileFromSourceTitle => 'Fout bij het openen van bestand.';

  @override
  String errorLoadFileFromSourceBody(Object source, Object error) {
    return 'Niet mogelijk om $source te openen.\n$error';
  }

  @override
  String get errorUnlockFileTitle => 'Kan bestand niet openen';

  @override
  String errorUnlockFileBody(Object error) {
    return 'Onbekende fout bij het openen van bestand. $error';
  }

  @override
  String get dialogContinue => 'Doorgaan';

  @override
  String get dialogSendErrorReport => 'Foutrapport versturen';

  @override
  String get dialogReportErrorForum => 'Rapporteer fout in Forum/Hulp';

  @override
  String get groupFilterDescription =>
      'Selecteer de groepen om te tonen (recursief)';

  @override
  String get groupFilterSelectAll => 'Alles selecteren';

  @override
  String get groupFilterDeselectAll => 'Alles deselecteren';

  @override
  String get createSubgroup => 'Subgroep aanmaken';

  @override
  String get editAction => 'Bewerken';

  @override
  String get mailboxEnableLabel => '(opnieuw) inschakelen';

  @override
  String get mailboxEnableHint => 'Doorgaan met ontvangen e-mails';

  @override
  String get mailboxDisableLabel => 'Uitschakelen';

  @override
  String get mailboxDisableHint => 'Ontvang geen e-mails meer';

  @override
  String get mailListNoMail => 'U heeft nog geen e-mails.';

  @override
  String mailboxLabelPrefixForEntry(Object entryLabel) {
    return 'Entry: $entryLabel';
  }

  @override
  String mailboxLabelPrefixUnknownEntry(Object entryUuid) {
    return 'Onbekende invoer: $entryUuid';
  }

  @override
  String mailboxLabelPrefixCreatedAt(Object dateTime) {
    return 'Aangemaakt op: $dateTime';
  }

  @override
  String get masterPasswordDescription =>
      'Het hoofdwachtwoord gebruik je om je wachtwoorddatabase veilig te versleutelen. Zorg ervoor dat u het onthoudt. Het wachtwoord kan niet hersteld worden.';

  @override
  String get unsavedChangesWarningTitle => 'Niet-opgeslagen wijzigingen';

  @override
  String get unsavedChangesWarningBody =>
      'Er zijn nog steeds niet-opgeslagen wijzigingen. Wilt u de wijzigingen weggooien?';

  @override
  String get unsavedChangesDiscardActionLabel => 'Wijzigingen weggooien';

  @override
  String get deletePermanentlyAction => 'Permanent verwijderen';

  @override
  String get restoreFromRecycleBinAction => 'Herstellen';

  @override
  String get deleteAction => 'Verwijderen';

  @override
  String get deletedEntry => 'Verwijderde invoer.';

  @override
  String get successfullyDeletedGroup => 'Verwijderde groep.';

  @override
  String get undoButtonLabel => 'Herstel';

  @override
  String get saveButtonLabel => 'Opslaan';

  @override
  String get webDavSettings => 'WebDAV instellingen';

  @override
  String get webDavUrlLabel => 'URL';

  @override
  String get webDavUrlHelperText => 'Basis URL voor je WebDAV service.';

  @override
  String get webDavUrlValidatorError => 'Voer een URL in';

  @override
  String get webDavUrlValidatorInvalidUrlError =>
      'Voer een geldige URL in met http:// of https://';

  @override
  String get webDavAuthUser => 'Gebruikersnaam';

  @override
  String get webDavopenvalutword => 'Wachtwoord';

  @override
  String get mergeSuccessDialogTitle =>
      'Wachtwoorddatabase succesvol samengevoegd';

  @override
  String mergeSuccessDialogMessage(Object fileName, Object mergeSummary) {
    return 'Conflict gedetecteerd bij het opslaan van $fileName, het is succesvol samengevoegd met het externe bestand: \n\n$mergeSummary';
  }

  @override
  String forDetailsVisitUrl(Object url) {
    return 'Voor details bezoek $url';
  }

  @override
  String get openvalutCloudAuthEmailInputLabel =>
      'Voer e-mailadres in om te registreren of in te loggen.';

  @override
  String get openvalutCloudAuthEmailInvalid => 'Vul een geldig e-mailadres in.';

  @override
  String get openvalutCloudAuthConfirmEmailButtonLabel => 'Bevestig Adres';

  @override
  String get openvalutCloudAuthConfirmEmail =>
      'Controleer uw e-mails om uw e-mailadres te bevestigen.';

  @override
  String get openvalutCloudAuthConfirmEmailExplain =>
      'Houd dit scherm open totdat u de link heeft bezocht die u per e-mail heeft ontvangen.';

  @override
  String get openvalutCloudAuthResendExplain =>
      'Als je nog geen e-mail hebt ontvangen, controleer dan je spam folder. Anders kun je proberen een nieuwe bevestigingslink aan te vragen.';

  @override
  String get openvalutCloudAuthResendButtonLabel =>
      'Vraag een nieuwe bevestigingslink aan';

  @override
  String permanentlyDeleteEntryConfirm(Object title) {
    return 'Dit zal het wachtwoord permanent verwijderen $title. Dit kan niet ongedaan gemaakt worden. Wilt u doorgaan?';
  }

  @override
  String get permanentlyDeletedEntrySnackBar => 'Item permanent verwijderd.';

  @override
  String get initialNewGroupName => 'Nieuwe groep';

  @override
  String get deleteGroupErrorTitle => 'Kan groep niet verwijderen';

  @override
  String get deleteGroupErrorBodyContainsGroup =>
      'Deze groep bevat nog andere groepen. Je kunt op dit moment alleen lege groepen verwijderen.';

  @override
  String get deleteGroupErrorBodyContainsEntries =>
      'Deze groep bevat nog steeds wachtwoordvermeldingen. Je kunt op dit moment alleen lege groepen verwijderen.';

  @override
  String get groupListAppBarTitle => 'Groepen';

  @override
  String get groupListFilterAppbarTitle => 'Filteren op groepen';

  @override
  String get clearQuickUnlock => 'Biometrische opslag wissen';

  @override
  String get clearQuickUnlockSubtitle =>
      'Verwijder opgeslagen hoofdwachtwoorden';

  @override
  String get unlock => 'Bestanden ontgrendelen';

  @override
  String get closePasswordFiles => 'sluit wachtwoordbestanden';

  @override
  String get clearQuickUnlockSuccess =>
      'Hoofdwachtwoorden verwijderd uit biometrische opslag.';

  @override
  String get diacOptIn => 'Meld je aan voor In-App Nieuws, Enquêtes.';

  @override
  String get diacOptInSubtitle =>
      'Zal af en toe een netwerkverzoek verzenden om nieuws op te halen.';

  @override
  String browserAutofillThirdPartyModeTitle(String browserName) {
    return 'Enable AutoFill in $browserName';
  }

  @override
  String browserAutofillThirdPartyModeSubtitle(String browserName) {
    return '$browserName currently uses its own password manager. Tap to open its settings and select “Autofill using another service”, then restart $browserName.';
  }

  @override
  String get enableAutofillDebug => 'Automatisch aanvullen: Debug inschakelen';

  @override
  String get enableAutofillDebugSubtitle =>
      'Toont informatie overlays voor elk invoerveld';

  @override
  String get createPasswordDatabase => 'Maak wachtwoord database';

  @override
  String get nameNewPasswordDatabase => 'Naam van je nieuwe database';

  @override
  String get validatorNameMissing =>
      'Voer een naam in voor de nieuwe database.';

  @override
  String get masterPasswordHelpText =>
      'Selecteer een veilig hoofdwachtwoord. Zorg ervoor dat je het onthoudt.';

  @override
  String get inputMasterPasswordText => 'Hoofdwachtwoord';

  @override
  String get masterPasswordMissingCreate =>
      'Voer een veilig, te onthouden wachtwoord in.';

  @override
  String get createDatabaseAction => 'Maak Database';

  @override
  String get databaseExistsError => 'Bestand bestaat';

  @override
  String databaseExistsErrorDescription(Object filePath) {
    return 'Fout bij het maken van database $filePath. Bestand bestaat al. Kies een andere naam.';
  }

  @override
  String get databaseCreateDefaultName => 'PersoonlijkeWachtwoorden';

  @override
  String get preferenceDynamicLoadIcons => 'Pictogrammen dynamisch laden';

  @override
  String preferenceDynamicLoadIconsSubtitle(Object urlFieldName) {
    return 'Zal http verzoeken indienen met de waarde in het $urlFieldName veld om de website-iconen te laden.';
  }

  @override
  String passwordScore(Object score) {
    return 'Sterkte: $score van 4';
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
  String get entryInfoFile => 'Bestand:';

  @override
  String get entryInfoGroup => 'Groep:';

  @override
  String get entryInfoLastModified => 'Laatst gewijzigd:';

  @override
  String movedEntryToGroup(Object groupName) {
    return 'Invoer verplaatst naar $groupName';
  }

  @override
  String sizeBytesStoredopenvalutCloud(Object count) {
    return '$count bytes, opgeslagen in OpenValut Cloud';
  }

  @override
  String sizeBytes(Object count) {
    return '$count bytes';
  }

  @override
  String get entryAttachmentSizeWarning =>
      'Bijgevoegde bestanden worden toegevoegd in het wachtwoordbestand. Dit kan de tijd die nodig is om wachtwoorden te openen/opslaan, aanzienlijk verhogen.';

  @override
  String get iconPngSizeWarning =>
      'Aangepaste pictogrammen worden toegevoegd het wachtwoordbestand. Dit kan de tijd die nodig is voor het openen/opslaan van wachtwoorden aanzienlijk verhogen.';

  @override
  String get notPngError => 'Het gekozen bestand is geen PNG.';

  @override
  String get entryAddField => 'Veld toevoegen';

  @override
  String get entryCustomField => 'Aangepast veld';

  @override
  String get entryCustomFieldTitle => 'Toevoegen van nieuw aangepast veld';

  @override
  String get entryCustomFieldInputLabel => 'Voer een naam in voor het veld';

  @override
  String get swipeCopyField => 'Veld kopiëren';

  @override
  String get fieldRename => 'Hernoem';

  @override
  String get fieldGeneratePassword => 'Wachtwoord genereren …';

  @override
  String get fieldProtect => 'Bescherm waarde';

  @override
  String get fieldUnprotect => 'Waarde niet beschermen';

  @override
  String get fieldPresent => 'Tonen';

  @override
  String get fieldGenerateEmail => 'Genereer E-mail';

  @override
  String get onboardingBackToOnboarding => 'Rondleiding';

  @override
  String get onboardingBackToOnboardingSubtitle =>
      'Herhaal de eerste keer tour 😅';

  @override
  String get onboardingHeadline => 'Laten we je wachtwoorden veilig maken!';

  @override
  String get onboardingQuestion =>
      'Heb je al eerder een wachtwoordmanager gebruikt?';

  @override
  String get onboardingYesOpenPasswords => 'Ja, open mijn wachtwoorden';

  @override
  String get onboardingNoCreate => 'Ik ben allemaal nieuw! Help me op gang.';

  @override
  String get backupButton => 'OPSLAAN NAAR CLOUD';

  @override
  String get dismissBackupButton => 'AFWIJZEN';

  @override
  String backupWarningMessage(Object databasename) {
    return 'Je wachtwoorden in $databasename worden alleen lokaal opgeslagen!';
  }

  @override
  String get saveAs => 'Opslaan in...';

  @override
  String get saving => 'Opslaan';

  @override
  String get increaseValue => 'Toename';

  @override
  String get decreaseValue => 'Verminderen';

  @override
  String get resetValue => 'Reset';

  @override
  String cloudStorageAppBarTitle(Object cloudStorageName) {
    return 'Cloudopslag - $cloudStorageName';
  }

  @override
  String get cloudStorageLogInCaption =>
      'U wordt omgeleid naar OpenValut authenticeren om toegang te krijgen tot uw gegevens.';

  @override
  String get cloudStorageLogInCode => 'Voer code in';

  @override
  String launchUrlError(Object url) {
    return 'Kan URL niet starten. Bezoek $url';
  }

  @override
  String cloudStorageLogInActionLabel(Object cloudStorageName) {
    return 'Inloggen op $cloudStorageName';
  }

  @override
  String cloudStorageAuthCodeDialogTitle(Object cloudStorageName) {
    return '$cloudStorageName authenticatie';
  }

  @override
  String get cloudStorageAuthCodeLabel => 'Authenticatie code';

  @override
  String get cloudStorageAuthErrorTitle => 'Fout tijdens authenticatie';

  @override
  String cloudStorageAuthErrorMessage(
    Object cloudStorageName,
    Object errorMessage,
  ) {
    return 'Fout bij het authenticeren van $cloudStorageName: $errorMessage';
  }

  @override
  String get cloudStorageSearchBoxLabel => 'Zoekopdracht';

  @override
  String cloudStorageItemsInFolder(Object itemCount) {
    return '$itemCount items in deze map.';
  }

  @override
  String get mailSubject => 'Onderwerp';

  @override
  String get mailFrom => 'Van';

  @override
  String get mailDate => 'Datum';

  @override
  String get mailMailbox => 'Postvak';

  @override
  String get mailNoData => 'Geen gegevens';

  @override
  String get mailMailboxesTitle => 'Postvakken';

  @override
  String get mailboxCreateButtonLabel => 'Maken';

  @override
  String get mailboxNameInputDialogTitle =>
      'Optioneel labelen voor nieuw postvak';

  @override
  String get mailboxNameInputLabel => '(intern) label';

  @override
  String get mailScreenTitle => 'OpenValut mail';

  @override
  String get mailTabBarTitleMailbox => 'Postvak';

  @override
  String get mailTabBarTitleMail => 'E-mail';

  @override
  String get mailMailboxListEmpty => 'Je hebt nog geen postvakken.';

  @override
  String mailMailboxAddressCopied(Object mailboxAddress) {
    return 'Postvak adres gekopieerd naar het klembord: $mailboxAddress';
  }

  @override
  String get errorWhileSavingTitle => 'Fout bij opslaan';

  @override
  String errorWhileSavingBody(Object errorMessage) {
    return 'Kan bestand niet opslaan: $errorMessage';
  }

  @override
  String get databaseDoesNotSupportSaving =>
      'Sorry, deze database ondersteunt geen opslaan. Open een lokaal databasebestand. Of gebruik \"Opslaan als\".';

  @override
  String get otpInvalidKeyTitle => 'Ongeldige sleutel';

  @override
  String get otpInvalidKeyBody =>
      'De gegeven invoer is geen geldige base32 TOTP-code. Controleer je invoer.';

  @override
  String get otpUnsupportedMigrationTitle => 'Unsupported OTP Migration';

  @override
  String otpUnsupportedMigrationBody(Object uriCount) {
    return 'We currently only support single item migrations. Got $uriCount';
  }

  @override
  String get otpPromptTitle => 'Authenticatie op basis van tijd';

  @override
  String get otpPromptHelperText => 'Voer de op tijd gebaseerde sleutel in.';

  @override
  String otpErrorMessageGeneration(Object errorMessage) {
    return 'Fout bij genereren uitnodigingscode: $errorMessage';
  }

  @override
  String get otpCopySecretActionLabel => 'Kopieer Secret';

  @override
  String get otpEntryLabel => 'Eenmalige token';

  @override
  String get entryFieldProtected => 'Beschermd veld. Klik om te tonen.';

  @override
  String get entryFieldActionRevealField => 'Toon beschermd veld';

  @override
  String get entryAttachmentOpenActionLabel => 'Open';

  @override
  String get entryAttachmentShareActionLabel => 'Delen';

  @override
  String get entryAttachmentShareSubject => 'Bijlage';

  @override
  String get entryAttachmentSaveActionLabel => 'Opslaan op apparaat';

  @override
  String get entryAttachmentRemoveActionLabel => 'Verwijderen';

  @override
  String entryAttachmentRemoveConfirm(Object attachmentLabel) {
    return 'Weet je zeker dat je $attachmentLabel wilt verwijderen?';
  }

  @override
  String get entryRenameFieldPromptTitle => 'Veld hernoemen';

  @override
  String get removerecentfile => 'Verbergen';

  @override
  String get entryRenameFieldPromptLabel =>
      'Voer de nieuwe naam voor het veld in';

  @override
  String get promptDialogPasteActionTooltip => 'Plakken vanaf klembord';

  @override
  String get promptDialogPasteHint =>
      'Tip: Als je wilt plakken, probeer dan de knop links ;-)';

  @override
  String get genericErrorDialogTitle => 'Fout bij het afhandelen actie';

  @override
  String genericErrorDialogBody(Object errorMessage) {
    return 'Onverwachte fout opgetreden. $errorMessage';
  }

  @override
  String get saveAsEntryLocalFile => 'Lokaal bestand';

  @override
  String get fileTypePngs => 'Afbeeldingen (png)';

  @override
  String get selectIconDialogAction => 'SELECTEER ICON';

  @override
  String get retryDialogActionLabel => 'OPNIEUW';

  @override
  String errorDuringNetworkCall(Object errorMessage) {
    return 'Fout tijdens Api oproep. $errorMessage';
  }

  @override
  String get passwordFilterHideDeleted => 'Verwijderde items verbergen';

  @override
  String get passwordFilterOnlyDeleted => 'Verwijderde items';

  @override
  String passwordFilterPrefixForOneGroup(Object groupName) {
    return 'Groep: $groupName';
  }

  @override
  String passwordFilterPrefixForMultipleGroups(Object groupCount) {
    return 'Aangepast filter ($groupCount groepen)';
  }

  @override
  String get menuItemopenvalutCloudAuthenticate =>
      'Authenticeer met OpenValut Cloud';

  @override
  String get menuItemopenvalutCloudMailboxes => 'Authass postbussen';

  @override
  String changesWithoutSaving(Object fileName) {
    return 'Je hebt wijzigingen in \"$fileName\", die geen ondersteuning heeft voor het schrijven van wijzigingen.';
  }

  @override
  String get changesSaveLocally => 'Bewaar lokaal';

  @override
  String get clearColor => 'Kleur verwijderen';

  @override
  String get databaseRenameInputLabel => 'Voer databasenaam in';

  @override
  String get databasePath => 'Pad';

  @override
  String get databaseColor => 'Kleur';

  @override
  String get databaseColorChoose =>
      'Selecteer een kleur om onderscheid te maken tussen bestanden.';

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
  String get databaseKdbxVersion => 'KDBX Bestandsversie';

  @override
  String databaseKdbxUpgradeVersion(Object versionName) {
    return 'Upgrade naar $versionName';
  }

  @override
  String get databaseKdbxUpgradeSuccessful =>
      'Bestand succesvol bijgewerkt en opgeslagen.';

  @override
  String get databaseReload => 'Herladen en samenvoegen';

  @override
  String progressStatus(Object statusProgress) {
    return 'Status: $statusProgress';
  }

  @override
  String finishedMerge(Object status) {
    return 'Samenvoegen $status gelukt';
  }

  @override
  String get closeAndLockFile => 'Sluiten/Vergrendelen';

  @override
  String get openvalutHomeScreenTagline =>
      'wachtwoordmanager, open source, beschikbaar op alle platformen.';

  @override
  String get addNewPasswordButtonLabel => 'Nieuw wachtwoord toevoegen';

  @override
  String get unnamedEntryPlaceholder => '(naamloos)';

  @override
  String get unnamedGroupPlaceholder => '(naamloos)';

  @override
  String get unnamedFilePlaceholder => '(naamloos)';

  @override
  String get editGroupScreenTitle => 'Groep bewerken';

  @override
  String get editGroupGroupNameLabel => 'Groep Naam';

  @override
  String get files => 'Bestanden';

  @override
  String get newGroupDialogTitle => 'Nieuwe groep';

  @override
  String get newGroupDialogInputLabel => 'Naam voor de nieuwe groep';

  @override
  String get groupActionShowPasswords => 'Wachtwoord weergeven';

  @override
  String get groupActionDelete => 'Verwijderen';

  @override
  String get logoutTooltip => 'Uitloggen';

  @override
  String get successfullyDeletedFileCloudStorage =>
      'Bestand succesvol verwijderd.';

  @override
  String shareDialogTitle(Object fileName) {
    return 'Opties voor delen $fileName';
  }

  @override
  String get shareFileActionLabel => 'Delen …';

  @override
  String get shareTokenListEmptyScreenPlaceholder =>
      'Bestand nog niet gedeeld.';

  @override
  String get shareTokenNoLabel => 'Geen label/omschrijving';

  @override
  String get shareTokenReadWrite => 'Lezen/schrijven';

  @override
  String get shareTokenReadOnly => 'Alleen lezen';

  @override
  String get shareCreateTokenDialogTitle => 'Bestand delen';

  @override
  String get shareCreateTokenReadOnly => 'Alleen lezen';

  @override
  String get shareCreateTokenReadOnlyHelpText =>
      'Opslaan van wijzigingen niet toestaan';

  @override
  String get shareCreateTokenLabelText => 'Omschrijving';

  @override
  String get shareCreateTokenLabelHint => 'Deel met mijn vriend';

  @override
  String get shareCreateTokenLabelHelp =>
      'Optioneel label om de deelcode te differentiëren.';

  @override
  String get shareCreateTokenSuccess => 'Deelcode succesvol aangemaakt.';

  @override
  String get sharePresentDialogTitle => 'Deel bestand met geheime deelcode';

  @override
  String get sharePresentDialogHelp =>
      'Met de volgende deelcode hebben gebruikers toegang tot het wachtwoord bestand. Ze hebben het wachtwoord en/of sleutelbestand nodig om het te openen.';

  @override
  String get sharePresentToken => 'Deelcode';

  @override
  String get sharePresentCopied => 'Deelcode gekopieerd naar klembord.';

  @override
  String get openvalutCloudOpenWithShareCodeTooltip => 'Openen met deelcode';

  @override
  String get openvalutCloudShareFileActionLabel => 'Delen';

  @override
  String get preferenceopenvalutCloudAttachmentTitle =>
      'Gebruik OpenValut Cloudbijlagen';

  @override
  String get preferenceopenvalutCloudAttachmentSubtitle =>
      'Sla bijlagen afzonderlijk versleuteld in OpenValut Cloud.';

  @override
  String get shareCodeInputDialogTitle => 'Geheime deelcode invoeren';

  @override
  String get shareCodeInputDialogScan => 'Scan QR Code';

  @override
  String get shareCodeInputLabel => 'Geheime deelcode';

  @override
  String get shareCodeInputHelperText =>
      'Als je een deelcode hebt ontvangen, plak deze dan hierboven.';

  @override
  String get shareCodeOpen => 'Een deelcode ontvangen voor OpenValut Cloud?';

  @override
  String get shareCodeOpenScreenTitle => 'Bestand met deelcode laden';

  @override
  String get shareCodeLoadingProgress => 'Bestand laden …';

  @override
  String get shareCodeOpenFileButtonLabel => 'OPEN';

  @override
  String get shareCodeOpenInstallAppCaption =>
      'Wil je dit bestand in plaats daarvan openen met een van onze native Apps?';

  @override
  String get shareCodeOpenAnotherAppCaption =>
      'Wil je dit bestand op een ander apparaat openen?';

  @override
  String get shareCodeOpenInstallAppButtonLabel => 'App installeren';

  @override
  String get shareCodeOpenShowCodeButtonLabel => 'Toon deelcode';

  @override
  String get changeMasterPasswordActionLabel => 'Hoofdwachtwoord wijzigen';

  @override
  String get changeMasterPasswordFormSubmit => 'Opslaan met nieuw wachtwoord';

  @override
  String get changeMasterPasswordSuccess =>
      'Hoofdwachtwoord succesvol opgeslagen.';

  @override
  String get changeMasterPasswordScreenTitle => 'Hoofdwachtwoord wijzigen';

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
      'Ik heb de e-mail ontvangen en de link bezocht';

  @override
  String get openvalutCloudAuthNotConfirmed =>
      'E-mailadres is nog niet bevestigd. Zorg ervoor dat in de e-mail op de link klikt en vervolgens de captcha oplost om je e-mailadres te bevestigen.';

  @override
  String get getHelpButton => 'Hulp krijgen in het forum';

  @override
  String get shortcutCopyUsername => 'Gebruikersnaam kopiëren';

  @override
  String get shortcutCopyPassword => 'Wachtwoord kopiëren';

  @override
  String get shortcutCopyTotp => 'TOTP kopiëren';

  @override
  String get shortcutMoveUp => 'Selecteer vorig wachtwoord';

  @override
  String get shortcutMoveDown => 'Selecteer het volgende wachtwoord';

  @override
  String get shortcutGeneratePassword => 'Wachtwoord genereren';

  @override
  String get shortcutCopyUrl => 'Kopieer URL';

  @override
  String get shortcutOpenUrl => 'Open URL';

  @override
  String get shortcutCancelSearch => 'Zoeken annuleren';

  @override
  String get shortcutShortcutHelp => 'Toetsenbord sneltoets Help';

  @override
  String get shortcutHelpTitle => 'Toetsenbord sneltoetsen';

  @override
  String unexpectedError(String error) {
    return 'Onverwachte fout: $error';
  }

  @override
  String get googleDriveMorePermissionsRequired =>
      'Additional permissions needed to access Google Drive.';

  @override
  String get googleDriveRequestPermissionButtonLabel => 'Request Permissions';

  @override
  String get scanQrCodeTitle => 'Scan QR Code.';
}
