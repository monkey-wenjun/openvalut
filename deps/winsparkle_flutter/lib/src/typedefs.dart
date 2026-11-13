part of 'winsparkle_flutter.dart';

// ignore_for_file: non_constant_identifier_names

// https://github.com/vslavik/winsparkle/blob/master/include/winsparkle.h

// /**
//     Starts WinSparkle.
//     If WinSparkle is configured to check for updates on startup, proceeds
//     to perform the check. You should only call this function when your app
//     is initialized and shows its main window.
//     @note This call doesn't block and returns almost immediately. If an
//           update is available, the respective UI is shown later from a separate
//           thread.
//     @see win_sparkle_cleanup()
//  */
// WIN_SPARKLE_API void __cdecl win_sparkle_init();

typedef win_sparkle_init_native = Void Function();
typedef win_sparkle_init_dart = void Function();

final win_sparkle_init =
    _winsparkle.lookupFunction<win_sparkle_init_native, win_sparkle_init_dart>(
        'win_sparkle_init');

// /**
//     Cleans up after WinSparkle.
//     Should be called by the app when it's shutting down. Cancels any
//     pending Sparkle operations and shuts down its helper threads.
//  */
// WIN_SPARKLE_API void __cdecl win_sparkle_cleanup();

typedef win_sparkle_cleanup_native = Void Function();
typedef win_sparkle_cleanup_dart = void Function();

final win_sparkle_cleanup = _winsparkle.lookupFunction<
    win_sparkle_cleanup_native,
    win_sparkle_cleanup_dart>('win_sparkle_cleanup');

// /**
//     Sets URL for the app's appcast.
//     Only http and https schemes are supported.
//     If this function isn't called by the app, the URL is obtained from
//     Windows resource named "FeedURL" of type "APPCAST".
//     @param url  URL of the appcast.
//     @note Always use HTTPS feeds, do not use unencrypted HTTP! This is
//           necessary to prevent both leaking user information and preventing
//           various MITM attacks.
//     @note See https://github.com/vslavik/winsparkle/wiki/Appcast-Feeds for
//           more information about appcast feeds.
//  */
// WIN_SPARKLE_API void __cdecl win_sparkle_set_appcast_url(const char *url);

typedef win_sparkle_set_appcast_url_native = Void Function(Pointer<Utf8> url);
typedef win_sparkle_set_appcast_url_dart = void Function(Pointer<Utf8> url);

final win_sparkle_set_appcast_url = _winsparkle.lookupFunction<
    win_sparkle_set_appcast_url_native,
    win_sparkle_set_appcast_url_dart>('win_sparkle_set_appcast_url');

// /**
//     Sets DSA public key.
//     Only PEM format is supported.
//     Public key will be used to verify DSA signature of the update file.
//     PEM data will be set only if it contains valid DSA public key.
//     If this function isn't called by the app, public key is obtained from
//     Windows resource named "DSAPub" of type "DSAPEM".
//     @param dsa_pub_pem  DSA public key in PEM format.
//     @return  1 if valid DSA public key provided, 0 otherwise.
//     @since 0.6.0
//  */
// WIN_SPARKLE_API int __cdecl win_sparkle_set_dsa_pub_pem(const char *dsa_pub_pem);
typedef win_sparkle_set_dsa_pub_pem_native = Void Function(
    Pointer<Utf8> dsa_pub_pem);
typedef win_sparkle_set_dsa_pub_pem_dart = void Function(
    Pointer<Utf8> dsa_pub_pem);

final win_sparkle_set_dsa_pub_pem = _winsparkle.lookupFunction<
    win_sparkle_set_dsa_pub_pem_native,
    win_sparkle_set_dsa_pub_pem_dart>('win_sparkle_set_dsa_pub_pem');

// /**
//     Sets application metadata.
//     Normally, these are taken from VERSIONINFO/StringFileInfo resources,
//     but if your application doesn't use them for some reason, using this
//     function is an alternative.
//     @param company_name  Company name of the vendor.
//     @param app_name      Application name. This is both shown to the user
//                          and used in HTTP User-Agent header.
//     @param app_version   Version of the app, as string (e.g. "1.2" or "1.2rc1").
//     @note @a company_name and @a app_name are used to determine the location
//           of WinSparkle settings in registry.
//           (HKCU\Software\<company_name>\<app_name>\WinSparkle is used.)
//     @since 0.3
//     @see win_sparkle_set_app_build_version();
//  */
// WIN_SPARKLE_API void __cdecl win_sparkle_set_app_details(const wchar_t *company_name,
//                                                          const wchar_t *app_name,
//                                                          const wchar_t *app_version);

typedef win_sparkle_set_app_details_native = Void Function(
  Pointer<Utf16> company_name,
  Pointer<Utf16> app_name,
  Pointer<Utf16> app_version,
);
typedef win_sparkle_set_app_details_dart = void Function(
  Pointer<Utf16> company_name,
  Pointer<Utf16> app_name,
  Pointer<Utf16> app_version,
);

final win_sparkle_set_app_details = _winsparkle.lookupFunction<
    win_sparkle_set_app_details_native,
    win_sparkle_set_app_details_dart>('win_sparkle_set_app_details');

