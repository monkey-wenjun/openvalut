// FIXME need to fix this lint
// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:file_picker_writable/file_picker_writable.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_async_utils/flutter_async_utils.dart';
import 'package:kdbx/kdbx.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/bloc/deps.dart';
import 'package:openvalut/bloc/kdbx/file_content.dart';
import 'package:openvalut/bloc/kdbx/file_source_openvalut_cloud.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/openvalut_cloud/openvalut_client.dart';
import 'package:openvalut/openvalut_cloud/openvalut_cloud_session.dart';
import 'package:openvalut/openvalut_cloud/openvalut_crypto.dart';
import 'package:openvalut/ui/screens/create_file.dart';
import 'package:openvalut/ui/screens/main_app_scaffold.dart';
import 'package:openvalut/ui/screens/select_file_screen.dart';
import 'package:openvalut/ui/widgets/password_input_field.dart';
import 'package:openvalut/utils/constants.dart';
import 'package:openvalut/utils/dialog_utils.dart';
import 'package:openvalut/utils/platform.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:recase/recase.dart';
import 'package:string_literal_finder_annotations/string_literal_finder_annotations.dart';
// ignore: implementation_imports
import 'package:zxcvbn/zxcvbn.dart';

final _logger = Logger('openvalut_cloud_screen');

/// 构建时通过 --dart-define=openvalut_CLOUD_URI=... 注入（值来自本地 .env），
/// 不把私有域名硬编码进源码。
const _defaultServerUrl = String.fromEnvironment(
  'openvalut_CLOUD_URI',
  defaultValue: '',
);

/// Formats a 32-char hex Secret Key as 4-char groups separated by dashes
/// (XXXXXXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX), uppercase.
String formatSecretKey(String key) {
  final clean = key.replaceAll('-', '').toUpperCase();
  return List.generate(
    8,
    (i) => clean.substring(i * 4, i * 4 + 4),
  ).join('-');
}

class openvalutCloudScreen extends StatefulWidget {
  const openvalutCloudScreen({super.key});

  static Route<void> route() => MaterialPageRoute<void>(
    settings: const RouteSettings(name: '/openvalutCloud'),
    builder: (context) => const openvalutCloudScreen(),
  );

  @override
  _openvalutCloudScreenState createState() => _openvalutCloudScreenState();
}

class _openvalutCloudScreenState extends State<openvalutCloudScreen>
    with FutureTaskStateMixin {
  @NonNls
  String get serverUrl {
    final deps = Provider.of<Deps>(context, listen: false);
    final configured = deps.env.featureFlags.openvalutCloudUri;
    if (configured == null ||
        configured.isEmpty ||
        configured.contains('localhost')) {
      return _defaultServerUrl.isNotEmpty ? _defaultServerUrl : '';
    }
    return configured;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenValut Cloud'),
      ),
      body: ProgressOverlay(
        task: task,
        child: AnimatedBuilder(
          animation: openvalutCloudSession.instance,
          builder: (context, _) {
            // Keep the login/register form mounted while the session
            // changes: login/registration navigate away from this widget
            // itself, and unmounting it mid-flow would abort the flow.
            return _LoginBody(
              serverUrl: serverUrl,
            );
          },
        ),
      ),
    );
  }
}

class _LoginBody extends StatefulWidget {
  const _LoginBody({required this.serverUrl});

  final String serverUrl;

  @override
  _LoginBodyState createState() => _LoginBodyState();
}

class _LoginBodyState extends State<_LoginBody> {
  static final _zxcvbn = Zxcvbn();

  final _formKey = GlobalKey<FormState>();
  final _serverUrl = TextEditingController();
  final _email = TextEditingController();
  final _secretKey = TextEditingController();
  final _vaultName = TextEditingController();
  final _masterPassword = TextEditingController();
  final _masterPasswordConfirm = TextEditingController();
  final _emailFocus = FocusNode();
  final _vaultNameFocus = FocusNode();
  final _masterPasswordFocus = FocusNode();
  final _masterPasswordConfirmFocus = FocusNode();
  bool _registerMode = false;
  Result? _strength;
  bool _busy = false;
  String? _error;
  bool _scanMode = false;
  bool _scanBusy = false;
  Timer? _scanTimer;
  String? _scanSessionId;
  String? _scanQrContent;
  String? _scanError;

