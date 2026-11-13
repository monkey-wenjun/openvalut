import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kdbx/kdbx.dart';
import 'package:openvalut/bloc/analytics.dart';
import 'package:openvalut/bloc/kdbx/file_source_openvalut_cloud.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/openvalut_cloud/group_share_service.dart';
import 'package:openvalut/openvalut_cloud/openvalut_client.dart';
import 'package:openvalut/openvalut_cloud/openvalut_cloud_session.dart';
import 'package:openvalut/utils/builtin_groups.dart';
import 'package:openvalut/utils/dialog_utils.dart';
import 'package:openvalut/utils/format_utils.dart';
import 'package:openvalut/utils/password_strength.dart';
import 'package:openvalut/utils/platform.dart';
import 'package:openvalut/utils/read_access.dart';
import 'package:provider/provider.dart';

enum _DrawerGroupAction { rename, shareGroup, allowRead, denyRead }

class PasswordListDrawer extends StatefulWidget {
  const PasswordListDrawer({
    super.key,
    this.selectedGroup,
    required this.showRecycleBin,
    required this.onAllSelected,
    required this.onGroupSelected,
    required this.onRecycleBinSelected,
    required this.showWeakPasswords,
    required this.onWeakPasswordsSelected,
    this.onMySharesSelected,
    this.closeOnSelect = true,
  });

  final KdbxGroup? selectedGroup;
  final bool showRecycleBin;
  final VoidCallback onAllSelected;
  final void Function(KdbxGroup group) onGroupSelected;
  final VoidCallback onRecycleBinSelected;
  final bool showWeakPasswords;
  final VoidCallback onWeakPasswordsSelected;
  final VoidCallback? onMySharesSelected;
  final bool closeOnSelect;

  @override
  _PasswordListDrawerState createState() => _PasswordListDrawerState();
}

class _PasswordListDrawerState extends State<PasswordListDrawer> {
  bool initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      context.read<Analytics>().events.trackDrawerOpen();
      initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kdbxBloc = Provider.of<KdbxBloc>(context);

    final groups = <KdbxGroup>[];
    for (final file in kdbxBloc.openedFilesKdbx) {
      for (final group in file.body.rootGroup.groups) {
        if (group != file.recycleBin) {
          groups.add(group);
        }
      }
    }
    groups.sort(
      (a, b) => compareStringsIgnoreCase(
        a.name.get() ?? '',
        b.name.get() ?? '',
      ),
    );

