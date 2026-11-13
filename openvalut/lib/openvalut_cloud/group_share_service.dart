import 'dart:convert';
import 'dart:typed_data';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:kdbx/kdbx.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/bloc/kdbx/file_source_openvalut_cloud.dart';
import 'package:openvalut/openvalut_cloud/openvalut_client.dart';
import 'package:openvalut/openvalut_cloud/openvalut_cloud_session.dart';
import 'package:openvalut/openvalut_cloud/openvalut_crypto.dart';
import 'package:openvalut/openvalut_cloud/share_payload.dart';
import 'package:pointycastle/digests/sha256.dart';

final _logger = Logger('group_share_service');

const _registryStorageName = 'openvalutGroupShares'; // NON-NLS

/// Stable error codes for the group-share flows. UI layers translate these
/// through the localized strings (never hardcode UI copy in this service).
abstract final class GroupShareErrorCodes {
  static const loginRequired = 'loginRequired'; // NON-NLS
  static const groupNotInVault = 'groupNotInVault'; // NON-NLS
  static const recipientRequired = 'recipientRequired'; // NON-NLS
  static const cannotShareSelf = 'cannotShareSelf'; // NON-NLS
  static const alreadyShared = 'alreadyShared'; // NON-NLS
}

class GroupShareException implements Exception {
  GroupShareException(this.code);

  final String code;

  @override
  String toString() => 'GroupShareException($code)';
}

/// Local record of one outgoing dynamic group share. The owner keeps the raw
/// share key and a per-entry content hash so later saves can push only the
/// entries that actually changed into the live group share.
class _OutgoingGroupShare {
  _OutgoingGroupShare({
    required this.shareId,
    required this.vaultId,
    required this.groupPath,
    required this.recipientUsername,
    required this.shareKey,
    required this.entryHashes,
  });

  factory _OutgoingGroupShare.fromJson(Map<String, dynamic> json) =>
      _OutgoingGroupShare(
        shareId: json['shareId'] as String,
        vaultId: json['vaultId'] as String,
        groupPath: json['groupPath'] as String? ?? '',
        recipientUsername: json['recipientUsername'] as String? ?? '',
        shareKey: base64.decode(json['shareKey'] as String),
        entryHashes: (json['entryHashes'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as String)),
      );

  final String shareId;
  final String vaultId;
  final String groupPath;
  final String recipientUsername;
  final Uint8List shareKey;
  Map<String, String> entryHashes;

  Map<String, dynamic> toJson() => {
    'shareId': shareId,
    'vaultId': vaultId,
    'groupPath': groupPath,
    'recipientUsername': recipientUsername,
    'shareKey': base64.encode(shareKey),
    'entryHashes': entryHashes,
  };
}

/// One outgoing group share for display in "shared by me".
class OutgoingGroupShareSummary {
  OutgoingGroupShareSummary({
    required this.share,
    required this.name,
    required this.entryCount,
  });

  final openvalutGroupShare share;
  final String? name;
  final int? entryCount;
}

class openvalutGroupShareService {
  openvalutGroupShareService._();

  static final openvalutGroupShareService instance =
      openvalutGroupShareService._();

  Future<BiometricStorageFile> _registryStorage() =>
      BiometricStorage().getStorage(
        _registryStorageName,
        options: StorageFileInitOptions(authenticationRequired: false),
      );

  /// Outgoing group share summary for the "shared by me" list. [name] is the
  /// decrypted group path when the local registry still holds the share key;
  /// it is null after the registry was cleared (e.g. app data reset) and the
  /// UI falls back to a localized generic label.
  Future<List<OutgoingGroupShareSummary>> loadOutgoing() async {
    final client = openvalutCloudSession.instance.client;
    if (client == null) {
      return const [];
    }
    final headers = await client.listOutgoingGroupShares();
    final registry = await _loadOutgoing();
    final byId = {for (final s in registry) s.shareId: s};
    final out = <OutgoingGroupShareSummary>[];
    for (final header in headers) {
      String? name;
      final local = byId[header.id];
      if (local != null) {
        try {
          final plain = openvalutCrypto.decrypt(
            local.shareKey,
            base64.decode(header.nameNonce),
            base64.decode(header.nameCiphertext),
          );
          name = utf8.decode(plain);
        } catch (_) {
          name = null;
        }
      }
      out.add(
        OutgoingGroupShareSummary(
          share: header,
          name: name,
          entryCount: local?.entryHashes.length,
        ),
      );
    }
    return out;
  }

