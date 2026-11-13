import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_async_utils/flutter_async_utils.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/bloc/analytics.dart';
import 'package:openvalut/bloc/app_data.dart';
import 'package:openvalut/bloc/deps.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/openvalut_cloud/openvalut_cloud_session.dart';
import 'package:openvalut/openvalut_cloud/update_checker.dart';
import 'package:openvalut/computer/computer_two_factor_setup.dart';
import 'package:openvalut/ui/common_fields.dart';
import 'package:openvalut/ui/screens/locked_screen.dart';
import 'package:openvalut/ui/screens/select_file_screen.dart';
import 'package:openvalut/ui/widgets/installed_app_picker.dart';
import 'package:openvalut/ui/widgets/keyboard_handler.dart';
import 'package:openvalut/ui/widgets/password_input_field.dart';
import 'package:openvalut/ssh/import_ssh_keys.dart';
import 'package:openvalut/ssh/ssh_config.dart';
import 'package:openvalut/utils/autofill_prefs.dart';
import 'package:openvalut/utils/clipboard_prefs.dart';
import 'package:openvalut/utils/constants.dart';
import 'package:openvalut/utils/dialog_utils.dart';
import 'package:openvalut/utils/extension_methods.dart';
import 'package:openvalut/utils/platform.dart';
import 'package:openvalut/utils/sidebar_prefs.dart';
import 'package:openvalut/utils/unlock_prefs.dart';
import 'package:openvalut/utils/window_prefs.dart';
import 'package:provider/provider.dart';
import 'package:string_literal_finder_annotations/string_literal_finder_annotations.dart';

final _logger = Logger('preferences');

class PreferencesScreen extends StatelessWidget {
  static Route<void> route() => MaterialPageRoute(
    settings: const RouteSettings(name: '/preferences'),
    builder: (context) => PreferencesScreen(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).preferenceTitle),
        actions: [PreferencesOverflowMenuAction()],
      ),
      body: Scrollbar(
        child: SingleChildScrollView(child: PreferencesBody()),
      ),
    );
  }
}

class LocaleInfo {
  LocaleInfo(@NonNls this.locale, @NonNls this.nativeName, this.translatedName);

  final String? locale;
  final String nativeName;
  final String? translatedName;
}

class PreferencesBody extends StatefulWidget {
  @override
  _PreferencesBodyState createState() => _PreferencesBodyState();
}

