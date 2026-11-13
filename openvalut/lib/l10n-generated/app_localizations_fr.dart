// ignore_for_file: omit_local_variable_types,unused_local_variable

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

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
  String get entryAddAttachment => 'Ajouter une pièce jointe';

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
  String get fieldUserName => 'Utilisateur';

  @override
  String get fieldPassword => 'Mot de passe';

  @override
  String get fieldWebsite => 'Site Web';

  @override
  String get fieldTitle => 'Titre';

  @override
  String get fieldTotp => 'Mot de passe à usage unique (basé sur le temps)';

  @override
  String get english => 'Anglais';

  @override
  String get german => 'Allemand';

  @override
  String get russian => 'Russe';

  @override
  String get ukrainian => 'Ukrainien';

  @override
  String get lithuanian => 'Lituanien';

  @override
  String get french => 'Français';

  @override
  String get spanish => 'Espagnol';

  @override
  String get indonesian => 'Indonésie';

  @override
  String get turkish => 'Turc';

  @override
  String get hebrew => 'Hébreu';

  @override
  String get italian => 'Italien';

  @override
  String get chineseSimplified => 'Chinois simplifié';

  @override
  String get chineseTraditional => 'Chinois traditionnel';

  @override
  String get portugueseBrazilian => 'Portugais, Brésilien';

  @override
  String get slovak => 'Slovaque';

  @override
  String get dutch => 'Néerlandais';

  @override
  String get selectItem => 'Sélectionner';

  @override
  String get selectKeepassFile => 'OpenValut - Sélectionnez un fichier KeePass';

  @override
  String get selectKeepassFileLabel =>
      'Veuillez sélectionner un fichier KeePass (.kdbx).';

  @override
  String get createNewFile => 'Créer un nouveau fichier';

  @override
  String get openLocalFile => 'Ouvrir un fichier local';

  @override
  String get openFile => 'Ouvrir un fichier';

  @override
  String get loadFromDropdownMenu => 'Charger depuis …';

  @override
  String get quickUnlockingFiles => 'Déverrouillage rapide des fichiers…';

  @override
  String openFileProgress(Object fileName, Object current, Object totalCount) {
    return 'Ouverture de $fileName … ($current / $totalCount)';
  }

  @override
  String loadFrom(String cloudStorageName) {
    return 'Charger depuis $cloudStorageName';
  }

  @override
  String get loadFromRemoteUrl => 'Ouvrir kdbx à partir d\'une adresse URL';

  @override
  String get createNewKeepass =>
      'Nouveau sur KeePass?\nCréez une nouvelle base de données de mots de passe';

  @override
  String get labelLastOpenFiles => 'Derniers fichiers ouverts :';

  @override
  String get noFilesHaveBeenOpenYet =>
      'Aucun fichier n\'a été ouvert pour le moment.';

  @override
  String get preferenceSelectLanguage => 'Sélectionnez la langue';

  @override
  String get preferenceLanguage => 'Langue';

  @override
  String get preferenceTextScaleFactor => 'Taille du texte';

  @override
  String get preferenceVisualDensity => 'Espacement';

  @override
  String get preferenceTheme => 'Thème';

  @override
  String get preferenceThemeLight => 'Clair';

  @override
  String get preferenceThemeDark => 'Sombre';

  @override
  String get preferenceSystemDefault => 'Paramètre système';

  @override
  String get preferenceDefault => 'Par défaut';

  @override
  String get lockAllFiles => 'Verrouiller tous les fichiers ouverts';

  @override
  String get preferenceAllowScreenshots =>
      'Autoriser les captures d\'écran de l\'application';

  @override
  String get preferenceEnableAutoFill => 'Activer la saisie automatique';

  @override
  String get enableAutofillSuggestionBanner =>
      'Vous pouvez remplir les champs de saisie d\'autres applications en activant la saisie !';

  @override
  String get dismissAutofillSuggestionBannerButton => 'IGNORER';

  @override
  String get enableAutofillSuggestionBannerButton => 'ACTIVER !';

  @override
  String get preferenceAutoFillDescription =>
      'Uniquement supporté par Android Oreo (8.0) ou supérieur.';

  @override
  String get preferenceTitle => 'Paramètres';

  @override
  String get preferenceEnableSystemWideShortcuts =>
      'Activer les raccourcis dans tout le système';

  @override
  String get preferenceEnableSystemWideShortcutsHelp =>
      'Enregistrer ctrl+alt+f dans le système comme un raccourci pour ouvrir la recherche.';

  @override
  String get preferencesSearchFields => 'Personnaliser les champs de recherche';

  @override
  String get preferencesSearchFieldPromptTitle => 'Champs de recherche';

  @override
  String get preferencesSearchFieldPromptLabel =>
      'Liste des champs séparés par des virgules à utiliser dans la recherche de la liste des mots de passe.';

  @override
  String preferencesSearchFieldPromptHelp(
    Object wildCardCharacter,
    Object defaultSearchFields,
  ) {
    return 'Utiliser $wildCardCharacter pour tous, laisser vide pour les valeurs par défaut ($defaultSearchFields)';
  }

  @override
  String get aboutAppName => 'OpenValut';

  @override
  String get aboutLinkFeedback => 'Tout type de commentaire est le bienvenu !';

  @override
  String get aboutLinkVisitWebsite =>
      'N\'oubliez pas de visiter notre site Web';

  @override
  String get aboutLinkGitHub => 'Et également le projet Open Source';

  @override
  String aboutLogFile(String logFilePath) {
    return 'Fichier Log : $logFilePath';
  }

  @override
  String get aboutLinkContributors => 'Afficher les contributeurs';

  @override
  String get unableToLaunchUrlTitle => 'Impossible d\'ouvrir l\'URL';

  @override
  String unableToLaunchUrlDescription(Object url, Object openError) {
    return 'Impossible d\'ouvrir l\'$url : $openError';
  }

  @override
  String get unableToLaunchUrlNoHandler =>
      'Aucune application disponible pour cette URL.';

  @override
  String launchedUrl(Object url) {
    return 'URL $url ouverte :';
  }

  @override
  String get menuItemGeneratePassword => 'Générer un mot de passe';

  @override
  String get menuItemPreferences => 'Paramètres';

  @override
  String get menuItemOpenAnotherFile => 'Ouvrir un autre fichier';

  @override
  String get menuItemCheckForUpdates => 'Rechercher des mises à jour';

  @override
  String get menuItemSupport => 'Envoyer les logs';

  @override
  String get menuItemSupportSubtitle => 'Envoyer les logs par email';

  @override
  String get menuItemForum => 'Forum d’assistance';

  @override
  String get menuItemForumSubtitle =>
      'Signaler des problèmes et obtenir de l\'aide';

  @override
  String get menuItemHelp => 'Aide';

  @override
  String get menuItemHelpSubtitle => 'Afficher la documentation';

  @override
  String get menuItemAbout => 'À propos';

  @override
  String get actionOpenUrl => 'Ouvrir l\'URL';

  @override
  String get passwordPlainText => 'Afficher le mot de passe';

  @override
  String get generatorPassword => 'Mot de passe';

  @override
  String get generatePassword => 'Générer un mot de passe';

  @override
  String get doneButtonLabel => 'Terminé';

  @override
  String get useAsDefault => 'Utiliser comme valeur par défaut';

  @override
  String get characterSetLowerCase => 'Minuscules (a-z)';

  @override
  String get characterSetUpperCase => 'Majuscules (A-Z)';

  @override
  String get characterSetNumeric => 'Chiffres (0-9)';

  @override
  String get characterSetUmlauts => 'Accents (ä)';

  @override
  String get characterSetSpecial => 'Caractères spéciaux (@%+)';

  @override
  String get length => 'Longueur';

  @override
  String get customLength => 'Longueur personnalisée';

  @override
  String customLengthHelperText(Object customMinLength) {
    return 'Utilisé seulement pour une longueur > $customMinLength';
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
      other: '$numFilesString fichiers enregistrés: $files',
      one: 'In fichier enregistré: $files',
    );
    return '$_temp0';
  }

  @override
  String get manageGroups => 'Gestion des groupes';

  @override
  String get lockFiles => 'Verrouiller les fichiers';

  @override
  String get searchHint => 'Recherche';

  @override
  String get searchButtonLabel => 'Recherche';

  @override
  String get filterButtonLabel => 'Filtrer par groupe';

  @override
  String get clear => 'Supprimer';

  @override
  String get autofillFilterPrefix => 'Filtre :';

  @override
  String get autofillMatchPrefix => 'Matching entries for:';

  @override
  String get autofillPrompt =>
      'Sélectionnez le mot de passe pour le remplissage automatique.';

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
  String get copiedToClipboard => 'Copié dans le presse-papier.';

  @override
  String get noTitle => '(aucun titre)';

  @override
  String get noUsername => '(aucun nom d\'utilisateur)';

  @override
  String get filterCustomize => 'Personnaliser …';

  @override
  String get swipeCopyPassword => 'Copier le mot de passe';

  @override
  String get swipeCopyUsername => 'Copier le nom d\'utilisateur';

  @override
  String get copyUsernameNotExists =>
      'L\'entrée n\'a pas de nom d\'utilisateur défini.';

  @override
  String get copyPasswordNotExists =>
      'L\'entrée n\'a pas de nom d\'utilisateur défini.';

  @override
  String get doneCopiedPassword => 'Mot de passe copié dans le presse-papier.';

  @override
  String get doneCopiedUsername =>
      'Nom d\'utilisateur copié dans le presse-papier.';

  @override
  String get doneCopiedField => 'Copié.';

  @override
  String copiedFieldToClipboard(Object fieldName) {
    return '$fieldName copié.';
  }

  @override
  String copiedFieldEmpty(Object fieldName) {
    return '$fieldName est vide.';
  }

  @override
  String get emptyPasswordVaultPlaceholder =>
      'Vous n\'avez pas encore de mot de passe dans votre base de données.';

  @override
  String get emptyPasswordVaultButtonLabel =>
      'Créez votre premier mot de passe';

  @override
  String get loading => 'Chargement en cours';

  @override
  String get loadingFile => 'Chargement du fichier …';

  @override
  String get internalFile => 'Fichier interne';

  @override
  String get internalFileSubtitle =>
      'Base de données précédemment créée avec OpenValut';

  @override
  String get filePicker => 'Gestionnaire de fichiers';

  @override
  String get filePickerSubtitle => 'Ouvrir un fichier de l\'appareil.';

  @override
  String get credentialsAppBarTitle => 'Identification';

  @override
  String get credentialLabel => 'Entrez le mot de passe pour :';

  @override
  String get masterPasswordInputLabel => 'Mot de passe';

  @override
  String get masterPasswordEmptyValidator =>
      'Veuillez entrer votre mot de passe.';

  @override
  String get masterPasswordIncorrectValidator => 'Mot de passe incorrect';

  @override
  String get useKeyFile => 'Utiliser un fichier clé';

  @override
  String get saveMasterPasswordBiometric =>
      'Enregistrer le mot de passe dans les données biométriques ?';

  @override
  String get close => 'Fermer';

  @override
  String get addNewPassword => 'Ajouter un nouveau mot de passe';

  @override
  String get errorOpenFileInvalidFileStructureTitle =>
      'Tentative d\'ouverture d\'un type de fichier invalide';

  @override
  String errorOpenFileInvalidFileStructureBody(Object fileName) {
    return 'Le fichier ($fileName) ne partait pas être un fichier KDBX valide. Veuillez choisir un fichier KDBX valide ou créer une nouvelle base de donnée.';
  }

  @override
  String get errorOpenFileAlreadyOpenTitle => 'Fichier déjà ouvert';

  @override
  String errorOpenFileAlreadyOpenBody(
    Object databaseName,
    Object openFileSource,
    Object newFileSource,
  ) {
    return 'La base de données $databaseName sélectionnée est déjà ouverte depuis $openFileSource (tentative d\'ouverture depuis $newFileSource)';
  }

  @override
  String get loadFromUrl => 'Télécharger depuis une URL';

  @override
  String get loadFromUrlEnterUrl => 'Entrez l\'URL';

  @override
  String get loadFromUrlErrorEnterFullUrl =>
      'Veuillez entrer une url complète commençant par http:// ou https://';

  @override
  String get loadFromUrlErrorInvalidUrl => 'Veuillez entrer une URL valide.';

  @override
  String get linuxAppArmorWarning =>
      'OpenValut nécessite les autorisations de communication avec les services secrets pour sauvegarder les identifiants dans le stockage cloud.\nVeuillez exécuter les commandes suivantes:';

  @override
  String get cancel => 'Annuler';

  @override
  String get errorLoadFileFromSourceTitle =>
      'Erreur lors de l\'ouverture du fichier.';

  @override
  String errorLoadFileFromSourceBody(Object source, Object error) {
    return 'Impossible d\'ouvrir $source.\n$error';
  }

  @override
  String get errorUnlockFileTitle => 'Ouverture de fichier impossible';

  @override
  String errorUnlockFileBody(Object error) {
    return 'Erreur inconnue lors de l\'ouverture du fichier. $error';
  }

  @override
  String get dialogContinue => 'Suivant';

  @override
  String get dialogSendErrorReport => 'Envoyer le rapport d\'erreur';

  @override
  String get dialogReportErrorForum => 'Signaler une erreur dans le Forum/Aide';

  @override
  String get groupFilterDescription =>
      'Sélectionnez les groupes à afficher (récursif)';

  @override
  String get groupFilterSelectAll => 'Tout sélectionner';

  @override
  String get groupFilterDeselectAll => 'Tout désélectionner';

  @override
  String get createSubgroup => 'Créer un sous-groupe';

  @override
  String get editAction => 'Modifier';

  @override
  String get mailboxEnableLabel => '(ré)activer';

  @override
  String get mailboxEnableHint => 'Continuer à recevoir des e-mails';

  @override
  String get mailboxDisableLabel => 'Désactiver';

  @override
  String get mailboxDisableHint => 'Ne plus recevoir d\'e-mails';

  @override
  String get mailListNoMail => 'Vous n\'avez pas encore d\'e-mail.';

  @override
  String mailboxLabelPrefixForEntry(Object entryLabel) {
    return 'Saisie : $entryLabel';
  }

  @override
  String mailboxLabelPrefixUnknownEntry(Object entryUuid) {
    return 'Entrée inconnue: $entryUuid';
  }

  @override
  String mailboxLabelPrefixCreatedAt(Object dateTime) {
    return 'Créé le : $dateTime';
  }

  @override
  String get masterPasswordDescription =>
      'Le mot de passe maître est utilisé pour chiffrer de façon sécurisée votre base de données de mot de passe. Assurez-vous de vous en souvenir. Il ne peut pas être restauré.';

  @override
  String get unsavedChangesWarningTitle => 'Modifications non sauvegardées';

  @override
  String get unsavedChangesWarningBody =>
      'Il y a encore des modifications non enregistrées. Voulez-vous annuler les modifications ?';

  @override
  String get unsavedChangesDiscardActionLabel => 'Ignorer les modifications';

  @override
  String get deletePermanentlyAction => 'Supprimer définitivement';

  @override
  String get restoreFromRecycleBinAction => 'Restaurer';

  @override
  String get deleteAction => 'Supprimer';

  @override
  String get deletedEntry => 'Entrée supprimée.';

  @override
  String get successfullyDeletedGroup => 'Groupe supprimé.';

  @override
  String get undoButtonLabel => 'Annuler';

  @override
  String get saveButtonLabel => 'Sauvegarder';

  @override
  String get webDavSettings => 'Configuration WebDAV';

  @override
  String get webDavUrlLabel => 'URL';

  @override
  String get webDavUrlHelperText => 'Url de base de votre service WebDAV.';

  @override
  String get webDavUrlValidatorError => 'Veuillez entrer une URL';

  @override
  String get webDavUrlValidatorInvalidUrlError =>
      'Veuillez entrer une url valide avec http:// ou https://';

  @override
  String get webDavAuthUser => 'Nom d\'utilisateur';

  @override
  String get webDavopenvalutword => 'Mot de passe';

  @override
  String get mergeSuccessDialogTitle =>
      'La base de données de mots de passe a été fusionnée avec succès';

  @override
  String mergeSuccessDialogMessage(Object fileName, Object mergeSummary) {
    return 'Conflit détecté lors de la sauvegarde de $fileName, il a été fusionné avec succès avec le fichier distant : \n\n$mergeSummary';
  }

  @override
  String forDetailsVisitUrl(Object url) {
    return 'Pour plus de détails, consultez $url';
  }

  @override
  String get openvalutCloudAuthEmailInputLabel =>
      'Entrez l\'adresse e-mail pour vous inscrire ou vous connecter.';

  @override
  String get openvalutCloudAuthEmailInvalid =>
      'Veuillez entrer une adresse e-mail valide.';

  @override
  String get openvalutCloudAuthConfirmEmailButtonLabel =>
      'Confirmer l\'adresse';

  @override
  String get openvalutCloudAuthConfirmEmail =>
      'Veuillez vérifier vos e-mails pour confirmer votre adresse e-mail.';

  @override
  String get openvalutCloudAuthConfirmEmailExplain =>
      'Gardez cet écran ouvert jusqu\'à ce que vous ayez visité le lien que vous avez reçu par courriel.';

  @override
  String get openvalutCloudAuthResendExplain =>
      'Si vous n\'avez pas reçu d\'e-mail, veuillez vérifier votre dossier spam. Sinon, vous pouvez essayer de demander un nouveau lien de confirmation.';

  @override
  String get openvalutCloudAuthResendButtonLabel =>
      'Demander un nouveau lien de confirmation';

  @override
  String permanentlyDeleteEntryConfirm(Object title) {
    return 'Cela supprimera définitivement l\'entrée de mot de passe $title. Cela ne peut pas être annulé. Voulez-vous continuer ?';
  }

  @override
  String get permanentlyDeletedEntrySnackBar =>
      'Entrée supprimée définitivement.';

  @override
  String get initialNewGroupName => 'Nouveau groupe';

  @override
  String get deleteGroupErrorTitle => 'Impossible de supprimer le groupe';

  @override
  String get deleteGroupErrorBodyContainsGroup =>
      'Ce groupe contient d\'autres groupes. Vous ne pouvez supprimer que des groupes vides.';

  @override
  String get deleteGroupErrorBodyContainsEntries =>
      'Ce groupe contient des mots de passe. Vous ne pouvez supprimer que des groupes vides.';

  @override
  String get groupListAppBarTitle => 'Groupes';

  @override
  String get groupListFilterAppbarTitle => 'Filtrer par groupes';

  @override
  String get clearQuickUnlock => 'Effacer le stockage des données biométriques';

  @override
  String get clearQuickUnlockSubtitle =>
      'Supprimer les mots de passe principaux enregistrés';

  @override
  String get unlock => 'Déverrouiller les fichiers';

  @override
  String get closePasswordFiles =>
      'fermer les fichiers contenant les mots de passe';

  @override
  String get clearQuickUnlockSuccess =>
      'Supprimer les mots de passe maître sauvegardés dans l’espace de stockage des données biométriques.';

  @override
  String get diacOptIn =>
      'Inscrivez-vous pour les actualités et sondages concernant l\'application.';

  @override
  String get diacOptInSubtitle =>
      'Envoie occasionnellement une requête réseau pour récupérer les actualités.';

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
      'Remplissage automatique : Activer le débogage';

  @override
  String get enableAutofillDebugSubtitle =>
      'Affiche des informations supplémentaires pour chaque champ de saisie';

  @override
  String get createPasswordDatabase =>
      'Créer une base de données de mots de passe';

  @override
  String get nameNewPasswordDatabase => 'Nom de votre nouvelle base de données';

  @override
  String get validatorNameMissing =>
      'Veuillez entrer un nom pour votre nouvelle base de données.';

  @override
  String get masterPasswordHelpText =>
      'Sélectionnez un mot de passe principal sécurisé. Assurez-vous de vous en souvenir.';

  @override
  String get inputMasterPasswordText => 'Mot de passe principal';

  @override
  String get masterPasswordMissingCreate =>
      'S’il vous plait entrer un mot de passe sécurisé, que vous pouvez retenir.';

  @override
  String get createDatabaseAction => 'Créer une base de données';

  @override
  String get databaseExistsError => 'Le fichier existe déjà';

  @override
  String databaseExistsErrorDescription(Object filePath) {
    return 'Erreur lors de la création de la base de données $filePath. Le fichier existe déjà. Veuillez choisir un autre nom.';
  }

  @override
  String get databaseCreateDefaultName => 'Mots de passe personnels';

  @override
  String get preferenceDynamicLoadIcons => 'Chargement dynamique des icônes';

  @override
  String preferenceDynamicLoadIconsSubtitle(Object urlFieldName) {
    return 'Effectuera des requêtes http avec la valeur du champ $urlFieldName pour charger les icônes du site web.';
  }

  @override
  String passwordScore(Object score) {
    return 'Force : $score sur 4';
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
  String get entryInfoFile => 'Fichier :';

  @override
  String get entryInfoGroup => 'Groupe :';

  @override
  String get entryInfoLastModified => 'Dernière modification :';

  @override
  String movedEntryToGroup(Object groupName) {
    return 'Entrée déplacée vers $groupName';
  }

  @override
  String sizeBytesStoredopenvalutCloud(Object count) {
    return '$count octets, stockés dans le OpenValut Cloud';
  }

  @override
  String sizeBytes(Object count) {
    return '$count octets';
  }

  @override
  String get entryAttachmentSizeWarning =>
      'Les fichiers joints seront intégrés au fichier de mots de passe. Cela peut considérablement augmenter le temps nécessaire pour ouvrir/enregistrer les mots de passe.';

  @override
  String get iconPngSizeWarning =>
      'Les fichiers joints seront intégrés au fichier de mots de passe. Cela peut considérablement augmenter le temps nécessaire pour ouvrir/enregistrer les mots de passe.';

  @override
  String get notPngError => 'Le fichier choisi n\'est pas un PNG.';

  @override
  String get entryAddField => 'Ajouter un champ';

  @override
  String get entryCustomField => 'Champ personnalisé';

  @override
  String get entryCustomFieldTitle => 'Ajout d\'un nouveau champ personnalisé';

  @override
  String get entryCustomFieldInputLabel => 'Entrez un nom pour le champ';

  @override
  String get swipeCopyField => 'Copier le champ';

  @override
  String get fieldRename => 'Renommer';

  @override
  String get fieldGeneratePassword => 'Générer un mot de passe …';

  @override
  String get fieldProtect => 'Protéger la valeur';

  @override
  String get fieldUnprotect => 'Déprotéger la valeur';

  @override
  String get fieldPresent => 'Afficher';

  @override
  String get fieldGenerateEmail => 'Générer une adresse e-mail';

  @override
  String get onboardingBackToOnboarding => 'Visite guidée';

  @override
  String get onboardingBackToOnboardingSubtitle =>
      'Revivez l\'expérience de la première exécution 😅';

  @override
  String get onboardingHeadline => 'Sécurisons vos mots de passe !';

  @override
  String get onboardingQuestion =>
      'Avez-vous déjà utilisé un gestionnaire de mots de passe ?';

  @override
  String get onboardingYesOpenPasswords => 'Oui, ouvrir mes mots de passe';

  @override
  String get onboardingNoCreate =>
      'Je suis tout nouveau ! Commençons ensemble.';

  @override
  String get backupButton => 'SAUVEGARDER SUR LE CLOUD';

  @override
  String get dismissBackupButton => 'IGNORER';

  @override
  String backupWarningMessage(Object databasename) {
    return 'Vos mots de passe dans $databasename ne sont sauvegardés que localement !';
  }

  @override
  String get saveAs => 'Sauvegarder dans...';

  @override
  String get saving => 'Enregistrement';

  @override
  String get increaseValue => 'Augmenter';

  @override
  String get decreaseValue => 'Diminuer';

  @override
  String get resetValue => 'Réinitialiser';

  @override
  String cloudStorageAppBarTitle(Object cloudStorageName) {
    return 'Stockage cloud - $cloudStorageName';
  }

  @override
  String get cloudStorageLogInCaption =>
      'Vous allez être redirigé vers l\'authentification OpenValut pour accéder à vos données.';

  @override
  String get cloudStorageLogInCode => 'Saisir le code';

  @override
  String launchUrlError(Object url) {
    return 'Impossible d\'ouvrir l’adresse url. Veuillez visiter $url';
  }

  @override
  String cloudStorageLogInActionLabel(Object cloudStorageName) {
    return 'Se connecter à $cloudStorageName';
  }

  @override
  String cloudStorageAuthCodeDialogTitle(Object cloudStorageName) {
    return 'Authentification $cloudStorageName';
  }

  @override
  String get cloudStorageAuthCodeLabel => 'Code d\'authentification';

  @override
  String get cloudStorageAuthErrorTitle => 'Erreur lors de l\'authentification';

  @override
  String cloudStorageAuthErrorMessage(
    Object cloudStorageName,
    Object errorMessage,
  ) {
    return 'Erreur lors de l\'authentification à $cloudStorageName: $errorMessage';
  }

  @override
  String get cloudStorageSearchBoxLabel => 'Rechercher';

  @override
  String cloudStorageItemsInFolder(Object itemCount) {
    return '$itemCount éléments dans le dossier.';
  }

  @override
  String get mailSubject => 'Objet';

  @override
  String get mailFrom => 'De';

  @override
  String get mailDate => 'Date';

  @override
  String get mailMailbox => 'Boite mail';

  @override
  String get mailNoData => 'Aucune donnée';

  @override
  String get mailMailboxesTitle => 'Boîtes aux lettres';

  @override
  String get mailboxCreateButtonLabel => 'Créer';

  @override
  String get mailboxNameInputDialogTitle =>
      'Étiquette facultative pour la nouvelle boîte mail';

  @override
  String get mailboxNameInputLabel => 'Libellé (interne)';

  @override
  String get mailScreenTitle => 'Addresses mails OpenValut';

  @override
  String get mailTabBarTitleMailbox => 'Boite mail';

  @override
  String get mailTabBarTitleMail => 'Email';

  @override
  String get mailMailboxListEmpty => 'Vous n\'avez pas encore d\'e-mail.';

  @override
  String mailMailboxAddressCopied(Object mailboxAddress) {
    return 'Adresse e-mail copiée dans le presse-papiers: $mailboxAddress';
  }

  @override
  String get errorWhileSavingTitle => 'Erreur lors de l\'enregistrement';

  @override
  String errorWhileSavingBody(Object errorMessage) {
    return 'Impossible d\'enregistrer le fichier : $errorMessage';
  }

  @override
  String get databaseDoesNotSupportSaving =>
      'Désolé, cette base de données ne prend pas en charge l\'enregistrement. Veuillez ouvrir un fichier de base de données locale. Ou utilisez \"Enregistrer sous\".';

  @override
  String get otpInvalidKeyTitle => 'Clé invalide';

  @override
  String get otpInvalidKeyBody =>
      'L\'entrée donnée n\'est pas un code TOTP valide en base32. Veuillez vérifier votre entrée.';

  @override
  String get otpUnsupportedMigrationTitle => 'Unsupported OTP Migration';

  @override
  String otpUnsupportedMigrationBody(Object uriCount) {
    return 'We currently only support single item migrations. Got $uriCount';
  }

  @override
  String get otpPromptTitle => 'Authentification basée sur le temps';

  @override
  String get otpPromptHelperText =>
      'Veuillez entrer une clé basée sur le temps.';

  @override
  String otpErrorMessageGeneration(Object errorMessage) {
    return 'Erreur lors de la génération du code d\'invitation : $errorMessage';
  }

  @override
  String get otpCopySecretActionLabel => 'Copier le secret';

  @override
  String get otpEntryLabel => 'Jeton à usage unique';

  @override
  String get entryFieldProtected => 'Champ protégé. Cliquez pour révéler.';

  @override
  String get entryFieldActionRevealField => 'Afficher le champ protégé';

  @override
  String get entryAttachmentOpenActionLabel => 'Ouvrir';

  @override
  String get entryAttachmentShareActionLabel => 'Partager';

  @override
  String get entryAttachmentShareSubject => 'Pièce jointe';

  @override
  String get entryAttachmentSaveActionLabel => 'Enregistrer sur l\'appareil';

  @override
  String get entryAttachmentRemoveActionLabel => 'Supprimer';

  @override
  String entryAttachmentRemoveConfirm(Object attachmentLabel) {
    return 'Souhaitez vous réellement supprimer $attachmentLabel ?';
  }

  @override
  String get entryRenameFieldPromptTitle => 'Renommer le champ';

  @override
  String get removerecentfile => 'Masquer';

  @override
  String get entryRenameFieldPromptLabel => 'Entrez le nouveau nom du champ';

  @override
  String get promptDialogPasteActionTooltip => 'Coller depuis le presse-papier';

  @override
  String get promptDialogPasteHint =>
      'Astuce : si vous avez besoin de coller, essayez le bouton à gauche ;-)';

  @override
  String get genericErrorDialogTitle =>
      'Erreur lors du traitement de l\'action';

  @override
  String genericErrorDialogBody(Object errorMessage) {
    return 'Une erreur inattendue est survenue. $errorMessage';
  }

  @override
  String get saveAsEntryLocalFile => 'Fichier local';

  @override
  String get fileTypePngs => 'Images (png)';

  @override
  String get selectIconDialogAction => 'SÉLECTIONNER L\'ICÔNE';

  @override
  String get retryDialogActionLabel => 'RÉESSAYER';

  @override
  String errorDuringNetworkCall(Object errorMessage) {
    return 'Erreur pendant la requête API. $errorMessage';
  }

  @override
  String get passwordFilterHideDeleted => 'Masquer les entrées supprimées';

  @override
  String get passwordFilterOnlyDeleted => 'Entrées supprimées';

  @override
  String passwordFilterPrefixForOneGroup(Object groupName) {
    return 'Groupe: $groupName';
  }

  @override
  String passwordFilterPrefixForMultipleGroups(Object groupCount) {
    return 'Filtre personnalisé ($groupCount Groupes )';
  }

  @override
  String get menuItemopenvalutCloudAuthenticate =>
      'S\'authentifier avec OpenValut Cloud';

  @override
  String get menuItemopenvalutCloudMailboxes => 'Addresses mails OpenValut';

  @override
  String changesWithoutSaving(Object fileName) {
    return 'Vous avez des modifications dans \"$fileName\", qui ne prennent pas en charge l\'écriture des modifications.';
  }

  @override
  String get changesSaveLocally => 'Enregistrer localement';

  @override
  String get clearColor => 'Effacer la couleur';

  @override
  String get databaseRenameInputLabel => 'Entrez le nom de la base de données';

  @override
  String get databasePath => 'Chemin d\'accès';

  @override
  String get databaseColor => 'Couleur';

  @override
  String get databaseColorChoose =>
      'Sélectionnez une couleur pour distinguer les fichiers.';

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
  String get databaseKdbxVersion => 'Version du fichier KDBX';

  @override
  String databaseKdbxUpgradeVersion(Object versionName) {
    return 'Mettre à jour vers $versionName';
  }

  @override
  String get databaseKdbxUpgradeSuccessful =>
      'Fichier mis à jour et enregistré avec succès.';

  @override
  String get databaseReload => 'Recharger et fusionner';

  @override
  String progressStatus(Object statusProgress) {
    return 'Statut : $statusProgress';
  }

  @override
  String finishedMerge(Object status) {
    return 'Fusion terminée $status';
  }

  @override
  String get closeAndLockFile => 'Fermer/Verrouiller';

  @override
  String get openvalutHomeScreenTagline =>
      'gestionnaire de mots de passe, open source, disponible sur toutes les plateformes.';

  @override
  String get addNewPasswordButtonLabel => 'Ajouter un nouveau mot de passe';

  @override
  String get unnamedEntryPlaceholder => '(Sans nom)';

  @override
  String get unnamedGroupPlaceholder => '(Sans nom)';

  @override
  String get unnamedFilePlaceholder => '(Sans nom)';

  @override
  String get editGroupScreenTitle => 'Modifier le groupe';

  @override
  String get editGroupGroupNameLabel => 'Nom du groupe';

  @override
  String get files => 'Fichiers';

  @override
  String get newGroupDialogTitle => 'Nouveau groupe';

  @override
  String get newGroupDialogInputLabel => 'Nom du nouveau groupe';

  @override
  String get groupActionShowPasswords => 'Afficher les mots de passe';

  @override
  String get groupActionDelete => 'Supprimer';

  @override
  String get logoutTooltip => 'Déconnexion';

  @override
  String get successfullyDeletedFileCloudStorage =>
      'Fichier supprimé avec succès.';

  @override
  String shareDialogTitle(Object fileName) {
    return 'Options de partage pour $fileName';
  }

  @override
  String get shareFileActionLabel => 'Partager …';

  @override
  String get shareTokenListEmptyScreenPlaceholder =>
      'Fichier pas encore partagé.';

  @override
  String get shareTokenNoLabel => 'Aucune étiquette/description';

  @override
  String get shareTokenReadWrite => 'Lire/Écrire';

  @override
  String get shareTokenReadOnly => 'Lecture seulement';

  @override
  String get shareCreateTokenDialogTitle => 'Partager le fichier';

  @override
  String get shareCreateTokenReadOnly => 'Lecture seulement';

  @override
  String get shareCreateTokenReadOnlyHelpText =>
      'Ne pas autoriser la sauvegarde des modifications';

  @override
  String get shareCreateTokenLabelText => 'Description';

  @override
  String get shareCreateTokenLabelHint => 'Partager pour mon ami';

  @override
  String get shareCreateTokenLabelHelp =>
      'Libellé facultatif pour différencier le code de partage.';

  @override
  String get shareCreateTokenSuccess => 'Code de partage créé avec succès.';

  @override
  String get sharePresentDialogTitle =>
      'Partager un fichier avec un code secret de partage';

  @override
  String get sharePresentDialogHelp =>
      'En utilisant le code de partage suivant, les utilisateurs peuvent accéder au fichier de mot de passe. Ils auront besoin du mot de passe et/ou du fichier clé pour l\'ouvrir.';

  @override
  String get sharePresentToken => 'Partager le Code';

  @override
  String get sharePresentCopied =>
      'Code de partage copié dans le presse-papiers.';

  @override
  String get openvalutCloudOpenWithShareCodeTooltip =>
      'Ouvrir avec le Code de Partage';

  @override
  String get openvalutCloudShareFileActionLabel => 'Partager';

  @override
  String get preferenceopenvalutCloudAttachmentTitle =>
      'Utiliser les pièces jointes OpenValut Cloud';

  @override
  String get preferenceopenvalutCloudAttachmentSubtitle =>
      'Stocker séparément les pièces jointes chiffrées sur OpenValut Cloud.';

  @override
  String get shareCodeInputDialogTitle => 'Saisir le code de partage secret';

  @override
  String get shareCodeInputDialogScan => 'Scanner le Code QR';

  @override
  String get shareCodeInputLabel => 'Partager le Code Secret';

  @override
  String get shareCodeInputHelperText =>
      'Si vous avez reçu un code de partage, veuillez le coller ci-dessus.';

  @override
  String get shareCodeOpen =>
      'Vous avez reçu un code de partage pour OpenValut Cloud ?';

  @override
  String get shareCodeOpenScreenTitle =>
      'Chargement du fichier avec le code de partage';

  @override
  String get shareCodeLoadingProgress => 'Chargement du fichier …';

  @override
  String get shareCodeOpenFileButtonLabel => 'OUVRIR';

  @override
  String get shareCodeOpenInstallAppCaption =>
      'Voulez-vous ouvrir ce fichier avec l\'une de nos applications natives à la place ?';

  @override
  String get shareCodeOpenAnotherAppCaption =>
      'Voulez-vous ouvrir ce fichier sur un autre appareil ?';

  @override
  String get shareCodeOpenInstallAppButtonLabel => 'Installer l\'app';

  @override
  String get shareCodeOpenShowCodeButtonLabel => 'Afficher le Code de Partage';

  @override
  String get changeMasterPasswordActionLabel =>
      'Changer le mot de passe maître';

  @override
  String get changeMasterPasswordFormSubmit =>
      'Sauvegarder avec un nouveau mot de passe';

  @override
  String get changeMasterPasswordSuccess =>
      'Mot de passe maître sauvegardé avec succès.';

  @override
  String get changeMasterPasswordScreenTitle =>
      'Changer le mot de passe maître';

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
      'J\'ai reçu un e-mail et j\'ai visité le lien';

  @override
  String get openvalutCloudAuthNotConfirmed =>
      'L\'adresse e-mail n\'a pas encore été confirmée. Assurez-vous de cliquer sur le lien dans l\'e-mail que vous avez reçu et de résoudre le captcha pour confirmer votre adresse e-mail.';

  @override
  String get getHelpButton => 'Obtenir de l\'aide dans le forum';

  @override
  String get shortcutCopyUsername => 'Copier le nom d\'utilisateur';

  @override
  String get shortcutCopyPassword => 'Copier le mot de passe';

  @override
  String get shortcutCopyTotp => 'Copier le TOTP';

  @override
  String get shortcutMoveUp => 'Sélectionner le mot de passe précédent';

  @override
  String get shortcutMoveDown => 'Sélectionner le mot de passe suivant';

  @override
  String get shortcutGeneratePassword => 'Générer un mot de passe';

  @override
  String get shortcutCopyUrl => 'Copier l\'URL';

  @override
  String get shortcutOpenUrl => 'Ouvrir l\'URL';

  @override
  String get shortcutCancelSearch => 'Annuler la recherche';

  @override
  String get shortcutShortcutHelp => 'Aide pour les Raccourcis clavier';

  @override
  String get shortcutHelpTitle => 'Raccourcis clavier';

  @override
  String unexpectedError(String error) {
    return 'Erreur inattendue : $error';
  }

  @override
  String get googleDriveMorePermissionsRequired =>
      'Additional permissions needed to access Google Drive.';

  @override
  String get googleDriveRequestPermissionButtonLabel => 'Request Permissions';

  @override
  String get scanQrCodeTitle => 'Scan QR Code.';
}
