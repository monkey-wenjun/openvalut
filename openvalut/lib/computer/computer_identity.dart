import 'dart:io';

import 'package:kdbx/kdbx.dart';
import 'package:openvalut/ssh/machine_identity.dart';

/// Helpers for storing the current computer's credentials as a vault entry.
///
/// The entry lives in a dedicated "计算机" group and carries:
/// - title: hostname
/// - UserName: current OS user
/// - Password: the sudo/login password for this machine
/// - OTP: a TOTP secret for two-step verification
/// - machine-id: the unique machine identifier used for binding
///
/// On Linux this lets OpenValut validate a TOTP code before returning the
/// real password to agents/programs that need sudo access.
class ComputerIdentity {
  ComputerIdentity._();

  static const groupName = '计算机';
  static const machineIdKey = 'machine-id';

  static String get _currentUser =>
      Platform.environment['USER'] ??
      Platform.environment['USERNAME'] ??
      '';

  /// Returns the existing entry for this machine, or `null` if none exists.
  static KdbxEntry? findEntry(KdbxFile file) {
    final group = _findGroup(file);
    if (group == null) {
      return null;
    }
    final machineId = MachineIdentity.machineId;
    for (final entry in group.getAllEntries()) {
      if (entry.getString(KdbxKey(machineIdKey))?.getText() == machineId) {
        return entry;
      }
    }
    return null;
  }

  /// Finds the entry by matching hostname as a fallback.
  static KdbxEntry? findEntryByHostname(KdbxFile file, String hostname) {
    final group = _findGroup(file);
    if (group == null) {
      return null;
    }
    for (final entry in group.getAllEntries()) {
      if (entry.label == hostname) {
        return entry;
      }
    }
    return null;
  }

  /// Returns the dedicated "计算机" group, creating it when missing.
  static KdbxGroup ensureGroup(KdbxFile file) {
    final root = file.body.rootGroup;
    for (final group in root.groups) {
      if (group.name.get() == groupName) {
        return group;
      }
    }
    return file.createGroup(parent: root, name: groupName);
  }

  static KdbxGroup? _findGroup(KdbxFile file) {
    final root = file.body.rootGroup;
    for (final group in root.groups) {
      if (group.name.get() == groupName) {
        return group;
      }
    }
    return null;
  }

  /// Creates or updates the entry for the current machine.
  static KdbxEntry ensureEntry(KdbxFile file) {
    var entry = findEntry(file);
    entry ??= findEntryByHostname(file, MachineIdentity.hostname);
    if (entry == null) {
      final group = ensureGroup(file);
      entry = KdbxEntry.create(file, group);
      entry.label = MachineIdentity.hostname;
      entry.setString(KdbxKeyCommon.USER_NAME, PlainValue(_currentUser));
      entry.setString(KdbxKey(machineIdKey), PlainValue(MachineIdentity.machineId));
      group.addEntry(entry);
    }
    // Make sure the machine id is up to date.
    entry.setString(KdbxKey(machineIdKey), PlainValue(MachineIdentity.machineId));
    return entry;
  }

  /// Reads the stored username for this machine, if any.
  static String? getUsername(KdbxEntry entry) {
    return entry.getString(KdbxKeyCommon.USER_NAME)?.getText();
  }

  /// Reads the stored password for this machine, if any.
  static String? getPassword(KdbxEntry entry) {
    return entry.getString(KdbxKeyCommon.PASSWORD)?.getText();
  }

  /// Reads the stored TOTP secret/URI for this machine, if any.
  static String? getTotp(KdbxEntry entry) {
    return entry.getString(KdbxKeyCommon.OTP)?.getText();
  }

  /// Reads the machine id stored in the entry.
  static String? getMachineId(KdbxEntry entry) {
    return entry.getString(KdbxKey(machineIdKey))?.getText();
  }
}