class _PreferencesBodyState extends State<PreferencesBody>
    with StreamSubscriberMixin, WidgetsBindingObserver {
  KdbxBloc? _kdbxBloc;

  late AppDataBloc _appDataBloc;
  AppData? _appData;
  bool _persistentSidebar = true;
  bool? _biometricSupported;
  String? _agentSocketPath;

  Analytics get _analytics => context.read<Analytics>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPersistentSidebar();
    // Re-read on every visit: the startup load can only have failed because the
    // platform channel was not attached yet, and this screen is where the value
    // is shown. Reading the service's own store keeps a single source of truth.
    unawaited(AutofillPrefs.load());
    unawaited(_loadAgentSocketPath());
  }

  Future<void> _loadAgentSocketPath() async {
    final path = await SshConfig.resolveSocketPath();
    if (mounted) {
      setState(() {
        _agentSocketPath = path;
      });
    }
  }

  Future<void> _loadPersistentSidebar() async {
    final isDesktop =
        OpenValutPlatform.isLinux ||
        OpenValutPlatform.isWindows ||
        OpenValutPlatform.isMacOS;
    if (!isDesktop) {
      return;
    }
    await SidebarPrefs.load();
    if (mounted) {
      setState(() {
        _persistentSidebar = SidebarPrefs.persistentEnabled.value;
      });
    }
  }

  Future<void> _checkBiometricSupport() async {
    final supported = await _kdbxBloc!.quickUnlockStorage
        .supportsBiometricKeyStore();
    if (mounted && _biometricSupported != supported) {
      setState(() {
        _biometricSupported = supported;
      });
    }
  }

  Future<void> _toggleAutoConfigureComputer(
    BuildContext context,
    bool value,
  ) async {
    final loc = AppLocalizations.of(context);
    if (!value) {
      _showSnack(loc.prefDisablingSystem2fa);
      final result = await ComputerTwoFactorSetup.disable(loc: loc);
      await UnlockPrefs.setAutoConfigureComputer2fa(result.ok);
      _showSnack(
        result.ok
            ? (result.message ?? loc.prefTwoFactorDisabled)
            : (result.error ?? loc.prefTwoFactorDisableFailed),
      );
      if (mounted) {
        setState(() {});
      }
      return;
    }
    final kdbxBloc = Provider.of<KdbxBloc>(context, listen: false);
    if (kdbxBloc.openedFilesKdbx.isEmpty) {
      _showSnack(loc.prefNeedUnlockedVaultForAutoConfig);
      return;
    }
    final password = await _askSudoPassword(context);
    if (password == null || password.isEmpty) {
      await UnlockPrefs.setAutoConfigureComputer2fa(false);
      if (mounted) {
        setState(() {});
      }
      return;
    }
    _showSnack(loc.prefConfiguringSystem2fa);
    final result = await ComputerTwoFactorSetup.autoConfigure(
      kdbxBloc: kdbxBloc,
      sudoPassword: password,
      loc: loc,
    );
    await UnlockPrefs.setAutoConfigureComputer2fa(result.ok);
    if (result.ok) {
      _showSnack(result.message ?? loc.prefTwoFactorConfigured);
    } else {
      _showSnack(result.error ?? loc.prefTwoFactorConfigFailed);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<String?> _askSudoPassword(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.prefSystemPasswordDialogTitle),
        content: PasswordInputField(
          controller: controller,
          autofocus: true,
          labelText: loc.prefSudoPasswordLabel,
          helperText: loc.prefSudoPasswordHelper,
          showVisibilityToggle: false,
          onFieldSubmitted: (v) => Navigator.of(dialogContext).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(loc.okAction),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _selectRememberDays() async {
    final loc = AppLocalizations.of(context);
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(loc.prefRememberMasterPasswordTitle),
        children: [
          RadioGroup<int>(
            groupValue: UnlockPrefs.rememberUnlockDays.value,
            onChanged: (value) => Navigator.of(context).pop(value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final days in const [0, 7, 14, 30])
                  RadioListTile<int>(
                    value: days,
                    title: Text(
                      days == 0
                          ? loc.prefRememberOffEveryLogin
                          : loc.prefDaysPlaceholder(days),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected != null) {
      await UnlockPrefs.setRememberUnlockDays(selected);
      if (selected == 0) {
        await _kdbxBloc!.clearRememberedUnlock();
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// 检查并安装 openvalut-server 发布的新版本（Android）。
  Future<void> _checkForUpdate() async {
    final loc = AppLocalizations.of(context);
    final deps = context.read<Deps>();
    final serverUrl =
        openvalutCloudSession.instance.serverUrl ??
        deps.env.featureFlags.openvalutCloudUri;
    if (serverUrl == null || serverUrl.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(loc.prefCloudServiceNotConfigured)),
        );
      return;
    }
    final base = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    try {
      final info = await UpdateChecker.checkForUpdate(baseUrl: base);
      if (!mounted) {
        return;
      }
      final current = await deps.env.getAppInfo();
      if (info == null || info.versionCode <= current.buildNumber) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(loc.prefUpToDate)));
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(loc.prefNewVersionAvailableTitle(info.versionName)),
          content: SingleChildScrollView(
            child: Text(
              info.changelog.isEmpty
                  ? loc.prefUpdateNowQuestion
                  : info.changelog,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(loc.prefUpdateLaterAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(loc.prefUpdateNowAction),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) {
        return;
      }
      final path = await UpdateChecker.downloadAndInstall(info);
      if (!OpenValutPlatform.isAndroid) {
        // 桌面端无法静默安装，提示用户手动安装。
        final installHint = OpenValutPlatform.isLinux
            ? 'sudo dpkg -i "${path.split('/').last}"'
            : path;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(loc.prefNewVersionDownloadedTitle),
            content: Text(
              loc.prefInstallManuallyBody(path, installHint),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(loc.prefGotItAction),
              ),
            ],
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.warning('Update check failed.', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(loc.prefUpdateCheckFailedTitle('$e'))),
          );
      }
    }
  }

  Future<void> _selectClipboardAutoClearSeconds() async {
    final loc = AppLocalizations.of(context);
    final selected = await showDialog<int>(
      context: context,
      builder: (context) {
        var value = ClipboardPrefs.autoClearSeconds.value.toDouble();
        return AlertDialog(
          title: Text(loc.prefClipboardAutoClearTitle),
          content: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value == 0
                      ? loc.prefOff
                      : loc.prefSecondsPlaceholder(value.toInt()),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Slider(
                  value: value,
                  min: 0,
                  max: ClipboardPrefs.maxAutoClearSeconds.toDouble(),
                  divisions: ClipboardPrefs.maxAutoClearSeconds ~/ 5,
                  label: value == 0
                      ? loc.prefOff
                      : loc.prefSecondsPlaceholder(value.toInt()),
                  onChanged: (v) => setState(() => value = v),
                ),
                Text(loc.prefZeroDisablesAutoClear),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(value.toInt()),
              child: Text(loc.okAction),
            ),
          ],
        );
      },
    );
    if (selected != null) {
      await ClipboardPrefs.setAutoClearSeconds(selected);
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _selectCloseAction() async {
    final loc = AppLocalizations.of(context);
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(loc.prefCloseWindowTitle),
        children: [
          RadioGroup<String>(
            groupValue: WindowPrefs.closeAction.value,
            onChanged: (value) => Navigator.of(context).pop(value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  value: 'hide',
                  title: Text(loc.prefHideToTrayRunning),
                ),
                RadioListTile<String>(
                  value: 'minimize',
                  title: Text(loc.prefMinimizeToTaskbarRunning),
                ),
                RadioListTile<String>(
                  value: 'exit',
                  title: Text(loc.prefQuitApplication),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected != null) {
      await WindowPrefs.setCloseAction(selected);
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _writeSshConfig() async {
    final loc = AppLocalizations.of(context);
    if (SshConfig.hasExternalIdentityAgent()) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(loc.sshConfigExternalIdentityAgent)),
          );
      }
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.writeSshConfig),
        content: Text(
          loc.prefSshConfigAppendPreview +
              'Host *\n'
                  '    IdentityAgent $_agentSocketPath',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.writeSshConfig),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final changed = await SshConfig.enable();
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              changed ? loc.writeSshConfigDone : loc.sshConfigAlreadyPresent,
            ),
          ),
        );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String _passwordReminderSubtitle(AppData appData) {
    final loc = AppLocalizations.of(context);
    final days = appData.passwordReminderDays ?? 0;
    if (days <= 0) {
      return loc.prefNotEnabledStatus;
    }
    final changed = appData.lastPasswordChangeDate;
    if (changed == null) {
      return loc.prefReminderNoChangeDate(days);
    }
    final next = changed.add(Duration(days: days));
    final remaining = next.difference(clock.now()).inDays;
    if (remaining < 0) {
      return loc.prefReminderExpired(-remaining);
    }
    return loc.prefReminderEvery(days, remaining);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_kdbxBloc == null) {
      _kdbxBloc = Provider.of<KdbxBloc>(context);
      unawaited(_checkBiometricSupport());
      _appDataBloc = Provider.of<AppDataBloc>(context);
      handleSubscription(
        _appDataBloc.store.onValueChangedAndLoad.listen((appData) {
          setState(() {
            _appData = appData;
          });
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appData = _appData;
    final loc = AppLocalizations.of(context);
    if (appData == null) {
      return Text(loc.prefLoadingEllipsis);
    }
    final localeInfo = [
      LocaleInfo(null, loc.preferenceSystemDefault, null),
      LocaleInfo('de', 'Deutsch', loc.german),
      LocaleInfo('en', 'English', loc.english),
      LocaleInfo('lt', 'lietuviškai', loc.lithuanian),
      LocaleInfo('ru', 'русский', loc.russian),
      LocaleInfo('uk', 'українська', loc.ukrainian),
      LocaleInfo('fr', 'Français', loc.french),
      LocaleInfo('es', 'Español', loc.spanish),
      LocaleInfo('id', 'Bahasa Indonesia', loc.indonesian),
      LocaleInfo('tr', 'Türkçe', loc.turkish),
      LocaleInfo('he', 'עִבְרִית', loc.hebrew),
      LocaleInfo('it', 'Italiano', loc.italian),
      LocaleInfo('zh', 'Chinese Simplified', loc.chineseSimplified),
      LocaleInfo('zh_TW', 'Chinese Traditional', loc.chineseTraditional),
      LocaleInfo('pt_BR', 'Portuguese, Brazilian', loc.portugueseBrazilian),
      LocaleInfo('sk', 'Slovak', loc.slovak),
      LocaleInfo('nl', 'Nederlands', loc.dutch),
    ];
    final locales = Map.fromEntries(
      localeInfo.map((e) => MapEntry(e.locale, e)),
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: <Widget>[
            ...?(!OpenValutPlatform.isAndroid &&
                    !OpenValutPlatform.isWindows &&
                    !OpenValutPlatform.isMacOS)
                ? null
                : [
                    SwitchListTile(
                      secondary: const Icon(Icons.camera_alt),
                      title: Text(loc.preferenceAllowScreenshots),
                      value: !appData.secureWindowOrDefault,
                      onChanged: (value) {
                        _appDataBloc.update(
                          (builder, data) => builder.secureWindow = !value,
                        );
                        _analytics.events.trackPreferences(
                          setting: 'allowScreenshots',
                          to: '$value',
                        );
                      },
                    ),
                  ],
            ...?!OpenValutPlatform.isAndroid && !OpenValutPlatform.isIOS
                ? [
                    SwitchListTile(
                      secondary: const Icon(Icons.view_sidebar_outlined),
                      title: Text(loc.prefAlwaysShowSidePanel),
                      subtitle: Text(loc.prefAlwaysShowSidePanelSubtitle),
                      value: _persistentSidebar,
                      onChanged: (value) async {
                        await SidebarPrefs.setPersistentEnabled(value);
                        if (mounted) {
                          setState(() {
                            _persistentSidebar = value;
                          });
                        }
                      },
                    ),
                  ]
                : null,
            if (!OpenValutPlatform.isWeb)
              ListTile(
                leading: const Icon(Icons.system_update_alt),
                title: Text(loc.menuItemCheckForUpdates),
                subtitle: Text(loc.prefCheckForUpdatesSubtitle),
                onTap: () => _checkForUpdate(),
              ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.clock),
              title: Text(loc.prefRememberMasterPasswordTitle),
              subtitle: Text(loc.prefRememberMasterPasswordSubtitle),
              trailing: Text(
                UnlockPrefs.rememberUnlockDays.value == 0
                    ? loc.prefOff
                    : loc.prefDaysPlaceholder(
                        UnlockPrefs.rememberUnlockDays.value,
                      ),
              ),
              onTap: () => _selectRememberDays(),
            ),
            ListTile(
              leading: const Icon(Icons.content_paste_go),
              title: Text(loc.prefClipboardAutoClearTitle),
              subtitle: Text(loc.prefClipboardAutoClearSubtitle),
              trailing: Text(
                ClipboardPrefs.autoClearSeconds.value == 0
                    ? loc.prefOff
                    : loc.prefSecondsPlaceholder(
                        ClipboardPrefs.autoClearSeconds.value,
                      ),
              ),
              onTap: () => _selectClipboardAutoClearSeconds(),
            ),
            if (OpenValutPlatform.isDesktop)
              ListTile(
                leading: const Icon(Icons.minimize),
                title: Text(loc.prefCloseWindowTitle),
                subtitle: Text(loc.prefCloseWindowSubtitle),
                trailing: Text(
                  switch (WindowPrefs.closeAction.value) {
                    'exit' => loc.prefQuitApplication,
                    'minimize' => loc.prefMinimizeToTaskbar,
                    'hide' => loc.prefHideToTray,
                    _ => loc.prefHideToTray,
                  },
                ),
                onTap: () => _selectCloseAction(),
              ),
            if (OpenValutPlatform.isLinux)
              SwitchListTile(
                secondary: const Icon(Icons.power_settings_new),
                title: Text(loc.prefStartAtLogin),
                subtitle: Text(loc.prefStartAtLoginSubtitle),
                value: WindowPrefs.autoStart.value,
                onChanged: (value) async {
                  await WindowPrefs.setAutoStart(value);
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
            if (_biometricSupported == true)
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: Text(loc.prefFingerprintUnlock),
                subtitle: Text(loc.prefFingerprintUnlockSubtitle),
                value: UnlockPrefs.fingerprintEnabled.value,
                onChanged: (value) async {
                  final kdbxBloc = Provider.of<KdbxBloc>(
                    context,
                    listen: false,
                  );
                  await UnlockPrefs.setFingerprintEnabled(value);
                  if (value) {
                    await kdbxBloc.enableQuickUnlockForOpenedFiles();
                  } else {
                    await kdbxBloc.disableQuickUnlock();
                  }
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
            if (OpenValutPlatform.isAndroid) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  loc.androidAutofillSection,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.filter_alt_off_outlined),
                title: Text(loc.prefAutofillIgnoredAppsTitle),
                subtitle: Text(loc.prefAutofillIgnoredAppsSubtitle),
                trailing: Text(
                  AutofillPrefs.ignoredPackages.value.isEmpty
                      ? loc.prefAutofillIgnoredAppsNone
                      : loc.prefAutofillIgnoredAppsCount(
                          AutofillPrefs.ignoredPackages.value.length,
                        ),
                ),
                onTap: () async {
                  final next = await showIgnoredAppPicker(
                    context,
                    selected: AutofillPrefs.ignoredPackages.value,
                  );
                  if (next == null) {
                    return;
                  }
                  await AutofillPrefs.setIgnoredPackages(next);
                  _analytics.events.trackAutofillFilter(
                    filter: 'ignoreApp',
                    value: next.length,
                  );
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                loc.localServicesSection,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.key),
              title: Text(loc.sshAgentSetting),
              subtitle: Text(loc.sshAgentSettingHelp),
              value: UnlockPrefs.sshAgentEnabled.value,
              onChanged: (value) async {
                await UnlockPrefs.setSshAgentEnabled(value);
                if (value) {
                  await SshConfig.enable();
                  if (SshConfig.hasExternalIdentityAgent() && mounted) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(loc.sshConfigExternalIdentityAgent),
                        ),
                      );
                  }
                } else {
                  await SshConfig.disable();
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(loc.sshConfigRemoved),
                        ),
                      );
                  }
                }
                if (mounted) {
                  setState(() {});
                }
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.terminal),
              title: Text(loc.credentialServerSetting),
              subtitle: Text(loc.credentialServerSettingHelp),
              value: UnlockPrefs.credentialServerEnabled.value,
              onChanged: (value) async {
                await UnlockPrefs.setCredentialServerEnabled(value);
                if (mounted) {
                  setState(() {});
                }
              },
            ),
            if (OpenValutPlatform.isLinux)
              SwitchListTile(
                secondary: const Icon(Icons.computer),
                title: Text(loc.prefAutoTwoFactorTitle),
                subtitle: Text(loc.prefAutoTwoFactorSubtitle),
                value: UnlockPrefs.autoConfigureComputer2fa.value,
                onChanged: (value) =>
                    _toggleAutoConfigureComputer(context, value),
              ),
            ListTile(
              leading: const Icon(Icons.download_for_offline_outlined),
              title: Text(loc.importSshKeys),
              subtitle: Text(loc.prefImportSshSubtitle),
              onTap: () async {
                final imported = await showImportSshKeysDialog(
                  context,
                  kdbxBloc: _kdbxBloc,
                );
                if (imported.isNotEmpty && mounted) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(loc.prefImportedSshKeys(imported.length)),
                      ),
                    );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: Text(loc.sshConfigSnippet),
              subtitle: Text(
                _agentSocketPath == null
                    ? 'IdentityAgent …'
                    : 'IdentityAgent $_agentSocketPath',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                tooltip: loc.copiedToClipboard,
                onPressed: () async {
                  final path =
                      _agentSocketPath ?? await SshConfig.resolveSocketPath();
                  await Clipboard.setData(
                    ClipboardData(
                      text: 'Host *\n    IdentityAgent $path',
                    ),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(loc.copiedToClipboard)),
                      );
                  }
                },
              ),
              onTap: _writeSshConfig,
            ),
            ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.lightbulb,
              ),
              title: Text(loc.preferenceTheme),
              trailing: appData.theme == null
                  ? Text(loc.preferenceSystemDefault)
                  : appData.theme == AppDataTheme.light
                  ? Text(loc.preferenceThemeLight)
                  : Text(loc.preferenceThemeDark),
              onTap: () async {
                final newTheme = await _appDataBloc.updateNextTheme();
                _analytics.events.trackPreferences(
                  setting: 'theme',
                  to: '$newTheme',
                );
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.language),
              title: Text(loc.preferenceLanguage),
              trailing: Text(locales[appData.localeOverride]!.nativeName),
              onTap: () async {
                final result = await showDialog<LocaleInfo>(
                  context: context,
                  builder: (_) => SelectLanguageDialog(
                    locales: localeInfo,
                    localeOverride: appData.localeOverride,
                  ),
                );
                if (result != null) {
                  await _appDataBloc.update(
                    (builder, data) => builder.localeOverride = result.locale,
                  );
                }
                _analytics.events.trackPreferences(
                  setting: 'localeOverride',
                  to: result?.locale ?? 'null',
                );
              },
            ),

            if (KeyboardHandler.supportsSystemWideShortcuts) ...[
              CheckboxListTile(
                secondary: const Icon(Icons.desktop_mac),
                value: appData.systemWideShortcuts,
                title: Text(loc.preferenceEnableSystemWideShortcuts),
                subtitle: Text(loc.preferenceEnableSystemWideShortcutsHelp),
                isThreeLine: true,
                onChanged: (value) {
                  _logger.fine('Changed to $value');
                  _analytics.events.trackPreferences(
                    setting: 'systemWideShortcuts',
                    to: '$value',
                  );
                  _appDataBloc.update(
                    (builder, data) => builder.systemWideShortcuts = value,
                  );
                },
                tristate: false,
              ),
            ],
            ListTile(
              leading: const Icon(Icons.search),
              title: Text(loc.preferencesSearchFields),
              subtitle:
                  appData.searchFields?.let((it) => Text(it)) ??
                  Text(
                    CommonFields.defaultSearchFields
                        .map((e) => e.key)
                        .join(CharConstants.comma),
                  ),
              onTap: () async {
                final value = (await SimplePromptDialog(
                  title: loc.preferencesSearchFieldPromptTitle,
                  labelText: loc.preferencesSearchFieldPromptLabel,
                  initialValue: appData.searchFields ?? CharConstants.empty,
                  helperText: loc.preferencesSearchFieldPromptHelp(
                    CharConstants.star,
                    CommonFields.defaultSearchFields
                        .map((e) => e.key)
                        .join(CharConstants.comma),
                  ),
                ).show(context))?.trim();
                if (value != null) {
                  await _appDataBloc.update(
                    (builder, data) =>
                        builder.searchFields = value.isEmpty ? null : value,
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_clock),
              title: Text(loc.prefPasswordChangeReminderTitle),
              subtitle: Text(_passwordReminderSubtitle(appData)),
              trailing: DropdownButton<int>(
                value: appData.passwordReminderDays ?? 0,
                items: [
                  DropdownMenuItem(value: 0, child: Text(loc.prefOff)),
                  DropdownMenuItem(
                    value: 7,
                    child: Text(loc.prefDaysPlaceholder(7)),
                  ),
                  DropdownMenuItem(
                    value: 30,
                    child: Text(loc.prefDaysPlaceholder(30)),
                  ),
                  DropdownMenuItem(
                    value: 90,
                    child: Text(loc.prefDaysPlaceholder(90)),
                  ),
                ],
                onChanged: (value) async {
                  if (value == null) return;
                  await _appDataBloc.update(
                    (builder, data) => builder
                      ..passwordReminderDays = value == 0 ? null : value
                      ..lastPasswordChangeDate ??= clock.now().toUtc(),
                  );
                  _analytics.events.trackPreferences(
                    setting: 'passwordReminderDays',
                    to: '$value',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectLanguageDialog extends StatelessWidget {
  const SelectLanguageDialog({
    super.key,
    required this.locales,
    this.localeOverride,
  });

  final List<LocaleInfo> locales;
  final String? localeOverride;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(loc.preferenceSelectLanguage),
      content: Scrollbar(
        trackVisibility: true,
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: RadioGroup<String?>(
            groupValue: localeOverride,
            onChanged: (value) {
              // 弹回 LocaleInfo 对象而不是裸字符串：外层 showDialog<LocaleInfo>
              // 期待 LocaleInfo，直接 pop String 会抛
              // "type 'String' is not a subtype of type 'LocaleInfo?'"，
              // 导致切语言时报错、界面像卡死。
              Navigator.of(context).pop(
                locales.firstWhere((e) => e.locale == value),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...locales.map(
                  (e) => RadioListTile<String?>(
                    value: e.locale,
                    title: Text(e.nativeName),
                    subtitle: e.translatedName
                        ?.takeIf((n) => n != e.nativeName)
                        ?.let(
                          (name) => Text(name),
                        ),
                    secondary: e.locale?.let((locale) => Text(locale)),
                    enabled: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // return SimpleDialog(
    //   title: Text(loc.preferenceSelectLanguage),
    //   children: locales
    //       .map(
    //         (LocaleInfo e) => RadioListTile<String?>(
    //           title: Text(e.nativeName),
    //           subtitle: e.translatedName
    //               ?.takeIf((n) => n != e.nativeName)
    //               ?.let((name) => Text(e.translatedName!)),
    //           secondary: e.locale?.let((locale) => Text(locale)),
    //           value: e.locale,
    //           groupValue: localeOverride,
    //           onChanged: (value) {
    //             Navigator.of(context).pop(e);
    //           },
    //         ),
    //       )
    //       .toList(),
    // );
  }
}

class SliderSelector extends StatefulWidget {
  const SliderSelector({
    super.key,
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
    required this.steps,
    required this.onChanged,
  });

  final double initialValue;
  final double minValue;
  final double maxValue;
  final int steps;
  final void Function(double value) onChanged;

  @override
  _SliderSelectorState createState() => _SliderSelectorState();
}

class _SliderSelectorState extends State<SliderSelector> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: _value,
      min: widget.minValue,
      max: widget.maxValue,
      divisions: widget.steps,
      onChanged: (value) {
        setState(() {
          _value = value;
          widget.onChanged(value);
        });
      },
    );
  }
}

class PreferencesOverflowMenuAction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final kdbxBloc = context.read<KdbxBloc>();
    return FutureBuilder<bool>(
      future: kdbxBloc.quickUnlockStorage.supportsBiometricKeyStore(),
      initialData: kdbxBloc.quickUnlockStorage.supportsBiometricKeystoreAlready,
      builder: (context, snapshot) {
        final supportsBiometricKeystore = snapshot.data == true;
        return PopupMenuButton<VoidCallback>(
          itemBuilder: (context) {
            return [
              if (supportsBiometricKeystore) ...[
                PopupMenuItem(
                  value: () async {
                    await kdbxBloc.closeAllFiles(clearQuickUnlock: true);
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.clearQuickUnlockSuccess)),
                    );
                    await SelectFileScreen.navigate(context);
                  },
                  child: ListTile(
                    leading: const FaIcon(FontAwesomeIcons.bug),
                    title: Text(loc.clearQuickUnlock),
                    subtitle: Text(loc.clearQuickUnlockSubtitle),
                  ),
                ),
              ],
              if (kdbxBloc.openedFilesWithSources.isNotEmpty) ...[
                PopupMenuItem(
                  value: () async {
                    await kdbxBloc.closeAllFiles(clearQuickUnlock: false);
                    if (!context.mounted) {
                      return;
                    }
                    await Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushAndRemoveUntil(LockedScreen.route(), (_) => false);
                  },
                  child: ListTile(
                    leading: const FaIcon(FontAwesomeIcons.rightFromBracket),
                    title: Text(loc.lockAllFiles),
                  ),
                ),
              ],
            ];
          },
          onSelected: (value) => value(),
        );
      },
    );
  }
}