  Future<List<_OutgoingGroupShare>> _loadOutgoing() async {
    try {
      final raw = await (await _registryStorage()).read();
      if (raw == null || raw.isEmpty) {
        return [];
      }
      final data = json.decode(raw) as Map<String, dynamic>;
      final list = data['shares'] as List<dynamic>? ?? const [];
      return list
          .map(
            (e) => _OutgoingGroupShare.fromJson(
              (e as Map<dynamic, dynamic>).cast<String, dynamic>(),
            ),
          )
          .toList();
    } catch (e, stackTrace) {
      _logger.warning('Unable to load outgoing group shares.', e, stackTrace);
      return [];
    }
  }

  Future<void> _saveOutgoing(List<_OutgoingGroupShare> shares) async {
    try {
      final json = jsonEncode({
        'shares': shares.map((s) => s.toJson()).toList(),
      });
      await (await _registryStorage()).write(json);
    } catch (e, stackTrace) {
      // A failing keyring must not make the caller think the share failed:
      // the next save re-syncs from the server state if the write is retried.
      _logger.warning('Unable to persist outgoing group shares.', e, stackTrace);
    }
  }

  /// Shares [group] as a live group share with [recipientUsername]. Every
  /// current member entry and the display name are encrypted under a fresh
  /// random share key; the key is wrapped to the recipient. Later saves of
  /// the vault keep the share up to date automatically.
  Future<String> createGroupShare({
    required KdbxFile file,
    required FileSourceopenvalutCloud source,
    required KdbxGroup group,
    required String recipientUsername,
  }) async {
    if (group.file != file) {
      throw GroupShareException(GroupShareErrorCodes.groupNotInVault);
    }
    final session = openvalutCloudSession.instance;
    final client = session.client;
    if (client == null) {
      throw GroupShareException(GroupShareErrorCodes.loginRequired);
    }
    final recipient = recipientUsername.trim().toLowerCase();
    if (recipient.isEmpty) {
      throw GroupShareException(GroupShareErrorCodes.recipientRequired);
    }
    if (recipient == (session.username ?? '').toLowerCase()) {
      throw GroupShareException(GroupShareErrorCodes.cannotShareSelf);
    }

    final groupPath = _groupPathOf(group);
    final existing = await _loadOutgoing();
    if (existing.any(
      (s) =>
          s.vaultId == source.vaultId &&
          s.groupPath == groupPath &&
          s.recipientUsername == recipient,
    )) {
      throw GroupShareException(GroupShareErrorCodes.alreadyShared);
    }
    final entries = group
        .getAllEntries()
        .where((entry) => !entry.isInRecycleBin())
        .toList();

    final recipientPublicKey = base64.decode(
      await client.getUserPublicKey(recipient),
    );
    final shareKey = openvalutCrypto.secureRandomBytes(
      openvalutCrypto.keyLength,
    );
    final wrapped = await openvalutCrypto.wrapShareKey(
      recipientPublicKey: recipientPublicKey,
      shareKey: shareKey,
    );

    final (nameNonce, nameCiphertext) = openvalutCrypto.encrypt(
      shareKey,
      Uint8List.fromList(utf8.encode(groupPath)),
    );
    final rows = <Map<String, String>>[];
    final hashes = <String, String>{};
    for (final entry in entries) {
      final fields = sharedFieldsFromKdbx(entry);
      final row = _encryptRow(shareKey, kdbxEntryUuidHex(entry), fields);
      rows.add(row);
      hashes[kdbxEntryUuidHex(entry)] = _hashHex(fields);
    }

    final shareId = await client.createGroupShare(
      vaultId: source.vaultId,
      recipientUsername: recipient,
      encryptedShareKey: base64.encode(wrapped),
      nameNonce: base64.encode(nameNonce),
      nameCiphertext: base64.encode(nameCiphertext),
      entries: rows,
    );

    final outgoing = _OutgoingGroupShare(
      shareId: shareId,
      vaultId: source.vaultId,
      groupPath: groupPath,
      recipientUsername: recipient,
      shareKey: shareKey,
      entryHashes: hashes,
    );
    existing.add(outgoing);
    await _saveOutgoing(existing);
    return shareId;
  }

