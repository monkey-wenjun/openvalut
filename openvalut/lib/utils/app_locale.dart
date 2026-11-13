/// Runtime handle to the locale currently used by the MaterialApp.
///
/// Native/system surfaces (tray menus, biometric prompts, exception messages
/// built outside widgets) can consult this instead of hard-coding Chinese.
class AppLocale {
  AppLocale._();

  /// Set by the app builder once the resolved locale is known
  /// (see `main.dart`). Null until the first frame.
  static String? localeName;

  static bool get isChinese =>
      (localeName ?? '').toLowerCase().startsWith('zh');
}