// /**
//     Sets application build version number.
//     This is the internal version number that is not normally shown to the user.
//     It can be used for finer granularity that official release versions, e.g. for
//     interim builds.
//     If this function is called, then the provided *build* number is used for comparing
//     versions; it is compared to the "version" attribute in the appcast and corresponds
//     to OS X Sparkle's CFBundleVersion handling. If used, then the appcast must
//     also contain the "shortVersionString" attribute with human-readable display
//     version string. The version passed to win_sparkle_set_app_details()
//     corresponds to this and is used for display.
//     @since 0.4
//     @see win_sparkle_set_app_details()
//  */
// WIN_SPARKLE_API void __cdecl win_sparkle_set_app_build_version(const wchar_t *build);

typedef win_sparkle_set_app_build_version_native = Void Function(
    Pointer<Utf16> build);
typedef win_sparkle_set_app_build_version_dart = void Function(
    Pointer<Utf16> build);

final win_sparkle_set_app_build_version = _winsparkle.lookupFunction<
        win_sparkle_set_app_build_version_native,
        win_sparkle_set_app_build_version_dart>(
    'win_sparkle_set_app_build_version');

// /**
//     Set custom HTTP header for appcast checks.
//     @since 0.7
//     @see win_sparkle_clear_http_headers()
// */
// WIN_SPARKLE_API void __cdecl win_sparkle_set_http_header(const char *name, const char *value);

typedef win_sparkle_set_http_header_native = Void Function(
    Pointer<Utf8> name, Pointer<Utf8> value);
typedef win_sparkle_set_http_header_dart = void Function(
    Pointer<Utf8> build, Pointer<Utf8> value);

final win_sparkle_set_http_header = _winsparkle.lookupFunction<
    win_sparkle_set_http_header_native,
    win_sparkle_set_http_header_dart>('win_sparkle_set_http_header');

// /**
//     Clears all custom HTTP headers previously added using
//     win_sparkle_set_http_header().
//     @since 0.7
//     @see win_sparkle_set_http_header()
// */
// WIN_SPARKLE_API void __cdecl win_sparkle_clear_http_headers();

typedef win_sparkle_clear_http_headers_native = Void Function(
    Pointer<Utf8> name, Pointer<Utf8> value);
typedef win_sparkle_clear_http_headers_dart = void Function(
    Pointer<Utf8> build, Pointer<Utf8> value);

final win_sparkle_clear_http_headers = _winsparkle.lookupFunction<
    win_sparkle_clear_http_headers_native,
    win_sparkle_clear_http_headers_dart>('win_sparkle_clear_http_headers');

//     Checks if an update is available, showing progress UI to the user.
//     Normally, WinSparkle checks for updates on startup and only shows its UI
//     when it finds an update. If the application disables this behavior, it
//     can hook this function to "Check for updates..." menu item.
//     When called, background thread is started to check for updates. A small
//     window is shown to let the user know the progress. If no update is found,
//     the user is told so. If there is an update, the usual "update available"
//     window is shown.
//     This function returns immediately.
//     @note Because this function is intended for manual, user-initiated checks
//           for updates, it ignores "Skip this version" even if the user checked
//           it previously.
//     @see win_sparkle_check_update_without_ui()
//  */
// WIN_SPARKLE_API void __cdecl win_sparkle_check_update_with_ui();

typedef win_sparkle_check_update_with_ui_native = Void Function();
typedef win_sparkle_check_update_with_ui_dart = void Function();

final win_sparkle_check_update_with_ui = _winsparkle.lookupFunction<
    win_sparkle_check_update_with_ui_native,
    win_sparkle_check_update_with_ui_dart>('win_sparkle_check_update_with_ui');

// /**
//     Checks if an update is available, showing progress UI to the user and
//     immediately installing the update if one is available.
//     This is useful for the case when users should almost always use the
//     newest version of your software. When called, WinSparkle will check for
//     updates showing a progress UI to the user. If an update is found the update
//     prompt will be skipped and the update will be installed immediately.
//     If your application expects to do something after checking for updates you
//     may wish to use win_sparkle_set_did_not_find_update_callback() and
//     win_sparkle_set_update_cancelled_callback().
//     @since 0.5
//     @see win_sparkle_set_did_find_update_callback()
//     @see win_sparkle_set_update_cancelled_callback()
//  */
// WIN_SPARKLE_API void __cdecl win_sparkle_check_update_with_ui_and_install();

typedef win_sparkle_check_update_with_ui_and_install_native = Void Function();
typedef win_sparkle_check_update_with_ui_and_install_dart = void Function();

final win_sparkle_check_update_with_ui_and_install = _winsparkle.lookupFunction<
        win_sparkle_check_update_with_ui_and_install_native,
        win_sparkle_check_update_with_ui_and_install_dart>(
    'win_sparkle_check_update_with_ui_and_install');

// /**
//     Checks if an update is available.
//     No progress UI is shown to the user when checking. If an update is
//     available, the usual "update available" window is shown; this function
//     is *not* completely UI-less.
//     Use with caution, it usually makes more sense to use the automatic update
//     checks on interval option or manual check with visible UI.
//     This function returns immediately.
//     @note This function respects "Skip this version" choice by the user.
//     @since 0.4
//     @see win_sparkle_check_update_with_ui()
//  */
// WIN_SPARKLE_API void __cdecl win_sparkle_check_update_without_ui();

typedef win_sparkle_check_update_without_ui_native = Void Function();
typedef win_sparkle_check_update_without_ui_dart = void Function();

final win_sparkle_check_update_without_ui = _winsparkle.lookupFunction<
        win_sparkle_check_update_without_ui_native,
        win_sparkle_check_update_without_ui_dart>(
    'win_sparkle_check_update_without_ui');
