import 'dart:convert';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:kdbx/kdbx.dart';
// forceSetUuid lives in an internal extension that kdbx.dart does not re-export.
import 'package:kdbx/src/kdbx_object.dart' show KdbxObjectInternal;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:openvalut/bloc/kdbx/file_content.dart';
import 'package:openvalut/bloc/kdbx/file_source.dart';
import 'package:openvalut/env/_base.dart';
import 'package:openvalut/openvalut_cloud/openvalut_client.dart';
import 'package:openvalut/openvalut_cloud/openvalut_crypto.dart';
import 'package:openvalut/openvalut_cloud/row_entry_codec.dart';
import 'package:openvalut/utils/path_utils.dart' show PathUtils;
import 'package:string_literal_finder_annotations/string_literal_finder_annotations.dart';

final _logger = Logger('file_source_openvalut_cloud');

/// A password database stored as encrypted per-entry rows on the OpenValut
/// Cloud server (each row is one entry encrypted with the vault key).
///
/// Rows give granular, per-entry sync and conflict handling. The whole-file
/// blob is still used as the fallback path and for the one-time migration:
/// the first save after switching writes every entry as a row, and if the
/// row path ever fails (missing credentials, server hiccup) the blob write is
/// used instead so the vault is never lost.
class FileSourceopenvalutCloud extends FileSource {
  FileSourceopenvalutCloud({
    required this.client,
    required this.vaultId,
    required this.vaultName,
    super.databaseName,
    required super.uuid,
    this.masterPassword,
    this.rememberedVaultKey,
    this.credentials,
    super.initialCachedContent,
  });

  final openvalutClient client;
  final String vaultId;
  final String vaultName;

  /// Set by the unlock screen right before [KdbxBloc.openFile] so [load]
  /// can decrypt the blob. Never persisted.
  String? masterPassword;

  /// The credentials the app actually opened the KDBX with (master password
  /// when typed, or the remembered hash on quick unlock). Lets the row-level
  /// sync re-parse and reconstruct the KDBX in both sessions.
  Credentials? credentials;

  /// The 32-byte vault key recovered from the remembered/quick unlock store,
  /// so the blob can be decrypted without asking for the master password
  /// again in the same boot session (or behind the biometric gate).
  Uint8List? rememberedVaultKey;

  Uint8List? _vaultKey;
  Future<Uint8List>? _vaultKeyFuture;

  /// The server `updatedAt` of the last blob this source loaded. Used by the
  /// auto-sync to detect changes without replacing the open file on every
  /// poll.
  int? lastSyncedUpdatedAt;

  /// Last-synced row state, keyed by entry UUID. Drives the row diff-sync.
  Map<String, openvalutEntryRow> _lastSyncedRows = {};
  Map<String, Map<String, dynamic>> _lastSyncedPayloads = {};

  /// Persistent local cache: the reconstructed (encrypted) KDBX bytes plus
  /// the raw row metadata, so cold starts skip the 576-row network fetch and
  /// rebuild when the vault hasn't changed server-side.
  Future<Directory> _vaultCacheDir() async {
    final cache = await PathUtils().getCacheDirectory();
    return cache.childDirectory('vault');
  }

  /// Validates a cached cloud vault against [creds] and, when valid, restores
  /// the last row state so the next save can still diff instead of uploading
  /// every entry as new. Returns null when the cache is stale/poisoned.
  Future<FileContent?> _cachedFileContentIfUsable({
    required ({
      int updatedAt,
      Uint8List bytes,
      List<openvalutEntryRow> rows,
    }) cached,
    required Credentials creds,
  }) async {
    try {
      await _read(cached.bytes, creds);
    } catch (e, stackTrace) {
      _logger.warning(
        'Cloud vault $vaultId cache does not open with the current '
        'credentials.',
        e,
        stackTrace,
      );
      return null;
    }
    _lastSyncedRows = {for (final r in cached.rows) r.uuid: r};
    final decoded = await Future.wait(
      cached.rows.map((r) async {
        try {
          return MapEntry(r.uuid, await _decodeRowPayload(r));
        } catch (_) {
          return MapEntry<String, Map<String, dynamic>>(r.uuid, const {});
        }
      }),
    );
    _lastSyncedPayloads = {for (final e in decoded) e.key: e.value};
    _logger.finer(
      'vault $vaultId loaded from local cache '
      '(${cached.rows.length} rows, updatedAt ${cached.updatedAt})',
    );
    return FileContent(
      cached.bytes,
      <String, dynamic>{'vaultId': vaultId, 'rowSync': true},
    );
  }

