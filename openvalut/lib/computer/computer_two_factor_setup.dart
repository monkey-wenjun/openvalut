import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:kdbx/kdbx.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';
import 'package:openvalut/computer/computer_identity.dart';
import 'package:openvalut/computer/pam_totp_file.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/ssh/machine_identity.dart';
import 'package:openvalut/utils/base32utils.dart';
import 'package:openvalut/utils/otpauth.dart';

final _logger = Logger('computer_two_factor_setup');

/// Runs a root command. Injected so unit tests can fake the elevated system
/// setup; when not injected, `autoConfigure` runs it as `sudo -S` using the
/// password the user typed once in the app (instead of a second polkit prompt).
typedef RootCommandRunner =
    Future<ProcessResult> Function(
      List<String> args,
    );

/// Outcome of an auto-configuration attempt.
class ComputerTwoFactorSetupResult {
  const ComputerTwoFactorSetupResult.ok(this.message) : ok = true, error = null;

  const ComputerTwoFactorSetupResult.failure(this.error)
    : ok = false,
      message = '';

  final bool ok;
  final String? message;
  final String? error;
}

/// One-shot provisioning of the current computer's two-step verification:
/// 1. Creates/updates the dedicated "计算机" vault entry with the current OS
///    user, the sudo password and a TOTP secret.
/// 2. Writes the machine-bound encrypted PAM TOTP file.
/// 3. Ensures the `pam_openvalut` module, the sudo askpass helper and the
///    `/etc/pam.d/sudo` line are present. Runs as `sudo -S` using the
///    password entered once in the app, so the user isn't prompted again.
class ComputerTwoFactorSetup {
  ComputerTwoFactorSetup._();

  /// Asset paths bundled into the Linux build (see `pubspec.yaml` + the
  /// module build step in `_tools/build-deb.sh`).
  static const _pamModuleAsset = 'assets/linux/pam_openvalut.so'; // NON-NLS
  static const _askpassAsset = 'assets/linux/openvalut-sudo-askpass'; // NON-NLS

  /// Uniquely identifies the group the computer details live in.
  static const _machineIdKey = 'machine-id'; // NON-NLS

  /// Entry label used for the otpauth URI when the entry has no label.
  static const _otpLabel = 'OpenValut'; // NON-NLS

  /// The generated secret is 160-bit (20 random bytes -> 32 base32 chars).
  static const _secretBytes = 20;

  /// Runs the full setup. [sudoPassword] is stored in the vault entry; in the
  /// Linux desktop the same password is what the system asks for when
  /// `sudo`ing, so it is also what unlocks the PAM-backed TOTP gate.
  static Future<ComputerTwoFactorSetupResult> autoConfigure({
    required KdbxBloc kdbxBloc,
    required String sudoPassword,
    AppLocalizations? loc,
    String? currentUser,
    String? machineId,
    String? hostname,
    RootCommandRunner? rootRunner,
  }) async {
    final files = kdbxBloc.openedFilesKdbx;
    if (files.isEmpty) {
      return ComputerTwoFactorSetupResult.failure(
        loc == null ? '没有打开的密码库' : loc.twoFactorNoOpenVault,
      );
    }
    final file = files.first;
    final user =
        (currentUser ??
                Platform.environment['USER'] ??
                Platform.environment['USERNAME'] ??
                '')
            .trim();
    if (user.isEmpty) {
      return ComputerTwoFactorSetupResult.failure(
        loc == null ? '无法确定当前系统用户名' : loc.twoFactorNoUsername,
      );
    }
    final mid = machineId ?? MachineIdentity.machineId;
    final host = hostname ?? MachineIdentity.hostname;
    if (mid.isEmpty || host.isEmpty) {
      return ComputerTwoFactorSetupResult.failure(
        loc == null ? '无法确定本机标识' : loc.twoFactorNoMachineId,
      );
    }
    if (sudoPassword.isEmpty) {
      return ComputerTwoFactorSetupResult.failure(
        loc == null ? 'sudo 密码不能为空' : loc.twoFactorEmptySudoPassword,
      );
    }

    try {
      // 1. Computer entry ------------------------------------------------
      final entry = ComputerIdentity.ensureEntry(file);
      // Reuse an existing OTP so the user's authenticator stays valid;
      // otherwise mint a fresh secret.
      final existingOtp = ComputerIdentity.getTotp(entry);
      final otpRaw = existingOtp != null && existingOtp.isNotEmpty
          ? existingOtp
          : buildOtpUri(
              user: user,
              host: host,
              secret: _randomSecret(),
            );
      entry.setString(
        KdbxKeyCommon.USER_NAME,
        PlainValue(user),
      );
      entry.setString(
        KdbxKeyCommon.PASSWORD,
        ProtectedValue.fromString(sudoPassword),
      );
      entry.setString(KdbxKeyCommon.OTP, PlainValue(otpRaw));
      entry.setString(KdbxKey(_machineIdKey), PlainValue(mid));
      await kdbxBloc.saveFile(file);

      // 2. Encrypted PAM TOTP file --------------------------------------
      final secretBase32 = extractBase32Secret(otpRaw);
      final pamPath = await PamTotpFile.write(secretBase32);
      if (pamPath == null) {
        return ComputerTwoFactorSetupResult.failure(
          loc == null
              ? '无法写入加密 TOTP 文件（缺少 machine-id 或主目录）'
              : loc.twoFactorTotpFileWriteFailed,
        );
      }
      await _backupTotp(pamPath, otpRaw, mid);

      // 3. Root system configuration -------------------------------------
      final result = await _configureSystem(
        rootRunner: rootRunner,
        sudoPassword: sudoPassword,
        loc: loc,
      );
      if (result != null) {
        return ComputerTwoFactorSetupResult.failure(
          loc == null
              ? '系统配置未完成：$result'
              : loc.twoFactorSystemSetupIncomplete(result),
        );
      }
      return ComputerTwoFactorSetupResult.ok(
        loc == null
            ? '计算机两步验证已配置完成，sudo 现在会额外要求输入一次性验证码。'
            : loc.twoFactorConfiguredDone,
      );
    } catch (e, stackTrace) {
      _logger.warning(
        'Computer two-step auto-configure failed.',
        e,
        stackTrace,
      );
      return ComputerTwoFactorSetupResult.failure(
        loc == null ? '配置失败：$e' : loc.twoFactorConfigFailed('$e'),
      );
    }
  }

