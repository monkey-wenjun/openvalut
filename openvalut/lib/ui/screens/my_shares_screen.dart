// FIXME need to fix this lint
// ignore_for_file: use_build_context_synchronously

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/bloc/kdbx/file_source_openvalut_cloud.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/openvalut_cloud/group_share_receiver.dart';
import 'package:openvalut/openvalut_cloud/group_share_service.dart';
import 'package:openvalut/openvalut_cloud/openvalut_cloud_session.dart';
import 'package:openvalut/openvalut_cloud/openvalut_share_service.dart';
import 'package:openvalut/theme.dart';
import 'package:openvalut/utils/dialog_utils.dart';
import 'package:openvalut/utils/share_prefs.dart';
import 'package:provider/provider.dart';
import 'package:string_literal_finder_annotations/string_literal_finder_annotations.dart';

final _logger = Logger('my_shares_screen');

/// Shows everything related to sharing, reachable from the sidebar:
///  - "我分享的": entries this account shared with others (+ revoke)
///  - "分享给我的": entries shared to this account (+ view / copy / save)
class MySharesScreen extends StatefulWidget {
  const MySharesScreen({super.key});

  static Route<void> route() => MaterialPageRoute<void>(
    settings: const RouteSettings(name: '/myShares'),
    builder: (context) => const MySharesScreen(),
  );

  @override
  _MySharesScreenState createState() => _MySharesScreenState();
}

class _MySharesScreenState extends State<MySharesScreen> {
  late Future<
    (
      List<openvalutIncomingShare>,
      List<openvalutOutgoingShare>,
      List<ReceivedGroupShare>,
      List<OutgoingGroupShareSummary>,
    )
  >
  _shares;

  @override
  void initState() {
    super.initState();
    _shares = _load();
  }

  Future<
    (
      List<openvalutIncomingShare>,
      List<openvalutOutgoingShare>,
      List<ReceivedGroupShare>,
      List<OutgoingGroupShareSummary>,
    )
  >
  _load() async {
    final kdbxBloc = Provider.of<KdbxBloc>(context, listen: false);
    final incoming = await openvalutShareService.instance.loadIncomingShares();
    final outgoing = await openvalutShareService.instance.loadOutgoingShares(
      kdbxBloc: kdbxBloc,
    );
    final incomingGroups =
        await openvalutGroupShareReceiver.instance.loadIncoming();
    final outgoingGroups =
        await openvalutGroupShareService.instance.loadOutgoing();
    await _autoSaveIncomingShares(kdbxBloc, incoming);
    await _autoSyncIncomingGroups(kdbxBloc, incomingGroups);
    return (incoming, outgoing, incomingGroups, outgoingGroups);
  }

