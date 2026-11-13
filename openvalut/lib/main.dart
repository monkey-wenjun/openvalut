import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:another_flushbar/flushbar_helper.dart';
import 'package:another_flushbar/flushbar_route.dart' as flushbar_route;
import 'package:biometric_storage/biometric_storage.dart';
import 'package:diac_client/diac_client.dart';
import 'package:file/local.dart';
import 'package:file_picker_writable/file_picker_writable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_async_utils/flutter_async_utils.dart';
import 'package:flutter_store_listing/flutter_store_listing.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:kdbx/kdbx.dart';
import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';
import 'package:openvalut/bloc/analytics.dart';
import 'package:openvalut/bloc/app_data.dart';
import 'package:openvalut/bloc/deps.dart';
import 'package:openvalut/bloc/kdbx/file_content.dart';
import 'package:openvalut/bloc/kdbx/file_source.dart';
import 'package:openvalut/bloc/kdbx/file_source_local.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';
import 'package:openvalut/cloud_storage/cloud_storage_bloc.dart';
import 'package:openvalut/credential_server/credential_server_controller.dart';
import 'package:openvalut/env/_base.dart';
import 'package:openvalut/env/fdroid.dart';
import 'package:openvalut/host_bridge/host_bridge.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/ssh/ssh_agent_controller.dart';
import 'package:openvalut/ssh/ssh_config.dart';
import 'package:openvalut/theme.dart';
import 'package:openvalut/ui/common_fields.dart';
import 'package:openvalut/ui/screens/onboarding/onboarding.dart';
import 'package:openvalut/ui/screens/select_file_screen.dart';
import 'package:openvalut/ui/widgets/platform_menu_bar.dart';
import 'package:openvalut/utils/android_autofill.dart';
import 'package:openvalut/utils/app_locale.dart';
import 'package:openvalut/utils/autofill_prefs.dart';
import 'package:openvalut/utils/cache_manager.dart';
import 'package:openvalut/utils/clipboard_prefs.dart';
import 'package:openvalut/utils/constants.dart';
import 'package:openvalut/utils/diac_utils.dart';
import 'package:openvalut/utils/dialog_utils.dart';
import 'package:openvalut/utils/extension_methods.dart';
import 'package:openvalut/utils/file_picker_writable_noop.dart';
import 'package:openvalut/utils/format_utils.dart';
import 'package:openvalut/utils/keep_alive.dart';
import 'package:openvalut/utils/logging_utils.dart';
import 'package:openvalut/utils/path_utils.dart';
import 'package:openvalut/utils/platform.dart';
import 'package:openvalut/utils/secure_window.dart';
import 'package:openvalut/utils/tray.dart';
import 'package:openvalut/utils/unlock_prefs.dart';
import 'package:openvalut/utils/window_prefs.dart';
import 'package:openvalut/utils/window_title_bar.dart';
import 'package:openvalut/utils/winsparkle_init_noop.dart'
    if (dart.library.io) 'package:openvalut/utils/winsparkle_init.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:simple_json_persistence/simple_json_persistence.dart';
import 'package:string_literal_finder_annotations/string_literal_finder_annotations.dart';

final _logger = Logger('main');

const _windowChannel = MethodChannel('openvalut/window'); // NON-NLS

/// Handles the platform "close button" event. The C/GTK side intercepts the
/// close request, asks us what to do, and only really closes when we say so.
void initWindowCloseHandler() {
  if (!OpenValutPlatform.isDesktop) {
    _logger.info('initWindowCloseHandler: not desktop, skipped.');
    return;
  }
  _logger.info('initWindowCloseHandler: registering method call handler.');
  _windowChannel.setMethodCallHandler((call) async {
    _logger.info('Window channel method: ${call.method}');
    switch (call.method) {
      case 'onWindowCloseRequested':
        final action = WindowPrefs.closeAction.value;
        _logger.info(
          'onWindowCloseRequested: closeAction=$action '
          'type=${action.runtimeType} len=${action.length} '
          'codes=${action.codeUnits}',
        );
        switch (action) {
          case 'minimize':
            // Minimize to the taskbar/dock instead of hiding. Keeping the window
            // iconified is more reliable across Linux desktops than hiding it
            // (which can be mistaken for quitting when the tray icon is not
            // visible). The tray menu can still be used to show or quit.
            _logger.info('Close action: minimize to taskbar.');
            await TrayController.minimizeToTaskbar();
          case 'hide':
            // Hide to the system tray. The tray icon stays alive and can be
            // clicked to restore the window.
            _logger.info('Close action: hide to tray.');
            await TrayController.hideToTray();
          case 'exit':
            _logger.info('Close action: exit.');
            await _windowChannel.invokeMethod('close');
          default:
            _logger.warning(
              'Close action: unknown "$action", defaulting to hide.',
            );
            await TrayController.hideToTray();
        }
    }
    return null;
  });
}