  /// Reverts the system-side two-step verification that [autoConfigure]
  /// enabled: deletes the machine-bound encrypted TOTP file (which alone makes
  /// the PAM module silently succeed), then best-effort removes the
  /// `pam_openvalut` line from `/etc/pam.d/sudo`.
  ///
  /// The TOTP file lives in the user's own home, so removing it needs no
  /// elevation and cannot deadlock on the very gate it closes. The PAM-line
  /// cleanup does need root (`pkexec`); a failure there is reported but not
  /// fatal, because the gate is already off without the file.
  static Future<ComputerTwoFactorSetupResult> disable({
    String? currentUser,
    String? machineId,
    RootCommandRunner? rootRunner,
    AppLocalizations? loc,
  }) async {
    final user =
        (currentUser ??
                Platform.environment['USER'] ??
                Platform.environment['USERNAME'] ??
                '')
            .trim();
    final home = Platform.environment['HOME'] ?? '';
    final mid = machineId ?? MachineIdentity.machineId;
    if (user.isEmpty || home.isEmpty || mid.isEmpty) {
      return ComputerTwoFactorSetupResult.failure(
        loc == null ? '无法确定用户名/主目录/本机标识' : loc.twoFactorIdentityMissing,
      );
    }
    final totpFile = '$home/.openvalut/totp/$mid.enc';

    // 1. Effective gate-off at the user level.
    String? localErr;
    try {
      final f = File(totpFile);
      if (f.existsSync()) {
        await f.delete();
      }
    } catch (e, stackTrace) {
      _logger.warning('Unable to delete PAM TOTP file.', e, stackTrace);
      localErr = e.toString();
    }

    // 2. Best-effort cleanup of the PAM line / sudoers drop-in.
    final script =
        '''
set -e
_pamfile=/etc/pam.d/sudo
if [ -e "\$_pamfile" ]; then
  sed -i '/pam_openvalut\\.so/d' "\$_pamfile"
fi
rm -f /etc/sudoers.d/openvalut-totp /etc/sudoers.d/openvalut-totp.disabled
rm -f "$totpFile"
''';
    String? sysErr;
    final runner = rootRunner ?? _pkexecRunner;
    try {
      final result = await runner(['bash', '-c', script]);
      if (result.exitCode != 0) {
        final err = result.stderr.toString().trim();
        sysErr = err.isEmpty
            ? (loc == null ? '用户取消或认证失败' : loc.twoFactorUserCancelled)
            : err;
        _logger.warning('PAM cleanup via pkexec failed: $sysErr');
      }
    } catch (e, stackTrace) {
      _logger.warning('PAM cleanup failed.', e, stackTrace);
      sysErr = e.toString();
    }

    if (localErr != null && sysErr != null) {
      return ComputerTwoFactorSetupResult.failure(
        loc == null
            ? '无法删除 TOTP 文件（$localErr），且系统清理失败（$sysErr）'
            : loc.twoFactorTotpFileDeleteFailed(localErr, sysErr),
      );
    }
    if (sysErr != null) {
      return ComputerTwoFactorSetupResult.ok(
        loc == null
            ? '已关闭两步验证（sudo 不再要求验证码）。'
                  '未能移除 /etc/pam.d/sudo 中的 PAM 行。'
            : loc.twoFactorDisabledPamFailed,
      );
    }
    return ComputerTwoFactorSetupResult.ok(
      loc == null ? '已关闭系统两步验证，sudo 不再要求一次性验证码。' : loc.twoFactorDisabledDone,
    );
  }

