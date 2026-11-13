import 'dart:async';
import 'dart:collection';

import 'package:built_collection/built_collection.dart';
import 'package:clock/clock.dart';
// import 'package:collection/collection.dart' show IterableExtension;
import 'package:diac_client/diac_client.dart';
import 'package:flinq/flinq.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_async_utils/flutter_async_utils.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kdbx/kdbx.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/bloc/analytics.dart';
import 'package:openvalut/bloc/app_data.dart';
import 'package:openvalut/bloc/kdbx/file_source.dart';
import 'package:openvalut/bloc/kdbx/file_source_local.dart';
import 'package:openvalut/bloc/kdbx/file_source_openvalut_cloud.dart';
import 'package:openvalut/bloc/kdbx/file_source_ui.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';
import 'package:openvalut/env/_base.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/openvalut_cloud/openvalut_client.dart';
import 'package:openvalut/openvalut_cloud/openvalut_cloud_session.dart';
import 'package:openvalut/openvalut_cloud/openvalut_share_service.dart';
import 'package:openvalut/ssh/import_ssh_keys.dart';
import 'package:openvalut/ssh/ssh_keygen.dart';
import 'package:openvalut/ui/common_fields.dart';
import 'package:openvalut/ui/screens/app_bar_menu.dart';
import 'package:openvalut/ui/screens/entry_details.dart';
import 'package:openvalut/ui/screens/group_list.dart';
import 'package:openvalut/ui/screens/master_password_change.dart';
import 'package:openvalut/ui/screens/my_shares_screen.dart';
import 'package:openvalut/ui/screens/password_categories.dart';
import 'package:openvalut/ui/screens/password_list_drawer.dart';
import 'package:openvalut/ui/screens/select_file_screen.dart';
import 'package:openvalut/ui/widgets/backup_warning_banner.dart';
import 'package:openvalut/ui/widgets/keyboard_handler.dart';
import 'package:openvalut/ui/widgets/primary_button.dart';
import 'package:openvalut/ui/widgets/savefile/save_file_diag_button.dart';
import 'package:openvalut/ui/widgets/shortcut/openvalut_intents.dart';
import 'package:openvalut/utils/brand_icons.dart';
import 'package:openvalut/utils/builtin_groups.dart';
import 'package:openvalut/utils/clipboard_auto_clear.dart';
import 'package:openvalut/utils/constants.dart';
import 'package:openvalut/utils/dialog_utils.dart';
import 'package:openvalut/utils/extension_methods.dart';
import 'package:openvalut/utils/format_utils.dart';
import 'package:openvalut/utils/password_strength.dart';
import 'package:openvalut/utils/platform.dart';
import 'package:openvalut/utils/predefined_icons.dart';
import 'package:openvalut/utils/sidebar_prefs.dart';
import 'package:openvalut/utils/theme_utils.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:string_literal_finder_annotations/string_literal_finder_annotations.dart';

final _logger = Logger('password_list');

class EntryViewModel implements Comparable<EntryViewModel> {
  EntryViewModel(this.entry, this.kdbxBloc)
    : label = entry.label,
      _labelComparable = entry.label?.toLowerCase() ?? CharConstants.empty,
      groupNames = _createGroupNames(entry.parent!),
      fileColor = kdbxBloc.fileForKdbxFile(entry.file).openedFile.color;

  /// Builds a view model, returning null when the entry is in a transient or
  /// broken state (null parent, missing file source) so one bad entry cannot
  /// blank the whole password list.
  static EntryViewModel? tryBuild(KdbxEntry entry, KdbxBloc kdbxBloc) {
    try {
      return EntryViewModel(entry, kdbxBloc);
    } catch (e) {
      return null;
    }
  }

  static const websiteKey = KdbxKeyCommon.URL;

  final KdbxBloc kdbxBloc;
  final KdbxEntry entry;

  late final String? website = _normalizeUrl();
  final String? label;
  final String _labelComparable;
  final List<String> groupNames;
  final Color? fileColor;

  static final hasSchemaRegexp = RegExp(r'^https?://');
  static final hasNewline = RegExp('[\r\n]');

  static List<String> _createGroupNames(KdbxGroup group) =>
      group.breadcrumbs.map((e) => e.name.get()!).toList();

  String? _normalizeUrl() {
    final url = entry.getString(websiteKey)?.getText()?.trim();
    if (url == null || url.isEmpty) {
      return null;
    }
    try {
      // If the url contains newlines, just take the first line.
      var urlToParse = url.split(hasNewline).first;
      if (!url.startsWith(hasSchemaRegexp)) {
        urlToParse = 'http://$urlToParse'; // NON-NLS
      }
      final parsed = Uri.parse(urlToParse);
      final resolved = parsed.resolve('/'); // NON-NLS
      //      _logger
      //          .finer('url $url ($parsed) with scheme $ret resolved to $resolved');
      return resolved.toString();
    } catch (e) {
      return null;
    }
  }

  @override
  int compareTo(EntryViewModel other) {
    if (entry == other.entry) {
      return 0;
    }
    return _labelComparable
        .compareTo(other._labelComparable)
        .unlessZero(() => entry.uuid.uuid.compareTo(other.entry.uuid.uuid));
  }
}

extension on int {
  int unlessZero(int Function() cb) => this == 0 ? cb() : this;
}

typedef OnEntrySelected =
    void Function(KdbxEntry entry, EntrySelectionType type);

class PasswordList extends StatefulWidget {
  const PasswordList({
    super.key,
    this.scaffoldKey,
    required this.onEntrySelected,
    this.selectedEntry,
  });

  static const routeSettings = RouteSettings(name: '/passwordList');

  static Widget phopenvalutwordList(BuildContext context) {
    return PasswordList(
      onEntrySelected: (entry, type) {
        if (type == EntrySelectionType.activeOpen) {
          Navigator.of(context).push(EntryDetailsScreen.route(entry: entry));
        }
      },
    );
  }

  static Route<void> route() => MaterialPageRoute(
    settings: routeSettings,
    builder: (context) => phopenvalutwordList(context),
  );

  final GlobalKey<ScaffoldState>? scaffoldKey;
  final KdbxEntry? selectedEntry;
  final OnEntrySelected onEntrySelected;

  @override
  State<PasswordList> createState() => _PasswordListState();
}

class _PasswordListState extends State<PasswordList> {
  /// Bumped on every dirty-object change of any opened file so the content
  /// widget can tell "the underlying data changed" apart from unrelated
  /// rebuilds and only recompute the entry list when it actually has to.
  int _dirtyRevision = 0;

  @override
  Widget build(BuildContext context) {
    final kdbxBloc = Provider.of<KdbxBloc>(context);

    final streams = kdbxBloc.openedFilesKdbx.map(
      (file) => file.dirtyObjectsChanged,
    );
    if (streams.isEmpty) {
      Provider.of<Analytics>(context).events.trackPasswordListEmpty();
      final loc = AppLocalizations.of(context);
      return Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: PrimaryButton(
          onPressed: () {
            Navigator.of(
              context,
              rootNavigator: true,
            ).pushAndRemoveUntil(SelectFileScreen.route(), (_) => false);
          },
          child: Text(loc.openFile),
        ),
      );
    }
    return StreamBuilder<int>(
      stream: Rx.merge(streams).map((x) => ++_dirtyRevision),
      builder: (context, snapshot) {
        return PasswordListContent(
          appData: context.watch<AppData>(),
          kdbxBloc: kdbxBloc,
          openedKdbxFiles: kdbxBloc.openedFilesKdbx,
          dataVersion: snapshot.data ?? 0,
          scaffoldKey: widget.scaffoldKey,
          selectedEntry: widget.selectedEntry,
          onEntrySelected: widget.onEntrySelected,
        );
      },
    );
  }
}