void initIsolate({bool fromMain = false}) {
  LoggingUtils().setupLogging(fromMainIsolate: fromMain);
}

void main() => throw Exception('Run some env/*.dart');

final startupStopwatch = Stopwatch();

/// Local socket kept open for the lifetime of the process so only one desktop
/// instance runs at a time. Binding to a fixed loopback port is simpler and
/// more reliable than a PID file (no stale locks after crashes).
// ignore: unused_element
ServerSocket? _singleInstanceSocket;
void Function()? _onSecondInstanceRequested;

const _singleInstancePort = 18293; // NON-NLS

/// Native single-instance dialog shown before the Flutter UI exists, so it
/// follows the OS locale (the in-app language override applies on next start).
String get _instanceAlreadyRunningMessage {
  final zh = (OpenValutPlatform.localeName ?? '').toLowerCase().startsWith(
    'zh',
  );
  return zh
      ? 'OpenValut 正在运行（可能已最小化到系统托盘），请先右键托盘图标选择「退出」后再启动。'
      : 'OpenValut is already running (it may be minimized to the tray). '
            'Right-click the tray icon and choose Quit, then try again.';
}

/// On desktop, bind a loopback socket. If the port is already in use, another
/// OpenValut instance is running: show a native error dialog and exit.
Future<void> _ensureSingleInstance() async {
  if (!OpenValutPlatform.isDesktop) {
    return;
  }
  try {
    _singleInstanceSocket = await ServerSocket.bind(
      InternetAddress.loopbackIPv4,
      _singleInstancePort,
      shared: false,
    );
    _singleInstanceSocket!.listen((socket) {
      // A second launch (launcher icon, file open, tray-less environment)
      // signals the running instance to restore its window.
      socket.destroy();
      _logger.info(
        'Second OpenValut instance requested; showing the running window.',
      );
      _onSecondInstanceRequested?.call();
    });
    _logger.fine('Acquired single-instance lock on port $_singleInstancePort.');
  } on SocketException catch (e, stackTrace) {
    const addressInUseErrorCodes = {
      48, // macOS
      98, // Linux
      10048, // Windows
    };
    if (!addressInUseErrorCodes.contains(e.osError?.errorCode)) {
      _logger.severe(
        'Failed to acquire the single-instance lock.',
        e,
        stackTrace,
      );
      rethrow;
    }
    _logger.warning(
      'Another OpenValut instance is already running; exiting.',
      e,
      stackTrace,
    );
    // Ask the already-running instance to show its window instead of failing
    // with a confusing "already running" dialog.
    final notified = await _notifyRunningInstanceToShow();
    if (!notified) {
      await _showInstanceAlreadyRunningDialog();
    }
    exit(1);
  }
}

