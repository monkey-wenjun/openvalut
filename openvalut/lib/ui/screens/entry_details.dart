// FIXME need to fix this lint
// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io' as io;

import 'package:clock/clock.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:file_picker_writable/file_picker_writable.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_async_utils/flutter_async_utils.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kdbx/kdbx.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:openvalut/bloc/analytics.dart';
import 'package:openvalut/bloc/app_data.dart';
import 'package:openvalut/bloc/kdbx/file_source_openvalut_cloud.dart';
import 'package:openvalut/bloc/kdbx/storage_exception.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';
import 'package:openvalut/env/_base.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/openvalut_cloud/openvalut_client.dart';
import 'package:openvalut/openvalut_cloud/openvalut_cloud_session.dart';
import 'package:openvalut/openvalut_cloud/openvalut_share_service.dart';
import 'package:openvalut/theme.dart';
import 'package:openvalut/ui/common_fields.dart';
import 'package:openvalut/ui/screens/app_bar_menu.dart';
import 'package:openvalut/ui/screens/entry_totp.dart';
import 'package:openvalut/ui/screens/group_list.dart';
import 'package:openvalut/ui/screens/hud.dart';
import 'package:openvalut/ui/screens/password_categories.dart';
import 'package:openvalut/ui/screens/password_generator.dart';
import 'package:openvalut/ui/screens/password_list.dart';
import 'package:openvalut/ui/widgets/icon_selector.dart';
import 'package:openvalut/ui/widgets/installed_app_picker.dart';
import 'package:openvalut/ui/widgets/keyboard_handler.dart';
import 'package:openvalut/ui/widgets/primary_button.dart';
import 'package:openvalut/ui/widgets/shortcut/openvalut_intents.dart';
import 'package:openvalut/utils/base32utils.dart';
import 'package:openvalut/utils/brand_icons.dart';
import 'package:openvalut/utils/clipboard_auto_clear.dart';
import 'package:openvalut/utils/constants.dart';
import 'package:openvalut/utils/dialog_utils.dart';
import 'package:openvalut/utils/extension_methods.dart';
import 'package:openvalut/utils/format_utils.dart';
import 'package:openvalut/utils/otpauth.dart';
import 'package:openvalut/utils/password_generator.dart';
import 'package:openvalut/utils/path_utils.dart';
import 'package:openvalut/utils/platform.dart';
import 'package:openvalut/utils/read_access.dart';
import 'package:openvalut/utils/secret_reference.dart';
import 'package:openvalut/utils/secure_window.dart';
import 'package:openvalut/utils/theme_utils.dart';
import 'package:otp/otp.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:string_literal_finder_annotations/string_literal_finder_annotations.dart';
import 'package:tuple/tuple.dart';

final _logger = Logger('entry_details');

enum _SpecialField {
  totp,
  website,
  sshPrivateKey,
  sshPublicKey,
  sshPort,
  accessKey,
  file,
  notes,
}

/// KDBX key prefix for extra “target website / associated app” fields.
/// The bare `KP2A_URL` field keeps its existing “关联 App” role; numbered
/// fields (`KP2A_URL2`, `KP2A_URL3`, …) act as additional target websites and
/// are already matched by the native host when a website asks for credentials.
const String _extraWebsiteKeyPrefix = 'KP2A_URL'; // NON-NLS

bool _isExtraWebsiteKey(KdbxKey key) =>
    key.key.toUpperCase().startsWith(_extraWebsiteKeyPrefix);

/// Numeric part of an extra website key: `KP2A_URL2` -> 2. Bare `KP2A_URL`
/// (the “关联 App” row) returns null.
int? _extraWebsiteNumber(KdbxKey key) {
  final upper = key.key.toUpperCase();
  if (upper == _extraWebsiteKeyPrefix) {
    return null;
  }
  if (!upper.startsWith(_extraWebsiteKeyPrefix)) {
    return null;
  }
  return int.tryParse(upper.substring(_extraWebsiteKeyPrefix.length));
}

/// The next free numbered website key (starts at `KP2A_URL2`).
KdbxKey _nextWebsiteKey(KdbxEntry entry) {
  var maxNumber = 1;
  for (final pair in entry.stringEntries) {
    final number = _extraWebsiteNumber(pair.key);
    if (number != null && number > maxNumber) {
      maxNumber = number;
    }
  }
  return KdbxKey('$_extraWebsiteKeyPrefix${maxNumber + 1}');
}

class EntryDetailsScreen extends StatefulWidget {
  const EntryDetailsScreen({super.key, required this.entry});

  static Route<void> route({required KdbxEntry entry}) => MaterialPageRoute(
    settings: const RouteSettings(name: '/entry'),
    builder: (context) => EntryDetailsScreen(
      entry: entry,
    ),
  );

  final KdbxEntry entry;

  @override
  _EntryDetailsScreenState createState() => _EntryDetailsScreenState();
}

