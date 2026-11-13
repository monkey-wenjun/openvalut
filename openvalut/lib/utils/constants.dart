import 'package:string_literal_finder_annotations/string_literal_finder_annotations.dart';

@NonNls
class AppConstants {
  static const openvalut = 'OpenValut'; // NON-NLS
  static const openvalutCloud = 'OpenValut Cloud'; // NON-NLS

  /// Whether to use the Rust vault implementation on Android.
  ///
  /// Enabled at build time with `--dart-define=OPENVALUT_RUST_VAULT=true`.
  /// When enabled, unlocking, entry listing and saving prefer the Rust core
  /// vault and fall back to the Dart `kdbx` package on failure.
  static const useRustVault = bool.fromEnvironment(
    'OPENVALUT_RUST_VAULT',
    defaultValue: false,
  );

  static const routeOpenFile = '/openFile'; // NON-NLS
  static const routeOpenFileParamFile = 'file'; // NON-NLS
  /// OpenValut Cloud based share code
  static const routeOpenFileParamToken = 'token'; // NON-NLS
  static const routeOpen = '/open'; // NON-NLS

  static const kdbxExtension = '.kdbx'; // NON-NLS
  static const pngExtension = '.png'; // NON-NLS
  static const pngExtensionNoDot = 'png'; // NON-NLS

  static const contentTypeTextPlain = 'text/plain'; // NON-NLS

  static const openvalutHost = 'openvalut.app';
  static const openvalutUrl = 'https://$openvalutHost';
  static const openvalutCloudInfoUrl = '$openvalutUrl/docs/openvalut-cloud/';
  static final openvalutInstall = Uri.parse(
    'https://openvalut.app/docs/getting-started/#installation--getting-started',
  );
  static const openvalutWebApp = 'https://web.openvalut.app';
  static final openvalutWebAppUri = Uri.parse('$openvalutWebApp/');

  static const utmCampaign = 'utm_campaign';
  static const utmSource = 'utm_source';
  static const utmSourceValue = 'app';
}

extension UriAnalytics on Uri {
  Uri utmCampaign(@NonNls String campaign) {
    return replace(
      queryParameters: <String, List<String>>{
        ...queryParametersAll,
        AppConstants.utmCampaign: [campaign],
        AppConstants.utmSource: [AppConstants.utmSourceValue],
      },
    );
  }
}

@NonNls
class CharConstants {
  static const empty = ''; // NON-NLS
  static const underScore = '_'; // NON-NLS
  static const plus = '+'; // NON-NLS

  static const space = ' '; // NON-NLS
  static const curlyOpen = '{'; // NON-NLS

  static const chevronRight = ' » '; // NON-NLS

  static const slash = '/'; // NON-NLS
  static const newLine = '\n'; // NON-NLS

  static const colon = ':'; // NON-NLS
  static const comma = ',';

  static const semiColon = ';'; // NON-NLS

  static const equalSign = '=';

  static const star = '*';

  static const questionMark = '?';
}

class AssetConstants {
  @NonNls
  static const imageOnboardingHeader = 'assets/images/onboarding-header.webp';
  @NonNls
  static const imageOnboardingButtonOpen = 'assets/images/safe-filled-v2.webp';

  @NonNls
  static String imageOnboardingButtonCreate =
      'assets/images/safe-empty-v2.webp';

  @NonNls
  static String logoWithText = 'assets/images/logo_with_text.png';

  @NonNls
  static String logoIcon = 'assets/images/logo_icon.png';

  @NonNls
  static String logoIconWindows = 'assets/images/logo_icon.ico';

  @NonNls
  static String logoIconTray = 'assets/images/logo_icon_tray.png';
}

class UrlConstants {
  static const forumUrl = 'https://forum.openvalut.app/'; // NON-NLS
}
