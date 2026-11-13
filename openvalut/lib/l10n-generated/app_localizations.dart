// ignore_for_file: omit_local_variable_types,unused_local_variable
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_et.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_he.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_lt.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_si.dart';
import 'app_localizations_sk.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n-generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('de'),
    Locale('es'),
    Locale('et'),
    Locale('fi'),
    Locale('fr'),
    Locale('he'),
    Locale('id'),
    Locale('it'),
    Locale('lt'),
    Locale('nl'),
    Locale('pa'),
    Locale('pl'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('ru'),
    Locale('si'),
    Locale('sk'),
    Locale('tr'),
    Locale('uk'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @okAction.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okAction;

  /// No description provided for @cloudAuthEmailOrSecretInvalid.
  ///
  /// In en, this message translates to:
  /// **'Email or Secret Key is incorrect. Please check and try again.'**
  String get cloudAuthEmailOrSecretInvalid;

  /// No description provided for @cloudEmailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Sign in instead.'**
  String get cloudEmailAlreadyRegistered;

  /// No description provided for @cloudConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the OpenValut Cloud service: {error}'**
  String cloudConnectFailed(Object error);

  /// No description provided for @cloudNoVaultTitle.
  ///
  /// In en, this message translates to:
  /// **'This account has no vault yet'**
  String get cloudNoVaultTitle;

  /// No description provided for @cloudNoVaultBody.
  ///
  /// In en, this message translates to:
  /// **'A vault is created automatically during registration. Sign out and register to create one.'**
  String get cloudNoVaultBody;

  /// No description provided for @cloudWrongMasterPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong master password. Could not unlock the vault.'**
  String get cloudWrongMasterPassword;

  /// No description provided for @cloudDecryptFailedMasterPassword.
  ///
  /// In en, this message translates to:
  /// **'Cloud data could not be decrypted: the master password may be incorrect.'**
  String get cloudDecryptFailedMasterPassword;

  /// No description provided for @cloudScanCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the sign-in QR code: {error}'**
  String cloudScanCreateFailed(Object error);

  /// No description provided for @cloudScanExpired.
  ///
  /// In en, this message translates to:
  /// **'The QR code expired. Refresh and try again.'**
  String get cloudScanExpired;

  /// No description provided for @cloudScanSessionInvalid.
  ///
  /// In en, this message translates to:
  /// **'The sign-in session expired ({message}). Refresh the QR code.'**
  String cloudScanSessionInvalid(Object message);

  /// No description provided for @cloudScanWaitingPhone.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the phone to confirm ({error})'**
  String cloudScanWaitingPhone(Object error);

  /// No description provided for @cloudRegisterNoSecretKey.
  ///
  /// In en, this message translates to:
  /// **'Registration failed: no Secret Key was returned'**
  String get cloudRegisterNoSecretKey;

  /// No description provided for @cloudSaveSecretKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Save your Secret Key'**
  String get cloudSaveSecretKeyTitle;

  /// No description provided for @cloudSecretKeyDescription.
  ///
  /// In en, this message translates to:
  /// **'This is the unique identity key (account UUID) for your OpenValut Cloud account. Signing in requires email + Secret Key + master password. This key cannot be recovered, so copy it now and keep it safe; you can also skip this step.'**
  String get cloudSecretKeyDescription;

  /// No description provided for @cloudSaveToFileAction.
  ///
  /// In en, this message translates to:
  /// **'Save to local file'**
  String get cloudSaveToFileAction;

  /// No description provided for @cloudCopyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get cloudCopyAction;

  /// No description provided for @cloudSkipAction.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get cloudSkipAction;

  /// No description provided for @cloudSavedContinueAction.
  ///
  /// In en, this message translates to:
  /// **'I\'ve saved it — continue'**
  String get cloudSavedContinueAction;

  /// No description provided for @cloudSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get cloudSavedTitle;

  /// No description provided for @cloudSavedToFileBody.
  ///
  /// In en, this message translates to:
  /// **'Secret Key saved to a local file. Keep it safe.'**
  String get cloudSavedToFileBody;

  /// No description provided for @cloudSaveFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get cloudSaveFailedTitle;

  /// No description provided for @cloudSaveFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Could not save the Secret Key: {error}'**
  String cloudSaveFailedBody(Object error);

  /// No description provided for @cloudAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account: {email}'**
  String cloudAccountLabel(Object email);

  /// No description provided for @cloudLoginRequiresNote.
  ///
  /// In en, this message translates to:
  /// **'To sign in you need: email + Secret Key + master password'**
  String get cloudLoginRequiresNote;

  /// No description provided for @cloudSecretKeepSafeNote.
  ///
  /// In en, this message translates to:
  /// **'This key cannot be recovered — keep it safe.'**
  String get cloudSecretKeepSafeNote;

  /// No description provided for @cloudRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Register an OpenValut Cloud account'**
  String get cloudRegisterTitle;

  /// No description provided for @cloudLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to OpenValut Cloud'**
  String get cloudLoginTitle;

  /// No description provided for @cloudRegisterIntro.
  ///
  /// In en, this message translates to:
  /// **'Registration only needs an email. The vault master password is only used on this device for encryption and is never uploaded.'**
  String get cloudRegisterIntro;

  /// No description provided for @cloudLoginIntroDesktop.
  ///
  /// In en, this message translates to:
  /// **'Enter email, Secret Key and master password, or scan with the mobile app.'**
  String get cloudLoginIntroDesktop;

  /// No description provided for @cloudLoginIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter email, Secret Key and master password to sign in.'**
  String get cloudLoginIntro;

  /// No description provided for @cloudServerUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get cloudServerUrlLabel;

  /// No description provided for @cloudServerUrlHelp.
  ///
  /// In en, this message translates to:
  /// **'A default server is preconfigured; you can point it to your own domain.'**
  String get cloudServerUrlHelp;

  /// No description provided for @cloudServerUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the server URL'**
  String get cloudServerUrlRequired;

  /// No description provided for @cloudServerUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Server URL must start with http:// or https://'**
  String get cloudServerUrlInvalid;

  /// No description provided for @cloudEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get cloudEmailLabel;

  /// No description provided for @cloudEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get cloudEmailRequired;

  /// No description provided for @cloudEmailNoSpaces.
  ///
  /// In en, this message translates to:
  /// **'Email must not contain spaces'**
  String get cloudEmailNoSpaces;

  /// No description provided for @cloudEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get cloudEmailInvalid;

  /// No description provided for @cloudSecretKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Secret Key (the UUID saved at registration)'**
  String get cloudSecretKeyLabel;

  /// No description provided for @cloudSecretKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your Secret Key'**
  String get cloudSecretKeyRequired;

  /// No description provided for @cloudSecretKeyChars.
  ///
  /// In en, this message translates to:
  /// **'Secret Key may only contain hex characters and - separators'**
  String get cloudSecretKeyChars;

  /// No description provided for @cloudSecretKeyLength.
  ///
  /// In en, this message translates to:
  /// **'Secret Key should be 32 hex characters'**
  String get cloudSecretKeyLength;

  /// No description provided for @cloudMasterPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Vault master password'**
  String get cloudMasterPasswordLabel;

  /// No description provided for @cloudMasterPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the vault master password'**
  String get cloudMasterPasswordRequired;

  /// No description provided for @cloudPasswordNoSpaces.
  ///
  /// In en, this message translates to:
  /// **'Password must not contain spaces'**
  String get cloudPasswordNoSpaces;

  /// No description provided for @cloudVaultNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Vault name'**
  String get cloudVaultNameLabel;

  /// No description provided for @cloudVaultNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a vault name'**
  String get cloudVaultNameRequired;

  /// No description provided for @cloudVaultNameNoLeadingDigit.
  ///
  /// In en, this message translates to:
  /// **'Name must not start with a digit'**
  String get cloudVaultNameNoLeadingDigit;

  /// No description provided for @cloudVaultNameChars.
  ///
  /// In en, this message translates to:
  /// **'Name may only contain Chinese, English letters and digits'**
  String get cloudVaultNameChars;

  /// No description provided for @cloudMasterPasswordMin6.
  ///
  /// In en, this message translates to:
  /// **'Master password must be at least 6 characters'**
  String get cloudMasterPasswordMin6;

  /// No description provided for @cloudConfirmMasterPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm master password'**
  String get cloudConfirmMasterPasswordLabel;

  /// No description provided for @cloudPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two passwords do not match'**
  String get cloudPasswordMismatch;

  /// No description provided for @cloudRegisterSubmit.
  ///
  /// In en, this message translates to:
  /// **'Register and create vault'**
  String get cloudRegisterSubmit;

  /// No description provided for @cloudLoginSubmit.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get cloudLoginSubmit;

  /// No description provided for @cloudSwitchToLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get cloudSwitchToLogin;

  /// No description provided for @cloudSwitchToRegister.
  ///
  /// In en, this message translates to:
  /// **'No account? Register one'**
  String get cloudSwitchToRegister;

  /// No description provided for @cloudUseQrLogin.
  ///
  /// In en, this message translates to:
  /// **'Scan with the mobile app to sign in'**
  String get cloudUseQrLogin;

  /// No description provided for @cloudServerInfo.
  ///
  /// In en, this message translates to:
  /// **'Server: {server}'**
  String cloudServerInfo(Object server);

  /// No description provided for @cloudQrLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan to sign in to OpenValut Cloud'**
  String get cloudQrLoginTitle;

  /// No description provided for @cloudQrLoginDescription.
  ///
  /// In en, this message translates to:
  /// **'Use the mobile app signed in to OpenValut Cloud to scan the QR code below and confirm sign-in.'**
  String get cloudQrLoginDescription;

  /// No description provided for @cloudScanWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the phone to confirm…'**
  String get cloudScanWaiting;

  /// No description provided for @cloudRefreshQr.
  ///
  /// In en, this message translates to:
  /// **'Refresh QR code'**
  String get cloudRefreshQr;

  /// No description provided for @cloudBackToManual.
  ///
  /// In en, this message translates to:
  /// **'Back to manual entry'**
  String get cloudBackToManual;

  /// No description provided for @myShareReceiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive share'**
  String get myShareReceiveTitle;

  /// No description provided for @myShareReceiveNeedVault.
  ///
  /// In en, this message translates to:
  /// **'Open or create an OpenValut Cloud vault first to receive shares.'**
  String get myShareReceiveNeedVault;

  /// No description provided for @myShareAutoSavedCount.
  ///
  /// In en, this message translates to:
  /// **'Auto-saved {count} shared entries into the vault'**
  String myShareAutoSavedCount(Object count);

  /// No description provided for @myShareRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke share'**
  String get myShareRevokeTitle;

  /// No description provided for @myShareRevokeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Revoke the share of \"{entry}\"? The recipient will no longer be able to view it.'**
  String myShareRevokeConfirm(Object entry);

  /// No description provided for @myShareRevokeAction.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get myShareRevokeAction;

  /// No description provided for @myShareRevokeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to revoke'**
  String get myShareRevokeFailed;

  /// No description provided for @myShareUrlField.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get myShareUrlField;

  /// No description provided for @myShareNotesField.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get myShareNotesField;

  /// No description provided for @myShareUntitledEntry.
  ///
  /// In en, this message translates to:
  /// **'Unnamed entry'**
  String get myShareUntitledEntry;

  /// No description provided for @myShareFromOwner.
  ///
  /// In en, this message translates to:
  /// **'From {owner}'**
  String myShareFromOwner(Object owner);

  /// No description provided for @myShareOutgoingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shared with {recipient} · {date}'**
  String myShareOutgoingSubtitle(Object date, Object recipient);

  /// No description provided for @myShareIncomingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From {owner} · {date}'**
  String myShareIncomingSubtitle(Object date, Object owner);

  /// No description provided for @myShareCopyFieldTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy {field}'**
  String myShareCopyFieldTooltip(Object field);

  /// No description provided for @myShareCopiedField.
  ///
  /// In en, this message translates to:
  /// **'Copied {field}'**
  String myShareCopiedField(Object field);

  /// No description provided for @myShareDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete share'**
  String get myShareDeleteTitle;

  /// No description provided for @myShareDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this share?'**
  String get myShareDeleteConfirm;

  /// No description provided for @myShareDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete'**
  String get myShareDeleteFailed;

  /// No description provided for @mySharesTitle.
  ///
  /// In en, this message translates to:
  /// **'My shares'**
  String get mySharesTitle;

  /// No description provided for @mySharesNeedLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in to OpenValut Cloud first'**
  String get mySharesNeedLogin;

  /// No description provided for @mySharesRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get mySharesRefresh;

  /// No description provided for @mySharesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load shares: {error}'**
  String mySharesLoadFailed(Object error);

  /// No description provided for @mySharesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No shares yet'**
  String get mySharesEmpty;

  /// No description provided for @mySharesByMe.
  ///
  /// In en, this message translates to:
  /// **'Shared by me'**
  String get mySharesByMe;

  /// No description provided for @mySharesToMe.
  ///
  /// In en, this message translates to:
  /// **'Shared with me'**
  String get mySharesToMe;

  /// No description provided for @myShareDeletedEntry.
  ///
  /// In en, this message translates to:
  /// **'Deleted entry'**
  String get myShareDeletedEntry;

  /// No description provided for @myShareGroupBadge.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get myShareGroupBadge;

  /// No description provided for @myShareGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Group · {count} entries · From {owner} · {date}'**
  String myShareGroupSubtitle(Object count, Object date, Object owner);

  /// No description provided for @myShareGroupSyncAction.
  ///
  /// In en, this message translates to:
  /// **'Sync to my vault'**
  String get myShareGroupSyncAction;

  /// No description provided for @myShareGroupSyncedCount.
  ///
  /// In en, this message translates to:
  /// **'Synced {count} group shares to the vault'**
  String myShareGroupSyncedCount(Object count);

  /// No description provided for @myShareGroupEmpty.
  ///
  /// In en, this message translates to:
  /// **'This group share has no entries yet.'**
  String get myShareGroupEmpty;

  /// No description provided for @importUntitledEntry.
  ///
  /// In en, this message translates to:
  /// **'Unnamed entry'**
  String get importUntitledEntry;

  /// No description provided for @importReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to read: {error}'**
  String importReadFailed(Object error);

  /// No description provided for @importCsvEmptyOrInvalid.
  ///
  /// In en, this message translates to:
  /// **'The CSV file is empty or has an invalid format'**
  String get importCsvEmptyOrInvalid;

  /// No description provided for @importPasswordWrongTitle.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get importPasswordWrongTitle;

  /// No description provided for @importPasswordWrongBody.
  ///
  /// In en, this message translates to:
  /// **'Wrong KDBX file password. Please try again.'**
  String get importPasswordWrongBody;

  /// No description provided for @importNeedCloudVault.
  ///
  /// In en, this message translates to:
  /// **'Open an OpenValut Cloud vault first'**
  String get importNeedCloudVault;

  /// No description provided for @importReadonlyVaultWarning.
  ///
  /// In en, this message translates to:
  /// **'This vault was opened with a remembered key (read-only). Lock the app, reopen the vault with the master password, then import again.'**
  String get importReadonlyVaultWarning;

  /// No description provided for @importKdbxPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter KDBX file password'**
  String get importKdbxPasswordTitle;

  /// No description provided for @importPasswordLabelForFile.
  ///
  /// In en, this message translates to:
  /// **'Password ({fileName})'**
  String importPasswordLabelForFile(Object fileName);

  /// No description provided for @importDoneCount.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} entries'**
  String importDoneCount(Object count);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(Object error);

  /// No description provided for @importReselectAction.
  ///
  /// In en, this message translates to:
  /// **'Choose again'**
  String get importReselectAction;

  /// No description provided for @importSourcePickerIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose a source. After reading it, select the entries to import into the currently open OpenValut Cloud vault.'**
  String get importSourcePickerIntro;

  /// No description provided for @importSource1PasswordCsvSubtitle.
  ///
  /// In en, this message translates to:
  /// **'CSV file exported from 1Password'**
  String get importSource1PasswordCsvSubtitle;

  /// No description provided for @importSourceKdbxTitle.
  ///
  /// In en, this message translates to:
  /// **'KDBX file'**
  String get importSourceKdbxTitle;

  /// No description provided for @importSourceKdbxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'.kdbx exported from KeePass or other vaults'**
  String get importSourceKdbxSubtitle;

  /// No description provided for @importReadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Reading…'**
  String get importReadingEllipsis;

  /// No description provided for @importSelectFileAndRead.
  ///
  /// In en, this message translates to:
  /// **'Choose file and read'**
  String get importSelectFileAndRead;

  /// No description provided for @importSelectAllCount.
  ///
  /// In en, this message translates to:
  /// **'Select all ({count} entries)'**
  String importSelectAllCount(Object count);

  /// No description provided for @importSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String importSelectedCount(Object count);

  /// No description provided for @importImportingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get importImportingEllipsis;

  /// No description provided for @importImportSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'Import the {count} selected entries'**
  String importImportSelectedCount(Object count);

  /// No description provided for @fieldNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get fieldNotesLabel;

  /// No description provided for @masterChangeLockedFirst.
  ///
  /// In en, this message translates to:
  /// **'Lock the vault and reopen it with the master password before changing it.'**
  String get masterChangeLockedFirst;

  /// No description provided for @scanLoginNeedAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your OpenValut Cloud account first, then use scan-to-sign-in.'**
  String get scanLoginNeedAccount;

  /// No description provided for @scanLoginNotOpenvalutQr.
  ///
  /// In en, this message translates to:
  /// **'Not an OpenValut sign-in QR code. Scan the QR code shown on the PC sign-in page.'**
  String get scanLoginNotOpenvalutQr;

  /// No description provided for @scanLoginConfirmedNoKey.
  ///
  /// In en, this message translates to:
  /// **'Confirmed. The PC will sign in automatically (no master password was sent; enter it on the PC).'**
  String get scanLoginConfirmedNoKey;

  /// No description provided for @scanLoginConfirmedUnlock.
  ///
  /// In en, this message translates to:
  /// **'Confirmed. The PC will sign in and unlock the vault automatically.'**
  String get scanLoginConfirmedUnlock;

  /// No description provided for @scanLoginConfirmFailed.
  ///
  /// In en, this message translates to:
  /// **'Confirmation failed: {error}'**
  String scanLoginConfirmFailed(Object error);

  /// No description provided for @scanLoginEnterMasterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the vault master password'**
  String get scanLoginEnterMasterTitle;

  /// No description provided for @scanLoginMasterLabel.
  ///
  /// In en, this message translates to:
  /// **'Master password'**
  String get scanLoginMasterLabel;

  /// No description provided for @scanLoginMasterHint.
  ///
  /// In en, this message translates to:
  /// **'Used to authorize direct unlock on the PC'**
  String get scanLoginMasterHint;

  /// No description provided for @pickerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search app name or package'**
  String get pickerSearchHint;

  /// No description provided for @pickerNoMatchingApps.
  ///
  /// In en, this message translates to:
  /// **'No matching apps found'**
  String get pickerNoMatchingApps;

  /// No description provided for @twoFactorNoOpenVault.
  ///
  /// In en, this message translates to:
  /// **'No vault is open'**
  String get twoFactorNoOpenVault;

  /// No description provided for @twoFactorNoUsername.
  ///
  /// In en, this message translates to:
  /// **'Could not determine the current system username'**
  String get twoFactorNoUsername;

  /// No description provided for @twoFactorNoMachineId.
  ///
  /// In en, this message translates to:
  /// **'Could not determine this computer\'s identifier'**
  String get twoFactorNoMachineId;

  /// No description provided for @twoFactorEmptySudoPassword.
  ///
  /// In en, this message translates to:
  /// **'sudo password cannot be empty'**
  String get twoFactorEmptySudoPassword;

  /// No description provided for @twoFactorTotpFileWriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not write the encrypted TOTP file (missing machine-id or home directory)'**
  String get twoFactorTotpFileWriteFailed;

  /// No description provided for @twoFactorSystemSetupIncomplete.
  ///
  /// In en, this message translates to:
  /// **'System setup incomplete: {detail}'**
  String twoFactorSystemSetupIncomplete(Object detail);

  /// No description provided for @twoFactorConfiguredDone.
  ///
  /// In en, this message translates to:
  /// **'Two-step verification for this computer is configured; sudo will now ask for a one-time code.'**
  String get twoFactorConfiguredDone;

  /// No description provided for @twoFactorConfigFailed.
  ///
  /// In en, this message translates to:
  /// **'Configuration failed: {error}'**
  String twoFactorConfigFailed(Object error);

  /// No description provided for @twoFactorIdentityMissing.
  ///
  /// In en, this message translates to:
  /// **'Could not determine username/home directory/computer identifier'**
  String get twoFactorIdentityMissing;

  /// No description provided for @twoFactorUserCancelled.
  ///
  /// In en, this message translates to:
  /// **'User cancelled or authentication failed'**
  String get twoFactorUserCancelled;

  /// No description provided for @twoFactorTotpFileDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the TOTP file ({localError}), and system cleanup failed ({systemError})'**
  String twoFactorTotpFileDeleteFailed(Object localError, Object systemError);

  /// No description provided for @twoFactorDisabledPamFailed.
  ///
  /// In en, this message translates to:
  /// **'Two-step verification is off (sudo no longer asks for a code), but the PAM line in /etc/pam.d/sudo could not be removed.'**
  String get twoFactorDisabledPamFailed;

  /// No description provided for @twoFactorDisabledDone.
  ///
  /// In en, this message translates to:
  /// **'System two-step verification is off; sudo no longer asks for a one-time code.'**
  String get twoFactorDisabledDone;

  /// No description provided for @twoFactorAssetReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the bundled PAM module/askpass file: {error}'**
  String twoFactorAssetReadFailed(Object error);

  /// No description provided for @twoFactorPkexecFailed.
  ///
  /// In en, this message translates to:
  /// **'pkexec did not complete (exit code {code}): {message}'**
  String twoFactorPkexecFailed(Object code, Object message);

  /// No description provided for @sshKeysAlreadyImported.
  ///
  /// In en, this message translates to:
  /// **'These SSH keys are already in the vault; no need to import them again.'**
  String get sshKeysAlreadyImported;

  /// No description provided for @sshSkippedAlreadyImported.
  ///
  /// In en, this message translates to:
  /// **'Already imported, skipped'**
  String get sshSkippedAlreadyImported;

  /// No description provided for @openFileFailedLabel.
  ///
  /// In en, this message translates to:
  /// **'Failed to open file'**
  String get openFileFailedLabel;

  /// No description provided for @untitledLabel.
  ///
  /// In en, this message translates to:
  /// **'Unnamed'**
  String get untitledLabel;

  /// No description provided for @trayShowOpenvalut.
  ///
  /// In en, this message translates to:
  /// **'Show OpenValut'**
  String get trayShowOpenvalut;

  /// No description provided for @trayQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get trayQuit;

  /// No description provided for @appAlreadyRunningMessage.
  ///
  /// In en, this message translates to:
  /// **'OpenValut is already running (it may be minimized to the tray). Right-click the tray icon and choose Quit, then try again.'**
  String get appAlreadyRunningMessage;

  /// No description provided for @lockedChooseAnotherVault.
  ///
  /// In en, this message translates to:
  /// **'Choose another vault'**
  String get lockedChooseAnotherVault;

  /// No description provided for @offlineBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'You are currently offline'**
  String get offlineBannerTitle;

  /// No description provided for @selectFileOpenLocalFile.
  ///
  /// In en, this message translates to:
  /// **'Open local file'**
  String get selectFileOpenLocalFile;

  /// No description provided for @enableFingerprintQuestion.
  ///
  /// In en, this message translates to:
  /// **'Enable fingerprint authentication?'**
  String get enableFingerprintQuestion;

  /// No description provided for @enableFingerprintDescription.
  ///
  /// In en, this message translates to:
  /// **'Once enabled, you can unlock vaults with your fingerprint instead of entering the master password.'**
  String get enableFingerprintDescription;

  /// No description provided for @enableFingerprintAction.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enableFingerprintAction;

  /// No description provided for @cloudUnlockFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not unlock the cloud vault'**
  String get cloudUnlockFailedTitle;

  /// No description provided for @cloudUnlockFailedDescription.
  ///
  /// In en, this message translates to:
  /// **'Cloud data could not be decrypted: the master password may be wrong, or the vault was created on another device with a different master password.'**
  String get cloudUnlockFailedDescription;

  /// No description provided for @menuImportPasswords.
  ///
  /// In en, this message translates to:
  /// **'Import passwords'**
  String get menuImportPasswords;

  /// No description provided for @menuExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get menuExportCsv;

  /// No description provided for @menuScanLogin.
  ///
  /// In en, this message translates to:
  /// **'Scan code to sign in'**
  String get menuScanLogin;

  /// No description provided for @menuAboutOpenvalut.
  ///
  /// In en, this message translates to:
  /// **'About OpenValut'**
  String get menuAboutOpenvalut;

  /// No description provided for @menuAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get menuAbout;

  /// No description provided for @menuAuthorName.
  ///
  /// In en, this message translates to:
  /// **'OpenValut Contributors'**
  String get menuAuthorName;

  /// No description provided for @menuEmailPrefix.
  ///
  /// In en, this message translates to:
  /// **'Email: '**
  String get menuEmailPrefix;

  /// No description provided for @menuBlogPrefix.
  ///
  /// In en, this message translates to:
  /// **'Blog: '**
  String get menuBlogPrefix;

  /// No description provided for @menuExportedCsvTitle.
  ///
  /// In en, this message translates to:
  /// **'Exported'**
  String get menuExportedCsvTitle;

  /// No description provided for @menuExportedAllCsv.
  ///
  /// In en, this message translates to:
  /// **'All entries were exported as CSV.'**
  String get menuExportedAllCsv;

  /// No description provided for @menuExportFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get menuExportFailedTitle;

  /// No description provided for @copyUsernameAction.
  ///
  /// In en, this message translates to:
  /// **'Copy username'**
  String get copyUsernameAction;

  /// No description provided for @renameEntryDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename entry'**
  String get renameEntryDialogTitle;

  /// No description provided for @newNameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get newNameFieldLabel;

  /// No description provided for @restoredSnack.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get restoredSnack;

  /// No description provided for @deletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deletedSnack;

  /// No description provided for @undoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoAction;

  /// No description provided for @shareWithFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Share with family'**
  String get shareWithFamilyTitle;

  /// No description provided for @shareRecipientEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipient\'s OpenValut Cloud email'**
  String get shareRecipientEmailLabel;

  /// No description provided for @shareRecipientEmailHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. family@example.com'**
  String get shareRecipientEmailHint;

  /// No description provided for @shareTargetLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to OpenValut Cloud first (Select Vault screen → OpenValut Cloud).'**
  String get shareTargetLoginRequired;

  /// No description provided for @shareRequiresCloudVault.
  ///
  /// In en, this message translates to:
  /// **'Only entries in an OpenValut Cloud vault can be shared.'**
  String get shareRequiresCloudVault;

  /// No description provided for @sharedToRecipient.
  ///
  /// In en, this message translates to:
  /// **'Shared with {recipient}'**
  String sharedToRecipient(Object recipient);

  /// No description provided for @shareUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find user {recipient}. Make sure they registered and signed in to OpenValut Cloud.'**
  String shareUserNotFound(Object recipient);

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Share failed'**
  String get shareFailed;

  /// No description provided for @shareFailedDetail.
  ///
  /// In en, this message translates to:
  /// **'Sharing failed: {detail}'**
  String shareFailedDetail(Object detail);

  /// No description provided for @shareGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Share whole group'**
  String get shareGroupTitle;

  /// No description provided for @shareGroupActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Share whole group…'**
  String get shareGroupActionLabel;

  /// No description provided for @shareGroupRequiresCloudVault.
  ///
  /// In en, this message translates to:
  /// **'Only groups in an OpenValut Cloud vault can be shared as a whole group.'**
  String get shareGroupRequiresCloudVault;

  /// No description provided for @shareGroupSelfNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'You cannot share a group with yourself.'**
  String get shareGroupSelfNotAllowed;

  /// No description provided for @shareGroupRecipientRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the recipient\'s OpenValut Cloud email.'**
  String get shareGroupRecipientRequired;

  /// No description provided for @shareGroupAlreadyShared.
  ///
  /// In en, this message translates to:
  /// **'This group is already shared with {recipient}.'**
  String shareGroupAlreadyShared(Object recipient);

  /// No description provided for @sharedGroupToRecipient.
  ///
  /// In en, this message translates to:
  /// **'Shared group \"{group}\" with {recipient}. Future changes stay in sync automatically.'**
  String sharedGroupToRecipient(Object group, Object recipient);

  /// No description provided for @drawerAllEntries.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get drawerAllEntries;

  /// No description provided for @drawerRecycleBin.
  ///
  /// In en, this message translates to:
  /// **'Recycle bin'**
  String get drawerRecycleBin;

  /// No description provided for @drawerMyShares.
  ///
  /// In en, this message translates to:
  /// **'My shares'**
  String get drawerMyShares;

  /// No description provided for @drawerGroupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get drawerGroupNameLabel;

  /// No description provided for @renameGroupDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename group'**
  String get renameGroupDialogTitle;

  /// No description provided for @cliReadAllowTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow CLI/script read access'**
  String get cliReadAllowTitle;

  /// No description provided for @cliReadAllowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Entries in this group (including subgroups) are hidden from CLI/scripts by default. Allow all of them now.'**
  String get cliReadAllowSubtitle;

  /// No description provided for @cliReadDenyTitle.
  ///
  /// In en, this message translates to:
  /// **'Deny CLI/script read access'**
  String get cliReadDenyTitle;

  /// No description provided for @cliReadDenySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore the default: entries in this group are hidden from CLI/scripts.'**
  String get cliReadDenySubtitle;

  /// No description provided for @cliReadGroupAllAllowed.
  ///
  /// In en, this message translates to:
  /// **'All entries in this group are now readable by CLI/scripts'**
  String get cliReadGroupAllAllowed;

  /// No description provided for @cliReadGroupAllowedCount.
  ///
  /// In en, this message translates to:
  /// **'Allowed {count} entries to be read by CLI/scripts (takes effect after saving)'**
  String cliReadGroupAllowedCount(Object count);

  /// No description provided for @cliReadGroupAllDenied.
  ///
  /// In en, this message translates to:
  /// **'All entries in this group are now hidden from CLI/scripts'**
  String get cliReadGroupAllDenied;

  /// No description provided for @cliReadGroupDeniedCount.
  ///
  /// In en, this message translates to:
  /// **'Denied CLI/script access to {count} entries (takes effect after saving)'**
  String cliReadGroupDeniedCount(Object count);

  /// No description provided for @organizeByCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Organize by category'**
  String get organizeByCategoryTitle;

  /// No description provided for @organizeByCategoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Move root-level entries into Website / App / Other / Finance groups (created automatically if missing), then save to the server. Continue?'**
  String get organizeByCategoryDescription;

  /// No description provided for @organizeAction.
  ///
  /// In en, this message translates to:
  /// **'Organize'**
  String get organizeAction;

  /// No description provided for @organizeDoneCount.
  ///
  /// In en, this message translates to:
  /// **'Organized {count} entries'**
  String organizeDoneCount(Object count);

  /// No description provided for @groupListNewGroup.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get groupListNewGroup;

  /// Sidebar group that lists every entry whose password is detected as weak.
  ///
  /// In en, this message translates to:
  /// **'Weak passwords'**
  String get weakPasswordsLabel;

  /// No description provided for @allowCliRead.
  ///
  /// In en, this message translates to:
  /// **'Allow CLI/script read access'**
  String get allowCliRead;

  /// No description provided for @denyCliRead.
  ///
  /// In en, this message translates to:
  /// **'Deny CLI/script read access'**
  String get denyCliRead;

  /// No description provided for @entryAllowCliRead.
  ///
  /// In en, this message translates to:
  /// **'Allow CLI/script read access'**
  String get entryAllowCliRead;

  /// No description provided for @entryAllowCliReadDescription.
  ///
  /// In en, this message translates to:
  /// **'Read access is denied by default. Enabling it lets openvalut-cli list/get and the local credential service read this entry.'**
  String get entryAllowCliReadDescription;

  /// No description provided for @entryAddWebsite.
  ///
  /// In en, this message translates to:
  /// **'Add website'**
  String get entryAddWebsite;

  ///
  ///
  /// In en, this message translates to:
  /// **'Add Attachment'**
  String get entryAddAttachment;

  /// No description provided for @entryAddSpecialField.
  ///
  /// In en, this message translates to:
  /// **'Add field'**
  String get entryAddSpecialField;

  /// No description provided for @entryPasswordExpired.
  ///
  /// In en, this message translates to:
  /// **'This password expired {days} days ago. Change it soon.'**
  String entryPasswordExpired(Object days);

  /// No description provided for @entryPasswordExpires.
  ///
  /// In en, this message translates to:
  /// **'This password expires in {remaining} days. Change it soon.'**
  String entryPasswordExpires(Object remaining);

  /// No description provided for @entryLinkApp.
  ///
  /// In en, this message translates to:
  /// **'Associated app'**
  String get entryLinkApp;

  /// No description provided for @entryTargetWebsite.
  ///
  /// In en, this message translates to:
  /// **'Target website {number}'**
  String entryTargetWebsite(Object number);

  /// No description provided for @entryPickAppTooltip.
  ///
  /// In en, this message translates to:
  /// **'Choose the app to associate'**
  String get entryPickAppTooltip;

  /// No description provided for @entryPasteReference.
  ///
  /// In en, this message translates to:
  /// **'Copied reference: {reference}'**
  String entryPasteReference(Object reference);

  /// No description provided for @entryCopyReferenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy reference'**
  String get entryCopyReferenceTitle;

  /// No description provided for @masterPasswordExpiredBanner.
  ///
  /// In en, this message translates to:
  /// **'The master password expired {days} days ago. Change it soon.'**
  String masterPasswordExpiredBanner(Object days);

  /// No description provided for @masterPasswordExpiresBanner.
  ///
  /// In en, this message translates to:
  /// **'The master password expires in {remaining} days. Change it soon.'**
  String masterPasswordExpiresBanner(Object remaining);

  /// No description provided for @changeMasterPasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Change master password'**
  String get changeMasterPasswordAction;

  /// No description provided for @remindLaterAction.
  ///
  /// In en, this message translates to:
  /// **'Remind me later'**
  String get remindLaterAction;

  /// No description provided for @prefDisablingSystem2fa.
  ///
  /// In en, this message translates to:
  /// **'Disabling system two-step verification…'**
  String get prefDisablingSystem2fa;

  /// No description provided for @prefTwoFactorDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get prefTwoFactorDisabled;

  /// No description provided for @prefTwoFactorDisableFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to disable'**
  String get prefTwoFactorDisableFailed;

  /// No description provided for @prefNeedUnlockedVaultForAutoConfig.
  ///
  /// In en, this message translates to:
  /// **'Open and unlock a vault first, then enable automatic setup.'**
  String get prefNeedUnlockedVaultForAutoConfig;

  /// No description provided for @prefConfiguringSystem2fa.
  ///
  /// In en, this message translates to:
  /// **'Configuring two-step verification for this computer…'**
  String get prefConfiguringSystem2fa;

  /// No description provided for @prefTwoFactorConfigured.
  ///
  /// In en, this message translates to:
  /// **'Setup complete'**
  String get prefTwoFactorConfigured;

  /// No description provided for @prefTwoFactorConfigFailed.
  ///
  /// In en, this message translates to:
  /// **'Setup failed'**
  String get prefTwoFactorConfigFailed;

  /// No description provided for @prefSystemPasswordDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter system login password'**
  String get prefSystemPasswordDialogTitle;

  /// No description provided for @prefSudoPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'sudo password'**
  String get prefSudoPasswordLabel;

  /// No description provided for @prefSudoPasswordHelper.
  ///
  /// In en, this message translates to:
  /// **'Used to save a Computer entry and protect two-step verification'**
  String get prefSudoPasswordHelper;

  /// No description provided for @prefRememberMasterPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Remember master password'**
  String get prefRememberMasterPasswordTitle;

  /// No description provided for @prefRememberOffEveryLogin.
  ///
  /// In en, this message translates to:
  /// **'Off (enter the master password each time)'**
  String get prefRememberOffEveryLogin;

  /// No description provided for @prefDaysPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String prefDaysPlaceholder(Object days);

  /// No description provided for @prefCloudServiceNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'OpenValut Cloud service is not configured'**
  String get prefCloudServiceNotConfigured;

  /// No description provided for @prefUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You are up to date'**
  String get prefUpToDate;

  /// No description provided for @prefNewVersionAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'New version {versionName} available'**
  String prefNewVersionAvailableTitle(Object versionName);

  /// No description provided for @prefUpdateNowQuestion.
  ///
  /// In en, this message translates to:
  /// **'A new version is available. Update now?'**
  String get prefUpdateNowQuestion;

  /// No description provided for @prefUpdateLaterAction.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get prefUpdateLaterAction;

  /// No description provided for @prefUpdateNowAction.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get prefUpdateNowAction;

  /// No description provided for @prefNewVersionDownloadedTitle.
  ///
  /// In en, this message translates to:
  /// **'New version downloaded'**
  String get prefNewVersionDownloadedTitle;

  /// No description provided for @prefInstallManuallyBody.
  ///
  /// In en, this message translates to:
  /// **'Installer saved to:\n{path}\n\nInstall it manually from that folder.\nLinux example:\n{installHint}'**
  String prefInstallManuallyBody(Object installHint, Object path);

  /// No description provided for @prefGotItAction.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get prefGotItAction;

  /// No description provided for @prefUpdateCheckFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to check for updates: {error}'**
  String prefUpdateCheckFailedTitle(Object error);

  /// No description provided for @prefClipboardAutoClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear clipboard automatically'**
  String get prefClipboardAutoClearTitle;

  /// No description provided for @prefClipboardAutoClearSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear the system clipboard after copying a password or username'**
  String get prefClipboardAutoClearSubtitle;

  /// No description provided for @prefOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get prefOff;

  /// No description provided for @prefSecondsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String prefSecondsPlaceholder(Object seconds);

  /// No description provided for @prefZeroDisablesAutoClear.
  ///
  /// In en, this message translates to:
  /// **'0 disables automatic clearing'**
  String get prefZeroDisablesAutoClear;

  /// No description provided for @prefCloseWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'When closing the window'**
  String get prefCloseWindowTitle;

  /// No description provided for @prefCloseWindowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what the close button does'**
  String get prefCloseWindowSubtitle;

  /// No description provided for @prefHideToTrayRunning.
  ///
  /// In en, this message translates to:
  /// **'Hide to tray (app keeps running)'**
  String get prefHideToTrayRunning;

  /// No description provided for @prefMinimizeToTaskbarRunning.
  ///
  /// In en, this message translates to:
  /// **'Minimize to taskbar (app keeps running)'**
  String get prefMinimizeToTaskbarRunning;

  /// No description provided for @prefQuitApplication.
  ///
  /// In en, this message translates to:
  /// **'Quit app'**
  String get prefQuitApplication;

  /// No description provided for @prefHideToTray.
  ///
  /// In en, this message translates to:
  /// **'Hide to tray'**
  String get prefHideToTray;

  /// No description provided for @prefMinimizeToTaskbar.
  ///
  /// In en, this message translates to:
  /// **'Minimize to taskbar'**
  String get prefMinimizeToTaskbar;

  /// No description provided for @prefSshConfigAppendPreview.
  ///
  /// In en, this message translates to:
  /// **'Appending to the end of ~/.ssh/config:\n\n'**
  String get prefSshConfigAppendPreview;

  /// No description provided for @prefNotEnabledStatus.
  ///
  /// In en, this message translates to:
  /// **'Not enabled'**
  String get prefNotEnabledStatus;

  /// No description provided for @prefReminderNoChangeDate.
  ///
  /// In en, this message translates to:
  /// **'Remind every {days} days (no change date recorded yet)'**
  String prefReminderNoChangeDate(Object days);

  /// No description provided for @prefReminderExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired {days} days ago — change it soon'**
  String prefReminderExpired(Object days);

  /// No description provided for @prefReminderEvery.
  ///
  /// In en, this message translates to:
  /// **'Remind every {days} days, {remaining} days left'**
  String prefReminderEvery(Object days, Object remaining);

  /// No description provided for @prefLoadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get prefLoadingEllipsis;

  /// No description provided for @prefAlwaysShowSidePanel.
  ///
  /// In en, this message translates to:
  /// **'Always show side panel'**
  String get prefAlwaysShowSidePanel;

  /// No description provided for @prefAlwaysShowSidePanelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the category panel visible; when off it collapses when you click elsewhere'**
  String get prefAlwaysShowSidePanelSubtitle;

  /// No description provided for @prefCheckForUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check for and download new OpenValut Cloud releases'**
  String get prefCheckForUpdatesSubtitle;

  /// No description provided for @prefRememberMasterPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open vaults without re-entering the master password during this period'**
  String get prefRememberMasterPasswordSubtitle;

  /// No description provided for @prefStartAtLogin.
  ///
  /// In en, this message translates to:
  /// **'Start on login'**
  String get prefStartAtLogin;

  /// No description provided for @prefStartAtLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start OpenValut and hide it to the tray after login'**
  String get prefStartAtLoginSubtitle;

  /// No description provided for @prefFingerprintUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock with fingerprint'**
  String get prefFingerprintUnlock;

  /// No description provided for @prefFingerprintUnlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use a fingerprint to unlock quickly without the master password'**
  String get prefFingerprintUnlockSubtitle;

  /// No description provided for @prefAutoTwoFactorTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically configure two-step verification'**
  String get prefAutoTwoFactorTitle;

  /// No description provided for @prefAutoTwoFactorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Saves this computer\'s username/password/TOTP and configures two-step verification for sudo (PAM module, askpass and /etc/pam.d/sudo)'**
  String get prefAutoTwoFactorSubtitle;

  /// No description provided for @prefImportSshSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import private keys from ~/.ssh into the vault and mark them for this computer'**
  String get prefImportSshSubtitle;

  /// No description provided for @prefImportedSshKeys.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} SSH keys'**
  String prefImportedSshKeys(Object count);

  /// No description provided for @prefPasswordChangeReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Password change reminder'**
  String get prefPasswordChangeReminderTitle;

  /// No description provided for @fieldUserName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get fieldUserName;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @fieldWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get fieldWebsite;

  /// No description provided for @fieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get fieldTitle;

  /// Label for fields of TOTP (Time based one time passwords)
  ///
  /// In en, this message translates to:
  /// **'One Time Password (Time Based)'**
  String get fieldTotp;

  /// language switcher subtitle
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// language switcher subtitle
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// language switcher subtitle
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// language switcher subtitle
  ///
  /// In en, this message translates to:
  /// **'Ukrainian'**
  String get ukrainian;

  /// language switcher subtitle
  ///
  /// In en, this message translates to:
  /// **'Lithuanian'**
  String get lithuanian;

  /// language switcher subtitle
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// language switcher subtitle
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// language switcher subtitle
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get indonesian;

  /// Language switcher subtitle
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get turkish;

  /// Language switcher subtitle
  ///
  /// In en, this message translates to:
  /// **'Hebrew'**
  String get hebrew;

  /// Language switcher subtitle
  ///
  /// In en, this message translates to:
  /// **'italian'**
  String get italian;

  /// Language switcher subtitle
  ///
  /// In en, this message translates to:
  /// **'Chinese Simplified'**
  String get chineseSimplified;

  /// Language switcher subtitle
  ///
  /// In en, this message translates to:
  /// **'Chinese Traditional'**
  String get chineseTraditional;

  /// Language switcher subtitle
  ///
  /// In en, this message translates to:
  /// **'Portuguese, Brazilian'**
  String get portugueseBrazilian;

  /// Language switcher subtitle
  ///
  /// In en, this message translates to:
  /// **'Slovak'**
  String get slovak;

  /// Language switcher subtitle
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get dutch;

  /// semantic label for checkboxes to select item.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectItem;

  /// No description provided for @selectKeepassFile.
  ///
  /// In en, this message translates to:
  /// **'OpenValut - Select KeePass File'**
  String get selectKeepassFile;

  /// No description provided for @selectKeepassFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Please select a KeePass (.kdbx) file.'**
  String get selectKeepassFileLabel;

  /// button on select file screen to create a new password database.
  ///
  /// In en, this message translates to:
  /// **'Create New File'**
  String get createNewFile;

  /// No description provided for @openLocalFile.
  ///
  /// In en, this message translates to:
  /// **'Open\nLocal File'**
  String get openLocalFile;

  /// Displayed as placeholder in password list when no file is open.
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get openFile;

  /// label for dropdown menu which shows more cloud storage options.
  ///
  /// In en, this message translates to:
  /// **'Load from …'**
  String get loadFromDropdownMenu;

  /// Status shown while we are loading files and trying to unlock them.
  ///
  /// In en, this message translates to:
  /// **'Quick unlocking files …'**
  String get quickUnlockingFiles;

  /// Progress shown while files are loaded during quick unlock.
  ///
  /// In en, this message translates to:
  /// **'Opening {fileName} … ({current} / {totalCount})'**
  String openFileProgress(Object fileName, Object current, Object totalCount);

  /// No description provided for @loadFrom.
  ///
  /// In en, this message translates to:
  /// **'Load from {cloudStorageName}'**
  String loadFrom(String cloudStorageName);

  /// Overflow menu option to load KeePass file from URL.
  ///
  /// In en, this message translates to:
  /// **'Open kdbx from URL'**
  String get loadFromRemoteUrl;

  /// deprecated
  ///
  /// In en, this message translates to:
  /// **'New to KeePass?\nCreate New Password Database'**
  String get createNewKeepass;

  /// No description provided for @labelLastOpenFiles.
  ///
  /// In en, this message translates to:
  /// **'Last opened files:'**
  String get labelLastOpenFiles;

  /// No description provided for @noFilesHaveBeenOpenYet.
  ///
  /// In en, this message translates to:
  /// **'No files have been opened yet.'**
  String get noFilesHaveBeenOpenYet;

  /// No description provided for @preferenceSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get preferenceSelectLanguage;

  /// No description provided for @preferenceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get preferenceLanguage;

  /// No description provided for @preferenceTextScaleFactor.
  ///
  /// In en, this message translates to:
  /// **'Text Scale Factor'**
  String get preferenceTextScaleFactor;

  /// No description provided for @preferenceVisualDensity.
  ///
  /// In en, this message translates to:
  /// **'Visual Density'**
  String get preferenceVisualDensity;

  /// No description provided for @preferenceTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get preferenceTheme;

  /// No description provided for @preferenceThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get preferenceThemeLight;

  /// No description provided for @preferenceThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get preferenceThemeDark;

  /// No description provided for @preferenceSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get preferenceSystemDefault;

  /// No description provided for @preferenceDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get preferenceDefault;

  /// No description provided for @lockAllFiles.
  ///
  /// In en, this message translates to:
  /// **'Lock all open files'**
  String get lockAllFiles;

  /// No description provided for @preferenceAllowScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Allow Screenshots of the App'**
  String get preferenceAllowScreenshots;

  /// No description provided for @preferenceEnableAutoFill.
  ///
  /// In en, this message translates to:
  /// **'Enable autofill'**
  String get preferenceEnableAutoFill;

  /// This text will shown as a banner on top of password list
  ///
  /// In en, this message translates to:
  /// **'You can you can fill field of other application by enabling autofill!'**
  String get enableAutofillSuggestionBanner;

  /// Button that is displayed in autofill suggestion warnings to dismiss the warning
  ///
  /// In en, this message translates to:
  /// **'DISMISS'**
  String get dismissAutofillSuggestionBannerButton;

  /// Button that is displayed in autofill suggestion warnings to enable autofill
  ///
  /// In en, this message translates to:
  /// **'ENABLE!'**
  String get enableAutofillSuggestionBannerButton;

  /// No description provided for @preferenceAutoFillDescription.
  ///
  /// In en, this message translates to:
  /// **'Only supported on Android Oreo (8.0) or later.'**
  String get preferenceAutoFillDescription;

  /// No description provided for @preferenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferenceTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Enable system wide shortcuts'**
  String get preferenceEnableSystemWideShortcuts;

  ///
  ///
  /// In en, this message translates to:
  /// **'Registers ctrl+alt+f as system wide shortcut to open search.'**
  String get preferenceEnableSystemWideShortcutsHelp;

  ///
  ///
  /// In en, this message translates to:
  /// **'Customize Search fields'**
  String get preferencesSearchFields;

  ///
  ///
  /// In en, this message translates to:
  /// **'Search fields'**
  String get preferencesSearchFieldPromptTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Comma separated list of fields to use in the password list search.'**
  String get preferencesSearchFieldPromptLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Use {wildCardCharacter} for all, leave empty for default ({defaultSearchFields})'**
  String preferencesSearchFieldPromptHelp(
    Object wildCardCharacter,
    Object defaultSearchFields,
  );

  /// No description provided for @aboutAppName.
  ///
  /// In en, this message translates to:
  /// **'OpenValut'**
  String get aboutAppName;

  /// No description provided for @aboutLinkFeedback.
  ///
  /// In en, this message translates to:
  /// **'We welcome any kind of feedback!'**
  String get aboutLinkFeedback;

  /// No description provided for @aboutLinkVisitWebsite.
  ///
  /// In en, this message translates to:
  /// **'Also make sure to visit our website'**
  String get aboutLinkVisitWebsite;

  /// No description provided for @aboutLinkGitHub.
  ///
  /// In en, this message translates to:
  /// **'And Open Source Project'**
  String get aboutLinkGitHub;

  /// No description provided for @aboutLogFile.
  ///
  /// In en, this message translates to:
  /// **'Log File: {logFilePath}'**
  String aboutLogFile(String logFilePath);

  /// No description provided for @aboutLinkContributors.
  ///
  /// In en, this message translates to:
  /// **'Show Contributors'**
  String get aboutLinkContributors;

  ///
  ///
  /// In en, this message translates to:
  /// **'Unable to open Url'**
  String get unableToLaunchUrlTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Unable to launch {url}: {openError}'**
  String unableToLaunchUrlDescription(Object url, Object openError);

  ///
  ///
  /// In en, this message translates to:
  /// **'No application available for url.'**
  String get unableToLaunchUrlNoHandler;

  /// snackbar confirmation after opening a url externally
  ///
  /// In en, this message translates to:
  /// **'Opened URL: {url}'**
  String launchedUrl(Object url);

  /// No description provided for @menuItemGeneratePassword.
  ///
  /// In en, this message translates to:
  /// **'Generate Password'**
  String get menuItemGeneratePassword;

  /// No description provided for @menuItemPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get menuItemPreferences;

  /// No description provided for @menuItemOpenAnotherFile.
  ///
  /// In en, this message translates to:
  /// **'Open another File'**
  String get menuItemOpenAnotherFile;

  /// No description provided for @menuItemCheckForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get menuItemCheckForUpdates;

  /// No description provided for @menuItemSupport.
  ///
  /// In en, this message translates to:
  /// **'Send logs'**
  String get menuItemSupport;

  /// No description provided for @menuItemSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send logs by email'**
  String get menuItemSupportSubtitle;

  /// No description provided for @menuItemForum.
  ///
  /// In en, this message translates to:
  /// **'Support Forum'**
  String get menuItemForum;

  /// No description provided for @menuItemForumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Report Problems and get help'**
  String get menuItemForumSubtitle;

  /// No description provided for @menuItemHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get menuItemHelp;

  /// No description provided for @menuItemHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show documentation'**
  String get menuItemHelpSubtitle;

  /// No description provided for @menuItemAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get menuItemAbout;

  /// tooltip for button to open URL/Website of an entry.
  ///
  /// In en, this message translates to:
  /// **'Open URL'**
  String get actionOpenUrl;

  /// Master password input: show password as plain text during input. (shown as tooltip)
  ///
  /// In en, this message translates to:
  /// **'Reveal password'**
  String get passwordPlainText;

  /// Label for generated password
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get generatorPassword;

  /// screen title for password generator
  ///
  /// In en, this message translates to:
  /// **'Generate Password'**
  String get generatePassword;

  /// generic button label for 'Done' action.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButtonLabel;

  /// Button Label for Password generator settings: use as defaults
  ///
  /// In en, this message translates to:
  /// **'Use as Default'**
  String get useAsDefault;

  /// No description provided for @characterSetLowerCase.
  ///
  /// In en, this message translates to:
  /// **'Lowercase (a-z)'**
  String get characterSetLowerCase;

  /// No description provided for @characterSetUpperCase.
  ///
  /// In en, this message translates to:
  /// **'Uppercase (A-Z)'**
  String get characterSetUpperCase;

  /// No description provided for @characterSetNumeric.
  ///
  /// In en, this message translates to:
  /// **'Numeric (0-9)'**
  String get characterSetNumeric;

  /// No description provided for @characterSetUmlauts.
  ///
  /// In en, this message translates to:
  /// **'Umlauts (ä)'**
  String get characterSetUmlauts;

  /// No description provided for @characterSetSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special (@%+)'**
  String get characterSetSpecial;

  /// Length of password
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get length;

  /// Label for custom length field
  ///
  /// In en, this message translates to:
  /// **'Custom Length'**
  String get customLength;

  /// Help text for custom length field
  ///
  /// In en, this message translates to:
  /// **'Only used for length > {customMinLength}'**
  String customLengthHelperText(Object customMinLength);

  /// Message displayed when files were saved. (One or more).
  ///
  /// In en, this message translates to:
  /// **'{numFiles, plural, =1 {One file saved: {files}} other {{numFiles} files saved: {files}}}'**
  String savedFiles(int numFiles, Object files);

  ///
  ///
  /// In en, this message translates to:
  /// **'Manage Groups'**
  String get manageGroups;

  /// Close all files and return to start screen.
  ///
  /// In en, this message translates to:
  /// **'Lock Files'**
  String get lockFiles;

  /// Placeholder in the password list search box
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// search button tooltip/semantic label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchButtonLabel;

  /// tooltip/semantic label for filter app bar icon.
  ///
  /// In en, this message translates to:
  /// **'Filter by group'**
  String get filterButtonLabel;

  /// Remove existing group filter from password list
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Label displayed for android auto fill
  ///
  /// In en, this message translates to:
  /// **'Filter:'**
  String get autofillFilterPrefix;

  /// Label displayed during autofill when the list was narrowed to entries whose URL belongs to the requesting website or app, rather than by a text search. Followed by the domain or app name.
  ///
  /// In en, this message translates to:
  /// **'Matching entries for:'**
  String get autofillMatchPrefix;

  ///
  ///
  /// In en, this message translates to:
  /// **'Select password entry for autofill.'**
  String get autofillPrompt;

  /// Empty state shown in the Android autofill picker when no vault entry matches the requesting website or app.
  ///
  /// In en, this message translates to:
  /// **'No matching entries found for this page.'**
  String get autofillNoMatches;

  /// Empty state shown in the Android autofill picker when every vault is closed.
  ///
  /// In en, this message translates to:
  /// **'No unlocked password database. Open one in OpenValut first, then return to the browser and trigger autofill again.'**
  String get autofillNoOpenVault;

  /// Settings section header for the Android autofill service options.
  ///
  /// In en, this message translates to:
  /// **'Android autofill'**
  String get androidAutofillSection;

  /// Settings row that opens a multi-select list of apps where the Android autofill service must stay silent.
  ///
  /// In en, this message translates to:
  /// **'Never autofill in these apps'**
  String get prefAutofillIgnoredAppsTitle;

  /// Explains the per-app autofill ignore list, including that it also covers password/OTP fields and that the keyboard affordance cannot be removed.
  ///
  /// In en, this message translates to:
  /// **'OpenValut offers nothing in the selected apps, even when they show a password or a verification-code field. Login pages a web view hosts inside such an app are silenced too. The keyboard\'s autofill key stays where it is — tapping it just yields nothing.'**
  String get prefAutofillIgnoredAppsSubtitle;

  /// Trailing label when no app is on the autofill ignore list.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get prefAutofillIgnoredAppsNone;

  /// Trailing label showing how many apps are on the autofill ignore list.
  ///
  /// In en, this message translates to:
  /// **'{count} apps'**
  String prefAutofillIgnoredAppsCount(int count);

  /// Title of the multi-select sheet for the autofill ignore list.
  ///
  /// In en, this message translates to:
  /// **'Apps to ignore'**
  String get prefAutofillIgnoredAppsPickerTitle;

  /// Commit button of the multi-select sheet for the autofill ignore list.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get prefAutofillIgnoredAppsDone;

  /// Clears the whole autofill ignore list selection inside the picker.
  ///
  /// In en, this message translates to:
  /// **'Remove all'**
  String get prefAutofillIgnoredAppsRemoveAll;

  /// Warning title shown before adding a web browser to the autofill ignore list.
  ///
  /// In en, this message translates to:
  /// **'Ignore this browser?'**
  String get prefAutofillIgnoreBrowserTitle;

  /// Warning body explaining that ignoring a browser disables web page autofill, not just app autofill.
  ///
  /// In en, this message translates to:
  /// **'{app} is a browser: while it is ignored, OpenValut will not fill any website in it. This is usually not what you want.'**
  String prefAutofillIgnoreBrowserBody(String app);

  /// Confirm button that adds a browser to the autofill ignore list despite the warning.
  ///
  /// In en, this message translates to:
  /// **'Ignore anyway'**
  String get prefAutofillIgnoreBrowserConfirm;

  /// Checkbox on the vault selection page. Checked: the selection page is shown on every start. Unchecked: OpenValut automatically reopens the last vault instead.
  ///
  /// In en, this message translates to:
  /// **'Show this page every time OpenValut opens'**
  String get showVaultStartPage;

  /// Sidebar category above the recycle bin, containing the weak-passwords group.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityCategoryLabel;

  /// Empty state shown when the weak-passwords filter finds no matching entries.
  ///
  /// In en, this message translates to:
  /// **'No weak passwords detected. Nice.'**
  String get weakPasswordsEmpty;

  /// App bar action that generates an ed25519 key pair and stores it in the current group.
  ///
  /// In en, this message translates to:
  /// **'Generate SSH key pair'**
  String get generateSshKeyPair;

  /// Prompt for the name/comment of a new SSH key.
  ///
  /// In en, this message translates to:
  /// **'Key name'**
  String get sshKeyNameLabel;

  /// Snackbar shown after an SSH key pair was generated.
  ///
  /// In en, this message translates to:
  /// **'SSH key pair generated'**
  String get sshKeyGenerated;

  /// Dialog title when generating an SSH key fails.
  ///
  /// In en, this message translates to:
  /// **'SSH key generation failed'**
  String get sshKeyGenerationFailedTitle;

  /// Name of the vault group that stores SSH keys.
  ///
  /// In en, this message translates to:
  /// **'SSH Keys'**
  String get sshKeysGroupName;

  /// Field name for an OpenSSH private key.
  ///
  /// In en, this message translates to:
  /// **'SSH private key'**
  String get fieldSshPrivateKey;

  /// Field name for an OpenSSH public key.
  ///
  /// In en, this message translates to:
  /// **'SSH public key'**
  String get fieldSshPublicKey;

  /// TCP port used to reach the SSH server stored in this entry.
  ///
  /// In en, this message translates to:
  /// **'SSH port'**
  String get fieldSshPort;

  /// Field name for the Access Key (AK) of an AK/SK credential.
  ///
  /// In en, this message translates to:
  /// **'Access Key ID'**
  String get fieldAccessKey;

  /// Field name for the Secret Key (SK) of an AK/SK credential.
  ///
  /// In en, this message translates to:
  /// **'Secret Access Key'**
  String get fieldSecretKey;

  /// Menu entry that adds an Access Key ID + Secret Access Key pair.
  ///
  /// In en, this message translates to:
  /// **'AK/SK credential'**
  String get entryAddAkskCredential;

  /// Button that adds a special field (TOTP, SSH keys) to an entry.
  ///
  /// In en, this message translates to:
  /// **'Add field'**
  String get addSpecialField;

  /// Menu item that adds a TOTP field.
  ///
  /// In en, this message translates to:
  /// **'One-time password'**
  String get addTotpField;

  /// Dialog title when adding a TOTP field.
  ///
  /// In en, this message translates to:
  /// **'Add one-time password'**
  String get totpSecretPromptTitle;

  /// Prompt label for the TOTP secret input.
  ///
  /// In en, this message translates to:
  /// **'otpauth:// link or base32 secret'**
  String get totpSecretPromptLabel;

  /// Settings section for the SSH agent and the credential server.
  ///
  /// In en, this message translates to:
  /// **'Local services'**
  String get localServicesSection;

  /// Settings toggle for the local SSH agent.
  ///
  /// In en, this message translates to:
  /// **'SSH Agent'**
  String get sshAgentSetting;

  /// Explanation shown under the SSH agent toggle.
  ///
  /// In en, this message translates to:
  /// **'While the vault is unlocked, ssh can use vault keys through IdentityAgent. No private key ever touches disk.'**
  String get sshAgentSettingHelp;

  /// Settings toggle for the local credential server.
  ///
  /// In en, this message translates to:
  /// **'Credential server (openvalut-cli)'**
  String get credentialServerSetting;

  /// Explanation shown under the credential server toggle.
  ///
  /// In en, this message translates to:
  /// **'While the vault is unlocked, openvalut-cli can read usernames, passwords and TOTP codes.'**
  String get credentialServerSettingHelp;

  /// Button that imports private keys from ~/.ssh into the vault.
  ///
  /// In en, this message translates to:
  /// **'Import local SSH keys'**
  String get importSshKeys;

  /// Shown when ~/.ssh contains no OpenSSH private keys.
  ///
  /// In en, this message translates to:
  /// **'No importable SSH keys were found in ~/.ssh.'**
  String get importSshKeysNoneFound;

  /// Confirm button of the SSH key import dialog.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importButton;

  /// Confirmation dialog title after importing SSH keys.
  ///
  /// In en, this message translates to:
  /// **'Delete the local originals?'**
  String get importSshKeysDeleteTitle;

  /// Confirmation dialog body after importing SSH keys.
  ///
  /// In en, this message translates to:
  /// **'The keys were imported into the vault. Delete the original files under ~/.ssh? After deletion they are only usable through the SSH Agent while the vault is unlocked.'**
  String get importSshKeysDeleteBody;

  /// Keep the local files instead of deleting them.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// Confirm deletion of the local key files.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Label for the ssh IdentityAgent config snippet.
  ///
  /// In en, this message translates to:
  /// **'SSH config'**
  String get sshConfigSnippet;

  /// Button that appends the IdentityAgent block to the user ssh config.
  ///
  /// In en, this message translates to:
  /// **'Write to ~/.ssh/config'**
  String get writeSshConfig;

  /// Snackbar after appending the IdentityAgent block.
  ///
  /// In en, this message translates to:
  /// **'SSH config updated.'**
  String get writeSshConfigDone;

  /// Notice shown when the user ssh config already sets IdentityAgent outside the managed block.
  ///
  /// In en, this message translates to:
  /// **'Found an existing IdentityAgent in ~/.ssh/config. ssh uses the first matching value, so the OpenValut reference may not take effect.'**
  String get sshConfigExternalIdentityAgent;

  /// Snackbar after disabling the SSH agent removed the managed config block.
  ///
  /// In en, this message translates to:
  /// **'Removed the OpenValut SSH Agent reference from ~/.ssh/config.'**
  String get sshConfigRemoved;

  /// Snackbar when the managed block already exists.
  ///
  /// In en, this message translates to:
  /// **'The OpenValut SSH Agent reference is already present.'**
  String get sshConfigAlreadyPresent;

  /// Snackbar text when copying text to clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard.'**
  String get copiedToClipboard;

  /// Text to display in place of a title, when password entry has no name assigned.
  ///
  /// In en, this message translates to:
  /// **'(no title)'**
  String get noTitle;

  /// Text to display in place of a user name in the password list if none is defined.
  ///
  /// In en, this message translates to:
  /// **'(no username)'**
  String get noUsername;

  /// Customize filter in password list
  ///
  /// In en, this message translates to:
  /// **'Customize …'**
  String get filterCustomize;

  /// swipe action in password list to copy password
  ///
  /// In en, this message translates to:
  /// **'Copy Password'**
  String get swipeCopyPassword;

  /// swipe action in password list to copy username
  ///
  /// In en, this message translates to:
  /// **'Copy Username'**
  String get swipeCopyUsername;

  /// Error message when trying to copy username from an entry which has none.
  ///
  /// In en, this message translates to:
  /// **'Entry has no username defined.'**
  String get copyUsernameNotExists;

  /// Error message when trying to copy password from an entry which has none.
  ///
  /// In en, this message translates to:
  /// **'Entry has no password defined.'**
  String get copyPasswordNotExists;

  /// snackbar confirmation that password was copied.
  ///
  /// In en, this message translates to:
  /// **'Copied password to clipboard.'**
  String get doneCopiedPassword;

  /// snackbar confirmation that username was copied.
  ///
  /// In en, this message translates to:
  /// **'Copied username to clipboard.'**
  String get doneCopiedUsername;

  ///
  ///
  /// In en, this message translates to:
  /// **'Copied.'**
  String get doneCopiedField;

  ///
  ///
  /// In en, this message translates to:
  /// **'{fieldName} copied.'**
  String copiedFieldToClipboard(Object fieldName);

  /// Displayed when user wants to copy a field which is empty or not defined.
  ///
  /// In en, this message translates to:
  /// **'{fieldName} is empty.'**
  String copiedFieldEmpty(Object fieldName);

  /// Placeholder text shown when a user opens an empty password file.
  ///
  /// In en, this message translates to:
  /// **'You do not have any password in your database yet.'**
  String get emptyPasswordVaultPlaceholder;

  /// Button shown under placeholder text when password database is empty
  ///
  /// In en, this message translates to:
  /// **'Create your first Password'**
  String get emptyPasswordVaultButtonLabel;

  /// generic loading indicator displayed during network request (e.g. when loading file list from cloud storage)
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// credential screen while unlocking file.
  ///
  /// In en, this message translates to:
  /// **'Loading file …'**
  String get loadingFile;

  /// Choose a file previously created in OpenValut app sandbox
  ///
  /// In en, this message translates to:
  /// **'Internal file'**
  String get internalFile;

  /// Choose a file previously created in OpenValut app sandbox
  ///
  /// In en, this message translates to:
  /// **'Database previously created with OpenValut'**
  String get internalFileSubtitle;

  /// Choose a file with the system's file picker. (ios/android)
  ///
  /// In en, this message translates to:
  /// **'File Picker'**
  String get filePicker;

  /// Choose a file with the system's file picker. (ios/android)
  ///
  /// In en, this message translates to:
  /// **'Open file from the device.'**
  String get filePickerSubtitle;

  /// Credential screen to enter master password when opening kdbx file.
  ///
  /// In en, this message translates to:
  /// **'Credentials'**
  String get credentialsAppBarTitle;

  /// Label for the file/database being opened
  ///
  /// In en, this message translates to:
  /// **'Enter the password for:'**
  String get credentialLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get masterPasswordInputLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get masterPasswordEmptyValidator;

  ///
  ///
  /// In en, this message translates to:
  /// **'Invalid password'**
  String get masterPasswordIncorrectValidator;

  /// label for a key file in combination with mater password
  ///
  /// In en, this message translates to:
  /// **'Use Key File'**
  String get useKeyFile;

  /// Label for the checkbox to save master password for quick unlock.
  ///
  /// In en, this message translates to:
  /// **'Save Password with biometric key store?'**
  String get saveMasterPasswordBiometric;

  /// Tooltip/semantic label for close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Tooltip for adding new password button (floating action button)
  ///
  /// In en, this message translates to:
  /// **'Add New Password'**
  String get addNewPassword;

  /// Title of error dialog when trying to open an invalid/unsupported file type
  ///
  /// In en, this message translates to:
  /// **'Tried to open invalid file type'**
  String get errorOpenFileInvalidFileStructureTitle;

  /// Body of error dialog when trying to open an invalid/unsupported file type
  ///
  /// In en, this message translates to:
  /// **'The file ({fileName}) does not appear to be a valid KDBX file. Please either choose a valid KDBX file or create a new password database.'**
  String errorOpenFileInvalidFileStructureBody(Object fileName);

  /// Trying to open a database from a second file source which is already open.
  ///
  /// In en, this message translates to:
  /// **'File already open'**
  String get errorOpenFileAlreadyOpenTitle;

  /// Trying to open a database from a second file source which is already open.
  ///
  /// In en, this message translates to:
  /// **'The selected database {databaseName} is already open from {openFileSource} (Tried to open from {newFileSource})'**
  String errorOpenFileAlreadyOpenBody(
    Object databaseName,
    Object openFileSource,
    Object newFileSource,
  );

  ///
  ///
  /// In en, this message translates to:
  /// **'Download from Url'**
  String get loadFromUrl;

  /// label for input box to enter url.
  ///
  /// In en, this message translates to:
  /// **'Enter URL'**
  String get loadFromUrlEnterUrl;

  /// validator error message when user does not enter a absolute url.
  ///
  /// In en, this message translates to:
  /// **'Please enter full url starting with http:// or https://'**
  String get loadFromUrlErrorEnterFullUrl;

  /// validator error message hwen user enters a url which could not be parsed.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid url.'**
  String get loadFromUrlErrorInvalidUrl;

  /// On linux when user has not given OpenValut permission to connect to secret service he has to execute a command on the console.
  ///
  /// In en, this message translates to:
  /// **'OpenValut requires permission to communicate with Secret Service to store credentials for cloud storage.\nPlease run the following command:'**
  String get linuxAppArmorWarning;

  /// button label for cancelling an action.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// error title when user selects a file which can't be downloaded.
  ///
  /// In en, this message translates to:
  /// **'Error while opening file.'**
  String get errorLoadFileFromSourceTitle;

  /// error body when user selects a file which can't be downloaded.
  ///
  /// In en, this message translates to:
  /// **'Unable to open {source}.\n{error}'**
  String errorLoadFileFromSourceBody(Object source, Object error);

  /// generic error when opening a file (dialog title)
  ///
  /// In en, this message translates to:
  /// **'Unable to open File'**
  String get errorUnlockFileTitle;

  /// generic error when opening a file (description)
  ///
  /// In en, this message translates to:
  /// **'Unknown error while trying to open file. {error}'**
  String errorUnlockFileBody(Object error);

  /// Dialog action to continue to next step (e.g. credential screen when finished with master password)
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get dialogContinue;

  /// action button in error dialogs to send email to support with log file.
  ///
  /// In en, this message translates to:
  /// **'Send Error Report'**
  String get dialogSendErrorReport;

  /// action button in error dialog to open forum and create new topic.
  ///
  /// In en, this message translates to:
  /// **'Report Error in Forum/Help'**
  String get dialogReportErrorForum;

  /// Description shown in the group list for filtering (e.g. app drawer)
  ///
  /// In en, this message translates to:
  /// **'Select which Groups to show (recursively)'**
  String get groupFilterDescription;

  /// No description provided for @groupFilterSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get groupFilterSelectAll;

  /// No description provided for @groupFilterDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get groupFilterDeselectAll;

  /// menu action: create nested group inside another group
  ///
  /// In en, this message translates to:
  /// **'Create Subgroup'**
  String get createSubgroup;

  /// menu action: edit item (e.g. delete a group)
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  ///
  ///
  /// In en, this message translates to:
  /// **'(re)enable'**
  String get mailboxEnableLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Continue receiving emails'**
  String get mailboxEnableHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get mailboxDisableLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Receive no more emails'**
  String get mailboxDisableHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'You do not have any emails yet.'**
  String get mailListNoMail;

  /// when a mailbox was created for a (password) entry.
  ///
  /// In en, this message translates to:
  /// **'Entry: {entryLabel}'**
  String mailboxLabelPrefixForEntry(Object entryLabel);

  /// when a mailbox was created for password entry which has been deleted or is otherwise not in the currently opened password files.
  ///
  /// In en, this message translates to:
  /// **'Unknown Entry: {entryUuid}'**
  String mailboxLabelPrefixUnknownEntry(Object entryUuid);

  /// When a mailbox was not created for an entry and has no label, the creation date is shown.
  ///
  /// In en, this message translates to:
  /// **'Created at: {dateTime}'**
  String mailboxLabelPrefixCreatedAt(Object dateTime);

  ///
  ///
  /// In en, this message translates to:
  /// **'The master password is used to securely encrypt your password database. Make sure to remember it, it can not be restored.'**
  String get masterPasswordDescription;

  ///
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChangesWarningTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'There are still unsaved changes. Do you want to discard changes?'**
  String get unsavedChangesWarningBody;

  ///
  ///
  /// In en, this message translates to:
  /// **'Discard Changes'**
  String get unsavedChangesDiscardActionLabel;

  /// menu action: delete an item permanently from the file (only shown for entries/groups already in the recycle bin.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanentlyAction;

  /// menu action: restore an entry/group which was moved into the recycle bin.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreFromRecycleBinAction;

  /// menu action: delete item (e.g. delete a group)
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// Confirmation when a password entry was deleted (ie. moved to recycle bin)
  ///
  /// In en, this message translates to:
  /// **'Deleted entry.'**
  String get deletedEntry;

  /// snackbar after deleting a group.
  ///
  /// In en, this message translates to:
  /// **'Deleted group.'**
  String get successfullyDeletedGroup;

  /// undo action label (e.g. in a snackbar after deleting a group, or some other action)
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoButtonLabel;

  /// save file, for example button displayed in entry details
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButtonLabel;

  /// dialog title for entering WebDAV settings.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Settings'**
  String get webDavSettings;

  ///
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get webDavUrlLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Base Url to your WebDAV service.'**
  String get webDavUrlHelperText;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please enter a URL'**
  String get webDavUrlValidatorError;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid url with http:// or https://'**
  String get webDavUrlValidatorInvalidUrlError;

  ///
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get webDavAuthUser;

  ///
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get webDavopenvalutword;

  ///
  ///
  /// In en, this message translates to:
  /// **'Successfully merged password database'**
  String get mergeSuccessDialogTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Conflict detected while saving {fileName}, it was merged successfully with the remote file: \n\n{mergeSummary}'**
  String mergeSuccessDialogMessage(Object fileName, Object mergeSummary);

  ///
  ///
  /// In en, this message translates to:
  /// **'For details visit {url}'**
  String forDetailsVisitUrl(Object url);

  ///
  ///
  /// In en, this message translates to:
  /// **'Enter email address to register or sign in.'**
  String get openvalutCloudAuthEmailInputLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get openvalutCloudAuthEmailInvalid;

  ///
  ///
  /// In en, this message translates to:
  /// **'Confirm Address'**
  String get openvalutCloudAuthConfirmEmailButtonLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please check your emails to confirm your email address.'**
  String get openvalutCloudAuthConfirmEmail;

  ///
  ///
  /// In en, this message translates to:
  /// **'Keep this screen open until you visited the link you received by email.'**
  String get openvalutCloudAuthConfirmEmailExplain;

  ///
  ///
  /// In en, this message translates to:
  /// **'If you have not received an email, please check your spam folder. Otherwise you can try to request a new confirmation link.'**
  String get openvalutCloudAuthResendExplain;

  ///
  ///
  /// In en, this message translates to:
  /// **'Request a new confirmation link'**
  String get openvalutCloudAuthResendButtonLabel;

  /// shown to force user to acknowledge delete before a entry will be permanently deleted.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the password entry {title}. This can not be undone. Do you want to continue?'**
  String permanentlyDeleteEntryConfirm(Object title);

  /// snackbar confirming that the entry was deleted.
  ///
  /// In en, this message translates to:
  /// **'Permanently deleted entry.'**
  String get permanentlyDeletedEntrySnackBar;

  /// initial name of groups when user creates a new one.
  ///
  /// In en, this message translates to:
  /// **'New Group'**
  String get initialNewGroupName;

  /// Title of error dialog when group could not be deleted.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete group'**
  String get deleteGroupErrorTitle;

  /// Body of error dialog when a group can't be deleted because it is not empty.
  ///
  /// In en, this message translates to:
  /// **'This group still contains other groups. You can currently only delete empty groups.'**
  String get deleteGroupErrorBodyContainsGroup;

  /// Body of error dialog when a group can't be deleted because it is not empty.
  ///
  /// In en, this message translates to:
  /// **'This group still contains password entries. You can currently only delete empty groups.'**
  String get deleteGroupErrorBodyContainsEntries;

  /// title in the app bar for the groups list
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupListAppBarTitle;

  /// title in the app bar for group lists when displayed for filtering password list
  ///
  /// In en, this message translates to:
  /// **'Filter by groups'**
  String get groupListFilterAppbarTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Clear Biometric Storage'**
  String get clearQuickUnlock;

  ///
  ///
  /// In en, this message translates to:
  /// **'Remove saved master passwords'**
  String get clearQuickUnlockSubtitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Unlock Files'**
  String get unlock;

  /// delete quick unlock (passwords stored in biometric storage)
  ///
  /// In en, this message translates to:
  /// **'close password files'**
  String get closePasswordFiles;

  ///
  ///
  /// In en, this message translates to:
  /// **'Removed saved master passwords from biometric storage.'**
  String get clearQuickUnlockSuccess;

  /// No description provided for @diacOptIn.
  ///
  /// In en, this message translates to:
  /// **'Opt in to In-App News, Surveys.'**
  String get diacOptIn;

  /// No description provided for @diacOptInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Will occasionally send a network request to fetch news.'**
  String get diacOptInSubtitle;

  /// Preference which opens the settings of a browser, where the user has to allow third party autofill services.
  ///
  /// In en, this message translates to:
  /// **'Enable AutoFill in {browserName}'**
  String browserAutofillThirdPartyModeTitle(String browserName);

  /// Explains why autofill does not work inside a browser.
  ///
  /// In en, this message translates to:
  /// **'{browserName} currently uses its own password manager. Tap to open its settings and select “Autofill using another service”, then restart {browserName}.'**
  String browserAutofillThirdPartyModeSubtitle(String browserName);

  /// only visible in debug build. Preference to enable Auto-Fill Debugging.
  ///
  /// In en, this message translates to:
  /// **'AutoFill: Enable debug'**
  String get enableAutofillDebug;

  /// only visible in debug build. Preference to enable Auto-Fill Debugging.
  ///
  /// In en, this message translates to:
  /// **'Shows information overlays for every input field'**
  String get enableAutofillDebugSubtitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Create Password Database'**
  String get createPasswordDatabase;

  /// creating new kdbx file, prompt
  ///
  /// In en, this message translates to:
  /// **'Name of your new Database'**
  String get nameNewPasswordDatabase;

  /// Error message when no password database name is given.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for your new database.'**
  String get validatorNameMissing;

  /// DEPRECATED FOR NOW help text for master password when creating new password database
  ///
  /// In en, this message translates to:
  /// **'Select a secure master Password. Make sure to remember it.'**
  String get masterPasswordHelpText;

  /// Creating new file: input field for master password
  ///
  /// In en, this message translates to:
  /// **'Master Password'**
  String get inputMasterPasswordText;

  /// Text displayed when master password is empty while creating new password database
  ///
  /// In en, this message translates to:
  /// **'Please enter a secure, rememberable password.'**
  String get masterPasswordMissingCreate;

  /// Label for button to create new database
  ///
  /// In en, this message translates to:
  /// **'Create Database'**
  String get createDatabaseAction;

  /// dialog title for error message when creating a new database with a name which already exists.
  ///
  /// In en, this message translates to:
  /// **'File Exists'**
  String get databaseExistsError;

  /// dialog body for error message when creating a new database with a name which already exists.
  ///
  /// In en, this message translates to:
  /// **'Error while trying to create database {filePath}. File already exists. Please choose another name.'**
  String databaseExistsErrorDescription(Object filePath);

  /// Default database name when creating a new database file. (WITHOUT .kdbx extension)
  ///
  /// In en, this message translates to:
  /// **'PersonalPasswords'**
  String get databaseCreateDefaultName;

  /// preferences: dynamically load website icons
  ///
  /// In en, this message translates to:
  /// **'Dynamically load Icons'**
  String get preferenceDynamicLoadIcons;

  /// preferences: dynamically load website icons help text.
  ///
  /// In en, this message translates to:
  /// **'Will make http requests with the value in {urlFieldName} field to load website icons.'**
  String preferenceDynamicLoadIconsSubtitle(Object urlFieldName);

  /// choosing a master password - calculated password strength.
  ///
  /// In en, this message translates to:
  /// **'Strength: {score} of 4'**
  String passwordScore(Object score);

  /// Password strength label for score 0.
  ///
  /// In en, this message translates to:
  /// **'Very weak'**
  String get passwordStrengthVeryWeak;

  /// Password strength label for score 1.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordStrengthWeak;

  /// Password strength label for score 2.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get passwordStrengthFair;

  /// Password strength label for score 3.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrengthStrong;

  /// Password strength label for score 4.
  ///
  /// In en, this message translates to:
  /// **'Very strong'**
  String get passwordStrengthVeryStrong;

  /// Hint shown when password strength is 0.
  ///
  /// In en, this message translates to:
  /// **'Too short or too common. Use more characters and mix letters, numbers and symbols.'**
  String get passwordStrengthHintVeryWeak;

  /// Hint shown when password strength is 1.
  ///
  /// In en, this message translates to:
  /// **'Still weak. Add a few more characters or avoid common words.'**
  String get passwordStrengthHintWeak;

  /// Hint shown when password strength is 2.
  ///
  /// In en, this message translates to:
  /// **'Decent, but could be stronger with an uncommon phrase.'**
  String get passwordStrengthHintFair;

  /// Hint shown when password strength is 3.
  ///
  /// In en, this message translates to:
  /// **'Strong password.'**
  String get passwordStrengthHintStrong;

  /// Hint shown when password strength is 4.
  ///
  /// In en, this message translates to:
  /// **'Excellent password.'**
  String get passwordStrengthHintVeryStrong;

  ///
  ///
  /// In en, this message translates to:
  /// **'File:'**
  String get entryInfoFile;

  ///
  ///
  /// In en, this message translates to:
  /// **'Group:'**
  String get entryInfoGroup;

  ///
  ///
  /// In en, this message translates to:
  /// **'Last Modified:'**
  String get entryInfoLastModified;

  ///
  ///
  /// In en, this message translates to:
  /// **'Moved entry into {groupName}'**
  String movedEntryToGroup(Object groupName);

  ///
  ///
  /// In en, this message translates to:
  /// **'{count} bytes, stored on OpenValut Cloud'**
  String sizeBytesStoredopenvalutCloud(Object count);

  ///
  ///
  /// In en, this message translates to:
  /// **'{count} bytes'**
  String sizeBytes(Object count);

  ///
  ///
  /// In en, this message translates to:
  /// **'Attached files will be embedded in password file. This can significantly increase time required to open/save passwords.'**
  String get entryAttachmentSizeWarning;

  /// Warning shown when user selects a large png file as custom icon.
  ///
  /// In en, this message translates to:
  /// **'Custom icons will be embedded in password file. This can significantly increase time required to open/save passwords.'**
  String get iconPngSizeWarning;

  /// Error when user selects an unsupported file as custom icon.
  ///
  /// In en, this message translates to:
  /// **'Chosen file is not a PNG.'**
  String get notPngError;

  ///
  ///
  /// In en, this message translates to:
  /// **'Add Field'**
  String get entryAddField;

  ///
  ///
  /// In en, this message translates to:
  /// **'Custom Field'**
  String get entryCustomField;

  ///
  ///
  /// In en, this message translates to:
  /// **'Adding new custom Field'**
  String get entryCustomFieldTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Enter a name for the field'**
  String get entryCustomFieldInputLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Copy Field'**
  String get swipeCopyField;

  ///
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get fieldRename;

  ///
  ///
  /// In en, this message translates to:
  /// **'Generate Password …'**
  String get fieldGeneratePassword;

  ///
  ///
  /// In en, this message translates to:
  /// **'Protect Value'**
  String get fieldProtect;

  ///
  ///
  /// In en, this message translates to:
  /// **'Unprotect Value'**
  String get fieldUnprotect;

  ///
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get fieldPresent;

  ///
  ///
  /// In en, this message translates to:
  /// **'Generate Email'**
  String get fieldGenerateEmail;

  /// Context menu entry which reverts to onboarding
  ///
  /// In en, this message translates to:
  /// **'Tour'**
  String get onboardingBackToOnboarding;

  /// Context menu entry which reverts to onboarding
  ///
  /// In en, this message translates to:
  /// **'Relive the first run experience 😅️'**
  String get onboardingBackToOnboardingSubtitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Let\'s make your Passwords Secure!'**
  String get onboardingHeadline;

  ///
  ///
  /// In en, this message translates to:
  /// **'Have you used a password manager before?'**
  String get onboardingQuestion;

  ///
  ///
  /// In en, this message translates to:
  /// **'Yes, open my passwords'**
  String get onboardingYesOpenPasswords;

  ///
  ///
  /// In en, this message translates to:
  /// **'I\'m all new! Get me started.'**
  String get onboardingNoCreate;

  /// Button that is displayed in backup warnings
  ///
  /// In en, this message translates to:
  /// **'SAVE TO CLOUD'**
  String get backupButton;

  /// Button that is displayed in backup warnings to dismiss the warning
  ///
  /// In en, this message translates to:
  /// **'DISMISS'**
  String get dismissBackupButton;

  /// Warning message that is displayed in backup warnings
  ///
  /// In en, this message translates to:
  /// **'Your passwords in {databasename} are only saved locally!'**
  String backupWarningMessage(Object databasename);

  /// Save as text
  ///
  /// In en, this message translates to:
  /// **'Save In...'**
  String get saveAs;

  /// Saving text
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get saving;

  /// Preferences value modifier (Text Scale Factor/Visual Density)
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get increaseValue;

  /// Preferences value modifier (Text Scale Factor/Visual Density)
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get decreaseValue;

  /// Preferences value modifier (Text Scale Factor/Visual Density)
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetValue;

  /// app bar title for opening/saving to cloud storage.
  ///
  /// In en, this message translates to:
  /// **'CloudStorage - {cloudStorageName}'**
  String cloudStorageAppBarTitle(Object cloudStorageName);

  ///
  ///
  /// In en, this message translates to:
  /// **'You will be redirected to authenticate OpenValut to access your data.'**
  String get cloudStorageLogInCaption;

  /// for oauth authentication user has to enter auth code - this is the label for the text field.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get cloudStorageLogInCode;

  ///
  ///
  /// In en, this message translates to:
  /// **'Unable to launch url. Please visit {url}'**
  String launchUrlError(Object url);

  /// when the user has not authenticated yet, he will see this button to start the login flow of a cloud storage backend.
  ///
  /// In en, this message translates to:
  /// **'Login to {cloudStorageName}'**
  String cloudStorageLogInActionLabel(Object cloudStorageName);

  ///
  ///
  /// In en, this message translates to:
  /// **'{cloudStorageName} Authentication'**
  String cloudStorageAuthCodeDialogTitle(Object cloudStorageName);

  ///
  ///
  /// In en, this message translates to:
  /// **'Authentication Code'**
  String get cloudStorageAuthCodeLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Error while authenticating'**
  String get cloudStorageAuthErrorTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Error while trying to authenticate to {cloudStorageName}: {errorMessage}'**
  String cloudStorageAuthErrorMessage(
    Object cloudStorageName,
    Object errorMessage,
  );

  ///
  ///
  /// In en, this message translates to:
  /// **'Search Query'**
  String get cloudStorageSearchBoxLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'{itemCount} items in this folder.'**
  String cloudStorageItemsInFolder(Object itemCount);

  ///
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get mailSubject;

  ///
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get mailFrom;

  ///
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get mailDate;

  ///
  ///
  /// In en, this message translates to:
  /// **'Mailbox'**
  String get mailMailbox;

  /// Message shown when email text body is empty (or can't be decoded)
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get mailNoData;

  /// Title of the screen showing all available mailboxes.
  ///
  /// In en, this message translates to:
  /// **'Mailboxes'**
  String get mailMailboxesTitle;

  /// FAB label to create a new mailbox.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get mailboxCreateButtonLabel;

  /// title of the dialog asking for a mailbox label/name
  ///
  /// In en, this message translates to:
  /// **'Optionally label for new mailbox'**
  String get mailboxNameInputDialogTitle;

  /// Label for the text field asking for a label for a mailbox, while creating it.
  ///
  /// In en, this message translates to:
  /// **'(Internal) Label'**
  String get mailboxNameInputLabel;

  /// title for the screen showing available emails
  ///
  /// In en, this message translates to:
  /// **'OpenValut Mail'**
  String get mailScreenTitle;

  /// title for the tab showing list of mailboxes.
  ///
  /// In en, this message translates to:
  /// **'Mailbox'**
  String get mailTabBarTitleMailbox;

  /// title for the tab showing list of mails.
  ///
  /// In en, this message translates to:
  /// **'Mail'**
  String get mailTabBarTitleMail;

  ///
  ///
  /// In en, this message translates to:
  /// **'You do not have any mailboxes yet.'**
  String get mailMailboxListEmpty;

  /// Success message when mailbox email address was copied to clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied mailbox address to clipboard: {mailboxAddress}'**
  String mailMailboxAddressCopied(Object mailboxAddress);

  /// title for error dialog shown when an error occurs while saving
  ///
  /// In en, this message translates to:
  /// **'Error while saving'**
  String get errorWhileSavingTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Unable to save file: {errorMessage}'**
  String errorWhileSavingBody(Object errorMessage);

  /// keepass files loaded through a URL can't be saved.
  ///
  /// In en, this message translates to:
  /// **'Sorry this database does not support saving. Please open a local database file. Or use \"Save As\".'**
  String get databaseDoesNotSupportSaving;

  /// dialog title for an invalid key of a one time password (OTP/TOTP)
  ///
  /// In en, this message translates to:
  /// **'Invalid Key'**
  String get otpInvalidKeyTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Given input is not a valid base32 TOTP code. Please verify your input.'**
  String get otpInvalidKeyBody;

  /// No description provided for @otpUnsupportedMigrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsupported OTP Migration'**
  String get otpUnsupportedMigrationTitle;

  /// No description provided for @otpUnsupportedMigrationBody.
  ///
  /// In en, this message translates to:
  /// **'We currently only support single item migrations. Got {uriCount}'**
  String otpUnsupportedMigrationBody(Object uriCount);

  ///
  ///
  /// In en, this message translates to:
  /// **'Time Based Authentication'**
  String get otpPromptTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please enter time based key.'**
  String get otpPromptHelperText;

  ///
  ///
  /// In en, this message translates to:
  /// **'Error generating invite code: {errorMessage}'**
  String otpErrorMessageGeneration(Object errorMessage);

  ///
  ///
  /// In en, this message translates to:
  /// **'Copy Secret'**
  String get otpCopySecretActionLabel;

  /// The label for entries which show a one time token for a TOTP
  ///
  /// In en, this message translates to:
  /// **'One Time Token'**
  String get otpEntryLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Protected field. Click to reveal.'**
  String get entryFieldProtected;

  ///
  ///
  /// In en, this message translates to:
  /// **'Show protected field'**
  String get entryFieldActionRevealField;

  ///
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get entryAttachmentOpenActionLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get entryAttachmentShareActionLabel;

  /// the 'subject' passed to the system when sharing an attachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get entryAttachmentShareSubject;

  ///
  ///
  /// In en, this message translates to:
  /// **'Save to device'**
  String get entryAttachmentSaveActionLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get entryAttachmentRemoveActionLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete {attachmentLabel}?'**
  String entryAttachmentRemoveConfirm(Object attachmentLabel);

  ///
  ///
  /// In en, this message translates to:
  /// **'Renaming field'**
  String get entryRenameFieldPromptTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get removerecentfile;

  ///
  ///
  /// In en, this message translates to:
  /// **'Enter the new name for the field'**
  String get entryRenameFieldPromptLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Paste from Clipboard'**
  String get promptDialogPasteActionTooltip;

  /// sometimes the paste shortcut is not working properly, so tell users they can use the paste button from the UI
  ///
  /// In en, this message translates to:
  /// **'Hint: If you need to paste, try the button to the left ;-)'**
  String get promptDialogPasteHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'Error while handling action'**
  String get genericErrorDialogTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Encountered an unexpected error. {errorMessage}'**
  String genericErrorDialogBody(Object errorMessage);

  /// menu entry in the 'save as' dialog for saving as local file.
  ///
  /// In en, this message translates to:
  /// **'Local File'**
  String get saveAsEntryLocalFile;

  /// When selecting custom icons, users can choose a png image. This is the name of the 'file group'
  ///
  /// In en, this message translates to:
  /// **'Images (png)'**
  String get fileTypePngs;

  ///
  ///
  /// In en, this message translates to:
  /// **'SELECT ICON'**
  String get selectIconDialogAction;

  ///
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get retryDialogActionLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Error during api call. {errorMessage}'**
  String errorDuringNetworkCall(Object errorMessage);

  /// filter name to show only password entries which are not deleted
  ///
  /// In en, this message translates to:
  /// **'Hide Deleted Entries'**
  String get passwordFilterHideDeleted;

  /// filter name to show only deleted password entries
  ///
  /// In en, this message translates to:
  /// **'Deleted Entries'**
  String get passwordFilterOnlyDeleted;

  /// The label for a password filter for one specific group
  ///
  /// In en, this message translates to:
  /// **'Group: {groupName}'**
  String passwordFilterPrefixForOneGroup(Object groupName);

  /// The label for a password filter for multiple groups
  ///
  /// In en, this message translates to:
  /// **'Custom Filter ({groupCount} Groups)'**
  String passwordFilterPrefixForMultipleGroups(Object groupCount);

  /// menu entry in password list to allow users to authenticate with OpenValut Cloud
  ///
  /// In en, this message translates to:
  /// **'Authenticate with OpenValut Cloud'**
  String get menuItemopenvalutCloudAuthenticate;

  ///
  ///
  /// In en, this message translates to:
  /// **'OpenValut Mailboxes'**
  String get menuItemopenvalutCloudMailboxes;

  ///
  ///
  /// In en, this message translates to:
  /// **'You have changes in \"{fileName}\", which does not support writing of changes.'**
  String changesWithoutSaving(Object fileName);

  ///
  ///
  /// In en, this message translates to:
  /// **'Save locally'**
  String get changesSaveLocally;

  /// Action to remove a selected color and reset to default.
  ///
  /// In en, this message translates to:
  /// **'Clear Color'**
  String get clearColor;

  ///
  ///
  /// In en, this message translates to:
  /// **'Enter database name'**
  String get databaseRenameInputLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get databasePath;

  ///
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get databaseColor;

  ///
  ///
  /// In en, this message translates to:
  /// **'Select a color to distinguish between files.'**
  String get databaseColorChoose;

  /// Switch on the database screen, enabling this database for iOS AutoFill.
  ///
  /// In en, this message translates to:
  /// **'AutoFill'**
  String get databaseAutofill;

  /// Explains what enabling AutoFill for a database does.
  ///
  /// In en, this message translates to:
  /// **'Offer this database\'s entries when apps and websites ask for a password.'**
  String get databaseAutofillSubtitle;

  /// Shown when AutoFill is on for a database, so it is clear a second copy of the file exists and what removes it.
  ///
  /// In en, this message translates to:
  /// **'An encrypted copy of this database is kept for AutoFill until you switch it off, or close the database.'**
  String get databaseAutofillCopyWarning;

  /// Shown instead of the AutoFill switch for kdbx3 databases, which cannot be mirrored for the extension.
  ///
  /// In en, this message translates to:
  /// **'AutoFill needs KDBX 4. Upgrade this database below to use it.'**
  String get databaseAutofillNeedsKdbx4;

  /// Reminder that iOS needs OpenValut enabled as a credential provider as well.
  ///
  /// In en, this message translates to:
  /// **'Also turn OpenValut on in Settings › General › AutoFill & Passwords.'**
  String get databaseAutofillSystemHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'KDBX File Version'**
  String get databaseKdbxVersion;

  ///
  ///
  /// In en, this message translates to:
  /// **'Upgrade to {versionName}'**
  String databaseKdbxUpgradeVersion(Object versionName);

  ///
  ///
  /// In en, this message translates to:
  /// **'Successfully upgraded file and saved.'**
  String get databaseKdbxUpgradeSuccessful;

  ///
  ///
  /// In en, this message translates to:
  /// **'Reload and Merge'**
  String get databaseReload;

  /// While an action is running this is displayed as status message. Don't worry too much, users should typically not see this for too long (if at all)
  ///
  /// In en, this message translates to:
  /// **'Status: {statusProgress}'**
  String progressStatus(Object statusProgress);

  ///
  ///
  /// In en, this message translates to:
  /// **'Finished Merge {status}'**
  String finishedMerge(Object status);

  ///
  ///
  /// In en, this message translates to:
  /// **'Close/Lock'**
  String get closeAndLockFile;

  ///
  ///
  /// In en, this message translates to:
  /// **'password manager, open source, available on all platforms.'**
  String get openvalutHomeScreenTagline;

  ///
  ///
  /// In en, this message translates to:
  /// **'Add new Password'**
  String get addNewPasswordButtonLabel;

  /// displayed instead of entry label, if entry has no name or it is blank.
  ///
  /// In en, this message translates to:
  /// **'(Unnamed)'**
  String get unnamedEntryPlaceholder;

  /// displayed instead of a groups name, it is unnamed or it's name is empty
  ///
  /// In en, this message translates to:
  /// **'(Unnamed)'**
  String get unnamedGroupPlaceholder;

  ///
  ///
  /// In en, this message translates to:
  /// **'(Unnamed)'**
  String get unnamedFilePlaceholder;

  ///
  ///
  /// In en, this message translates to:
  /// **'Edit Group'**
  String get editGroupScreenTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get editGroupGroupNameLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  ///
  ///
  /// In en, this message translates to:
  /// **'New Group'**
  String get newGroupDialogTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Name for the new group'**
  String get newGroupDialogInputLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Show passwords'**
  String get groupActionShowPasswords;

  ///
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get groupActionDelete;

  /// Tooltip for logging out of a cloud storage provider.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTooltip;

  /// deleted file from cloud storage.
  ///
  /// In en, this message translates to:
  /// **'Successfully deleted file.'**
  String get successfullyDeletedFileCloudStorage;

  ///
  ///
  /// In en, this message translates to:
  /// **'Sharing Options for {fileName}'**
  String shareDialogTitle(Object fileName);

  ///
  ///
  /// In en, this message translates to:
  /// **'Share …'**
  String get shareFileActionLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'File not shared yet.'**
  String get shareTokenListEmptyScreenPlaceholder;

  /// User did not specify a description for a given share code.
  ///
  /// In en, this message translates to:
  /// **'No Label/Description'**
  String get shareTokenNoLabel;

  /// Share Code allows reading and writing
  ///
  /// In en, this message translates to:
  /// **'Read/Write'**
  String get shareTokenReadWrite;

  /// Share code only allows reading.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get shareTokenReadOnly;

  ///
  ///
  /// In en, this message translates to:
  /// **'Share file'**
  String get shareCreateTokenDialogTitle;

  /// switch between read only and read/write
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get shareCreateTokenReadOnly;

  /// help text for the switch between read only and read/write
  ///
  /// In en, this message translates to:
  /// **'Do not allow saving of changes'**
  String get shareCreateTokenReadOnlyHelpText;

  /// Allows users to add a description/label to a share code.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get shareCreateTokenLabelText;

  /// the placeholder/hint text displayed when the user has not yet entered a label
  ///
  /// In en, this message translates to:
  /// **'Share for my friend'**
  String get shareCreateTokenLabelHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'Optional label to differentiate share code.'**
  String get shareCreateTokenLabelHelp;

  /// snackbar when share code was created successfully.
  ///
  /// In en, this message translates to:
  /// **'Successfully created share code.'**
  String get shareCreateTokenSuccess;

  ///
  ///
  /// In en, this message translates to:
  /// **'Share file with secret share code'**
  String get sharePresentDialogTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Using the following share code users can access the password file. They will need the password and/or key file to open it.'**
  String get sharePresentDialogHelp;

  ///
  ///
  /// In en, this message translates to:
  /// **'Share Code'**
  String get sharePresentToken;

  ///
  ///
  /// In en, this message translates to:
  /// **'Copied share code to clipboard.'**
  String get sharePresentCopied;

  /// Allows users to open cloud files using a share code/token.
  ///
  /// In en, this message translates to:
  /// **'Open with Share Code'**
  String get openvalutCloudOpenWithShareCodeTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get openvalutCloudShareFileActionLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Use OpenValut Cloud Attachments'**
  String get preferenceopenvalutCloudAttachmentTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Store Attachments encrypted on OpenValut Cloud separately.'**
  String get preferenceopenvalutCloudAttachmentSubtitle;

  /// input dialog for inputting secret share code to access password file in OpenValutCloud
  ///
  /// In en, this message translates to:
  /// **'Input Secret Share Code'**
  String get shareCodeInputDialogTitle;

  /// button label for triggering QR code scanner
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get shareCodeInputDialogScan;

  ///
  ///
  /// In en, this message translates to:
  /// **'Secret Share Code'**
  String get shareCodeInputLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'If you have received a share code, please paste it above.'**
  String get shareCodeInputHelperText;

  ///
  ///
  /// In en, this message translates to:
  /// **'Received a Share Code for OpenValut Cloud?'**
  String get shareCodeOpen;

  ///
  ///
  /// In en, this message translates to:
  /// **'Loading file with share code'**
  String get shareCodeOpenScreenTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Loading file …'**
  String get shareCodeLoadingProgress;

  ///
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get shareCodeOpenFileButtonLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Want to open this file with one of our native Apps instead?'**
  String get shareCodeOpenInstallAppCaption;

  ///
  ///
  /// In en, this message translates to:
  /// **'Want to open this file on another device?'**
  String get shareCodeOpenAnotherAppCaption;

  ///
  ///
  /// In en, this message translates to:
  /// **'Install App'**
  String get shareCodeOpenInstallAppButtonLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Show Share Code'**
  String get shareCodeOpenShowCodeButtonLabel;

  /// label for the button to show the dialog for changing master password.
  ///
  /// In en, this message translates to:
  /// **'Change Master Password'**
  String get changeMasterPasswordActionLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Save with new password'**
  String get changeMasterPasswordFormSubmit;

  ///
  ///
  /// In en, this message translates to:
  /// **'Successfully saved master password.'**
  String get changeMasterPasswordSuccess;

  /// app bar title for change password screen.
  ///
  /// In en, this message translates to:
  /// **'Change Master Password'**
  String get changeMasterPasswordScreenTitle;

  /// label for the confirmation field when changing the master password.
  ///
  /// In en, this message translates to:
  /// **'Repeat new password'**
  String get changeMasterPasswordConfirmLabel;

  /// title of the post-change checklist dialog.
  ///
  /// In en, this message translates to:
  /// **'Password changed — one more step'**
  String get changeMasterPasswordCleanupTitle;

  /// checklist item: remind the user to re-enter the new password on other devices.
  ///
  /// In en, this message translates to:
  /// **'• Other devices: lock the vault and unlock it again with the new master password. Sessions remembered with the old password can no longer decrypt the vault.'**
  String get changeMasterPasswordCleanupDevices;

  /// checklist item: old backups remain encrypted with the old password.
  ///
  /// In en, this message translates to:
  /// **'• Backups and exported copies made before the change are still encrypted with the old password — open and re-save them, or delete them.'**
  String get changeMasterPasswordCleanupBackups;

  /// checklist item: quick unlock was cleared on this device.
  ///
  /// In en, this message translates to:
  /// **'• On this device, quick unlock and remembered passwords were cleared; the new password will be required at the next unlock.'**
  String get changeMasterPasswordCleanupQuickUnlock;

  /// title of the error dialog shown when rotating the cloud vault key failed.
  ///
  /// In en, this message translates to:
  /// **'Could not re-encrypt the cloud vault'**
  String get changeMasterPasswordRotationFailedTitle;

  /// explains that the local password change succeeded but the server-side re-encryption did not, and how to retry.
  ///
  /// In en, this message translates to:
  /// **'The master password was changed on this device, but re-encrypting the vault on the server failed: {error}. Open \"Change Master Password\" again and enter the same new password once more to retry.'**
  String changeMasterPasswordRotationFailedBody(Object error);

  /// title of the log dialog after a cloud vault reload (which replaces the file instead of merging).
  ///
  /// In en, this message translates to:
  /// **'Finished Reload {status}'**
  String finishedReload(Object status);

  ///
  ///
  /// In en, this message translates to:
  /// **'I received email and visited link'**
  String get openvalutCloudAuthClickedLink;

  ///
  ///
  /// In en, this message translates to:
  /// **'Email address was not yet confirmed. Make sure to click the link in the email you received and solve the captcha to confirm your email address.'**
  String get openvalutCloudAuthNotConfirmed;

  ///
  ///
  /// In en, this message translates to:
  /// **'Get help in the forum'**
  String get getHelpButton;

  ///
  ///
  /// In en, this message translates to:
  /// **'Copy Username'**
  String get shortcutCopyUsername;

  ///
  ///
  /// In en, this message translates to:
  /// **'Copy Password'**
  String get shortcutCopyPassword;

  ///
  ///
  /// In en, this message translates to:
  /// **'Copy TOTP'**
  String get shortcutCopyTotp;

  ///
  ///
  /// In en, this message translates to:
  /// **'Select the previous password'**
  String get shortcutMoveUp;

  ///
  ///
  /// In en, this message translates to:
  /// **'Select the next password'**
  String get shortcutMoveDown;

  ///
  ///
  /// In en, this message translates to:
  /// **'Generate Password'**
  String get shortcutGeneratePassword;

  ///
  ///
  /// In en, this message translates to:
  /// **'Copy URL'**
  String get shortcutCopyUrl;

  ///
  ///
  /// In en, this message translates to:
  /// **'Open URL'**
  String get shortcutOpenUrl;

  ///
  ///
  /// In en, this message translates to:
  /// **'Cancel Search'**
  String get shortcutCancelSearch;

  ///
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcut Help'**
  String get shortcutShortcutHelp;

  /// title of dialog showing keyboard shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts'**
  String get shortcutHelpTitle;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected Error: {error}'**
  String unexpectedError(String error);

  /// No description provided for @googleDriveMorePermissionsRequired.
  ///
  /// In en, this message translates to:
  /// **'Additional permissions needed to access Google Drive.'**
  String get googleDriveMorePermissionsRequired;

  /// No description provided for @googleDriveRequestPermissionButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Request Permissions'**
  String get googleDriveRequestPermissionButtonLabel;

  /// No description provided for @scanQrCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code.'**
  String get scanQrCodeTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'et',
    'fi',
    'fr',
    'he',
    'id',
    'it',
    'lt',
    'nl',
    'pa',
    'pl',
    'pt',
    'ru',
    'si',
    'sk',
    'tr',
    'uk',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'et':
      return AppLocalizationsEt();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'he':
      return AppLocalizationsHe();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'lt':
      return AppLocalizationsLt();
    case 'nl':
      return AppLocalizationsNl();
    case 'pa':
      return AppLocalizationsPa();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'si':
      return AppLocalizationsSi();
    case 'sk':
      return AppLocalizationsSk();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