class _EntryDetailsScreenState extends State<EntryDetailsScreen>
    with
        TaskStateMixin<EntryDetailsScreen>,
        StreamSubscriberMixin<EntryDetailsScreen>,
        KdbxObjectSavableStateMixin<EntryDetailsScreen> {
  @override
  KdbxFile get file => widget.entry.file;

  @override
  Changeable<KdbxNode> get kdbxObject => widget.entry;
  @override
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final entryDetailsKey = GlobalKey<_EntryDetailsState>();
  EntryViewModel? entryViewModel;

  /// Whether the entry was already dirty (i.e. freshly created and not yet
  /// saved) when the details screen opened. Such entries are removed again
  /// when the user discards the unsaved changes.
  late bool _entryDirtyOnOpen;

  /// Captured while the context is valid so the pop callback (which runs
  /// around navigation) can talk to the bloc without a stale context.
  late KdbxBloc _kdbxBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _entryDirtyOnOpen = widget.entry.isDirty;
    _kdbxBloc = context.read<KdbxBloc>();
    final kdbxBloc = context.watch<KdbxBloc>();
    if (entryViewModel == null) {
      entryViewModel = EntryViewModel(widget.entry, kdbxBloc);
      handleSubscription(
        widget.entry.file.dirtyObjectsChanged.listen((event) {
          setState(() {
            entryViewModel = EntryViewModel(widget.entry, kdbxBloc);
          });
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final env = Provider.of<Env>(context);
    final vm = entryViewModel!;
    // final vm = EntryViewModel(widget.entry, context.watch<KdbxBloc>());
    final entry = widget.entry;
    final loc = AppLocalizations.of(context);
    final analytics = context.watch<Analytics>();
    return Scaffold(
      appBar: AppBar(
        title: Text(vm.label?.takeUnlessBlank() ?? loc.noTitle),
        actions: <Widget>[
          ...?!isDirty
              ? null
              : [
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: saveCallback,
                  ),
                ],
          IconButton(
            key: const ValueKey('shareEntry'),
            tooltip: loc.shareWithFamilyTitle,
            icon: const Icon(Icons.share),
            onPressed: () {
              unawaited(_shareEntry(context));
            },
          ),
          AppBarMenu.createOverflowMenuButton(
            context,
            builder: (context) => [
              if (entry.isInRecycleBin()) ...[
                PopupMenuItem(
                  value: () async {
                    final e = entry;
                    final result = await DialogUtils.showConfirmDialog(
                      context: context,
                      params: ConfirmDialogParams(
                        content: loc.permanentlyDeleteEntryConfirm(
                          e.label ?? CharConstants.empty,
                        ),
                      ),
                    );
                    if (!result) {
                      analytics.events.trackPermanentlyDeleteEntryCancel();
                      return;
                    }
                    subscriptions.cancelSubscriptions();
                    final scaffoldManager = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    entry.file.deletePermanently(entry);
                    context.read<KdbxBloc>().refreshOpenedFiles();
                    analytics.events.trackPermanentlyDeleteEntry();
                    scaffoldManager.hideCurrentSnackBar();
                    final controller = scaffoldManager.showSnackBar(
                      SnackBar(
                        content: Text(loc.permanentlyDeletedEntrySnackBar),
                        behavior: SnackBarBehavior.fixed,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    var snackBarClosed = false;
                    controller.closed.then(
                      (_) => snackBarClosed = true,
                      onError: (_) => snackBarClosed = true,
                    );
                    Timer(const Duration(seconds: 1), () {
                      if (!snackBarClosed) {
                        controller.close();
                      }
                    });
                  },
                  child: ListTile(
                    leading: const Icon(Icons.delete_forever),
                    title: Text(loc.deletePermanentlyAction),
                  ),
                ),
                PopupMenuItem(
                  value: () async {
                    final previousParent = entry.previousParentGroup.get()?.let(
                      (that) => entry.file.findGroupByUuid(that),
                    );
                    final entryDetails = entryDetailsKey.currentState;
                    if (entryDetails == null) {
                      return;
                    }
                    await entryDetails._showMoveToGroup(
                      loc,
                      vm.entry,
                      toGroup:
                          previousParent == null ||
                              previousParent.isInRecycleBin() ||
                              previousParent == entry.file.recycleBin
                          ? null
                          : previousParent,
                    );
                  },
                  child: ListTile(
                    leading: const Icon(Icons.restore_from_trash),
                    title: Text(loc.restoreFromRecycleBinAction),
                  ),
                ),
              ] else ...[
                PopupMenuItem(
                  value: () {
                    final oldGroup = entry.parent;
                    final scaffoldManager = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    entry.file.deleteEntry(entry);
                    context.read<KdbxBloc>().refreshOpenedFiles();
                    scaffoldManager.hideCurrentSnackBar();
                    final controller = scaffoldManager.showSnackBar(
                      SnackBar(
                        content: Text(loc.deletedEntry),
                        behavior: SnackBarBehavior.fixed,
                        duration: const Duration(seconds: 1),
                        action: SnackBarAction(
                          label: loc.undoButtonLabel,
                          onPressed: () {
                            entry.file.move(entry, oldGroup!);
                          },
                        ),
                      ),
                    );
                    // The ScaffoldMessenger auto-dismiss timer is not started
                    // when a snackbar is shown right after popping a route from
                    // a popup menu on some Flutter versions, which would leave
                    // the snackbar on screen forever. Hide it explicitly after
                    // the same delay. If the snackbar already closed on its
                    // own, this is a no-op.
                    var snackBarClosed = false;
                    controller.closed.then(
                      (_) => snackBarClosed = true,
                      onError: (_) => snackBarClosed = true,
                    );
                    Timer(const Duration(seconds: 1), () {
                      if (!snackBarClosed) {
                        scaffoldManager.hideCurrentSnackBar(
                          reason: SnackBarClosedReason.timeout,
                        );
                      }
                    });
                  },
                  child: ListTile(
                    leading: const Icon(Icons.delete),
                    title: Text(loc.deleteAction),
                  ),
                ),
              ],
              ...?!env.isDebug
                  ? null
                  : [
                      PopupMenuItem(
                        value: () {
                          Clipboard.setData(
                            ClipboardData(
                              text: entry.toXml().toXmlString(pretty: true),
                            ),
                          );
                        },
                        child: ListTile(
                          leading: const Icon(Icons.bug_report),
                          title: Text(nonNls('Debug: Copy XML')),
                        ),
                      ),
                    ],
            ],
          ),
        ],
      ),
      //      floatingActionButton: FloatingActionButton(
      //        child: Icon(Icons.add),
      //        onPressed: () {},
      //      ),
      body: PopScope(
        canPop: !isFormDirty,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) {
            // Route popped without the confirm dialog (clean form). If this
            // was a freshly created entry that was never saved, remove it so
            // a blank/untitled entry does not linger in the file (and keep the
            // pending-tracking consistent so auto-save resumes).
            if (_entryDirtyOnOpen && widget.entry.isDirty) {
              widget.entry.file.deleteEntry(widget.entry);
              _kdbxBloc.discardNewEntry(widget.entry);
            }
            return;
          }
          final navigator = Navigator.of(context);
          if (await DialogUtils.showConfirmDialog(
            context: context,
            params: ConfirmDialogParams(
              title: loc.unsavedChangesWarningTitle,
              content: loc.unsavedChangesWarningBody,
              positiveButtonText: loc.unsavedChangesDiscardActionLabel,
            ),
          )) {
            if (_entryDirtyOnOpen && widget.entry.isDirty) {
              // A freshly created entry that was never saved must not stay
              // in the list after the user discards it.
              widget.entry.file.deleteEntry(widget.entry);
              _kdbxBloc.discardNewEntry(widget.entry);
            }
            navigator.pop();
          }
        },
        child: Form(
          key: formKey,
          onChanged: () {
            if (!isFormDirty) {
              setState(() => isFormDirty = true);
            }
          },
          child: EntryDetails(
            key: entryDetailsKey,
            entry: vm,
            onSavedPressed: !isDirty && !entry.isDirty ? null : saveCallback,
          ),
        ),
      ),
    );
  }

  Future<void> _shareEntry(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final kdbxBloc = context.read<KdbxBloc>();
    final opened = kdbxBloc.fileForKdbxFile(widget.entry.file);
    if (opened.fileSource is! FileSourceopenvalutCloud) {
      await DialogUtils.showSimpleAlertDialog(
        context,
        loc.entryAttachmentShareActionLabel,
        loc.shareRequiresCloudVault,
        routeAppend: 'shareNotCloud',
      );
      return;
    }
    if (openvalutCloudSession.instance.currentClient == null) {
      await DialogUtils.showSimpleAlertDialog(
        context,
        loc.entryAttachmentShareActionLabel,
        loc.shareTargetLoginRequired,
        routeAppend: 'shareNotLoggedIn',
      );
      return;
    }

    final recipient = await showDialog<String>(
      context: context,
      builder: (context) => const _ShareRecipientDialog(),
    );
    if (recipient == null || !mounted) {
      return;
    }
    try {
      await openvalutShareService.instance.shareEntry(
        entry: widget.entry,
        recipientUsername: recipient,
        kdbxBloc: kdbxBloc,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(loc.sharedToRecipient(recipient))),
        );
    } on openvalutApiException catch (e) {
      _logger.fine('Share failed', e);
      final message = e.statusCode == 404
          ? loc.shareUserNotFound(recipient)
          : loc.shareFailedDetail(e.message);
      if (mounted) {
        await DialogUtils.showErrorDialog(context, loc.shareFailed, message);
      }
    } catch (e, stackTrace) {
      _logger.severe('Share failed', e, stackTrace);
      if (mounted) {
        await DialogUtils.showErrorDialog(context, loc.shareFailed, '$e');
      }
    }
  }
}

class _ShareRecipientDialog extends StatefulWidget {
  const _ShareRecipientDialog();

  @override
  _ShareRecipientDialogState createState() => _ShareRecipientDialogState();
}

class _ShareRecipientDialogState extends State<_ShareRecipientDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(loc.shareWithFamilyTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: loc.shareRecipientEmailLabel,
          hintText: loc.shareRecipientEmailHint,
        ),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            Navigator.of(context).pop(value.trim());
          }
        },
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        FilledButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isNotEmpty) {
              Navigator.of(context).pop(value);
            }
          },
          child: Text(loc.entryAttachmentShareActionLabel),
        ),
      ],
    );
  }
}

mixin KdbxObjectSavableStateMixin<T extends StatefulWidget>
    on State<T>, TaskStateMixin<T>, StreamSubscriberMixin<T> {
  GlobalKey<FormState> get formKey;

  KdbxFile get file;

  bool _isObjectDirty = false;

  bool get isDirty => _isObjectDirty || isFormDirty;
  bool isFormDirty = false;

  Changeable<KdbxNode> get kdbxObject;

  @override
  void initState() {
    super.initState();
    _registerListener();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _registerListener();
  }

  void _registerListener() {
    subscriptions.cancelSubscriptions();
    handleSubscription(
      kdbxObject.changes.listen((change) {
        _logger.finer(
          '_isObjectDirty = ${change.isDirty} (before: $_isObjectDirty / formDirty: $isFormDirty',
        );
        setState(() {
          _isObjectDirty = change.isDirty;
        });
      }),
    );
  }

  @protected
  VoidCallback? get saveCallback => asyncTaskCallback(() async {
    final loc = AppLocalizations.of(context);
    final form = formKey.currentState;
    if (form == null) {
      return;
    }
    if (form.validate()) {
      form.save();
      setState(() => isFormDirty = false);
      classifyEntryIntoCategoryGroup(kdbxObject as KdbxEntry);
      final kdbxBloc = Provider.of<KdbxBloc>(context, listen: false);
      if (kdbxBloc.fileForKdbxFile(file).fileSource.supportsWrite) {
        try {
          await kdbxBloc.saveFile(file);
        } on StorageException catch (e, stackTrace) {
          _logger.warning('Error while saving database.', e, stackTrace);
          await DialogUtils.showErrorDialog(
            context,
            loc.errorWhileSavingTitle,
            loc.errorWhileSavingBody(e),
          );
          return;
        } catch (e, stackTrace) {
          _logger.severe('Error while saving database.', e, stackTrace);
          if (mounted) {
            await DialogUtils.showErrorDialog(
              context,
              loc.errorWhileSavingTitle,
              loc.errorWhileSavingBody(e),
            );
          }
          rethrow;
        }
      } else {
        await DialogUtils.showSimpleAlertDialog(
          context,
          null,
          loc.databaseDoesNotSupportSaving,
          routeAppend: 'databaseNoSupportSaving',
        );
      }
    }
  });
}

