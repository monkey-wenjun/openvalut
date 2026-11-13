import 'dart:async';
import 'dart:convert';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/openvalut_cloud/openvalut_client.dart';
import 'package:openvalut/openvalut_cloud/openvalut_crypto.dart';
import 'package:openvalut/openvalut_cloud/scan_vault_key.dart';
import 'package:openvalut/utils/uuid_util.dart';
import 'package:pointycastle/export.dart' show RSAPrivateKey;

final _logger = Logger('openvalut_cloud_session');

const _identityStorageName = 'openvalutCloudShareIdentity'; // NON-NLS
const _accountStorageName = 'openvalutCloudAccount'; // NON-NLS
const _vaultMasterPasswordStorageName = 'openvalutCloudVaultMasterPassword'; // NON-NLS
// Legacy storage names used before the openvalut→openvalut rename, so accounts,
// identities and the stored vault master password still load (and are migrated
// to the new names) instead of silently disappearing.
const _legacyIdentityStorageName = 'openvalutCloudShareIdentity'; // NON-NLS
const _legacyAccountStorageName = 'openvalutCloudAccount'; // NON-NLS
const _legacyVaultMasterPasswordStorageName = 'openvalutCloudVaultMasterPassword'; // NON-NLS

/// In-memory OpenValut Cloud account session.
///
/// The server token and the derived vault keys live only in memory: closing
/// the app forgets the account, and the vault master password is never sent
/// anywhere. `OpenedFile.toFileSource` reconstructs cloud vault sources from
/// this session, so recent cloud vaults are only reopenable after the user
/// logged in again in the current app run.
class openvalutCloudSession extends ChangeNotifier {
  openvalutCloudSession._();

  static final openvalutCloudSession instance = openvalutCloudSession._();

  openvalutClient? _client;
  String? _username;
  String? _userId;
  openvalutShareIdentity? _shareIdentity;

  /// The server URL (e.g. https://openvalut.example.com/).
  String? _serverUrl;
  RSAPrivateKey? _scanLoginPrivateKey;
  String? _scanSessionSecret;

  /// 本机已解锁云密码库的主密码（仅内存）。扫码确认时用于加密回传给 PC，
  /// 退出登录即清空，不落盘。
  String? _vaultMasterPassword;
  /// Which file (FileSource uuid) [vaultMasterPassword] belongs to, so
  /// unlocking another vault never auto-fills a password from a different
  /// database (a local vault and a cloud vault may use different passwords).
  String? _vaultMasterPasswordVaultId;

  openvalutClient? get client => _client;
  String? get username => _username;
  String? get userId => _userId;
  String? get serverUrl => _serverUrl;
  String? get vaultMasterPassword => _vaultMasterPassword;
  openvalutShareIdentity? get shareIdentity => _shareIdentity;
  bool get isLoggedIn => _client != null && _tokenValid;

  bool _tokenValid = false;

