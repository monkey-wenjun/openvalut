import 'package:kdbx/kdbx.dart';

/// Row-level entry payload codec.
///
/// Each server row stores one entry encrypted with the vault key. The
/// plaintext is a JSON map produced by [encodeEntryRow]: the entry's standard
/// and custom string fields, which keys were stored protected, and the icon.
/// [applyEntryRow] restores a payload onto an entry in a live [KdbxFile].
Map<String, dynamic> encodeEntryRow(KdbxEntry entry) {
  final fields = <String, dynamic>{};
  final protected = <String>[];
  for (final pair in entry.stringEntries) {
    final value = pair.value;
    if (value == null) {
      continue;
    }
    final text = value.getText();
    if (text == null) {
      continue;
    }
    fields[pair.key.key] = text;
    if (value is ProtectedValue) {
      protected.add(pair.key.key);
    }
  }
  final icon = entry.icon.get();
  return <String, dynamic>{
    'fields': fields,
    'protected': protected,
    'icon': icon?.index,
  };
}

/// Applies a decoded row payload onto [entry] (which must already belong to a
/// live [KdbxFile], so protected values are re-protected in that file's
/// context).
void applyEntryRow(KdbxEntry entry, Map<String, dynamic> row) {
  final fields = (row['fields'] as Map<dynamic, dynamic>?) ?? const {};
  final protected =
      ((row['protected'] as List<dynamic>?) ?? const []).cast<String>();
  fields.forEach((key, value) {
    final name = key.toString();
    final text = value?.toString();
    if (text == null) {
      return;
    }
    entry.setString(
      KdbxKey(name),
      protected.contains(name)
          ? ProtectedValue.fromString(text)
          : PlainValue(text),
    );
  });
  final icon = row['icon'];
  if (icon is int && icon >= 0 && icon < KdbxIcon.values.length) {
    entry.icon.set(KdbxIcon.values[icon]);
  }
}