enum FieldType {
  string,
  otp,
}

class EntryDetails extends StatefulWidget {
  const EntryDetails({
    super.key,
    required this.entry,
    required this.onSavedPressed,
  });

  final EntryViewModel entry;
  final VoidCallback? onSavedPressed;

  @override
  _EntryDetailsState createState() => _EntryDetailsState();
}

class _EntryDetailsState extends State<EntryDetails>
    with StreamSubscriberMixin {
  List<Tuple3<GlobalKey<_EntryFieldState>, KdbxKey, CommonField?>>? _fieldKeys;

  IntentActionRegistration? _shortcutRegistration;

  @override
  void dispose() {
    _shortcutRegistration?.dispose();
    super.dispose();
  }

  void _initShortcutListener(
    KeyboardShortcutEvents events,
    CommonFields commonFields,
  ) {
    _shortcutRegistration?.dispose();
    _shortcutRegistration = events.registerActions({
      CopyPasswordIntent: CallbackAction(
        onInvoke: (_) {
          final context = FocusManager.instance.primaryFocus?.context;
          if (context != null) {
            _logger.fine('context: $context');
            if (context.widget is EditableText) {
              final ctrl = (context.widget as EditableText).controller;
              if (!ctrl.selection.isCollapsed && ctrl.selection.isNormalized) {
                final data = ctrl.selection.textInside(ctrl.text);
                if (data.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: data));
                  if (mounted) {
                    final loc = AppLocalizations.of(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.copiedToClipboard)),
                    );
                  }
                  return;
                }
              }
            }

            final entryFieldState = context
                .findAncestorStateOfType<_EntryFieldState>();
            if (entryFieldState != null) {
              entryFieldState.copyValue();
              return;
            }
            if (widget is EditableText) {
              return;
            }
          }

          _copyField([commonFields.password]);
          return null;
        },
      ),
      CopyUsernameIntent: CallbackAction(
        onInvoke: (_) {
          _copyField([commonFields.userName]);
          return null;
        },
      ),
      CopyTotpIntent: CallbackAction(
        onInvoke: (_) {
          _logger.fine('Copying ${commonFields.otpAuth}');
          _copyField([
            commonFields.otpAuth,
            commonFields.otpAuthCompat2,
            commonFields.otpAuthCompat1,
          ]);
          return null;
        },
      ),
      OpenUrlIntent: CallbackAction(
        onInvoke: (_) {
          _fieldStateFor(commonFields.url)?.openUrl();
          return null;
        },
      ),
      CopyUrlIntent: CallbackAction(
        onInvoke: (_) {
          _fieldStateFor(commonFields.url)?.copyValue();
          return null;
        },
      ),
      // DismissIntent: CallbackAction(onInvoke: (_) {
      //   FocusManager.instance.primaryFocus?.unfocus();
      // }),
      // CancelSearchFilterIntent: CallbackAction(onInvoke: (_) {
      // final primaryFocus = FocusManager.instance.primaryFocus;
      // if (primaryFocus)
      //     ?.unfocus();
      //   }),
    });
  }

  _EntryFieldState? _fieldStateFor(CommonField commonField) => _fieldKeys!
      .firstWhereOrNull((f) => f.item2 == commonField.key)
      ?.item1
      .currentState;

  Future<bool> _copyField(List<CommonField> commonFields) async {
    for (final commonField in commonFields) {
      if (await _copyFieldValue(commonField)) {
        return true;
      }
    }
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.copiedFieldEmpty(commonFields.first.displayName)),
      ),
    );
    return false;
  }

  Future<bool> _copyFieldValue(CommonField commonField) async {
    final field = _fieldStateFor(commonField);
    if (field != null) {
      if (await field.copyValue()) {
        return true;
      }
    }
    final loc = AppLocalizations.of(context);
    final entry = widget.entry.entry;
    final value = entry.getString(commonField.key);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (value == null || value.getText() == null) {
      return false;
    }
    await Clipboard.setData(
      ClipboardData(text: value.getText() ?? CharConstants.empty),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.copiedFieldToClipboard(commonField.displayName)),
      ),
    );
    return true;
  }

  void _initFields(CommonFields commonFields) {
    final entry = widget.entry.entry;
    final nonCommonKeys = entry.stringEntries.where(
      (str) =>
          !commonFields.isCommon(str.key) && !isInternalReadAccessKey(str.key),
    );
    // 把老条目里存在 URL 主字段的 androidapp:// 关联迁移到独立字段，
    // 这样“目标网站”和“关联 App”各占一个文本框。
    final urlField = entry.getString(commonFields.url.key);
    final urlText = urlField?.getText() ?? '';
    final existingAppLink =
        entry.getString(KdbxKey('KP2A_URL'))?.getText() ?? '';
    if (urlText.toLowerCase().startsWith('androidapp://') &&
        existingAppLink.isEmpty) {
      entry.setString(KdbxKey('KP2A_URL'), PlainValue(urlText));
      entry.setString(commonFields.url.key, PlainValue(''));
    }
    final oldKeys = _fieldKeys == null
        ? <KdbxKey, GlobalKey<_EntryFieldState>>{}
        : Map.fromEntries(_fieldKeys!.map((e) => MapEntry(e.item2, e.item1)));
    final fields = commonFields.fields
        .where((f) => f.showByDefault || entry.getString(f.key) != null)
        .map(
          (f) => Tuple3<GlobalKey<_EntryFieldState>, KdbxKey, CommonField?>(
            oldKeys[f.key] ??
                GlobalKey<_EntryFieldState>(debugLabel: f.key.toString()),
            f.key,
            f,
          ),
        )
        .followedBy(
          nonCommonKeys.map(
            (f) => Tuple3(
              oldKeys[f.key] ??
                  GlobalKey<_EntryFieldState>(debugLabel: f.key.toString()),
              f.key,
              null,
            ),
          ),
        )
        .toList();
    // URL 字段之后固定插入“关联 App”独立文本框（KP2A_URL），未设置时
    // 也显示，方便用户直接选择要关联的应用。
    final appLinkKey = KdbxKey('KP2A_URL'); // NON-NLS
    final hasAppLink = fields.any((f) => f.item2 == appLinkKey);
    if (!hasAppLink) {
      final urlIndex = fields.indexWhere(
        (f) => f.item2 == commonFields.url.key,
      );
      fields.insert(
        urlIndex < 0 ? fields.length : urlIndex + 1,
        Tuple3(
          oldKeys[appLinkKey] ??
              GlobalKey<_EntryFieldState>(debugLabel: 'KP2A_URL'),
          appLinkKey,
          null,
        ),
      );
    }
    _fieldKeys = fields;
    // Reorder fields to: Title, URL, UserName, Password, TOTP, Notes, Others.
    int sortOrder(KdbxKey key) {
      if (key == commonFields.title.key) return 0;
      if (key == commonFields.url.key) return 1;
      if (_isExtraWebsiteKey(key)) return 2;
      if (key == commonFields.userName.key) return 3;
      if (key == commonFields.password.key) return 4;
      if (commonFields.isTotp(key)) return 5;
      if (key == commonFields.notes.key) return 6;
      return 7;
    }

    int extraOrder(KdbxKey key) {
      if (!_isExtraWebsiteKey(key)) {
        return 0;
      }
      // Bare KP2A_URL (关联 App) comes first, then numbered website fields.
      return _extraWebsiteNumber(key) ?? 1;
    }

    _fieldKeys!.sort((a, b) {
      final byPriority = sortOrder(a.item2).compareTo(sortOrder(b.item2));
      return byPriority != 0
          ? byPriority
          : extraOrder(a.item2).compareTo(extraOrder(b.item2));
    });
    _logger.fine('Listing on changes for ${widget.entry.label}');
    handleSubscription(
      entry.changes.listen((event) {
        _logger.fine('Widget entry changed.');
        setState(() {});
      }),
    );
  }

  Future<void> _addSpecialField(
    BuildContext context,
    _SpecialField field,
  ) async {
    final loc = AppLocalizations.of(context);
    final commonFields = Provider.of<CommonFields>(context, listen: false);
    final entry = widget.entry.entry;
    switch (field) {
      case _SpecialField.totp:
        final secret = await SimplePromptDialog(
          title: loc.totpSecretPromptTitle,
          labelText: loc.totpSecretPromptLabel,
        ).show(context);
        if (secret == null || secret.trim().isEmpty) {
          return;
        }
        final value = secret.trim();
        entry.setString(
          KdbxKeyCommon.OTP,
          PlainValue(
            value.startsWith('otpauth://')
                ? value
                : 'otpauth://totp/${entry.label ?? 'otp'}?secret=$value',
          ),
        );
      case _SpecialField.website:
        entry.setString(_nextWebsiteKey(entry), PlainValue(''));
      case _SpecialField.sshPrivateKey:
        entry.setString(KdbxKey('ssh-private-key'), PlainValue(''));
      case _SpecialField.sshPublicKey:
        entry.setString(KdbxKey('ssh-public-key'), PlainValue(''));
      case _SpecialField.sshPort:
        entry.setString(KdbxKey('ssh-port'), PlainValue(''));
      case _SpecialField.accessKey:
        // AK/SK 成对添加：Access Key ID（明文）+ Secret Access Key（保护值）。
        entry.setString(KdbxKey('access-key'), PlainValue(''));
        entry.setString(
          KdbxKey('secret-key'),
          ProtectedValue.fromString(''),
        );
      case _SpecialField.file:
        final file = await openFile();
        if (file == null) {
          return;
        }
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) {
          return;
        }
        entry.createBinary(
          isProtected: false,
          name: file.name,
          bytes: bytes,
        );
      case _SpecialField.notes:
        entry.setString(commonFields.notes.key, PlainValue(''));
    }
    if (mounted) {
      setState(() {
        _initFields(commonFields);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logger.info('_EntryDetailsState.didChangeDependencies');
    if (_fieldKeys == null) {
      subscriptions.cancelSubscriptions();
      _initFields(Provider.of<CommonFields>(context));
      _initShortcutListener(
        Provider.of<KeyboardShortcutEvents>(context),
        Provider.of<CommonFields>(context),
      );
    }
  }

  @override
  void didUpdateWidget(EntryDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    _logger.fine('_EntryDetailsState.didUpdateWidget');
    if (oldWidget.entry != widget.entry) {
      _logger.info('_EntryDetailsState: widget.entry changed.');
      _initFields(Provider.of<CommonFields>(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final commonFields = Provider.of<CommonFields>(context);
    final vm = widget.entry;
    final entry = widget.entry.entry;
    final formatUtils = Provider.of<FormatUtils>(context);
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    final appData = Provider.of<AppData>(context);
    final passwordReminderBanner = _buildPasswordReminderBanner(appData, entry);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: SafeArea(
          top: false,
          left: false,
          child: Column(
            children: <Widget>[
              if (passwordReminderBanner != null) ...[
                passwordReminderBanner,
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(width: 16),
                  EntryIcon(
                    vm: vm,
                    size: OpenValutPlatform.isDesktop ? 32 : 64,
                    fallback: (context) => IconSelectorFormField(
                      initialValue: SelectedIcon.fromObject(entry),
                      iconColor: brandIconForEntry(entry)?.color,
                      onSaved: (icon) {
                        // TODO is it possible for icon to be null here?!
                        icon?.when(
                          predefined: (predefined) {
                            entry.customIcon = null;
                            entry.icon.set(predefined);
                          },
                          custom: (custom) {
                            entry.customIcon = custom;
                          },
                        );
                      },
                      kdbxFile: entry.file,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 16),
                        EntryMetaInfo(
                          label: loc.entryInfoFile,
                          value: entry.file.body.meta.databaseName.get(),
                        ),
                        EntryMetaInfo(
                          label: loc.entryInfoGroup,
                          value: vm.groupNames.join(' » '), // NON-NLS
                          onTap: () async {
                            await _showMoveToGroup(loc, vm.entry);
                          },
                        ),
                        EntryMetaInfo(
                          label: loc.entryInfoLastModified,
                          value: formatUtils.formatDateFull(
                            vm.entry.times.lastModificationTime.get() ??
                                DateTime.now(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                secondary: const Icon(Icons.terminal),
                title: Text(loc.entryAllowCliRead),
                subtitle: Text(loc.entryAllowCliReadDescription),
                value: isReadAllowed(entry),
                onChanged: (allowed) {
                  setState(() {
                    setReadAllowed(entry, allowed);
                  });
                },
              ),
              const SizedBox(height: 8),
              ..._fieldKeys!
                  .map(
                    (f) => EntryField(
                      fieldType: commonFields.isTotp(f.item2)
                          ? FieldType.otp
                          : FieldType.string,
                      key: f.item1,
                      entry: entry,
                      fieldKey: f.item2,
                      commonField: f.item3,
                      onChangedMetadata: () => setState(() {
                        _initFields(
                          Provider.of<CommonFields>(context, listen: false),
                        );
                      }),
                    ),
                  )
                  .expand(
                    (el) => [
                      el,
                      SizedBox(
                        height:
                            OpenValutPlatform.isLinux ||
                                OpenValutPlatform.isWindows ||
                                OpenValutPlatform.isMacOS
                            ? 24
                            : 16,
                      ),
                    ],
                  ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: PopupMenuButton<_SpecialField>(
                    tooltip: loc.addSpecialField,
                    onSelected: (field) => _addSpecialField(context, field),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _SpecialField.totp,
                        child: Text(loc.addTotpField),
                      ),
                      PopupMenuItem(
                        value: _SpecialField.website,
                        child: Text(loc.entryAddWebsite),
                      ),
                      PopupMenuItem(
                        value: _SpecialField.sshPrivateKey,
                        child: Text(loc.fieldSshPrivateKey),
                      ),
                      PopupMenuItem(
                        value: _SpecialField.sshPublicKey,
                        child: Text(loc.fieldSshPublicKey),
                      ),
                      PopupMenuItem(
                        value: _SpecialField.sshPort,
                        child: Text(loc.fieldSshPort),
                      ),
                      PopupMenuItem(
                        value: _SpecialField.accessKey,
                        child: Text(loc.entryAddAkskCredential),
                      ),
                      PopupMenuItem(
                        value: _SpecialField.file,
                        child: Text(loc.entryAddAttachment),
                      ),
                      PopupMenuItem(
                        value: _SpecialField.notes,
                        child: Text(commonFields.notes.displayName),
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: OpenValutPlatform.isDesktop ? 14 : 20,
                          ),
                          const SizedBox(width: 8),
                          Text(loc.addSpecialField),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ...entry.binaryEntries.map((e) {
                return InkWell(
                  onTap: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      builder: (context) => AttachmentBottomSheet(
                        entry: entry,
                        attachment: e,
                      ),
                    );
                  },
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 500),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.attach_file),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                e.key.key,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                loc.sizeBytes(e.value.value.length),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              PrimaryButton(
                icon: const Icon(Icons.save),
                onPressed: widget.onSavedPressed,
                child: Text(loc.saveButtonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildPasswordReminderBanner(AppData appData, KdbxEntry entry) {
    final loc = AppLocalizations.of(context);
    final days = appData.passwordReminderDays ?? 0;
    if (days <= 0) {
      return null;
    }
    final changed = entry.times.lastModificationTime.get();
    if (changed == null) {
      return null;
    }
    final next = changed.add(Duration(days: days));
    final remaining = next.difference(clock.now()).inDays;
    if (remaining > 7) {
      return null;
    }

    final theme = Theme.of(context);
    final isExpired = remaining < 0;
    final text = isExpired
        ? loc.entryPasswordExpired(-remaining)
        : loc.entryPasswordExpires(remaining);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isExpired
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isExpired ? Icons.warning : Icons.lock_clock,
            color: isExpired
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isExpired
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<KdbxGroup?> _showMoveToGroup(
    AppLocalizations loc,
    KdbxEntry entry, {
    final KdbxGroup? toGroup,
  }) async {
    final file = entry.file;
    final newGroup =
        toGroup ??
        (await Navigator.of(context).push(
          GroupListFlat.route(
            {entry.parent!},
            groupListMode: GroupListMode.singleSelect,
            rootGroup: entry.file.body.rootGroup,
          ),
        ))?.firstOrNull;
    if (newGroup != null) {
      final oldGroup = entry.parent;
      file.move(entry, newGroup);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.movedEntryToGroup(newGroup.name.get()!)),
          action: SnackBarAction(
            label: loc.undoButtonLabel,
            onPressed: () {
              file.move(entry, oldGroup!);
            },
          ),
        ),
      );
    }
    return newGroup;
  }
}

class AttachmentBottomSheet extends StatelessWidget {
  const AttachmentBottomSheet({
    super.key,
    required this.entry,
    required this.attachment,
  });

  final KdbxEntry entry;
  final MapEntry<KdbxKey, KdbxBinary> attachment;

  @override
  Widget build(BuildContext context) {
    final analytics = Provider.of<Analytics>(context);
    final loc = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          leading: const Icon(Icons.open_in_new),
          title: Text(loc.entryAttachmentOpenActionLabel),
          onTap: () async {
            analytics.events.trackAttachmentAction('open');
            Navigator.of(context).pop();
            final kdbxBloc = context.read<KdbxBloc>();
            final provider = await kdbxBloc.attachmentProviderForFileSource(
              entry.file,
            );
            final bytes = await provider.readAttachmentBytes(
              entry.file,
              attachment.value,
            );
            final f = await PathUtils().saveToTempDirectory(
              bytes,
              dirPrefix: 'openbinary',
              fileName: attachment.key.key,
            );
            _logger.fine('Opening ${f.path}');
            final result = await OpenFile.open(f.path);
            _logger.fine('finished opening ${result.type}: ${result.message}');
          },
        ),
        ListTile(
          leading: const Icon(Icons.share),
          title: Text(loc.entryAttachmentShareActionLabel),
          onTap: () async {
            analytics.events.trackAttachmentAction('share');
            final kdbxBloc = context.read<KdbxBloc>();
            final provider = await kdbxBloc.attachmentProviderForFileSource(
              entry.file,
            );
            final bytes = await provider.readAttachmentBytes(
              entry.file,
              attachment.value,
            );
            final mimeType = lookupMimeType(
              attachment.key.key,
              headerBytes: bytes.length > defaultMagicNumbersMaxLength
                  ? Uint8List.sublistView(
                      bytes,
                      0,
                      defaultMagicNumbersMaxLength,
                    )
                  : null,
            )!;
            _logger.fine('Opening attachment with mimeType $mimeType');

            final tempDir = await PathUtils().getTemporaryDirectory();
            final f = await tempDir.childFile(attachment.key.key).create();
            await f.writeAsBytes(bytes);

            try {
              await SharePlus.instance.share(
                ShareParams(
                  files: [
                    XFile(f.path, mimeType: mimeType),
                  ],
                  subject: loc.entryAttachmentShareSubject,
                ),
              );
            } finally {
              unawaited(f.delete());
            }

            // Share.file('Attachment', attachment.key.key,
            //     attachment.value.value, mimeType);
            Navigator.of(context).pop();
          },
        ),
        if (!OpenValutPlatform.isWeb)
          ListTile(
            leading: const Icon(Icons.save),
            title: Text(loc.entryAttachmentSaveActionLabel),
            onTap: () async {
              analytics.events.trackAttachmentAction('saveToDevice');
              Navigator.of(context).pop();
              final kdbxBloc = context.read<KdbxBloc>();
              final provider = await kdbxBloc.attachmentProviderForFileSource(
                entry.file,
              );
              final bytes = await provider.readAttachmentBytes(
                entry.file,
                attachment.value,
              );
              if (OpenValutPlatform.isIOS || OpenValutPlatform.isAndroid) {
                await FilePickerWritable().openFileForCreate(
                  fileName: attachment.key.key,
                  writer: (file) async {
                    _logger.fine('Opening ${file.path}');
                    await file.writeAsBytes(bytes);
                  },
                );
              } else {
                final saveLocation = await getSaveLocation(
                  suggestedName: attachment.key.key,
                  confirmButtonText: loc.saveButtonLabel,
                );
                if (saveLocation != null) {
                  final outputFile = io.File(saveLocation.path);
                  await outputFile.writeAsBytes(bytes);
                }
              }
            },
          ),
        ListTile(
          leading: const Icon(Icons.delete),
          title: Text(loc.entryAttachmentRemoveActionLabel),
          onTap: () async {
            analytics.events.trackAttachmentAction('remove');
            Navigator.of(context).pop();
            final confirm = await DialogUtils.showConfirmDialog(
              context: context,
              params: ConfirmDialogParams(
                content: loc.entryAttachmentRemoveConfirm(attachment.key.key),
              ),
            );
            if (confirm) {
              entry.removeBinary(attachment.key);
            }
          },
        ),
      ],
    );
  }
}

class EntryMetaInfo extends StatelessWidget {
  const EntryMetaInfo({
    super.key,
    this.label,
    this.value,
    this.onTap,
  });

  final String? label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          //          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            ...?onTap == null
                ? null
                : [
                    Icon(
                      Icons.edit,
                      size: OpenValutPlatform.isDesktop ? 14 : 16,
                      color: Colors.black45,
                    ),
                    const SizedBox(width: 8),
                  ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label!, style: theme.textTheme.bodySmall),
                  Text(
                    value!,
                    style: theme.textTheme.bodyLarge!.copyWith(
                      color: theme.textTheme.bodySmall!.color,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EntryField extends StatefulWidget {
  const EntryField({
    super.key,
    required this.fieldType,
    required this.entry,
    required this.fieldKey,
    this.commonField,
    required this.onChangedMetadata,
  });

  final FieldType fieldType;
  final KdbxEntry entry;
  final KdbxKey fieldKey;
  final CommonField? commonField;
  final VoidCallback onChangedMetadata;

  @override
  _EntryFieldState createState() =>
      // ignore: no_logic_in_create_state
      fieldType == FieldType.otp ? _OtpEntryFieldState() : _EntryFieldState();
}

enum EntryAction {
  copy,
  copyReference,
  copyRawData,
  rename,
  protect,
  delete,
  show,
  passwordGenerator,
}

abstract class FieldDelegate {
  Future<void> generatePassword();

  Future<void> openUrl();

  /// Lets the user pick an installed Android app and stores it as an
  /// androidapp:// url so Android autofill can match this entry to that app.
  Future<void> pickApp();
}

class _EntryFieldState extends State<EntryField>
    with StreamSubscriberMixin, TaskStateMixin
    implements FieldDelegate {
  final GlobalKey _formFieldKey = GlobalKey();
  late TextEditingController _controller;
  bool _isValueObscured = false;
  final FocusNode _focusNode = FocusNode();
  late CommonFields _commonFields;

  IntentActionRegistration? _keyboardRegistration;

  StringValue? get _fieldValue => widget.entry.getString(widget.fieldKey);

  set _fieldValue(StringValue? value) {
    widget.entry.setString(widget.fieldKey, value);
  }

  bool get _isProtected => _fieldValue == null
      ? widget.commonField?.protect == true
      : _fieldValue is ProtectedValue;

  String? get _valueCurrent =>
      (_isValueObscured
          ? widget.entry.getString(widget.fieldKey)?.getText()
          : _controller.text) ??
      _fieldValue?.getText();

  final GlobalKey<HighlightWidgetState> _highlightWidgetKey =
      GlobalKey<HighlightWidgetState>();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_focusNodeChanged);
    _initController();
  }

  void _initController() {
    if (_fieldValue is ProtectedValue || widget.commonField?.protect == true) {
      _isValueObscured = true;
      _controller = TextEditingController();
    } else {
      _controller = TextEditingController(
        text: _fieldValue?.getText() ?? CharConstants.empty,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _commonFields = Provider.of<CommonFields>(context);
    if (widget.fieldKey == _commonFields.password.key) {
      _keyboardRegistration?.dispose();
      final keyboardShortcutEvents = context.watch<KeyboardShortcutEvents>();
      _keyboardRegistration = keyboardShortcutEvents.registerActions({
        GeneratePassword: CallbackAction(onInvoke: (_) => _generatePassword()),
      });
    }
  }

  void _focusNodeChanged() {
    if (!_isProtected) {
      return;
    }
    if (OpenValutPlatform.isMacOS) {
      unawaited(SecureWindow.setSecureEventInput(_focusNode.hasFocus));
    }
    _logger.info(
      'Focus changed to ${_focusNode.hasFocus} (primary: ${_focusNode.hasPrimaryFocus})',
    );
    if (!_focusNode.hasFocus) {
      setState(() {
        _fieldValue = ProtectedValue.fromString(_controller.text);
        _isValueObscured = true;
        _logger.finer('${widget.fieldKey} _isProtected= $_isValueObscured');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('building ${widget.fieldKey} ($_isValueObscured)');
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(widget.fieldKey),
      background: Container(
        alignment: Alignment.centerLeft,
        color: theme.brightness == Brightness.light
            ? Colors.lightBlueAccent
            : Colors.blueAccent,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.lock),
            const SizedBox(height: 4),
            Text(loc.swipeCopyField),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        //        await ClipboardManager.copyToClipBoard(_value.getText());
        await copyValue();
        return false;
      },
      child: HighlightWidget(
        key: _highlightWidgetKey,
        childOnHighlight: Text(
          loc.doneCopiedField,
          style: theme.textTheme.bodyMedium!
              .copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 1,
                  ),
                ],
                letterSpacing: 1,
              )
              .apply(fontSizeFactor: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _buildEntryFieldEditor(),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: loc.swipeCopyField,
                    icon: Icon(
                      Icons.content_copy,
                      color: theme.colorScheme.onSurface,
                      size: OpenValutPlatform.isMacOS ? 16 : null,
                    ),
                    onPressed: () async {
                      await copyValue();
                    },
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    firstChild: PopupMenuButton<EntryAction>(
                      useRootNavigator: true,
                      icon: Icon(
                        Icons.more_vert,
                        color: theme.colorScheme.onSurface,
                        size: OpenValutPlatform.isMacOS ? 13 : null,
                      ),
                      offset: const Offset(0, 32),
                      onSelected: _handleMenuEntrySelected,
                      itemBuilder: _buildMenuEntries,
                    ),
                    secondChild: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                    crossFadeState: task == null
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                  ),
                ],
              ),
              //            IconButton(
              //              icon: Icon(Icons.content_copy),
              //              tooltip: 'Copy to clipboard',
              //              onPressed: () {
              //                ClipboardManager.copyToClipBoard(_value.getText());
              //              },
              //            ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleMenuEntrySelected(EntryAction entryAction) async {
    switch (entryAction) {
      case EntryAction.copy:
        await copyValue();
        break;
      case EntryAction.copyReference:
        await _copyReference();
        break;
      case EntryAction.copyRawData:
        // only used by [_OtpEntryFieldState]
        throw UnsupportedError('Field does not support this action.');
      case EntryAction.rename:
        final loc = AppLocalizations.of(context);
        final key = await SimplePromptDialog(
          title: loc.entryRenameFieldPromptTitle,
          labelText: loc.entryRenameFieldPromptLabel,
          initialValue: widget.fieldKey.key,
        ).show(context);
        if (key != null) {
          widget.entry.renameKey(widget.fieldKey, KdbxKey(key));
          widget.onChangedMetadata();
        }
        break;
      case EntryAction.passwordGenerator:
        await _launchPasswordGenerator();
        break;
      case EntryAction.protect:
        setState(() {
          if (_isProtected) {
            _fieldValue = PlainValue(_valueCurrent ?? CharConstants.empty);
            _isValueObscured = false;
          } else {
            _logger.fine(
              'protected: $_isProtected, obscured: $_isValueObscured, current: $_valueCurrent',
            );
            _fieldValue = ProtectedValue.fromString(
              _valueCurrent ?? CharConstants.empty,
            );
            _isValueObscured = true;
          }
          _initController();
        });
        break;
      case EntryAction.delete:
        widget.entry.removeString(widget.fieldKey);
        widget.onChangedMetadata();
        break;
      case EntryAction.show:
        FullScreenHud.show(context, (context) {
          return FullScreenHud(
            value: _valueCurrent ?? CharConstants.empty,
          );
        });
        break;
    }
  }

  Future<void> _copyReference() async {
    final loc = AppLocalizations.of(context);
    final kdbxBloc = context.read<KdbxBloc>();
    final opened = kdbxBloc.fileForKdbxFile(widget.entry.file);
    final vaultId = opened.fileSource.displayName;
    final field = _referenceFieldName();
    final reference = SecretReference.generate(
      vaultId: vaultId,
      entryId: widget.entry.uuid.uuid,
      field: field,
    );
    await Clipboard.setData(ClipboardData(text: reference));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.entryPasteReference(reference))),
      );
    }
  }

  String _referenceFieldName() {
    final commonField = widget.commonField;
    if (commonField != null) {
      if (commonField.key == KdbxKeyCommon.PASSWORD) {
        return 'password';
      }
      if (commonField.key == KdbxKeyCommon.USER_NAME) {
        return 'username';
      }
      if (commonField.key == KdbxKeyCommon.URL) {
        return 'url';
      }
      if (commonField.key == KdbxKeyCommon.TITLE) {
        return 'title';
      }
      if (commonField.key == KdbxKeyCommon.OTP ||
          commonField.key == KdbxKey('Notes')) {
        return commonField.key == KdbxKeyCommon.OTP ? 'totp' : 'notes';
      }
    }
    if (widget.fieldType == FieldType.otp) {
      return 'totp';
    }
    return widget.fieldKey.key;
  }

  List<PopupMenuEntry<EntryAction>> _buildMenuEntries(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return <PopupMenuEntry<EntryAction>>[
      PopupMenuItem(
        value: EntryAction.copy,
        child: ListTile(
          leading: const Icon(Icons.content_copy),
          title: Text(loc.swipeCopyField),
        ),
      ),
      PopupMenuItem(
        value: EntryAction.copyReference,
        child: ListTile(
          leading: const FaIcon(FontAwesomeIcons.link),
          title: Text(loc.entryCopyReferenceTitle),
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: EntryAction.rename,
        child: ListTile(
          leading: const Icon(Icons.edit),
          title: Text(loc.fieldRename),
        ),
      ),
      PopupMenuItem(
        value: EntryAction.passwordGenerator,
        child: ListTile(
          leading: const FaIcon(FontAwesomeIcons.shuffle),
          title: Text(loc.generatePassword),
          //            subtitle: null,
        ),
      ),
      PopupMenuItem(
        value: EntryAction.protect,
        child: ListTile(
          leading: Icon(
            _isProtected ? Icons.no_encryption : Icons.enhanced_encryption,
          ),
          title: Text(_isProtected ? loc.fieldUnprotect : loc.fieldProtect),
        ),
      ),
      PopupMenuItem(
        value: EntryAction.delete,
        child: ListTile(
          leading: const Icon(Icons.delete),
          title: Text(loc.deleteAction),
        ),
      ),
      PopupMenuItem(
        value: EntryAction.show,
        child: ListTile(
          //                    leading: Icon(Icons.present_to_all),
          leading: const FaIcon(FontAwesomeIcons.qrcode),
          title: Text(loc.fieldPresent),
        ),
      ),
    ];
  }

  @override
  Future<void> openUrl() async {
    context.events.trackEntryAction(EntryActionType.openUrl);
    final url = _valueCurrent!;
    final loc = AppLocalizations.of(context);
    String? openError;
    try {
      var parsed = Uri.parse(url);
      if (!parsed.hasScheme) {
        parsed = Uri.parse('http://$url'); // NON-NLS
      }
      _logger.finer('Opening url $url ($parsed)');
      if (await DialogUtils.openUrl(parsed.toString())) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.launchedUrl(url))));
      } else {
        openError = loc.unableToLaunchUrlNoHandler;
      }
    } catch (e, stackTrace) {
      openError = e.toString();
      _logger.severe('Unable to open url, $url', e, stackTrace);
    }
    if (openError != null) {
      await DialogUtils.showErrorDialog(
        context,
        loc.unableToLaunchUrlTitle,
        loc.unableToLaunchUrlDescription(url, openError),
      );
    }
  }

  @override
  Future<void> generatePassword() => _generatePassword();

  @override
  Future<void> pickApp() async {
    if (!OpenValutPlatform.isAndroid) {
      return;
    }
    final app = await showInstalledAppPicker(context);
    if (app == null || !mounted) {
      return;
    }
    final appUrl = 'androidapp://${app.packageName}'; // NON-NLS
    _controller.text = appUrl;
    setState(() {});
  }

  Future<void> _generatePassword() async {
    context.events.trackEntryAction(EntryActionType.generatePassword);
    final appData = await Provider.of<AppDataBloc>(
      context,
      listen: false,
    ).store.load();
    final characterSets = CharacterSet.characterSetFromIds(
      appData.passwordGeneratorCharacterSets,
    );
    if (characterSets.isEmpty) {
      characterSets.addAll([CharacterSet.alphaNumeric, CharacterSet.numeric]);
    }
    final length = appData.passwordGeneratorLength ?? 16;
    _generatedPassword(
      PasswordGenerator.singleton().generatePassword(
        CharacterSetCollection(characterSets.toList()),
        length,
      ),
    );
  }

  Future<void> _launchPasswordGenerator() async {
    final password = await Navigator.of(
      context,
    ).push(PasswordGeneratorScreen.route(finishButton: FinishButtonStyle.done));
    if (password != null) {
      setState(() {
        _generatedPassword(password);
      });
    }
  }

  void _generatedPassword(String password) {
    setState(() {
      _isValueObscured = false;
      _controller.text = password;
      _fieldValue = ProtectedValue.fromString(_controller.text);
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
      _focusNode.requestFocus();
    });
    copyValue();
  }

  Future<bool> copyValue() async {
    _highlightWidgetKey.currentState!.triggerHighlight();
    Provider.of<Analytics>(
      context,
      listen: false,
    ).events.trackCopyField(key: widget.fieldKey.key);
    final text = _valueCurrent ?? CharConstants.empty;
    if (widget.commonField?.key == KdbxKeyCommon.PASSWORD ||
        widget.commonField?.key == KdbxKeyCommon.USER_NAME) {
      await ClipboardAutoClear.copyWithAutoClear(text);
    } else {
      await Clipboard.setData(ClipboardData(text: text));
    }
    return true;
  }

  Widget _buildEntryFieldEditor() =>
      _isValueObscured && _valueCurrent?.isEmpty == false
      ? _buildObscuredEntryFieldEditor()
      : _buildStringEntryFieldEditor();

  Widget _buildObscuredEntryFieldEditor() {
    return ObscuredEntryFieldEditor(
      onPressed: () {
        setState(() {
          _controller.text = _valueCurrent ?? CharConstants.empty;
          _controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controller.text.length,
          );
          _isValueObscured = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _focusNode.requestFocus();
            _logger.finer('requesting focus.');
          });
        });
      },
      onShowPressed: () {
        _handleMenuEntrySelected(EntryAction.show);
      },
      fieldKey: widget.fieldKey,
      commonField: widget.commonField,
    );
  }

  Widget _buildStringEntryFieldEditor() {
    return StringEntryFieldEditor(
      onSaved: (value) {
        if (value == null) {
          _fieldValue = null;
        } else {
          final newValue = _isProtected
              ? ProtectedValue.fromString(value)
              : PlainValue(value);
          _fieldValue = newValue;
        }
      },
      fieldKey: widget.fieldKey,
      commonField: widget.commonField,
      controller: _controller,
      formFieldKey: _formFieldKey,
      focusNode: _focusNode,
      delegate: this,
    );
  }

  @override
  void dispose() {
    _logger.fine(
      'EntryFieldState.dispose() - ${widget.key} (${widget.fieldKey})',
    );
    _keyboardRegistration?.dispose();
    if (_isProtected && _focusNode.hasFocus && OpenValutPlatform.isMacOS) {
      unawaited(SecureWindow.setSecureEventInput(false));
    }
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class _OtpEntryFieldState extends _EntryFieldState {
  Timer? _timer;

  String _currentOtp = CharConstants.empty;

  String? _errorMessage;

  /// elapsed seconds since the last period change.
  int _elapsed = 0;

  /// period in seconds how often the otp changes.
  int _period = 30;

  @override
  String get _valueCurrent =>
      widget.entry.getString(widget.fieldKey)?.getText() ?? CharConstants.empty;

  OtpAuth _getOtpAuth() {
    final value = widget.entry.getString(widget.fieldKey)?.getText();
    if (value == null || value.isEmpty) {
      return throw FormatException('OTP Field contains no data.', value);
    }
    if (value.startsWith(OtpAuth.URI_PREFIX)) {
      // Our own format :-) (And also used by KeeWeb)
      return OtpAuth.fromUri(Uri.parse(value));
    }
    final otpAuth = OtpAuth.fromQueryString(value);
    if (otpAuth != null) {
      return otpAuth;
    }
    // assume base32 encoded secret, with more settings stored in a second field.
    try {
      final binarySecret = base32Decode(value);
      final settings =
          _commonFields.otpAuthCompat1Settings.stringValue(widget.entry) ??
          CharConstants.empty;
      final settingsOptions = settings.isEmpty
          ? <String>[]
          : settings.split(CharConstants.semiColon);
      _logger.finest('settings: $settings');
      return OtpAuth(
        secret: binarySecret,
        period: settingsOptions.optGet(0)?.toInt() ?? OtpAuth.DEFAULT_PERIOD,
        digits: settingsOptions.optGet(1)?.toInt() ?? OtpAuth.DEFAULT_DIGITS,
      );
    } on FormatException catch (e, stackTrace) {
      // ignore format exception from base32 decoding.
      _logger.fine('Error decoding base32 secret', e, stackTrace);
    } catch (e, stackTrace) {
      _logger.fine('Error while parsing OTP format', e, stackTrace);
      throw FormatException('Error parsing Tray OTP Format $e', value);
    }
    throw FormatException('Unknown format for OTP', value);
  }

  void _updateOtp() {
    try {
      final otpAuth = _getOtpAuth();
      final secretBase32 = base32Encode(otpAuth.secret);
      _logger.fine('uri: $otpAuth');
      final now = clock.now().millisecondsSinceEpoch;
      final totpCode = OTP.generateTOTPCodeString(
        secretBase32,
        now,
        algorithm: otpAuth.algorithm,
        length: otpAuth.digits,
        interval: otpAuth.period,
        // do not pad OTP secret if it is not of correct length.
        isGoogle: true,
      );
      setState(() {
        _elapsed = (now ~/ 1000) % otpAuth.period;
        _period = otpAuth.period;
        _currentOtp = totpCode;
        _errorMessage = null;
      });
    } on FormatException catch (e, stackTrace) {
      _logger.severe(
        'Error while decoding otpauth url for ${widget.fieldKey}.',
        e,
        stackTrace,
      );
      final loc = AppLocalizations.of(context);
      setState(() {
        _currentOtp = CharConstants.empty;
        _errorMessage = loc.otpErrorMessageGeneration(e);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer == null) {
      _updateOtp();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateOtp();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<bool> copyValue() async {
    _logger.finer('Copying OTP value.');
    _highlightWidgetKey.currentState!.triggerHighlight();
    Provider.of<Analytics>(
      context,
      listen: false,
    ).events.trackCopyField(key: widget.fieldKey.key);
    await Clipboard.setData(ClipboardData(text: _currentOtp));
    return true;
  }

  @override
  Widget _buildEntryFieldEditor() =>
      _errorMessage?.let((it) => Text(it)) ??
      OtpFieldEntryEditor(
        period: _period,
        elapsed: _elapsed,
        otpCode: _currentOtp,
      );

  @override
  Future<void> _handleMenuEntrySelected(EntryAction entryAction) async {
    if (entryAction == EntryAction.copyRawData) {
      await Clipboard.setData(ClipboardData(text: _valueCurrent));
      return;
    }
    return super._handleMenuEntrySelected(entryAction);
  }

  @override
  List<PopupMenuEntry<EntryAction>> _buildMenuEntries(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return super
        ._buildMenuEntries(context)
        .where(
          (item) =>
              item is PopupMenuItem &&
              const [
                EntryAction.delete,
                EntryAction.copy,
                EntryAction.copyReference,
              ].contains((item as PopupMenuItem).value),
        )
        .followedBy([
          PopupMenuItem(
            value: EntryAction.copyRawData,
            child: ListTile(
              leading: const Icon(Icons.code),
              title: Text(loc.otpCopySecretActionLabel),
            ),
          ),
        ])
        .toList();
  }
}

class ObscuredEntryFieldEditor extends StatelessWidget {
  const ObscuredEntryFieldEditor({
    super.key,
    required this.onPressed,
    required this.onShowPressed,
    required this.commonField,
    required this.fieldKey,
  });

  final CommonField? commonField;
  final KdbxKey fieldKey;
  final VoidCallback onPressed;
  final VoidCallback onShowPressed;

  @override
  Widget build(BuildContext context) {
    final color = ThemeUtil.iconColor(Theme.of(context), null);
    final loc = AppLocalizations.of(context);
    final isDesktop =
        OpenValutPlatform.isLinux ||
        OpenValutPlatform.isWindows ||
        OpenValutPlatform.isMacOS;

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        InkWell(
          onTap: onPressed,
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: commonField?.icon == null
                  ? null
                  : Icon(commonField!.icon, size: isDesktop ? 14 : 24),
              labelText: commonField?.displayName ?? fieldKey.key,
              filled: true,
              labelStyle: TextStyle(
                color: color.withValues(alpha: 0.2),
                fontSize: isDesktop ? 13 : null,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 16,
              ),
            ),
            child: Text(
              nonNls('*') * 10,
              style: TextStyle(
                color: color.withValues(alpha: 0.2),
                fontSize: isDesktop ? 14 : null,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.eye),
          color: color,
          tooltip: loc.entryFieldActionRevealField,
          onPressed: onShowPressed,
        ),
      ],
    );
  }
}

class StringEntryFieldEditor extends StatelessWidget {
  const StringEntryFieldEditor({
    super.key,
    required this.onSaved,
    required this.controller,
    required this.formFieldKey,
    required this.focusNode,
    required this.commonField,
    required this.fieldKey,
    required this.delegate,
  });

  final Key formFieldKey;
  final FocusNode focusNode;
  final CommonField? commonField;
  final KdbxKey fieldKey;
  final TextEditingController? controller;
  final FormFieldSetter<String> onSaved;
  final FieldDelegate delegate;

  @override
  Widget build(BuildContext context) {
    final commonFields = Provider.of<CommonFields>(context);
    final loc = AppLocalizations.of(context);
    final color = ThemeUtil.iconColor(Theme.of(context), null);
    final isDesktop =
        OpenValutPlatform.isLinux ||
        OpenValutPlatform.isWindows ||
        OpenValutPlatform.isMacOS;
    final isUrl = fieldKey == commonFields.url.key;
    final isKp2aField = _isExtraWebsiteKey(fieldKey);
    final extraWebsiteNumber = _extraWebsiteNumber(fieldKey);
    final currentText = controller?.text.trim().toLowerCase() ?? '';
    final isAppLinkRow =
        isKp2aField &&
        (extraWebsiteNumber == null || currentText.startsWith('androidapp://'));
    final isAppLink = isAppLinkRow && currentText.startsWith('androidapp://');
    final fieldLabel = isUrl
        ? commonField!.displayName
        : isAppLink || isAppLinkRow
        ? loc.entryLinkApp
        : extraWebsiteNumber != null
        ? loc.entryTargetWebsite(extraWebsiteNumber)
        : commonField?.displayName ?? fieldKey.key;
    final isNotes = fieldKey == commonFields.notes.key;
    // 代码/密钥类内容用等宽字体，便于核对且视觉统一。
    final useMono =
        isAppLinkRow ||
        fieldKey == commonFields.password.key ||
        commonFields.isTotp(fieldKey) ||
        fieldKey.key == 'ssh-private-key' || // NON-NLS
        fieldKey.key == 'ssh-public-key'; // NON-NLS
    final inputField = TextFormField(
      key: formFieldKey,
      minLines: isNotes ? 4 : 1,
      maxLines: isUrl || isKp2aField
          ? 1
          : isNotes
          ? 8
          : null,
      focusNode: focusNode,
      style: TextStyle(
        fontSize: isDesktop ? 14 : 16,
        fontFamily: useMono ? OpenValutTheme.monoFontFamily : null,
      ),
      decoration: InputDecoration(
        filled: true,
        prefixIcon: isAppLinkRow
            ? Icon(
                Icons.smartphone,
                size: isDesktop ? 14 : 24,
              )
            : extraWebsiteNumber != null
            ? Icon(
                Icons.link,
                size: isDesktop ? 14 : 24,
              )
            : commonField?.icon == null
            ? null
            : Icon(commonField!.icon, size: isDesktop ? 14 : 24),
        labelText: fieldLabel,
        labelStyle: isDesktop ? const TextStyle(fontSize: 13) : null,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
      ),
      keyboardType: isKp2aField ? TextInputType.url : commonField?.keyboardType,
      autocorrect: commonField?.autocorrect ?? true,
      enableSuggestions: commonField?.enableSuggestions ?? true,
      textCapitalization:
          commonField?.textCapitalization ?? TextCapitalization.sentences,
      controller: controller,
      onSaved: onSaved,
    );
    // The password generator stays inside the password field, replacing the
    // empty text with a one-tap action.
    final passwordAction = ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller!,
      builder: (context, value, child) {
        if (fieldKey == commonFields.password.key && controller!.text.isEmpty) {
          return IconButton(
            tooltip: '${loc.menuItemGeneratePassword} (cmd+g)', // NON-NLS
            icon: const Icon(Icons.refresh),
            onPressed: delegate.generatePassword,
            color: color,
          );
        }
        return const SizedBox();
      },
    );
    // “关联 App”选择按钮放在输入框内部右侧，与其他字段保持一致的高度。
    final appLinkAction = ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller!,
      builder: (context, value, child) {
        if (!isAppLinkRow) {
          return const SizedBox();
        }
        return IconButton(
          tooltip: loc.entryPickAppTooltip,
          icon: const Icon(Icons.smartphone),
          onPressed: delegate.pickApp,
          color: color,
        );
      },
    );
    // URL actions (link to app / open website) live on their own row below
    // the input so a long url can never cover the icons.
    final urlActions = ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller!,
      builder: (context, value, child) {
        final text = value.text.trim().toLowerCase();
        final canOpen =
            isUrl || (extraWebsiteNumber != null && text.startsWith('http'));
        if (!canOpen) {
          return const SizedBox.shrink();
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value.text.trim().isNotEmpty)
              IconButton(
                tooltip: '${loc.actionOpenUrl} (shift+cmd+U)', // NON-NLS
                icon: const Icon(Icons.open_in_new),
                onPressed: delegate.openUrl,
                color: color,
                visualDensity: VisualDensity.compact,
              ),
          ],
        );
      },
    );
    final field = Stack(
      alignment: Alignment.centerRight,
      children: [inputField, passwordAction, appLinkAction],
    );
    if (isUrl || extraWebsiteNumber != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field,
          Align(alignment: Alignment.centerRight, child: urlActions),
        ],
      );
    }
    return field;
  }
}

