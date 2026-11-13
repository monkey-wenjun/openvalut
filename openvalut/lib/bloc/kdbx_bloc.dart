import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:math';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_async_utils/flutter_async_utils.dart';
import 'package:kdbx/kdbx.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/bloc/analytics.dart';
import 'package:openvalut/bloc/app_data.dart';
import 'package:openvalut/bloc/kdbx/file_content.dart';
import 'package:openvalut/bloc/kdbx/file_source.dart';
import 'package:openvalut/bloc/kdbx/file_source_local.dart';
import 'package:openvalut/bloc/kdbx/file_source_openvalut_cloud.dart';
import 'package:openvalut/bloc/kdbx/file_source_web_none.dart'
    if (dart.library.js_interop) 'package:openvalut/bloc/kdbx/file_source_web.dart';
import 'package:openvalut/bloc/kdbx/storage_exception.dart';
import 'package:openvalut/bloc/kdbx_argon2_ffi.dart'
    if (dart.library.js_interop) 'package:openvalut/bloc/kdbx_argon2_web.dart';
import 'package:openvalut/cloud_storage/cloud_storage_bloc.dart';
import 'package:openvalut/cloud_storage/cloud_storage_provider.dart';
import 'package:openvalut/computer/computer_identity.dart';
import 'package:openvalut/computer/pam_totp_file.dart';
import 'package:openvalut/credential_server/credential_server.dart';
import 'package:openvalut/env/_base.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/main.dart';
import 'package:openvalut/openvalut_cloud/group_share_service.dart';
import 'package:openvalut/openvalut_cloud/openvalut_client.dart';
import 'package:openvalut/openvalut_cloud/openvalut_cloud_session.dart';
import 'package:openvalut/rust_core/rust_vault.dart';
import 'package:openvalut/ssh/machine_identity.dart';
import 'package:openvalut/ssh/openssh_key.dart';
import 'package:openvalut/ssh/ssh_agent.dart';
import 'package:openvalut/ssh/ssh_profile.dart';
import 'package:openvalut/theme.dart';
import 'package:openvalut/utils/base32utils.dart';
import 'package:openvalut/utils/biometric_prompts.dart';
import 'package:openvalut/utils/builtin_groups.dart';
import 'package:openvalut/utils/clipboard_auto_clear.dart';
import 'package:openvalut/utils/constants.dart';
import 'package:openvalut/utils/extension_methods.dart';
import 'package:openvalut/utils/otp_field_migration.dart';
import 'package:openvalut/utils/otpauth.dart';
import 'package:openvalut/utils/path_utils.dart';
import 'package:openvalut/utils/platform.dart';
import 'package:openvalut/utils/read_access.dart';
import 'package:openvalut/utils/secret_reference.dart';
import 'package:openvalut/utils/session_store.dart';
import 'package:openvalut/utils/system_auth_io.dart'
    if (dart.library.js_interop) 'package:openvalut/utils/system_auth_web.dart';
import 'package:openvalut/utils/unlock_prefs.dart';
import 'package:rxdart/rxdart.dart';
import 'package:string_literal_finder_annotations/string_literal_finder_annotations.dart';

final _logger = Logger('kdbx_bloc');

bool _isMissingBiometricEntitlement(Object error) {
  if (error is! PlatformException) {
    return false;
  }
  final description = [
    error.code,
    error.message,
    error.details,
  ].whereType<Object>().join(' ').toLowerCase();
  return description.contains('-34018') ||
      description.contains("required entitlement isn't present") ||
      description.contains('missing entitlement');
}

/// Whether a file source lives on the OpenValut Cloud server. Cloud blobs are
/// encrypted with a key derived from the master password, so they can only
/// be reopened after the password (or the in-memory session key) is present;
/// biometric/remembered unlock would have to persist the vault key.
bool isCloudFileSource(FileSource fileSource) =>
    fileSource is FileSourceopenvalutCloud;

/// Returns the cached vault key of an OpenValut Cloud source, or null for
/// non-cloud sources / when the key is not available. Only used after a
/// successful unlock, so the key is already cached in memory and the master
/// password is never persisted.
Future<Uint8List?> vaultKeyForRememberStore(FileSource fileSource) async {
  if (fileSource is! FileSourceopenvalutCloud) {
    return null;
  }
  try {
    final key = await fileSource.ensureVaultKey();
    _logger.fine(
      'Remember store: cloud vault ${fileSource.vaultId} vault key '
      'available (${key.length} bytes).',
    );
    return key;
  } catch (e, stackTrace) {
    _logger.warning(
      'Unable to read cloud vault key for remember store.',
      e,
      stackTrace,
    );
    return null;
  }
}

/// The master password of an OpenValut Cloud source, if still in memory. Only
/// used right after a successful unlock to store it (encrypted) so the file
/// can be reopened writable in the same boot session.
String? masterPasswordForRememberStore(FileSource fileSource) {
  if (fileSource is FileSourceopenvalutCloud) {
    return fileSource.masterPassword;
  }
  return null;
}

/// Rebuilds the credentials used to actually open a remembered file. Cloud
/// vaults reopen with the stored master password (writable); everything else
/// uses the remembered (transformed) credentials directly.
Credentials writableRememberedCredentials(RememberedUnlockData data) {
  final masterPassword = data.masterPassword;
  if (masterPassword != null && masterPassword.isNotEmpty) {
    return Credentials.composite(
      ProtectedValue.fromString(masterPassword),
      null,
    );
  }
  return data.credentials;
}

/// Publishes a master password recovered from the remembered/quick-unlock
/// store into the shared app/CLI session keyring, so reopening the vault
/// without typing (biometric / remembered unlock) still leaves the CLI
/// unlocked on this machine until it reboots. No-op when the store never
/// carried the plaintext password (local vaults unlocked without one).
void publishSharedUnlock(String? masterPassword) {
  if (masterPassword != null && masterPassword.isNotEmpty) {
    SessionStore.save(masterPassword);
  }
}

/// Returns the dedicated SSH key group in [file], creating it when missing.
///
/// The group always uses the stable canonical storage name
/// ([BuiltInGroupNames.sshKeys]); UI labels are localized separately, so
/// switching the app language never creates a second group.
KdbxGroup ensureSshKeyGroup(KdbxFile file) {
  final root = file.body.rootGroup;
  KdbxGroup? candidate;
  for (final group in root.groups) {
    if (isSshKeysGroupStoredName(group.name.get())) {
      candidate = group;
      break;
    }
  }
  if (candidate == null) {
    return file.createGroup(parent: root, name: BuiltInGroupNames.sshKeys);
  }
  if (candidate.name.get() != BuiltInGroupNames.sshKeys) {
    candidate.name.set(BuiltInGroupNames.sshKeys);
  }
  return candidate;
}

class FileExistsException extends KdbxException {
  FileExistsException({
    required this.path,
  });

  final String path;

  @NonNls
  @override
  String toString() {
    return 'FileExistsException{path: $path}';
  }
}

class FileAlreadyOpenException extends KdbxException {
  FileAlreadyOpenException({
    required this.newFileSource,
    required this.newFile,
    required this.openFileSource,
    required this.openFile,
  }) : assert(newFile.body.rootGroup.uuid == openFile.body.rootGroup.uuid);

  FileSource newFileSource;
  KdbxFile newFile;
  FileSource openFileSource;
  KdbxFile openFile;

  @NonNls
  @override
  String toString() {
    final map = {
      'newFileSource': newFileSource.toString(),
      'openFileSource': openFileSource.toString(),
      'uuid': newFile.body.rootGroup.uuid,
      'databaseName': newFile.body.meta.databaseName.get(),
    };
    return 'FileAlreadyOpenException{$map}';
  }
}

/// Biometric (fingerprint / face) quick-unlock store.
///
/// The payload lives in the platform keystore (Android Keystore / iOS
/// Keychain) behind a biometric prompt, but the keystore key itself is *not*
/// invalidated by a reboot. Every entry is therefore stamped with the boot
/// session it was written in ([quickUnlockPayload]) and only reused while that
/// session is still the current one, so a reboot always falls back to the
/// master password.
class QuickUnlockStorage {
  QuickUnlockStorage({
    required this.cloudStorageBloc,
    required this.env,
    required this.analytics,
  });

  final CloudStorageBloc cloudStorageBloc;
  final Env env;
  final Analytics analytics;
  bool? _supported;

  static var debugForceNoBiometricSupport = false;

  /// should only be used if used in non interactive callbacks.
  bool? get supportsBiometricKeystoreAlready => _supported;

  Future<bool> supportsBiometricKeyStore() async {
    if (debugForceNoBiometricSupport) {
      _logger.warning('debugForceNoBiometricSupport enabled.');
      return false;
    }
    if (_supported != null) {
      return _supported!;
    }
    final canAuthenticate = await BiometricStorage().canAuthenticate();
    _logger.finer('supportBiometricKeyStore: $canAuthenticate');
    return _supported = (canAuthenticate == CanAuthenticateResponse.success);
  }

  Future<BiometricStorageFile>? _storageFileCached;

  @NonNls
  Future<BiometricStorageFile> _storageFile() =>
      _storageFileCached ??= BiometricStorage().getStorage(
        '${env.storageNamespace ?? ''}QuickUnlock',
        promptInfo: biometricPromptInfo(),
      );

  Future<void> _disableUnavailableBiometricStorage(
    Object error,
    StackTrace stackTrace,
  ) async {
    _supported = false;
    _storageFileCached = null;
    if (UnlockPrefs.fingerprintEnabled.value) {
      await UnlockPrefs.setFingerprintEnabled(false);
    }
    _logger.warning(
      'Biometric storage is unavailable on this build; disabling quick '
      'unlock and falling back to the master password.',
      error,
      stackTrace,
    );
  }

  Future<void> deleteQuickUnlock() async {
    final storageFile = await _storageFile();
    await storageFile.delete();
    await UnlockPrefs.setQuickUnlockBootId(null);
  }

  Future<void> updateQuickUnlockFile(
    Map<FileSource, RememberedUnlockData> fileCredentials,
  ) async {
    if (!(await supportsBiometricKeyStore())) {
      _logger.severe(
        'updateQuickUnlockFile must not be called when biometric store is not supported.',
      );
      return;
    }
    final bootId = await currentBootId();
    final quickUnlockCredentials = fileCredentials.map(
      (key, value) => MapEntry(
        key.uuid,
        quickUnlockPayload(value, bootId: bootId),
      ),
    );
    _logger.fine('Getting storage file.');
    final storage = await _storageFile();
    _logger.fine(
      'got storage, writing credentials.'
      ' ${quickUnlockCredentials.length}',
    );
    try {
      if (quickUnlockCredentials.isEmpty) {
        _logger.fine('Deleting quick unlock.');
        await storage.delete();
        await UnlockPrefs.setQuickUnlockBootId(null);
      } else {
        await storage.write(json.encode(quickUnlockCredentials));
        // Remember which boot session the store belongs to so a reboot can
        // skip the biometric read (and its prompt) entirely.
        await UnlockPrefs.setQuickUnlockBootId(bootId);
      }
    } catch (e, stackTrace) {
      if (_isMissingBiometricEntitlement(e)) {
        await _disableUnavailableBiometricStorage(e, stackTrace);
        return;
      }
      _logger.severe(
        'Error while writing quick unlock credentials.',
        e,
        stackTrace,
      );
      rethrow;
    } finally {
      _logger.finer('all done.');
    }
  }

