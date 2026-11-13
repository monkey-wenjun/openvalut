// FIXME need to fix this lint
// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io' as io;

import 'package:biometric_storage/biometric_storage.dart';
import 'package:file_picker_writable/file_picker_writable.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_async_utils/flutter_async_utils.dart';
import 'package:kdbx/kdbx.dart';
import 'package:logging/logging.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import 'package:openvalut/bloc/analytics.dart';
import 'package:openvalut/bloc/app_data.dart';
import 'package:openvalut/bloc/deps.dart';
import 'package:openvalut/bloc/kdbx/file_content.dart';
import 'package:openvalut/bloc/kdbx/file_source.dart';
import 'package:openvalut/bloc/kdbx/file_source_local.dart';
import 'package:openvalut/bloc/kdbx/file_source_openvalut_cloud.dart';
import 'package:openvalut/bloc/kdbx/file_source_ui.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';
import 'package:openvalut/cloud_storage/cloud_storage_bloc.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/openvalut_cloud/openvalut_cloud_session.dart';
import 'package:openvalut/openvalut_cloud/openvalut_crypto.dart';
import 'package:openvalut/ui/screens/create_file.dart';
import 'package:openvalut/ui/screens/main_app_scaffold.dart';
import 'package:openvalut/ui/screens/openvalut_cloud_screen.dart';
import 'package:openvalut/ui/widgets/link_button.dart';
import 'package:openvalut/ui/widgets/openvalut_progress_indicator.dart';
import 'package:openvalut/ui/widgets/password_input_field.dart';
import 'package:openvalut/utils/constants.dart';
import 'package:openvalut/utils/dialog_utils.dart';
import 'package:openvalut/utils/platform.dart';
import 'package:openvalut/utils/session_store.dart';
import 'package:openvalut/utils/theme_utils.dart';
import 'package:openvalut/utils/unlock_prefs.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:simple_form_field_validator/simple_form_field_validator.dart';
import 'package:string_literal_finder_annotations/string_literal_finder_annotations.dart';
import 'package:tinycolor/color_extension.dart';

import '../../theme.dart';

final _logger = Logger('openvalut.select_file_screen');

class SelectFileScreen extends StatelessWidget {
  const SelectFileScreen({
    super.key,
    this.skipQuickUnlock = false,
    this.autoOpenLast = true,
  });

  static Route<Object> route({
    bool skipQuickUnlock = false,
    bool autoOpenLast = true,
  }) => MaterialPageRoute(
    settings: const RouteSettings(name: '/selectFile'),
    builder: (context) => SelectFileScreen(
      skipQuickUnlock: skipQuickUnlock,
      autoOpenLast: autoOpenLast,
    ),
  );

  static Future<void> navigate(
    BuildContext context, {
    bool skipQuickUnlock = false,
    bool autoOpenLast = true,
  }) =>
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushAndRemoveUntil(
        SelectFileScreen.route(
          skipQuickUnlock: skipQuickUnlock,
          autoOpenLast: autoOpenLast,
        ),
        (_) => false,
      );

  final bool skipQuickUnlock;
  final bool autoOpenLast;

  @override
  Widget build(BuildContext context) {
    final cloudBloc = context.watch<Deps>().cloudStorageBloc;
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.selectKeepassFile),
      ),
      body: Provider<CloudStorageBloc>.value(
        value: cloudBloc,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: SelectFileWidget(
            skipQuickUnlock: skipQuickUnlock,
            autoOpenLast: autoOpenLast,
          ),
        ),
      ),
    );
  }
}

class ProgressOverlay extends StatelessWidget {
  const ProgressOverlay({super.key, required this.child, this.task});

  final FutureTask? task;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = this.task;

    return Stack(
      children: <Widget>[
        child,
        Positioned.fill(
          child: AnimatedCrossFade(
            firstChild: task == null
                ? Container()
                : Container(
                    color: Colors.black12,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor.withAlpha(
                            250,
                          ), //Color(0xefffffff),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(8),
                          ),
                        ),
                        padding: const EdgeInsets.all(32),
                        child: ValueListenableBuilder<FutureTask>(
                          valueListenable: task,
                          builder: (context, value, child) {
                            _logger.fine(
                              'Generating progress dialog'
                              ' with label ${value.progressLabel}',
                            );
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const CircularProgressIndicator(),
                                ...?(value.progressLabel == null
                                    ? null
                                    : [
                                        const SizedBox(height: 16),
                                        Text(value.progressLabel!),
                                      ]),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
            secondChild: Container(),
            crossFadeState: task != null
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ),
      ],
    );
  }
}

class SelectFileWidget extends StatefulWidget {
  const SelectFileWidget({
    super.key,
    this.skipQuickUnlock = false,
    this.autoOpenLast = true,
  });