/// Connects to the running instance's loopback port. Returns true when the
/// running instance accepted the "show window" signal.
Future<bool> _notifyRunningInstanceToShow() async {
  try {
    final socket = await Socket.connect(
      InternetAddress.loopbackIPv4,
      _singleInstancePort,
    );
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}

/// Shows a platform-native error dialog. Falls back to stderr when no dialog
/// helper is available.
Future<void> _showInstanceAlreadyRunningDialog() async {
  if (OpenValutPlatform.isLinux) {
    final commands = [
      [
        'zenity',
        '--error',
        '--title=OpenValut',
        '--width=420',
        '--height=120',
        '--no-wrap',
        '--text=$_instanceAlreadyRunningMessage',
      ],
      [
        'kdialog',
        '--error',
        _instanceAlreadyRunningMessage,
        '--title',
        'OpenValut',
      ],
    ];
    for (final cmd in commands) {
      try {
        final result = await Process.run(cmd.first, cmd.sublist(1));
        if (result.exitCode == 0) {
          return;
        }
      } catch (_) {
        // Try the next dialog helper.
      }
    }
  } else if (OpenValutPlatform.isMacOS) {
    try {
      await Process.run('osascript', [
        '-e',
        'display alert "OpenValut" message "$_instanceAlreadyRunningMessage"',
      ]);
      return;
    } catch (_) {}
  } else if (OpenValutPlatform.isWindows) {
    try {
      await Process.run('powershell.exe', [
        '-Command',
        'Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show("$_instanceAlreadyRunningMessage", "OpenValut")',
      ]);
      return;
    } catch (_) {}
  }
  stderr.writeln(_instanceAlreadyRunningMessage);
}

Future<void> startApp(Env env) async {
  startupStopwatch
    ..start()
    ..reset();

  StoreBackend.defaultBaseDirectoryBuilder = () async =>
      (await PathUtils().getAppDataDirectory()).path;

  initIsolate(fromMain: true);
  await _ensureSingleInstance();
  _setTargetPlatformForDesktop();
  _logger.info(
    'Initialized logger. '
    '(${OpenValutPlatform.operatingSystem}, ${OpenValutPlatform.operatingSystemVersion}) ${startupStopwatch.elapsedMilliseconds}',
  );
  if (!OpenValutPlatform.isWeb) {
    _logger.info('${OpenValutPlatform.debugInfo()}');
    unawaited(
      Future<dynamic>.delayed(const Duration(seconds: 10)).then((
        dynamic value,
      ) async {
        _logger.info('DeviceInfo: ${await LoggingUtils.getDebugDeviceInfo()}');
      }),
    );
  }

  final navigatorKey = GlobalKey<NavigatorState>();

  if (env.overrideFlutterOnError) {
    FlutterError.onError = (errorDetails) {
      _logger.shout(
        'Unhandled Flutter framework (${errorDetails.library}) error.',
        errorDetails.exception,
        errorDetails.stack,
      );
      _logger.fine(errorDetails.summary.toString());
      Analytics.trackError(
        ErrorSource.flutter,
        errorDetails.summary.toString(),
        true,
      );
    };
  }

  FutureTaskStateMixin.defaultShowErrorDialog = (error) {
    navigatorKey.currentState?.overlay?.context.let((context) {
      DialogUtils.showErrorDialog(
        context,
        error.title,
        error.message,
      );
    });
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    _logger.shout('Unhandled error in app.', error, stackTrace);
    final errorString = error is Exception
        ? error.toStringWithCause()
        : error.toString();
    Analytics.trackError(ErrorSource.dart, error.toString(), true);
    navigatorKey.currentState?.overlay?.context.let((context) {
      String? message = 'Unexpected error: $errorString'; // NON-NLS
      try {
        message = AppLocalizations.of(context).unexpectedError(errorString);
      } catch (e, stackTrace) {
        _logger.fine('Error while localizing error message', e, stackTrace);
      }
      DialogUtils.showErrorDialog(context, null, message);
    });
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();
  if (OpenValutPlatform.isWindows) {
    // biometric_storage ships its Windows implementation as an inline Dart
    // plugin but pins `flutter: ">=2.8.0"`, and the tool only auto-registers
    // inline desktop implementations from Flutter 2.11 on. Register it
    // manually, otherwise saving the cloud account / master password throws
    // MissingPluginException on Windows.
    Win32BiometricStoragePlugin.registerWith();
  }
  final deps = Deps(env: env);
  deps.kdbxBloc.delegate = KdbxBlocDelegateHandler(navigatorKey);
  // 桌面端启动回环桥，让 Chrome 扩展直接读取已解锁的密码库。
  if (OpenValutPlatform.isDesktop) {
    unawaited(
      HostBridge.instance.start(
        kdbxBloc: deps.kdbxBloc,
        onShowWindow: () {
          unawaited(TrayController.showFromTray());
        },
      ),
    );
    await TrayController.init();
    _onSecondInstanceRequested = () {
      unawaited(TrayController.showFromTray());
    };
  }
  final appData = await deps.appDataBloc.store.load();
  await UnlockPrefs.load();
  await WindowPrefs.load();
  await ClipboardPrefs.load();
  await AutofillPrefs.load();
  initWindowCloseHandler();
  final startHidden =
      OpenValutPlatform.isDesktop &&
      Platform.environment['openvalut_START_HIDDEN'] == '1'; // NON-NLS
  if (startHidden) {
    _logger.info(
      'Started with openvalut_START_HIDDEN=1, hiding window to tray.',
    );
    await TrayController.hideToTray();
  }
  runApp(
    OpenValutApp(
      env: env,
      deps: deps,
      navigatorKey: navigatorKey,
      isFirstRun: appData.previousFiles.isEmpty,
    ),
  );
}

class KdbxBlocDelegateHandler extends KdbxBlocDelegate {
  KdbxBlocDelegateHandler(this.navigatorKey);

  GlobalKey<NavigatorState> navigatorKey;

  @override
  void conflictMerged(
    FileSource fileSource,
    KdbxFile file,
    MergeContext merge,
  ) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      return;
    }
    final loc = AppLocalizations.of(context);
    DialogUtils.showSimpleAlertDialog(
      context,
      loc.mergeSuccessDialogTitle,
      loc.mergeSuccessDialogMessage(
        fileSource.displayName,
        merge.debugSummary(),
      ),
      routeAppend: 'merged',
    );
  }
}