  Future<Map<FileSource, RememberedUnlockData>> loadQuickUnlockFile(
    AppDataBloc appDataBloc,
  ) async {
    if (!(await supportsBiometricKeyStore())) {
      _logger.fine('Biometric store not supported. no quickunlock.');
      return {};
    }
    final bootId = await currentBootId();
    final storedBootId = UnlockPrefs.quickUnlockBootId.value;
    if (bootId != null && storedBootId != null && storedBootId != bootId) {
      // The device rebooted since quick unlock was stored. Do not even read
      // the biometric store: the fingerprint prompt could not unlock anything,
      // the master password has to be entered again.
      _logger.fine(
        'Quick unlock was stored in an earlier boot session '
        '($storedBootId != $bootId); the master password is required.',
      );
      return {};
    }
    final String? jsonContent;
    try {
      final storage = await _storageFile();
      jsonContent = await storage.read();
    } catch (e, stackTrace) {
      if (_isMissingBiometricEntitlement(e)) {
        await _disableUnavailableBiometricStorage(e, stackTrace);
        return {};
      }
      // Android Keystore key missing/invalidated or biometric storage
      // corrupted after app data clear, biometric enrollment change, etc.
      // Treat it as "no quick unlock" so the user falls back to the master
      // password screen instead of an uncaught "Unexpected error" dialog.
      _logger.warning(
        'Unable to read quick unlock storage (keystore key missing or '
        'biometric data corrupted). Falling back to manual unlock.',
        e,
        stackTrace,
      );
      // Try to clean up stale quick unlock state so we don't keep retrying.
      try {
        await deleteQuickUnlock();
      } catch (deleteError, deleteStackTrace) {
        _logger.fine(
          'Ignoring error while deleting corrupt quick unlock data.',
          deleteError,
          deleteStackTrace,
        );
      }
      return {};
    }
    if (jsonContent == null) {
      _logger.finer('No quick unlock available.');
      return {};
    }
    final map = json.decode(jsonContent) as Map<String, dynamic>;
    final appData = await appDataBloc.store.load();
    return Map.fromEntries(
      map.entries.map((entry) {
        final file = appData.recentFileByUuid(entry.key);
        if (file == null) {
          return null;
        }
        // Second line of defense: even when the cached boot id above is
        // missing (e.g. upgraded from a build without it) the payload itself
        // decides whether the entry may be reused in this boot session.
        final raw = entry.value;
        final entryBootId = raw is Map<String, dynamic> ? raw['bootId'] : null;
        if (!isQuickUnlockEntryUsable(
          entryBootId: entryBootId,
          currentBootId: bootId,
        )) {
          _logger.fine(
            'Ignoring quick unlock entry ${entry.key}: '
            'it was stored in an earlier boot session.',
          );
          return null;
        }
        try {
          final source = file.toFileSource(cloudStorageBloc);
          Uint8List? vaultKey;
          Credentials credentials;
          if (raw is String) {
            // Legacy formats: plain base64 composite hash, or (broken early
            // cloud entries) a JSON-encoded {hash, vaultKey} map.
            try {
              credentials = HashCredentials(base64.decode(raw));
            } on FormatException {
              final decoded = json.decode(raw) as Map<String, dynamic>;
              credentials = HashCredentials(
                base64.decode(decoded['hash'] as String),
              );
              final storedVaultKey = decoded['vaultKey'];
              if (storedVaultKey is String) {
                vaultKey = Uint8List.fromList(
                  base64.decode(storedVaultKey),
                );
              }
            }
            if (source is FileSourceopenvalutCloud) {
              source.credentials = credentials;
            }
          } else if (raw is Map<String, dynamic>) {
            credentials = HashCredentials(
              base64.decode(raw['hash'] as String),
            );
            final storedVaultKey = raw['vaultKey'];
            if (storedVaultKey is String) {
              vaultKey = Uint8List.fromList(base64.decode(storedVaultKey));
            }
            String? masterPassword;
            final storedMasterPassword = raw['masterPassword'];
            if (storedMasterPassword is String) {
              masterPassword = utf8.decode(
                base64.decode(storedMasterPassword),
              );
            }
            if (source is FileSourceopenvalutCloud && masterPassword != null) {
              source.masterPassword = masterPassword;
            }
            if (source is FileSourceopenvalutCloud) {
              // Quick-unlock reopens with these remembered credentials; the
              // row-level sync needs them to re-parse and reconstruct.
              source.credentials = credentials;
            }
            if (source is FileSourceopenvalutCloud && vaultKey != null) {
              // Without this the row store cannot be decrypted on cold start:
              // the JSON map payload stores the vault key, but only the
              // legacy string payload propagated it back to the source.
              source.rememberedVaultKey = vaultKey;
            }
            return MapEntry(
              source,
              RememberedUnlockData(
                credentials: credentials,
                vaultKey: vaultKey,
                masterPassword: masterPassword,
              ),
            );
          } else {
            return null;
          }
          if (source is FileSourceopenvalutCloud && vaultKey != null) {
            source.rememberedVaultKey = vaultKey;
          }
          return MapEntry(
            source,
            RememberedUnlockData(
              credentials: credentials,
              vaultKey: vaultKey,
            ),
          );
        } catch (e, stackTrace) {
          // e.g. OpenValut Cloud vaults that cannot be rebuilt without an
          // active session; drop them instead of breaking quick unlock.
          _logger.warning(
            'Unable to rebuild file source for quick unlock entry '
            '${entry.key}. Dropping it.',
            e,
            stackTrace,
          );
          return null;
        }
      }).whereNotNull(),
    );
  }
}

/// Stores the composite credentials of recently unlocked files without a
/// biometric prompt, so the master password only has to be entered once
/// within the configured grace period (default 30 days).
///
/// The payload is stored in the platform's encrypted store (Android Keystore /
/// iOS Keychain / macOS Keychain / Linux Secret Service) but without an
/// authentication gate. When fingerprint unlock is enabled the biometric
/// gate is provided by [QuickUnlockStorage] instead; this store then simply
/// covers the "no password for N days" case.
/// One remembered-unlock entry: the KDBX credentials plus (for OpenValut Cloud
/// vaults) the 32-byte vault key needed to decrypt the server-side blob.
class RememberedUnlockData {
  RememberedUnlockData({
    required this.credentials,
    this.vaultKey,
    this.masterPassword,
  });

  final Credentials credentials;
  final Uint8List? vaultKey;

  /// OpenValut Cloud vaults also store the master password (in the encrypted
  /// keyring, same boot session only) so the file can be reopened writable:
  /// a TransformedKeyCredentials file is read-only in kdbx.
  final String? masterPassword;
}

class RememberedUnlockStorage {
  RememberedUnlockStorage({required this.env});

  final Env env;

  Future<BiometricStorageFile>? _storageFileCached;

  @NonNls
  Future<BiometricStorageFile> _storageFile() =>
      _storageFileCached ??= BiometricStorage().getStorage(
        '${env.storageNamespace ?? ''}RememberedUnlock',
        options: StorageFileInitOptions(authenticationRequired: false),
      );

  /// How often the credential store read is attempted before the store is
  /// treated as unreadable.
  static const _readAttempts = 3;

  /// Delay between two read attempts.
  static const _readRetryDelay = Duration(milliseconds: 80);

  /// Reads the remembered unlock store.
  ///
  /// The Windows credential manager occasionally fails a `CredRead` with a
  /// bogus error code; `biometric_storage` reports that as "no credential",
  /// which used to look like "nothing was remembered" and silently downgraded
  /// the next start to the master password (no PIN / system-password prompt).
  /// Retrying a few times recovers the transient case and costs nothing when
  /// the store really is empty.
  Future<Map<String, dynamic>> _read(BiometricStorageFile storage) async {
    Object? lastError;
    StackTrace? lastStackTrace;
    for (var attempt = 1; attempt <= _readAttempts; attempt++) {
      try {
        final jsonContent = await storage.read();
        if (jsonContent == null) {
          if (attempt < _readAttempts) {
            _logger.finer(
              'Remembered unlock store read returned nothing '
              '(attempt $attempt of $_readAttempts).',
            );
            await Future<void>.delayed(_readRetryDelay);
            continue;
          }
          _logger.finer(
            'Remembered unlock store is empty after $_readAttempts attempts.',
          );
          return {};
        }
        if (attempt > 1) {
          _logger.fine(
            'Remembered unlock store readable again after $attempt attempts.',
          );
        }
        try {
          return json.decode(jsonContent) as Map<String, dynamic>;
        } catch (e, stackTrace) {
          _logger.warning(
            'Unable to decode remembered unlock data.',
            e,
            stackTrace,
          );
          return {};
        }
      } catch (e, stackTrace) {
        lastError = e;
        lastStackTrace = stackTrace;
        if (attempt < _readAttempts) {
          _logger.finer(
            'Reading the remembered unlock store failed '
            '(attempt $attempt of $_readAttempts); retrying.',
          );
          await Future<void>.delayed(_readRetryDelay);
        }
      }
    }
    _logger.warning(
      'Unable to read the remembered unlock store after $_readAttempts '
      'attempts; the master password is required.',
      lastError,
      lastStackTrace,
    );
    return {};
  }

  /// Saves (or refreshes) the credentials for [fileCredentials] and stamps
  /// them with [savedAt], which starts the grace period.
  Future<void> save(
    Map<FileSource, RememberedUnlockData> fileCredentials, {
    required DateTime savedAt,
  }) async {
    if (fileCredentials.isEmpty) {
      return;
    }
    final bootId = await currentBootId();
    final storage = await _storageFile();
    final existing = await _read(storage);
    existing.addAll(
      fileCredentials.map(
        (key, value) => MapEntry(
          key.uuid,
          rememberedUnlockPayload(
            value.credentials,
            savedAt,
            bootId,
            vaultKey: value.vaultKey,
            masterPassword: value.masterPassword,
          ),
        ),
      ),
    );
    await storage.write(json.encode(existing));
  }

  /// Returns the credentials that are still inside the remember period.
  /// Expired or unknown entries are dropped; when nothing is left the whole
  /// store is deleted.
  Future<Map<FileSource, RememberedUnlockData>> load({
    required CloudStorageBloc cloudStorageBloc,
    required AppDataBloc appDataBloc,
    required int rememberDays,
  }) async {
    if (rememberDays <= 0) {
      return {};
    }
    final storage = await _storageFile();
    final data = await _read(storage);
    if (data.isEmpty) {
      return {};
    }

    final appData = await appDataBloc.store.load();
    final now = clock.now().millisecondsSinceEpoch;
    final maxAge = Duration(days: rememberDays).inMilliseconds;
    final bootId = await currentBootId();
    final keep = <String, dynamic>{};
    final result = <FileSource, RememberedUnlockData>{};
    var dropped = false;
    for (final entry in data.entries) {
      final value = entry.value;
      final savedAt = value is Map<String, dynamic> ? value['savedAt'] : null;
      final entryBootId = value is Map<String, dynamic>
          ? value['bootId']
          : null;
      final file = appData.recentFileByUuid(entry.key);
      if (value is! Map<String, dynamic> ||
          savedAt is! int ||
          file == null ||
          !isRememberedUnlockEntryUsable(
            savedAt: DateTime.fromMillisecondsSinceEpoch(savedAt),
            now: DateTime.fromMillisecondsSinceEpoch(now),
            maxAge: Duration(milliseconds: maxAge),
            entryBootId: entryBootId,
            currentBootId: bootId,
          )) {
        _logger.finer('Dropping remembered unlock entry ${entry.key}.');
        dropped = true;
        continue;
      }
      final data = rememberedUnlockDataFromPayload(value);
      if (data == null) {
        _logger.finer(
          'Dropping unreadable remembered unlock entry ${entry.key}.',
        );
        dropped = true;
        continue;
      }
      keep[entry.key] = value;
      result[file.toFileSource(cloudStorageBloc)] = data;
    }
    if (dropped) {
      if (keep.isEmpty) {
        await storage.delete();
      } else {
        await storage.write(json.encode(keep));
      }
    }
    return result;
  }

  /// Removes a single entry (e.g. when its transformed key went stale because
  /// the file was saved elsewhere).
  Future<void> remove(FileSource fileSource) async {
    final storage = await _storageFile();
    final data = await _read(storage);
    if (data.remove(fileSource.uuid) != null) {
      await storage.write(json.encode(data));
    }
  }

  /// Refreshes a single entry after a save rotated the KDF salt, so the
  /// stored transformed key stays current and the next reopen skips Argon2.
  Future<void> updateEntry(
    FileSource fileSource,
    RememberedUnlockData entry, {
    required DateTime savedAt,
  }) async {
    final bootId = await currentBootId();
    final storage = await _storageFile();
    final stored = await _read(storage);
    stored[fileSource.uuid] = rememberedUnlockPayload(
      entry.credentials,
      savedAt,
      bootId,
      vaultKey: entry.vaultKey,
      masterPassword: entry.masterPassword,
    );
    await storage.write(json.encode(stored));
  }

  Future<void> delete() async {
    final storage = await _storageFile();
    await storage.delete();
  }
}

/// Whether a remembered-unlock entry may still be reused.
///
/// Two conditions: the master password was entered within [maxAge], and —
/// when the platform exposes a boot id — the entry was recorded in the same
/// boot session. The boot check is what makes a reboot require the master
/// password again instead of silently reopening via the remembered store.
bool isRememberedUnlockEntryUsable({
  required DateTime savedAt,
  required DateTime now,
  required Duration maxAge,
  required Object? entryBootId,
  required String? currentBootId,
}) {
  if (now.difference(savedAt) > maxAge) {
    return false;
  }
  if (currentBootId != null && entryBootId != currentBootId) {
    return false;
  }
  return true;
}

/// Whether a biometric quick-unlock entry may still be reused.
///
/// Quick unlock is bound to one boot session: the platform keystore key
/// (Android Keystore / iOS Keychain) survives a restart, so without this check
/// a reboot would still let a fingerprint — or the stored credentials behind
/// it — reopen the vault. When the platform exposes no boot id the check is
/// skipped, matching [isRememberedUnlockEntryUsable].
bool isQuickUnlockEntryUsable({
  required Object? entryBootId,
  required String? currentBootId,
}) {
  if (currentBootId == null) {
    return true;
  }
  return entryBootId == currentBootId;
}

/// Serializes one biometric quick-unlock entry.
///
/// The payload is the same shape as the remembered-unlock payload, plus the
/// boot id it was written in (see [isQuickUnlockEntryUsable]).
Map<String, dynamic> quickUnlockPayload(
  RememberedUnlockData value, {
  required String? bootId,
}) =>
    {
      'hash': base64.encode(value.credentials.getHash()),
      if (value.vaultKey != null) 'vaultKey': base64.encode(value.vaultKey!),
      if (value.masterPassword != null)
        'masterPassword': base64.encode(utf8.encode(value.masterPassword!)),
      'bootId': ?bootId,
    };

/// Serializes one remembered-unlock entry.
///
/// KDBX4 files store the post-KDF [TransformedKeyCredentials], so reopening
/// skips Argon2 entirely (the master password only has to be entered once,
/// and the "正在解锁 / preparing" pause disappears). KDBX3 has no
/// transformed key and falls back to the composite hash, which re-runs the
/// KDF.
Map<String, dynamic> rememberedUnlockPayload(
  Credentials credentials,
  DateTime savedAt,
  String? bootId, {
  Uint8List? vaultKey,
  String? masterPassword,
}) {
  final Map<String, dynamic> payload;
  if (credentials is TransformedKeyCredentials) {
    payload = {
      'type': 'transformed',
      'transformedKey': base64.encode(credentials.transformedKey),
      'fingerprint': credentials.kdfFingerprint,
      'savedAt': savedAt.millisecondsSinceEpoch,
      // The entry is only reusable while the machine keeps running; after
      // a reboot the master password has to be entered again.
      'bootId': ?bootId,
    };
  } else {
    payload = {
      'type': 'composite',
      'hash': base64.encode(credentials.getHash()),
      'savedAt': savedAt.millisecondsSinceEpoch,
      'bootId': ?bootId,
    };
  }
  if (vaultKey != null) {
    payload['vaultKey'] = base64.encode(vaultKey);
  }
  if (masterPassword != null) {
    payload['masterPassword'] = base64.encode(
      utf8.encode(masterPassword),
    );
  }
  return payload;
}

