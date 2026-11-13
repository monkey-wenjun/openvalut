import 'package:kdbx/kdbx.dart';
import 'package:openvalut/utils/read_access.dart';
import 'package:string_literal_finder_annotations/string_literal_finder_annotations.dart';

/// Shared-payload helpers used by both the entry share service and the
/// dynamic group share service. A shared payload is the entry's plain string
/// fields; internal OpenValut bookkeeping never travels with a share.

/// Returns the shareable plain string fields of [entry].
Map<String, String> sharedFieldsFromKdbx(KdbxEntry entry) {
  final fields = <String, String>{};
  for (final stringEntry in entry.stringEntries) {
    // Internal OpenValut bookkeeping (e.g. the CLI read allow flag) is a
    // local policy and must not travel with a share: the recipient decides
    // on their own device which entries CLI/scripts may read.
    if (isInternalReadAccessKey(stringEntry.key)) {
      continue;
    }
    final value = stringEntry.value?.getText();
    if (value != null && value.isNotEmpty) {
      fields[stringEntry.key.key] = value;
    }
  }
  return fields;
}

/// Applies shared [fields] onto [target].
void applySharedFieldsToKdbx(
  KdbxEntry target,
  Map<String, String> fields,
) {
  for (final entry in fields.entries) {
    if (isInternalReadAccessKey(KdbxKey(entry.key))) {
      continue;
    }
    target.setString(KdbxKey(entry.key), PlainValue(entry.value));
  }
}

/// The entry's 16-byte UUID as lowercase hex (the server's entry key).
String kdbxEntryUuidHex(KdbxEntry entry) {
  final bytes = entry.uuid.toBytes();
  return [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
}

/// Stable content hash of a shared payload, used to detect changes without
/// storing plaintext copies in local group-share metadata.
String sharedPayloadHash(Map<String, String> fields) {
  final keys = fields.keys.toList()..sort();
  final buffer = StringBuffer();
  for (final key in keys) {
    buffer
      ..write(key.length)
      ..write(':')
      ..write(key)
      ..write(fields[key]!.length)
      ..write(':')
      ..write(fields[key]);
  }
  return buffer.toString();
}

/// Internal field keys used by the group-share mirror on the recipient side.
@NonNls
class GroupShareMetaFields {
  static const source = 'openvalut.group-share-source'; // NON-NLS
  static const hash = 'openvalut.group-share-hash'; // NON-NLS
}