  /// Normalizes a user-supplied server URL.
  ///
  /// - Trims whitespace.
  /// - Removes a trailing slash.
  /// - Defaults to `https://` when no scheme is provided.
  static String normalizeServerUrl(String serverUrl) {
    var normalized = serverUrl.trim();
    if (normalized.isEmpty) {
      return normalized;
    }
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  /// Creates (or replaces) the client for [serverUrl].
  ///
  /// Normalizes the URL: trims whitespace, removes a trailing slash, and
  /// defaults to `https://` when no scheme is provided.
  openvalutClient ensureClient(String serverUrl) {
    final normalized = normalizeServerUrl(serverUrl);
    _serverUrl = normalized;
    _client = openvalutClient(baseUrl: normalized);
    _client!.refreshToken = _refreshClientToken;
    final identity = _shareIdentity;
    if (identity != null) {
      _client!.envelopePrivateKey = identity.privateKey;
    }
    final userId = _userId;
    if (userId != null) {
      _client!.signKey = userId;
    }
    _tokenValid = false;
    _username = null;
    _userId = null;
    _shareIdentity = null;
    notifyListeners();
    return _client!;
  }

  /// Re-login with the remembered email + Secret Key to mint a fresh token
  /// after the previous one expired. Returns null when no account is known
  /// in this session (e.g. the very first login attempt), so login failures
  /// never loop.
  Future<String?> _refreshClientToken() async {
    final username = _username;
    final userId = _userId;
    final client = _client;
    if (username == null || userId == null || client == null) {
      return null;
    }
    try {
      final token = await client.login(username: username, userId: userId);
      if (token.isEmpty) {
        return null;
      }
      _tokenValid = true;
      return token;
    } catch (e, stackTrace) {
      _logger.warning('OpenValut Cloud token refresh failed.', e, stackTrace);
      return null;
    }
  }

  /// Logs in with the account email and its Secret Key (the account UUID).
  Future<void> login({
    required String username,
    required String userId,
    String? serverUrl,
  }) async {
    final client = serverUrl != null ? ensureClient(serverUrl) : _client;
    if (client == null) {
      throw StateError('OpenValut Cloud server URL is not configured.');
    }
    final identity = await ensureShareIdentity();
    client.envelopePrivateKey = identity.privateKey;
    final token = await client.login(
      username: username,
      userId: userId,
      publicKey: base64Encode(identity.publicKey),
    );
    if (token.isEmpty) {
      throw openvalutApiException(401, 'login failed');
    }
    _username = username;
    _userId = userId;
    _tokenValid = true;
    await _ensurePublicKeyRegistered(client);
    await _saveAccount();
    notifyListeners();
  }

  /// Derives and installs the account metadata key from the vault master
  /// password. The key encrypts vault names / group names client-side, so
  /// the server only stores ciphertext; it is never sent anywhere.
  Future<void> setVaultMetaKey(String masterPassword) async {
    final userId = _userId;
    final client = _client;
    if (userId == null || client == null || masterPassword.isEmpty) {
      return;
    }
    final key = await openvalutCrypto.deriveKey(
      masterPassword,
      Uint8List.fromList(utf8.encode(userId)),
    );
    client.metaKey = key;
  }

  /// Attempts to log in with the account remembered from the last session
  /// (email + Secret Key). Returns true when a token was obtained.
  Future<bool> autoLogin() async {
    if (isLoggedIn) {
      return true;
    }
    final saved = await loadSavedAccount();
    if (saved == null) {
      return false;
    }
    try {
      await login(
        username: saved.username,
        userId: saved.userId,
        serverUrl: saved.serverUrl,
      );
      return true;
    } catch (e, stackTrace) {
      _logger.warning('Automatic OpenValut Cloud login failed.', e, stackTrace);
      return false;
    }
  }

  Future<BiometricStorageFile> _accountStorage() =>
      BiometricStorage().getStorage(
        _accountStorageName,
        options: StorageFileInitOptions(authenticationRequired: false),
      );

  /// Reads a biometric storage value, falling back to the legacy (pre-rename)
  /// storage name and migrating the value to the current name when found.
  Future<String?> _readWithLegacyFallback(
    String currentName,
    String legacyName,
  ) async {
    Future<BiometricStorageFile> storage(String name) =>
        BiometricStorage().getStorage(
          name,
          options: StorageFileInitOptions(authenticationRequired: false),
        );
    final current = await (await storage(currentName)).read();
    if (current != null) {
      return current;
    }
    final legacy = await (await storage(legacyName)).read();
    if (legacy != null) {
      try {
        await (await storage(currentName)).write(legacy);
      } catch (_) {
        // Migration is best-effort; the value is still usable from legacyName.
      }
    }
    return legacy;
  }

  /// Persists the account (email + Secret Key + server) so the next launch
  /// can log in automatically. The Secret Key is only stored in the
  /// platform's encrypted keyring; it is still required on the very first
  /// login of a new device.
  Future<void> _saveAccount() async {
    final username = _username;
    final userId = _userId;
    final serverUrl = _serverUrl;
    if (username == null || userId == null || serverUrl == null) {
      return;
    }
    try {
      await (await _accountStorage()).write(
        json.encode({
          'username': username,
          'userId': userId,
          'serverUrl': serverUrl,
        }),
      );
    } catch (e, stackTrace) {
      _logger.warning('Unable to persist cloud account.', e, stackTrace);
    }
  }

  Future<({String username, String userId, String serverUrl})?>
  loadSavedAccount() async {
    try {
      final jsonContent = await _readWithLegacyFallback(
        _accountStorageName,
        _legacyAccountStorageName,
      );
      if (jsonContent == null) {
        return null;
      }
      final data = json.decode(jsonContent) as Map<String, dynamic>;
      final username = data['username'] as String?;
      final userId = data['userId'] as String?;
      final serverUrl = data['serverUrl'] as String?;
      if (username == null || userId == null || serverUrl == null) {
        return null;
      }
      return (username: username, userId: userId, serverUrl: serverUrl);
    } catch (e, stackTrace) {
      _logger.warning('Unable to load saved cloud account.', e, stackTrace);
      return null;
    }
  }

  /// Removes the remembered account, so the next launch asks for the email
  /// and Secret Key again.
  Future<void> forgetAccount() async {
    try {
      await (await _accountStorage()).delete();
    } catch (e, stackTrace) {
      _logger.warning('Unable to forget cloud account.', e, stackTrace);
    }
  }

  /// Starts a QR-code login against [serverUrl] and returns the session id
  /// plus the QR content the not-yet-authenticated device should render.
  Future<({String sessionId, String qrContent})> startScanLogin({
    required String serverUrl,
  }) async {
    final client = ensureClient(serverUrl);
    // PC 端生成一次性 RSA 密钥对，公钥随二维码传给手机，私钥留在内存里
    // 用于解密手机回传的主密码密文。
    final pair = generateScanKeyPair();
    _scanLoginPrivateKey = pair.privateKey;
    final created = await client.createScanLogin(
      publicKey: encodeScanPublicKey(pair.publicKey),
    );
    // 会话创建者专属的一次性密钥：只有它能取回登录 token，二维码里没有它。
    _scanSessionSecret = created.sessionSecret;
    return (
      sessionId: created.sessionId,
      qrContent: created.qrContent,
    );
  }

  /// PC 端：解密手机在扫码确认时回传的主密码密文。
  String? decryptScanVaultKey(String ciphertext) {
    final privateKey = _scanLoginPrivateKey;
    if (privateKey == null || ciphertext.isEmpty) {
      return null;
    }
    try {
      return decryptVaultKeyFromScan(ciphertext, privateKey);
    } catch (e, stackTrace) {
      _logger.warning('Unable to decrypt relayed vault key.', e, stackTrace);
      return null;
    }
  }

  /// 记录本机刚解锁的云密码库主密码（仅内存）。
  void rememberVaultMasterPassword(
    String? password, {
    String? vaultId,
  }) {
    _vaultMasterPassword = (password == null || password.isEmpty)
        ? null
        : password;
    _vaultMasterPasswordVaultId = vaultId;
    // 同时写入系统钥匙串（biometric_storage 加密存储），这样指纹快捷解锁
    // 重新打开密码库后，扫码仍能取回明文主密码加密回传给 PC（与 1Password
    // 把解锁密钥存进系统 Keychain 的做法一致）。
    unawaited(
      persistVaultMasterPassword(_vaultMasterPassword, vaultId: vaultId),
    );
  }

  /// Clears the in-memory vault master password without touching the persisted
  /// copy, so a subsequent lock screen cannot auto-fill it.
  void clearInMemoryVaultMasterPassword() {
    _vaultMasterPassword = null;
    _vaultMasterPasswordVaultId = null;
  }

  /// In-memory master password only when it belongs to [vaultId]. The
  /// credential screen uses this so unlocking one vault never auto-fills a
  /// password remembered for another vault.
  String? vaultMasterPasswordFor(String vaultId) {
    if (_vaultMasterPasswordVaultId != null &&
        _vaultMasterPasswordVaultId != vaultId) {
      return null;
    }
    return _vaultMasterPassword;
  }

  /// 把主密码持久化到系统钥匙串（加密存储、不依赖本次进程内存）。
  Future<void> persistVaultMasterPassword(
    String? password, {
    String? vaultId,
  }) async {
    try {
      final storage = await _vaultMasterPasswordStorage();
      if (password == null || password.isEmpty) {
        await storage.delete();
      } else {
        await storage.write(json.encode({
          'vaultId': vaultId,
          'password': password,
        }));
      }
    } catch (e, stackTrace) {
      _logger.warning('Unable to persist vault master password.', e, stackTrace);
    }
  }

  /// 从系统钥匙串读取主密码（指纹快捷解锁后扫码时使用）。
  Future<String?> loadVaultMasterPassword({String? vaultId}) async {
    try {
      final raw = await _readWithLegacyFallback(
        _vaultMasterPasswordStorageName,
        _legacyVaultMasterPasswordStorageName,
      );
      if (raw == null || raw.isEmpty) {
        return null;
      }
      try {
        final data = json.decode(raw) as Map<String, dynamic>;
        final storedId = data['vaultId'] as String?;
        final password = data['password'] as String?;
        if (vaultId != null && storedId != null && storedId != vaultId) {
          return null;
        }
        return (password == null || password.isEmpty) ? null : password;
      } on FormatException {
        // Records written before per-vault scoping stored the bare password.
        // They cannot be attributed to a vault, so only unscoped callers
        // (scan login) may use them; a specific cloud vault asks the user
        // once and re-saves a scoped record instead of failing repeatedly.
        return vaultId == null ? raw : null;
      }
    } catch (e, stackTrace) {
      _logger.warning('Unable to load vault master password.', e, stackTrace);
      return null;
    }
  }

  Future<BiometricStorageFile> _vaultMasterPasswordStorage() =>
      BiometricStorage().getStorage(
        _vaultMasterPasswordStorageName,
        options: StorageFileInitOptions(authenticationRequired: false),
      );

  /// 手机端：从服务器取回 PC 注册到扫码会话上的临时公钥。
  Future<String?> fetchScanPublicKey(String sessionId) async {
    final data = await pollScanLogin(sessionId);
    return data['publicKey'] as String?;
  }

  /// Polls a QR login session; the caller keeps polling while the status is
  /// `pending`. A `confirmed` result carries the one-time login token.
  ///
  /// The creator's one-time secret (held by this device when it started the
  /// session) is sent automatically so the token is only ever released to the
  /// device that owns the QR session.
  Future<Map<String, dynamic>> pollScanLogin(String sessionId) {
    final client = _client;
    if (client == null) {
      throw StateError('OpenValut Cloud server URL is not configured.');
    }
    return client.pollScanLogin(
      sessionId,
      sessionSecret: _scanSessionSecret,
    );
  }

  /// Completes a QR login once [pollScanLogin] returned `confirmed`.
  ///
  /// [userId] is the account id returned by the server on the secret-gated
  /// poll. It doubles as the request signing key, so passing it lets the
  /// not-yet-logged-in device sign its very next request without a bootstrap
  /// call. When it is absent (older server) we fall back to asking `/api/me`.
  Future<void> applyScanLogin({
    required String token,
    required String username,
    String? userId,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('OpenValut Cloud server URL is not configured.');
    }
    if (token.isEmpty) {
      throw openvalutApiException(401, 'login failed');
    }
    client.token = token;
    _username = username;
    _tokenValid = true;
    if (userId != null && userId.isNotEmpty) {
      _userId = userId;
      client.signKey = userId;
    } else {
      // Older server: the confirmed poll has no account id, so fetch it. This
      // only works on a server that accepts a token-only `/api/me`; on the
      // Rust server (signature required) it fails and the id stays unresolved.
      try {
        final me = await client.me();
        _userId = me['id'] as String?;
        client.signKey = _userId;
      } catch (e, stackTrace) {
        _logger.warning('Unable to resolve user id after QR login.', e, stackTrace);
      }
    }
    await _ensurePublicKeyRegistered(client);
    notifyListeners();
  }

  /// Confirms a scanned QR login with the currently logged-in account
  /// (mobile app side). [vaultCiphertext] is the opened vault's master
  /// password encrypted to the PC's ephemeral public key.
  Future<void> confirmScanLogin(
    String sessionId, {
    String? vaultCiphertext,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('OpenValut Cloud is not logged in.');
    }
    await client.confirmScanLogin(sessionId, vaultCiphertext: vaultCiphertext);
  }

  /// Registers a new account and logs in.
  Future<void> register({
    required String username,
    String? serverUrl,
  }) async {
    final client = serverUrl != null ? ensureClient(serverUrl) : _client;
    if (client == null) {
      throw StateError('OpenValut Cloud server URL is not configured.');
    }
    _username = username;
    final identity = await ensureShareIdentity();
    client.envelopePrivateKey = identity.privateKey;
    _userId = await client.register(
      username: username,
      publicKey: base64Encode(identity.publicKey),
    );
    _tokenValid = true;
    await _saveAccount();
    notifyListeners();
  }

  /// Marks the token as invalid (e.g. after a 401).
  void invalidateToken() {
    _tokenValid = false;
    notifyListeners();
  }

  /// Generates (once per app run) and returns the X25519 identity used for
  /// sharing.
  Future<openvalutShareIdentity> ensureShareIdentity() async {
    final existing = _shareIdentity;
    if (existing != null) {
      return existing;
    }
    final stored = await _loadStoredIdentity();
    if (stored != null) {
      _shareIdentity = stored;
      return stored;
    }
    final identity = await openvalutCrypto.generateShareIdentity();
    _shareIdentity = identity;
    await _storeIdentity(identity);
    return identity;
  }

  Future<BiometricStorageFile> _identityStorage() =>
      BiometricStorage().getStorage(
        _identityStorageName,
        options: StorageFileInitOptions(authenticationRequired: false),
      );

  /// Restores the identity persisted for this account (username + server),
  /// so shares wrapped to our public key stay decryptable across restarts.
  Future<openvalutShareIdentity?> _loadStoredIdentity() async {
    final username = _username;
    final serverUrl = _serverUrl;
    if (username == null || serverUrl == null) {
      return null;
    }
    try {
      final jsonContent = await _readWithLegacyFallback(
        _identityStorageName,
        _legacyIdentityStorageName,
      );
      if (jsonContent == null) {
        return null;
      }
      final data = json.decode(jsonContent) as Map<String, dynamic>;
      if (data['username'] != username || data['serverUrl'] != serverUrl) {
        return null;
      }
      final privateKey = data['privateKey'] as String?;
      final publicKey = data['publicKey'] as String?;
      if (privateKey == null || publicKey == null) {
        return null;
      }
      return openvalutShareIdentity(
        privateKey: Uint8List.fromList(base64.decode(privateKey)),
        publicKey: Uint8List.fromList(base64.decode(publicKey)),
      );
    } catch (e, stackTrace) {
      _logger.warning('Unable to load stored share identity.', e, stackTrace);
      return null;
    }
  }

  Future<void> _storeIdentity(openvalutShareIdentity identity) async {
    final username = _username;
    final serverUrl = _serverUrl;
    if (username == null || serverUrl == null) {
      return;
    }
    try {
      await (await _identityStorage()).write(
        json.encode({
          'username': username,
          'serverUrl': serverUrl,
          'privateKey': base64.encode(identity.privateKey),
          'publicKey': base64.encode(identity.publicKey),
        }),
      );
    } catch (e, stackTrace) {
      // A failing keyring must not block login; the identity is regenerated
      // on the next run (previously wrapped shares become undecryptable).
      _logger.warning('Unable to persist share identity.', e, stackTrace);
    }
  }

  Future<void> _ensurePublicKeyRegistered(openvalutClient client) async {
    final identity = await ensureShareIdentity();
    await client.setPublicKey(base64Encode(identity.publicKey));
  }

  void clear() {
    _client = null;
    _username = null;
    _userId = null;
    _serverUrl = null;
    _scanLoginPrivateKey = null;
    _scanSessionSecret = null;
    _vaultMasterPassword = null;
    unawaited(persistVaultMasterPassword(null));
    _shareIdentity = null;
    _tokenValid = false;
    notifyListeners();
  }

  /// The current client or null when not logged in.
  openvalutClient? get currentClient => isLoggedIn ? _client : null;

  static String newVaultId() {
    // The server expects a 32-char lowercase hex id; a UUID v4 without
    // dashes matches. The id doubles as the per-vault KDF salt.
    return UuidUtil.createUuid().replaceAll('-', '').toLowerCase();
  }
}
