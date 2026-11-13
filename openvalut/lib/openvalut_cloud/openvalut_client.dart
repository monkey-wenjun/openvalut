import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:openvalut/openvalut_cloud/openvalut_crypto.dart';
import 'package:openvalut/utils/app_locale.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _logger = Logger('openvalut_client');

const _serverPublicKeyPinKey = 'openvalut_server_public_key_pin'; // NON-NLS

/// Thrown for non-2xx responses.
class openvalutApiException implements Exception {
  openvalutApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'openvalutApiException($statusCode): $message';
}

class openvalutVault {
  openvalutVault({
    required this.id,
    required this.name,
    required this.nonce,
    required this.ciphertext,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String nonce;
  final String ciphertext;
  final int? updatedAt;
}

/// One row-level entry: an entry payload encrypted with the vault key, plus
/// its (meta-key-encrypted) group path and a per-row version for optimistic
/// concurrency.
class openvalutEntryRow {
  openvalutEntryRow({
    required this.uuid,
    required this.group,
    required this.nonce,
    required this.ciphertext,
    required this.updatedAt,
  });

  factory openvalutEntryRow.fromJson(Map<dynamic, dynamic> json) =>
      openvalutEntryRow(
        uuid: json['uuid'] as String? ?? '',
        group: json['group'] as String? ?? '',
        nonce: json['nonce'] as String? ?? '',
        ciphertext: json['ciphertext'] as String? ?? '',
        updatedAt: json['updatedAt'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'group': group,
    'nonce': nonce,
    'ciphertext': ciphertext,
    'updatedAt': updatedAt,
  };

  final String uuid;
  final String group;
  final String nonce;
  final String ciphertext;
  final int updatedAt;
}

class openvalutShare {
  openvalutShare({
    required this.id,
    required this.entryUuid,
    required this.ownerUsername,
    required this.recipientUsername,
    required this.encryptedShareKey,
    required this.sharedNonce,
    required this.sharedCiphertext,
    required this.createdAt,
  });

  final String id;
  final String entryUuid;
  final String ownerUsername;
  final String recipientUsername;
  final String encryptedShareKey;
  final String sharedNonce;
  final String sharedCiphertext;
  final int createdAt;
}

/// One member row of a dynamic group share.
class openvalutGroupShareRow {
  openvalutGroupShareRow({
    required this.entryUuid,
    required this.nonce,
    required this.ciphertext,
    required this.updatedAt,
  });

  factory openvalutGroupShareRow.fromJson(Map<dynamic, dynamic> json) =>
      openvalutGroupShareRow(
        entryUuid: json['entryUuid'] as String? ?? '',
        nonce: json['nonce'] as String? ?? '',
        ciphertext: json['ciphertext'] as String? ?? '',
        updatedAt: json['updatedAt'] as int? ?? 0,
      );

  final String entryUuid;
  final String nonce;
  final String ciphertext;
  final int updatedAt;

  Map<String, Object?> toJson() => {
    'entryUuid': entryUuid,
    'nonce': nonce,
    'ciphertext': ciphertext,
    'updatedAt': updatedAt,
  };
}

/// Dynamic group share: one share key wrapped to the recipient; the display
/// name and every member row are encrypted with that same key.
class openvalutGroupShare {
  openvalutGroupShare({
    required this.id,
    required this.vaultId,
    required this.ownerUsername,
    required this.recipientUsername,
    required this.encryptedShareKey,
    required this.nameNonce,
    required this.nameCiphertext,
    required this.createdAt,
  });

  factory openvalutGroupShare.fromJson(Map<dynamic, dynamic> json) =>
      openvalutGroupShare(
        id: json['id'] as String? ?? '',
        vaultId: json['vaultId'] as String? ?? '',
        ownerUsername: json['ownerUsername'] as String? ?? '',
        recipientUsername: json['recipientUsername'] as String? ?? '',
        encryptedShareKey: json['encryptedShareKey'] as String? ?? '',
        nameNonce: json['nameNonce'] as String? ?? '',
        nameCiphertext: json['nameCiphertext'] as String? ?? '',
        createdAt: json['createdAt'] as int? ?? 0,
      );

  final String id;
  final String vaultId;
  final String ownerUsername;
  final String recipientUsername;
  final String encryptedShareKey;
  final String nameNonce;
  final String nameCiphertext;
  final int createdAt;
}

/// REST client for openvalut-server. Credentials (token) live only in memory.
class openvalutClient {
  openvalutClient({
    required this.baseUrl,
    this.token = '',
    http.Client? httpClient,
    this.refreshToken,
    this.signKey,
    this.envelopePrivateKey,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;
  String token;

  /// Called when the server rejects the current token with 401 so the
  /// session can mint a fresh one (re-login with the stored Secret Key).
  /// Returning null (or an empty token) means no refresh is possible.
  Future<String?> Function()? refreshToken;

  /// The user's 32-char UUID, used as the HMAC key for request signatures.
  /// Null until the first login completes; login itself signs with the
  /// userId supplied in the request.
  String? signKey;

  /// The user's X25519 private key, used to decrypt enveloped responses.
  /// Set by the session once the share identity is loaded.
  Uint8List? envelopePrivateKey;

  /// Account-level metadata key (Argon2id(master password, userId)) used to
  /// encrypt vault names and entry group names before upload, so the server
  /// only ever stores ciphertext for these fields too.
  Uint8List? metaKey;

  Uint8List? _serverPublicKey;

  /// Fetches the server's transport-envelope public key (plaintext
  /// endpoint). The key is pinned in memory and persisted locally; a MITM
  /// cannot swap it without triggering a mismatch on the next fetch.
  Future<Uint8List> fetchServerKey() async {
    final uri = Uri.parse('$baseUrl/api/server-key');
    final response = await _http.get(uri);
    if (response.statusCode != 200) {
      throw openvalutApiException(
        response.statusCode,
        'unable to fetch server key',
      );
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    final encoded = data['publicKey'] as String;
    final key = base64Decode(encoded);
    if (key.length != 32) {
      throw openvalutApiException(0, 'invalid server key');
    }

    final pinned = _serverPublicKey ?? await _loadPinnedServerKey();
    if (pinned != null) {
      if (!fixedTimeEquals(pinned, key)) {
        throw openvalutApiException(0, 'server key mismatch');
      }
    } else {
      await _pinServerKey(key);
    }
    _serverPublicKey = key;
    return key;
  }

  Future<Uint8List?> _loadPinnedServerKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_serverPublicKeyPinKey);
      if (encoded == null || encoded.isEmpty) {
        return null;
      }
      final key = base64Decode(encoded);
      if (key.length != 32) {
        return null;
      }
      return key;
    } catch (e, stackTrace) {
      _logger.warning('Failed to load pinned server key', e, stackTrace);
      return null;
    }
  }

  Future<void> _pinServerKey(Uint8List key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_serverPublicKeyPinKey, base64Encode(key));
    } catch (e, stackTrace) {
      _logger.warning('Failed to persist pinned server key', e, stackTrace);
    }
  }

  /// Constant-time comparison for byte arrays to avoid timing side channels.
  static bool fixedTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      return false;
    }
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
    Map<String, String>? extraHeaders,
  }) async {
    var refreshed = false;
    while (true) {
      final serverPublicKey = _serverPublicKey ??= await fetchServerKey();
      final plainBody = body == null
          ? null
          : Uint8List.fromList(utf8.encode(json.encode(body)));
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
          .toString();
      final nonce = openvalutCrypto.generateNonce();
      // The server verifies the signature against r.URL.Path, which Go
      // percent-decodes before routing. The request itself must still use the
      // encoded path (e.g. %40 for '@'), but the signature has to cover the
      // decoded path so both sides hash the same string.
      final signaturePath = Uri.decodeFull(path);
      final signature = signKey == null
          ? null
          : openvalutCrypto.signRequest(
              userId: signKey!,
              method: method,
              path: signaturePath,
              timestamp: timestamp,
              nonce: nonce,
              body: plainBody ?? const [],
            );

      // Wrap the request body in the transport envelope when the server key
      // is available. GET/DELETE have no body and stay unwrapped.
      Object? wireBody;
      if (plainBody != null) {
        final blob = await openvalutCrypto.envelopeEncrypt(
          recipientPublicKey: serverPublicKey,
          plaintext: plainBody,
        );
        wireBody = {'enc': base64Encode(blob)};
      }
      final headers = <String, String>{
        'Content-Type': 'application/json',
        // Only request an enveloped response when we hold the private key
        // to open it (QR-login devices without a share identity stay on the
        // plaintext response path for compatibility).
        'X-Envelope': ?(envelopePrivateKey == null ? null : '1'), // NON-NLS
        'X-Timestamp': timestamp, // NON-NLS
        'X-Nonce': nonce, // NON-NLS
        'X-Signature': ?signature, // NON-NLS
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        ...?extraHeaders,
      };
      final uri = Uri.parse('$baseUrl$path');
      late http.Response response;
      try {
        switch (method) {
          case 'GET':
            response = await _http.get(uri, headers: headers);
          case 'POST':
            response = await _http.post(
              uri,
              headers: headers,
              body: wireBody == null ? null : json.encode(wireBody),
            );
          case 'PUT':
            response = await _http.put(
              uri,
              headers: headers,
              body: wireBody == null ? null : json.encode(wireBody),
            );
          case 'DELETE':
            response = await _http.delete(uri, headers: headers);
          default:
            throw ArgumentError(method);
        }
      } catch (e, stackTrace) {
        // Network-layer failures (DNS, connection refused, timeout, socket
        // errors) are reported with statusCode 0 so callers can distinguish
        // them from HTTP errors and back off instead of hammering the server.
        _logger.warning(
          'OpenValut Cloud request failed ($method $path): $e',
          e,
          stackTrace,
        );
        throw openvalutApiException(
          0,
          AppLocale.isChinese ? '网络请求失败: $e' : 'Network request failed: $e',
        );
      }
      final decoded = await _decodeResponse(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      if (response.statusCode == 429) {
        throw openvalutApiException(429, 'rate limit exceeded');
      }
      if (response.statusCode == 401 && !refreshed && refreshToken != null) {
        refreshed = true;
        final fresh = await refreshToken!();
        if (fresh != null && fresh.isNotEmpty) {
          token = fresh;
          continue;
        }
      }
      throw openvalutApiException(
        response.statusCode,
        decoded['error'] as String? ?? 'HTTP ${response.statusCode}',
      );
    }
  }

  /// Decodes a response, unwrapping the transport envelope with the user's
  /// private key when the server wrapped it.
  Future<Map<String, dynamic>> _decodeResponse(String raw) async {
    if (raw.isEmpty) {
      return <String, dynamic>{};
    }
    final privateKey = envelopePrivateKey;
    if (privateKey != null) {
      try {
        final env = json.decode(raw) as Map<String, dynamic>;
        final enc = env['enc'];
        if (enc is String && enc.isNotEmpty) {
          final blob = base64Decode(enc);
          final plain = await openvalutCrypto.envelopeDecrypt(
            privateKey: privateKey,
            blob: blob,
          );
          return json.decode(utf8.decode(plain)) as Map<String, dynamic>;
        }
      } on openvalutDecryptionException {
        // Fall through to the plaintext decode below (e.g. login response
        // when the share identity was not loaded yet).
      } on FormatException {
        // Not an envelope; treat as plaintext.
      }
    }
    return json.decode(raw) as Map<String, dynamic>;
  }

  /// Registers (or logs in if the username exists) and stores the token.
  Future<String> register({
    required String username,
    String publicKey = '',
  }) async {
    final data = await _request(
      'POST',
      '/api/register',
      body: {
        'username': username,
        'publicKey': publicKey,
      },
    );
    token = data['token'] as String;
    return data['user']['id'] as String;
  }

  /// Returns the authenticated user's profile (id, username, public key).
  Future<Map<String, dynamic>> me() async {
    final data = await _request('GET', '/api/me');
    return (data['user'] as Map<Object?, Object?>).map(
      (k, v) => MapEntry(k as String, v),
    );
  }

  /// Logs in with the account email and its Secret Key (the account UUID).
  /// The vault master password never leaves the client, so it is not part
  /// of the request.
  Future<String> login({
    required String username,
    required String userId,
    String publicKey = '',
  }) async {
    // The login request itself is signed with the account UUID so a MITM
    // cannot replay or alter it; afterwards this key stays for all requests.
    signKey = userId;
    final data = await _request(
      'POST',
      '/api/login',
      body: {
        'username': username,
        'userId': userId,
        if (publicKey.isNotEmpty) 'publicKey': publicKey,
      },
    );
    token = data['token'] as String;
    return token;
  }

  /// Starts a QR-code login and returns the session id, the content to
  /// render as a QR code, and the one-time creator secret required to poll
  /// for the login token. [publicKey] (optional) is the PC's ephemeral RSA
  /// public key, registered with the session server-side so the scanning
  /// mobile app can fetch it and encrypt the vault master password back to
  /// this device without bloating the QR code.
  Future<({String sessionId, String qrContent, String sessionSecret})>
  createScanLogin({
    String? publicKey,
  }) async {
    final data = await _request(
      'POST',
      '/api/login/scan',
      body: publicKey == null ? null : {'publicKey': publicKey},
    );
    return (
      sessionId: data['sessionId'] as String,
      qrContent: data['qrContent'] as String,
      sessionSecret: data['sessionSecret'] as String,
    );
  }

  /// Resolves the status of a QR login:
  /// `pending`, `expired`, or `confirmed` (with a one-time token).
  /// [sessionSecret] is the creator-held secret; it must be sent to receive
  /// the token once the session is confirmed.
  Future<Map<String, dynamic>> pollScanLogin(
    String sessionId, {
    String? sessionSecret,
  }) async {
    return _request(
      'GET',
      '/api/login/scan/${Uri.encodeComponent(sessionId)}',
      extraHeaders: sessionSecret == null || sessionSecret.isEmpty
          ? null
          : {'X-Scan-Secret': sessionSecret},
    );
  }

  /// Confirms a QR login on behalf of the currently logged-in account
  /// (called by the mobile app that scanned the code). [vaultCiphertext] is
  /// the master password encrypted to the PC's ephemeral public key; the
  /// server only relays it.
  Future<void> confirmScanLogin(
    String sessionId, {
    String? vaultCiphertext,
  }) async {
    await _request(
      'POST',
      '/api/login/scan/${Uri.encodeComponent(sessionId)}/confirm',
      body: {'vaultCiphertext': vaultCiphertext},
    );
  }

  /// Returns the X25519 public key (base64) of [username], used to wrap
  /// share keys to them.
  Future<String> getUserPublicKey(String username) async {
    final data = await _request(
      'GET',
      '/api/users/${Uri.encodeComponent(username)}/public-key',
    );
    return data['publicKey'] as String;
  }

  /// Registers this device's X25519 public key for receiving shares.
  Future<void> setPublicKey(String publicKey) async {
    await _request(
      'PUT',
      '/api/me/public-key',
      body: {
        'publicKey': publicKey,
      },
    );
  }

  Future<List<openvalutShare>> listIncomingShares() async {
    final data = await _request('GET', '/api/shares/incoming');
    return _parseShares(data);
  }

  Future<List<openvalutShare>> listOutgoingShares() async {
    final data = await _request('GET', '/api/shares/outgoing');
    return _parseShares(data);
  }

  List<openvalutShare> _parseShares(Map<String, dynamic> data) {
    final shares = data['shares'];
    if (shares == null) {
      return [];
    }
    return (shares as List<Object?>)
        .cast<Map<Object?, Object?>>()
        .map(
          (s) => openvalutShare(
            id: s['id']! as String,
            entryUuid: s['entryUuid']! as String,
            ownerUsername: s['ownerUsername']! as String,
            recipientUsername: s['recipientUsername']! as String,
            encryptedShareKey: s['encryptedShareKey']! as String,
            sharedNonce: s['sharedNonce']! as String,
            sharedCiphertext: s['sharedCiphertext']! as String,
            createdAt: s['createdAt']! as int,
          ),
        )
        .toList();
  }

  Future<void> createShare({
    required String vaultId,
    required String entryUuid,
    required String recipientUsername,
    required String encryptedShareKey,
    required String sharedNonce,
    required String sharedCiphertext,
  }) async {
    await _request(
      'POST',
      '/api/vaults/$vaultId/shares',
      body: {
        'entryUuid': entryUuid,
        'recipientUsername': recipientUsername,
        'encryptedShareKey': encryptedShareKey,
        'sharedNonce': sharedNonce,
        'sharedCiphertext': sharedCiphertext,
      },
    );
  }

  Future<void> deleteShare(String shareId) async {
    await _request('DELETE', '/api/shares/$shareId');
  }

  Future<List<openvalutGroupShare>> listIncomingGroupShares() async {
    final data = await _request('GET', '/api/group-shares/incoming');
    return _parseGroupShares(data);
  }

  Future<List<openvalutGroupShare>> listOutgoingGroupShares() async {
    final data = await _request('GET', '/api/group-shares/outgoing');
    return _parseGroupShares(data);
  }

  List<openvalutGroupShare> _parseGroupShares(Map<String, dynamic> data) {
    final shares = data['shares'];
    if (shares == null) {
      return [];
    }
    return (shares as List<Object?>)
        .cast<Map<Object?, Object?>>()
        .map(openvalutGroupShare.fromJson)
        .toList();
  }

  /// Returns a group share and all of its current member rows.
  Future<({
    openvalutGroupShare share,
    List<openvalutGroupShareRow> rows,
  })>
  getGroupShare(String shareId) async {
    final data = await _request('GET', '/api/group-shares/$shareId');
    final share = openvalutGroupShare.fromJson(
      data['share'] as Map<Object?, Object?>,
    );
    final rows = (data['entries'] as List<dynamic>? ?? [])
        .map((e) => openvalutGroupShareRow.fromJson(e as Map<dynamic, dynamic>))
        .toList();
    return (share: share, rows: rows);
  }

  /// Creates the group share and returns its server id.
  Future<String> createGroupShare({
    required String vaultId,
    required String recipientUsername,
    required String encryptedShareKey,
    required String nameNonce,
    required String nameCiphertext,
    required List<Map<String, String>> entries,
  }) async {
    final data = await _request(
      'POST',
      '/api/vaults/$vaultId/group-shares',
      body: {
        'recipientUsername': recipientUsername,
        'encryptedShareKey': encryptedShareKey,
        'nameNonce': nameNonce,
        'nameCiphertext': nameCiphertext,
        'entries': entries,
      },
    );
    final share = data['share'] as Map<Object?, Object?>;
    return share['id']! as String;
  }

  Future<void> upsertGroupShareRows(
    String shareId,
    List<Map<String, String>> entries,
  ) async {
    await _request(
      'POST',
      '/api/group-shares/$shareId/entries',
      body: {'entries': entries},
    );
  }

  Future<void> removeGroupShareRow(String shareId, String entryUuid) async {
    await _request(
      'DELETE',
      '/api/group-shares/$shareId/entries/$entryUuid',
    );
  }

  Future<void> deleteGroupShare(String shareId) async {
    await _request('DELETE', '/api/group-shares/$shareId');
  }

  Future<List<openvalutVault>> listVaults() async {
    final data = await _request('GET', '/api/vaults');
    return (data['vaults'] as List<Object?>)
        .cast<Map<Object?, Object?>>()
        .map(
          (v) => openvalutVault(
            id: v['id']! as String,
            name: _decryptMeta(v['name']! as String),
            nonce: v['nonce']! as String,
            ciphertext: v['ciphertext']! as String,
            updatedAt: v['updatedAt'] as int?,
          ),
        )
        .toList();
  }

  Future<openvalutVault> getVault(String vaultId) async {
    final data = await _request('GET', '/api/vaults/$vaultId');
    final v = data['vault'] as Map<Object?, Object?>;
    return openvalutVault(
      id: v['id']! as String,
      name: _decryptMeta(v['name']! as String),
      nonce: v['nonce']! as String,
      ciphertext: v['ciphertext']! as String,
      updatedAt: v['updatedAt'] as int?,
    );
  }

  /// Lightweight vault metadata (updated time + blob size) without the
  /// encrypted payload, used for cheap change polling.
  Future<({int? updatedAt, int? size})> getVaultMeta(String vaultId) async {
    final data = await _request('GET', '/api/vaults/$vaultId/meta');
    final v = data['vault'] as Map<Object?, Object?>;
    return (
      updatedAt: v['updatedAt'] as int?,
      size: v['size'] as int?,
    );
  }

  Future<openvalutVault> createVault({
    String? id,
    required String name,
    required String nonce,
    required String ciphertext,
  }) async {
    final data = await _request(
      'POST',
      '/api/vaults',
      body: {
        'id': ?id,
        'name': _encryptMeta(name),
        'nonce': nonce,
        'ciphertext': ciphertext,
      },
    );
    final v = data['vault'] as Map<Object?, Object?>;
    return openvalutVault(
      id: v['id']! as String,
      name: _decryptMeta(v['name']! as String),
      nonce: v['nonce']! as String,
      ciphertext: v['ciphertext']! as String,
      updatedAt: v['updatedAt'] as int?,
    );
  }

  /// Uploads the encrypted blob. [baseUpdatedAt] is the server `updatedAt`
  /// the caller last read; the server rejects with 409 (conflict) when the
  /// blob changed since then. Returns the server's new `updatedAt` on success.
  Future<int> updateVaultBlob({
    required String vaultId,
    required String nonce,
    required String ciphertext,
    required int baseUpdatedAt,
  }) async {
    final data = await _request(
      'PUT',
      '/api/vaults/$vaultId',
      body: {
        'nonce': nonce,
        'ciphertext': ciphertext,
        'base_updated_at': baseUpdatedAt,
      },
    );
    return (data['updatedAt'] as int?) ?? baseUpdatedAt;
  }

  Future<void> deleteVault(String vaultId) async {
    await _request('DELETE', '/api/vaults/$vaultId');
  }

  /// Lists the encrypted per-entry rows of a vault. This is the row-level sync
  /// basis: each row is one entry encrypted with the vault key.
  Future<List<openvalutEntryRow>> listEntries(String vaultId) async {
    final data = await _request('GET', '/api/vaults/$vaultId/entries');
    final rows = (data['entries'] as List<dynamic>? ?? [])
        .map((e) => openvalutEntryRow.fromJson(e as Map<dynamic, dynamic>))
        .toList();
    return rows;
  }

  Future<void> deleteEntry(String vaultId, String uuid) async {
    await _request('DELETE', '/api/vaults/$vaultId/entries/$uuid');
  }

  /// Batch-syncs rows (upserts + deletes) in a single request, avoiding the
  /// per-request rate limit during migration / save-diff. Per-row optimistic
  /// locking still applies; conflicting uuids are returned, not failed.
  Future<({List<String> conflicts, Map<String, int> updatedAt})> syncEntries({
    required String vaultId,
    required List<Map<String, Object?>> upserts,
    required List<String> deletes,
  }) async {
    final data = await _request(
      'POST',
      '/api/vaults/$vaultId/entries/sync',
      body: {'upserts': upserts, 'deletes': deletes},
    );
    final updatedAt = <String, int>{
      for (final e in (data['upserted'] as List<dynamic>? ?? []))
        (e as Map)['uuid'] as String: (e)['updatedAt'] as int,
    };
    final conflicts = (data['conflicts'] as List<dynamic>? ?? [])
        .cast<String>();
    return (conflicts: conflicts, updatedAt: updatedAt);
  }

  /// Upserts one row-level entry (encrypted with the vault key). [baseUpdatedAt]
  /// is the row's version this client last read; the server rejects with 409
  /// when another writer changed the row since. Returns the new version.
  Future<int> upsertEntry({
    required String vaultId,
    required String uuid,
    required String group,
    required String nonce,
    required String ciphertext,
    required int baseUpdatedAt,
  }) async {
    final data = await _request(
      'POST',
      '/api/vaults/$vaultId/entries',
      body: {
        'uuid': uuid,
        'group': group,
        'nonce': nonce,
        'ciphertext': ciphertext,
        'baseUpdatedAt': baseUpdatedAt,
      },
    );
    return (data['entry']?['updatedAt'] as int?) ?? 0;
  }

  /// Encrypts a metadata string (vault name / entry group) with the
  /// account metadata key. Legacy/plain values are passed through unchanged.
  String _encryptMeta(String plain) {
    final key = metaKey;
    if (key == null || plain.isEmpty) {
      return plain;
    }
    final (nonce, ct) = openvalutCrypto.encrypt(
      key,
      Uint8List.fromList(utf8.encode(plain)),
    );
    return 'v1:${base64Encode(nonce)}.${base64Encode(ct)}'; // NON-NLS
  }

  /// Decrypts a metadata string. Returns the stored value verbatim when the
  /// key is unavailable (not unlocked yet) or the value is legacy plaintext.
  String _decryptMeta(String stored) {
    final key = metaKey;
    if (key == null || !stored.startsWith('v1:')) {
      return stored;
    }
    try {
      final rest = stored.substring(3);
      final dot = rest.indexOf('.');
      if (dot <= 0) {
        return stored;
      }
      final nonce = base64Decode(rest.substring(0, dot));
      final ct = base64Decode(rest.substring(dot + 1));
      final plain = openvalutCrypto.decrypt(key, nonce, ct);
      return utf8.decode(plain);
    } catch (_) {
      return stored;
    }
  }
}