  /// Generates a `otpauth://` URI for a freshly generated TOTP secret.
  static String buildOtpUri({
    required String user,
    required String host,
    required Uint8List secret,
  }) {
    final label = '$_otpLabel:$user@$host';
    final otp = OtpAuth(
      label: label,
      secret: secret,
      algorithm: OtpAuth.DEFAULT_ALGORITHM,
      digits: OtpAuth.DEFAULT_DIGITS,
      period: OtpAuth.DEFAULT_PERIOD,
    );
    final uri = otp.toUri();
    return uri
        .replace(
          queryParameters: {
            ...uri.queryParameters,
            'issuer': _otpLabel, // NON-NLS
          },
        )
        .toString();
  }

  /// Returns the normalized base32 secret from an `otpauth://` URI, a KeeOTP
  /// query string or a bare base32 value.
  static String extractBase32Secret(String raw) {
    final value = raw.trim();
    if (value.startsWith(OtpAuth.URI_PREFIX)) {
      return base32Encode(OtpAuth.fromUri(Uri.parse(value)).secret);
    }
    final fromQuery = OtpAuth.fromQueryString(value);
    if (fromQuery != null) {
      return base32Encode(fromQuery.secret);
    }
    return base32Encode(base32Decode(value));
  }

  static Uint8List _randomSecret() {
    final random = Random.secure();
    final bytes = Uint8List(_secretBytes);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  /// Keeps a recoverable copy of the machine-bound TOTP config and a
  /// human-readable secret/URI so the authenticator can be re-enrolled if the
  /// vault entry is ever lost.
  static Future<void> _backupTotp(
    String encPath,
    String otpRaw,
    String machineId,
  ) async {
    try {
      final home =
          Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '';
      if (home.isEmpty) {
        return;
      }
      final dir = Directory('$home/.config/openvalut/totp-backups');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final encFile = File(encPath);
      if (encFile.existsSync()) {
        final dst = File('${dir.path}/$machineId.enc');
        if (dst.existsSync()) {
          await dst.delete();
        }
        await encFile.copy(dst.path);
      }
      final secretFile = File('${dir.path}/totp-secret.txt');
      await secretFile.writeAsString(
        '# OpenValut 计算机 TOTP 备份（勿泄露）\n'
        '# machine-id: $machineId\n'
        '# hostname:   ${MachineIdentity.hostname}\n'
        'secret=${extractBase32Secret(otpRaw)}\n'
        'uri=$otpRaw\n',
        flush: true,
      );
      await Process.run('chmod', ['600', dir.path]);
      await Process.run('chmod', ['600', '${dir.path}/$machineId.enc']);
      await Process.run('chmod', ['600', secretFile.path]);
    } catch (e, stackTrace) {
      _logger.warning('Unable to back up the TOTP config.', e, stackTrace);
    }
  }

  /// Writes the bundled module + askpass to temp files, then asks the desktop
  /// polkit agent (via `pkexec`) to install them and enable the PAM stack.
  /// Returns an error message on failure, or null on success.
  static Future<String?> _configureSystem({
    RootCommandRunner? rootRunner,
    String? sudoPassword,
    AppLocalizations? loc,
  }) async {
    // Idempotent re-run: once the PAM gate is active, both `sudo -S` and
    // `pkexec` need the TOTP code the module enforces, so a second enable
    // would deadlock. If the module and the `/etc/pam.d/sudo` line are already
    // in place there is nothing left to elevate for, so skip root entirely.
    if (_alreadyConfigured()) {
      return null;
    }
    final runner =
        rootRunner ??
        (sudoPassword != null && sudoPassword.isNotEmpty
            ? (args) => _sudoRunner(args, sudoPassword)
            : _pkexecRunner);
    final String modSrc;
    final String askSrc;
    try {
      modSrc = await _writeAssetToTemp(_pamModuleAsset, 'pam_openvalut.so');
      askSrc = await _writeAssetToTemp(
        _askpassAsset,
        'openvalut-sudo-askpass',
      );
    } catch (e, stackTrace) {
      _logger.warning('Unable to stage bundled system files.', e, stackTrace);
      return loc == null
          ? '无法读取内置的 PAM 模块/askpass 文件：$e'
          : loc.twoFactorAssetReadFailed('$e');
    }

    // % is escaped as %% for printf; "/etc/pam.d" files use a literal
    // "#%PAM-1.0" first line.
    final script =
        '''
set -e
mkdir -p /opt/openvalut/pam
install -m 0644 $modSrc /opt/openvalut/pam/pam_openvalut.so
install -m 0755 $askSrc /opt/openvalut/openvalut-sudo-askpass
PAMFILE=/etc/pam.d/sudo
if [ -e "\$PAMFILE" ]; then
  cp -p "\$PAMFILE" "\$PAMFILE.bak"
  # TOTP must live in the *account* stack so it runs on every sudo even when
  # the password timestamp is cached (the auth stack is skipped then).
  sed -i "s|^[[:space:]]*auth[[:space:]]*required[[:space:]]*/opt/openvalut/pam/pam_openvalut.so|account    required   /opt/openvalut/pam/pam_openvalut.so|" "\$PAMFILE"
  if ! grep -q 'account[[:space:]]*required[[:space:]]*/opt/openvalut/pam/pam_openvalut.so' "\$PAMFILE"; then
    printf '\\n# OpenValut TOTP verification.\\naccount    required   %s\\n' /opt/openvalut/pam/pam_openvalut.so >> "\$PAMFILE"
  fi
else
  printf '#%%PAM-1.0\\n\\n# Set up user limits from /etc/security/limits.conf.\\nsession    required   pam_limits.so\\n\\n@include common-auth\\n@include common-account\\n@include common-session-noninteractive\\n\\n# OpenValut TOTP verification.\\naccount    required   %s\\n' /opt/openvalut/pam/pam_openvalut.so > "\$PAMFILE"
fi
# Restore default password caching: drop any forced "re-auth every time".
if [ -e /etc/sudoers.d/openvalut-totp ]; then
  mv /etc/sudoers.d/openvalut-totp /etc/sudoers.d/openvalut-totp.disabled
fi
''';
    final result = await runner([
      'bash',
      '-c',
      script,
    ]);
    if (result.exitCode != 0) {
      final err = result.stderr.toString().trim();
      final message = err.isEmpty
          ? (loc == null ? '用户取消或认证失败' : loc.twoFactorUserCancelled)
          : err;
      return loc == null
          ? 'pkexec 未能完成（退出码 ${result.exitCode}）：$message'
          : loc.twoFactorPkexecFailed(result.exitCode, message);
    }
    _logger.fine('System two-step configuration completed.');
    return null;
  }

  static Future<String> _writeAssetToTemp(String asset, String name) async {
    final data = await rootBundle.load(asset);
    final tmpDir = Directory.systemTemp.createTempSync('openvalut-setup-');
    final file = File('${tmpDir.path}/$name');
    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    await Process.run('chmod', ['0644', file.path]);
    return file.path;
  }

  /// Default root runner: `pkexec` triggers the desktop polkit agent, which
  /// verifies the OS password without the app ever handling it as a string.
  static Future<ProcessResult> _pkexecRunner(List<String> args) {
    return Process.run('pkexec', args);
  }

  /// Whether the Linux PAM stack is already wired up for this machine, so the
  /// enable step can skip re-elevating (see [_configureSystem]).
  static bool _alreadyConfigured() {
    try {
      final pam = File('/etc/pam.d/sudo');
      if (!pam.existsSync()) {
        return false;
      }
      final active = pam
          .readAsStringSync()
          .split('\n')
          .any(
            (line) =>
                line.contains('pam_openvalut.so') &&
                !line.trimLeft().startsWith('#'),
          );
      return active && File('/opt/openvalut/pam/pam_openvalut.so').existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Runs [args] as root via `sudo -S`, feeding the password on stdin. This
  /// keeps configuration to a single prompt in the app rather than asking for
  /// the password again through the polkit dialog.
  static Future<ProcessResult> _sudoRunner(
    List<String> args,
    String password,
  ) async {
    final process = await Process.start('sudo', ['-S', ...args]);
    process.stdin.write('$password\n');
    await process.stdin.close();
    final out = process.stdout.transform(utf8.decoder).join();
    final err = process.stderr.transform(utf8.decoder).join();
    final code = await process.exitCode;
    return ProcessResult(process.pid, code, await out, await err);
  }
}