  /// Automatically saves every incoming share into the currently opened
  /// OpenValut Cloud vault. Shares that were already saved are skipped.
  Future<void> _autoSaveIncomingShares(
    KdbxBloc kdbxBloc,
    List<openvalutIncomingShare> incoming,
  ) async {
    final loc = AppLocalizations.of(context);
    if (incoming.isEmpty) {
      return;
    }
    final cloudFile = kdbxBloc.openedFilesWithSources
        .where((entry) => entry.key is FileSourceopenvalutCloud)
        .map((entry) => entry.value)
        .firstOrNull;
    if (cloudFile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          DialogUtils.showSimpleAlertDialog(
            context,
            loc.myShareReceiveTitle,
            loc.myShareReceiveNeedVault,
            routeAppend: 'shareNeedsCloudVault',
          );
        }
      });
      return;
    }
    final savedIds = await SharePrefs.getAutoSavedShareIds();
    final toSave = incoming
        .where((s) => !savedIds.contains(s.share.id))
        .toList();
    if (toSave.isEmpty) {
      return;
    }
    final succeededShareIds = <String>[];
    for (final share in toSave) {
      try {
        final target = kdbxBloc.createEntry(file: cloudFile);
        openvalutShareService.applySharedEntryToKdbx(target, share.entry);
        succeededShareIds.add(share.share.id);
      } catch (e, stackTrace) {
        _logger.severe(
          'Auto-save incoming share ${share.share.id} failed',
          e,
          stackTrace,
        );
      }
    }
    if (succeededShareIds.isEmpty) {
      return;
    }
    var savedCount = 0;
    try {
      await kdbxBloc.saveFile(cloudFile);
      for (final shareId in succeededShareIds) {
        await SharePrefs.markAutoSaved(shareId);
      }
      savedCount = succeededShareIds.length;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to save cloud vault after auto-saving shares',
        e,
        stackTrace,
      );
    }
    if (savedCount > 0 && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(loc.myShareAutoSavedCount(savedCount))),
            );
        }
      });
    }
  }

  /// Mirrors every incoming dynamic group share into the opened cloud vault.
  /// Runs quietly every time the screen loads so the local copy follows the
  /// owner's latest changes (new rows, edits and removals).
  Future<void> _autoSyncIncomingGroups(
    KdbxBloc kdbxBloc,
    List<ReceivedGroupShare> groups,
  ) async {
    if (groups.isEmpty) {
      return;
    }
    final cloudFile = kdbxBloc.openedFilesWithSources
        .where((entry) => entry.key is FileSourceopenvalutCloud)
        .map((entry) => entry.value)
        .firstOrNull;
    if (cloudFile == null) {
      return;
    }
    try {
      await openvalutGroupShareReceiver.instance.syncToVault(
        kdbxBloc: kdbxBloc,
        file: cloudFile,
        received: groups,
      );
    } catch (e, stackTrace) {
      _logger.severe('Sync incoming group shares failed', e, stackTrace);
    }
  }

  Future<void> _syncIncomingGroup(ReceivedGroupShare groupShare) async {
    final loc = AppLocalizations.of(context);
    final kdbxBloc = Provider.of<KdbxBloc>(context, listen: false);
    final cloudFile = kdbxBloc.openedFilesWithSources
        .where((entry) => entry.key is FileSourceopenvalutCloud)
        .map((entry) => entry.value)
        .firstOrNull;
    if (cloudFile == null) {
      if (mounted) {
        await DialogUtils.showSimpleAlertDialog(
          context,
          loc.myShareReceiveTitle,
          loc.myShareReceiveNeedVault,
          routeAppend: 'groupShareNeedsCloudVault',
        );
      }
      return;
    }
    try {
      final count = await openvalutGroupShareReceiver.instance.syncToVault(
        kdbxBloc: kdbxBloc,
        file: cloudFile,
        received: [groupShare],
      );
      if (mounted && count > 0) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(loc.myShareGroupSyncedCount(count)),
            ),
          );
      }
    } catch (e, stackTrace) {
      _logger.severe('Manual group share sync failed', e, stackTrace);
      if (mounted) {
        await DialogUtils.showErrorDialog(
          context,
          loc.shareFailed,
          '$e',
        );
      }
    }
  }

  void _refresh() {
    setState(() {
      _shares = _load();
    });
  }

  Future<void> _revoke(openvalutOutgoingShare share) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await DialogUtils.showConfirmDialog(
      context: context,
      params: ConfirmDialogParams(
        title: loc.myShareRevokeTitle,
        content: loc.myShareRevokeConfirm(
          share.entryLabel ?? loc.myShareDeletedEntry,
        ),
        positiveButtonText: loc.myShareRevokeAction,
      ),
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      await openvalutShareService.instance.deleteOutgoingShare(share.share.id);
      if (mounted) {
        _refresh();
      }
    } catch (e, stackTrace) {
      _logger.severe('Revoke share failed', e, stackTrace);
      if (mounted) {
        await DialogUtils.showErrorDialog(
          context,
          loc.myShareRevokeFailed,
          '$e',
        );
      }
    }
  }

  Future<void> _revokeGroupShare(OutgoingGroupShareSummary share) async {
    final loc = AppLocalizations.of(context);
    final label = share.name ?? loc.myShareGroupBadge;
    final confirmed = await DialogUtils.showConfirmDialog(
      context: context,
      params: ConfirmDialogParams(
        title: loc.myShareRevokeTitle,
        content: loc.myShareRevokeConfirm(label),
        positiveButtonText: loc.myShareRevokeAction,
      ),
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      await openvalutGroupShareService.instance.revokeGroupShare(
        share.share.id,
      );
      if (mounted) {
        _refresh();
      }
    } catch (e, stackTrace) {
      _logger.severe('Revoke group share failed', e, stackTrace);
      if (mounted) {
        await DialogUtils.showErrorDialog(
          context,
          loc.myShareRevokeFailed,
          '$e',
        );
      }
    }
  }

  Future<void> _showIncomingDetails(openvalutIncomingShare share) async {
    final loc = AppLocalizations.of(context);
    final entry = share.entry;
    final extraFields = Map<String, String>.fromEntries(
      entry.fields.entries.where(
        (e) => !const {
          'Title',
          'UserName',
          'Password',
          'URL',
          'Notes',
        }.contains(e.key),
      ),
    );
    final fields = <String, String>{
      if (entry.label != null) loc.fieldTitle: entry.label!,
      if (entry.username != null) loc.webDavAuthUser: entry.username!,
      if (entry.url != null) loc.myShareUrlField: entry.url!,
      if (entry.notes != null) loc.myShareNotesField: entry.notes!,
      ...extraFields,
    };
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      entry.label ?? loc.myShareUntitledEntry,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: loc.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                loc.myShareFromOwner(share.ownerUsername),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final field in fields.entries)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            field.value,
                            style: const TextStyle(
                              fontFamily: OpenValutTheme.monoFontFamily,
                            ),
                          ),
                          subtitle: Text(field.key),
                          trailing: IconButton(
                            tooltip: loc.myShareCopyFieldTooltip(field.key),
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: field.value),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        loc.myShareCopiedField(field.key),
                                      ),
                                    ),
                                  );
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await DialogUtils.showConfirmDialog(
                          context: context,
                          params: ConfirmDialogParams(
                            title: loc.myShareDeleteTitle,
                            content: loc.myShareDeleteConfirm,
                            positiveButtonText: loc.deleteAction,
                          ),
                        );
                        if (!confirmed || !mounted) {
                          return;
                        }
                        try {
                          await openvalutShareService.instance
                              .deleteIncomingShare(
                                share.share.id,
                              );
                          if (mounted) {
                            Navigator.of(context).pop();
                            _refresh();
                          }
                        } catch (e, stackTrace) {
                          _logger.severe(
                            'Delete share failed',
                            e,
                            stackTrace,
                          );
                          if (mounted) {
                            await DialogUtils.showErrorDialog(
                              context,
                              loc.myShareDeleteFailed,
                              '$e',
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: Text(loc.deleteAction),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @NonNls
  String _formatCreated(int createdAt) {
    final time = DateTime.fromMillisecondsSinceEpoch(
      createdAt * 1000,
    ).toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (openvalutCloudSession.instance.currentClient == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.mySharesTitle)),
        body: Center(child: Text(loc.mySharesNeedLogin)),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.mySharesTitle),
        actions: <Widget>[
          IconButton(
            tooltip: loc.mySharesRefresh,
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body:
          FutureBuilder<
            (
              List<openvalutIncomingShare>,
              List<openvalutOutgoingShare>,
              List<ReceivedGroupShare>,
              List<OutgoingGroupShareSummary>,
            )
          >(
            future: _shares,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(loc.mySharesLoadFailed('${snapshot.error}')),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _refresh,
                        child: Text(loc.retryDialogActionLabel),
                      ),
                    ],
                  ),
                );
              }
              final (incoming, outgoing, incomingGroups, outgoingGroups) =
                  snapshot.data ??
                  (
                    <openvalutIncomingShare>[],
                    <openvalutOutgoingShare>[],
                    <ReceivedGroupShare>[],
                    <OutgoingGroupShareSummary>[],
                  );
              if (incoming.isEmpty &&
                  outgoing.isEmpty &&
                  incomingGroups.isEmpty &&
                  outgoingGroups.isEmpty) {
                return Center(child: Text(loc.mySharesEmpty));
              }
              return ListView(
                children: <Widget>[
                  if (outgoing.isNotEmpty || outgoingGroups.isNotEmpty) ...[
                    _SectionHeader(loc.mySharesByMe),
                    for (final share in outgoing)
                      ListTile(
                        leading: const Icon(Icons.share),
                        title: Text(
                          share.entryLabel ?? loc.myShareDeletedEntry,
                        ),
                        subtitle: Text(
                          loc.myShareOutgoingSubtitle(
                            share.recipientUsername,
                            _formatCreated(share.createdAt),
                          ),
                        ),
                        trailing: IconButton(
                          tooltip: loc.myShareRevokeTitle,
                          icon: const Icon(Icons.link_off),
                          onPressed: () => _revoke(share),
                        ),
                      ),
                    for (final groupShare in outgoingGroups)
                      ListTile(
                        leading: const Icon(Icons.folder_shared),
                        title: Text(
                          groupShare.name ?? loc.myShareGroupBadge,
                        ),
                        subtitle: Text(
                          loc.myShareOutgoingSubtitle(
                            groupShare.share.recipientUsername,
                            _formatCreated(groupShare.share.createdAt),
                          ),
                        ),
                        trailing: IconButton(
                          tooltip: loc.myShareRevokeTitle,
                          icon: const Icon(Icons.link_off),
                          onPressed: () => _revokeGroupShare(groupShare),
                        ),
                      ),
                  ],
                  if (incoming.isNotEmpty || incomingGroups.isNotEmpty) ...[
                    _SectionHeader(loc.mySharesToMe),
                    for (final share in incoming)
                      ListTile(
                        leading: const Icon(Icons.lock_open),
                        title: Text(
                          share.entry.label ?? loc.myShareUntitledEntry,
                        ),
                        subtitle: Text(
                          loc.myShareIncomingSubtitle(
                            share.ownerUsername,
                            _formatCreated(share.share.createdAt),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showIncomingDetails(share),
                      ),
                    for (final groupShare in incomingGroups)
                      ListTile(
                        leading: const Icon(Icons.folder_shared),
                        title: Text(
                          groupShare.name.isEmpty
                              ? loc.myShareGroupBadge
                              : groupShare.name,
                        ),
                        subtitle: Text(
                          loc.myShareGroupSubtitle(
                            groupShare.entries.length,
                            _formatCreated(groupShare.share.createdAt),
                            groupShare.share.ownerUsername,
                          ),
                        ),
                        trailing: TextButton.icon(
                          onPressed: () => _syncIncomingGroup(groupShare),
                          icon: const Icon(Icons.download, size: 18),
                          label: Text(loc.myShareGroupSyncAction),
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