    final allCount = kdbxBloc.openedFilesKdbx
        .expand((file) => file.body.rootGroup.getAllEntries())
        .where((entry) => !entry.isInRecycleBin())
        .length;
    final recycleBinCount = kdbxBloc.openedFilesKdbx.fold<int>(
      0,
      (sum, file) => sum + (file.recycleBin?.getAllEntries().length ?? 0),
    );
    final weakPasswordCount = kdbxBloc.openedFilesKdbx
        .expand((file) => file.body.rootGroup.getAllEntries())
        .where(
          (entry) =>
              !entry.isInRecycleBin() &&
              isWeakPassword(
                entry.getString(KdbxKeyCommon.PASSWORD)?.getText(),
              ),
        )
        .length;
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: groups.length + 5,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAllTile(theme, allCount);
              }
              if (index <= groups.length) {
                return _buildGroupTile(theme, groups[index - 1]);
              }
              if (index == groups.length + 1) {
                return const Divider();
              }
              if (index == groups.length + 2) {
                return _buildSecuritySection(theme, weakPasswordCount, loc);
              }
              if (index == groups.length + 3) {
                return _buildMySharesTile(theme);
              }
              return _buildRecycleBinTile(theme, recycleBinCount);
            },
          ),
        ),
        ListTile(
          leading: FaIcon(
            FontAwesomeIcons.plus,
            color: theme.iconTheme.color,
          ),
          title: Text(
            loc.groupListNewGroup,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () async {
            final newName = await SimplePromptDialog(
              title: loc.groupListNewGroup,
              labelText: loc.drawerGroupNameLabel,
            ).show(context);
            if (newName != null && newName.isNotEmpty) {
              final files = kdbxBloc.openedFilesKdbx;
              if (files.isNotEmpty) {
                files.first.createGroup(
                  parent: files.first.body.rootGroup,
                  name: newName,
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildAllTile(ThemeData theme, int count) {
    final loc = AppLocalizations.of(context);
    final isSelected =
        widget.selectedGroup == null &&
        !widget.showRecycleBin &&
        !widget.showWeakPasswords;
    final selectedColor = theme.colorScheme.onPrimaryContainer;
    return ListTile(
      tileColor: isSelected ? theme.colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      leading: FaIcon(
        FontAwesomeIcons.layerGroup,
        color: isSelected ? selectedColor : theme.iconTheme.color,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              loc.drawerAllEntries,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected ? selectedColor : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isSelected ? selectedColor : null,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onTap: () {
        widget.onAllSelected();
        if (widget.closeOnSelect) {
          Scaffold.of(context).closeDrawer();
        }
      },
    );
  }

  Widget _buildGroupTile(ThemeData theme, KdbxGroup group) {
    final loc = AppLocalizations.of(context);
    final isSelected = widget.selectedGroup == group;
    final selectedColor = theme.colorScheme.onPrimaryContainer;
    final count = group
        .getAllEntries()
        .where((e) => !e.isInRecycleBin())
        .length;
    final tile = ListTile(
      tileColor: isSelected ? theme.colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      leading: FaIcon(
        FontAwesomeIcons.folder,
        color: isSelected ? selectedColor : theme.iconTheme.color,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              builtInGroupDisplayName(group, loc) ?? loc.untitledLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected ? selectedColor : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isSelected ? selectedColor : null,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onTap: () {
        widget.onGroupSelected(group);
        if (widget.closeOnSelect) {
          Scaffold.of(context).closeDrawer();
        }
      },
      onLongPress: () => _showGroupActions(context, group, loc),
    );
    return GestureDetector(
      onSecondaryTapDown: (details) => _showGroupActions(
        context,
        group,
        loc,
        at: details.globalPosition,
      ),
      child: tile,
    );
  }

  Future<void> _showGroupActions(
    BuildContext context,
    KdbxGroup group,
    AppLocalizations loc, {
    Offset? at,
  }) async {
    final _DrawerGroupAction? action;
    if (at == null) {
      action = await showDialog<_DrawerGroupAction>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(
            builtInGroupDisplayName(group, loc) ?? loc.untitledLabel,
          ),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.of(context).pop(_DrawerGroupAction.rename),
              child: ListTile(
                leading: const Icon(Icons.edit),
                title: Text(loc.renameGroupDialogTitle),
              ),
            ),
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.of(context).pop(_DrawerGroupAction.shareGroup),
              child: ListTile(
                leading: const Icon(Icons.share),
                title: Text(loc.shareGroupTitle),
              ),
            ),
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.of(context).pop(_DrawerGroupAction.allowRead),
              child: ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: Text(loc.cliReadAllowTitle),
                subtitle: Text(loc.cliReadAllowSubtitle),
              ),
            ),
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.of(context).pop(_DrawerGroupAction.denyRead),
              child: ListTile(
                leading: const Icon(Icons.visibility_off_outlined),
                title: Text(loc.cliReadDenyTitle),
                subtitle: Text(loc.cliReadDenySubtitle),
              ),
            ),
          ],
        ),
      );
    } else {
      action = await showMenu<_DrawerGroupAction>(
        context: context,
        position: RelativeRect.fromLTRB(
          at.dx,
          at.dy,
          at.dx,
          at.dy,
        ),
        items: <PopupMenuEntry<_DrawerGroupAction>>[
          PopupMenuItem(
            value: _DrawerGroupAction.rename,
            child: ListTile(
              leading: const Icon(Icons.edit),
              title: Text(loc.renameGroupDialogTitle),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: _DrawerGroupAction.shareGroup,
            child: ListTile(
              leading: const Icon(Icons.share),
              title: Text(loc.shareGroupTitle),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: _DrawerGroupAction.allowRead,
            child: ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: Text(loc.cliReadAllowTitle),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: _DrawerGroupAction.denyRead,
            child: ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: Text(loc.cliReadDenyTitle),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      );
    }
    if (action == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    await _handleGroupAction(context, group, loc, action);
  }

  Future<void> _handleGroupAction(
    BuildContext context,
    KdbxGroup group,
    AppLocalizations loc,
    _DrawerGroupAction action,
  ) async {
    switch (action) {
      case _DrawerGroupAction.rename:
        final newName = await SimplePromptDialog(
          title: loc.renameGroupDialogTitle,
          labelText: loc.newNameFieldLabel,
          initialValue: group.name.get() ?? '',
        ).show(context);
        if (newName != null && newName.isNotEmpty) {
          group.name.set(newName);
        }
      case _DrawerGroupAction.shareGroup:
        await _shareGroup(context, group, loc);
      case _DrawerGroupAction.allowRead:
        var count = 0;
        for (final entry in group.getAllEntries()) {
          if (entry.isInRecycleBin()) {
            continue;
          }
          if (!isReadAllowed(entry)) {
            setReadAllowed(entry, true);
            count++;
          }
        }
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count == 0
                  ? loc.cliReadGroupAllAllowed
                  : loc.cliReadGroupAllowedCount(count),
            ),
          ),
        );
      case _DrawerGroupAction.denyRead:
        var denied = 0;
        for (final entry in group.getAllEntries()) {
          if (entry.isInRecycleBin()) {
            continue;
          }
          if (isReadAllowed(entry)) {
            setReadAllowed(entry, false);
            denied++;
          }
        }
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              denied == 0
                  ? loc.cliReadGroupAllDenied
                  : loc.cliReadGroupDeniedCount(denied),
            ),
          ),
        );
    }
  }

  Future<void> _shareGroup(
    BuildContext context,
    KdbxGroup group,
    AppLocalizations loc,
  ) async {
    final kdbxBloc = Provider.of<KdbxBloc>(context, listen: false);
    final opened = kdbxBloc.fileForKdbxFile(group.file);
    if (opened.fileSource is! FileSourceopenvalutCloud) {
      await DialogUtils.showSimpleAlertDialog(
        context,
        loc.shareGroupTitle,
        loc.shareGroupRequiresCloudVault,
        routeAppend: 'groupShareNotCloud',
      );
      return;
    }
    if (openvalutCloudSession.instance.currentClient == null) {
      await DialogUtils.showSimpleAlertDialog(
        context,
        loc.shareGroupTitle,
        loc.mySharesNeedLogin,
        routeAppend: 'groupShareNotLoggedIn',
      );
      return;
    }
    final recipient = await SimplePromptDialog(
      title: loc.shareGroupTitle,
      labelText: loc.shareRecipientEmailLabel,
      helperText: loc.shareRecipientEmailHint,
    ).show(context);
    if (!context.mounted) {
      return;
    }
    final email = recipient?.trim() ?? '';
    if (email.isEmpty) {
      return;
    }
    final currentUser =
        (openvalutCloudSession.instance.username ?? '').toLowerCase();
    if (email.toLowerCase() == currentUser) {
      await DialogUtils.showSimpleAlertDialog(
        context,
        loc.shareGroupTitle,
        loc.shareGroupSelfNotAllowed,
        routeAppend: 'groupShareSelf',
      );
      return;
    }
    final groupName =
        builtInGroupDisplayName(group, loc) ?? loc.untitledLabel;
    try {
      await openvalutGroupShareService.instance.createGroupShare(
        file: group.file,
        source: opened.fileSource as FileSourceopenvalutCloud,
        group: group,
        recipientUsername: email,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(loc.sharedGroupToRecipient(groupName, email)),
            ),
          );
      }
    } on openvalutApiException catch (e) {
      if (!context.mounted) {
        return;
      }
      final message = e.statusCode == 404
          ? loc.shareUserNotFound(email)
          : loc.shareFailedDetail(e.message);
      await DialogUtils.showErrorDialog(context, loc.shareFailed, message);
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      final message = switch (e) {
        GroupShareException(code: GroupShareErrorCodes.loginRequired) =>
          loc.mySharesNeedLogin,
        GroupShareException(code: GroupShareErrorCodes.recipientRequired) =>
          loc.shareGroupRecipientRequired,
        GroupShareException(code: GroupShareErrorCodes.cannotShareSelf) =>
          loc.shareGroupSelfNotAllowed,
        GroupShareException(code: GroupShareErrorCodes.alreadyShared) =>
          loc.shareGroupAlreadyShared(email),
        GroupShareException(code: GroupShareErrorCodes.groupNotInVault) =>
          loc.shareGroupRequiresCloudVault,
        _ => loc.shareFailedDetail('$e'),
      };
      await DialogUtils.showErrorDialog(context, loc.shareFailed, message);
    }
  }

  Widget _buildSecuritySection(
    ThemeData theme,
    int weakCount,
    AppLocalizations loc,
  ) {
    final isSelected = widget.showWeakPasswords;
    final selectedColor = theme.colorScheme.onPrimaryContainer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            loc.securityCategoryLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.disabledColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ListTile(
          tileColor: isSelected ? theme.colorScheme.primaryContainer : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          leading: FaIcon(
            FontAwesomeIcons.triangleExclamation,
            size: OpenValutPlatform.isDesktop ? 14 : 18,
            color: isSelected ? selectedColor : theme.iconTheme.color,
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  loc.weakPasswordsLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isSelected ? selectedColor : null,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$weakCount',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected ? selectedColor : null,
                ),
              ),
            ],
          ),
          selected: isSelected,
          onTap: () {
            widget.onWeakPasswordsSelected();
            if (widget.closeOnSelect) {
              Scaffold.of(context).closeDrawer();
            }
          },
        ),
      ],
    );
  }

  Widget _buildRecycleBinTile(ThemeData theme, int count) {
    final loc = AppLocalizations.of(context);
    final isSelected = widget.showRecycleBin;
    final selectedColor = theme.colorScheme.onPrimaryContainer;
    return ListTile(
      tileColor: isSelected ? theme.colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      leading: FaIcon(
        FontAwesomeIcons.trash,
        color: isSelected ? selectedColor : theme.iconTheme.color,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              loc.drawerRecycleBin,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected ? selectedColor : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isSelected ? selectedColor : null,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onTap: () {
        widget.onRecycleBinSelected();
        if (widget.closeOnSelect) {
          Scaffold.of(context).closeDrawer();
        }
      },
    );
  }

  Widget _buildMySharesTile(ThemeData theme) {
    final loc = AppLocalizations.of(context);
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      leading: FaIcon(
        FontAwesomeIcons.shareNodes,
        color: theme.iconTheme.color,
      ),
      title: Text(
        loc.drawerMyShares,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium,
      ),
      onTap: () {
        widget.onMySharesSelected?.call();
        if (widget.closeOnSelect) {
          Scaffold.of(context).closeDrawer();
        }
      },
    );
  }
}