  /// Pushes member-row changes of every active outgoing group share in this
  /// vault. Called after a successful vault save. Failures are logged and
  /// swallowed so the vault save itself never depends on the share service;
  /// the local registry is only advanced when the server accepted the rows.
  Future<void> syncOutgoingAfterSave({
    required KdbxFile file,
    required FileSourceopenvalutCloud source,
  }) async {
    final client = openvalutCloudSession.instance.client;
    if (client == null) {
      return;
    }
    final shares = await _loadOutgoing();
    final mine = shares.where((s) => s.vaultId == source.vaultId).toList();
    if (mine.isEmpty) {
      return;
    }

    final currentEntries = <String, KdbxEntry>{};
    final currentPaths = <String, String>{};
    for (final entry in file.body.rootGroup.getAllEntries()) {
      if (entry.isInRecycleBin()) {
        continue;
      }
      final uuid = kdbxEntryUuidHex(entry);
      currentEntries[uuid] = entry;
      currentPaths[uuid] = _groupPathOf(entry.parent!);
    }

    var changed = false;
    for (final share in mine) {
      final upserts = <Map<String, String>>[];
      final removes = <String>[];
      final nextHashes = <String, String>{};
      final previous = share.entryHashes;
      final memberUuids = currentPaths.entries
          .where((e) => e.value == share.groupPath)
          .map((e) => e.key)
          .toSet();
      final allUuids = <String>{...previous.keys, ...memberUuids};
      for (final uuid in allUuids) {
        final entry = currentEntries[uuid];
        if (entry == null) {
          removes.add(uuid);
          continue;
        }
        final fields = sharedFieldsFromKdbx(entry);
        final hash = _hashHex(fields);
        final oldHash = previous[uuid];
        if (oldHash == null || oldHash != hash) {
          upserts.add(_encryptRow(share.shareKey, uuid, fields));
        }
        nextHashes[uuid] = hash;
      }
      if (upserts.isNotEmpty) {
        await client.upsertGroupShareRows(share.shareId, upserts);
      }
      for (final uuid in removes) {
        await client.removeGroupShareRow(share.shareId, uuid);
      }
      if (upserts.isNotEmpty || removes.isNotEmpty) {
        share.entryHashes = nextHashes;
        changed = true;
      }
    }
    if (changed) {
      await _saveOutgoing(shares);
    }
  }

  /// Removes one outgoing group share from the server and local registry.
  Future<void> revokeGroupShare(String shareId) async {
    final client = openvalutCloudSession.instance.client;
    if (client != null) {
      await client.deleteGroupShare(shareId);
    }
    final shares = await _loadOutgoing();
    shares.removeWhere((s) => s.shareId == shareId);
    await _saveOutgoing(shares);
  }

  String _groupPathOf(KdbxGroup group) {
    final parts = <String>[];
    KdbxGroup? current = group;
    while (current != null && current.parent != null) {
      final name = current.name.get();
      if (name != null && name.isNotEmpty) {
        parts.insert(0, name);
      }
      current = current.parent;
    }
    return parts.join('/');
  }

  String _hashHex(Map<String, String> fields) {
    final normalized = sharedPayloadHash(fields);
    final digest = SHA256Digest().process(
      Uint8List.fromList(utf8.encode(normalized)),
    );
    return [
      for (final b in digest) b.toRadixString(16).padLeft(2, '0'),
    ].join();
  }
}

Map<String, String> _encryptRow(
  Uint8List shareKey,
  String entryUuid,
  Map<String, String> fields,
) {
  final plain = Uint8List.fromList(utf8.encode(jsonEncode(fields)));
  final (nonce, ciphertext) = openvalutCrypto.encrypt(shareKey, plain);
  return {
    'entryUuid': entryUuid,
    'nonce': base64.encode(nonce),
    'ciphertext': base64.encode(ciphertext),
  };
}