  @override
  void initState() {
    super.initState();
    _serverUrl.text = widget.serverUrl;
    unawaited(_tryAutoLogin());
  }

  /// Entry point: if the account was remembered, log in and open the vault
  /// automatically so the user lands on the main screen. If the master
  /// password is not available, stay on the login form.
  Future<void> _tryAutoLogin() async {
    final session = openvalutCloudSession.instance;
    if (session.isLoggedIn) {
      return;
    }
    final loggedIn = await session.autoLogin();
    if (!loggedIn || !mounted) {
      return;
    }
    final client = session.currentClient;
    if (client == null) {
      return;
    }
    List<openvalutVault> vaults;
    try {
      vaults = await client.listVaults();
    } catch (e, stackTrace) {
      _logger.warning('Auto-login vault listing failed.', e, stackTrace);
      return;
    }
    if (vaults.isEmpty || !mounted) {
      return;
    }
    final vault = vaults.first;
    var masterPassword = session.vaultMasterPasswordFor(vault.id);
    if (masterPassword == null || masterPassword.isEmpty) {
      masterPassword = await session.loadVaultMasterPassword(
        vaultId: vault.id,
      );
    }
    if (masterPassword == null || masterPassword.isEmpty) {
      return;
    }
    try {
      await _afterLogin(
        masterPassword: masterPassword,
        preferredVaultId: vault.id,
      );
    } on Exception catch (e, stackTrace) {
      _logger.warning('Auto-login vault open failed.', e, stackTrace);
      session.clear();
    }
  }

