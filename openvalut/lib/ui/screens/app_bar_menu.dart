import 'package:flutter/material.dart';
import 'dart:io' as io;

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker_writable/file_picker_writable.dart';
import 'package:file_selector/file_selector.dart';
import 'package:openvalut/bloc/analytics.dart';
import 'package:openvalut/bloc/kdbx/file_source_ui.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/openvalut_cloud/openvalut_cloud_session.dart';
import 'package:openvalut/openvalut_cloud/scan_login.dart';
import 'package:openvalut/ui/screens/import_passwords_screen.dart';
import 'package:openvalut/ui/screens/locked_screen.dart';
import 'package:openvalut/ui/screens/manage_file.dart';
import 'package:openvalut/ui/screens/password_generator.dart';
import 'package:openvalut/ui/screens/preferences.dart';
import 'package:openvalut/ui/screens/select_file_screen.dart';
import 'package:openvalut/utils/dialog_utils.dart';
import 'package:openvalut/utils/platform.dart';
import 'package:provider/provider.dart';

class AppBarMenu {
  static Iterable<PopupMenuEntry<VoidCallback>> createDefaultPopupMenuItems(
    BuildContext context,
    OpenedKdbxFiles openedKdbxFiles, {
    List<PopupMenuItem<VoidCallback>> Function(BuildContext context)?
    secondaryBuilder,
    bool isOnOpenFileScreen = false,
  }) {
    final openedFiles = openedKdbxFiles.values;
    final analytics = Provider.of<Analytics>(context, listen: false);
    final loc = AppLocalizations.of(context);
    return [
      PopupMenuItem(
        value: () {
          analytics.events.trackActionPressed(action: 'generatePassword');
          Navigator.of(context).push(
            PasswordGeneratorScreen.route(finishButton: FinishButtonStyle.save),
          );
        },
        child: ListTile(
          key: const ValueKey('openPasswordGenerator'),
          leading: const FaIcon(FontAwesomeIcons.shuffle),
          title: Text(loc.menuItemGeneratePassword),
        ),
      ),
      PopupMenuItem(
        value: () {
          Navigator.of(context).push(ImportPasswordsScreen.route());
        },
        child: ListTile(
          key: const ValueKey('importPasswords'),
          leading: const Icon(Icons.file_download_outlined),
          title: Text(loc.menuImportPasswords),
        ),
      ),
      PopupMenuItem(
        value: () => _exportCsv(context),
        child: ListTile(
          key: const ValueKey('exportCsv'),
          leading: const Icon(Icons.file_upload_outlined),
          title: Text(loc.menuExportCsv),
        ),
      ),
      if (openvalutCloudSession.instance.isLoggedIn &&
          (OpenValutPlatform.isAndroid || OpenValutPlatform.isIOS)) ...[
        PopupMenuItem(
          value: () => scanAndConfirmCloudLogin(context),
          child: ListTile(
            key: const ValueKey('scanQrCloudLogin'),
            leading: const Icon(Icons.qr_code_scanner),
            title: Text(loc.menuScanLogin),
          ),
        ),
      ],
      PopupMenuItem(
        value: () {
          analytics.events.trackActionPressed(action: 'preferences');
          Navigator.of(context, rootNavigator: true).push(
            PreferencesScreen.route(),
          );
        },
        child: ListTile(
          leading: const FaIcon(FontAwesomeIcons.gears),
          title: Text(loc.menuItemPreferences),
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: () {
          analytics.events.trackActionPressed(action: 'about');
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(loc.menuAboutOpenvalut),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.menuAuthorName),
                  const SizedBox(height: 4),
                  const Text('2026.08'),
                  const SizedBox(height: 4),
                  Text(
                    '${loc.menuEmailPrefix}'
                    '${String.fromEnvironment(
                      'openvalut_CONTACT_EMAIL',
                      defaultValue: 'hi@example.com',
                    )}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${loc.menuBlogPrefix}'
                    '${String.fromEnvironment(
                      'openvalut_WEBSITE_URL',
                      defaultValue: 'https://www.example.com',
                    )}',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(loc.okAction),
                ),
              ],
            ),
          );
        },
        child: ListTile(
          leading: const FaIcon(FontAwesomeIcons.circleInfo),
          title: Text(loc.menuAbout),
        ),
      ),
      ...?(openedFiles.isNotEmpty != true
          ? null
          : (<PopupMenuEntry<VoidCallback>>[
              const PopupMenuDivider(),
            ]).followedBy(
              openedFiles.map(
                (file) => PopupMenuItem(
                  value: () {
                    analytics.events.trackActionPressed(action: 'manageFile');
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).push(ManageFileScreen.route(file.fileSource));
                  },
                  child: ListTile(
                    leading: file.fileSource.displayIcon.iconData.widget(
                      color: file.openedFile.color,
                    ),
                    title: Text(file.fileSource.displayName),
                    subtitle: Text(
                      file.fileSource.displayPath,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            )),
      if (!isOnOpenFileScreen) ...[
        PopupMenuItem(
          value: () {
            analytics.events.trackActionPressed(action: 'openFile');
            Navigator.of(
              context,
              rootNavigator: true,
            ).push(SelectFileScreen.route(autoOpenLast: false));
          },
          child: ListTile(
            key: const ValueKey('openAnotherFile'),
            leading: const FaIcon(FontAwesomeIcons.folderPlus),
            title: Text(loc.menuItemOpenAnotherFile),
          ),
        ),
      ],
      if (openedFiles.isNotEmpty) ...[
        const PopupMenuDivider(),
        PopupMenuItem(
          value: () {
            analytics.events.trackActionPressed(action: 'lockFiles');
            context.read<KdbxBloc>().closeAllFiles(clearQuickUnlock: false);
            Navigator.of(
              context,
              rootNavigator: true,
            ).pushAndRemoveUntil(LockedScreen.route(), (_) => false);
          },
          child: ListTile(
            leading: const FaIcon(FontAwesomeIcons.lock),
            title: Text(loc.lockFiles),
          ),
        ),
      ],
      if (secondaryBuilder != null) ...secondaryBuilder(context),
    ];
  }

  static PopupMenuButton<VoidCallback> createOverflowMenuButton(
    BuildContext context, {
    List<PopupMenuItem<VoidCallback>> Function(BuildContext context)? builder,
    List<PopupMenuItem<VoidCallback>> Function(BuildContext context)?
    secondaryBuilder,
    bool isOnOpenFileScreen = false,
  }) {
    final openedFiles = Provider.of<OpenedKdbxFiles>(context);
    return PopupMenuButton<VoidCallback>(
      useRootNavigator: true,
      key: const ValueKey('appBarOverflowMenu'),
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).colorScheme.onSurface,
        size: OpenValutPlatform.isMacOS ? 13 : null,
      ),
      onSelected: (val) => val(),
      itemBuilder: (context) => [
        ...?(builder == null ? null : builder(context)),
        ...AppBarMenu.createDefaultPopupMenuItems(
          context,
          openedFiles,
          secondaryBuilder: secondaryBuilder,
          isOnOpenFileScreen: isOnOpenFileScreen,
        ),
      ],
    );
  }
}

