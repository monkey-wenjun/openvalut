import 'package:kdbx/kdbx.dart';

/// Reserved entry-field prefix used for internal OpenValut bookkeeping.
///
/// Fields with this prefix are never shown as user custom fields; they are
/// still carried by the KDBX file (and by cloud row sync), which is what lets
/// the desktop app, `openvalut-cli` and the local credential server agree on
/// the read allow-list.
const String readAccessInternalPrefix = 'openvalut.'; // NON-NLS

/// Hidden entry field marking that CLI / scripts may list and read the entry.
/// The read interfaces are deny-by-default: entries without this field set to
/// "1" (and entries inside groups that were never explicitly allowed) are not
/// listed or readable by `openvalut-cli list/get` or the credential server.
const String readAllowedField = 'openvalut.read-allowed'; // NON-NLS
const String readAllowedMark = '1'; // NON-NLS

KdbxKey readAllowedFieldKey() => KdbxKey(readAllowedField);

/// Whether [entry] is allowed to be listed/read by CLI and scripts.
bool isReadAllowed(KdbxEntry entry) {
  final value = entry.getString(readAllowedFieldKey())?.getText()?.trim();
  return value == readAllowedMark;
}

/// Sets/clears the read allow flag on [entry]. The change marks the entry
/// (and therefore the containing file) dirty; callers still need to save the
/// file for it to persist.
void setReadAllowed(KdbxEntry entry, bool allowed) {
  if (allowed) {
    entry.setString(readAllowedFieldKey(), PlainValue(readAllowedMark));
  } else {
    entry.removeString(readAllowedFieldKey());
  }
}

/// Whether a field key is internal OpenValut bookkeeping (never shown as a
/// normal user field).
bool isInternalReadAccessKey(KdbxKey key) =>
    key.key.startsWith(readAccessInternalPrefix);