class HighlightWidget extends StatefulWidget {
  const HighlightWidget({super.key, this.child, this.childOnHighlight});

  final Widget? child;
  final Widget? childOnHighlight;

  @override
  HighlightWidgetState createState() => HighlightWidgetState();
}

class HighlightWidgetState extends State<HighlightWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Animation<Decoration>? _decorationAnimation;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.addStatusListener(_animationStatusChanged);
  }

  void _animationStatusChanged(AnimationStatus status) {
    _logger.finer('Highlight animation status changed: $status');
    if (status == AnimationStatus.completed) {
      setState(() {
        _decorationAnimation = null;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _decorationAnimation == null
        ? widget.child!
        /* Stack(children: [
            widget.child,
            Positioned.fill(
                child: Opacity(
              opacity: 0.9,
              child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.5),
                    backgroundBlendMode: BlendMode.color,
                    /*boxShadow: const [BoxShadow(blurRadius: 2)]*/
                  ),
                  child: Center(child: widget.childOnHighlight)),
            ))
          ])*/
        : Stack(
            clipBehavior: Clip.none,
            children: [
              widget.child!,
              Positioned.fill(
                top: -4,
                bottom: -4,
                child: FadeTransition(
                  opacity: _opacity,
                  child: DecoratedBoxTransition(
                    decoration: _decorationAnimation!,
                    child: Center(child: widget.childOnHighlight),
                  ),
                ),
              ),
            ],
          );
  }

  void triggerHighlight() {
    final tween = DecorationTween(
      begin: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.8),
        //        backgroundBlendMode: BlendMode.color,
      ),
      end: BoxDecoration(
        color: Colors.green.withValues(alpha: 1),
        //        backgroundBlendMode: BlendMode.color,
      ),
      //      end: const BoxDecoration(color: Color(0xffffffff), backgroundBlendMode: BlendMode.overlay),
    );
    setState(() {
      _decorationAnimation = CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ).drive(tween);
      _opacity = CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ).drive(Tween(begin: 1, end: 0));
      _controller.forward(from: 0);
    });
  }
}
