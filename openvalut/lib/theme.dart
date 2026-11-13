import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/utils/platform.dart';
import 'package:string_literal_finder_annotations/string_literal_finder_annotations.dart';

final _logger = Logger('theme');

class OpenValutTheme {
  @NonNls
  static const monoFontFamily = 'JetBrainsMono';

  // MiSans covers both Latin and Simplified Chinese with a consistent,
  // modern look; it is the app's default UI typeface on every platform.
  @NonNls
  static const fontFamily = 'MiSans';

  //  static const Color linkColor = Colors.blueAccent;
  static const int _primaryColorValue = 0xFF3B66F4;
  static const Color primaryColor = Color(_primaryColorValue);
  static const Color linkColor = primaryColor;
  static const MaterialColor primarySwatch = MaterialColor(
    _primaryColorValue,
    <int, Color>{
      50: Color(0xFFEDF1FF),
      100: Color(0xFFDCE4FF),
      200: Color(0xFFB9C8FF),
      300: Color(0xFF92A9FF),
      400: Color(0xFF6B88FF),
      500: Color(0xFF3B66F4),
      600: Color(0xFF2F54D8),
      700: Color(0xFF2544B4),
      800: Color(0xFF1D3691),
      900: Color(0xFF15296F),
    },
  );

  static const defaultFileColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    primaryColor,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
  ];
  static const defaultColorOrder = [
    Colors.blue,
    Colors.indigo,
    Colors.orange,
    Colors.red,
  ];
}

abstract class Breakpoints {
  static const TABLET_WIDTH = 720;
}

// during development use getters :-)
//ThemeData get openvalutLightTheme => createTheme();
//ThemeData get openvalutDarkTheme => createDarkTheme();
final openvalutLightTheme = createTheme();
final openvalutDarkTheme = createDarkTheme();

/// Page transition builder that immediately shows the new page without any
/// animation. Used on desktop to avoid the mobile-style slide/fade effects.
class _NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

ThemeData _customize(ThemeData base) {
  final isDesktop =
      OpenValutPlatform.isLinux ||
      OpenValutPlatform.isWindows ||
      OpenValutPlatform.isMacOS;
  final pageTransitionBuilders = {...const PageTransitionsTheme().builders};
  if (isDesktop) {
    // Disable page transition animations on desktop.
    for (final platform in TargetPlatform.values) {
      pageTransitionBuilders[platform] =
          const _NoAnimationPageTransitionsBuilder();
    }
  } else {
    pageTransitionBuilders[TargetPlatform.macOS] =
        const FadeUpwardsPageTransitionsBuilder();
  }
  // Linux/Windows desktop: keep a compact 14px-base text scale instead of the
  // larger Material defaults, so the UI matches dense desktop apps.
  final compactDesktopText =
      OpenValutPlatform.isLinux || OpenValutPlatform.isWindows;
  var theme = base;
  if (compactDesktopText) {
    final tt = theme.textTheme;
    theme = theme.copyWith(
      textTheme: tt.copyWith(
        titleMedium: tt.titleMedium?.copyWith(fontSize: 14),
        titleLarge: tt.titleLarge?.copyWith(fontSize: 16),
        bodyLarge: tt.bodyLarge?.copyWith(fontSize: 14),
        labelLarge: tt.labelLarge?.copyWith(fontSize: 14),
      ),
    );
  }
  return theme.copyWith(
    // androidOverscrollIndicator: AndroidOverscrollIndicator.stretch,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: pageTransitionBuilders,
    ),
  );
}

bool _addedMiSansLicense = false;