  Future<({int updatedAt, Uint8List bytes, List<openvalutEntryRow> rows})?>
  _readVaultCache() async {
    try {
      final dir = await _vaultCacheDir();
      final metaFile = dir.childFile('$vaultId.meta');
      final bytesFile = dir.childFile('$vaultId.kdbx');
      if (!await metaFile.exists() || !await bytesFile.exists()) {
        return null;
      }
      final meta = jsonDecode(await metaFile.readAsString());
      final rows = (meta['rows'] as List<dynamic>? ?? const [])
          .map((r) => openvalutEntryRow.fromJson(r as Map<dynamic, dynamic>))
          .toList();
      return (
        updatedAt: meta['updatedAt'] as int? ?? 0,
        bytes: Uint8List.fromList(await bytesFile.readAsBytes()),
        rows: rows,
      );
    } catch (e, st) {
      _logger.warning('vault cache read failed for $vaultId', e, st);
      return null;
    }
  }

  Future<void> _writeVaultCache(
    Uint8List bytes,
    int updatedAt,
    List<openvalutEntryRow> rows,
  ) async {
    try {
      final dir = await _vaultCacheDir();
      await dir.create(recursive: true);
      await dir
          .childFile('$vaultId.meta')
          .writeAsString(
            jsonEncode({
              'updatedAt': updatedAt,
              'rows': rows.map((r) => r.toJson()).toList(),
            }),
          );
      await dir.childFile('$vaultId.kdbx').writeAsBytes(bytes);
    } catch (e, st) {
      _logger.warning('vault cache write failed for $vaultId', e, st);
    }
  }

  /// Lightweight check (meta endpoint, no blob download) whether the server
  /// has a newer version than the one we last loaded.
  Future<bool> hasServerUpdate() async {
    final meta = await client.getVaultMeta(vaultId);
    final updatedAt = meta.updatedAt;
    if (updatedAt == null) {
      return false;
    }
    return updatedAt != lastSyncedUpdatedAt;
  }

  /// Derives (and caches) the vault key. Overridable for tests.
  @protected
  Future<Uint8List> vaultKey() async {
    final cached = _vaultKey;
    if (cached != null) {
      return cached;
    }
    // Serialize concurrent callers: the row sync launches many decryptions in
    // parallel, and deriving Argon2 once per caller would stall the machine.
    return _vaultKeyFuture ??= _deriveVaultKey();
  }

  Future<Uint8List> _deriveVaultKey() async {
    try {
      // The password the user just entered always wins over a remembered
      // key. The remembered value can be stale (another device changed the
      // master password) and preferring it would make a correct unlock fail
      // with "wrong password" forever.
      final password = masterPassword;
      if (password != null && password.isNotEmpty) {
        final key = await openvalutCrypto.deriveKey(
          password,
          Uint8List.fromList(utf8.encode(vaultId)),
        );
        _vaultKey = key;
        return key;
      }
      final remembered = rememberedVaultKey;
      if (remembered != null &&
          remembered.length == openvalutCrypto.keyLength) {
        _vaultKey = remembered;
        return remembered;
      }
      throw StateError(
        'OpenValut Cloud vault $vaultId requires the master password.',
      );
    } finally {
      _vaultKeyFuture = null;
    }
  }

  /// Public accessor for the (cached) vault key, used by the share service.
  Future<Uint8List> ensureVaultKey() => vaultKey();

  /// Drops the cached vault key (e.g. after the master password changed) so
  /// the next [write]/[load] derives the key from the new password.
  void invalidateVaultKeyCache() {
    _vaultKey = null;
    _vaultKeyFuture = null;
    rememberedVaultKey = null;
  }

  @NonNls
  @override
  String get typeDebug => 'FileSourceopenvalutCloud';

  @override
  String get displayNameFromPath => vaultName;

  @override
  String get displayPath => '${Env.OpenValutCloud} / $vaultName';

