import 'package:kdbx/kdbx.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:string_literal_finder_annotations/string_literal_finder_annotations.dart';

/// Stable, locale-independent names of built-in vault groups.
///
/// Built-in groups used by features (SSH keys, computer entries, categories)
/// must not store a localized display name in the vault: changing the UI
/// language would otherwise create duplicate groups ("SSH Keys" vs
/// "SSH 密钥"). Features refer to these canonical storage names; the UI
/// localizes the display through [builtInGroupDisplayName].
@NonNls
class BuiltInGroupNames {
  static const sshKeys = 'SSH Keys'; // NON-NLS canonical storage name

  /// Historical storage name written by older builds that localized the
  /// group name on creation. Kept only to identify/merge legacy duplicates.
  @NonNls
  static const sshKeysLegacyZh = 'SSH 密钥'; // NON-NLS historical value
}

/// Whether [storedName] is one of the storage names used for the SSH key
/// group (canonical or historical legacy).
bool isSshKeysGroupStoredName(String? storedName) =>
    storedName == BuiltInGroupNames.sshKeys ||
    storedName == BuiltInGroupNames.sshKeysLegacyZh;

/// Whether [group] is the built-in SSH key group (by stored name).
bool isSshKeysGroup(KdbxGroup group) =>
    isSshKeysGroupStoredName(group.name.get());

/// Display name of [group] for the current UI language. Built-in groups keep
/// a canonical storage name, so their user-facing label follows the active
/// locale instead of the stored value.
String? builtInGroupDisplayName(KdbxGroup group, AppLocalizations loc) {
  if (isSshKeysGroup(group)) {
    return loc.sshKeysGroupName;
  }
  return group.name.get();
}