  @override
  void dispose() {
    _serverUrl.dispose();
    _email.dispose();
    _secretKey.dispose();
    _vaultName.dispose();
    _masterPassword.dispose();
    _masterPasswordConfirm.dispose();
    _emailFocus.dispose();
    _scanTimer?.cancel();
    _vaultNameFocus.dispose();
    _masterPasswordFocus.dispose();
    _masterPasswordConfirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context);
    _serverUrl.text = openvalutCloudSession.normalizeServerUrl(_serverUrl.text);
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = openvalutCloudSession.instance;
      if (_registerMode) {
        await _registerAccount(session);
      } else {
        await session.login(
          username: _email.text.trim(),
          userId: _secretKey.text.trim().replaceAll('-', '').toLowerCase(),
          serverUrl: _serverUrl.text.trim(),
        );
        await _afterLogin(masterPassword: _masterPassword.text);
      }
    } on openvalutApiException catch (e) {
      _logger.warning('OpenValut Cloud auth failed', e);
      if (mounted) {
        setState(() {
          _error = switch (e.statusCode) {
            401 => loc.cloudAuthEmailOrSecretInvalid,
            409 => loc.cloudEmailAlreadyRegistered,
            _ => e.message,
          };
        });
      }
    } catch (e, stackTrace) {
      _logger.severe('OpenValut Cloud auth error', e, stackTrace);
      if (mounted) {
        setState(() {
          _error = loc.cloudConnectFailed('$e');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  /// After login: jump straight into the (first) vault. Manual login carries
  /// the master password and unlocks immediately; QR login (empty password)
  /// goes to the master-password screen. Accounts without a vault are told to
  /// register instead (registration creates the vault automatically).
  Future<void> _afterLogin({
    required String masterPassword,
    String? preferredVaultId,
  }) async {
    final loc = AppLocalizations.of(context);
    final client = openvalutCloudSession.instance.currentClient;
    if (client == null) {
      return;
    }
    // Derive the metadata key so vault names come back decrypted below.
    if (masterPassword.isNotEmpty) {
      await openvalutCloudSession.instance.setVaultMetaKey(masterPassword);
    }
    final vaults = await client.listVaults();
    if (!mounted) {
      return;
    }
    if (vaults.isEmpty) {
      await DialogUtils.showSimpleAlertDialog(
        context,
        loc.cloudNoVaultTitle,
        loc.cloudNoVaultBody,
        routeAppend: 'noVault',
      );
      openvalutCloudSession.instance.clear();
      return;
    }
    final vault = preferredVaultId == null
        ? vaults.first
        : vaults.firstWhere(
            (v) => v.id == preferredVaultId,
            orElse: () => vaults.first,
          );
    if (masterPassword.isEmpty) {
      // QR login: the mobile app confirmed the account; ask for the master
      // password here to unlock the vault.
      final source = FileSourceopenvalutCloud(
        client: client,
        vaultId: vault.id,
        vaultName: vault.name,
        uuid: vault.id,
      );
      await Navigator.of(context).push(CredentialsScreen.route(source));
      return;
    }
    final source = FileSourceopenvalutCloud(
      client: client,
      vaultId: vault.id,
      vaultName: vault.name,
      uuid: vault.id,
      masterPassword: masterPassword,
    );
    final deps = Provider.of<Deps>(context, listen: false);
    final credentials = Credentials.composite(
      ProtectedValue.fromString(masterPassword),
      null,
    );
    try {
      await deps.kdbxBloc
          .openFile(source, credentials, addToQuickUnlock: false)
          .last;
    } on KdbxInvalidKeyException {
      throw openvalutApiException(0, loc.cloudWrongMasterPassword);
    } on openvalutDecryptionException {
      throw openvalutApiException(
        0,
        loc.cloudDecryptFailedMasterPassword,
      );
    }
    openvalutCloudSession.instance.rememberVaultMasterPassword(
      masterPassword,
      vaultId: vault.id,
    );
    if (!mounted) {
      return;
    }
    await Navigator.of(
      context,
      rootNavigator: true,
    ).pushAndRemoveUntil(MainAppScaffold.route(), (_) => false);
  }

  /// Starts a QR-code login and begins polling for the mobile confirmation.
  Future<void> _startScanLogin() async {
    final loc = AppLocalizations.of(context);
    _serverUrl.text = openvalutCloudSession.normalizeServerUrl(_serverUrl.text);
    setState(() {
      _scanBusy = true;
      _scanError = null;
    });
    try {
      final info = await openvalutCloudSession.instance.startScanLogin(
        serverUrl: _serverUrl.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _scanSessionId = info.sessionId;
        _scanQrContent = info.qrContent;
      });
      _scanTimer?.cancel();
      _scanTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _pollScanLogin(),
      );
    } on Exception catch (e, stackTrace) {
      _logger.warning('Unable to create scan login', e, stackTrace);
      if (mounted) {
        setState(() {
          _scanError = loc.cloudScanCreateFailed('$e');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _scanBusy = false;
        });
      }
    }
  }

  Future<void> _pollScanLogin() async {
    final loc = AppLocalizations.of(context);
    final sessionId = _scanSessionId;
    if (sessionId == null) {
      return;
    }
    try {
      final result = await openvalutCloudSession.instance.pollScanLogin(
        sessionId,
      );
      if (!mounted) {
        return;
      }
      switch (result['status']) {
        case 'pending':
          // Keep polling.
          break;
        case 'expired':
          _scanTimer?.cancel();
          setState(() {
            _scanError = loc.cloudScanExpired;
          });
        case 'confirmed':
          _scanTimer?.cancel();
          await openvalutCloudSession.instance.applyScanLogin(
            token: result['token'] as String,
            username: result['username'] as String,
            userId: result['userId'] as String?,
          );
          if (!mounted) {
            return;
          }
          // 手机扫码确认时把主密码加密回传了，PC 解密后直接解锁；
          // 没有回传（例如手机未打开密码库）时仍走主密码输入界面。
          final masterPassword = openvalutCloudSession.instance
              .decryptScanVaultKey(
                (result['vaultCiphertext'] as String?) ?? '',
              );
          try {
            await _afterLogin(masterPassword: masterPassword ?? '');
          } on openvalutApiException catch (e) {
            // 自动带入的主密码不匹配时，退回主密码输入界面手动解锁，
            // 而不是让扫码流程失败。
            _logger.warning('Auto-unlock with relayed vault key failed', e);
            if (mounted) {
              await _afterLogin(masterPassword: '');
            }
          }
      }
    } on openvalutApiException catch (e) {
      _logger.warning('Scan login poll failed', e);
      if (!mounted) {
        return;
      }
      _scanTimer?.cancel();
      setState(() {
        _scanError = loc.cloudScanSessionInvalid(e.message);
      });
    } on Exception catch (e, stackTrace) {
      // Transient network errors: show a hint but keep polling.
      _logger.fine('Scan login poll transient error', e, stackTrace);
      if (mounted) {
        setState(() {
          _scanError = loc.cloudScanWaitingPhone('$e');
        });
      }
    }
  }

  void _stopScanLogin() {
    _scanTimer?.cancel();
    setState(() {
      _scanMode = false;
      _scanSessionId = null;
      _scanQrContent = null;
      _scanError = null;
    });
  }

  /// Registers the email account (server auto-generates the 32-char user
  /// UUID), then creates the first cloud vault with the given name and
  /// master password. The master password is only used on this device to
  /// derive the vault key — it is never sent to the server.
  Future<void> _registerAccount(openvalutCloudSession session) async {
    final loc = AppLocalizations.of(context);
    await session.register(
      username: _email.text.trim(),
      serverUrl: _serverUrl.text.trim(),
    );
    final secretKey = session.userId;
    if (secretKey == null) {
      throw StateError(loc.cloudRegisterNoSecretKey);
    }
    final deps = Provider.of<Deps>(context, listen: false);
    final client = session.currentClient!;

    // 1) 立即用填写的密码库名称和主密码创建密码库，避免被后续
    //    Secret Key 保存提醒卡住导致"注册了却没有库"。
    final vaultId = openvalutCloudSession.newVaultId();
    final key = await openvalutCrypto.deriveKey(
      _masterPassword.text,
      Uint8List.fromList(utf8.encode(vaultId)),
    );
    final inMemory = await deps.kdbxBloc.createFileInMemory(
      password: _masterPassword.text,
      databaseName: _vaultName.text.trim(),
    );
    final (nonce, ciphertext) = openvalutCrypto.encrypt(key, inMemory.bytes);
    final vault = await client.createVault(
      id: vaultId,
      name: _vaultName.text.trim(),
      nonce: base64.encode(nonce),
      ciphertext: base64.encode(ciphertext),
    );
    final source = FileSourceopenvalutCloud(
      client: client,
      vaultId: vault.id,
      vaultName: vault.name,
      uuid: vault.id,
      masterPassword: _masterPassword.text,
      initialCachedContent: FileContent(inMemory.bytes),
    );

    // 2) 打开新库（解锁成功）。
    await deps.kdbxBloc.openFile(source, inMemory.credentials).last;
    openvalutCloudSession.instance.rememberVaultMasterPassword(
      _masterPassword.text,
      vaultId: vault.id,
    );
    if (!mounted) {
      return;
    }

    // 3) 提醒保存 Secret Key（4 位一组显示，可跳过）。在进入主界面前
    //    弹出，此时登录页仍挂载，context 有效。
    await _showSecretKeyDialog(secretKey, _email.text.trim());
    if (!mounted) {
      return;
    }

    // 4) 进入主界面（带侧边栏）。
    await Navigator.of(
      context,
      rootNavigator: true,
    ).pushAndRemoveUntil(MainAppScaffold.route(), (_) => false);
  }

  /// Shows the freshly generated Secret Key (account UUID) once, with a
  /// copy button and a strong save reminder. The dialog cannot be dismissed
  /// without confirming, because the key cannot be recovered later.
  Future<void> _showSecretKeyDialog(String secretKey, String email) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final formatted = formatSecretKey(secretKey);
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(loc.cloudSaveSecretKeyTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(loc.cloudSecretKeyDescription),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                formatted,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _saveSecretKeyToFile(secretKey, email),
                icon: const Icon(Icons.save_alt),
                label: Text(loc.cloudSaveToFileAction),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () => Clipboard.setData(
              ClipboardData(text: formatted),
            ),
            icon: const Icon(Icons.copy),
            label: Text(loc.cloudCopyAction),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cloudSkipAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cloudSavedContinueAction),
          ),
        ],
      ),
    );
  }

  /// Lets the user store the Secret Key in a local text file via the
  /// platform's save dialog (picker on mobile, save dialog on desktop).
  Future<void> _saveSecretKeyToFile(String secretKey, String email) async {
    final loc = AppLocalizations.of(context);
    final formatted = formatSecretKey(secretKey);
    final content =
        'OpenValut Cloud Secret Key\n'
        '========================\n'
        '${loc.cloudAccountLabel(email)}\n'
        'Secret Key：$formatted\n'
        '\n'
        '${loc.cloudLoginRequiresNote}\n'
        '${loc.cloudSecretKeepSafeNote}\n';
    final suggestedName =
        'openvalut-secret-key-${email.replaceAll('@', '_at_')}.txt';
    try {
      if (OpenValutPlatform.isIOS || OpenValutPlatform.isAndroid) {
        await FilePickerWritable().openFileForCreate(
          fileName: suggestedName,
          writer: (file) async {
            await file.writeAsString(content);
          },
        );
      } else {
        final location = await getSaveLocation(suggestedName: suggestedName);
        if (location == null) {
          return; // User canceled.
        }
        await io.File(location.path).writeAsString(content);
      }
      if (!mounted) {
        return;
      }
      await DialogUtils.showSimpleAlertDialog(
        context,
        loc.cloudSavedTitle,
        loc.cloudSavedToFileBody,
        routeAppend: 'secretKeySaved',
      );
    } on Exception catch (e, stackTrace) {
      _logger.warning('Unable to save Secret Key to file', e, stackTrace);
      if (!mounted) {
        return;
      }
      await DialogUtils.showErrorDialog(
        context,
        loc.cloudSaveFailedTitle,
        loc.cloudSaveFailedBody('$e'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_scanMode) {
      return _buildScanBody(theme);
    }
    return _buildManualBody(theme);
  }

  Widget _buildManualBody(ThemeData theme) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(
                  Icons.cloud,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  _registerMode ? loc.cloudRegisterTitle : loc.cloudLoginTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _registerMode
                      ? loc.cloudRegisterIntro
                      : (!OpenValutPlatform.isAndroid &&
                            !OpenValutPlatform.isIOS)
                      ? loc.cloudLoginIntroDesktop
                      : loc.cloudLoginIntro,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _serverUrl,
                  decoration: InputDecoration(
                    labelText: loc.cloudServerUrlLabel,
                    prefixIcon: const Icon(Icons.dns_outlined),
                    helperText: loc.cloudServerUrlHelp,
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) {
                      return loc.cloudServerUrlRequired;
                    }
                    if (!value.startsWith('http://') &&
                        !value.startsWith('https://')) {
                      return loc.cloudServerUrlInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  decoration: InputDecoration(
                    labelText: loc.cloudEmailLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: _registerMode
                      ? TextInputAction.next
                      : TextInputAction.done,
                  onFieldSubmitted: _registerMode
                      ? (_) => _vaultNameFocus.requestFocus()
                      : (_) => _submit(),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) {
                      return loc.cloudEmailRequired;
                    }
                    if (value.contains(' ')) {
                      return loc.cloudEmailNoSpaces;
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return loc.cloudEmailInvalid;
                    }
                    return null;
                  },
                ),
                if (!_registerMode) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _secretKey,
                    decoration: InputDecoration(
                      labelText: loc.cloudSecretKeyLabel,
                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                    ),
                    keyboardType: TextInputType.visiblePassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        _masterPasswordFocus.requestFocus(),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) {
                        return loc.cloudSecretKeyRequired;
                      }
                      if (RegExp(r'[^0-9a-fA-F-]').hasMatch(value)) {
                        return loc.cloudSecretKeyChars;
                      }
                      final clean = value.replaceAll('-', '');
                      return RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(clean)
                          ? null
                          : loc.cloudSecretKeyLength;
                    },
                  ),
                  const SizedBox(height: 12),
                  PasswordInputField(
                    controller: _masterPassword,
                    labelText: loc.cloudMasterPasswordLabel,
                    focusNode: _masterPasswordFocus,
                    showVisibilityToggle: true,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return loc.cloudMasterPasswordRequired;
                      }
                      if (v.contains(' ')) {
                        return loc.cloudPasswordNoSpaces;
                      }
                      return null;
                    },
                  ),
                ],
                if (_registerMode) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vaultName,
                    focusNode: _vaultNameFocus,
                    decoration: InputDecoration(
                      labelText: loc.cloudVaultNameLabel,
                      prefixIcon: const Icon(Icons.label_outline),
                    ),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        _masterPasswordFocus.requestFocus(),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) {
                        return loc.cloudVaultNameRequired;
                      }
                      if (value.startsWith(RegExp(r'[0-9]'))) {
                        return loc.cloudVaultNameNoLeadingDigit;
                      }
                      if (!RegExp(
                        r'^[\u4e00-\u9fa5a-zA-Z0-9]+$',
                      ).hasMatch(value)) {
                        return loc.cloudVaultNameChars;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  PasswordInputField(
                    controller: _masterPassword,
                    labelText: loc.cloudMasterPasswordLabel,
                    focusNode: _masterPasswordFocus,
                    showVisibilityToggle: true,
                    onChanged: (value) {
                      final userInput = _vaultName.text.pathCase.split(
                        CharConstants.slash,
                      );
                      setState(() {
                        if (value.isEmpty) {
                          _strength = null;
                        } else {
                          _strength = _zxcvbn.evaluate(
                            value,
                            userInputs: userInput,
                          );
                        }
                      });
                    },
                    onFieldSubmitted: (_) =>
                        _masterPasswordConfirmFocus.requestFocus(),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return loc.cloudMasterPasswordMin6;
                      }
                      if (v.contains(' ')) {
                        return loc.cloudPasswordNoSpaces;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  PasswordStrengthDisplay(strength: _strength),
                  const SizedBox(height: 12),
                  PasswordInputField(
                    controller: _masterPasswordConfirm,
                    labelText: loc.cloudConfirmMasterPasswordLabel,
                    focusNode: _masterPasswordConfirmFocus,
                    showVisibilityToggle: true,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) => v != _masterPassword.text
                        ? loc.cloudPasswordMismatch
                        : null,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _registerMode
                              ? loc.cloudRegisterSubmit
                              : loc.cloudLoginSubmit,
                        ),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () {
                          setState(() {
                            _registerMode = !_registerMode;
                            _secretKey.clear();
                            _error = null;
                          });
                        },
                  child: Text(
                    _registerMode
                        ? loc.cloudSwitchToLogin
                        : loc.cloudSwitchToRegister,
                  ),
                ),
                if (!OpenValutPlatform.isAndroid && !OpenValutPlatform.isIOS)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () {
                            setState(() {
                              _scanMode = true;
                              _error = null;
                            });
                            _startScanLogin();
                          },
                    child: Text(loc.cloudUseQrLogin),
                  ),
                const SizedBox(height: 8),
                Text(
                  loc.cloudServerInfo(_serverUrl.text),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanBody(ThemeData theme) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Icon(
                Icons.qr_code_2,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                loc.cloudQrLoginTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                loc.cloudQrLoginDescription,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _scanQrContent == null
                      ? const SizedBox(
                          width: 220,
                          height: 220,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : QrImageView(
                          data: _scanQrContent!,
                          size: 220,
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _scanError ?? loc.cloudScanWaiting,
                textAlign: TextAlign.center,
                style: _scanError == null
                    ? theme.textTheme.bodyMedium
                    : TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _scanBusy ? null : _startScanLogin,
                icon: const Icon(Icons.refresh),
                label: Text(loc.cloudRefreshQr),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              TextButton(
                onPressed: _stopScanLogin,
                child: Text(loc.cloudBackToManual),
              ),
              const SizedBox(height: 8),
              Text(
                loc.cloudServerInfo(_serverUrl.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
