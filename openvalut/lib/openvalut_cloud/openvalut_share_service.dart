import 'dart:convert';
import 'dart:typed_data';

import 'package:kdbx/kdbx.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/bloc/kdbx/file_source_openvalut_cloud.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';
import 'package:openvalut/openvalut_cloud/openvalut_client.dart';
import 'package:openvalut/openvalut_cloud/openvalut_cloud_session.dart';
import 'package:openvalut/openvalut_cloud/openvalut_crypto.dart';
import 'package:openvalut/openvalut_cloud/share_payload.dart';
import 'package:openvalut/utils/app_locale.dart';

final _logger = Logger('openvalut_share_service');

class openvalutIncomingShare {
  openvalutIncomingShare({
    required this.share,
    required this.entry,
    required this.ownerUsername,
  });

  final openvalutShare share;
  final openvalutSharedEntry entry;
  final String ownerUsername;
}

class openvalutOutgoingShare {
  openvalutOutgoingShare({
    required this.share,
    required this.recipientUsername,
    required this.entryUuid,
    required this.createdAt,
    this.entryLabel,
  });

  final openvalutShare share;
  final String recipientUsername;
  final String entryUuid;
  final int createdAt;

  /// The entry title, resolved from the currently open cloud vaults. Null
  /// when the entry is no longer present (e.g. deleted or on another device).
  final String? entryLabel;
}

/// Orchestrates OpenValut Cloud sharing on top of the KDBX entries:
///  - the shared payload is the entry's plain string fields, encrypted with a
///    random 32-byte share key;
///  - the share key is wrapped to the recipient's X25519 public key;
///  - a copy of the entry is also upserted (encrypted with the vault key) so
///    the server can verify the sharer owns the entry.
class openvalutShareService {
  openvalutShareService._();

  static final openvalutShareService instance = openvalutShareService._();

  static openvalutSharedEntry sharedEntryFromKdbx(KdbxEntry entry) {
    return openvalutSharedEntry(fields: sharedFieldsFromKdbx(entry));
  }

  /// Applies shared fields onto [target] (used by "存入我的密码库").
  static void applySharedEntryToKdbx(
    KdbxEntry target,
    openvalutSharedEntry shared,
  ) {
    applySharedFieldsToKdbx(target, shared.fields);
  }

  static String entryUuidHex(KdbxEntry entry) {
    return kdbxEntryUuidHex(entry);
  }

  /// Shares [entry] (which must belong to an opened OpenValut Cloud vault)
  /// with [recipientUsername]. Throws [openvalutApiException] / [StateError]
  /// with user-presentable messages.
  Future<void> shareEntry({
    required KdbxEntry entry,
    required String recipientUsername,
    required KdbxBloc kdbxBloc,
  }) async {
    final session = openvalutCloudSession.instance;
    final client = session.currentClient;
    if (client == null) {
      throw StateError(
        AppLocale.isChinese
            ? '请先登录 OpenValut Cloud'
            : 'Sign in to OpenValut Cloud first',
      );
    }
    final opened = kdbxBloc.fileForKdbxFile(entry.file);
    final source = opened.fileSource;
    if (source is! FileSourceopenvalutCloud) {
      throw StateError(
        AppLocale.isChinese
            ? '仅 OpenValut Cloud 密码库中的条目支持分享'
            : 'Only entries in an OpenValut Cloud vault can be shared',
      );
    }
    final recipient = recipientUsername.trim().toLowerCase();
    if (recipient.isEmpty) {
      throw StateError(
        AppLocale.isChinese
            ? '请输入接收者的 OpenValut Cloud 用户名'
            : 'Enter the recipient\'s OpenValut Cloud username',
      );
    }
    if (recipient == (session.username ?? '').toLowerCase()) {
      throw StateError(
        AppLocale.isChinese ? '不能分享给自己' : 'You cannot share with yourself',
      );
    }

    final shared = sharedEntryFromKdbx(entry);
    if (shared.fields.isEmpty) {
      throw StateError(
        AppLocale.isChinese
            ? '该条目没有可分享的内容'
            : 'This entry has no content to share',
      );
    }

    // 1. Recipient public key (needed to wrap the share key).
    final recipientPublicKey = base64.decode(
      await client.getUserPublicKey(recipient),
    );

    // 2. Random share key + wrapped copy + entry copy under the vault key.
    final shareKey = openvalutCrypto.secureRandomBytes(
      openvalutCrypto.keyLength,
    );
    final wrapped = await openvalutCrypto.wrapShareKey(
      recipientPublicKey: recipientPublicKey,
      shareKey: shareKey,
    );
    final (shareNonce, shareCiphertext) = openvalutCrypto.encrypt(
      shareKey,
      shared.toBytes(),
    );

    final entryUuid = entryUuidHex(entry);
    final vaultKey = await source.ensureVaultKey();
    final (entryNonce, entryCiphertext) = openvalutCrypto.encrypt(
      vaultKey,
      shared.toBytes(),
    );
    await client.upsertEntry(
      vaultId: source.vaultId,
      uuid: entryUuid,
      group: '',
      nonce: base64.encode(entryNonce),
      ciphertext: base64.encode(entryCiphertext),
      baseUpdatedAt: 0, // fresh row for the share
    );

    // 3. Hand the wrapped share key + encrypted payload to the server.
    await client.createShare(
      vaultId: source.vaultId,
      entryUuid: entryUuid,
      recipientUsername: recipient,
      encryptedShareKey: base64.encode(wrapped),
      sharedNonce: base64.encode(shareNonce),
      sharedCiphertext: base64.encode(shareCiphertext),
    );
    _logger.info('Shared ${entry.label} with $recipient');
  }

