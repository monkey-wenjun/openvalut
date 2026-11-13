// FIXME need to fix this lint
// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:kdbx/kdbx.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/bloc/kdbx/file_source_openvalut_cloud.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/ui/widgets/password_input_field.dart';
import 'package:openvalut/utils/dialog_utils.dart';
import 'package:provider/provider.dart';

final _logger = Logger('import_passwords');

enum ImportSource { csv, kdbx }

/// One imported entry, shown in a selectable list before being written into
/// the cloud vault.
class ImportedItem {
  ImportedItem({
    required this.fields,
    this.binaries = const {},
    this.selected = true,
  });

  final Map<String, String> fields;
  final Map<String, dynamic> binaries;
  bool selected;

  String get title {
    final t = fields['Title'];
    return t ?? '';
  }
}

/// Imports passwords from a 1Password CSV export or an existing KDBX file
/// into the currently open OpenValut Cloud vault. The parsed entries are
/// shown first so the user can pick which ones to import.
class ImportPasswordsScreen extends StatefulWidget {
  const ImportPasswordsScreen({super.key});

  static Route<void> route() => MaterialPageRoute<void>(
    settings: const RouteSettings(name: '/importPasswords'),
    builder: (context) => const ImportPasswordsScreen(),
  );

  @override
  _ImportPasswordsScreenState createState() => _ImportPasswordsScreenState();
}

class _ImportPasswordsScreenState extends State<ImportPasswordsScreen> {
  ImportSource? _source;
  bool _busy = false;
  String? _error;
  String? _resultMessage;
  List<ImportedItem>? _items;

