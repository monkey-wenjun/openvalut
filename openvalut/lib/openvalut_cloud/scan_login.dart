import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/openvalut_cloud/openvalut_cloud_session.dart';
import 'package:openvalut/openvalut_cloud/scan_vault_key.dart';
import 'package:openvalut/ui/screens/barcodescan_screen.dart';

final _logger = Logger('openvalut.scan_login');

/// 移动端扫码入口：扫描 PC 端登录页显示的二维码并确认会话，
/// 之后 PC 免输账号（邮箱 + Secret Key）登录密码库。
Future<void> scanAndConfirmCloudLogin(BuildContext context) async {
  final loc = AppLocalizations.of(context);
  final session = openvalutCloudSession.instance;
  if (session.serverUrl == null ||
      session.serverUrl!.isEmpty ||
      !session.isLoggedIn) {
    _showScanLoginResult(
      context,
      loc.scanLoginNeedAccount,
    );
    return;
  }
  final result = await BarcodeScanHelper.scanBarcode(
    context,
    titleText: loc.menuScanLogin,
    formats: [BarcodeFormat.qrCode],
  );
  if (!context.mounted) {
    return;
  }
  if (result is! ScanResultValid || result.barcode.text.trim().isEmpty) {
    return; // 用户取消扫描
  }
  final text = result.barcode.text.trim();
  const prefix = 'openvalut://scan-login/';
  if (!text.startsWith(prefix)) {
    _showScanLoginResult(
      context,
      loc.scanLoginNotOpenvalutQr,
    );
    return;
  }
  final sessionId = text.substring(prefix.length);
  // PC 的临时公钥由服务器保管（不在二维码里），手机取回后把主密码加密，
  // 随确认一起回传；PC 解密即可直接解锁。手机没有已解锁密码库时，PC 仍
  // 会要求输入主密码。
  String? vaultCiphertext;
  try {
    final encodedPublicKey = await openvalutCloudSession.instance
        .fetchScanPublicKey(sessionId);
    if (encodedPublicKey != null && encodedPublicKey.isNotEmpty) {
      var pw = openvalutCloudSession.instance.vaultMasterPassword;
      if (pw == null || pw.isEmpty) {
        // 指纹快捷解锁只保留密码哈希，拿不到明文；先从系统钥匙串取，
        // 取不到再让用户输一次，之后加密回传给 PC 自动解锁。
        pw = await openvalutCloudSession.instance.loadVaultMasterPassword();
        if (pw == null || pw.isEmpty) {
          if (!context.mounted) {
            return;
          }
          pw = await _promptMasterPassword(context);
          if (pw != null && pw.isNotEmpty) {
            openvalutCloudSession.instance.rememberVaultMasterPassword(pw);
          }
        }
      }
      if (pw != null && pw.isNotEmpty) {
        vaultCiphertext = encryptVaultKeyForScan(
          pw,
          encodedPublicKey,
        );
      }
    }
  } on Exception catch (e, stackTrace) {
    _logger.warning('Unable to fetch scan public key.', e, stackTrace);
  }
  try {
    await openvalutCloudSession.instance.confirmScanLogin(
      sessionId,
      vaultCiphertext: vaultCiphertext,
    );
    if (!context.mounted) {
      return;
    }
    _showScanLoginResult(
      context,
      vaultCiphertext == null
          ? loc.scanLoginConfirmedNoKey
          : loc.scanLoginConfirmedUnlock,
    );
  } on Exception catch (e) {
    if (!context.mounted) {
      return;
    }
    _showScanLoginResult(context, loc.scanLoginConfirmFailed('$e'));
  }
}

/// 手机上没记录到明文主密码时（例如指纹快捷解锁），弹窗让用户输入一次。
Future<String?> _promptMasterPassword(BuildContext context) {
  final loc = AppLocalizations.of(context);
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(loc.scanLoginEnterMasterTitle),
      content: TextField(
        controller: controller,
        obscureText: true,
        autofocus: true,
        decoration: InputDecoration(
          labelText: loc.scanLoginMasterLabel,
          hintText: loc.scanLoginMasterHint,
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: Text(loc.okAction),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

void _showScanLoginResult(BuildContext context, String message) {
  final loc = AppLocalizations.of(context);
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.okAction),
        ),
      ],
    ),
  );
}
