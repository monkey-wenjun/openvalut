import 'package:openvalut/env/_base.dart';
import 'package:openvalut/main.dart';
import 'package:openvalut/utils/constants.dart';
import 'package:openvalut/utils/extension_methods.dart';
import 'package:openvalut/utils/platform.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:string_literal_finder_annotations/string_literal_finder_annotations.dart';

final _logger = Logger('env');

const _DEFAULT_APP_NAME = AppConstants.openvalut;
@NonNls
const _DEFAULT_VERSION = String.fromEnvironment(
  'openvalut_VERSION',
  defaultValue: '1.0.0',
);
@NonNls
const _DEFAULT_BUILD_NUMBER = int.fromEnvironment(
  'openvalut_BUILD_NUMBER',
  defaultValue: 1,
);
@NonNls
const _DEFAULT_PACKAGE_NAME = String.fromEnvironment(
  'openvalut_PACKAGE_NAME',
  defaultValue: 'design.codeux.openvalut.dev',
);

abstract class EnvAppBase extends Env {
  EnvAppBase(super.type);

  @NonNls
  static const _ENV_STORAGE_NAMESPACE = 'openvalut_STORAGE_NAMESPACE';

  @override
  EnvSecrets? get secrets;

  //  String get oauthRedirectUri => 'openvalut://oauth/code';
  @NonNls
  @override
  String? get oauthRedirectUri => oauthRedirectUriSupported
      // for clients not supporting https:// handling, it will redirect
      // to openvalut://
      ? 'https://links.openvalut.app/app/oauth/code'
      : null;
  @override
  bool get oauthRedirectUriSupported =>
      OpenValutPlatform.isIOS ||
      OpenValutPlatform.isAndroid ||
      OpenValutPlatform.isMacOS;

  @override
  String? get storageNamespaceFromEnvironment =>
      OpenValutPlatform.environment[_ENV_STORAGE_NAMESPACE];

  Future<void> start() async {
    await startApp(this);
  }

  @override
  Future<AppInfo> getAppInfo() async {
    final pi = await _getPackageInfo();
    return AppInfo(
      (b) => b
        ..appName = pi?.appName.nullIfBlank() ?? _DEFAULT_APP_NAME
        ..version = pi?.version.nullIfBlank() ?? _DEFAULT_VERSION
        ..buildNumber =
            int.tryParse(
              pi?.buildNumber.nullIfBlank() ?? _DEFAULT_BUILD_NUMBER.toString(),
            ) ??
            _DEFAULT_BUILD_NUMBER
        ..packageName = pi?.packageName.nullIfBlank() ?? _DEFAULT_PACKAGE_NAME,
    );
  }

  Future<PackageInfo?> _getPackageInfo() async {
    try {
      // linux and windows don't support this right now.
      if (OpenValutPlatform.isWeb ||
          OpenValutPlatform.isLinux ||
          OpenValutPlatform.isWindows) {
        return null;
      }
      return await PackageInfo.fromPlatform();
    } on PlatformException catch (e, stackTrace) {
      _logger.severe('Error getting package info', e, stackTrace);
      return null;
    }
  }
}