  Future<void> _loadSource() async {
    final loc = AppLocalizations.of(context);
    final source = _source;
    if (source == null) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _resultMessage = null;
    });
    try {
      final items = switch (source) {
        ImportSource.csv => await _loadCsv(),
        ImportSource.kdbx => await _loadKdbx(),
      };
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
      });
    } catch (e, stackTrace) {
      _logger.severe('Import load failed', e, stackTrace);
      if (mounted) {
        setState(() {
          _error = loc.importReadFailed('$e');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<List<ImportedItem>> _loadCsv() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'CSV', extensions: ['csv']),
      ],
    );
    if (file == null) {
      return const [];
    }
    final content = await file.readAsString();
    final rows = parseCsvRows(content);
    if (rows.isEmpty) {
      throw StateError(AppLocalizations.of(context).importCsvEmptyOrInvalid);
    }
    final headers = rows.first.map((h) => h.trim().toLowerCase()).toList();
    return rows.skip(1).map((row) {
      final fields = <String, String>{};
      for (var i = 0; i < headers.length && i < row.length; i++) {
        fields[headers[i]] = row[i];
      }
      final item = ImportedItem(fields: _csvFieldsToKdbx(fields));
      return item;
    }).toList();
  }

  /// Maps 1Password CSV columns to KDBX field names.
  Map<String, String> _csvFieldsToKdbx(Map<String, String> csv) {
    final out = <String, String>{};
    void add(String kdbxKey, String? value) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) {
        out[kdbxKey] = v;
      }
    }

    add('Title', csv['title']);
    add('URL', csv['url']);
    add('UserName', csv['username']);
    add('Password', csv['password']);
    add('Notes', csv['notes']);
    final otp = csv['otpauth']?.trim();
    if (otp != null && otp.isNotEmpty) {
      out['otp'] = otp.startsWith('otpauth://')
          ? otp
          : 'otpauth://totp/${out['Title'] ?? 'otp'}?secret=$otp';
    }
    return out;
  }

  Future<List<ImportedItem>> _loadKdbx() async {
    final loc = AppLocalizations.of(context);
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'KeePass', extensions: ['kdbx']),
      ],
    );
    if (file == null) {
      return const [];
    }
    final bytes = await file.readAsBytes();
    final kdbxBloc = Provider.of<KdbxBloc>(context, listen: false);

    while (true) {
      final password = await _askKdbxPassword(file.name);
      if (password == null) {
        return const [];
      }
      try {
        final sourceFile = await kdbxBloc.kdbxFormat.read(
          bytes,
          Credentials(ProtectedValue.fromString(password)),
        );
        return sourceFile.body.rootGroup.getAllEntries().map((entry) {
          return ImportedItem(
            fields: {
              for (final s in entry.stringEntries)
                s.key.key: s.value?.getText() ?? '',
            },
            binaries: {
              for (final b in entry.binaryEntries) b.key.key: b.value.value,
            },
          );
        }).toList();
      } on KdbxInvalidKeyException {
        if (!mounted) {
          return const [];
        }
        await DialogUtils.showSimpleAlertDialog(
          context,
          loc.importPasswordWrongTitle,
          loc.importPasswordWrongBody,
          routeAppend: 'importWrongPassword',
        );
        // Loop: ask for the password again.
      }
    }
  }

  Future<int> _importSelected() async {
    final loc = AppLocalizations.of(context);
    final cloudFile = _cloudVaultFile();
    if (cloudFile == null) {
      throw StateError(loc.importNeedCloudVault);
    }
    if (cloudFile.credentials is TransformedKeyCredentials) {
      throw StateError(loc.importReadonlyVaultWarning);
    }
    final kdbxBloc = Provider.of<KdbxBloc>(context, listen: false);
    final rootGroup = cloudFile.body.rootGroup;
    final selected = _items!.where((item) => item.selected).toList();
    var count = 0;
    for (final item in selected) {
      final entry = kdbxBloc.createEntry(file: cloudFile, group: rootGroup);
      for (final field in item.fields.entries) {
        if (field.value.isNotEmpty) {
          entry.setString(KdbxKey(field.key), PlainValue(field.value));
        }
      }
      for (final binary in item.binaries.entries) {
        entry.createBinary(
          isProtected: false,
          name: binary.key,
          bytes: binary.value as Uint8List,
        );
      }
      count++;
    }
    if (count > 0) {
      await kdbxBloc.saveFile(cloudFile);
    }
    return count;
  }

  KdbxFile? _cloudVaultFile() {
    final kdbxBloc = Provider.of<KdbxBloc>(context, listen: false);
    final cloudFile = kdbxBloc.openedFilesWithSources
        .where((entry) => entry.key is FileSourceopenvalutCloud)
        .map((entry) => entry.value)
        .firstOrNull;
    return cloudFile;
  }

  Future<String?> _askKdbxPassword(String fileName) {
    final loc = AppLocalizations.of(context);
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.importKdbxPasswordTitle),
        content: PasswordInputField(
          controller: controller,
          autofocus: true,
          labelText: loc.importPasswordLabelForFile(fileName),
          showVisibilityToggle: false,
          onFieldSubmitted: (v) {
            if (v.isNotEmpty) {
              Navigator.of(context).pop(v);
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
              final v = controller.text;
              if (v.isNotEmpty) {
                Navigator.of(context).pop(v);
              }
            },
            child: Text(loc.okAction),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmImport() async {
    final loc = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
      _resultMessage = null;
    });
    try {
      final count = await _importSelected();
      if (!mounted) {
        return;
      }
      // Imported entries are already visible in the vault list; go back to
      // the main page and show a short confirmation there.
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(loc.importDoneCount(count))));
    } catch (e, stackTrace) {
      _logger.severe('Import failed', e, stackTrace);
      if (mounted) {
        setState(() {
          _error = loc.importFailed('$e');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final items = _items;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.menuImportPasswords),
        actions: <Widget>[
          if (items != null)
            TextButton(
              onPressed: () => setState(() {
                _items = null;
                _resultMessage = null;
              }),
              child: Text(loc.importReselectAction),
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: items == null
                ? _buildSourcePicker(theme)
                : _buildItemList(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildSourcePicker(ThemeData theme) {
    final loc = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          loc.importSourcePickerIntro,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        _SourceCard(
          icon: Icons.table_chart_outlined,
          title: '1Password CSV',
          subtitle: loc.importSource1PasswordCsvSubtitle,
          selected: _source == ImportSource.csv,
          onTap: () => setState(() => _source = ImportSource.csv),
        ),
        const SizedBox(height: 12),
        _SourceCard(
          icon: Icons.lock_outline,
          title: loc.importSourceKdbxTitle,
          subtitle: loc.importSourceKdbxSubtitle,
          selected: _source == ImportSource.kdbx,
          onTap: () => setState(() => _source = ImportSource.kdbx),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _busy || _source == null ? null : _loadSource,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.file_open_outlined),
          label: Text(
            _busy ? loc.importReadingEllipsis : loc.importSelectFileAndRead,
          ),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      ],
    );
  }

  Widget _buildItemList(ThemeData theme) {
    final loc = AppLocalizations.of(context);
    final items = _items!;
    final selectedCount = items.where((i) => i.selected).length;
    final allSelected = selectedCount == items.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Checkbox(
              value: allSelected,
              onChanged: (v) => setState(() {
                for (final item in items) {
                  item.selected = v ?? false;
                }
              }),
            ),
            Text(loc.importSelectAllCount(items.length)),
            const Spacer(),
            Text(loc.importSelectedCount(selectedCount)),
          ],
        ),
        const Divider(height: 1),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return CheckboxListTile(
                value: item.selected,
                dense: true,
                title: Text(
                  item.title.isEmpty ? loc.importUntitledEntry : item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    item.fields['UserName'],
                    item.fields['URL'],
                  ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onChanged: (v) => setState(() {
                  item.selected = v ?? false;
                }),
              );
            },
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        if (_resultMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _resultMessage!,
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy || selectedCount == 0 ? null : _confirmImport,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_done_outlined),
          label: Text(
            _busy
                ? loc.importImportingEllipsis
                : loc.importImportSelectedCount(selectedCount),
          ),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: selected ? theme.colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: selected ? const Icon(Icons.check_circle) : null,
        onTap: onTap,
      ),
    );
  }
}

/// Minimal RFC 4180-ish CSV parser: comma separated, double-quoted fields
/// with "" escaping, CRLF tolerant. Empty lines are dropped.
List<List<String>> parseCsvRows(String content) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < content.length; i++) {
    final c = content[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < content.length && content[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
    } else {
      switch (c) {
        case '"':
          inQuotes = true;
        case ',':
          row.add(field.toString());
          field.clear();
        case '\n':
          row.add(field.toString());
          rows.add(row);
          row = <String>[];
          field.clear();
        case '\r':
          break;
        default:
          field.write(c);
      }
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows.where((r) => r.any((f) => f.trim().isNotEmpty)).toList();
}