/// Rebuilds [Credentials] from a stored payload, or null when the payload is
/// corrupt. Entries saved before the transformed-key format (no `type`) are
/// treated as composite hashes.
Credentials? rememberedCredentialsFromPayload(Map<String, dynamic> value) {
  final type = value['type'];
  if (type == 'transformed') {
    final transformedKey = value['transformedKey'];
    final fingerprint = value['fingerprint'];
    if (transformedKey is String && fingerprint is String) {
      return TransformedKeyCredentials(
        transformedKey: Uint8List.fromList(base64.decode(transformedKey)),
        kdfFingerprint: fingerprint,
      );
    }
    return null;
  }
  final hash = value['hash'];
  if (hash is String) {
    return Credentials.fromHash(base64.decode(hash));
  }
  return null;
}

/// Rebuilds a [RememberedUnlockData] from a stored payload, including the
/// optional OpenValut Cloud vault key.
RememberedUnlockData? rememberedUnlockDataFromPayload(
  Map<String, dynamic> value,
) {
  final credentials = rememberedCredentialsFromPayload(value);
  if (credentials == null) {
    return null;
  }
  Uint8List? vaultKey;
  final storedVaultKey = value['vaultKey'];
  if (storedVaultKey is String) {
    try {
      vaultKey = Uint8List.fromList(base64.decode(storedVaultKey));
    } catch (e, stackTrace) {
      _logger.warning(
        'Unable to decode remembered vault key.',
        e,
        stackTrace,
      );
      return null;
    }
  }
  String? masterPassword;
  final storedMasterPassword = value['masterPassword'];
  if (storedMasterPassword is String) {
    try {
      masterPassword = utf8.decode(base64.decode(storedMasterPassword));
    } catch (e, stackTrace) {
      _logger.warning(
        'Unable to decode remembered master password.',
        e,
        stackTrace,
      );
      return null;
    }
  }
  return RememberedUnlockData(
    credentials: credentials,
    vaultKey: vaultKey,
    masterPassword: masterPassword,
  );
}

/// response to [KdbxBloc.readKdbxFile] will either be an exception OR a file.
class ReadFileResponse {
  ReadFileResponse(this.file, this.exception, this.exceptionType);
  final KdbxFile? file;
  final Object? exception;
  final String? exceptionType;
}

class KdbxOpenedFile {
  KdbxOpenedFile({
    required this.fileSource,
    required this.openedFile,
    required this.kdbxFile,
    required this.kdbxFileContent,
    this.rustVault,
  });

  final FileSource fileSource;
  final OpenedFile openedFile;
  final KdbxFile kdbxFile;

  /// Optional Rust-core vault opened in parallel with [kdbxFile].
  ///
  /// Used when [AppConstants.useRustVault] is enabled on Android to route
  /// unlock/entry-listing/save through the Rust implementation while keeping
  /// the Dart object model as the source of truth.
  final RustVault? rustVault;

  /// The file content as the source last saw it: what [kdbxFile] was read
  /// from, and after that whatever the most recent save wrote.
  final FileContent kdbxFileContent;
}

class OpenedKdbxFiles {
  OpenedKdbxFiles(Map<FileSource, KdbxOpenedFile> files)
    : _files = Map.unmodifiable(files);
  final Map<FileSource, KdbxOpenedFile> _files;

  int get length => _files.length;

  //  bool get isNotEmpty => _files.isNotEmpty;

  KdbxOpenedFile? operator [](FileSource? fileSource) => _files[fileSource!];
  Iterable<MapEntry<FileSource, KdbxOpenedFile>> get entries => _files.entries;
  Iterable<KdbxOpenedFile> get values => _files.values;

  bool containsKey(FileSource file) => _files.containsKey(file);

  //  Map<K2, V2> map<K2, V2>(
  //          MapEntry<K2, V2> Function(FileSource key, KdbxOpenedFile value) f) =>
  //      _files.map(f);
}

/// Result information for [KdbxBloc.openFile] method calls.
class OpenFileResult {
  OpenFileResult({
    this.kdbxOpenedFile,
    this.fileContent,
    this.unlockStopwatch,
    this.loadStopwatch,
  });
  final KdbxOpenedFile? kdbxOpenedFile;
  final FileContent? fileContent;
  final Stopwatch? unlockStopwatch;
  final Stopwatch? loadStopwatch;
}

abstract class KdbxBlocDelegate {
  void conflictMerged(FileSource fileSource, KdbxFile file, MergeContext merge);
}

typedef OpenedFileUpdater = void Function(OpenedFileBuilder b);

class KdbxBloc {
  KdbxBloc({
    required this.env,
    required this.appDataBloc,
    required this.analytics,
    required this.cloudStorageBloc,
  }) : quickUnlockStorage = QuickUnlockStorage(
         cloudStorageBloc: cloudStorageBloc,
         env: env,
         analytics: analytics,
       ),
       rememberedUnlockStorage = RememberedUnlockStorage(env: env) {
    if (OpenValutPlatform.isWeb) {
      KdbxFormat.dartWebWorkaround = true;
    }
    _openedFiles
        .map(
          (value) => Map.fromEntries(
            value.entries.map(
              (entry) => MapEntry(entry.value.kdbxFile, entry.value),
            ),
          ),
        )
        .listen((data) => _openedFilesByKdbxFile = data);
  }

  final Env env;
  final AppDataBloc appDataBloc;
  final Analytics analytics;
  final CloudStorageBloc cloudStorageBloc;
  final QuickUnlockStorage quickUnlockStorage;
  final RememberedUnlockStorage rememberedUnlockStorage;

  late final KdbxFormat kdbxFormat = KdbxFormat(FlutterArgon2());
  KdbxBlocDelegate? delegate;

  final _openedFiles = BehaviorSubject<OpenedKdbxFiles>.seeded(
    OpenedKdbxFiles({}),
  );
  late Map<KdbxFile, KdbxOpenedFile> _openedFilesByKdbxFile;
  final _openedFilesQuickUnlock = <FileSource>{};

  // Auto-save state.
  final _autoSaveSubscriptions = <KdbxFile, StreamSubscription<void>>{};
  final _autoSavePending = <KdbxFile>{};
  final _autoSaveInProgress = <KdbxFile>{};

  // Freshly created entries that the user has not explicitly saved yet.
  // While any are pending, the auto-save must not persist them, otherwise a
  // blank/untitled entry created via the "+" button would be uploaded to the
  // server before the user hits Save. They are cleared when the user saves
  // the file or discards the never-saved entry.
  final _unsavedNewEntries = <KdbxFile, Set<KdbxEntry>>{};

  // Auto-sync state for OpenValut Cloud vaults (multi-device).
  Timer? _cloudSyncTimer;
  final _cloudSyncedUpdatedAt = <String, int?>{};
  DateTime? _cloudSyncBackoffUntil;

  /// True while the OpenValut Cloud server is unreachable (network down / DNS
  /// failure / timeout). Consumed by the UI to show a persistent banner.
  final ValueNotifier<bool> cloudNetworkError = ValueNotifier(false);

  Future<int>? _quickUnlockCheckRunning;

  Iterable<MapEntry<FileSource, KdbxFile>> get openedFilesWithSources =>
      _openedFiles.value.entries.map(
        (entry) => MapEntry(entry.key, entry.value.kdbxFile),
      );

  OpenedKdbxFiles get openedFiles => _openedFiles.value;
  List<KdbxFile> get openedFilesKdbx =>
      _openedFiles.value.values.map((value) => value.kdbxFile).toList();
  ValueStream<OpenedKdbxFiles> get openedFilesChanged => _openedFiles.stream;

  void dispose() {
    _cloudSyncTimer?.cancel();
    for (final file in _openedFiles.value.values) {
      _stopAutoSave(file.kdbxFile);
      file.rustVault?.close();
    }
    _openedFiles.close();
    //    super.dispose();
  }

  Future<KdbxOpenedFile> updateOpenedFile(
    KdbxOpenedFile file,
    OpenedFileUpdater updater,
  ) async {
    final updatedFile = (file.openedFile.toBuilder()..update(updater)).build();
    await appDataBloc.update((b, data) {
      b.previousFiles.map((f) {
        if (!f.isSameFileAs(file.openedFile)) {
          return f;
        }
        //          return (f.toBuilder()..update(updater)).build();
        return updatedFile;
      });
    });
    final newFile = KdbxOpenedFile(
      fileSource: file.fileSource,
      openedFile: updatedFile,
      kdbxFile: file.kdbxFile,
      kdbxFileContent: file.kdbxFileContent,
      rustVault: file.rustVault,
    );
    _openedFiles.add(
      OpenedKdbxFiles({
        ..._openedFiles.value._files,
        file.fileSource: newFile,
      }),
    );
    _logger.info('new values: ${_openedFiles.value}');
    return newFile;
  }

  Stream<OpenFileResult> openFile(
    FileSource file,
    Credentials credentials, {
    bool addToQuickUnlock = false,
  }) async* {
    Uint8List? previous;
    late KdbxOpenedFile openedFile;
    await for (final fileContent in file.content()) {
      _logger.finer('$file got from ${fileContent.source}');
      final loadStopwatch = Stopwatch()..start();
      if (previous != null) {
        if (ByteUtils.eq(previous, fileContent.content)) {
          _logger.finer('$file: No changes detected. Nothing to do.');
          continue;
        } else {
          if (openedFile.kdbxFile.isDirty) {
            // ooooopsie.
            throw StateError(
              'File was changed locally while '
              'loading new file from remote storage.',
            );
          }
        }
      }
      previous = fileContent.content;
      loadStopwatch.stop();
      final unlockStopwatch = Stopwatch()..start();
      openedFile = await _openFileContent(
        file,
        credentials,
        fileContent,
        addToQuickUnlock,
      );
      addToQuickUnlock = false;

      yield OpenFileResult(
        kdbxOpenedFile: openedFile,
        fileContent: fileContent,
        unlockStopwatch: unlockStopwatch..stop(),
        loadStopwatch: loadStopwatch,
      );
    }
    _logger.finer('$file: Done.');
  }

  Future<KdbxOpenedFile> _openFileContent(
    FileSource file,
    Credentials credentials,
    FileContent fileContent,
    bool addToQuickUnlock,
  ) async {
    final readArgs = KdbxReadArgs(fileContent.content, credentials);
    //    final kdbxReadFile = await compute(
    //        staticReadKdbxFile, readArgs,
    //        debugLabel: 'readKdbxFile');
    final kdbxReadFile = await readKdbxFile(kdbxFormat, readArgs);
    final kdbxReadFileException = kdbxReadFile.exception;
    if (kdbxReadFileException != null) {
      final mapping = <Type, Exception Function()>{
        KdbxInvalidKeyException: () => KdbxInvalidKeyException(),
        KdbxCorruptedFileException: () => KdbxCorruptedFileException(''),
        KdbxTransformedKeyStaleException: () =>
            KdbxTransformedKeyStaleException(expected: '', actual: ''),
      }.map((key, value) => MapEntry(key.toString(), value));
      final exception = mapping[kdbxReadFile.exceptionType!];
      if (exception != null) {
        throw exception();
      }
      throw kdbxReadFileException;
    }
    final kdbxFile = kdbxReadFile.file!;

    // Optionally open the same vault through the Rust core on Android.
    // This validates that the Rust implementation can unlock the file and
    // keeps a native handle ready for entry-listing/save paths.
    RustVault? rustVault;
    if (AppConstants.useRustVault && OpenValutPlatform.isAndroid) {
      try {
        final transformed = kdbxFile.transformedKeyCredentials;
        if (transformed != null) {
          rustVault = RustVault.openWithTransformedKey(
            bytes: fileContent.content,
            transformedKey: transformed.transformedKey,
          );
          _logger.fine('Opened Rust vault for ${file.displayName}.');
        } else {
          _logger.fine(
            'Skipping Rust vault for ${file.displayName}: '
            'no transformed key available (KDBX3?).',
          );
        }
      } catch (e, stackTrace) {
        _logger.warning(
          'Rust vault unlock failed for ${file.displayName}; '
          'falling back to Dart kdbx.',
          e,
          stackTrace,
        );
      }
    }

    // make sure kdbxFile is not already opened with another FileSource.
    final openedUuid = kdbxFile.body.rootGroup.uuid;
    for (final openedFile in _openedFiles.value.values) {
      if (openedFile.kdbxFile.body.rootGroup.uuid == openedUuid &&
          openedFile.fileSource != file) {
        throw FileAlreadyOpenException(
          newFileSource: file,
          newFile: kdbxFile,
          openFileSource: openedFile.fileSource,
          openFile: openedFile.kdbxFile,
        );
      }
    }

    final openedFile = await appDataBloc.openedFile(
      file,
      name: kdbxFile.body.meta.databaseName.get(),
      defaultColor: _defaultNextColor(),
    );
    final kdbxOpenedFile = KdbxOpenedFile(
      fileSource: file,
      openedFile: openedFile,
      kdbxFile: kdbxFile,
      kdbxFileContent: fileContent,
      rustVault: rustVault,
    );
    _cloudSyncedUpdatedAt[file.uuid] =
        fileContent.metadata?['updatedAt'] as int?;
    _openedFiles.add(
      OpenedKdbxFiles({
        ..._openedFiles.value._files,
        file: kdbxOpenedFile,
      }),
    );
    _startAutoSave(kdbxOpenedFile);
    migrateLegacyOtpFieldsInFile(kdbxOpenedFile.kdbxFile);
    _ensureCloudSyncTimer();

    if (addToQuickUnlock) {
      _openedFilesQuickUnlock.add(file);
      _logger.fine('adding file to quick unlock.');
      await _updateQuickUnlockStore();
    }
    analytics.events.trackOpenFile(type: file.typeDebug);
    analytics.events.trackOpenFile2(
      generator: kdbxFile.body.meta.generator.get() ?? 'NULL',
      version: '${kdbxFile.header.version}',
    );

    return kdbxOpenedFile;
  }