enum EntrySelectionType {
  /// entry was highlighted (e.g. via search or up/down arrows) must not switch context.
  passiveHighlight,

  /// entry was actively selected by the user (e.g. via tap).
  activeOpen,
}

class PasswordListContent extends StatefulWidget {
  const PasswordListContent({
    super.key,
    required this.appData,
    required this.kdbxBloc,
    required this.openedKdbxFiles,
    this.dataVersion = 0,
    this.scaffoldKey,
    required void Function(KdbxEntry entry, EntrySelectionType type)
    onEntrySelected,
    this.selectedEntry,
  }) : _onEntrySelected = onEntrySelected;

  final AppData appData;
  final KdbxBloc kdbxBloc;
  final List<KdbxFile> openedKdbxFiles;

  /// Bumped whenever an opened file's dirty state changed; used to invalidate
  /// the cached entry view models.
  final int dataVersion;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  final void Function(KdbxEntry entry, EntrySelectionType type)
  _onEntrySelected;
  final KdbxEntry? selectedEntry;

  void onEntrySelected(
    BuildContext context,
    KdbxEntry entry,
    EntrySelectionType type,
  ) {
    _onEntrySelected(entry, type);
    Provider.of<Analytics>(
      context,
      listen: false,
    ).events.trackSelectEntry(type: type);
  }

  @override
  _PasswordListContentState createState() => _PasswordListContentState();
}

class PasswordListFilterIsolateRunner {
  static List<EntryViewModel> filterEntries(
    AppData appData,
    List<EntryViewModel> allEntries,
    String query, {
    int maxResults = 30,
  }) {
    _logger.finer('We have to filter for $query');
    final searchKeys = appData.searchFields == CharConstants.star
        ? null
        : (appData.searchFields
                  ?.split(CharConstants.comma)
                  .map((e) => KdbxKey(e))
                  .toSet() ??
              searchFields);
    final terms = query.toLowerCase().split(CharConstants.space);
    return allEntries
        .where((entry) => matches(searchKeys, entry, terms))
        // take no more than 30 for now.
        .take(maxResults)
        .toList(growable: false);
  }

  static final searchFields = CommonFields.defaultSearchFields;

  static bool matches(
    Set<KdbxKey>? searchFields,
    EntryViewModel entry,
    List<String> filterTerms,
  ) {
    for (final term in filterTerms) {
      final matchesNoGroupName = entry.groupNames
          .where((string) => string.toLowerCase().contains(term))
          .isEmpty;
      if (searchFields == null) {
        if (entry.entry.stringEntries
                .where(
                  (element) =>
                      element.value?.getText()?.toLowerCase().contains(term) ==
                      true,
                )
                .isEmpty &&
            matchesNoGroupName) {
          return false;
        }
        continue;
      }
      if (searchFields
              .where(
                (field) =>
                    entry.entry
                        .getString(field)
                        ?.getText()
                        ?.toLowerCase()
                        .contains(term) ==
                    true,
              )
              .isEmpty &&
          matchesNoGroupName) {
        return false;
      }
    }
    return true;
  }
}

class GroupFilterEntry {
  const GroupFilterEntry({required this.group, required this.isRecursive});

  final KdbxGroup group;
  final bool isRecursive;
}

class GroupFilter {
  const GroupFilter({
    this.groups = const [],
    required this.showRecycleBin,
    required this.showActive,
    this.showWeakPasswords = false,
    required String name,
  }) : _name = name,
       nameLoc = null;

  const GroupFilter._({
    required this.showRecycleBin,
    required this.showActive,
    required this.nameLoc,
    this.showWeakPasswords = false,
  }) : groups = const [],
       _name = null;

  static final defaultGroupFilter = GroupFilter._(
    showRecycleBin: false,
    showActive: true,
    nameLoc: (loc) => loc.passwordFilterHideDeleted,
  );
  static final recycleBin = GroupFilter._(
    showRecycleBin: true,
    showActive: false,
    nameLoc: (loc) => loc.passwordFilterOnlyDeleted,
  );
  static final weakPasswords = GroupFilter._(
    showRecycleBin: false,
    showActive: true,
    showWeakPasswords: true,
    nameLoc: (loc) => loc.weakPasswordsLabel,
  );

  final List<GroupFilterEntry> groups;

  /// show items which are in the recycle bins.
  final bool showRecycleBin;

  /// show items which are not in recycle bins.
  final bool showActive;

  /// show only entries whose password is weak (see [isWeakPassword]).
  final bool showWeakPasswords;

  /// Name to display.
  final String? _name;

  final String Function(AppLocalizations loc)? nameLoc;

  String name(AppLocalizations loc) {
    return _name ?? nameLoc!(loc);
  }

  Iterable<KdbxEntry> getEntries(List<KdbxFile> files) {
    if (showWeakPasswords) {
      return files.expand(
        (f) => f.body.rootGroup.getAllEntries().where(
          (e) => !e.isInRecycleBin() && _isWeakEntry(e),
        ),
      );
    }
    if (groups.isNotEmpty) {
      return groups.expand((groupSelected) {
        final groups = groupSelected.isRecursive
            ? groupSelected.group.getAllGroups()
            : [groupSelected.group];
        if (showRecycleBin && showActive) {
          return groups.expand((g) => g.entries);
        } else if (showActive) {
          return groups
              .where((g) => g == groupSelected.group || g.file.recycleBin != g)
              .expand((g) => g.entries);
        } else if (showRecycleBin) {
          return groups
              .where((g) => g.file.recycleBin == g)
              .expand((g) => g.entries);
        } else {
          throw StateError(
            'Impossible. (showRecycleBin: $showRecycleBin,'
            'showActive: $showActive)',
          );
        }
      });
    }
    return files.expand((f) {
      if (showRecycleBin && showActive) {
        return f.body.rootGroup.getAllEntries();
      } else {
        final recycleBin = f.recycleBin;
        if (showRecycleBin) {
          return recycleBin?.entries ?? [];
        } else {
          return f.body.rootGroup
              .getAllGroups()
              .where((g) => g != recycleBin)
              .expand((e) => e.entries);
        }
      }
    });
  }

  static bool _isWeakEntry(KdbxEntry entry) {
    final password = entry.getString(KdbxKeyCommon.PASSWORD)?.getText();
    return isWeakPassword(password);
  }
}

class _CancelSearchFilterAction extends Action<CancelSearchFilterIntent> {
  _CancelSearchFilterAction(this.state);

  final _PasswordListContentState state;

  @override
  bool isActionEnabled = false;

  void updateEnabled() {
    final isEnabled = state._filterQuery != null;
    if (isActionEnabled != isEnabled) {
      isActionEnabled = isEnabled;
      notifyActionListeners();
    }
  }

  @override
  bool consumesKey(CancelSearchFilterIntent intent) {
    _logger.fine('_CancelSearchFilterAction.consumesKey() = $isActionEnabled');
    return isActionEnabled;
  }

  @override
  Object? invoke(CancelSearchFilterIntent intent) {
    state._cancelFilter();
    return null;
  }
}

