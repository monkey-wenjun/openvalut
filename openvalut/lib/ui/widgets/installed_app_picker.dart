import 'package:flutter/material.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/utils/installed_apps.dart';

/// Browsers, as far as autofill is concerned. Ignoring one of these silences
/// web page autofill too, which is almost never what the user meant to do, so
/// the multi-select asks before adding it. Seeded from the
/// `compatibility-package` list in
/// `deps/autofill_service/android/src/main/res/xml/service_configuration.xml`;
/// kept as a literal because that list is what the framework treats as
/// autofilling browsers, and it covers Firefox / Samsung Internet, which a
/// Chromium-only query would miss.
const Set<String> _browserPackages = <String>{
  'com.android.chrome', // NON-NLS
  'com.chrome.beta', // NON-NLS
  'com.chrome.dev', // NON-NLS
  'com.chrome.canary', // NON-NLS
  'com.microsoft.emmx', // NON-NLS
  'com.opera.browser', // NON-NLS
  'com.opera.browser.beta', // NON-NLS
  'com.opera.mini.native', // NON-NLS
  'com.opera.mini.native.beta', // NON-NLS
  'com.sec.android.app.sbrowser', // NON-NLS
  'com.sec.android.app.sbrowser.beta', // NON-NLS
  'org.mozilla.firefox', // NON-NLS
  'org.mozilla.firefox_beta', // NON-NLS
  'org.mozilla.fennec_aurora', // NON-NLS
};

/// Bottom sheet that lets the user pick an installed Android app by searching
/// its name (or package name). Returns the chosen app, or null on cancel.
Future<InstalledApp?> showInstalledAppPicker(BuildContext context) async {
  final picked = await _showSheet(
    context,
    multiSelect: false,
    initialSelected: const <String>{},
  );
  return picked is InstalledApp ? picked : null;
}

/// Multi-select variant used by "never autofill in these apps".
/// Returns the new complete selection, or null when the sheet was cancelled —
/// an empty set is a real answer ("ignore nothing"), cancel is not.
Future<Set<String>?> showIgnoredAppPicker(
  BuildContext context, {
  required Set<String> selected,
}) async {
  final picked = await _showSheet(
    context,
    multiSelect: true,
    initialSelected: selected,
  );
  return picked is Set<String> ? picked : null;
}

Future<Object?> _showSheet(
  BuildContext context, {
  required bool multiSelect,
  required Set<String> initialSelected,
}) {
  return showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => _InstalledAppPickerSheet(
      multiSelect: multiSelect,
      initialSelected: initialSelected,
    ),
  );
}

class _InstalledAppPickerSheet extends StatefulWidget {
  const _InstalledAppPickerSheet({
    required this.multiSelect,
    required this.initialSelected,
  });

  final bool multiSelect;
  final Set<String> initialSelected;

  @override
  _InstalledAppPickerSheetState createState() =>
      _InstalledAppPickerSheetState();
}

class _InstalledAppPickerSheetState extends State<_InstalledAppPickerSheet> {
  List<InstalledApp>? _apps;
  String _query = '';

  /// The selection is keyed on package names and seeded from the caller, never
  /// derived from [_apps]: an entry the user ignored earlier can be missing
  /// from the fetched list (uninstalled, or not launcher-visible), and rebuilding
  /// from what is on screen would drop it without saying so.
  late final Set<String> _selected = Set<String>.from(widget.initialSelected);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final apps = await fetchInstalledApps();
    if (!mounted) {
      return;
    }
    setState(() {
      _apps = apps;
    });
  }

  List<InstalledApp> get _filtered {
    final apps = _apps;
    if (apps == null) {
      return const [];
    }
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return apps;
    }
    return [
      for (final app in apps)
        if (app.label.toLowerCase().contains(query) ||
            app.packageName.toLowerCase().contains(query))
          app,
    ];
  }

  Future<void> _toggle(InstalledApp app) async {
    if (_selected.contains(app.packageName)) {
      setState(() => _selected.remove(app.packageName));
      return;
    }
    if (_browserPackages.contains(app.packageName.toLowerCase())) {
      final proceed = await _confirmIgnoreBrowser(app);
      if (!proceed) {
        return;
      }
    }
    setState(() => _selected.add(app.packageName));
  }

  Future<bool> _confirmIgnoreBrowser(InstalledApp app) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.prefAutofillIgnoreBrowserTitle),
        content: Text(loc.prefAutofillIgnoreBrowserBody(app.label)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(loc.prefAutofillIgnoreBrowserConfirm),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final apps = _apps;
    final filtered = _filtered;
    final multiSelect = widget.multiSelect;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text(
              multiSelect
                  ? loc.prefAutofillIgnoredAppsPickerTitle
                  : loc.entryLinkApp,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: loc.pickerSearchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const Divider(height: 12),
          Flexible(
            child: apps == null
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(loc.pickerNoMatchingApps)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final app = filtered[index];
                      final checked = _selected.contains(app.packageName);
                      return ListTile(
                        leading: multiSelect
                            ? Checkbox(
                                value: checked,
                                onChanged: (_) => _toggle(app),
                              )
                            : CircleAvatar(
                                child: Text(
                                  app.label.isEmpty
                                      ? '?'
                                      : app.label.characters.first.toUpperCase(),
                                ),
                              ),
                        title: Text(
                          app.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          app.packageName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: multiSelect
                            ? () => _toggle(app)
                            : () => Navigator.of(context).pop(app),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: multiSelect
                ? Row(
                    children: [
                      TextButton(
                        onPressed: _selected.isEmpty
                            ? null
                            : () => setState(_selected.clear),
                        child: Text(loc.prefAutofillIgnoredAppsRemoveAll),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(loc.cancel),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pop(Set<String>.from(_selected)),
                        child: Text(loc.prefAutofillIgnoredAppsDone),
                      ),
                    ],
                  )
                : TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(loc.cancel),
                  ),
          ),
        ],
      ),
    );
  }
}