/// Exports every decrypted entry as CSV to a user-chosen location.
Future<void> _exportCsv(BuildContext context) async {
  final loc = AppLocalizations.of(context);
  final kdbxBloc = context.read<KdbxBloc>();
  final csv = kdbxBloc.credentialServerExportCsv();
  final suggestedName =
      'openvalut-export-${DateTime.now().millisecondsSinceEpoch}.csv';
  try {
    if (OpenValutPlatform.isIOS || OpenValutPlatform.isAndroid) {
      await FilePickerWritable().openFileForCreate(
        fileName: suggestedName,
        writer: (file) async {
          await file.writeAsString(csv);
        },
      );
    } else {
      final location = await getSaveLocation(suggestedName: suggestedName);
      if (location == null) {
        return; // User canceled.
      }
      await io.File(location.path).writeAsString(csv);
    }
    if (!context.mounted) {
      return;
    }
    await DialogUtils.showSimpleAlertDialog(
      context,
      loc.menuExportedCsvTitle,
      loc.menuExportedAllCsv,
      routeAppend: 'exportCsv',
    );
  } on Exception catch (e) {
    if (!context.mounted) {
      return;
    }
    await DialogUtils.showSimpleAlertDialog(
      context,
      loc.menuExportFailedTitle,
      e.toString(),
      routeAppend: 'exportCsvError',
    );
  }
}
