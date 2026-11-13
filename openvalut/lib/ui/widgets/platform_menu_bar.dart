import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/ui/screens/locked_screen.dart';
import 'package:openvalut/ui/screens/preferences.dart';
import 'package:openvalut/ui/screens/select_file_screen.dart';
import 'package:provider/provider.dart';

class PlatformMenuBarWrapper extends StatelessWidget {
  const PlatformMenuBarWrapper({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final kdbxBloc = Provider.of<KdbxBloc>(context);
    final hasOpenFiles = kdbxBloc.openedFilesKdbx.isNotEmpty;
    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: loc.aboutAppName,
          menus: [
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                PlatformMenuItem(
                  label: loc.menuItemPreferences,
                  onSelected: () {
                    navigatorKey.currentState?.push(PreferencesScreen.route());
                  },
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.comma,
                    meta: true,
                  ),
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                PlatformMenuItem(
                  label: loc.menuItemOpenAnotherFile,
                  onSelected: () {
                    navigatorKey.currentState?.push(
                      SelectFileScreen.route(autoOpenLast: false),
                    );
                  },
                ),
                if (hasOpenFiles)
                  PlatformMenuItem(
                    label: loc.lockFiles,
                    onSelected: () {
                      kdbxBloc.closeAllFiles(clearQuickUnlock: false);
                      navigatorKey.currentState?.pushAndRemoveUntil(
                        LockedScreen.route(),
                        (_) => false,
                      );
                    },
                  ),
              ],
            ),
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.quit,
            )) ...[
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.quit,
              ),
            ],
          ],
        ),
      ],
      child: child,
    );
  }
}