  /// Loads and decrypts all incoming shares for the current account.
  /// Shares that cannot be decrypted (e.g. stale keys) are skipped.
  Future<List<openvalutIncomingShare>> loadIncomingShares() async {
    final session = openvalutCloudSession.instance;
    final client = session.currentClient;
    if (client == null) {
      return const [];
    }
    final identity = session.shareIdentity;
    if (identity == null) {
      await session.ensureShareIdentity();
    }
    final privateKey = session.shareIdentity!.privateKey;
    final shares = await client.listIncomingShares();
    final out = <openvalutIncomingShare>[];
    for (final share in shares) {
      try {
        final shareKey = await openvalutCrypto.unwrapShareKey(
          privateKey: privateKey,
          wrapped: Uint8List.fromList(base64.decode(share.encryptedShareKey)),
        );
        final plain = openvalutCrypto.decrypt(
          shareKey,
          Uint8List.fromList(base64.decode(share.sharedNonce)),
          Uint8List.fromList(base64.decode(share.sharedCiphertext)),
        );
        out.add(
          openvalutIncomingShare(
            share: share,
            entry: openvalutSharedEntry.fromBytes(plain),
            ownerUsername: share.ownerUsername,
          ),
        );
      } catch (e, stackTrace) {
        _logger.warning(
          'Unable to decrypt incoming share ${share.id} '
          'from ${share.ownerUsername}',
          e,
          stackTrace,
        );
      }
    }
    return out;
  }

  Future<void> deleteIncomingShare(String shareId) async {
    final client = openvalutCloudSession.instance.currentClient;
    if (client == null) {
      return;
    }
    await client.deleteShare(shareId);
  }

  /// Loads the shares this account created ("我的分享"), resolving the entry
  /// title from the open cloud vaults.
  Future<List<openvalutOutgoingShare>> loadOutgoingShares({
    required KdbxBloc kdbxBloc,
  }) async {
    final client = openvalutCloudSession.instance.currentClient;
    if (client == null) {
      return const [];
    }
    final labels = <String, String>{};
    for (final file in kdbxBloc.openedFilesKdbx) {
      for (final entry in file.body.rootGroup.getAllEntries()) {
        final label = entry.label;
        if (label != null && label.isNotEmpty) {
          labels[entryUuidHex(entry)] = label;
        }
      }
    }
    final shares = await client.listOutgoingShares();
    return shares
        .map(
          (share) => openvalutOutgoingShare(
            share: share,
            recipientUsername: share.recipientUsername,
            entryUuid: share.entryUuid,
            createdAt: share.createdAt,
            entryLabel: labels[share.entryUuid],
          ),
        )
        .toList();
  }

  Future<void> deleteOutgoingShare(String shareId) async {
    final client = openvalutCloudSession.instance.currentClient;
    if (client == null) {
      return;
    }
    await client.deleteShare(shareId);
  }
}
