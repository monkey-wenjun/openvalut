import 'dart:convert';
import 'dart:typed_data';

import 'package:kdbx/kdbx.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';
import 'package:openvalut/openvalut_cloud/openvalut_client.dart';
import 'package:openvalut/openvalut_cloud/openvalut_cloud_session.dart';
import 'package:openvalut/openvalut_cloud/openvalut_crypto.dart';
import 'package:openvalut/openvalut_cloud/share_payload.dart';
import 'package:pointycastle/digests/sha256.dart';

final _logger = Logger('group_share_receiver');

/// One decrypted member entry of an incoming dynamic group share.
class ReceivedGroupShareEntry {
  ReceivedGroupShareEntry({
    required this.entryUuid,
    required this.fields,
  });

  final String entryUuid;
  final Map<String, String> fields;

  String? get label => fields['Title'];
  String? get username => fields['UserName'];
}

/// One decrypted incoming dynamic group share.
class ReceivedGroupShare {
  ReceivedGroupShare({
    required this.share,
    required this.name,
    required this.entries,
  });

  final openvalutGroupShare share;
  final String name;
  final List<ReceivedGroupShareEntry> entries;
}

class openvalutGroupShareReceiver {
  openvalutGroupShareReceiver._();

  static final openvalutGroupShareReceiver instance =
      openvalutGroupShareReceiver._();

  Future<openvalutClient?> _client() async {
    final session = openvalutCloudSession.instance;
    if (session.client == null) {
      return null;
    }
    await session.ensureShareIdentity();
    return session.client;
  }

  /// Loads and decrypts every incoming dynamic group share for the current
  /// account. Groups whose share key can no longer be unwrapped are skipped.
  Future<List<ReceivedGroupShare>> loadIncoming() async {
    final client = await _client();
    if (client == null) {
      return const [];
    }
    final session = openvalutCloudSession.instance;
    final identity = session.shareIdentity;
    if (identity == null) {
      return const [];
    }
    final headers = await client.listIncomingGroupShares();
    final out = <ReceivedGroupShare>[];
    for (final header in headers) {
      try {
        final detail = await client.getGroupShare(header.id);
        final shareKey = await openvalutCrypto.unwrapShareKey(
          privateKey: identity.privateKey,
          wrapped: base64.decode(detail.share.encryptedShareKey),
        );
        final name = _decryptText(
          shareKey,
          detail.share.nameNonce,
          detail.share.nameCiphertext,
        );
        final entries = <ReceivedGroupShareEntry>[];
        for (final row in detail.rows) {
          final fields = _decryptRow(shareKey, row);
          if (fields != null) {
            entries.add(
              ReceivedGroupShareEntry(
                entryUuid: row.entryUuid,
                fields: fields,
              ),
            );
          }
        }
        out.add(
          ReceivedGroupShare(
            share: detail.share,
            name: name,
            entries: entries,
          ),
        );
      } catch (e, stackTrace) {
        _logger.warning(
          'Unable to decrypt incoming group share ${header.id}',
          e,
          stackTrace,
        );
      }
    }
    return out;
  }

  /// Removes an incoming group share. Local mirrored copies are kept (the
  /// same way deleting an entry share keeps already-saved entries).
  Future<void> deleteIncomingGroupShare(String shareId) async {
    final client = await _client();
    if (client == null) {
      return;
    }
    await client.deleteGroupShare(shareId);
  }

  /// Mirrors every incoming group share into the given cloud [file]: creates
  /// a root group named after the share, keeps member entries in sync with
  /// the server rows (updates/changes/deletions), and saves once when
  /// something changed. Returns the number of groups mirrored.
  Future<int> syncToVault({
    required KdbxBloc kdbxBloc,
    required KdbxFile file,
    List<ReceivedGroupShare>? received,
  }) async {
    final resolved = received ?? await loadIncoming();
    if (resolved.isEmpty) {
      return 0;
    }
    var changed = false;
    for (final groupShare in resolved) {
      changed = _mirrorOne(file, groupShare) || changed;
    }
    if (changed) {
      await kdbxBloc.saveFile(file);
    }
    return resolved.length;
  }

  bool _mirrorOne(KdbxFile file, ReceivedGroupShare groupShare) {
    final shareId = groupShare.share.id;
    var group = file.body.rootGroup.groups
        .where((g) => g.name.get() == groupShare.name)
        .firstOrNull;
    group ??= file.createGroup(
      parent: file.body.rootGroup,
      name: groupShare.name,
    );
    final prefix = '$shareId:'; // NON-NLS
    final remote = <String, ReceivedGroupShareEntry>{
      for (final e in groupShare.entries) e.entryUuid: e,
    };
    var changed = false;
    final localBySource = <String, KdbxEntry>{};
    for (final entry in group.getAllEntries()) {
      final source = entry
          .getString(KdbxKey(GroupShareMetaFields.source))
          ?.getText();
      if (source != null && source.startsWith(prefix)) {
        localBySource[source.substring(prefix.length)] = entry;
      }
    }

    for (final remoteEntry in groupShare.entries) {
      final key = remoteEntry.entryUuid;
      final entry = localBySource[key];
      final fields = remoteEntry.fields;
      final hash = _fieldsHash(fields);
      if (entry == null) {
        final created = KdbxEntry.create(file, group);
        group.addEntry(created);
        applySharedFieldsToKdbx(created, fields);
        created.setString(
          KdbxKey(GroupShareMetaFields.source),
          PlainValue('$prefix$key'),
        );
        created.setString(
          KdbxKey(GroupShareMetaFields.hash),
          PlainValue(hash),
        );
        changed = true;
      } else {
        final oldHash = entry
            .getString(KdbxKey(GroupShareMetaFields.hash))
            ?.getText();
        if (oldHash != hash) {
          applySharedFieldsToKdbx(entry, fields);
          entry.setString(
            KdbxKey(GroupShareMetaFields.hash),
            PlainValue(hash),
          );
          changed = true;
        }
      }
    }

    for (final entry in localBySource.entries) {
      if (!remote.containsKey(entry.key)) {
        file.deletePermanently(entry.value);
        changed = true;
      }
    }
    return changed;
  }

  String _decryptText(Uint8List shareKey, String nonceB64, String ctB64) {
    final plain = openvalutCrypto.decrypt(
      shareKey,
      base64.decode(nonceB64),
      base64.decode(ctB64),
    );
    return utf8.decode(plain);
  }

  Map<String, String>? _decryptRow(
    Uint8List shareKey,
    openvalutGroupShareRow row,
  ) {
    try {
      final plain = openvalutCrypto.decrypt(
        shareKey,
        base64.decode(row.nonce),
        base64.decode(row.ciphertext),
      );
      final decoded = json.decode(utf8.decode(plain));
      if (decoded is! Map) {
        return null;
      }
      return decoded
          .map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    } catch (e, stackTrace) {
      _logger.warning(
        'Unable to decrypt group share row ${row.entryUuid}',
        e,
        stackTrace,
      );
      return null;
    }
  }

  String _fieldsHash(Map<String, String> fields) {
    final normalized = sharedPayloadHash(fields);
    final digest = SHA256Digest().process(
      Uint8List.fromList(utf8.encode(normalized)),
    );
    return [
      for (final b in digest) b.toRadixString(16).padLeft(2, '0'),
    ].join();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