  @override
  FileSourceIcon get displayIcon => FileSourceIcon.openvalut;

  @override
  bool get supportsWrite => true;

  @override
  Stream<FileContent> load() async* {
    int? serverUpdatedAt;
    FileContent? cacheContent;
    try {
      final meta = await client.getVaultMeta(vaultId);
      serverUpdatedAt = meta.updatedAt;
      lastSyncedUpdatedAt = serverUpdatedAt;
    } catch (e, stackTrace) {
      // A DNS/network blip must not masquerade as a wrong master password.
      // When a previously saved copy exists and the entered credentials open
      // it, serve the local cache; the auto-sync will reconnect later.
      _logger.warning(
        'Cloud vault $vaultId meta fetch failed; trying local cache.',
        e,
        stackTrace,
      );
      final cached = await _readVaultCache();
      final creds = _kdbxCredentials();
      if (cached != null && creds != null) {
        cacheContent = await _cachedFileContentIfUsable(
          cached: cached,
          creds: creds,
        );
      }
      if (cacheContent == null) {
        rethrow;
      }
    }
    if (cacheContent != null) {
      yield cacheContent;
      return;
    }

    // Persistent-cache fast path: if the server hasn't changed since we last
    // reconstructed the vault, skip the per-row network fetch and rebuild.
    var cached = await _readVaultCache();
    if (cached != null &&
        serverUpdatedAt != null &&
        cached.updatedAt == serverUpdatedAt) {
      final creds = _kdbxCredentials();
      if (creds != null) {
        final content = await _cachedFileContentIfUsable(
          cached: cached,
          creds: creds,
        );
        if (content != null) {
          yield content;
          return;
        }
        cached = null;
      }
    }

    // The row store is the single source of truth: fetch every entry as a
    // row, then rebuild the KDBX from them.
    List<openvalutEntryRow> rows;
    try {
      rows = await client.listEntries(vaultId);
    } catch (e) {
      _logger.warning('listEntries failed: $e');
      rows = const [];
    }
    _lastSyncedRows = {for (final r in rows) r.uuid: r};
    // Decrypt all row payloads in parallel: each row is independent and a
    // sequential await-per-row kept large vaults blocked on the UI thread.
    var decoded = await Future.wait(
      rows.map((r) async {
        try {
          return MapEntry(r.uuid, await _decodeRowPayload(r));
        } catch (_) {
          // Leave undecoded; the next save will simply re-upload the row.
          return MapEntry<String, Map<String, dynamic>>(r.uuid, const {});
        }
      }),
    );
    var decodedByUuid = {for (final e in decoded) e.key: e.value};
    _lastSyncedPayloads = Map<String, Map<String, dynamic>>.from(
      decodedByUuid,
    );

    if (rows.isEmpty) {
      // No rows yet: this vault predates the row store. Migrate in place by
      // loading the legacy blob once; the first save after this writes every
      // entry as a row and the blob is never consulted again.
      _logger.finer('loading legacy blob for vault $vaultId (0 rows)');
      final vault = await client.getVault(vaultId);
      final key = await vaultKey();
      final nonce = Uint8List.fromList(base64.decode(vault.nonce));
      final ciphertext = Uint8List.fromList(base64.decode(vault.ciphertext));
      final plain = openvalutCrypto.decrypt(key, nonce, ciphertext);
      lastSyncedUpdatedAt = vault.updatedAt;
      yield FileContent(
        plain,
        <String, dynamic>{
          'vaultId': vaultId,
          'updatedAt': vault.updatedAt,
        },
      );
      return;
    }

    // A failed row means the typed master password cannot decrypt the row
    // store. Older clients (macOS) still write the whole-file blob encrypted
    // with the same master password; when that blob opens, repair the rows in
    // place by re-encrypting them under the current vault key.
    final failedRows = rows
        .where((r) => (decodedByUuid[r.uuid]?.isEmpty ?? true))
        .length;
    if (failedRows > 0) {
      _logger.warning(
        'Cloud vault $vaultId has $failedRows row(s) that do not decrypt '
        'with the current vault key; attempting legacy-blob repair.',
      );
      final repaired = await _repairRowsFromBlob();
      if (repaired) {
        rows = _lastSyncedRows.values.toList();
        decoded = await Future.wait(
          rows.map((r) async {
            try {
              return MapEntry(r.uuid, await _decodeRowPayload(r));
            } catch (_) {
              return MapEntry<String, Map<String, dynamic>>(r.uuid, const {});
            }
          }),
        );
        decodedByUuid = {for (final e in decoded) e.key: e.value};
        _lastSyncedPayloads = Map<String, Map<String, dynamic>>.from(
          decodedByUuid,
        );
        _logger.info(
          'Cloud vault $vaultId rows repaired from the legacy blob '
          '(${rows.length} rows).',
        );
      }
    }

    // The row store does not decrypt with the current key and the blob could
    // not repair it. That is either a wrong master password or a server state
    // written by another key. Before failing the unlock outright, fall back
    // to the last good local copy: it is only served when the entered
    // credentials actually open it, so a genuinely wrong password still
    // fails.
    FileContent? content;
    try {
      final file = await _reconstructFromRows(rows);
      final bytes = await file.saveTo((b) async => b);
      await _writeVaultCache(bytes, serverUpdatedAt ?? 0, rows);
      _logger.finer('loaded cloud vault $vaultId from ${rows.length} rows');
      content = FileContent(
        bytes,
        <String, dynamic>{'vaultId': vaultId, 'rowSync': true},
      );
    } on openvalutDecryptionException {
      content = await _rescueFromLocalCache();
      if (content == null) {
        rethrow;
      }
    } on KdbxInvalidKeyException {
      content = await _rescueFromLocalCache();
      if (content == null) {
        rethrow;
      }
    }
    yield content;
  }