Typography _getTypography() {
  _logger.info(
    'using default theme $defaultTargetPlatform -- ${OpenValutPlatform.operatingSystemVersion}',
  );
  // MiSans is bundled for every platform; applying it globally gives the app
  // a consistent modern typeface for both Latin and Simplified Chinese text.
  if (!_addedMiSansLicense) {
    LicenseRegistry.addLicense(() async* {
      final license = await rootBundle.loadString(
        nonNls('assets/fonts/misans/MiSans-LICENSE.txt'),
      );
      yield LicenseEntryWithLineBreaks([nonNls('fonts_misans')], license);
    });
    _addedMiSansLicense = true;
  }
  final base = Typography.material2021(platform: defaultTargetPlatform);
  return Typography(
    platform: defaultTargetPlatform,
    black: base.black.apply(fontFamily: nonNls(OpenValutTheme.fontFamily)),
    white: base.white.apply(fontFamily: nonNls(OpenValutTheme.fontFamily)),
  );
}

ThemeData createTheme() => _buildTheme(dark: false);

ThemeData createDarkTheme() => _buildTheme(dark: true);

ThemeData _buildTheme({required bool dark}) {
  final bg = Color(dark ? 0xFF141519 : 0xFFF6F7F9);
  final surface = Color(dark ? 0xFF1D1F25 : 0xFFFFFFFF);
  final surfaceAlt = Color(dark ? 0xFF262930 : 0xFFEFF1F4);
  final primary = Color(dark ? 0xFF7C9BFF : 0xFF3B66F4);
  final onPrimary = Colors.white;
  // Material 3 in dark mode makes the legacy `theme.primaryColor` fall back
  // to surface (near-black) instead of the accent. Widgets that still style
  // filled buttons/links from `theme.primaryColor` therefore went black in
  // dark mode; pin it to the same visible accent the filled buttons use.
  final buttonPrimary = dark ? const Color(0xFF5B7BFA) : primary;
  final primaryContainer = Color(dark ? 0xFF25315C : 0xFFE2E9FF);
  final onPrimaryContainer = Color(dark ? 0xFFDCE4FF : 0xFF14256B);
  final text = Color(dark ? 0xFFECEEF2 : 0xFF1C2129);
  final textSecondary = Color(dark ? 0xFFADB3BF : 0xFF5F6672);
  final outline = Color(dark ? 0xFF2C2F36 : 0xFFE0E3E8);
  final outlineVariant = Color(dark ? 0xFF2C2F36 : 0xFFE0E3E8);

  final colorScheme = ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: Color(dark ? 0xFFAEB6C4 : 0xFF5B6472),
    onSecondary: dark ? Color(0xFF1A1D22) : Colors.white,
    secondaryContainer: Color(dark ? 0xFF2B2F38 : 0xFFE4E8EF),
    onSecondaryContainer: Color(dark ? 0xFFE0E4EC : 0xFF1F2633),
    error: Color(0xFFD93A3A),
    onError: Colors.white,
    errorContainer: Color(0xFFFFE0E0),
    onErrorContainer: Color(0xFF7A1212),
    surface: surface,
    onSurface: text,
    surfaceContainerHighest: surfaceAlt,
    onSurfaceVariant: textSecondary,
    outline: outline,
    outlineVariant: outlineVariant,
    shadow: Color(0xFF0F1420),
    scrim: Color(0x99000000),
    inverseSurface: Color(dark ? 0xFFECEEF2 : 0xFF2B3038),
    onInverseSurface: Color(dark ? 0xFF1C2129 : 0xFFF1F2F5),
    inversePrimary: Color(dark ? 0xFFAFC2FF : 0xFF6B88FF),
    surfaceTint: primary,
  );

  final radius = BorderRadius.circular(12);
  final radiusSmall = BorderRadius.circular(9);
  final border = BorderSide(color: outlineVariant, width: 1);

  WidgetStateProperty<Color?> selectedOr(Color? selected) =>
      WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return selected;
        }
        return null;
      });

  final isDesktop =
      OpenValutPlatform.isLinux ||
      OpenValutPlatform.isWindows ||
      OpenValutPlatform.isMacOS;
  // Keep a small, dense icon scale on desktop: macOS upstream already uses 13,
  // other desktop platforms (Linux/Windows) use 14 to match system trays and
  // menus on high-DPI laptops. Mobile keeps the default touch-friendly size.
  final compactIconSize = isDesktop
      ? (OpenValutPlatform.isMacOS ? 13.0 : 14.0)
      : null;
  // Desktop text stays compact: prominent text drops to a 14px base instead
  // of 16-17px. Mobile keeps the larger Material defaults for readability.
  final compactDesktopText =
      OpenValutPlatform.isLinux || OpenValutPlatform.isWindows;

  return _customize(
    ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      primaryColor: buttonPrimary,
      // Keep the compact desktop icon sizing local to macOS. Applying it
      // globally makes touch targets look undersized on mobile.
      iconTheme: IconThemeData(size: compactIconSize, color: text),
      primaryIconTheme: IconThemeData(size: compactIconSize),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(iconSize: compactIconSize),
      ),
      primarySwatch: OpenValutTheme.primarySwatch,
      typography: _getTypography(),
      // On desktop disable ripple/splash and hover highlight animations.
      splashFactory: isDesktop ? NoSplash.splashFactory : null,
      highlightColor: isDesktop ? Colors.transparent : null,
      hoverColor: isDesktop ? Colors.transparent : null,
      focusColor: isDesktop ? Colors.transparent : null,
      scaffoldBackgroundColor: bg,
      canvasColor: surface,
      dividerColor: outlineVariant,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: 0.22),
        selectionHandleColor: primary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        iconTheme: IconThemeData(color: text, size: compactIconSize),
        actionsIconTheme: IconThemeData(
          color: text,
          size: compactIconSize,
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        titleTextStyle: TextStyle(
          fontSize: compactDesktopText ? 14 : 17,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: border,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        labelStyle: TextStyle(
          color: dark ? const Color(0xFFC6CBD5) : textSecondary,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: dark ? const Color(0xFFB6BCC7) : textSecondary,
        ),
        prefixIconColor: dark ? const Color(0xFFB6BCC7) : textSecondary,
        suffixIconColor: dark ? const Color(0xFFB6BCC7) : textSecondary,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1.2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: buttonPrimary,
          foregroundColor: onPrimary,
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: border,
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: text,
        shape: RoundedRectangleBorder(borderRadius: radiusSmall),
        selectedColor: primary,
        selectedTileColor: primaryContainer.withValues(alpha: 0.55),
        titleTextStyle: TextStyle(
          fontSize: compactDesktopText ? 14 : 15,
          fontWeight: FontWeight.w500,
          color: text,
        ),
        subtitleTextStyle: TextStyle(fontSize: 13, color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: bg,
        indicatorColor: primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        selectedIconTheme: IconThemeData(color: onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: textSecondary),
        selectedLabelTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: onPrimaryContainer,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontSize: 12,
          color: textSecondary,
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        titleTextStyle: TextStyle(
          fontSize: compactDesktopText ? 15 : 18,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        contentTextStyle: TextStyle(fontSize: 14, color: textSecondary),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: TextStyle(fontSize: 14, color: text),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? Color(0xFF2C3038) : Color(0xFF23262C),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        selectedColor: primaryContainer,
        labelStyle: TextStyle(fontSize: 13, color: text),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: radiusSmall),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark ? Color(0xFF3A3E48) : Color(0xFF2B2F38),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => textSecondary.withValues(alpha: 0.45),
        ),
        radius: const Radius.circular(6),
        thickness: const WidgetStatePropertyAll(6),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      dividerTheme: DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: 1,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: selectedOr(primary),
        side: BorderSide(color: textSecondary.withValues(alpha: 0.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(fillColor: selectedOr(primary)),
      switchTheme: SwitchThemeData(
        thumbColor: selectedOr(primary),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.45);
          }
          return null;
        }),
      ),
      textTheme:
          Typography.material2021(
                platform: defaultTargetPlatform,
              ).black
              .apply(
                fontFamily: nonNls(OpenValutTheme.fontFamily),
                bodyColor: text,
                displayColor: text,
              )
              .copyWith(
                titleMedium: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: text,
                ),
                titleLarge: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
                bodyMedium: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: text,
                ),
                bodySmall: TextStyle(fontSize: 12.5, color: textSecondary),
                labelLarge: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
    ),
  );
}
