import 'dart:convert';
import 'dart:typed_data';

import 'package:openvalut/rust_core/rust_core.dart';

/// A KeePass vault opened through the Rust core.
///
/// This is a thin wrapper around the FFI handle. Callers must [close] the
/// vault when done, or use [open]/[createNew] inside a try/finally block.
class RustVault {
  RustVault._(this.handle);

  /// Opaque handle to the native vault.
  final int handle;

  /// Create a new empty vault.
  static RustVault createNew({required String name}) {
    return RustVault._(RustCore.vaultCreateNew(name: name));
  }

  /// Open a vault from encrypted [bytes] with [password].
  static RustVault open({required Uint8List bytes, required String password}) {
    return RustVault._(RustCore.vaultOpen(bytes: bytes, password: password));
  }

  /// Open a vault from encrypted [bytes] with a 32-byte [transformedKey].
  static RustVault openWithTransformedKey({
    required Uint8List bytes,
    required Uint8List transformedKey,
  }) {
    return RustVault._(
      RustCore.vaultOpenWithTransformedKey(
        bytes: bytes,
        transformedKey: transformedKey,
      ),
    );
  }

  /// Serialize the vault back to KDBX bytes using [password].
  Uint8List save({required String password}) {
    return RustCore.vaultSave(handle: handle, password: password);
  }

  /// List all entries in the vault.
  List<RustEntry> entries() {
    final json = RustCore.vaultEntries(handle: handle);
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => RustEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Read a single field value for an entry by UUID, or `null` if absent.
  String? entryValue({required String uuid, required String key}) {
    return RustCore.vaultEntryValue(handle: handle, uuid: uuid, key: key);
  }

  /// Create a new entry and return its UUID.
  String createEntry(RustEntry entry) {
    return RustCore.vaultCreateEntry(
      handle: handle,
      json: jsonEncode(entry.toCreateJson()),
    );
  }

  /// Update an existing entry by UUID.
  void updateEntry({required String uuid, required RustEntry entry}) {
    RustCore.vaultUpdateEntry(
      handle: handle,
      uuid: uuid,
      json: jsonEncode(entry.toUpdateJson()),
    );
  }

  /// Delete an entry by UUID.
  void deleteEntry(String uuid) {
    RustCore.vaultDeleteEntry(handle: handle, uuid: uuid);
  }

  /// Close the vault and free native resources.
  void close() {
    RustCore.vaultClose(handle);
  }
}

/// A vault entry as seen by the Rust core.
class RustEntry {
  const RustEntry({
    this.uuid = '',
    required this.title,
    required this.username,
    required this.password,
    required this.url,
    this.notes = '',
    this.group = '',
    this.otp,
    this.sshPrivateKey,
    this.machineId,
    this.custom = const [],
  });

  factory RustEntry.fromJson(Map<String, dynamic> json) {
    return RustEntry(
      uuid: json['uuid'] as String? ?? '',
      title: json['title'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      url: json['url'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      group: json['group'] as String? ?? '',
      custom: (json['custom'] as List<dynamic>? ?? [])
          .map((e) => RustCustomField.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String uuid;
  final String title;
  final String username;
  final String password;
  final String url;
  final String notes;
  final String group;
  final String? otp;
  final String? sshPrivateKey;
  final String? machineId;
  final List<RustCustomField> custom;

  Map<String, dynamic> toCreateJson() => {
    'title': title,
    'username': username,
    'password': password,
    'url': url,
    'notes': notes,
    if (group.isNotEmpty) 'group': group,
    if (otp != null) 'otp': otp,
    if (sshPrivateKey != null) 'ssh_private_key': sshPrivateKey,
    if (machineId != null) 'machine_id': machineId,
    'custom': custom.map((c) => c.toJson()).toList(),
  };

  Map<String, dynamic> toUpdateJson() => {
    'title': title,
    'username': username,
    'password': password,
    'url': url,
    'notes': notes,
    if (group.isNotEmpty) 'group': group,
    if (otp != null) 'otp': otp,
    if (sshPrivateKey != null) 'ssh_private_key': sshPrivateKey,
    if (machineId != null) 'machine_id': machineId,
    'custom': custom.map((c) => c.toJson()).toList(),
  };
}

class RustCustomField {
  const RustCustomField({required this.key, required this.value});

  factory RustCustomField.fromJson(Map<String, dynamic> json) {
    return RustCustomField(
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  final String key;
  final String value;

  Map<String, dynamic> toJson() => {'key': key, 'value': value};
}
