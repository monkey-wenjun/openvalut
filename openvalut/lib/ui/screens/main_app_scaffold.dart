import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kdbx/kdbx.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/bloc/analytics.dart';
import 'package:openvalut/bloc/app_data.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';
import 'package:openvalut/env/_base.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/main.dart';
import 'package:openvalut/theme.dart';
import 'package:openvalut/ui/screens/entry_details.dart';
import 'package:openvalut/ui/screens/password_list.dart';
import 'package:openvalut/ui/widgets/keyboard_handler.dart';
import 'package:openvalut/ui/widgets/primary_button.dart';
import 'package:openvalut/ui/widgets/utils/back_button_navigator_delegate.dart';
import 'package:openvalut/utils/constants.dart';
import 'package:openvalut/utils/sidebar_prefs.dart';
import 'package:provider/provider.dart';

final _logger = Logger('main_app_scaffold');

class MainAppScaffold extends StatefulWidget {
  const MainAppScaffold({super.key});

  static MaterialPageRoute<void> route() => MaterialPageRoute(
    settings: const RouteSettings(name: '/main'),
    builder: (context) => const MainAppScaffold(),
  );

  @override
  _MainAppScaffoldState createState() => _MainAppScaffoldState();
}

class _MainAppScaffoldState extends State<MainAppScaffold> {
  KdbxBloc? _kdbxBloc;

  @override
  void initState() {
    super.initState();
    _kdbxBloc = Provider.of<KdbxBloc>(context, listen: false);
    _kdbxBloc!.cloudNetworkError.addListener(_handleNetworkError);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleNetworkError());
  }

  @override
  void dispose() {
    _kdbxBloc?.cloudNetworkError.removeListener(_handleNetworkError);
    super.dispose();
  }

  /// Shows a persistent "connection lost" banner while the OpenValut Cloud
  /// server is unreachable; it stays until the user dismisses it or the
  /// network recovers.
  void _handleNetworkError() {
    final loc = AppLocalizations.of(context);
    final bloc = _kdbxBloc;
    final messenger = ScaffoldMessenger.of(context);
    if (bloc == null) {
      return;
    }
    if (bloc.cloudNetworkError.value) {
      messenger.showMaterialBanner(
        MaterialBanner(
          content: Text(loc.offlineBannerTitle),
          leading: const Icon(Icons.cloud_off),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          actions: <Widget>[
            TextButton(
              onPressed: () => messenger.hideCurrentMaterialBanner(),
              child: Text(loc.close),
            ),
          ],
        ),
      );
    } else {
      messenger.hideCurrentMaterialBanner();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final systemWideShortcuts = context.select<AppData, bool>(
      (appData) => appData.systemWideShortcuts,
    );
    _logger.finer('size.width: ${mediaQuery.size.width}');
    if (mediaQuery.size.width >= Breakpoints.TABLET_WIDTH) {
      return KeyboardHandler(
        systemWideShortcuts: systemWideShortcuts,
        child: MainAppTabletScaffold(),
      );
    }
    return KeyboardHandler(
      systemWideShortcuts: systemWideShortcuts,
      child: BackButtonNavigatorDelegate(
        observers: [
          AnalyticsNavigatorObserver(Provider.of<Analytics>(context)),
        ],
        onGenerateRoute: null,
        onGenerateInitialRoutes: (navigator, initialRoute) => [
          PasswordList.route(),
        ],
      ),
    );
  }
}

class MainAppTabletScaffold extends StatefulWidget {
  @override
  _MainAppTabletScaffoldState createState() => _MainAppTabletScaffoldState();
}

/// Workaround for the search text field losing focus when pushing
/// a second route.
/// https://github.com/flutter/flutter/issues/53441
class FocusWorkaroundPageRoute<T> extends MaterialPageRoute<T> {
  FocusWorkaroundPageRoute({
    super.settings,
    required super.builder,
    this.focusNode,
  });

  final FocusNode? focusNode;

  @override
  void install() {
    super.install();
    _logger.fine('focusNode: $focusNode');
    focusNode!.addListener(_changedFocus);
  }

  void _changedFocus() {
    _logger.finest(
      'Changed focus. ${focusNode!.hasFocus} --- isCurrent:$isCurrent',
    );
    if (!focusNode!.hasFocus) {
      focusNode!.requestFocus();
    }
  }