/// If the current platform is desktop, override the default platform to
/// a supported platform (iOS for macOS, Android for Linux and Windows).
/// Otherwise, do nothing.
void _setTargetPlatformForDesktop() {
  // this is no longer needed.

  // TargetPlatform? targetPlatform;
  // /*if (OpenValutPlatform.isMacOS) {
  //   targetPlatform = TargetPlatform.iOS;
  // } else */
  // if (OpenValutPlatform.isLinux || OpenValutPlatform.isWindows) {
  //   targetPlatform = TargetPlatform.android;
  // }
  // _logger.info('targetPlatform: $targetPlatform');
  // if (targetPlatform != null) {
  //   debugDefaultTargetPlatformOverride = targetPlatform;
  // }
}

class OpenValutApp extends StatefulWidget {
  const OpenValutApp({
    super.key,
    required this.env,
    required this.navigatorKey,
    required this.deps,
    required this.isFirstRun,
  });

  final Env env;
  final Deps deps;
  final GlobalKey<NavigatorState> navigatorKey;
  final bool isFirstRun;
  @visibleForTesting
  static GlobalKey<NavigatorState>? currentNavigatorKey;

  @override
  // ignore: no_logic_in_create_state
  _OpenValutAppState createState() {
    currentNavigatorKey = navigatorKey;
    return _OpenValutAppState();
  }
}