  /// Keeps a background poll running while any OpenValut Cloud vault is open,
  /// so changes made on other devices get picked up automatically.
  void _ensureCloudSyncTimer() {
    final hasCloud = _openedFiles.value.entries.any(
      (entry) => entry.key is FileSourceopenvalutCloud,
    );
    if (hasCloud && _cloudSyncTimer == null) {
      _logger.fine('Starting cloud auto-sync timer.');
      _cloudSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        unawaited(reloadCloudVaults());
      });
    } else if (!hasCloud && _cloudSyncTimer != null) {
      _logger.fine('Stopping cloud auto-sync timer.');
      _cloudSyncTimer!.cancel();
      _cloudSyncTimer = null;
    }
  }

  /// Pulls the latest blob for every open cloud vault and, when the server
  /// changed and there are no unsaved local edits, replaces the open file so
  /// the new entries are visible without reopening the vault.
  Future<void> reloadCloudVaults() async {
    if (_cloudSyncBackoffUntil != null &&
        clock.now().isBefore(_cloudSyncBackoffUntil!)) {
      // Network was down recently; stop hammering the server (e.g. when the
      // phone is outside the LAN).
      return;
    }
    var networkError = false;
    for (final entry in _openedFiles.value.entries.toList()) {
      final source = entry.key;
      if (source is! FileSourceopenvalutCloud) {
        continue;
      }
      final opened = entry.value;
      if (opened.kdbxFile.dirtyObjects.isNotEmpty) {
        // Local edits are pending; do not clobber them.
        continue;
      }
      try {
        // Cheap check first: only download the full blob when the server
        // actually changed.
        if (!await source.hasServerUpdate()) {
          continue;
        }
        final content = await source.content(updateCache: false).last;
        final updatedAt = content.metadata?['updatedAt'] as int?;
        if (updatedAt != null &&
            updatedAt == _cloudSyncedUpdatedAt[source.uuid]) {
          continue;
        }
        final newFile = await kdbxFormat.read(
          content.content,
          opened.kdbxFile.credentials,
        );
        _stopAutoSave(opened.kdbxFile);
        opened.kdbxFile.dispose();
        opened.rustVault?.close();
        _cloudSyncedUpdatedAt[source.uuid] = updatedAt;
        final newOpened = KdbxOpenedFile(
          fileSource: source,
          openedFile: opened.openedFile,
          kdbxFile: newFile,
          kdbxFileContent: content,
        );
        _openedFiles.add(
          OpenedKdbxFiles({
            ..._openedFiles.value._files,
            source: newOpened,
          }),
        );
        _startAutoSave(newOpened);
        _logger.info(
          'Cloud vault ${source.displayName} auto-synced from server.',
        );
      } catch (e, stackTrace) {
        if (e is openvalutApiException && e.statusCode == 0) {
          networkError = true;
          _logger.warning(
            'Cloud auto-sync network error for ${source.displayName}; '
            'backing off.',
            e,
            stackTrace,
          );
        } else {
          _logger.warning(
            'Cloud auto-sync failed for ${source.displayName}.',
            e,
            stackTrace,
          );
        }
      }
    }
    if (networkError) {
      _cloudSyncBackoffUntil = clock.now().add(const Duration(minutes: 5));
      if (!cloudNetworkError.value) {
        cloudNetworkError.value = true;
      }
      _logger.info(
        'Cloud auto-sync paused for 5 minutes after network errors.',
      );
    } else if (_cloudSyncBackoffUntil != null) {
      _cloudSyncBackoffUntil = null;
      if (cloudNetworkError.value) {
        cloudNetworkError.value = false;
      }
    }
  }

  /// Replaces an already-opened vault identified by [id] with the given [bytes]
  /// and [credentials], then saves it to its source. Used by the Chrome
  /// extension host bridge when the extension edits a vault locally.
  Future<void> replaceOpenedVaultFromBytes({
    required String id,
    required Uint8List bytes,
    required TransformedKeyCredentials credentials,
  }) async {
    FileSource? source;
    KdbxOpenedFile? opened;
    for (final entry in _openedFiles.value.entries) {
      if (entry.key.uuid == id || entry.key.displayName == id) {
        source = entry.key;
        opened = entry.value;
        break;
      }
    }
    if (source == null || opened == null) {
      throw StateError('Vault $id is not open.');
    }
    final newFile = await kdbxFormat.read(bytes, credentials);
    _stopAutoSave(opened.kdbxFile);
    opened.kdbxFile.dispose();
    opened.rustVault?.close();
    final newOpened = KdbxOpenedFile(
      fileSource: source,
      openedFile: opened.openedFile,
      kdbxFile: newFile,
      kdbxFileContent: FileContent(
        bytes,
        opened.kdbxFileContent.metadata,
        FileContentSource.memoryCache,
      ),
    );
    _openedFiles.add(
      OpenedKdbxFiles({
        ..._openedFiles.value._files,
        source: newOpened,
      }),
    );
    _startAutoSave(newOpened);
    await saveFile(newFile);

    // Saving with a transformed key leaves the file read-only. Re-open it with
    // writable remembered credentials so the app and the extension can keep
    // editing it without asking for the master password again.
    await reopenWithWritableCredentials(source, newOpened);
  }

  /// Tries to re-open [opened] with writable credentials remembered for
  /// [source]. If no writable credentials are available the file is left as-is.
  Future<void> reopenWithWritableCredentials(
    FileSource source,
    KdbxOpenedFile opened,
  ) async {
    final writable = await writableCredentialsFor(source);
    if (writable == null) {
      return;
    }
    try {
      final bytes = opened.kdbxFileContent.content;
      final writableFile = await kdbxFormat.read(bytes, writable);
      _stopAutoSave(opened.kdbxFile);
      opened.kdbxFile.dispose();
      opened.rustVault?.close();
      final writableOpened = KdbxOpenedFile(
        fileSource: source,
        openedFile: opened.openedFile,
        kdbxFile: writableFile,
        kdbxFileContent: opened.kdbxFileContent,
      );
      _openedFiles.add(
        OpenedKdbxFiles({
          ..._openedFiles.value._files,
          source: writableOpened,
        }),
      );
      _startAutoSave(writableOpened);
      _logger.fine(
        'Re-opened ${source.displayName} with writable credentials.',
      );
    } on KdbxTransformedKeyStaleException {
      _logger.info(
        'Remembered key for ${source.displayName} is stale; '
        'keeping transformed.',
      );
    } catch (e, stackTrace) {
      _logger.warning(
        'Unable to re-open ${source.displayName} with writable credentials.',
        e,
        stackTrace,
      );
    }
  }

  /// Returns writable credentials for [fileSource] if they are available in
  /// remembered unlock storage, otherwise returns null.
  Future<Credentials?> writableCredentialsFor(FileSource fileSource) async {
    if (UnlockPrefs.rememberUnlockDays.value <= 0) {
      return null;
    }
    try {
      final unlockFiles = await rememberedUnlockStorage.load(
        cloudStorageBloc: cloudStorageBloc,
        appDataBloc: appDataBloc,
        rememberDays: UnlockPrefs.rememberUnlockDays.value,
      );
      final remembered = unlockFiles[fileSource];
      if (remembered == null) {
        return null;
      }
      final credentials = writableRememberedCredentials(remembered);
      if (credentials is TransformedKeyCredentials) {
        return null;
      }
      return credentials;
    } catch (e, stackTrace) {
      _logger.warning(
        'Unable to read remembered unlock credentials for '
        '${fileSource.displayName}.',
        e,
        stackTrace,
      );
      return null;
    }
  }

  Color? _defaultNextColor() {
    for (final color in OpenValutTheme.defaultColorOrder) {
      if (!openedFiles.values.any(
        (file) => file.openedFile.colorCode == color.toARGB32(),
      )) {
        return color;
      }
    }
    return null;
  }

  /// writes all opened files into secure storage.
  Future<void> _updateQuickUnlockStore({FileSource? ifRequiredFor}) async {
    if (ifRequiredFor != null) {
      if (!_openedFilesQuickUnlock.contains(ifRequiredFor)) {
        return;
      }
    }
    final openedFiles = _openedFiles.value;
    final entries = <FileSource, RememberedUnlockData>{};
    for (final fileSource in _openedFilesQuickUnlock) {
      final openedFile = openedFiles[fileSource];
      if (openedFile == null) {
        _logger.warning(
          'File was closed, but was still listed in quick unlock files.',
        );
        continue;
      }
      entries[fileSource] = RememberedUnlockData(
        credentials: openedFile.kdbxFile.credentials,
        vaultKey: await vaultKeyForRememberStore(fileSource),
        masterPassword: masterPasswordForRememberStore(fileSource),
      );
    }
    await quickUnlockStorage.updateQuickUnlockFile(
      entries,
    );
    if (quickUnlockStorage.supportsBiometricKeystoreAlready == false) {
      _openedFilesQuickUnlock.clear();
    }
  }

  /// Adds [fileSource] with [credentials] to the quick-unlock store.
  ///
  /// Used after the user unlocks a file with the master password while the
  /// fingerprint unlock setting is enabled.
  Future<void> addToQuickUnlock(
    FileSource fileSource,
    Credentials credentials,
  ) async {
    _openedFilesQuickUnlock.add(fileSource);
    _logger.fine('Adding $fileSource to quick unlock via consent dialog.');
    await _updateQuickUnlockStore();
  }

  /// Adds all currently opened files to the biometric quick-unlock store.
  /// Used when the user enables fingerprint unlock in settings.
  Future<void> enableQuickUnlockForOpenedFiles() async {
    final openedFiles = _openedFiles.value;
    for (final entry in openedFiles.entries) {
      _openedFilesQuickUnlock.add(entry.key);
    }
    _logger.fine(
      'Enabling quick unlock for ${openedFiles.length} opened file(s).',
    );
    await _updateQuickUnlockStore();
  }

  /// Removes every file from the biometric quick-unlock store. Used when the
  /// user disables fingerprint unlock in settings.
  Future<void> disableQuickUnlock() async {
    _openedFilesQuickUnlock.clear();
    await quickUnlockStorage.updateQuickUnlockFile({});
  }

  /// Stores the credentials of [fileCredentials] in the time-limited
  /// remember store, unless the feature is disabled.
  ///
  /// The original composite credentials are stored instead of the post-KDF
  /// transformed key. That keeps the file writable on reopen (KDBX4 files
  /// opened with [TransformedKeyCredentials] are read-only), at the cost of
  /// re-running Argon2 when the file is unlocked again.
  Future<void> addToRememberedUnlock(
    Map<FileSource, Credentials> fileCredentials,
  ) async {
    if (UnlockPrefs.rememberUnlockDays.value <= 0) {
      return;
    }
    if (fileCredentials.isEmpty) {
      return;
    }
    try {
      final upgraded = <FileSource, RememberedUnlockData>{};
      for (final entry in fileCredentials.entries) {
        upgraded[entry.key] = RememberedUnlockData(
          credentials: entry.value,
          vaultKey: await vaultKeyForRememberStore(entry.key),
          masterPassword: masterPasswordForRememberStore(entry.key),
        );
      }
      await rememberedUnlockStorage.save(
        upgraded,
        savedAt: clock.now().toUtc(),
      );
    } catch (e, stackTrace) {
      // A failing keyring must never block a successful unlock.
      _logger.warning(
        'Unable to save remembered unlock credentials.',
        e,
        stackTrace,
      );
    }
  }

  /// Refreshes the timestamp of the remembered unlock entry for
  /// [fileSource] after a successful save, without downgrading it to a
  /// read-only transformed key.
  ///
  /// Composite credentials stay composite; legacy transformed entries are only
  /// kept when no master password is available to rebuild writable credentials.
  Future<void> _refreshRememberedUnlock(FileSource fileSource) async {
    if (UnlockPrefs.rememberUnlockDays.value <= 0) {
      return;
    }
    try {
      final unlockFiles = await rememberedUnlockStorage.load(
        cloudStorageBloc: cloudStorageBloc,
        appDataBloc: appDataBloc,
        rememberDays: UnlockPrefs.rememberUnlockDays.value,
      );
      final existing = unlockFiles[fileSource];
      if (existing == null) {
        return;
      }

      var credentials = existing.credentials;
      final masterPassword = existing.masterPassword;
      // If we somehow stored a transformed key but still have the master
      // password, rebuild writable composite credentials.
      if (credentials is TransformedKeyCredentials &&
          masterPassword != null &&
          masterPassword.isNotEmpty) {
        credentials = Credentials.composite(
          ProtectedValue.fromString(masterPassword),
          null,
        );
      }

      await rememberedUnlockStorage.updateEntry(
        fileSource,
        RememberedUnlockData(
          credentials: credentials,
          vaultKey: existing.vaultKey,
          masterPassword: masterPassword,
        ),
        savedAt: clock.now().toUtc(),
      );
    } catch (e, stackTrace) {
      _logger.warning(
        'Unable to refresh remembered unlock for '
        '${fileSource.displayName}.',
        e,
        stackTrace,
      );
    }
  }

  /// Clears the time-limited remember store (e.g. when the user closes all
  /// password files).
  Future<void> clearRememberedUnlock() async {
    try {
      await rememberedUnlockStorage.delete();
    } catch (e, stackTrace) {
      _logger.warning(
        'Unable to clear remembered unlock credentials.',
        e,
        stackTrace,
      );
    }
  }

  Future<void> continueLoadInBackground(
    StreamIterator<OpenFileResult> openIt, {
    @NonNls required String debugName,
    required FileSource fileSource,
  }) async {
    try {
      while (await openIt.moveNext()) {
        final r = openIt.current;
        _logger.fine('load:$debugName new data from ${r.fileContent!.source}');
      }
    } catch (e, stackTrace) {
      _logger.severe(
        'load:$debugName error while loading subsequent '
        'data from $fileSource.',
        e,
        stackTrace,
      );
      rethrow;
    }
    _logger.fine('load:$debugName finished.');
  }

  bool _isOpen(FileSource file) => _openedFiles.value.containsKey(file);

  /// Notifies all listeners that the open files changed (entry added, moved
  /// or deleted), forcing password lists and the sidebar to rebuild.
  void refreshOpenedFiles() {
    _openedFiles.add(_openedFiles.value);
  }

  bool hasQuickUnlockOpen() => _openedFilesQuickUnlock.isNotEmpty;

  bool isQuickUnlockFile(FileSource fileSource) =>
      _openedFilesQuickUnlock.contains(fileSource);

  Future<int> reopenQuickUnlock(
    AppLocalizations loc, {
    TaskProgress? progress,
  }) => _quickUnlockCheckRunning ??= (() async {
    var filesOpened = 0;
    var requiresMasterPassword = false;
    if (UnlockPrefs.fingerprintEnabled.value) {
      try {
        _logger.finer('Checking quick unlock.');
        final unlockFiles = await quickUnlockStorage.loadQuickUnlockFile(
          appDataBloc,
        );
        requiresMasterPassword =
            quickUnlockStorage.supportsBiometricKeystoreAlready == false;
        for (final file in unlockFiles.entries.where(
          (entry) =>
              !_isOpen(entry.key) &&
              (entry.key is! FileSourceopenvalutCloud ||
                  entry.value.vaultKey != null ||
                  entry.value.masterPassword != null),
        )) {
          try {
            progress!.progressLabel = loc.openFileProgress(
              file.key.displayName,
              filesOpened + 1,
              unlockFiles.length,
            );
            final open = StreamIterator(
              openFile(
                file.key,
                writableRememberedCredentials(file.value),
              ),
            );
            await open.moveNext();
            filesOpened++;
            publishSharedUnlock(file.value.masterPassword);
            unawaited(
              continueLoadInBackground(
                open,
                debugName:
                    '${file.key.displayName} … (${filesOpened + 1} / ${unlockFiles.length})',
                fileSource: file.key,
              ),
            );
          } catch (e, stackTrace) {
            _logger.severe(
              'Panic, error while trying to open file from '
              'quick unlock. ignoring file for now. ${file.key}',
              e,
              stackTrace,
            );
          }
        }
        analytics.events.trackQuickUnlock(value: filesOpened);
        _openedFilesQuickUnlock.clear();
        _openedFilesQuickUnlock.addAll(unlockFiles.keys);
      } on AuthException catch (e, stackTrace) {
        if (e.code == AuthExceptionCode.userCanceled) {
          _logger.info('User canceled quick unlock.');
        } else {
          _logger.severe('Error during quick unlock.', e, stackTrace);
        }
      } catch (e, stackTrace) {
        // 快速解锁数据损坏或存储异常时不能阻塞打开密码库页面：
        // 丢弃本次尝试，让用户走手动解锁。
        _logger.severe(
          'Quick unlock storage corrupted; skipping this attempt.',
          e,
          stackTrace,
        );
      }
    }
    if (filesOpened == 0 && !requiresMasterPassword) {
      filesOpened = await _reopenRemembered(loc, progress);
    }
    return filesOpened;
  })().whenComplete(() => _quickUnlockCheckRunning = null);

  /// Tries to open [fileSource] with remembered credentials (same boot
  /// session, grace period still valid). On Linux the user first
  /// authenticates with their system password, and on Windows with Windows
  /// Hello (PIN / biometric), mirroring [_reopenRemembered].
  ///
  /// Returns true when the file was opened; false when the master password
  /// has to be entered instead.
  Future<bool> openRememberedFile(FileSource fileSource) async {
    if (UnlockPrefs.rememberUnlockDays.value <= 0) {
      return false;
    }
    Map<FileSource, RememberedUnlockData> unlockFiles;
    try {
      unlockFiles = await rememberedUnlockStorage.load(
        cloudStorageBloc: cloudStorageBloc,
        appDataBloc: appDataBloc,
        rememberDays: UnlockPrefs.rememberUnlockDays.value,
      );
    } catch (e, stackTrace) {
      _logger.warning(
        'Unable to read remembered unlock credentials.',
        e,
        stackTrace,
      );
      return false;
    }
    final remembered = unlockFiles[fileSource];
    if (remembered == null) {
      _logger.finer(
        'No remembered unlock entry for ${fileSource.displayName}; '
        'asking for the master password.',
      );
      return false;
    }
    if (fileSource is FileSourceopenvalutCloud &&
        (remembered.vaultKey == null || remembered.masterPassword == null)) {
      // The master password was never saved for this cloud vault: there is
      // nothing the system password could unlock writably, so skip straight
      // to the master-password screen instead of opening it read-only.
      _logger.fine(
        'No writable remembered credentials for '
        '${fileSource.displayName}; '
        'skipping system password.',
      );
      return false;
    }
    if (fileSource is FileSourceopenvalutCloud) {
      fileSource.rememberedVaultKey = remembered.vaultKey;
      // The row-level sync needs the opening credentials (and the password,
      // when remembered) to re-parse/reconstruct without re-prompting.
      fileSource.credentials = remembered.credentials;
      fileSource.masterPassword = remembered.masterPassword;
    }
    if (!await authenticateForRememberedUnlock()) {
      _logger.fine(
        'User-presence check failed; not opening '
        '${fileSource.displayName} with remembered credentials.',
      );
      return false;
    }
    _logger.fine(
      'User presence confirmed; opening ${fileSource.displayName} with '
      'remembered credentials.',
    );
    try {
      final open = StreamIterator(
        openFile(fileSource, writableRememberedCredentials(remembered)),
      );
      await open.moveNext();
      unawaited(
        continueLoadInBackground(
          open,
          debugName: '${fileSource.displayName} (remembered)',
          fileSource: fileSource,
        ),
      );
      return true;
    } on KdbxTransformedKeyStaleException {
      _logger.info(
        'Remembered key for ${fileSource.displayName} is stale; dropping it.',
      );
      await rememberedUnlockStorage.remove(fileSource);
      return false;
    } catch (e, stackTrace) {
      _logger.severe(
        'Error while opening remembered file ${fileSource.displayName}.',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Reopens files whose master password is still remembered (within the
  /// configured grace period). On desktop Linux the user first has to
  /// authenticate with their system password, and on Windows with Windows
  /// Hello (PIN / biometric); on other platforms the reopen happens without a
  /// prompt (or via the platform's own mechanism).
  Future<int> _reopenRemembered(
    AppLocalizations loc, [
    TaskProgress? progress,
  ]) async {
    final rememberDays = UnlockPrefs.rememberUnlockDays.value;
    if (rememberDays <= 0) {
      return 0;
    }
    Map<FileSource, RememberedUnlockData> unlockFiles;
    try {
      _logger.fine('Checking remembered unlock ($rememberDays days).');
      unlockFiles = await rememberedUnlockStorage.load(
        cloudStorageBloc: cloudStorageBloc,
        appDataBloc: appDataBloc,
        rememberDays: rememberDays,
      );
    } catch (e, stackTrace) {
      _logger.warning(
        'Unable to read remembered unlock credentials.',
        e,
        stackTrace,
      );
      return 0;
    }
    if (unlockFiles.isEmpty) {
      return 0;
    }
    final usable = unlockFiles.entries
        .where(
          (entry) =>
              !_isOpen(entry.key) &&
              (entry.key is! FileSourceopenvalutCloud ||
                  (entry.value.vaultKey != null &&
                      entry.value.masterPassword != null)),
        )
        .toList();
    if (usable.isEmpty) {
      // Nothing can actually be reopened (e.g. cloud vaults whose master
      // password was never saved): don't ask for the system password, go
      // straight to the master-password screen.
      _logger.fine(
        'No usable remembered entries (cloud vault keys or master '
        'passwords missing); '
        'skipping system password.',
      );
      return 0;
    }
    if (!await authenticateForRememberedUnlock()) {
      _logger.fine(
        'User-presence check failed; not reopening remembered files.',
      );
      return 0;
    }
    _logger.fine('User presence confirmed; reopening remembered files.');
    var filesOpened = 0;
    for (final file in usable) {
      try {
        progress!.progressLabel = loc.openFileProgress(
          file.key.displayName,
          filesOpened + 1,
          unlockFiles.length,
        );
        if (file.key is FileSourceopenvalutCloud) {
          final cloud = file.key as FileSourceopenvalutCloud;
          if (file.value.vaultKey != null) {
            _logger.fine(
              'Restoring remembered cloud vault key for '
              '${file.key.displayName}.',
            );
            cloud.rememberedVaultKey = file.value.vaultKey;
          }
          // The row store can only be rebuilt (and written back) when the
          // remembered master password and credentials are restored too —
          // otherwise the reopen fails with "row reconstruction requires
          // credentials" and the user is asked for the master password again.
          cloud.masterPassword = file.value.masterPassword;
          cloud.credentials = file.value.credentials;
        }
        if (file.key is FileSourceopenvalutCloud &&
            file.value.vaultKey == null) {
          _logger.warning(
            'Remembered cloud vault ${file.key.displayName} has no vault '
            'key; falling back to the master password.',
          );
        }
        final open = StreamIterator(
          openFile(file.key, writableRememberedCredentials(file.value)),
        );
        await open.moveNext();
        filesOpened++;
        publishSharedUnlock(file.value.masterPassword);
        unawaited(
          continueLoadInBackground(
            open,
            debugName:
                '${file.key.displayName} … (${filesOpened + 1} / ${unlockFiles.length})',
            fileSource: file.key,
          ),
        );
      } on KdbxTransformedKeyStaleException {
        // The file was saved somewhere else since the key was stored; the
        // remembered key no longer applies. Drop the entry so the user is
        // asked for the master password instead of failing silently.
        _logger.info(
          'Remembered key for ${file.key.displayName} is stale; dropping it.',
        );
        await rememberedUnlockStorage.remove(file.key);
      } catch (e, stackTrace) {
        _logger.severe(
          'Error while trying to open remembered file ${file.key}. '
          'Ignoring file for now.',
          e,
          stackTrace,
        );
      }
    }
    if (filesOpened > 0) {
      _logger.info('Opened $filesOpened file(s) from remembered unlock.');
    }
    return filesOpened;
  }

  Future<void> close(KdbxFile file) async {
    _logger.fine('Close file.');
    await ClipboardAutoClear.clearIfMatches();
    analytics.events.trackCloseFile();
    final openedFile = fileForKdbxFile(file);
    final fileSource = openedFile.fileSource;
    _openedFiles.add(
      OpenedKdbxFiles(Map.from(_openedFiles.value._files)..remove(fileSource)),
    );
    _stopAutoSave(file);
    file.dispose();
    openedFile.rustVault?.close();
    if (_openedFilesQuickUnlock.remove(fileSource)) {
      _logger.fine('file was in quick unlock. need to persist it.');
      await _updateQuickUnlockStore();
    } else {
      _logger.fine('file was not in quick unlock.');
    }
  }

  Future<void> closeAllFiles({required bool clearQuickUnlock}) async {
    _logger.finer('Closing all files, clearing quick unlock.');
    await ClipboardAutoClear.clearIfMatches();
    // Forget the cloud vault master password so the lock screen cannot auto-fill
    // it and silently reopen the vault.
    openvalutCloudSession.instance.clearInMemoryVaultMasterPassword();
    // Drop the shared app/CLI unlock too: locking the app locks the CLI, the
    // same way unlocking either one unlocks the other.
    SessionStore.clear();
    for (final file in _openedFiles.value.values) {
      _stopAutoSave(file.kdbxFile);
      file.kdbxFile.dispose();
      file.rustVault?.close();
    }
    if (clearQuickUnlock) {
      // clear all quick unlock data.
      _openedFilesQuickUnlock.clear();
      await quickUnlockStorage.updateQuickUnlockFile({});
      await rememberedUnlockStorage.delete();
      analytics.events.trackCloseAllFiles(count: _openedFiles.value.length);
    } else {
      analytics.events.trackLockAllFiles(count: _openedFiles.value.length);
    }
    _openedFiles.add(OpenedKdbxFiles({}));
    _ensureCloudSyncTimer();
  }

  void _startAutoSave(KdbxOpenedFile openedFile) {
    final file = openedFile.kdbxFile;
    _stopAutoSave(file);
    // Debounce saves: a KDBX save runs Argon2 (≈1–2 s) plus the upload, and
    // firing it in the middle of an entry-creation animation makes the UI
    // stutter on mobile. Wait until the user pauses, then save once.
    _autoSaveSubscriptions[file] = file.dirtyObjectsChanged
        .debounceTime(const Duration(milliseconds: 1200))
        .listen((_) {
          if (!openedFile.fileSource.supportsWrite) {
            return;
          }
          unawaited(_autoSaveFile(openedFile));
        });
  }

  /// Saves changes to [openedFile] as soon as they happen. If a save is
  /// already uploading, remembers that newer changes arrived and saves them
  /// again as soon as the current upload finishes, so nothing is lost.
  Future<void> _autoSaveFile(KdbxOpenedFile openedFile) async {
    final file = openedFile.kdbxFile;
    if (_autoSaveInProgress.contains(file)) {
      _autoSavePending.add(file);
      return;
    }
    if (file.dirtyObjects.isEmpty) {
      return;
    }
    // If the user has a freshly created entry open that they have not saved
    // yet, do not auto-save: persisting it now would push a blank/untitled
    // entry to the server before they hit Save.
    final pendingNew = _unsavedNewEntries[file];
    if (pendingNew != null && pendingNew.isNotEmpty) {
      _logger.fine(
        'Auto-save skipped: ${pendingNew.length} unsaved new entry(ies).',
      );
      return;
    }
    _autoSaveInProgress.add(file);
    try {
      _logger.fine('Auto-saving ${openedFile.fileSource.displayName}.');
      await saveFile(file, autosave: true);
    } catch (e, stackTrace) {
      _logger.warning('Auto-save failed.', e, stackTrace);
    } finally {
      _autoSaveInProgress.remove(file);
      if (_autoSavePending.remove(file)) {
        unawaited(_autoSaveFile(openedFile));
      }
    }
  }

  void _stopAutoSave(KdbxFile file) {
    _autoSaveSubscriptions.remove(file)?.cancel();
    _autoSavePending.remove(file);
    _unsavedNewEntries.remove(file);
  }

  static Future<ReadFileResponse> staticReadKdbxFile(
    KdbxReadArgs readArgs,
  ) async {
    initIsolate();
    final kdbxFormat = KdbxFormat(FlutterArgon2());
    return readKdbxFile(kdbxFormat, readArgs);
  }

  static Future<ReadFileResponse> readKdbxFile(
    KdbxFormat kdbxFormat,
    KdbxReadArgs readArgs,
  ) async {
    try {
      _logger.finer('reading kdbx file ...');
      final fileContent = readArgs.content;
      final kdbxFile = await kdbxFormat.read(fileContent, readArgs.credentials);
      _logger.finer('done reading');
      return ReadFileResponse(kdbxFile, null, null);
    } catch (e, stackTrace) {
      _logger.warning('Error while reading kdbx file.', e, stackTrace);
      return ReadFileResponse(null, e.toString(), e.runtimeType.toString());
    }
  }

  /// Creates a new file in the application document directory by the given name.
  /// Throws a [FileExistsException] if a file of the same name already exists.
  Future<FileSource> createFile({
    required String password,
    required String databaseName,
    bool openAfterCreate = false,
    CloudStorageSaveTarget? target,
  }) async {
    analytics.events.trackCreateFile();
    assert(!(databaseName.endsWith(AppConstants.kdbxExtension)));
    final credentials = Credentials(ProtectedValue.fromString(password));
    final kdbxFile = kdbxFormat.create(
      credentials,
      databaseName,
      generator: Env.OpenValut,
    );
    final bytes = await _saveFileToBytes<Uint8List>(
      kdbxFile,
      (bytes) async => bytes,
    );
    FileSource fileSource;
    if (target == null) {
      final localSource = await _localFileSourceForDbName(databaseName);
      await localSource.contentWrite(bytes, metadata: <String, dynamic>{});
      fileSource = localSource;
    } else {
      final entity = await target.provider.createEntity(
        CloudStorageSelectorSaveResult(
          target.parent,
          _fileNameForDbName(databaseName),
        ),
        bytes,
      );
      fileSource = entity;
    }
    if (openAfterCreate) {
      await openFile(fileSource, credentials).last;
    }
    return fileSource;
  }

  /// Creates a new KDBX file in memory and returns its serialized bytes
  /// together with the credentials, without writing it to any storage.
  /// Used by the OpenValut Cloud create flow, which encrypts the whole blob
  /// before uploading it.
  Future<({Uint8List bytes, Credentials credentials})> createFileInMemory({
    required String password,
    required String databaseName,
  }) async {
    analytics.events.trackCreateFile();
    assert(!databaseName.endsWith(AppConstants.kdbxExtension));
    final credentials = Credentials(ProtectedValue.fromString(password));
    final kdbxFile = kdbxFormat.create(
      credentials,
      databaseName,
      generator: Env.OpenValut,
    );
    final bytes = await _saveFileToBytes<Uint8List>(
      kdbxFile,
      (bytes) async => bytes,
    );
    return (bytes: bytes, credentials: credentials);
  }

  String _fileNameForDbName(String databaseName) =>
      [databaseName, AppConstants.kdbxExtension].join();

  Future<FileSource> _localFileSourceForDbName(String databaseName) async {
    if (OpenValutPlatform.isWeb) {
      _logger.finer('in web mode - using FileSourceWeb.');
      return FileSourceWeb(
        databaseName: databaseName,
        uuid: AppDataBloc.createUuid(),
      );
    }
    final fileName = _fileNameForDbName(databaseName);
    final appDir = await PathUtils().getAppDocDirectory(ensureCreated: true);
    final localSource = FileSourceLocal(
      appDir.childFile(fileName),
      databaseName: databaseName,
      uuid: AppDataBloc.createUuid(),
    );
    if (localSource.file.existsSync()) {
      throw FileExistsException(path: localSource.file.path);
    }
    return localSource;
  }

  /// Creates a new password entry in [file] (default: the primary kdbx file),
  /// and adds it to [group] (default: main root group).
  KdbxEntry createEntry({
    KdbxFile? file,
    KdbxGroup? group,
  }) {
    file ??= group?.file;
    if (file == null) {
      if (openedFilesKdbx.isEmpty) {
        return throw StateError('No kdbxfiles are open. Specify a file.');
      }
      file = openedFilesKdbx.first;
    }
    final rootGroup = group ?? file.body.rootGroup;
    final entry = KdbxEntry.create(file, rootGroup);
    rootGroup.addEntry(entry);
    // Remember that this entry is brand new and not yet saved by the user, so
    // the auto-save does not persist it before it is explicitly saved or
    // discarded (fixes empty, untitled entries accumulating on the server).
    (_unsavedNewEntries[file] ??= <KdbxEntry>{}).add(entry);
    // Reflect the change in every listener (password list, sidebar counts)
    // immediately; otherwise freshly created/imported entries stay invisible
    // until the vault is reopened or the filter changes.
    _openedFiles.add(_openedFiles.value);
    clearEntryByUuidLookup();
    return entry;
  }

  /// Removes a never-saved entry from the pending set when the user discards
  /// it (e.g. closes the editor without saving). This unblocks the auto-save
  /// so subsequent genuine changes are persisted again.
  void discardNewEntry(KdbxEntry entry) {
    final set = _unsavedNewEntries[entry.file];
    if (set != null) {
      set.remove(entry);
      if (set.isEmpty) {
        _unsavedNewEntries.remove(entry.file);
      }
    }
  }

  @NonNls
  static const _customDataSaveCount = 'codeux.design.openvalut.save';

  /// Wrapper around [file.save()], which adds a bit of meta data
  /// before storing it.
  Future<T> _saveFileToBytes<T>(
    KdbxFile file,
    FileSaveCallback<T> saveBytes,
  ) async {
    final generator = file.body.meta.generator.get();
    if (generator == null || generator.isEmpty) {
      file.body.meta.generator.set(nonNls('OpenValut (save)'));
    }
    final String saveCounter =
        file.body.meta.customData[_customDataSaveCount] ?? nonNls('0');
    final newCounter = (int.tryParse(saveCounter) ?? 0) + 1;
    file.body.meta.customData[_customDataSaveCount] = newCounter.toString();
    analytics.events.trackSaveCount(generator: generator, value: newCounter);
    return await file.saveTo(saveBytes);
  }

  Future<FileContent> saveFile(
    KdbxFile file, {
    FileSource? toFileSource,
    Credentials? updateCredentials,
    bool autosave = false,
  }) async {
    final oldCredentials = file.credentials;
    if (updateCredentials != null) {
      file.credentials = updateCredentials;
    }

    // A direct (non auto-save) save commits every pending new entry: the user
    // (or an import / share / host-bridge flow) explicitly asked to persist
    // the file, so the created entries are no longer "unsaved new".
    if (!autosave) {
      _unsavedNewEntries.remove(file);
    }

    final fileSource = toFileSource ?? fileForKdbxFile(file).fileSource;

    Future<void> updateQuickUnlock() async {
      if (updateCredentials == null) {
        return;
      }
      try {
        await _updateQuickUnlockStore(ifRequiredFor: fileSource);
      } on AuthException catch (e) {
        if (e.code == AuthExceptionCode.userCanceled) {
          // ignore;
          return;
        }
        rethrow;
      }
    }

    try {
      // Hand the file's actual opening credentials to the cloud source so the
      // row-level sync can re-parse the bytes and diff against the rows,
      // regardless of how this session was unlocked.
      if (fileSource is FileSourceopenvalutCloud) {
        fileSource.credentials = file.credentials;
      }
      final ret = await _saveFileToBytes(file, (bytes) async {
        return await fileSource.contentWrite(bytes, metadata: null);
      });
      analytics.events.trackSave(
        type: fileSource.typeDebug,
        value: ret.content.length,
      );
      analytics.trackTiming(
        'saveFileSize',
        ret.content.length,
        category: 'fileSize',
        label: 'save',
      );
      await updateQuickUnlock();
      await _refreshRememberedUnlock(fileSource);
      await _syncOutgoingGroupShares(file, fileSource);
      return ret;
    } on StorageConflictException catch (e, stackTrace) {
      _logger.fine(
        'Got conflict while writing file. Trying to merge.',
        e,
        stackTrace,
      );
      final content = await fileSource.content(updateCache: false).last;
      final remoteFile = await kdbxFormat.read(content.content, oldCredentials);
      final mergeResult = file.merge(remoteFile);
      try {
        _logger.fine('mergeResult: $mergeResult');
        FileContent ret;
        try {
          ret = await _saveFileToBytes(file, (bytes) async {
            return await fileSource.contentWrite(
              bytes,
              metadata: content.metadata,
            );
          });
        } on StorageConflictException catch (conflict, conflictStack) {
          // Some WebDAV servers return etags that never match on If-Match.
          // The remote changes are already merged in, so forcing the write
          // once breaks the endless conflict loop without losing data.
          _logger.warning(
            'Write after merge conflicted again; forcing overwrite. '
            '(${fileSource.displayName})',
            conflict,
            conflictStack,
          );
          ret = await _saveFileToBytes(file, (bytes) async {
            return await fileSource.contentWrite(bytes, metadata: null);
          });
        }
        delegate?.conflictMerged(fileSource, file, mergeResult);
        analytics.events.trackSaveConflict(
          type: fileSource.typeDebug,
          value: mergeResult.totalChanges(),
          success: true,
        );
        analytics.events.trackSave(
          type: fileSource.typeDebug,
          value: ret.content.length,
        );
        analytics.trackTiming(
          'saveFileSize',
          ret.content.length,
          category: 'fileSize',
          label: 'save',
        );
        await updateQuickUnlock();
        await _refreshRememberedUnlock(fileSource);
        await _syncOutgoingGroupShares(file, fileSource);
        return ret;
      } catch (e) {
        analytics.events.trackSaveConflict(
          type: fileSource.typeDebug,
          value: mergeResult.totalChanges(),
          success: false,
        );
        rethrow;
      }
    }
  }

  /// Pushes member-row changes of every outgoing dynamic group share in this
  /// vault. Runs after a successful cloud save; never fails the save itself.
  Future<void> _syncOutgoingGroupShares(
    KdbxFile file,
    FileSource fileSource,
  ) async {
    if (fileSource is! FileSourceopenvalutCloud) {
      return;
    }
    try {
      await openvalutGroupShareService.instance.syncOutgoingAfterSave(
        file: file,
        source: fileSource,
      );
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to sync outgoing group shares for ${fileSource.displayName}',
        e,
        stackTrace,
      );
    }
  }

  KdbxOpenedFile fileForKdbxFile(KdbxFile file) =>
      _openedFilesByKdbxFile[file] ??
      (() {
        throw StateError('Missing file source for kdbxFile.');
      })();

  KdbxOpenedFile? fileForFileSource(FileSource fileSource) =>
      _openedFiles.value[fileSource];

  Future<KdbxOpenedFile> saveAs(
    KdbxOpenedFile oldFile,
    FileSource output,
  ) async {
    final content = await saveFile(oldFile.kdbxFile, toFileSource: output);
    return await _savedAs(oldFile, output, content);
  }

  Future<KdbxOpenedFile> _savedAs(
    KdbxOpenedFile oldFile,
    FileSource output,
    FileContent fileContent,
  ) async {
    final oldSource = oldFile.fileSource;
    final databaseName = oldFile.kdbxFile.body.meta.databaseName.get();
    final newOpenedFile = await appDataBloc.openedFile(
      output,
      name: databaseName,
      oldFile: oldFile.openedFile,
    );
    final newFile = KdbxOpenedFile(
      fileSource: output,
      openedFile: newOpenedFile,
      kdbxFile: oldFile.kdbxFile,
      kdbxFileContent: fileContent,
      rustVault: oldFile.rustVault,
    );
    _openedFiles.add(
      OpenedKdbxFiles({
        ...Map.fromEntries(
          _openedFiles.value._files.entries.where(
            (entry) => entry.key != oldSource,
          ),
        ),
        newFile.fileSource: newFile,
      }),
    );
    // TODO also do not update quick unlock if this file is not in quick unlock.
    if (_openedFilesQuickUnlock.isNotEmpty) {
      try {
        await _updateQuickUnlockStore();
      } on AuthException catch (e, stackTrace) {
        if (e.code == AuthExceptionCode.userCanceled) {
          _logger.warning(
            'User cancelled saving quick unlock. ignoring for now.',
            e,
            stackTrace,
          );
        } else {
          rethrow;
        }
      }
    }
    return newFile;
  }

  Future<KdbxOpenedFile> saveAsNewFile(
    KdbxOpenedFile oldFile,
    CloudStorageSelectorSaveResult createFileInfo,
    CloudStorageProvider cs,
  ) async {
    return await _saveFileToBytes(oldFile.kdbxFile, (bytes) async {
      final entity = await cs.createEntity(createFileInfo, bytes);
      final lastContent = entity.lastContent!;
      assert(bytes == lastContent.content);
      return await _savedAs(oldFile, entity, lastContent);
    });
  }

  Future<FileSource> saveLocally(FileSource? source) async {
    final file = _openedFiles.value[source];
    if (file == null) {
      throw StateError('file for $source is not open.');
    }
    final databaseName = file.kdbxFile.body.meta.databaseName.get()!;
    final localSource = await _localFileSourceForDbName(databaseName);
    return (await saveAs(file, localSource)).fileSource;
  }

  /// Returns the entries of [file], preferring the Rust vault when available.
  ///
  /// Falls back to the Dart `kdbxFile` entries if the Rust vault is missing,
  /// failed, or disabled. This lets entry-listing paths gradually move to the
  /// Rust implementation without breaking the default build.
  List<RustEntry> entriesFor(KdbxOpenedFile file) {
    final rustVault = file.rustVault;
    if (AppConstants.useRustVault && rustVault != null) {
      try {
        return rustVault.entries();
      } catch (e, stackTrace) {
        _logger.warning(
          'Rust vault entries failed for ${file.fileSource.displayName}; '
          'falling back to Dart kdbx.',
          e,
          stackTrace,
        );
      }
    }
    return file.kdbxFile.body.rootGroup
        .getAllEntries()
        .map(_kdbxEntryToRustEntry)
        .toList();
  }

  RustEntry _kdbxEntryToRustEntry(KdbxEntry entry) {
    String? plain(KdbxKey key) => entry.getString(key)?.getText();
    final custom = <RustCustomField>[
      for (final key in entry.stringEntries.where(
        (e) => !KdbxKeyCommon.all.contains(e.key),
      ))
        RustCustomField(key: key.key.key, value: plain(key.key) ?? ''),
    ];
    return RustEntry(
      uuid: entry.uuid.uuid,
      title: plain(KdbxKeyCommon.TITLE) ?? '',
      username: plain(KdbxKeyCommon.USER_NAME) ?? '',
      password: plain(KdbxKeyCommon.PASSWORD) ?? '',
      url: plain(KdbxKeyCommon.URL) ?? '',
      notes: plain(KdbxKey('Notes')) ?? '',
      group: entry.parent?.name.get() ?? '',
      custom: custom,
    );
  }

  /// Serializes [file] to KDBX bytes.
  ///
  /// When the Rust vault is enabled and a [password] is supplied, the Rust
  /// core performs the serialization and the resulting bytes are reloaded into
  /// the Dart [kdbxFile] so both sides stay consistent. Otherwise the existing
  /// Dart [kdbxFile.save()] path is used.
  ///
  /// Note: edits made through the Dart [KdbxFile] object model are not yet
  /// mirrored into the Rust vault, so the Rust save path is only used when
  /// the caller has explicitly kept the Rust vault in sync.
  Future<Uint8List> saveFileContent(
    KdbxOpenedFile file, {
    String? password,
  }) async {
    final rustVault = file.rustVault;
    if (AppConstants.useRustVault &&
        rustVault != null &&
        password != null &&
        password.isNotEmpty) {
      try {
        final bytes = rustVault.save(password: password);
        // Reload the Dart model from the Rust-produced bytes so both sides
        // agree on the serialized state (new KDF salts, etc.).
        final reloadCredentials = Credentials.composite(
          ProtectedValue.fromString(password),
          null,
        );
        final reloaded = await kdbxFormat.read(bytes, reloadCredentials);
        _stopAutoSave(file.kdbxFile);
        file.kdbxFile.dispose();
        final newOpened = KdbxOpenedFile(
          fileSource: file.fileSource,
          openedFile: file.openedFile,
          kdbxFile: reloaded,
          kdbxFileContent: FileContent(
            bytes,
            file.kdbxFileContent.metadata,
            FileContentSource.memoryCache,
          ),
          rustVault: rustVault,
        );
        _openedFiles.add(
          OpenedKdbxFiles({
            ..._openedFiles.value._files,
            file.fileSource: newOpened,
          }),
        );
        _startAutoSave(newOpened);
        // Re-open the Rust vault from the just-saved bytes so subsequent
        // reads see the new state (new KDF salts, etc.).
        try {
          final refreshedRustVault = RustVault.open(
            bytes: bytes,
            password: password,
          );
          newOpened.rustVault?.close();
          _openedFiles.add(
            OpenedKdbxFiles({
              ..._openedFiles.value._files,
              file.fileSource: KdbxOpenedFile(
                fileSource: newOpened.fileSource,
                openedFile: newOpened.openedFile,
                kdbxFile: newOpened.kdbxFile,
                kdbxFileContent: newOpened.kdbxFileContent,
                rustVault: refreshedRustVault,
              ),
            }),
          );
        } catch (e, stackTrace) {
          _logger.warning(
            'Failed to refresh Rust vault after save for '
            '${file.fileSource.displayName}.',
            e,
            stackTrace,
          );
        }
        _logger.fine(
          'Saved ${file.fileSource.displayName} through Rust vault.',
        );
        return bytes;
      } catch (e, stackTrace) {
        _logger.warning(
          'Rust vault save failed for ${file.fileSource.displayName}; '
          'falling back to Dart kdbx.',
          e,
          stackTrace,
        );
      }
    }
    return file.kdbxFile.save();
  }

  Map<String, KdbxEntry>? _entryUuidLookup;

  KdbxEntry? findEntryByUuid(String uuid) {
    final entryUuidLookup = _entryUuidLookup ??= Map.fromEntries(
      openedFilesKdbx.expand(
        (file) => file.body.rootGroup.getAllEntries().map(
          (e) => MapEntry(e.uuid.uuid, e),
        ),
      ),
    );

    return entryUuidLookup[uuid];
  }

  /// All SSH keys stored in the open vaults (entries with an
  /// `ssh-private-key` field), for the SSH agent.
  List<SshAgentIdentity> sshAgentIdentities() {
    final identities = <SshAgentIdentity>[];
    for (final file in openedFilesKdbx) {
      for (final entry in file.body.rootGroup.getAllEntries()) {
        if (entry.isInRecycleBin()) {
          continue;
        }
        final privateKey = entry
            .getString(KdbxKey('ssh-private-key'))
            ?.getText();
        if (privateKey == null || privateKey.trim().isEmpty) {
          continue;
        }
        // Keys imported on another machine stay hidden on this one.
        final machine =
            entry
                .getString(KdbxKey(SshProfileKeys.machine))
                ?.getText()
                ?.trim() ??
            '';
        final isServer = SshServerProfile.isServerEntry(entry);
        if (!isServer &&
            machine.isNotEmpty &&
            machine != MachineIdentity.tag &&
            // Entries tagged before the hardware-id change used `user@host`;
            // accept those on the matching hostname too.
            machine != MachineIdentity.legacyTag) {
          continue;
        }
        try {
          final key = parseOpensshPrivateKey(privateKey);
          final profile = isServer ? SshServerProfile.fromEntry(entry) : null;
          final publicLine =
              entry.getString(KdbxKey('ssh-public-key'))?.getText()?.trim() ??
              '';
          var comment = publicLine.split(' ').length >= 3
              ? publicLine.split(' ').skip(2).join(' ')
              : entry.label ?? 'ssh';
          if (profile != null) {
            comment =
                '${profile.host}:${profile.port} '
                '${comment.isEmpty ? 'ssh' : comment}';
          } else if (machine.isNotEmpty &&
              !(entry.label ?? '').contains(MachineIdentity.hostname)) {
            comment = '${entry.label ?? 'ssh'} (${MachineIdentity.hostname})';
          }
          identities.add(
            SshAgentIdentity(
              publicKeyBlob: key.publicKey,
              comment: comment.isEmpty ? 'ssh' : comment,
              key: key,
            ),
          );
        } catch (e, stackTrace) {
          _logger.warning(
            'Unable to parse SSH key in entry ${entry.label ?? entry.uuid}.',
            e,
            stackTrace,
          );
        }
      }
    }
    return identities;
  }

  void clearEntryByUuidLookup() => _entryUuidLookup = null;

  /// Entries offered by the local credential server (searchable metadata).
  List<CredentialServerEntry> credentialServerEntries() {
    final entries = <CredentialServerEntry>[];
    for (final file in openedFilesKdbx) {
      for (final entry in file.body.rootGroup.getAllEntries()) {
        // Deny-by-default read allow-list: entries the owner did not allow
        // (nor put into an allowed group) are invisible to CLI / scripts.
        if (entry.isInRecycleBin() || !isReadAllowed(entry)) {
          continue;
        }
        entries.add(
          CredentialServerEntry(
            uuid: entry.uuid.uuid,
            label: entry.label ?? '',
            username: entry.getString(KdbxKeyCommon.USER_NAME)?.getText() ?? '',
            group: entry.parent?.name.get() ?? '',
            file: fileForKdbxFile(file).fileSource.displayName,
            allowed: true,
          ),
        );
      }
    }
    return entries;
  }

  /// Every decrypted entry across the open vaults, for CSV export. Mirrors the
  /// standalone CLI export; skips the recycle bin.
  List<Map<String, Object?>> credentialServerExport() {
    return _credentialServerExport(allowOnly: false);
  }

  /// Same as [credentialServerExport], but only includes entries the owner
  /// allowed for CLI/script reads. Used by the loopback credential server's
  /// `export` method so the deny-by-default read policy also covers exports.
  List<Map<String, Object?>> credentialServerExportForReadAccess() {
    return _credentialServerExport(allowOnly: true);
  }

  List<Map<String, Object?>> _credentialServerExport({
    required bool allowOnly,
  }) {
    final out = <Map<String, Object?>>[];
    for (final file in openedFilesKdbx) {
      final fileName = fileForKdbxFile(file).fileSource.displayName;
      for (final entry in file.body.rootGroup.getAllEntries()) {
        if (entry.isInRecycleBin() || (allowOnly && !isReadAllowed(entry))) {
          continue;
        }
        String? str(KdbxKey key) => entry.getString(key)?.getText();
        out.add({
          'file': fileName,
          'group': entry.parent?.name.get() ?? '',
          'title': str(KdbxKeyCommon.TITLE) ?? entry.label ?? '',
          'username': str(KdbxKeyCommon.USER_NAME) ?? '',
          'password': str(KdbxKeyCommon.PASSWORD) ?? '',
          'url': str(KdbxKeyCommon.URL) ?? '',
          'notes': str(KdbxKey('Notes')) ?? '',
          'totp': str(KdbxKeyCommon.OTP) ?? '',
        });
      }
    }
    return out;
  }

  /// Serializes [credentialServerExport] to CSV (RFC 4180 quoting), matching
  /// the standalone CLI export columns.
  String credentialServerExportCsv() {
    final buffer = StringBuffer(
      'file,group,title,username,password,url,notes,totp\n',
    );
    for (final row in credentialServerExport()) {
      final values = [
        'file',
        'group',
        'title',
        'username',
        'password',
        'url',
        'notes',
        'totp',
      ].map((key) => _csvField('${row[key] ?? ''}'));
      buffer.writeln(values.join(','));
    }
    return buffer.toString();
  }

  /// Quotes a single CSV field per RFC 4180.
  static String _csvField(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  ({String? username, String? password})? credentialServerResolve(
    String entryUuid,
  ) {
    final entry = _findEntryFresh(entryUuid);
    if (entry == null) {
      return null;
    }
    if (!isReadAllowed(entry)) {
      return null;
    }
    return (
      username: entry.getString(KdbxKeyCommon.USER_NAME)?.getText(),
      password: entry.getString(KdbxKeyCommon.PASSWORD)?.getText(),
    );
  }

  /// Resolves a Secret Reference (`ov://<vault>/<entry>/<field>`) against the
  /// currently opened vaults. Returns the scalar value for standard/custom
  /// fields, or a TOTP map for the `totp` field. Returns `null` if the
  /// reference is malformed or points to a missing vault/entry/field.
  Object? credentialServerResolveReference(String reference) {
    final ref = SecretReference.parse(reference);
    if (ref == null) {
      _logger.fine('Malformed secret reference: $reference');
      return null;
    }

    KdbxOpenedFile? matchedFile;
    for (final file in openedFilesKdbx) {
      final opened = fileForKdbxFile(file);
      final source = opened.fileSource;
      if (source.uuid == ref.vaultId || source.displayName == ref.vaultId) {
        matchedFile = opened;
        break;
      }
    }
    if (matchedFile == null) {
      _logger.fine('No vault matches ${ref.vaultId}');
      return null;
    }

    KdbxEntry? matchedEntry;
    for (final entry in matchedFile.kdbxFile.body.rootGroup.getAllEntries()) {
      if (entry.isInRecycleBin()) {
        continue;
      }
      if (entry.uuid.uuid == ref.entryId ||
          (entry.label ?? '') == ref.entryId) {
        matchedEntry = entry;
        break;
      }
    }
    if (matchedEntry == null) {
      _logger.fine('No entry matches ${ref.entryId}');
      return null;
    }
    if (!isReadAllowed(matchedEntry)) {
      _logger.fine('Entry ${ref.entryId} is not allowed for read access');
      return null;
    }

    if (ref.isTotp) {
      final totp = generateTotpForEntry(
        matchedEntry,
        nowMillis: () => clock.now().millisecondsSinceEpoch,
      );
      if (totp == null) {
        return null;
      }
      return {
        'code': totp.code,
        'period': totp.period,
        'remainingSeconds': totp.remaining,
      };
    }

    final key = ref.standardKey ?? KdbxKey(ref.field);
    return matchedEntry.getString(key)?.getText();
  }

  ({String code, int period, int remaining})? credentialServerTotp(
    String entryUuid,
  ) {
    final entry = _findEntryFresh(entryUuid);
    if (entry == null) {
      return null;
    }
    return generateTotpForEntry(
      entry,
      nowMillis: () => clock.now().millisecondsSinceEpoch,
    );
  }

  /// Resolves the sudo password for the current machine after validating the
  /// provided [totpCode] against the computer entry's TOTP secret.
  ({String username, String password})? credentialServerSudo(String totpCode) {
    if (totpCode.isEmpty) {
      return null;
    }
    final entry = _findCurrentComputerEntry();
    if (entry == null) {
      return null;
    }
    final password = ComputerIdentity.getPassword(entry);
    final username = ComputerIdentity.getUsername(entry) ?? '';
    if (password == null || password.isEmpty) {
      return null;
    }
    final totp = generateTotpForEntry(
      entry,
      nowMillis: () => clock.now().millisecondsSinceEpoch,
    );
    if (totp == null || totp.code != totpCode) {
      return null;
    }
    return (username: username, password: password);
  }

  /// Ensures the current machine's dedicated 计算机 entry carries a
  /// `machine-id` and an OTP secret (generating a fresh TOTP secret when
  /// missing), saves the change back to the vault/cloud, then writes the
  /// encrypted PAM TOTP file used by `pam_openvalut`.
  ///
  /// [query] optionally pins the target entry (label/username substring) when
  /// the entry exists without a machine-id yet, so `openvalut-cli pam-setup
  /// <title>` can fill the entry the user already created.
  Future<String?> credentialServerPamSetup(String query) async {
    final files = openedFilesKdbx;
    if (files.isEmpty) {
      return null;
    }
    final user =
        (Platform.environment['USER'] ?? Platform.environment['USERNAME'] ?? '')
            .trim();
    if (user.isEmpty) {
      return null;
    }
    final mid = MachineIdentity.machineId;
    if (mid.isEmpty) {
      return null;
    }

    KdbxFile? targetFile;
    KdbxEntry? entry;
    for (final file in files) {
      entry = ComputerIdentity.findEntry(file);
      if (entry != null) {
        targetFile = file;
        break;
      }
    }
    final q = query.trim();
    if (entry == null && q.isNotEmpty) {
      for (final file in files) {
        entry = _findComputerEntryByQuery(file, q);
        if (entry != null) {
          targetFile = file;
          break;
        }
      }
    }

    var dirty = false;
    if (entry == null) {
      targetFile = files.first;
      entry = ComputerIdentity.ensureEntry(targetFile);
      dirty = true;
    }

    final existingMid = ComputerIdentity.getMachineId(entry);
    if (existingMid != mid) {
      entry.setString(
        KdbxKey(ComputerIdentity.machineIdKey),
        PlainValue(mid),
      );
      dirty = true;
    }
    final existingUser = ComputerIdentity.getUsername(entry) ?? '';
    if (existingUser.trim().isEmpty) {
      entry.setString(KdbxKeyCommon.USER_NAME, PlainValue(user));
      dirty = true;
    }

    var otpRaw = ComputerIdentity.getTotp(entry);
    if (otpRaw == null || otpRaw.trim().isEmpty) {
      final secret = Uint8List.fromList(
        List.generate(20, (_) => Random.secure().nextInt(256)),
      );
      final uri = OtpAuth(
        label: 'OpenValut:$user@${MachineIdentity.hostname}',
        secret: secret,
      ).toUri();
      otpRaw = uri
          .replace(
            queryParameters: {
              ...uri.queryParameters,
              'issuer': 'OpenValut', // NON-NLS
            },
          )
          .toString();
      entry.setString(KdbxKeyCommon.OTP, PlainValue(otpRaw));
      dirty = true;
    }

    if (dirty) {
      try {
        await saveFile(targetFile!);
      } catch (e, stackTrace) {
        _logger.warning(
          'PAM setup: failed to persist computer entry.',
          e,
          stackTrace,
        );
        return null;
      }
    }

    final Uint8List secret;
    try {
      if (otpRaw.startsWith(OtpAuth.URI_PREFIX)) {
        secret = OtpAuth.fromUri(Uri.parse(otpRaw)).secret;
      } else {
        final fromQuery = OtpAuth.fromQueryString(otpRaw);
        secret = fromQuery?.secret ?? base32Decode(otpRaw);
      }
    } catch (_) {
      return null;
    }
    final secretBase32 = base32Encode(secret);
    return PamTotpFile.write(secretBase32);
  }

  /// Finds a "计算机" group entry by label/username substring for pam-setup
  /// targeting (used when the entry predates machine-id tagging).
  KdbxEntry? _findComputerEntryByQuery(KdbxFile file, String rawQuery) {
    final query = rawQuery.toLowerCase();
    for (final group in file.body.rootGroup.groups) {
      if (group.name.get() != ComputerIdentity.groupName) {
        continue;
      }
      for (final entry in group.getAllEntries()) {
        final label = (entry.label ?? '').toLowerCase();
        final username =
            (entry.getString(KdbxKeyCommon.USER_NAME)?.getText() ?? '')
                .toLowerCase();
        if (label == query ||
            username == query ||
            label.contains(query) ||
            username.contains(query)) {
          return entry;
        }
      }
    }
    return null;
  }

  KdbxEntry? _findEntryFresh(String entryUuid) {
    for (final file in openedFilesKdbx) {
      for (final entry in file.body.rootGroup.getAllEntries()) {
        if (entry.uuid.uuid == entryUuid && isReadAllowed(entry)) {
          return entry;
        }
      }
    }
    return null;
  }

  /// The vault entry holding this machine's sudo credentials, if any open
  /// vault contains one (see [ComputerIdentity]).
  KdbxEntry? _findCurrentComputerEntry() {
    for (final file in openedFilesKdbx) {
      final entry = ComputerIdentity.findEntry(file);
      if (entry != null) {
        return entry;
      }
    }
    return null;
  }

  /// Moves every entry carrying an `ssh-private-key` field into the dedicated
  /// SSH key group of its file (created when missing). Returns the number of
  /// entries moved. Also merges legacy locale-named duplicates ("SSH Keys" /
  /// "SSH 密钥") into the canonical group and removes the emptied groups.
  int organizeSshKeyEntries() {
    var moved = 0;
    var changed = false;
    for (final file in openedFilesKdbx) {
      final root = file.body.rootGroup;
      final entries = file.body.rootGroup.getAllEntries().toList();
      final candidates = root.groups
          .where((g) => isSshKeysGroupStoredName(g.name.get()))
          .toList();
      final hasKeyEntries = entries.any(
        (entry) =>
            !entry.isInRecycleBin() &&
            entry
                    .getString(KdbxKey('ssh-private-key'))
                    ?.getText()
                    ?.isNotEmpty ==
                true,
      );
      if (candidates.isEmpty && !hasKeyEntries) {
        continue;
      }
      final sshGroup = candidates.isNotEmpty
          ? (candidates.firstWhere(
              (g) => g.name.get() == BuiltInGroupNames.sshKeys,
              orElse: () => candidates.first,
            ))
          : file.createGroup(
              parent: root,
              name: BuiltInGroupNames.sshKeys,
            );
      if (sshGroup.name.get() != BuiltInGroupNames.sshKeys) {
        sshGroup.name.set(BuiltInGroupNames.sshKeys);
        changed = true;
      }
      for (final entry in entries) {
        if (entry.isInRecycleBin() || entry.parent == sshGroup) {
          continue;
        }
        final hasKey =
            entry
                .getString(KdbxKey('ssh-private-key'))
                ?.getText()
                ?.isNotEmpty ==
            true;
        if (!hasKey) {
          continue;
        }
        file.move(entry, sshGroup);
        moved++;
        changed = true;
      }
      for (final legacy in candidates) {
        if (legacy == sshGroup) {
          continue;
        }
        // Only an emptied legacy group is removed; anything still inside is
        // user content and stays untouched.
        if (legacy.entries.isEmpty && legacy.groups.isEmpty) {
          file.deletePermanently(legacy);
          changed = true;
        }
      }
    }
    if (changed) {
      _openedFiles.add(_openedFiles.value);
      clearEntryByUuidLookup();
    }
    return moved;
  }

  Stream<ReloadStatus> reload(KdbxOpenedFile file) async* {
    Uint8List? bytes;
    final dirtyObjects = file.kdbxFile.dirtyObjects;
    var replaced = false;
    try {
      if (file.kdbxFile.isDirty) {
        //throw StateError('File must not be dirty for now.');
        bytes = await file.kdbxFile.save();
      }
      yield ReloadStatus.downloading;
      final reloadedContent = await file.fileSource.content().last;
      assert(reloadedContent.source == FileContentSource.origin);
      if (ByteUtils.eq(reloadedContent.content, file.kdbxFileContent.content)) {
        yield ReloadStatus.didNotChange;
        return;
      }

      // try loading the new file.
      yield ReloadStatus.decrypting;
      final readArgs = KdbxReadArgs(
        reloadedContent.content,
        file.kdbxFile.credentials,
      );
      final kdbxReadFile = await readKdbxFile(kdbxFormat, readArgs);
      if (kdbxReadFile.file == null) {
        // The file changed on disk in a way the remembered credentials cannot
        // open (e.g. it was saved elsewhere and the transformed key went
        // stale). Surface an error instead of crashing on a null merge.
        _logger.warning(
          'Unable to re-decrypt reloaded file ${file.fileSource.displayName}: '
          '${kdbxReadFile.exception}',
        );
        yield ReloadStatus.error;
        return;
      }

      if (file.fileSource is FileSourceopenvalutCloud) {
        // Cloud vaults are rebuilt from rows with a fresh root UUID on every
        // load, so a UUID-based merge is structurally impossible. Replace the
        // open file with the freshly loaded one; local changes were saved
        // above, so they are already on the server.
        _logger.info('Reload of cloud vault replaces the open file.');
        _replaceOpenedFile(file, kdbxReadFile.file!, reloadedContent);
        replaced = true;
        yield ReloadStatus.replaced;
        return;
      }

      _logger.info('\n\n\n===========\n\n\n');
      _logger.info('starting merge.');
      file.kdbxFile.merge(kdbxReadFile.file!);

      _logger.info('\n\nDONE MERGE\n\n\n\n');

      yield ReloadStatus.merged;
    } finally {
      if (!replaced && bytes != null && !file.kdbxFile.isDirty) {
        dirtyObjects.forEach(file.kdbxFile.dirtyObject);
      }
    }
  }

  /// Swaps the open [oldOpened] file for [newFile] (rebuilt from freshly
  /// loaded content), keeping autosave, the opened-files stream and the
  /// remembered-credentials bookkeeping consistent.
  void _replaceOpenedFile(
    KdbxOpenedFile oldOpened,
    KdbxFile newFile,
    FileContent content,
  ) {
    _stopAutoSave(oldOpened.kdbxFile);
    final newOpened = KdbxOpenedFile(
      fileSource: oldOpened.fileSource,
      openedFile: oldOpened.openedFile,
      kdbxFile: newFile,
      kdbxFileContent: content,
    );
    _openedFiles.add(
      OpenedKdbxFiles({
        ..._openedFiles.value._files,
        oldOpened.fileSource: newOpened,
      }),
    );
    _cloudSyncedUpdatedAt[oldOpened.fileSource.uuid] =
        content.metadata?['updatedAt'] as int?;
    _startAutoSave(newOpened);
    clearEntryByUuidLookup();
    oldOpened.kdbxFile.dispose();
    oldOpened.rustVault?.close();
  }

  Future<AttachmentProvider> attachmentProviderForFileSource(
    KdbxFile file,
  ) async {
    return AttachmentProviderLocal();
  }
}

abstract class AttachmentProvider {
  Future<Uint8List> readAttachmentBytes(KdbxFile file, KdbxBinary binary);
  Future<void> attachFile({
    required KdbxEntry entry,
    required String fileName,
    required Uint8List bytes,
  });
}

class AttachmentProviderLocal extends AttachmentProvider {
  @override
  Future<Uint8List> readAttachmentBytes(
    KdbxFile file,
    KdbxBinary binary,
  ) async {
    return binary.value;
  }

  @override
  Future<void> attachFile({
    required KdbxEntry entry,
    required String fileName,
    required Uint8List bytes,
  }) async {
    entry.createBinary(
      isProtected: false,
      name: fileName,
      bytes: bytes,
    );
  }
}

enum ReloadStatus {
  error,
  downloading,
  decrypting,
  didNotChange,
  merged,
  replaced,
}

class KdbxReadArgs {
  KdbxReadArgs(this.content, this.credentials);

  final Uint8List content;
  final Credentials credentials;
}
