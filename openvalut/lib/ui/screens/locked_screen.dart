import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/bloc/app_data.dart';
import 'package:openvalut/bloc/kdbx/file_source_openvalut_cloud.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';
import 'package:openvalut/cloud_storage/cloud_storage_bloc.dart';
import 'package:openvalut/env/_base.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/openvalut_cloud/openvalut_cloud_session.dart';
import 'package:openvalut/ui/screens/select_file_screen.dart';
import 'package:openvalut/ui/widgets/primary_button.dart';
import 'package:openvalut/utils/platform.dart';
import 'package:provider/provider.dart';

final _logger = Logger('locked_screen');

class LockedScreen extends StatelessWidget {
  static MaterialPageRoute<void> route() => MaterialPageRoute<void>(
    settings: const RouteSettings(name: '/lock'),
    builder: (context) => LockedScreen(),
  );

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(Env.OpenValut),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.lock,
                  size: OpenValutPlatform.isDesktop ? 48 : 128,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  onPressed: () {
                    _openLastVaultOrSelect(context);
                  },
                  child: Text(loc.unlock),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () {
                SelectFileScreen.navigate(
                  context,
                  skipQuickUnlock: true,
                  autoOpenLast: false,
                );
              },
              child: Text(loc.lockedChooseAnotherVault),
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context, rootNavigator: true);
                await context.read<KdbxBloc>().closeAllFiles(
                  clearQuickUnlock: true,
                );
                await navigator.pushAndRemoveUntil(
                  SelectFileScreen.route(
                    skipQuickUnlock: true,
                    autoOpenLast: false,
                  ),
                  (_) => false,
                );
              },
              child: Text(loc.closePasswordFiles.toUpperCase()),
            ),
          ),
        ],
      ),
    );
  }

  /// 1Password 式解锁：优先跳到最近打开密码库的主密码输入界面；
  /// 没有可用的最近密码库时退回密码库选择页。
  static Future<void> _openLastVaultOrSelect(BuildContext context) async {
    final appData = Provider.of<AppData>(context, listen: false);
    final cloudStorageBloc = Provider.of<CloudStorageBloc>(
      context,
      listen: false,
    );
    for (final entry in appData.previousFiles.reversed) {
      try {
        final source = entry.toFileSource(cloudStorageBloc);
        if (source is FileSourceopenvalutCloud) {
          final session = openvalutCloudSession.instance;
          if (!session.isLoggedIn && !await session.autoLogin()) {
            continue;
          }
          if (!context.mounted) {
            return;
          }
        }
        await Navigator.of(context, rootNavigator: true).pushReplacement(
          CredentialsScreen.route(source),
        );
        return;
      } catch (e, stackTrace) {
        _logger.warning(
          'Unable to restore last vault ${entry.uuid}.',
          e,
          stackTrace,
        );
      }
    }
    if (context.mounted) {
      unawaited(SelectFileScreen.navigate(context, skipQuickUnlock: true));
    }
  }
}