class _OpenValutAppState extends State<OpenValutApp>
    with StreamSubscriberMixin {
  late final Deps _deps = widget.deps;
  AppData? _appData;
  late final FilePickerState _filePickerState = _initFilePickerState();
  static const _credentialServerChannel = MethodChannel(
    'app.openvalut/misc',
  ); // NON-NLS

  GlobalKey<NavigatorState>? get _navigatorKey => widget.navigatorKey;
  AppLifecycleListener? _appLifecycleListener;

  @override
  void initState() {
    super.initState();
    PathUtils.runAppFinished.complete(true);
    _appData = _deps.appDataBloc.store.cachedValue;
    handleSubscription(
      _deps.appDataBloc.store.onValueChangedAndLoad.listen((appData) {
        if (_appData != appData) {
          setState(() {
            _appData = appData;
          });
        }
      }),
    );
    // Keep the process alive while the vault is open, so the user can switch
    // back to the app without another unlock prompt.
    handleSubscription(
      _deps.kdbxBloc.openedFilesChanged.listen((files) {
        if (files.length == 0) {
          unawaited(SessionKeepAlive.stop());
          unawaited(SshAgentController.instance.stop());
          unawaited(CredentialServerController.instance.stop());
        } else {
          unawaited(SessionKeepAlive.start());
          _syncLocalServices();
        }
      }),
    );
    // React to the service toggles in settings.
    UnlockPrefs.sshAgentEnabled.addListener(_syncLocalServices);
    UnlockPrefs.credentialServerEnabled.addListener(_syncLocalServices);
    _appLifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        await SshAgentController.instance.stop();
        await CredentialServerController.instance.stop();
        return ui.AppExitResponse.exit;
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Keep the managed ssh config reference in sync with the toggle.
      if (UnlockPrefs.sshAgentEnabled.value) {
        unawaited(SshConfig.enable());
      }
    });
    if (OpenValutPlatform.isAndroid) {
      AndroidAutofillCoordinator.instance.init(
        deps: _deps,
        navigatorKey: widget.navigatorKey,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          AndroidAutofillCoordinator.instance.checkForPendingAutofillIntent(),
        );
      });
      handleSubscription(
        _deps.appDataBloc.store.onValueChangedAndLoad
            .map((event) => event.secureWindowOrDefault)
            .distinct()
            .listen((secureWindowOrDefault) {
              if (secureWindowOrDefault) {
                FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
              } else {
                FlutterWindowManager.clearFlags(
                  FlutterWindowManager.FLAG_SECURE,
                );
              }
            }),
      );
    }
    if (OpenValutPlatform.isWindows || OpenValutPlatform.isMacOS) {
      handleSubscription(
        _deps.appDataBloc.store.onValueChangedAndLoad
            .map((event) => event.secureWindowOrDefault)
            .distinct()
            .listen((secureWindowOrDefault) {
              unawaited(SecureWindow.setSecure(secureWindowOrDefault));
            }),
      );
    }
    if (OpenValutPlatform.isWindows) {
      if (OpenValutPlatform.isWindowsWinAutoUpdate) {
        _logger.info('Initializing winsparkle.');
        initWinSparkle(widget.env);
      } else {
        _logger.info('Disabled winsparkle.');
      }
    }
  }

  @override
  void dispose() {
    UnlockPrefs.sshAgentEnabled.removeListener(_syncLocalServices);
    UnlockPrefs.credentialServerEnabled.removeListener(_syncLocalServices);
    _appLifecycleListener?.dispose();
    super.dispose();
  }

  void _syncLocalServices() {
    if (_deps.kdbxBloc.openedFilesKdbx.isEmpty) {
      return;
    }
    // The SSH agent bridge reads /proc/self/exe which is unavailable on
    // Android/iOS, so it stays desktop-only. The loopback credential server
    // itself is cross-platform: on Android sshbot reaches it through the
    // ContentProvider that the host channel below keeps in sync.
    if (OpenValutPlatform.isDesktop) {
      if (UnlockPrefs.sshAgentEnabled.value) {
        unawaited(
          SshAgentController.instance.start(
            identities: _deps.kdbxBloc.sshAgentIdentities,
          ),
        );
      } else {
        unawaited(SshAgentController.instance.stop());
      }
    }
    if (UnlockPrefs.credentialServerEnabled.value) {
      unawaited(
        CredentialServerController.instance.start(
          entries: _deps.kdbxBloc.credentialServerEntries,
          resolveReference: _deps.kdbxBloc.credentialServerResolveReference,
          export: _deps.kdbxBloc.credentialServerExportForReadAccess,
          sudo: _deps.kdbxBloc.credentialServerSudo,
          pamSetup: _deps.kdbxBloc.credentialServerPamSetup,
          onStatus: _publishCredentialServerStatus,
        ),
      );
    } else {
      unawaited(CredentialServerController.instance.stop());
      _publishCredentialServerStatus(null, null);
    }
  }

  void _publishCredentialServerStatus(int? port, String? token) {
    if (!OpenValutPlatform.isAndroid) {
      return;
    }
    unawaited(
      _credentialServerChannel.invokeMethod<void>(
        'updateCredentialServer',
        {
          'running': port != null && token != null,
          'port': port,
          'token': token,
        },
      ),
    );
  }

  FilePickerState _initFilePickerState() {
    // file picker writable currently has only ios, android, macos support.
    if (OpenValutPlatform.isIOS ||
        OpenValutPlatform.isAndroid ||
        OpenValutPlatform.isMacOS) {
      _logger.fine('Register FilePickerWritable listeners.');
      return FilePickerWritable().init()
        ..registerUriHandler((uri) {
          _logger.fine('we have received uri: $uri');
          return false;
        })
        ..registerFileOpenHandler((fileInfo, file) async {
          _logger.fine('got a new fileInfo: $fileInfo');
          Future<void> openRoute() async {
            var i = 0;
            while (_navigatorKey?.currentState == null) {
              _logger.finest('No navigator yet. waiting. $i');
              await Future<void>.delayed(const Duration(milliseconds: 100));
              if (i++ > 100) {
                _logger.warning('Giving up $fileInfo');
                return;
              }
            }
            await _navigatorKey!.currentState!.push(
              CredentialsScreen.route(
                FileSourceLocal(
                  (const LocalFileSystem()).file(file.path),
                  uuid: AppDataBloc.createUuid(),
                  filePickerIdentifier: fileInfo.toJsonString(),
                  initialCachedContent: FileContent(await file.readAsBytes()),
                ),
              ),
            );
          }

          await openRoute();
          return true;
        })
        ..registerErrorEventHandler((errorEvent) async {
          _logger.severe('Error received from file picker. $errorEvent');
          Analytics.trackError(
            ErrorSource.app,
            'FilePickerWritable: $errorEvent',
            false,
          );
          return true;
        });
    } else {
      return FilePickerStateNoop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO generate localizations.
    final view = View.maybeOf(context);
    _logger.fine(
      'Building OpenValut App state. route: '
      '${view?.platformDispatcher.defaultRouteName}',
    );
    return MultiProvider(
      providers: [
        Provider<DiacBloc>(
          create: (context) => _createDiacBloc(),
          dispose: (context, diac) => diac.dispose(),
        ),
        Provider<FilePickerState>.value(value: _filePickerState),
        Provider<Env>.value(value: _deps.env),
        Provider<Deps>.value(value: _deps),
        Provider<Analytics>.value(value: _deps.analytics),
        Provider<CloudStorageBloc>.value(value: _deps.cloudStorageBloc),
        Provider<AppDataBloc>.value(value: _deps.appDataBloc),
        Provider<OpenValutCacheManager>(
          create: (context) => OpenValutCacheManager(
            pathUtils: PathUtils(),
            env: _deps.env,
          ),
          dispose: (context, obj) => obj.store.dispose(),
        ),
        StreamProvider<AppData>(
          create: (context) => _deps.appDataBloc.store.onValueChangedAndLoad,
          initialData: _deps.appDataBloc.store.cachedValue ?? AppData(),
        ),
        ProxyProvider2<AppData, Env, FeatureFlags>(
          update: (_, appData, env, _) {
            if (appData.manualUserType == AppData.manualUserTypeAdmin) {
              return (env.featureFlags.toBuilder()..openvalutCloud = true)
                  .build();
            }
            return env.featureFlags;
          },
        ),
        StreamProvider<KdbxBloc>(
          create: (context) => _deps.kdbxBloc.openedFilesChanged
              .map((_) => _deps.kdbxBloc)
              .doOnData((data) {
                _logger.info('KdbxBloc updated.');
              }),
          updateShouldNotify: (a, b) => true,
          initialData: _deps.kdbxBloc,
        ),
        StreamProvider<OpenedKdbxFiles>.value(
          value: _deps.kdbxBloc.openedFilesChanged,
          initialData: _deps.kdbxBloc.openedFilesChanged.value,
        ),
      ],
      child: MaterialApp(
        navigatorObservers: [AnalyticsNavigatorObserver(_deps.analytics)],
        title: AppConstants.openvalut,
        navigatorKey: widget.navigatorKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        theme: _customizeTheme(openvalutLightTheme, _appData),
        darkTheme: _customizeTheme(openvalutDarkTheme, _appData),
        themeMode: _toThemeMode(_appData?.theme),
        locale: _parseLocale(_appData?.localeOverride),
        //        themeMode: ThemeMode.light,
        builder: (context, child) {
          // The Windows title bar lives outside the Flutter view, so it has to
          // be told the theme explicitly (dark mode otherwise keeps a light
          // frame above a dark window).
          unawaited(
            WindowTitleBar.syncDark(
              Theme.of(context).brightness == Brightness.dark,
            ),
          );
          final mq = MediaQuery.of(context);
          final physicalSize = view?.physicalSize;
          _deps.analytics.updateSizes(
            viewportSizeWidth: mq.size.width,
            viewportSizeHeight: mq.size.height,
            displaySizeWidth: physicalSize?.width,
            displaySizeHeight: physicalSize?.height,
            devicePixelRatio: view?.devicePixelRatio,
          );
          final locale = Localizations.localeOf(context);
          AppLocale.localeName = locale.toString();
          final localizations = AppLocalizations.of(context);
          final Widget ret = MultiProvider(
            providers: [
              Provider.value(value: FormatUtils(locale: locale.toString())),
              Provider<CommonFields>.value(value: CommonFields(localizations)),
            ],
            child: PlatformMenuBarWrapper(
              navigatorKey: _navigatorKey!,
              child: child ?? Container(),
            ),
          );
          final textScaleFactor =
              _appData?.themeFontSizeFactor ??
              (OpenValutPlatform.isMacOS ? 0.9 : null);
          if (textScaleFactor != null) {
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: textScaleFactor,
                end: textScaleFactor,
              ),
              duration: const Duration(milliseconds: 100),
              builder: (context, value, child) {
                return MediaQuery(
                  data: mq.copyWith(textScaler: TextScaler.linear(value)),
                  child: ret,
                );
              },
            );
          }
          return ret;
        },
        // onNavigationNotification: (notification) {
        //   _logger.fine(
        //       'onNavigationNotification: canHandlePop:${notification.canHandlePop} ()');
        //   SystemNavigator.setFrameworkHandlesBack(notification.canHandlePop);
        //   return true;
        // },
        onGenerateInitialRoutes: (initialRoute) {
          _logger.fine('initialRoute: $initialRoute');
          _deps.analytics.trackScreen(initialRoute);
          _deps.analytics.events.trackLaunch(
            systemBrightness: view?.platformDispatcher.platformBrightness,
          );
          if (startupStopwatch.isRunning) {
            startupStopwatch.stop();
            _deps.analytics.trackTiming(
              'startup',
              startupStopwatch.elapsedMilliseconds,
              category: 'startup',
              label: widget.isFirstRun ? 'startup firstRun' : 'startup run',
            );
          }
          if (initialRoute.startsWith(AppConstants.routeOpenFile)) {
            final uri = Uri.parse(initialRoute);
            final token =
                uri.queryParameters[AppConstants.routeOpenFileParamToken];
            if (token != null) {
              _logger.warning(
                'OpenValut Cloud file launch is no longer supported.',
              );
              return [
                MaterialPageRoute<void>(
                  builder: (context) => const SelectFileScreen(
                    skipQuickUnlock: true,
                    autoOpenLast: false,
                  ),
                ),
              ];
            }
            final file =
                uri.queryParameters[AppConstants.routeOpenFileParamFile];
            _logger.finer('uri: $uri /// file: $file');
            return [
              //              MaterialPageRoute<void>(
              //                  builder: (context) => const SelectFileScreen()),
              CredentialsScreen.route(
                FileSourceLocal(
                  (const LocalFileSystem().file(file)),
                  uuid: AppDataBloc.createUuid(),
                ),
              ),
            ];
          }
          return [
            (widget.isFirstRun && widget.env.featureOnboarding
                    ? OnboardingScreen.route()
                    : SelectFileScreen.route(
                        // "每次打开 OpenValut 时显示此页面" 取消勾选时，启动
                        // 直接尝试重开最近的密码库：同一开机时段内已记住
                        // 主密码的话，这里只需要系统密码。
                        skipQuickUnlock:
                            UnlockPrefs.showVaultStartPage.value,
                        autoOpenLast:
                            !UnlockPrefs.showVaultStartPage.value,
                      ))
                as Route<dynamic>,
          ];
        },
        // this is actually never used. But i still have to define it,
        // because of https://github.com/flutter/flutter/blob/f64f6e2b6bf5802f23d6a0e3896541b213be490a/packages/flutter/lib/src/widgets/app.dart#L226-L243
        // (defining a navigatorKey requires defining a `routes`)
        routes: {
          AppConstants.routeOpen: (context) => const SelectFileScreen(
            skipQuickUnlock: true,
            autoOpenLast: false,
          ),
        },
        //        home: const SelectFileScreen(),
      ),
    );
  }

  // TODO maybe support more than language code?
  Locale? _parseLocale(String? localeString) {
    if (localeString == null) {
      return null;
    }
    final parts = localeString.split(CharConstants.underScore);
    if (parts.length == 1) {
      return Locale(parts[0]);
    }
    return Locale(parts[0], parts[1]);
  }

  ThemeMode? _toThemeMode(AppDataTheme? theme) {
    if (theme == null) {
      return null;
    }
    switch (theme) {
      case AppDataTheme.light:
        return ThemeMode.light;
      case AppDataTheme.dark:
        return ThemeMode.dark;
    }
  }

  ThemeData _customizeTheme(ThemeData theme, AppData? appData) {
    if (appData == null) {
      return theme;
    }

    final visualDensity = appData.themeVisualDensity != null
        ? VisualDensity(
            horizontal: appData.themeVisualDensity!,
            vertical: appData.themeVisualDensity!,
          )
        : theme.visualDensity;
    _logger.fine('appData.themeFontSizeFactor: ${appData.themeFontSizeFactor}');
    //    final textTheme = appData.themeFontSizeFactor != null
    //        ? theme.textTheme.apply(fontSizeFactor: appData.themeFontSizeFactor)
    //        : theme.textTheme;
    return theme.copyWith(
      visualDensity: visualDensity,
      //      textTheme: textTheme,
    );
  }

  DiacBloc _createDiacBloc() {
    final disableOnlineMessages =
        _deps.env.diacDefaultDisabled && _appData!.diacOptIn != true;
    _logger.finest(
      '_createDiacBloc: $disableOnlineMessages = '
      '${_deps.env.diacDefaultDisabled} && ${_appData!.diacOptIn}',
    );
    return DiacBloc(
        opts: DiacOpts(
          endpointUrl: _deps.env.diacEndpoint,
          disableConfigFetch: disableOnlineMessages,
          // always reload after a new start.
          refetchIntervalCold: Duration.zero,
          initialConfig: !disableOnlineMessages || _deps.env.diacHidden
              ? null
              : DiacConfig(
                  updatedAt: DateTime(2020, 5, 18),
                  messages: nonNls([
                    DiacMessage(
                      uuid: 'e7373fa7-a793-4ed5-a2d1-d0a037ad778a',
                      body:
                          'Hello ${widget.env is FDroid ? 'F-Droid user' : 'there'}, thanks for using OpenValut! '
                          'I would love to occasionally display relevant news, surveys, etc (like this one ;), '
                          'no ads, spam, etc). You can disable it anytime.',
                      key: 'ask-opt-in',
                      expression: 'user.days > 0',
                      actions: const [
                        DiacMessageAction(
                          key: 'yes',
                          label: '👍️ Yes, Opt In',
                          url: 'diac:diacOptIn',
                        ),
                        DiacMessageAction(
                          key: 'no',
                          label: 'No, Sorry',
                          url: 'diac:diacNoOptIn',
                        ),
                      ],
                    ),
                  ]),
                ),
          packageInfo: () async =>
              (await _deps.env.getAppInfo()).toDiacPackageInfo(),
        ),
        contextBuilder: () async => nonNls({
          'env': <String, Object>{
            'isDebug': _deps.env.isDebug,
            'isGoogleStore':
                (await _deps.env.getAppInfo()).packageName ==
                    'design.codeux.openvalut' &&
                OpenValutPlatform.isAndroid,
            'isIOS': OpenValutPlatform.isIOS,
            'isAndroid': OpenValutPlatform.isAndroid,
            'operatingSystem': OpenValutPlatform.operatingSystem,
          },
          'appData': {
            'manualUserType': _appData?.manualUserType,
          },
        }),
        // TODO: This should probably be translated. Although right now all
        //       messages are english anyway..
        customActions: nonNls({
          'launchReview': (event) async {
            _deps.analytics.trackGenericEvent('review', 'reviewLaunch');
            return await FlutterStoreListing().launchStoreListing();
          },
          'requestReview': (event) async {
            _deps.analytics.trackGenericEvent('review', 'reviewRequest');
            return await FlutterStoreListing().launchRequestReview(
              onlyNative: true,
            );
          },
          'diacOptIn': (event) async {
            final flushbar = FlushbarHelper.createSuccess(
              message: 'Thanks! 🎉️',
            );
            final route = flushbar_route.showFlushbar<void>(
              context: context,
              flushbar: flushbar,
            );
            unawaited(widget.navigatorKey.currentState?.push<void>(route));
            await _deps.appDataBloc.update(
              (builder, data) => builder.diacOptIn = true,
            );
            return true;
          },
          'diacNoOptIn': (event) async {
            final flushbar = FlushbarHelper.createInformation(
              message:
                  '😢️ Too bad, if you ever change your mind, '
                  'check out the preferences 🙏️.',
            );
            final route = flushbar_route.showFlushbar<void>(
              context: context,
              flushbar: flushbar,
            );
            await widget.navigatorKey.currentState?.push<void>(route);
            return true;
          },
        }),
      )
      ..events.listen((event) {
        _deps.analytics.trackGenericEvent(
          'diac',
          event is DiacEventWithAction
              ? '${event.type.toStringBare()}:${event.action?.key}'
              : event.type.toStringBare(),
          label: event.message.key,
        );
      });
  }
}

class AnalyticsNavigatorObserver extends NavigatorObserver {
  AnalyticsNavigatorObserver(this.analytics);

  final Analytics analytics;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logger.finest('didPush');
    _sendScreenView(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _sendScreenView(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _sendScreenView(previousRoute);
  }

  String _screenNameFor(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null) {
      return name;
    }
    assert(
      (() {
        if (route is PopupRoute) {
          return true;
        }
        _logger.severe(
          'Route does not have a named RouteSettings! $route',
          null,
          StackTrace.current,
        );
        return true;
      })(),
    );
    return (route?.runtimeType).toString(); // NON-NLS
  }

  void _sendScreenView(Route<dynamic>? route) {
    final screenName = _screenNameFor(route);
    analytics.trackScreen(screenName);
  }
}