  @override
  TickerFuture didPush() {
    final ret = super.didPush();
    ret.then((value) {
      focusNode!.removeListener(_changedFocus);
    }); // focusNode.requestFocus());
    return ret;
  }
}

class _MainAppTabletScaffoldState extends State<MainAppTabletScaffold> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey();
  final GlobalKey<ScaffoldState> _passwordListScaffoldKey = GlobalKey();
  KdbxEntry? _selectedEntry;

  @override
  void initState() {
    super.initState();
    unawaited(SidebarPrefs.load());
    // HardwareKeyboard.instance.addHandler(_debugEvent);
    // RawKeyboard.instance.addListener(_debugEvent);
  }

  //   bool _debugEvent(KeyEvent ev) {
  // //    final keys = RawKeyboard.instance.keysPressed.map((k) => '${k.keyId} (${k.keyLabel})');
  // //    _logger.fine('Got key event. $keys');
  //   return false;
  //   }

  @override
  void dispose() {
    // HardwareKeyboard.instance.removeHandler(_debugEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SidebarPrefs.persistentEnabled,
      builder: (context, persistentSidebar, child) {
        final availableWidth = MediaQuery.of(context).size.width;
        const defaultLeftPaneWidth = 384.0;
        const persistentLeftPaneWidth = 600.0;
        const minRightPaneWidth = 384.0;
        final leftPaneWidth = persistentSidebar
            ? min(
                persistentLeftPaneWidth,
                max(defaultLeftPaneWidth, availableWidth - minRightPaneWidth),
              )
            : defaultLeftPaneWidth;
        return Row(
          children: <Widget>[
            SizedBox(
              width: leftPaneWidth,
              child: Navigator(
                onGenerateRoute: (settings) {
                  assert(settings.name == Navigator.defaultRouteName);
                  return MaterialPageRoute<void>(
                    settings: settings,
                    builder: (context) => PasswordList(
                      scaffoldKey: _passwordListScaffoldKey,
                      selectedEntry: _selectedEntry,
                      onEntrySelected: (entry, type) {
                        if (_selectedEntry != entry) {
                          final Future<dynamic> push;
                          // if (type == EntrySelectionType.passiveHighlight) {
                          //   push = _navigatorKey.currentState!.pushAndRemoveUntil(
                          //     FocusWorkaroundPageRoute<void>(
                          //       focusNode: WidgetsBinding
                          //           .instance
                          //           .focusManager
                          //           .primaryFocus,
                          //       settings: const RouteSettings(name: '/entry'),
                          //       builder: (context) => EntryDetailsScreen(
                          //         entry: entry,
                          //       ),
                          //     ),
                          //     (route) => route.isFirst,
                          //   );
                          // } else {
                          push = _navigatorKey.currentState!.pushAndRemoveUntil(
                            PageRouteBuilder<void>(
                              settings: const RouteSettings(name: '/entry'),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      EntryDetailsScreen(entry: entry),
                            ),
                            (route) => route.isFirst,
                          );
                          // }
                          push.then((dynamic value) {
                            _logger.finer('entry route was popped.');
                            if (entry == _selectedEntry && mounted) {
                              setState(() => _selectedEntry = null);
                            }
                          });
                          setState(() {
                            _selectedEntry = entry;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (_) =>
                    _passwordListScaffoldKey.currentState?.closeDrawer(),
                child: Navigator(
                  key: _navigatorKey,
                  requestFocus: false,
                  onGenerateRoute: (settings) {
                    assert(settings.name == Navigator.defaultRouteName);
                    return PageRouteBuilder<void>(
                      settings: settings,
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          EmptyStateInitialRoute(),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class EmptyStateInitialRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: Ink(
        color: Theme.of(context).cardColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ...Theme.of(context).brightness == Brightness.light
                  ? [
                      Image.asset(AssetConstants.logoWithText),
                    ]
                  : [
                      const SizedBox(height: 64),
                      Image.asset(AssetConstants.logoIcon),
                      Text(
                        Env.OpenValut,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      Text(
                        loc.openvalutHomeScreenTagline,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 64),
                    ],
              // const Text('Select a password.'),
              const SizedBox(height: 32),
              PrimaryButton(
                onPressed: () {
                  final newEntry = context.read<KdbxBloc>().createEntry();
                  Navigator.of(
                    context,
                  ).push(EntryDetailsScreen.route(entry: newEntry));
                },
                child: Text(loc.addNewPasswordButtonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