  final bool skipQuickUnlock;
  final bool autoOpenLast;

  @override
  _SelectFileWidgetState createState() => _SelectFileWidgetState();
}

class _SelectFileWidgetState extends State<SelectFileWidget>
    with FutureTaskStateMixin {
  bool _quickUnlockAttempted = false;
  bool _showLinuxAppArmorMessage = false;
  // When the "show start page every time" option is off, keep the selection
  // UI hidden while the last vault is being reopened automatically.
  bool _autoOpening = false;
  @NonNls
  static const _linuxAppArmorCommand =
      'snap connect openvalut:password-manager-service';
  int counter = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logger.finer('didChangeDependencies ${widget.skipQuickUnlock}');
    _autoOpening =
        !widget.skipQuickUnlock &&
        OpenValutPlatform.isDesktop &&
        !UnlockPrefs.showVaultStartPage.value;
    // On desktop the "show start page" option also switches auto-reopen off:
    // checked -> the page is shown and the user picks a vault (which then
    // unlocks via the system password when remembered). Unchecked -> reopen
    // the last vault immediately. Android keeps its automatic quick unlock.
    final runAutoReopen =
        !widget.skipQuickUnlock &&
        (!OpenValutPlatform.isDesktop || !UnlockPrefs.showVaultStartPage.value);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      unawaited(_initCloudSession(runAutoReopen: runAutoReopen));
    });
    _linuxAppArmorCheck();
  }

  /// Restores the remembered OpenValut Cloud account (email + Secret Key) so
  /// cloud vaults can be reopened automatically, then runs the quick-unlock /
  /// auto-reopen flow when requested.
  Future<void> _initCloudSession({required bool runAutoReopen}) async {
    await openvalutCloudSession.instance.autoLogin();
    if (!mounted) {
      return;
    }
    setState(() {});
    if (runAutoReopen) {
      await _checkQuickUnlock();
    }
    if (!mounted) {
      return;
    }
  }

  Future<bool> _linuxAppArmorCheck() async {
    if (!OpenValutPlatform.isLinux) {
      return true;
    }
    final isError = await BiometricStorage().linuxCheckAppArmorError();
    if (isError != _showLinuxAppArmorMessage) {
      setState(() {
        _showLinuxAppArmorMessage = isError;
      });
    }
    return !isError;
  }

  Future<void> _checkQuickUnlock() {
    final loc = AppLocalizations.of(context);
    Future<void> run(TaskProgress progress) async {
      try {
        if (_quickUnlockAttempted) {
          _logger.fine('_checkQuickUnlock already did quick unlock. skipping.');
          return;
        }
        _quickUnlockAttempted = true;
        progress.progressLabel = loc.quickUnlockingFiles;
        final kdbxBloc = Provider.of<KdbxBloc>(context, listen: false);
        if (kdbxBloc.openedFilesWithSources.isNotEmpty) {
          _logger.fine(
            'We already have files open. Not attempting quick unlock.',
          );
          return;
        }
        _logger.finer(
          'opening quick unlock. ${++counter} $_quickUnlockAttempted $mounted',
        );
        // Make sure the remembered cloud account is restored before rebuilding
        // cloud file sources.
        await openvalutCloudSession.instance.autoLogin();
        final opened = await kdbxBloc.reopenQuickUnlock(
          loc,
          progress: progress,
        );
        _logger.info(
          'opened $opened files with quick unlock. ${kdbxBloc.openedFilesKdbx.isNotEmpty}',
        );
        if (opened > 0 && kdbxBloc.openedFilesKdbx.isNotEmpty) {
          _logger.finer('Pushing main app scaffold. (mounted: $mounted)');
          unawaited(
            Navigator.of(context).pushReplacement(MainAppScaffold.route()),
          );
        } else if (widget.autoOpenLast && mounted) {
          // 1Password 式解锁：无法自动重开时，直接跳到最近密码库的
          // 主密码输入界面，而不是先展示选择页。
          await _autoOpenLastVault();
        }
      } catch (e, stackTrace) {
        // 自动重开异常（例如快速解锁数据在移除密码库后损坏）不能把
        // 页面卡在转圈状态。
        _logger.severe('Quick unlock / auto reopen failed.', e, stackTrace);
      } finally {
        if (_autoOpening && mounted) {
          // Clear the auto-opening spinner either way: when the unlock
          // screen was pushed, coming back from it must show the selection
          // page instead of an endless spinner.
          setState(() {
            _autoOpening = false;
          });
        }
      }
    }

    if (OpenValutPlatform.isDesktop || OpenValutPlatform.isAndroid) {
      // Desktop & Android: reopen silently in the background so the
      // automatic load is imperceptible (no blocking overlay with a
      // "preparing …" / "正在解锁文件 …" label).
      return run(const _SilentTaskProgress());
    }
    return asyncRunTask(run, label: loc.quickUnlockingFiles);
  }

  /// Opens the most recent vault straight to the master-password screen
  /// (used when no remembered/quick unlock is available). Prefers the last
  /// opened file (local or cloud), falling back to the first cloud vault.
  Future<bool> _autoOpenLastVault() async {
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
        }
        await Navigator.of(context).push(CredentialsScreen.route(source));
        return true;
      } catch (e, stackTrace) {
        _logger.warning(
          'Unable to auto-open last vault ${entry.uuid}.',
          e,
          stackTrace,
        );
      }
    }
    return _autoOpenLastCloudVault();
  }

  /// Fallback: opens the first OpenValut Cloud vault (account remembered but
  /// no recent-file entry could be rebuilt).
  Future<bool> _autoOpenLastCloudVault() async {
    final session = openvalutCloudSession.instance;
    final client = session.currentClient;
    if (client == null || !mounted) {
      return false;
    }
    try {
      final vaults = await client.listVaults();
      if (vaults.isEmpty || !mounted) {
        return false;
      }
      final vault = vaults.first;
      final source = FileSourceopenvalutCloud(
        client: client,
        vaultId: vault.id,
        vaultName: vault.name,
        uuid: vault.id,
      );
      await Navigator.of(context).push(CredentialsScreen.route(source));
      return true;
    } catch (e, stackTrace) {
      _logger.warning('Unable to auto-open last cloud vault.', e, stackTrace);
      return false;
    }
  }

  @override
  void didUpdateWidget(covariant SelectFileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _logger.finer('didUpdateWidget --- ${oldWidget != widget}');
    if (oldWidget != widget &&
        !widget.skipQuickUnlock &&
        (!OpenValutPlatform.isDesktop ||
            !UnlockPrefs.showVaultStartPage.value)) {
      _checkQuickUnlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_autoOpening) {
      return const Center(child: CircularProgressIndicator());
    }
    final appData = Provider.of<AppData>(context);
    final appDataBloc = Provider.of<AppDataBloc>(context);
    final cloudStorageBloc = Provider.of<CloudStorageBloc>(context);
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final recentFiles = appData.previousFiles.reversed
        .take(5)
        .map((f) {
          try {
            return MapEntry(f, f.toFileSource(cloudStorageBloc));
          } catch (e, stackTrace) {
            _logger.warning(
              'Unable to restore previous file $f',
              e,
              stackTrace,
            );
            return null;
          }
        })
        .whereType<MapEntry<OpenedFile, FileSource>>()
        .toList();
    return ProgressOverlay(
      task: task,
      child: Container(
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              ...?(_showLinuxAppArmorMessage
                  ? [
                      const SizedBox(height: 16),
                      Text(
                        loc.linuxAppArmorWarning,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      LinkButton(
                        icon: const Icon(Icons.content_copy),
                        onPressed: () async {
                          await Clipboard.setData(
                            const ClipboardData(text: _linuxAppArmorCommand),
                          );
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(loc.copiedToClipboard),
                              ),
                            );
                          await _linuxAppArmorCheck();
                        },
                        child: const Text(
                          _linuxAppArmorCommand,
                          style: TextStyle(
                            fontFamily: OpenValutTheme.monoFontFamily,
                          ),
                          maxLines: null,
                        ),
                      ),
                    ]
                  : null),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  loc.selectKeepassFileLabel,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SelectFileAction(
                    icon: .iconData(Icons.folder_open),
                    label: loc.selectFileOpenLocalFile,
                    onPressed: () async {
                      await _openLocalOrInternalFile(context);
                    },
                  ),
                  SelectFileAction(
                    icon: .iconData(Icons.cloud_outlined),
                    label: 'OpenValut Cloud',
                    onPressed: () {
                      Navigator.of(context).push(openvalutCloudScreen.route());
                    },
                  ),
                  SelectFileAction(
                    icon: .iconData(Icons.create_new_folder),
                    label: loc.createNewFile,
                    backgroundColor: theme.primaryColor.darken(),
                    onPressed: () {
                      Navigator.of(context).push(CreateFile.route());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              IntrinsicWidth(
                stepWidth: 100,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        loc.labelLastOpenFiles,
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      ...ListTile.divideTiles(
                        context: context,
                        tiles: recentFiles.isNotEmpty
                            ? recentFiles.map(
                                (entry) => OpenedFileTile(
                                  openedFile: entry.value,
                                  color: entry.key.color,
                                  onPressed: () => _loadAndGoToCredentials(
                                    entry.value,
                                  ),
                                  onLongPressed: () {
                                    showDialog<void>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return SimpleDialog(
                                          title: Text(
                                            entry.value.displayName.toString(),
                                          ),
                                          children: [
                                            SimpleDialogOption(
                                              child: ListTile(
                                                leading: const Icon(
                                                  Icons.remove_circle_outline,
                                                ),
                                                title: Text(
                                                  loc.removerecentfile,
                                                ),
                                              ),
                                              onPressed: () async {
                                                await appDataBloc.update((
                                                  builder,
                                                  data,
                                                ) {
                                                  builder.previousFiles.remove(
                                                    entry.key,
                                                  );
                                                });
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              )
                            : [
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(
                                    loc.noFilesHaveBeenOpenYet,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: UnlockPrefs.showVaultStartPage.value,
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                unawaited(
                                  UnlockPrefs.setShowVaultStartPage(value),
                                );
                                setState(() {});
                              },
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            Text(
                              loc.showVaultStartPage,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLocalOrInternalFile(BuildContext context) async {
    // Always go straight to the native file picker (local storage), matching
    // the desktop behaviour. The old "internal file" chooser is not offered
    // anymore.
    await _openLocalFile(context);
  }

  Future<void> _openLocalFile(BuildContext context) async {
    if (OpenValutPlatform.isIOS || OpenValutPlatform.isAndroid) {
      await _openIosAndAndroidLocalFilePicker();
    } else {
      final file = await openFile();
      if (file != null) {
        String? macOsBookmark;
        if (OpenValutPlatform.isMacOS) {
          macOsBookmark = await SecureBookmarks().bookmark(io.File(file.path));
        }
        await Navigator.of(context).push(
          CredentialsScreen.route(
            FileSourceLocal(
              FileSourceLocal.localFile(file.path),
              uuid: AppDataBloc.createUuid(),
              macOsSecureBookmark: macOsBookmark,
              filePickerIdentifier: null,
            ),
          ),
        );
      }
    }
  }

  Future<void> _openIosAndAndroidLocalFilePicker() async {
    await FilePickerWritable().openFile((fileInfo, file) async {
      await Navigator.of(context).push(
        CredentialsScreen.route(
          FileSourceLocal(
            FileSourceLocal.localFile(file.path),
            uuid: AppDataBloc.createUuid(),
            filePickerIdentifier: fileInfo.toJsonString(),
            initialCachedContent: FileContent(await file.readAsBytes()),
          ),
        ),
      );
    });
  }

  void _loadAndGoToCredentials(FileSource source) {
    final loc = AppLocalizations.of(context);
    final kdbxBloc = Provider.of<KdbxBloc>(context, listen: false);
    asyncRunTask((progress) async {
      try {
        if (source is FileSourceopenvalutCloud) {
          // Manual unlock: when the user has enrolled the fingerprint quick
          // unlock, prompt it here (biometric gate, no master password).
          // Otherwise fall back to the master-password screen.
          try {
            final unlockFiles = await kdbxBloc.quickUnlockStorage
                .loadQuickUnlockFile(kdbxBloc.appDataBloc);
            final data = unlockFiles[source];
            if (data != null) {
              final stream = kdbxBloc.openFile(
                source,
                writableRememberedCredentials(data),
              );
              final iterator = StreamIterator(stream);
              await iterator.moveNext();
              if (mounted) {
                await Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushReplacement(MainAppScaffold.route());
              }
              return;
            }
          } catch (e, stackTrace) {
            _logger.warning(
              'Quick-unlock open failed for ${source.displayName}; '
              'falling back to the credential screen.',
              e,
              stackTrace,
            );
          }
          // Same-boot remembered unlock: the master password was entered
          // once, so the system password (polkit/pkexec on Linux) replaces
          // the master-password form here as well. Cloud vaults store the
          // vault key + master password in the remembered payload, so the
          // row sync keeps working after this unlock.
          try {
            final opened = await kdbxBloc.openRememberedFile(source);
            if (opened) {
              if (mounted) {
                await Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushReplacement(MainAppScaffold.route());
              }
              return;
            }
          } catch (e, stackTrace) {
            _logger.warning(
              'Remembered unlock failed for ${source.displayName}; '
              'falling back to the credential screen.',
              e,
              stackTrace,
            );
          }
          if (mounted) {
            await Navigator.of(context).push(CredentialsScreen.route(source));
          }
          return;
        }
        // Same-boot remembered unlock first: the system password replaces the
        // master password form.
        final opened = await kdbxBloc.openRememberedFile(source);
        if (opened) {
          if (mounted) {
            await Navigator.of(
              context,
              rootNavigator: true,
            ).pushReplacement(MainAppScaffold.route());
          }
          return;
        }
        await source.content().last;
        if (mounted) {
          await Navigator.of(context).push(CredentialsScreen.route(source));
        }
      } catch (error) {
        _logger.fine('Error while trying to load file source $source');
        unawaited(
          DialogUtils.showErrorDialog(
            context,
            loc.errorLoadFileFromSourceTitle,
            loc.errorLoadFileFromSourceBody(source, error),
          ),
        );
      }
    });
    setState(() {});
  }
}

class OpenedFileTile extends StatelessWidget {
  const OpenedFileTile({
    super.key,
    required this.openedFile,
    this.onPressed,
    this.onLongPressed,
    required this.color,
  });

  final FileSource openedFile;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;
  final Color? color;

  String get _displayPath {
    try {
      return openedFile.displayPath;
    } catch (e) {
      return CharConstants.empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleStyle = TextStyle(
      color:
          ListTileTheme.of(context).textColor ??
          theme.textTheme.bodySmall!.color,
    );
    return InkWell(
      onTap: onPressed,
      onLongPress: onLongPressed,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          //        crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            openedFile.displayIcon.iconData.widget(
              color: ThemeUtil.iconColor(theme, color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    openedFile.displayName,
                    style: const TextStyle(color: OpenValutTheme.linkColor),
                  ),
                  Text(
                    _displayPath,
                    style: subtitleStyle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  //              Divider(),
                ],
              ),
            ),
            IconButton(
              onPressed: onLongPressed,
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectFileActionChrome extends StatelessWidget {
  const SelectFileActionChrome({
    super.key,
    this.backgroundColor,
    required this.child,
  });

  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final scale = width < 360 ? (width / 360).clamp(0.75, 1.0) : 1.0;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 120 * scale,
        maxWidth: 120 * scale,
        minHeight: 96 * scale,
      ),
      child: Material(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        color: backgroundColor ?? theme.primaryColor,
        elevation: 4,
        child: child,
      ),
    );
  }
}

class SelectFileAction extends StatelessWidget {
  const SelectFileAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
  });

  final IconDataWrapperBase icon;
  final String label;
  final Color? backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SelectFileActionChrome(
      backgroundColor: backgroundColor,
      child: InkWell(
        onTap: onPressed,
        child: SelectFileActionContent(icon: icon, label: label),
      ),
    );
  }
}

class SelectFileActionContent extends StatelessWidget {
  const SelectFileActionContent({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconDataWrapperBase icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final scale = width < 360 ? (width / 360).clamp(0.75, 1.0) : 1.0;
    return Padding(
      padding: EdgeInsets.all(8.0 * scale),
      child: DefaultTextStyle(
        style: theme.primaryTextTheme.bodyMedium!,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            icon.widget(
              color: theme.primaryTextTheme.bodyMedium!.color!.withValues(
                alpha: 0.8,
              ),
              size: (OpenValutPlatform.isDesktop ? 14.0 : 24.0) * scale,
            ),
            SizedBox(height: 8 * scale),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.primaryTextTheme.bodyMedium!.copyWith(
                letterSpacing: 0.9,
                fontSize:
                    (theme.primaryTextTheme.bodyMedium!.fontSize ?? 14) * scale,
              ),
              strutStyle: const StrutStyle(leading: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}

class CredentialsScreen extends StatefulWidget {
  const CredentialsScreen({super.key, required this.kdbxFilePath});

  static Route<void> route(FileSource kdbxFilePath) => MaterialPageRoute<void>(
    settings: const RouteSettings(name: '/credentials'),
    builder: (context) => CredentialsScreen(
      kdbxFilePath: kdbxFilePath,
    ),
  );

  final FileSource kdbxFilePath;

  @override
  _CredentialsScreenState createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends State<CredentialsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _invalidPassword;

  final _controller = TextEditingController();
  Future<bool>? _loadingFile;

  @override
  void initState() {
    super.initState();
    // 本次运行已用主密码解锁过（含扫码登录自动解锁）时，重开密码库
    // 自动带出主密码并直接解锁，不再要求输入；仅对云密码库生效。
    if (widget.kdbxFilePath is FileSourceopenvalutCloud) {
      final remembered = openvalutCloudSession.instance.vaultMasterPasswordFor(
        widget.kdbxFilePath.uuid,
      );
      if (remembered != null && remembered.isNotEmpty) {
        _controller.text = remembered;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(_tryUnlock());
          }
        });
      }
    }
    // 另一侧（openvalut-cli unlock，或同一台机器的其他终端 / SSH）已经解锁过：
    // 内核 user keyring 里有主密码，直接带入自动解锁，不再要求输入。
    if (_controller.text.isEmpty) {
      final shared = SessionStore.read();
      if (shared != null && shared.isNotEmpty) {
        _controller.text = shared;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(_tryUnlock());
          }
        });
      }
    }
    unawaited(
      (() async {
        if (widget.kdbxFilePath is FileSourceopenvalutCloud) {
          // Cloud blobs are encrypted; without the master password the
          // precache would fail. The password is set in [_tryUnlock].
          _logger.finer(
            'Skipping content precache for OpenValut Cloud vault.',
          );
          return;
        }
        _logger.finest('Precaching...');
        await widget.kdbxFilePath.contentPreCache();
      })(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(loc.credentialLabel),
                        Text(
                          widget.kdbxFilePath.displayName,
                          style: theme.textTheme.headlineMedium,
                        ),
                        Text(
                          widget.kdbxFilePath.displayPath,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(
                      top: 32,
                      right: 32,
                      left: 32,
                    ),
                    //              constraints: BoxConstraints.expand(),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: PasswordInputField(
                        controller: _controller,
                        labelText: loc.masterPasswordInputLabel,
                        // 解锁时允许用户确认自己输入的内容（排查输入法/全角字符问题）。
                        showVisibilityToggle: true,
                        autovalidateMode: _invalidPassword != null
                            ? AutovalidateMode.always
                            : AutovalidateMode.onUserInteraction,
                        validator: SValidator.invalidValue(
                          invalidValue: () => _invalidPassword,
                          message: loc.masterPasswordIncorrectValidator,
                        ).call,
                        // 用户重新输入时立即清掉上次失败的报错，
                        // 避免"还没输完就提示密码无效"。
                        onChanged: (_) {
                          if (_invalidPassword != null) {
                            setState(() {
                              _invalidPassword = null;
                            });
                          }
                        },
                        onEditingComplete: () async {
                          FocusScope.of(context).unfocus();

                          await _tryUnlock();
                        },
                      ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(top: 20),
                    child: _loadingFile != null
                        ? (OpenValutPlatform.isDesktop ||
                                  OpenValutPlatform.isAndroid
                              ? const SizedBox(height: 80)
                              : const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: OpenValutProgressIndicator(),
                                ))
                        : FilledButton(
                            key: const ValueKey('continue'),
                            onPressed: () async {
                              await _tryUnlock();
                            },
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(220, 48),
                            ),
                            child: Text(
                              loc.dialogContinue,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fileExtension() {
    final filePath = widget.kdbxFilePath.displayPath;
    return path.extension(filePath);
  }

  Future<void> _tryUnlock() async {
    if (_formKey.currentState!.validate()) {
      final deps = Provider.of<Deps>(context, listen: false);
      final loc = AppLocalizations.of(context);
      final analytics = deps.analytics;
      final kdbxBloc = deps.kdbxBloc;
      final pw = _controller.text;
      final stopWatch = Stopwatch();
      try {
        stopWatch.start();
        if (widget.kdbxFilePath is FileSourceopenvalutCloud) {
          final source = widget.kdbxFilePath as FileSourceopenvalutCloud;
          // Derive the vault key from what was typed in *this* attempt. A key
          // cached by an earlier failed attempt (typo, IME/full-width input)
          // would otherwise be reused for every later attempt and the correct
          // password would keep reporting "wrong password".
          source.invalidateVaultKeyCache();
          source.masterPassword = pw;
          source.credentials = Credentials.composite(
            pw == CharConstants.empty ? null : ProtectedValue.fromString(pw),
            null,
          );
        }
        final credentials = Credentials.composite(
          pw == CharConstants.empty ? null : ProtectedValue.fromString(pw),
          null,
        );
        final openFileStream = kdbxBloc.openFile(
          widget.kdbxFilePath,
          credentials,
          addToQuickUnlock: false,
        );
        // TODO handle subsequent errors.
        final openIt = StreamIterator(openFileStream);
        _loadingFile = openIt.moveNext();
        setState(() {});
        final result = await _loadingFile;
        _logger.info('waited for file $result');
        final fileResult = openIt.current;
        // 记住本次解锁密码库的主密码（仅内存，含本地库），供扫码授权
        // PC 直接解锁同一个密码库时自动带入。
        if (pw.isNotEmpty) {
          openvalutCloudSession.instance.rememberVaultMasterPassword(
            pw,
            vaultId: widget.kdbxFilePath.uuid,
          );
          // 同时发布到内核 user keyring（openvalut:master-password）：
          // 同一台机器的 openvalut-cli（任意终端 / SSH）随后无需再要主密码，
          // 直至重启。反向地，CLI `unlock` 后 App 也会自动解锁。
          SessionStore.save(pw);
        }
        analytics.trackTiming(
          'tryUnlockFile',
          fileResult.unlockStopwatch!.elapsedMilliseconds,
          category: 'unlock',
          label: 'successfully unlocked (${fileResult.fileContent!.source})',
        );
        analytics.events.trackTryUnlock(
          action: TryUnlockResult.success,
          ext: _fileExtension(),
          source: widget.kdbxFilePath.typeDebug,
        );
        final fileSource = fileResult.kdbxOpenedFile!.fileSource;
        unawaited(
          kdbxBloc.continueLoadInBackground(
            openIt,
            debugName: fileSource.displayName,
            fileSource: fileSource,
          ),
        );
        if (!kdbxBloc.isQuickUnlockFile(fileSource)) {
          final supported = await kdbxBloc.quickUnlockStorage
              .supportsBiometricKeyStore();
          if (supported && mounted) {
            var enableFingerprint = UnlockPrefs.fingerprintEnabled.value;
            if (!enableFingerprint) {
              final loc = AppLocalizations.of(context);
              final enable = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(loc.enableFingerprintQuestion),
                  content: Text(loc.enableFingerprintDescription),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(loc.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(loc.enableFingerprintAction),
                    ),
                  ],
                ),
              );
              enableFingerprint = enable == true;
            }
            if (enableFingerprint && mounted) {
              if (!UnlockPrefs.fingerprintEnabled.value) {
                await UnlockPrefs.setFingerprintEnabled(true);
              }
              try {
                await kdbxBloc.addToQuickUnlock(fileSource, credentials);
              } on AuthException catch (e) {
                if (e.code == AuthExceptionCode.userCanceled) {
                  _logger.fine(
                    'User canceled biometric prompt for quick unlock.',
                  );
                } else {
                  rethrow;
                }
              }
            }
          }
        }
        if (UnlockPrefs.rememberUnlockDays.value > 0) {
          await kdbxBloc.addToRememberedUnlock({fileSource: credentials});
        }
        final navigator = Navigator.of(context);
        unawaited(
          navigator.pushAndRemoveUntil(
            MainAppScaffold.route(),
            (route) => false,
          ),
        );
      } on KdbxInvalidKeyException catch (e, stackTrace) {
        _logger.severe(
          'KDBX unlock failed. '
          'isCloud=${widget.kdbxFilePath is FileSourceopenvalutCloud} '
          'vaultId=${widget.kdbxFilePath is FileSourceopenvalutCloud ? (widget.kdbxFilePath as FileSourceopenvalutCloud).vaultId : '?'} '
          'pwLength=${pw.length}',
          e,
          stackTrace,
        );
        analytics.trackTiming(
          'tryUnlockFile',
          stopWatch.elapsedMilliseconds,
          category: 'unlock',
          label: 'invalid credentials',
        );
        analytics.events.trackTryUnlock(
          action: TryUnlockResult.invalidCredential,
          ext: _fileExtension(),
          source: widget.kdbxFilePath.typeDebug,
        );
        if (!mounted) {
          _logger.warning(
            'Credential screen no longer mounted when handling error.',
          );
          return;
        }
        setState(() {
          _invalidPassword = pw;
          _formKey.currentState!.validate();
        });
      } on openvalutDecryptionException catch (e, stackTrace) {
        _logger.severe(
          'Cloud vault blob decryption failed. '
          'vaultId=${widget.kdbxFilePath is FileSourceopenvalutCloud ? (widget.kdbxFilePath as FileSourceopenvalutCloud).vaultId : '?'} '
          'masterPasswordSet=${(widget.kdbxFilePath as FileSourceopenvalutCloud).masterPassword?.isNotEmpty ?? false} '
          'pwLength=${pw.length}',
          e,
          stackTrace,
        );
        analytics.trackTiming(
          'tryUnlockFile',
          stopWatch.elapsedMilliseconds,
          category: 'unlock',
          label: 'invalid credentials (cloud)',
        );
        if (!mounted) {
          return;
        }
        final loc = AppLocalizations.of(context);
        final diagnostic = widget.kdbxFilePath is FileSourceopenvalutCloud
            ? '(diagnostic: vaultId=${(widget.kdbxFilePath as FileSourceopenvalutCloud).vaultId})'
            : null;
        await DialogUtils.showErrorDialog(
          context,
          loc.cloudUnlockFailedTitle,
          diagnostic == null
              ? loc.cloudUnlockFailedDescription
              : '${loc.cloudUnlockFailedDescription}\n\n$diagnostic',
          routeAppend: 'cloudDecryptFailed',
        );
        setState(() {
          _invalidPassword = pw;
          _formKey.currentState!.validate();
        });
      } on FileAlreadyOpenException catch (e, stackTrace) {
        _logger.fine('File already open.', e, stackTrace);
        await _handleOpenError(
          analytics: analytics,
          result: TryUnlockResult.alreadyOpen,
          errorTitle: loc.errorOpenFileAlreadyOpenTitle,
          errorBody: loc.errorOpenFileAlreadyOpenBody(
            e.newFile.body.meta.databaseName.get()!,
            e.openFileSource.displayPath,
            e.newFileSource.displayPath,
          ),
          stopWatch: stopWatch,
        );
      } on KdbxInvalidFileStructure catch (e, stackTrace) {
        _logger.fine(
          'Invalid file structore for file ${widget.kdbxFilePath}',
          e,
          stackTrace,
        );
        await _handleOpenError(
          analytics: analytics,
          result: TryUnlockResult.invalidFileStructure,
          errorTitle: loc.errorOpenFileInvalidFileStructureTitle,
          errorBody: loc.errorOpenFileInvalidFileStructureBody(
            widget.kdbxFilePath.displayName,
          ),
          stopWatch: stopWatch,
        );
      } catch (e, stackTrace) {
        _logger.fine('Unable to open kdbx file. ', e, stackTrace);
        await _handleOpenError(
          analytics: analytics,
          result: TryUnlockResult.failure,
          errorTitle: loc.errorUnlockFileTitle,
          errorBody: loc.errorUnlockFileBody(e),
          stopWatch: stopWatch,
        );
      } finally {
        if (mounted) {
          setState(() {
            _loadingFile = null;
          });
        } else {
          _logger.warning(
            'User navigated away from $runtimeType, '
            'not updating UI.',
          );
        }
      }
    }
  }

  Future<void> _handleOpenError({
    required Analytics analytics,
    required TryUnlockResult result,
    required String errorTitle,
    required String errorBody,
    required Stopwatch stopWatch,
  }) async {
    analytics.trackTiming(
      'tryUnlockFile',
      stopWatch.elapsedMilliseconds,
      category: 'unlock',
      label: 'error: $result',
    );
    analytics.events.trackTryUnlock(
      action: TryUnlockResult.alreadyOpen,
      ext: _fileExtension(),
      source: widget.kdbxFilePath.typeDebug,
    );
    await DialogUtils.showErrorDialog(
      context,
      errorTitle,
      errorBody,
      routeAppend: 'errorOpenFile',
    );
  }
}

/// Task progress sink that discards progress updates, used to run the
/// automatic reopen on desktop without showing the blocking progress overlay.
class _SilentTaskProgress implements TaskProgress {
  const _SilentTaskProgress();

  @override
  set progressLabel(String progressLabel) {
    // Progress updates are intentionally swallowed: the load is automatic
    // and should stay invisible on the PC.
  }
}