  /// Last-resort recovery for a server state that cannot be decrypted with
  /// the current key: serve the previously saved local copy when the entered
  /// credentials open it. The next save re-uploads every entry under the
  /// current key, which repairs the server state.
  Future<FileContent?> _rescueFromLocalCache() async {
    final cached = await _readVaultCache();
    final creds = _kdbxCredentials();
    if (cached == null || creds == null) {
      return null;
    }
    final content = await _cachedFileContentIfUsable(
      cached: cached,
      creds: creds,
    );
    if (content == null) {
      return null;
    }
    _logger.warning(
      'Cloud vault $vaultId: the server state does not decrypt with the '
      'current key, but the local copy from updatedAt ${cached.updatedAt} '
      '(${cached.rows.length} rows) does. Serving the local copy; the next '
      'save rewrites the server state under the current key.',
    );
    return content;
  }

  /// Tries to open the legacy whole-file blob with the current vault key and
  /// re-encrypt every server row from it. Returns true when the blob was
  /// valid and the row sync succeeded.
  Future<bool> _repairRowsFromBlob() async {
    try {
      final vault = await client.getVault(vaultId);
      final key = await vaultKey();
      final nonce = Uint8List.fromList(base64.decode(vault.nonce));
      final ciphertext = Uint8List.fromList(base64.decode(vault.ciphertext));
      final plain = openvalutCrypto.decrypt(key, nonce, ciphertext);
      final creds = _kdbxCredentials();
      if (creds == null) {
        _logger.warning(
          'Cannot repair cloud vault $vaultId: no credentials available.',
        );
        return false;
      }
      final file = await _read(plain, creds);
      await _syncRows(file);
      final meta = await client.getVaultMeta(vaultId);
      await _writeVaultCache(
        plain,
        meta.updatedAt ?? vault.updatedAt ?? 0,
        _lastSyncedRows.values.toList(),
      );
      return true;
    } catch (e, stackTrace) {
      _logger.warning(
        'Cloud vault $vaultId row repair from legacy blob failed '
        '(the master password may be wrong for the blob too).',
        e,
        stackTrace,
      );
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> write(
    Uint8List bytes,
    Map<String, dynamic>? previousMetadata,
  ) async {
    // The row-level store is the single source of truth. Every save diffs the
    // entries in [bytes] against the last-synced rows and upserts/deletes the
    // changed ones; per-row optimistic locking on the server resolves
    // concurrent writers.
    final credentials = _kdbxCredentials();
    if (credentials == null) {
      throw StateError(
        'OpenValut Cloud vault $vaultId requires the master password to sync.',
      );
    }
    final file = await _read(bytes, credentials);
    await _syncRows(file);

    // Refresh the change-detection timestamp so the auto-sync can tell the
    // server state apart from what we just wrote.
    final meta = await client.getVaultMeta(vaultId);
    lastSyncedUpdatedAt = meta.updatedAt;
    return <String, dynamic>{
      'vaultId': vaultId,
      'updatedAt': meta.updatedAt,
    };
  }

  /// Re-encrypts the entire server-side state under the current vault key
  /// after a master password change: every row (payload and group path) and
  /// the whole-file blob. The regular save diff is plaintext-based and would
  /// skip every unchanged row, leaving rows (and the blob) on the server that
  /// the old password can still decrypt — this method exists to close that
  /// hole. [masterPassword] must already be the new password.
  ///
  /// Rows that conflict on the server (another device wrote them
  /// concurrently) abort the rotation with a [StateError] instead of leaving
  /// a silently half-rotated vault behind.
  Future<void> rotateVaultKey(KdbxFile file) async {
    final key = await vaultKey();
    final currentEntries = _indexEntries(file);
    final upserts = <Map<String, Object?>>[];
    final newSyncedRows = <String, openvalutEntryRow>{};
    final newSyncedPayloads = <String, Map<String, dynamic>>{};

    for (final entry in currentEntries.values) {
      final uuid = _entryUuidHex(entry);
      final payload = encodeEntryRow(entry);
      final groupPath = _entryGroupPath(entry);
      final group = await _encryptGroup(groupPath);
      final (nonce, ct) = openvalutCrypto.encrypt(
        key,
        Uint8List.fromList(utf8.encode(jsonEncode(payload))),
      );
      upserts.add(<String, Object?>{
        'uuid': uuid,
        'group': group,
        'nonce': base64.encode(nonce),
        'ciphertext': base64.encode(ct),
        'baseUpdatedAt': _lastSyncedRows[uuid]?.updatedAt ?? 0,
      });
      newSyncedPayloads[uuid] = payload;
    }

    if (upserts.isNotEmpty) {
      final result = await client.syncEntries(
        vaultId: vaultId,
        upserts: upserts,
        deletes: const <String>[],
      );
      if (result.conflicts.isNotEmpty) {
        throw StateError(
          'Vault key rotation: ${result.conflicts.length} row(s) '
          'conflicted on the server. Another device may have written '
          'concurrently; re-run the password change to retry.',
        );
      }
      for (final u in upserts) {
        final uuid = u['uuid']! as String;
        newSyncedRows[uuid] = openvalutEntryRow(
          uuid: uuid,
          group: u['group']! as String,
          nonce: u['nonce']! as String,
          ciphertext: u['ciphertext']! as String,
          updatedAt: result.updatedAt[uuid] ?? 0,
        );
      }
    }
    _lastSyncedRows = newSyncedRows;
    _lastSyncedPayloads = newSyncedPayloads;

    // No server-side copy may stay decryptable with the old password: upload
    // the whole-file blob re-encrypted with the new key as well.
    final bytes = await file.saveTo((b) async => b);
    await _uploadBlobWithRetry(key, bytes);

    final meta = await client.getVaultMeta(vaultId);
    lastSyncedUpdatedAt = meta.updatedAt;
  }

  /// Uploads the blob encrypted with [key], transparently re-basing onto the
  /// current server version when the optimistic-lock check rejects the write
  /// with a 409.
  Future<void> _uploadBlobWithRetry(Uint8List key, Uint8List bytes) async {
    final (nonce, ct) = openvalutCrypto.encrypt(key, bytes);
    var base = lastSyncedUpdatedAt ?? 0;
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        lastSyncedUpdatedAt = await client.updateVaultBlob(
          vaultId: vaultId,
          nonce: base64.encode(nonce),
          ciphertext: base64.encode(ct),
          baseUpdatedAt: base,
        );
        return;
      } on openvalutApiException catch (e) {
        if (e.statusCode != 409) {
          rethrow;
        }
        final meta = await client.getVaultMeta(vaultId);
        base = meta.updatedAt ?? base;
      }
    }
    throw StateError(
      'Vault key rotation: blob upload kept conflicting with the server '
      'version. Try the password change again in a moment.',
    );
  }