class _PasswordListContentState extends State<PasswordListContent>
    with StreamSubscriberMixin, WidgetsBindingObserver, FutureTaskStateMixin {
  List<EntryViewModel>? _filteredEntries;

  String? get _filterQuery => __filterQuery;

  set _filterQuery(String? filterQuery) {
    __filterQuery = filterQuery;
    cancelSearchFilterAction.updateEnabled();
  }

  String? __filterQuery;
  final _filterTextEditingController = TextEditingController();
  final FocusNode _filterFocusNode = FocusNode();
  bool _speedDialOpen = false;
  final ValueNotifier<GroupFilter> _groupFilterNotifier = ValueNotifier(
    GroupFilter.defaultGroupFilter,
  );

  IntentActionRegistration? _actionsRegistration;

  late final _CancelSearchFilterAction cancelSearchFilterAction =
      _CancelSearchFilterAction(this);

  GroupFilter get _groupFilter => _groupFilterNotifier.value;
  KdbxGroup? get _selectedGroup {
    if (_groupFilter.groups.length == 1) {
      return _groupFilter.groups.first.group;
    }
    return null;
  }

  //  List<EntryViewModel> get _allEntries => _groupFilter == null
  //      ? widget.entries
  //      : _groupFilter
  //          .getAllEntries()
  //          .map((e) => EntryViewModel(e, widget.kdbxBloc))
  //          .toList();
  List<EntryViewModel>? _allEntries;

  /// Caches [EntryViewModel]s by entry uuid so switching the group filter
  /// doesn't have to reconstruct (and re-sort) a view model for every entry.
  /// Invalidated whenever the underlying vault data changes.
  final Map<String, EntryViewModel> _vmCache = {};

  //  final _isolateRunner = IsolateRunner.spawn();

  @override
  void initState() {
    super.initState();
    _logger.finer('Initializing password list content.');
    _loadPersistentSidebar();
    //    _isolateRunner.then((runner) => runner.run(PasswordListFilterIsolateRunner.init, widget.entries)).then((result) {
    //      _logger.finer('Initializd filter isolate $result');
    //    });
    WidgetsBinding.instance.addObserver(this);
    _organizeEntriesByCategory();
    _updateAllEntries();
    _groupFilterNotifier.addListener(_updateAllEntries);
    _updateDismissedBanners(widget.appData);
    // Once per open, pull any SSH key entries into their dedicated group.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final loc = AppLocalizations.of(context);
      final kdbxBloc = Provider.of<KdbxBloc>(context, listen: false);
      final moved = kdbxBloc.organizeSshKeyEntries();
      if (moved > 0) {
        _logger.info(
          'Organized $moved SSH entries into ${loc.sshKeysGroupName}.',
        );
      }
    });
  }

  void _organizeEntriesByCategory() {
    widget.openedKdbxFiles.forEach(organizeRootEntriesByCategory);
  }

  /// Live preference value. Using a getter guarantees the build method always
  /// sees the current value, even if the listener fired while the screen was
  /// not mounted.
  bool get _persistentSidebar => SidebarPrefs.persistentEnabled.value;

  void _loadPersistentSidebar() {
    final isDesktop =
        OpenValutPlatform.isLinux ||
        OpenValutPlatform.isWindows ||
        OpenValutPlatform.isMacOS;
    if (!isDesktop) {
      return;
    }
    SidebarPrefs.persistentEnabled.addListener(_onPersistentSidebarChanged);
    unawaited(SidebarPrefs.load());
  }

  void _onPersistentSidebarChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _updateDismissedBanners(AppData data) {
    _dismissedLocalFilesReady = true;
    setState(() {});
    _localBackupCandidate = _computeLocalBackupCandidate(data);
  }

  MapEntry<FileSource, KdbxFile>? _computeLocalBackupCandidate(AppData data) {
    final dismissed = data.dismissedBackupLocalFiles;
    for (final entry in widget.kdbxBloc.openedFilesWithSources) {
      if (entry.key is! FileSourceLocal) {
        continue;
      }
      if (dismissed?.contains(entry.key.uuid) ?? false) {
        continue;
      }
      final count = entry.value.body.rootGroup
          .getAllGroups()
          .where((element) => element != entry.value.recycleBin)
          .expand((element) => element.getAllEntries())
          .length;
      if (count >= 3) {
        return entry;
      }
    }
    return null;
  }

  void _updateAllEntries() {
    final watch = Stopwatch()..start();
    final kdbxBloc = widget.kdbxBloc;
    // The list may briefly reference a KdbxFile instance that was just
    // reloaded/replaced by the cloud auto-sync. Only build view models for
    // entries whose file is the currently opened instance, otherwise
    // EntryViewModel throws "Missing file source" and blanks the whole UI.
    final openFiles = kdbxBloc.openedFilesKdbx;
    final allEntries = SplayTreeSet<EntryViewModel>.from(
      _groupFilter
          .getEntries(widget.openedKdbxFiles)
          .where(
            (e) =>
                e.parent != null && openFiles.any((f) => identical(f, e.file)),
          )
          .map<EntryViewModel?>(
            (e) {
              final key = e.uuid.uuid;
              final cached = _vmCache[key];
              // Don't reuse a cached view model that points at an older file
              // instance (e.g. before a reload replaced the vault).
              if (cached != null && identical(cached.entry.file, e.file)) {
                return cached;
              }
              // A single entry with a broken parent/file must not blank the
              // whole list ("Missing file source" / null-parent regression).
              final vm = EntryViewModel.tryBuild(e, kdbxBloc);
              if (vm != null) {
                _vmCache[key] = vm;
              }
              return vm;
            },
          )
          .whereType<EntryViewModel>(),
      (EntryViewModel a, EntryViewModel b) => a.compareTo(b),
    );
    _allEntries = allEntries.toList(growable: false);
    watch.stop();
    _logger.finer(
      'Rebuilding PasswordList. (${_allEntries!.length} entries)'
      ' ${watch.elapsedMilliseconds}ms',
    );
    setState(() {});
  }

  /// `openedFilesKdbx` returns a fresh list instance on every access, so a
  /// plain `!=` comparison would always be true. Compare the actual files
  /// instead to detect real open/close/reload changes.
  bool _sameFiles(List<KdbxFile> a, List<KdbxFile> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }

  @override
  void didUpdateWidget(PasswordListContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final filesChanged = !_sameFiles(
      oldWidget.openedKdbxFiles,
      widget.openedKdbxFiles,
    );
    if (oldWidget.appData != widget.appData || filesChanged) {
      _updateDismissedBanners(widget.appData);
    }
    if (oldWidget.dataVersion != widget.dataVersion || filesChanged) {
      _vmCache.clear();
      _updateAllEntries();
    }
  }

  void _selectAllFilter() =>
      _filterTextEditingController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _filterTextEditingController.text.length,
      );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _logger.finer('didChangeAppLifecycleState($state)');
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _selectAllFilter();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    subscriptions.cancelSubscriptions();
    final shortcuts = Provider.of<KeyboardShortcutEvents>(context);
    _actionsRegistration?.dispose();
    _actionsRegistration = shortcuts.registerActions({
      SearchIntent: CallbackAction(
        onInvoke: (intent) => setState(() {
          if (_filterQuery == null || _filteredEntries == null) {
            _filterQuery ??= CharConstants.empty;
            _filteredEntries = _allEntries;
          }
          _selectAllFilter();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _filterFocusNode.requestFocus();
          });
        }),
      ),
      MoveUpIntent: CallbackAction(onInvoke: (intent) => _selectNextEntry(-1)),
      MoveDownIntent: CallbackAction(onInvoke: (intent) => _selectNextEntry(1)),
      // CancelSearchFilterIntent:
      //     CallbackAction(onInvoke: (intent) => _cancelFilter()),
      CancelSearchFilterIntent: cancelSearchFilterAction,
    });
  }

  @Deprecated('was only a workaround needed for manual shortcut handling')
  // ignore: unused_element
  bool _isFocusInForeignTextField() {
    final widget =
        WidgetsBinding.instance.focusManager.primaryFocus?.context?.widget;
    if (widget == null) {
      return false;
    }
    if (widget is EditableText) {
      if (widget.controller == _filterTextEditingController) {
        return false;
      }
      return true;
    }
    return false;
  }

  void _selectNextEntry(int next) {
    final entries = _filteredEntries ?? _allEntries!;
    if (entries.isEmpty) {
      return;
    }
    final idx = entries.indexWhere((a) => a.entry == widget.selectedEntry);
    // right now we ignore the fact that the user might select a list item which is not in view.
    // https://github.com/flutter/flutter/issues/12319
    if (idx < 0) {
      widget.onEntrySelected(
        context,
        entries.first.entry,
        EntrySelectionType.passiveHighlight,
      );
    } else {
      // new Index, modulo entry length to make sure we wrap around the end..
      final newIndex = (idx + next) % entries.length;
      widget.onEntrySelected(
        context,
        entries[newIndex].entry,
        EntrySelectionType.passiveHighlight,
      );
    }
  }

  @override
  void dispose() {
    _logger.info('Disposing isolate runner.');
    //    _isolateRunner.then<void>((runner) => runner.close());
    SidebarPrefs.persistentEnabled.removeListener(_onPersistentSidebarChanged);
    _filterFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _groupFilterNotifier.removeListener(_updateAllEntries);
    _groupFilterNotifier.dispose();
    _actionsRegistration?.dispose();
    super.dispose();
  }

  AppBar _buildDefaultAppBar(
    BuildContext context, {
    required bool canShowPersistentSidebar,
  }) {
    final kdbxBloc = Provider.of<KdbxBloc>(context);
    final isDirty = kdbxBloc.openedFiles.entries.any(
      (element) =>
          element.key.supportsWrite &&
          element.value.kdbxFile.dirtyObjects.isNotEmpty,
    );
    final loc = AppLocalizations.of(context);
    return AppBar(
      automaticallyImplyLeading: !canShowPersistentSidebar,
      title: const Text('OpenValut'), // NON-NLS
      actions: <Widget>[
        if (kdbxBloc.openedFilesKdbx.isNotEmpty)
          PopupMenuButton<String>(
            icon: const Icon(Icons.key),
            tooltip: loc.generateSshKeyPair,
            onSelected: (value) {
              if (value == 'generate') {
                _generateSshKey(context, kdbxBloc, loc);
              } else if (value == 'import') {
                unawaited(
                  showImportSshKeysDialog(
                    context,
                    kdbxBloc: kdbxBloc,
                    group: _groupFilter.groups.isNotEmpty
                        ? _groupFilter.groups.first.group
                        : null,
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'generate',
                child: Text(loc.generateSshKeyPair),
              ),
              PopupMenuItem(
                value: 'import',
                child: Text(loc.importSshKeys),
              ),
            ],
          ),
        ...?!isDirty
            ? null
            : [
                Builder(
                  builder: (context) => IconButton(
                    icon: Icon(
                      Icons.save,
                      semanticLabel: loc.saveButtonLabel,
                    ),
                    onPressed: () async {
                      final scaffold = ScaffoldMessenger.of(context);
                      final savedFiles = <String>[];
                      for (final entry in kdbxBloc.openedFiles.entries) {
                        if (entry.key.supportsWrite &&
                            entry.value.kdbxFile.dirtyObjects.isNotEmpty) {
                          await kdbxBloc.saveFile(entry.value.kdbxFile);
                          savedFiles.add(entry.key.displayName);
                        }
                      }
                      scaffold.showSnackBar(
                        SnackBar(
                          content: Text(
                            loc.savedFiles(
                              savedFiles.length,
                              savedFiles.join(Nls.COMMA_SPACE),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
        //        IconButton(
        //          icon: Icon(FontAwesomeIcons.sitemap),
        //          onPressed: () async {
        //            final groupFilter =
        //                await Navigator.of(context).push(GroupList.route(null));
        //            setState(() {
        //              _groupFilter = groupFilter;
        //              _filteredEntries = null;
        //              _filterTextEditingController.text = '';
        //            });
        //          },
        //        ),
        PopupMenuButton<VoidCallback>(
          useRootNavigator: true,
          icon: const FaIcon(FontAwesomeIcons.filter),
          tooltip: loc.filterButtonLabel,
          onSelected: (value) async {
            value();
            _logger.fine('onchanged - $value');
          },
          itemBuilder: (context) {
            final availableFilter = [
              GroupFilter.defaultGroupFilter,
              GroupFilter.recycleBin,
            ];
            if (!availableFilter.contains(_groupFilter)) {
              availableFilter.add(_groupFilter);
            }
            return <PopupMenuEntry<VoidCallback>>[
              ...availableFilter.map(
                (e) => CheckedPopupMenuItem<VoidCallback>(
                  value: () => _groupFilterNotifier.value = e,
                  checked: e == _groupFilter,
                  child: Text(e.name(loc)),
                ),
              ),
              //              const Divider(),
              PopupMenuItem(
                value: () async {
                  final groupFilter = await Navigator.of(context).push(
                    GroupListFlat.route(
                      _groupFilter.groups.map((e) => e.group).toSet(),
                    ),
                  );
                  if (groupFilter == null) {
                    return;
                  }
                  if (groupFilter.isEmpty) {
                    _groupFilterNotifier.value = GroupFilter.defaultGroupFilter;
                    return;
                  }
                  _createGroupFilter(loc, groupFilter);
                },
                child: ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(loc.filterCustomize),
                ),
              ),
            ];
          },
        ),
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: loc.searchButtonLabel,
          onPressed: () {
            setState(() {
              _filteredEntries = _allEntries;
            });
          },
        ),
        // 三个点的溢出菜单在移动端和桌面端都展示，二维码扫描入口移到菜单内。
        PopupMenuButton<VoidCallback>(
          useRootNavigator: true,
          key: const ValueKey('appBarOverflowMenu'),
          onSelected: (item) {
            item();
          },
          itemBuilder: (context) => [
            ...AppBarMenu.createDefaultPopupMenuItems(
              context,
              kdbxBloc.openedFiles,
            ),
          ],
        ),
      ],
    );
  }

  ThemeData filterAppBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.light) {
      return theme.copyWith(
        primaryColor: Colors.white,
        primaryIconTheme: theme.primaryIconTheme.copyWith(color: Colors.grey),
        //      primaryColorBrightness: Brightness.light,
        primaryTextTheme: theme.textTheme,
      );
    } else {
      return theme.copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.white,
          selectionColor: theme.colorScheme.secondary,
          selectionHandleColor: theme.colorScheme.secondary,
        ),
        //primaryColor: Colors.blue,
        //        cursorColor: Colors.red,
      );
    }
  }

  void _cancelFilter() {
    setState(() {
      _filterQuery = null;
      _filteredEntries = null;
    });
  }

  AppBar _buildFilterAppBar(BuildContext context) {
    final theme = filterAppBarTheme(context);
    final loc = AppLocalizations.of(context);
    return AppBar(
      backgroundColor: theme.primaryColor,
      iconTheme: theme.primaryIconTheme,
      toolbarTextStyle: theme.primaryTextTheme.bodyMedium,
      titleTextStyle: theme.primaryTextTheme.titleLarge,
      // old deprecated value:
      // textTheme: theme.primaryTextTheme,
      // brightness: theme.primaryColorBrightness,
      systemOverlayStyle: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _cancelFilter();
        },
      ),
      title: Theme(
        data: theme,
        child: TextField(
          style: theme.textTheme.titleLarge,
          // we also want the same cursorColor for mac/ios
          cursorColor: theme.textSelectionTheme.cursorColor,
          focusNode: _filterFocusNode,
          controller: _filterTextEditingController,
          onChanged: (newQuery) async {
            _logger.info('query changed to $newQuery');
            _updateFilterQuery(newQuery);
          },
          autofocus: true,
          decoration: InputDecoration(
            hintText: loc.searchHint,
            border: InputBorder.none,
            hintStyle: theme.inputDecorationTheme.hintStyle,
          ),
        ),
      ),
    );
  }

  int _updateFilterQuery(String newQuery) {
    // a text search replaces whatever the url matcher put on screen.
    final entries = PasswordListFilterIsolateRunner.filterEntries(
      widget.appData,
      _allEntries!,
      newQuery,
    );
    if (!mounted) {
      _logger.severe(
        'No longer mounted after updating filter query.',
        null,
        StackTrace.current,
      );
      return 0;
    }
    return _showFilteredEntries(newQuery, entries);
  }

  int _showFilteredEntries(String query, List<EntryViewModel> entries) {
    setState(() {
      _filterQuery = query;
      _filteredEntries = entries;
      if (_filteredEntries!.isNotEmpty &&
          (widget.selectedEntry == null ||
              !_filteredEntries!
                  .map((e) => e.entry)
                  .contains(widget.selectedEntry))) {
        widget.onEntrySelected(
          context,
          _filteredEntries!.first.entry,
          EntrySelectionType.passiveHighlight,
        );
        //                  // TODO this looks a bit like a workaround. But on MacOS we lose focus when
        //                  //      we show another password entry.
        //                  WidgetsBinding.instance.addPostFrameCallback((_) {
        //                    _filterFocusNode.requestFocus();
        //                  });
      }
    });
    return entries.length;
  }

  List<Widget>? _buildAutofillListPrefix() {
    return null;
  }

  List<Widget>? _buildListPrefix() {
    final kdbxBloc = Provider.of<KdbxBloc>(context);
    final unsupportedWrite = kdbxBloc.openedFilesWithSources.firstOrNullWhere(
      (f) => f.value.dirtyObjects.isNotEmpty && !f.key.supportsWrite,
    );
    if (unsupportedWrite == null) {
      return null;
    }
    return [UnsupportedWrite(source: unsupportedWrite.key)];
  }

  bool _dismissedLocalFilesReady = false;

  /// First local vault that still needs a backup, computed once per data
  /// change instead of re-traversing the whole vault on every build.
  MapEntry<FileSource, KdbxFile>? _localBackupCandidate;

  List<Widget>? _buildBackupWarningBanners() {
    final file = _localBackupCandidate;
    if (file == null || !_dismissedLocalFilesReady) {
      return null;
    }
    final kdbxBloc = widget.kdbxBloc;
    final loc = AppLocalizations.of(context);
    final analytics = context.watch<Analytics>();
    analytics.events.trackBackupBanner(BannerAction.shown);
    return [
      BackupBanner(
        loc.backupWarningMessage(file.key.displayName),
        backupWidget: SaveFileAsDialogButton(
          file: kdbxBloc.fileForFileSource(file.key)!,
          onSave: (saveFuture) {
            asyncRunTask((progress) async {
              analytics.events.trackBackupBanner(BannerAction.saved);
              await saveFuture;
            }, label: loc.saving);
          },
          child: Text(loc.backupButton),
        ),
        dismissText: loc.dismissBackupButton,
        onDismiss: () {
          analytics.events.trackBackupBanner(BannerAction.dismissed);
          context.read<AppDataBloc>().update(
            (builder, data) => builder.dismissedBackupLocalFiles =
                data.dismissedBackupLocalFiles?.toBuilder() ??
                      BuiltList<String>().toBuilder()
                  ..add(file.key.uuid),
          );
        },
      ),
    ];
  }

  List<Widget>? _buildPasswordReminderBanner() {
    final loc = AppLocalizations.of(context);
    final appData = context.read<AppData>();
    final days = appData.passwordReminderDays ?? 0;
    if (days <= 0) {
      return null;
    }
    final changed = appData.lastPasswordChangeDate;
    if (changed == null) {
      return null;
    }
    final due = changed.add(Duration(days: days));
    final remaining = due.difference(clock.now()).inDays;
    if (remaining > 3) {
      // Only start nagging a few days before the deadline.
      return null;
    }
    return [
      MaterialBanner(
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        content: Text(
          remaining < 0
              ? loc.masterPasswordExpiredBanner(-remaining)
              : loc.masterPasswordExpiresBanner(remaining),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final kdbxBloc = Provider.of<KdbxBloc>(context, listen: false);
              final fileSource =
                  kdbxBloc.openedFilesWithSources.firstOrNull?.key;
              if (fileSource == null) {
                return;
              }
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => MasterPasswordChangeScreen(
                    fileSource: fileSource,
                  ),
                ),
              );
            },
            child: Text(loc.changeMasterPasswordAction),
          ),
          TextButton(
            onPressed: () async {
              await context.read<AppDataBloc>().update(
                (builder, data) =>
                    builder..lastPasswordChangeDate = clock.now().toUtc(),
              );
            },
            child: Text(loc.remindLaterAction),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries ?? _allEntries;
    final listPrefix = [
      ...?_buildPasswordReminderBanner(),
      ...?_buildBackupWarningBanners(),
      ...?_buildAutofillListPrefix(),
      ...?_buildListPrefix(),
    ];
    if (listPrefix.isEmpty) {
      listPrefix.add(
        DiacMaterialBanner(
          diac: Provider.of<DiacBloc>(context),
        ),
      );
    }

    final theme = Theme.of(context);
    final kdbxBloc = Provider.of<KdbxBloc>(context);
    final loc = AppLocalizations.of(context);
    const sidebarWidth = 250.0;
    const minListWidthWhenSidebarVisible = 300.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final canShowPersistentSidebar =
            _persistentSidebar &&
            constraints.maxWidth >=
                sidebarWidth + minListWidthWhenSidebarVisible;
        return Actions(
          dispatcher: LoggingActionDispatcher(),
          actions: {
            SearchIntent: SearchAction(this),
          },
          child: Scaffold(
            key: widget.scaffoldKey,
            appBar: _filteredEntries == null
                ? _buildDefaultAppBar(
                    context,
                    canShowPersistentSidebar: canShowPersistentSidebar,
                  )
                : _buildFilterAppBar(context),
            drawer: canShowPersistentSidebar
                ? null
                : Drawer(
                    width: 240,
                    child: _buildSidebar(closeOnSelect: true),
                  ),
            body: canShowPersistentSidebar
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(
                        width: sidebarWidth,
                        child: ColoredBox(
                          color: Theme.of(context).colorScheme.surface,
                          child: _buildSidebar(closeOnSelect: false),
                        ),
                      ),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      Expanded(
                        child: _buildEntriesBody(context, listPrefix, entries),
                      ),
                    ],
                  )
                : GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapDown: (_) =>
                        widget.scaffoldKey?.currentState?.closeDrawer(),
                    child: _buildEntriesBody(context, listPrefix, entries),
                  ),
            floatingActionButton: _allEntries!.isEmpty || _filterQuery != null
                ? null
                : kdbxBloc.openedFiles.length == 1 ||
                      _groupFilter.groups.length == 1
                ? FloatingActionButton(
                    tooltip: loc.addNewPassword,
                    onPressed: () {
                      final group = _groupFilter.groups.isEmpty
                          ? null
                          : _groupFilter.groups.first.group;
                      final entry = kdbxBloc.createEntry(
                        file: group?.file,
                        group: group,
                      );
                      widget.onEntrySelected(
                        context,
                        entry,
                        EntrySelectionType.activeOpen,
                      );
                    },
                    child: const Icon(Icons.add),
                  )
                : SpeedDial(
                    tooltip: _speedDialOpen
                        ? CharConstants.empty
                        : loc.addNewPassword,
                    onOpen: () => setState(() => _speedDialOpen = true),
                    onClose: () => setState(() => _speedDialOpen = false),
                    overlayColor: theme.brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                    children: kdbxBloc.openedFiles.values
                        .map(
                          (file) => SpeedDialChild(
                            label: file.fileSource.displayName,
                            child: file.fileSource.displayIcon.iconData
                                .widget(),
                            labelBackgroundColor: Theme.of(context).cardColor,
                            backgroundColor: file.openedFile.colorCode == null
                                ? null
                                : Color(file.openedFile.colorCode!),
                            onTap: () {
                              final entry = kdbxBloc.createEntry(
                                file: file.kdbxFile,
                              );
                              widget.onEntrySelected(
                                context,
                                entry,
                                EntrySelectionType.activeOpen,
                              );
                            },
                          ),
                        )
                        .toList(),
                    child: Icon(_speedDialOpen ? Icons.close : Icons.add),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSidebar({required bool closeOnSelect}) {
    return PasswordListDrawer(
      selectedGroup: _selectedGroup,
      showRecycleBin: _groupFilter == GroupFilter.recycleBin,
      showWeakPasswords: _groupFilter == GroupFilter.weakPasswords,
      closeOnSelect: closeOnSelect,
      onAllSelected: () {
        _groupFilterNotifier.value = GroupFilter.defaultGroupFilter;
      },
      onGroupSelected: (group) {
        final loc = AppLocalizations.of(context);
        _groupFilterNotifier.value = GroupFilter(
          groups: [GroupFilterEntry(group: group, isRecursive: true)],
          showRecycleBin: false,
          showActive: true,
          name: builtInGroupDisplayName(group, loc) ?? loc.untitledLabel,
        );
      },
      onRecycleBinSelected: () {
        _groupFilterNotifier.value = GroupFilter.recycleBin;
      },
      onWeakPasswordsSelected: () {
        _groupFilterNotifier.value = GroupFilter.weakPasswords;
      },
      onMySharesSelected: () {
        Navigator.of(context).push(MySharesScreen.route());
      },
    );
  }

  Future<void> _generateSshKey(
    BuildContext context,
    KdbxBloc kdbxBloc,
    AppLocalizations loc,
  ) async {
    final name = await SimplePromptDialog(
      title: loc.generateSshKeyPair,
      labelText: loc.sshKeyNameLabel,
      initialValue: 'SSH Key',
    ).show(context);
    if (name == null || name.trim().isEmpty) {
      return;
    }

    final targetGroup = _groupFilter.groups.isNotEmpty
        ? _groupFilter.groups.first.group
        : null;
    final file = targetGroup?.file ?? kdbxBloc.openedFilesKdbx.first;
    // SSH keys always land in the dedicated SSH key group.
    final sshGroup = ensureSshKeyGroup(file);
    final entry = kdbxBloc.createEntry(
      file: file,
      group: sshGroup,
    );
    entry.label = name.trim();
    try {
      final generated = await generateSshKeyPair(
        comment: name.trim(),
      );
      entry.setString(
        KdbxKey('ssh-private-key'),
        PlainValue(generated.privateKey),
      );
      entry.setString(
        KdbxKey('ssh-public-key'),
        PlainValue(generated.publicKey),
      );
      kdbxBloc.organizeSshKeyEntries();
      await kdbxBloc.saveFile(file);
      if (!mounted) {
        return;
      }
      widget.onEntrySelected(
        context,
        entry,
        EntrySelectionType.activeOpen,
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(loc.sshKeyGenerated)),
        );
    } catch (e, stackTrace) {
      _logger.warning('SSH key generation failed.', e, stackTrace);
      if (mounted) {
        DialogUtils.showErrorDialog(
          context,
          loc.sshKeyGenerationFailedTitle,
          e.toString(),
        );
      }
    }
  }

  Widget _buildEntriesBody(
    BuildContext context,
    List<Widget> listPrefix,
    List<EntryViewModel>? entries,
  ) {
    final kdbxBloc = Provider.of<KdbxBloc>(context);
    return ProgressOverlay(
      task: task,
      child: _allEntries!.isEmpty
          ? _groupFilter.showWeakPasswords
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        Provider.of<AppLocalizations>(
                          context,
                        ).weakPasswordsEmpty,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : NoPasswordsEmptyView(
                    listPrefix: listPrefix,
                    onPrimaryButtonPressed: () {
                      final kdbxBloc = Provider.of<KdbxBloc>(
                        context,
                        listen: false,
                      );
                      final entry = kdbxBloc.createEntry();
                      //            Navigator.of(context).push(EntryDetailsScreen.route(entry: entry));
                      widget.onEntrySelected(
                        context,
                        entry,
                        EntrySelectionType.activeOpen,
                      );
                    },
                  )
          : ListView.builder(
              itemCount: entries!.length + 1,
              itemBuilder: (context, index) {
                // handle [listPrefix]
                if (index == 0) {
                  if (listPrefix.isEmpty) {
                    return const SizedBox();
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: listPrefix,
                  );
                }
                index--;

                final entry = entries[index];

                // Use the file colour captured when the view model was built;
                // re-resolving it through fileForKdbxFile() throws "Missing
                // file source" when a reload has replaced the file instance,
                // which blanked the whole list.
                final fileColor = entry.fileColor;
                return PasswordEntryListTileWrapper(
                  entry: entry,
                  fileColor: fileColor,
                  filterQuery: _filterQuery,
                  selectedEntry: widget.selectedEntry,
                  onEntrySelected: (KdbxEntry entry, EntrySelectionType type) {
                    widget.onEntrySelected(context, entry, type);
                  },
                );
              },
            ),
    );
  }

  void _createGroupFilter(AppLocalizations loc, Set<KdbxGroup> groupFilter) {
    if (groupFilter.isEmpty) {
      _groupFilterNotifier.value = GroupFilter.defaultGroupFilter;
      return;
    }
    final name = groupFilter.length == 1
        ? loc.passwordFilterPrefixForOneGroup(
            builtInGroupDisplayName(groupFilter.first, loc) ??
                loc.untitledLabel,
          )
        : loc.passwordFilterPrefixForMultipleGroups(groupFilter.length);
    _groupFilterNotifier.value = GroupFilter(
      groups: groupFilter
          .map((g) => GroupFilterEntry(group: g, isRecursive: true))
          .toList(),
      showRecycleBin: false,
      showActive: true,
      name: name,
    );
    _filteredEntries = null;
    _filterTextEditingController.text = CharConstants.empty;
  }
}

class SearchAction extends Action<SearchIntent> {
  SearchAction(this.state);

  final _PasswordListContentState state;

  @override
  Object? invoke(SearchIntent intent) {
    _logger.info('We should start search.');
    return null;
  }
}

class PasswordEntryListTileWrapper extends StatelessWidget {
  const PasswordEntryListTileWrapper({
    super.key,
    required this.entry,
    required this.selectedEntry,
    required this.fileColor,
    required String? filterQuery,
    required this.onEntrySelected,
  }) : _filterQuery = filterQuery;

  final EntryViewModel entry;
  final KdbxEntry? selectedEntry;
  final Color? fileColor;
  final String? _filterQuery;
  final OnEntrySelected onEntrySelected;

  Future<void> _showEntryContextMenu(
    BuildContext context,
    Offset position,
    CommonFields commonFields,
    AppLocalizations loc,
  ) async {
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem(
          value: 'open',
          child: ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(loc.editAction),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'copyUser',
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(loc.copyUsernameAction),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'copyPass',
          child: ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(loc.shortcutCopyPassword),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: ListTile(
            leading: const Icon(Icons.share),
            title: Text(loc.entryAttachmentShareActionLabel),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'rename',
          child: ListTile(
            leading: const Icon(Icons.drive_file_rename_outline),
            title: Text(loc.fieldRename),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (entry.entry.isInRecycleBin()) ...[
          PopupMenuItem(
            value: 'restore',
            child: ListTile(
              leading: const Icon(Icons.restore_from_trash),
              title: Text(loc.restoreFromRecycleBinAction),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'deletePermanently',
            child: ListTile(
              leading: const Icon(Icons.delete_forever_outlined),
              title: Text(loc.deletePermanentlyAction),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ]
        else
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(loc.deleteAction),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
    switch (action) {
      case 'open':
        onEntrySelected(entry.entry, EntrySelectionType.activeOpen);
        break;
      case 'copyUser':
        await _copyUsername(
          context,
          commonFields,
          loc,
          analyticsAction: 'context',
        );
        break;
      case 'copyPass':
        await _copyPassword(
          context,
          commonFields,
          loc,
          analyticsAction: 'context',
        );
        break;
      case 'share':
        await _shareEntry(context);
        break;
      case 'rename':
        final newName = await SimplePromptDialog(
          title: loc.renameEntryDialogTitle,
          labelText: loc.newNameFieldLabel,
          initialValue:
              entry.entry.getString(commonFields.title.key)?.getText() ?? '',
        ).show(context);
        if (newName != null && newName.isNotEmpty) {
          entry.entry.setString(commonFields.title.key, PlainValue(newName));
        }
        break;
      case 'restore':
        final entry2 = entry.entry;
        KdbxGroup? previousParent;
        final prevUuid = entry2.previousParentGroup.get();
        if (prevUuid != null) {
          try {
            previousParent = entry2.file.findGroupByUuid(prevUuid);
          } on StateError {
            previousParent = null;
          }
        }
        final target =
            (previousParent == null ||
                previousParent.isInRecycleBin() ||
                previousParent == entry2.file.recycleBin)
            ? entry2.file.body.rootGroup
            : previousParent;
        entry2.file.move(entry2, target);
        context.read<KdbxBloc>().refreshOpenedFiles();
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(loc.restoredSnack)));
        }
        break;
      case 'deletePermanently':
        if (!context.mounted) {
          break;
        }
        final confirmed = await DialogUtils.showConfirmDialog(
          context: context,
          params: ConfirmDialogParams(
            title: loc.deletePermanentlyAction,
            content: loc.permanentlyDeleteEntryConfirm(
              entry.entry.label ?? loc.untitledLabel,
            ),
            positiveButtonText: loc.deletePermanentlyAction,
          ),
        );
        if (!confirmed) {
          break;
        }
        if (!context.mounted) {
          break;
        }
        entry.entry.file.deletePermanently(entry.entry);
        context.read<KdbxBloc>().refreshOpenedFiles();
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(loc.permanentlyDeletedEntrySnackBar)),
            );
        }
        break;
      case 'delete':
        final oldGroup = entry.entry.parent;
        if (entry.entry.isInRecycleBin()) {
          // In the recycle bin "delete" means permanent deletion;
          // deleteEntry() is a no-op for already-recycled entries.
          entry.entry.file.deletePermanently(entry.entry);
        } else {
          entry.entry.file.deleteEntry(entry.entry);
        }
        context.read<KdbxBloc>().refreshOpenedFiles();
        final scaffoldManager = ScaffoldMessenger.of(context);
        scaffoldManager.hideCurrentSnackBar();
        final controller = scaffoldManager.showSnackBar(
          SnackBar(
            content: Text(loc.deletedSnack),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: loc.undoAction,
              onPressed: () {
                final group = oldGroup;
                if (group != null) {
                  entry.entry.file.move(entry.entry, group);
                }
              },
            ),
          ),
        );
        // Explicit fallback: on some Flutter desktop builds the auto-dismiss
        // timer is not started when a snackbar is shown from a popup menu.
        var snackBarClosed = false;
        controller.closed.then(
          (_) => snackBarClosed = true,
          onError: (_) => snackBarClosed = true,
        );
        Timer(const Duration(seconds: 2), () {
          if (!snackBarClosed) {
            controller.close();
          }
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final commonFields = Provider.of<CommonFields>(context);
    final theme = Theme.of(context);
    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: loc.swipeCopyPassword): () =>
            _copyPassword(
              context,
              commonFields,
              loc,
              analyticsAction: 'semantic',
            ),
        CustomSemanticsAction(label: loc.swipeCopyUsername): () =>
            _copyUsername(
              context,
              commonFields,
              loc,
              analyticsAction: 'semantic',
            ),
      },
      child: Dismissible(
        key: ValueKey(entry.entry.uuid),
        resizeDuration: null,
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
              Text(loc.swipeCopyPassword),
            ],
          ),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          color: theme.brightness == Brightness.light
              ? Colors.limeAccent
              : Colors.brown,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.account_circle),
              const SizedBox(height: 4),
              Text(loc.swipeCopyUsername),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            await _copyUsername(context, commonFields, loc);
          } else {
            await _copyPassword(context, commonFields, loc);
          }
          return false;
        },
        child: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Container(
            decoration: selectedEntry != entry.entry
                ? null
                : BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.55,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
            child: PasswordEntryTile(
              vm: entry,
              isSelected: entry.entry == selectedEntry,
              filterQuery: _filterQuery,
              onTap: () {
                //                      Navigator.of(context).push(EntryDetailsScreen.route(entry: entry));
                onEntrySelected(entry.entry, EntrySelectionType.activeOpen);
              },
              onSecondaryTapDown: (details) => _showEntryContextMenu(
                context,
                details.globalPosition,
                commonFields,
                loc,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyUsername(
    BuildContext context,
    CommonFields commonFields,
    AppLocalizations loc, {
    @NonNls String analyticsAction = 'swipe',
  }) async {
    final analytics = context.read<Analytics>();
    final stringValue = entry.entry.getString(commonFields.userName.key);
    if (stringValue == null || stringValue.isNullOrEmpty()) {
      context.showSnackBar(loc.copyUsernameNotExists);
      return;
    }
    await ClipboardAutoClear.copyWithAutoClear(
      stringValue.getText() ?? CharConstants.empty,
    );
    // ignore: use_build_context_synchronously
    context.showSnackBar(loc.doneCopiedUsername);
    analytics.events.trackCopyUsername(action: analyticsAction);
  }

  Future<void> _copyPassword(
    BuildContext context,
    CommonFields commonFields,
    AppLocalizations loc, {
    @NonNls String analyticsAction = 'swipe',
  }) async {
    final stringValue = entry.entry.getString(commonFields.password.key);
    if (stringValue == null || stringValue.isNullOrEmpty()) {
      context.showSnackBar(loc.copyPasswordNotExists);
      return;
    }
    await ClipboardAutoClear.copyWithAutoClear(
      stringValue.getText() ?? CharConstants.empty,
    );
    // ignore: use_build_context_synchronously
    context.showSnackBar(loc.doneCopiedPassword);
    // ignore: use_build_context_synchronously
    context.read<Analytics>().events.trackCopyPassword(action: analyticsAction);
  }

  Future<void> _shareEntry(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final kdbxBloc = Provider.of<KdbxBloc>(context, listen: false);
    final opened = kdbxBloc.fileForKdbxFile(entry.entry.file);
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
    final recipient = await SimplePromptDialog(
      title: loc.shareWithFamilyTitle,
      labelText: loc.shareRecipientEmailLabel,
      helperText: loc.shareRecipientEmailHint,
    ).show(context);
    final email = recipient?.trim() ?? '';
    if (email.isEmpty) {
      return;
    }
    try {
      await openvalutShareService.instance.shareEntry(
        entry: entry.entry,
        recipientUsername: email,
        kdbxBloc: kdbxBloc,
      );
      if (!context.mounted) {
        return;
      }
      context.showSnackBar(loc.sharedToRecipient(email));
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
      await DialogUtils.showErrorDialog(context, loc.shareFailed, '$e');
    }
  }
}

class NoPasswordsEmptyView extends StatelessWidget {
  const NoPasswordsEmptyView({
    super.key,
    this.onPrimaryButtonPressed,
    this.listPrefix,
  });

  final List<Widget>? listPrefix;
  final VoidCallback? onPrimaryButtonPressed;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        ...?listPrefix,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Align(
              alignment: const Alignment(0, -0.7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    '🤗️', // NON-NLS
                    style: TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.emptyPasswordVaultPlaceholder,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    onPressed: onPrimaryButtonPressed,
                    child: Text(loc.emptyPasswordVaultButtonLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class UnsupportedWrite extends StatelessWidget {
  const UnsupportedWrite({super.key, required this.source});

  final FileSource source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: theme.colorScheme.error.withValues(alpha: 0.2),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: <Widget>[
              Icon(Icons.warning, color: theme.colorScheme.error),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Text(loc.changesWithoutSaving(source.displayName)),
                    const SizedBox(height: 4),
                    Text(source.displayPath, style: theme.textTheme.bodySmall),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        //                        FlatButton(
                        //                          child: const Text('Dismiss'),
                        //                          onPressed: () {},
                        //                        ),
                        TextButton(
                          onPressed: () {
                            final bloc = Provider.of<KdbxBloc>(
                              context,
                              listen: false,
                            );
                            bloc.saveLocally(source);
                          },
                          child: Text(loc.changesSaveLocally),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PasswordEntryTile extends StatelessWidget {
  const PasswordEntryTile({
    super.key,
    required this.vm,
    required this.isSelected,
    required this.filterQuery,
    this.onTap,
    this.onSecondaryTapDown,
  });

  final EntryViewModel vm;
  final bool isSelected;
  final String? filterQuery;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onSecondaryTapDown;

  Widget _defaultIcon(Color? fgColor, ThemeData theme, double size) =>
      EntryIcon.defaultIcon(vm, fgColor, theme, size);

  @override
  Widget build(BuildContext context) {
    final commonFields = Provider.of<CommonFields>(context);
    final theme = Theme.of(context);
    final fgColor = isSelected ? theme.colorScheme.onPrimaryContainer : null;
    final iconTheme = IconTheme.of(context);
    // Keep row icons at the theme's base icon size (14 on Linux/Windows
    // desktop) so they stay compact on high-DPI laptops.
    final size = iconTheme.size!;
    final loc = AppLocalizations.of(context);

    final icon = EntryIcon(
      vm: vm,
      size: size,
      fallback: (context) => _defaultIcon(fgColor, theme, size),
    );

    return InkWell(
      onTap: onTap,
      onSecondaryTapDown: onSecondaryTapDown,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: icon,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  DefaultTextStyle(
                    style: theme.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.normal,
                      color: fgColor,
                    ),
                    child: Text.rich(
                      _highlightFilterQuery(vm.label?.nullIfBlank()) ??
                          TextSpan(text: loc.noTitle),
                      //                      style: theme.textTheme.subtitle1.copyWith(fontWeight: null),
                    ),
                  ),
                  const SizedBox(height: 2),
                  DefaultTextStyle(
                    style: theme.textTheme.bodyLarge!.copyWith(
                      fontSize: 13,
                      color: fgColor ?? theme.textTheme.bodySmall!.color,
                    ),
                    child: Text.rich(
                      _highlightFilterQuery(
                            commonFields.userName
                                .stringValue(vm.entry)
                                ?.nullIfBlank(),
                          ) ??
                          TextSpan(text: loc.noUsername),
                      style: theme.textTheme.bodyLarge!.copyWith(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall!.color,
                      ),
                    ),
                  ),
                  ...?vm.groupNames.length < 2
                      ? null
                      : [
                          Text(
                            nonNls('📁️  ') +
                                vm.groupNames
                                    .sublist(1)
                                    .join(CharConstants.chevronRight),
                            overflow: TextOverflow.fade,
                            maxLines: 1,
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodySmall!.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InlineSpan? _highlightFilterQuery(String? text) {
    if (text == null) {
      return null;
    }
    final filterQuery = this.filterQuery;
    if (filterQuery == null || filterQuery.isEmpty) {
      return TextSpan(text: text);
    }
    final lcText = text.toLowerCase();
    final lcFilterTerms = filterQuery.toLowerCase().split(CharConstants.space);
    final filterRegexp = RegExp(
      lcFilterTerms.map((e) => RegExp.escape(e)).join('|'),
    );
    var previousMatchEnd = 0;
    final spans = <TextSpan>[];
    for (final match in filterRegexp.allMatches(lcText)) {
      spans.add(TextSpan(text: text.substring(previousMatchEnd, match.start)));
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      );
      previousMatchEnd = match.end;
    }
    if (previousMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(previousMatchEnd)));
    }
    return TextSpan(children: spans);
  }
}

class EntryIcon extends StatelessWidget {
  const EntryIcon({
    super.key,
    required this.vm,
    required this.fallback,
    required this.size,
  });

  final EntryViewModel vm;
  final double size;
  final Widget Function(BuildContext context) fallback;

  static final newLineRegexp = RegExp(r'[\r\n]');

  @override
  Widget build(BuildContext context) {
    final env = context.watch<Env>();
    final appData = context.watch<AppData>();
    if (!(appData.fetchWebsiteIcons ??
        env.featureFetchWebsiteIconEnabledByDefault)) {
      return fallback(context);
    }

    final url = vm.website?.trim();

    if (url == null) {
      return fallback(context);
    }

    if (url.contains(newLineRegexp)) {
      // If the url field contains a new line, it's definitely not a URL.
      // So to avoid spilling secrets over the network, ignore it altogether.
      return fallback(context);
    }

    return fallback(context);
  }

  static Widget defaultIcon(
    EntryViewModel vm,
    Color? fgColor,
    ThemeData theme,
    double size,
  ) => defaultIconForEntry(
    vm.entry,
    fgColor,
    theme,
    size,
    fileColor: vm.fileColor,
  );

  static Widget defaultIconForEntry(
    KdbxEntry entry,
    Color? fgColor,
    ThemeData theme,
    double size, {
    Color? fileColor,
  }) {
    final brand = brandIconForEntry(entry);
    return entry.customIcon?.let(
          (customIcon) => Image.memory(
            customIcon.data,
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ) ??
        FaIcon(
          brand?.icon ??
              PredefinedIcons.iconFor(entry.icon.get() ?? KdbxIcon.Key),
          color:
              brand?.color ??
              (fgColor ?? ThemeUtil.iconColor(theme, fileColor)),
          size: size,
        );
  }
}