  // -------------------------------------------------------------------------
  // Row-level sync engine
  // -------------------------------------------------------------------------

  Credentials? _kdbxCredentials() {
    final pw = masterPassword;
    if (pw != null && pw.isNotEmpty) {
      return Credentials(ProtectedValue.fromString(pw));
    }
    return credentials;
  }

  Future<KdbxFile> _read(Uint8List bytes, Credentials credentials) async {
    final format = KdbxFormat();
    return format.read(bytes, credentials);
  }

  /// Walks every entry (including the recycle bin) with its UUID and payload.
  Map<String, KdbxEntry> _indexEntries(KdbxFile file) {
    final out = <String, KdbxEntry>{};
    for (final entry in file.body.rootGroup.getAllEntries()) {
      out[_entryUuidHex(entry)] = entry;
    }
    return out;
  }

  /// The entry's 16-byte UUID as lowercase hex (the server's entry key).
  String _entryUuidHex(KdbxEntry entry) {
    final bytes = entry.uuid.toBytes();
    return [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
  }

  Uint8List _hexBytes(String hex) {
    final out = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  String _entryGroupPath(KdbxEntry entry) {
    final parts = <String>[];
    KdbxGroup? group = entry.parent;
    while (group != null && group.parent != null) {
      final name = group.name.get();
      if (name != null && name.isNotEmpty) {
        parts.insert(0, name);
      }
      group = group.parent;
    }
    return parts.join('/');
  }

  Future<KdbxFile> _reconstructFromRows(List<openvalutEntryRow> rows) async {
    final format = KdbxFormat();
    // Reconstruct with the same credentials the app will reopen with (the
    // master password when typed, or the remembered hash on quick unlock), so
    // the rebuilt KDBX opens without re-prompting.
    final creds = _kdbxCredentials();
    if (creds == null) {
      throw StateError('row reconstruction requires credentials');
    }
    final file = format.create(creds, vaultName);
    final key = await vaultKey();
    final groups = <String, KdbxGroup>{'': file.body.rootGroup};
    for (final row in rows) {
      final groupPath = await _decryptGroup(row.group);
      final group = groups[groupPath] ??= _ensureGroup(file, groups, groupPath);
      final entry = KdbxEntry.create(file, group);
      group.addEntry(entry);
      // Keep the row's UUID so the next save diffs against the same identity
      // instead of re-uploading every entry as new.
      entry.forceSetUuid(KdbxUuid.fromBytes(_hexBytes(row.uuid)));
      final plain = openvalutCrypto.decrypt(
        key,
        base64.decode(row.nonce),
        base64.decode(row.ciphertext),
      );
      applyEntryRow(
        entry,
        jsonDecode(utf8.decode(plain)) as Map<String, dynamic>,
      );
    }
    // The app's deleteEntry() parks entries in a root-level "Trash" group.
    // Mark it as the file's recycle bin so the active entry list filters it
    // out instead of showing deleted entries as active.
    KdbxGroup? trash;
    for (final g in file.body.rootGroup.groups) {
      if (g.name.get() == 'Trash') {
        trash = g;
        break;
      }
    }
    if (trash != null) {
      file.body.meta.recycleBinEnabled.set(true);
      file.body.meta.recycleBinUUID.set(trash.uuid);
    }
    return file;
  }

  KdbxGroup _ensureGroup(
    KdbxFile file,
    Map<String, KdbxGroup> groups,
    String path,
  ) {
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    var current = file.body.rootGroup;
    var built = <String>[];
    for (final part in parts) {
      built.add(part);
      final key = built.join('/');
      current = groups[key] ??= file.createGroup(parent: current, name: part);
    }
    return current;
  }

  Future<Map<String, dynamic>> _decodeRowPayload(openvalutEntryRow row) async {
    final key = await vaultKey();
    final plain = openvalutCrypto.decrypt(
      key,
      base64.decode(row.nonce),
      base64.decode(row.ciphertext),
    );
    return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
  }

  Future<String> _encryptGroup(String group) async {
    final key = await vaultKey();
    final (nonce, ct) = openvalutCrypto.encrypt(
      key,
      Uint8List.fromList(utf8.encode(group)),
    );
    return '${base64.encode(nonce)}.${base64.encode(ct)}'; // NON-NLS
  }

  Future<String> _decryptGroup(String stored) async {
    if (stored.isEmpty) {
      return '';
    }
    final dot = stored.indexOf('.');
    if (dot <= 0) {
      return stored;
    }
    try {
      final key = await vaultKey();
      final plain = openvalutCrypto.decrypt(
        key,
        base64.decode(stored.substring(0, dot)),
        base64.decode(stored.substring(dot + 1)),
      );
      return utf8.decode(plain);
    } catch (_) {
      return stored;
    }
  }

  bool _samePayload(Map<String, dynamic> a, Map<String, dynamic> b) =>
      jsonEncode(a) == jsonEncode(b);

  Future<void> _syncRows(KdbxFile file) async {
    final key = await vaultKey();
    final currentEntries = _indexEntries(file);
    final upserts = <Map<String, Object?>>[];
    final deletes = <String>[];
    final newSyncedRows = <String, openvalutEntryRow>{};
    final newSyncedPayloads = <String, Map<String, dynamic>>{};

    for (final entry in currentEntries.values) {
      final uuid = _entryUuidHex(entry);
      final payload = encodeEntryRow(entry);
      final previousPayload = _lastSyncedPayloads[uuid];
      final previousRow = _lastSyncedRows[uuid];
      final groupPath = _entryGroupPath(entry);
      if (previousPayload != null && _samePayload(previousPayload, payload)) {
        final prev = previousRow;
        if (prev != null) {
          // Unchanged since last sync; keep the row as-is unless the entry
          // moved to another group (payload equality does not cover the
          // parent, and the server row must follow the new group path).
          final previousGroupPath = await _decryptGroup(prev.group);
          if (previousGroupPath == groupPath) {
            newSyncedRows[uuid] = prev;
            newSyncedPayloads[uuid] = payload;
            continue;
          }
        } else {
          continue;
        }
      }
      final group = await _encryptGroup(groupPath);
      final (nonce, ct) = openvalutCrypto.encrypt(
        key,
        Uint8List.fromList(utf8.encode(jsonEncode(payload))),
      );
      upserts.add(<String, Object?>{
        'uuid': uuid,
        'group': group,
        'nonce': base64.encode(nonce),
        'ciphertext': base64.encode(ct),
        'baseUpdatedAt': previousRow?.updatedAt ?? 0,
      });
      newSyncedPayloads[uuid] = payload;
    }

    // Entries removed locally (or absent from the current file) are deleted.
    for (final uuid in _lastSyncedRows.keys) {
      if (!currentEntries.containsKey(uuid)) {
        deletes.add(uuid);
      }
    }

    if (upserts.isNotEmpty || deletes.isNotEmpty) {
      final result = await client.syncEntries(
        vaultId: vaultId,
        upserts: upserts,
        deletes: deletes,
      );
      final conflicts = result.conflicts.toSet();
      for (final u in upserts) {
        final uuid = u['uuid']! as String;
        if (conflicts.contains(uuid)) {
          continue;
        }
        final version = result.updatedAt[uuid] ?? 0;
        newSyncedRows[uuid] = openvalutEntryRow(
          uuid: uuid,
          group: u['group']! as String,
          nonce: u['nonce']! as String,
          ciphertext: u['ciphertext']! as String,
          updatedAt: version,
        );
      }
      if (conflicts.isNotEmpty) {
        _logger.warning(
          'Row sync: ${conflicts.length} row(s) conflicted on the server; '
          'will retry on the next save.',
        );
      }
    }

    _lastSyncedRows = newSyncedRows;
    _lastSyncedPayloads = newSyncedPayloads;
  }

  @override
  FileSource copyWithDatabaseName(String databaseName) =>
      FileSourceopenvalutCloud(
        client: client,
        vaultId: vaultId,
        vaultName: databaseName,
        uuid: uuid,
        databaseName: databaseName,
        masterPassword: masterPassword,
        rememberedVaultKey: rememberedVaultKey,
        credentials: credentials,
        initialCachedContent: cached,
      );

  @NonNls
  @override
  Map<String, String?> toDebugMap() => {
    ...super.toDebugMap(),
    'vaultId': vaultId,
    'vaultName': vaultName,
  };
}
