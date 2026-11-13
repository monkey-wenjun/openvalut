import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:kdbx/kdbx.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/bloc/kdbx/file_source.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';
import 'package:openvalut/utils/platform.dart';

/// Whether [query] identifies the entry in the same way the app does.
///
/// The app stores KDBX UUIDs as base64 (`KdbxUuid.uuid`), while the Rust host's
/// `openvalut-core` exposes them as hyphenated hex (e.g.
/// `f41e9f98-d30e-4b25-b4b1-c81daad322e8`). Accepting both lets UUIDs passed
/// over the bridge from the host match entries held by the app.
bool _entryUuidMatches(String query, KdbxUuid uuid) {
  if (uuid.uuid == query) {
    return true;
  }
  final hex = query.replaceAll('-', '');
  if (hex.length != 32 || !RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(hex)) {
    return false;
  }
  final bytes = Uint8List(16);
  for (var i = 0; i < 16; i++) {
    bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return base64.encode(bytes) == uuid.uuid;
}

final _logger = Logger('host_bridge');

/// 回环 HTTP 桥：让 Chrome 扩展宿主直接读取桌面 App 已解锁的密码库，
/// 不需要在扩展里配置服务器或输入主密码。
///
/// 安全模型与凭据服务一致：只监听 127.0.0.1，请求必须携带随机 token；
/// token 和端口写在 0600 的 host-bridge.json（扩展宿主同路径读取）。
/// 传输的是加密后的 KDBX 字节 + 变换密钥（等价于主密码在当前版本上的
/// 效力），密钥只在本机回环上传递。
class HostBridge {
  HostBridge._();

  static HostBridge? _instance;

  static HostBridge get instance => _instance ??= HostBridge._();

  HttpServer? _server;
  String _token = '';
  String _sessionGeneration = '';
  List<Map<String, Object?>>? _vaultSnapshot;
  Future<List<Map<String, Object?>>>? _vaultSnapshotBuild;
  StreamSubscription<dynamic>? _openedFilesSubscription;
  final List<StreamSubscription<dynamic>> _vaultChangeSubscriptions = [];
  Directory? _configDir;
  void Function()? _onShowWindow;

  bool get isRunning => _server != null;

  Future<void> start({
    required KdbxBloc kdbxBloc,
    void Function()? onShowWindow,
  }) async {
    if (!OpenValutPlatform.isDesktop || OpenValutPlatform.isWeb) {
      return;
    }
    await stop();
    _onShowWindow = onShowWindow;
    _token = _randomToken();
    _sessionGeneration = _randomToken();
    _watchVaultChanges(kdbxBloc);
    final dir = await _bridgeDir();
    _configDir = dir;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    server.listen(
      (request) => unawaited(_handle(request, kdbxBloc)),
      onError: (Object error, StackTrace stackTrace) {
        _logger.warning('Host bridge server error.', error, stackTrace);
      },
    );
    await _writeInfo(dir, server.port, _token);
    _logger.info('Host bridge listening on 127.0.0.1:${server.port}');
  }

  void invalidateSession() {
    _sessionGeneration = _randomToken();
    _vaultSnapshot = null;
    _vaultSnapshotBuild = null;
  }

  Future<void> stop() async {
    await _openedFilesSubscription?.cancel();
    _openedFilesSubscription = null;
    for (final subscription in _vaultChangeSubscriptions) {
      await subscription.cancel();
    }
    _vaultChangeSubscriptions.clear();
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
    }
    final dir = _configDir;
    _configDir = null;
    if (dir != null) {
      try {
        final f = File('${dir.path}/host-bridge.json');
        if (f.existsSync()) {
          await f.delete();
        }
      } catch (e, stackTrace) {
        _logger.fine('Unable to remove host bridge info.', e, stackTrace);
      }
    }
  }

  void _watchVaultChanges(KdbxBloc kdbxBloc) {
    _replaceVaultChangeSubscriptions(kdbxBloc);
    _openedFilesSubscription = kdbxBloc.openedFilesChanged.listen((_) {
      invalidateSession();
      _replaceVaultChangeSubscriptions(kdbxBloc);
    });
  }

  void _replaceVaultChangeSubscriptions(KdbxBloc kdbxBloc) {
    for (final subscription in _vaultChangeSubscriptions) {
      unawaited(subscription.cancel());
    }
    _vaultChangeSubscriptions.clear();
    for (final openedFile in kdbxBloc.openedFiles.values) {
      _vaultChangeSubscriptions.add(
        openedFile.kdbxFile.dirtyObjectsChanged.listen((dirtyObjects) {
          // saveTo emits an empty set after serializing. Only content changes
          // invalidate the snapshot, otherwise every snapshot would invalidate itself.
          if (dirtyObjects.isNotEmpty) {
            invalidateSession();
          }
        }),
      );
    }
  }

  Future<void> _handle(HttpRequest request, KdbxBloc kdbxBloc) async {
    try {
      if (request.headers.value(HttpHeaders.authorizationHeader) !=
          'Bearer $_token') {
        request.response.statusCode = HttpStatus.unauthorized;
        await request.response.close();
        return;
      }
      if (request.method == 'GET' && request.uri.path == '/status') {
        await _writeJson(request.response, {
          'ok': true,
          'generation': _sessionGeneration,
          'unlocked': kdbxBloc.openedFiles.length != 0,
        });
        return;
      }
      if (request.method == 'GET' && request.uri.path == '/vaults') {
        final generation = _sessionGeneration;
        final vaults = await _getVaultSnapshot(kdbxBloc);
        if (generation != _sessionGeneration ||
            kdbxBloc.openedFiles.length == 0) {
          await _writeJson(
            request.response,
            {
              'ok': false,
              'error': 'Vault session changed while creating the snapshot.',
            },
            statusCode: HttpStatus.conflict,
          );
          return;
        }
        await _writeJson(request.response, {'vaults': vaults});
        return;
      }
      if (request.method == 'POST' && request.uri.path == '/showWindow') {
        _logger.info('Host bridge: showing desktop window.');
        _onShowWindow?.call();
        await _writeJson(request.response, {'ok': true});
        return;
      }
      if (request.method == 'POST' && request.uri.path == '/saveVault') {
        final body = await utf8.decoder.bind(request).join();
        final jsonBody = json.decode(body) as Map<String, dynamic>;
        final id = jsonBody['id'] as String?;
        final kdbxBase64 = jsonBody['kdbxBase64'] as String?;
        final transformedKeyBase64 =
            jsonBody['transformedKeyBase64'] as String?;
        final kdfFingerprint = jsonBody['kdfFingerprint'] as String?;
        if (id == null ||
            kdbxBase64 == null ||
            transformedKeyBase64 == null ||
            kdfFingerprint == null) {
          await _writeJson(
            request.response,
            {'ok': false, 'error': 'Missing required fields.'},
          );
          return;
        }
        final bytes = base64.decode(kdbxBase64);
        final transformedKey = base64.decode(transformedKeyBase64);
        await kdbxBloc.replaceOpenedVaultFromBytes(
          id: id,
          bytes: bytes,
          credentials: TransformedKeyCredentials(
            transformedKey: Uint8List.fromList(transformedKey),
            kdfFingerprint: kdfFingerprint,
          ),
        );
        invalidateSession();
        await _writeJson(request.response, {'ok': true});
        return;
      }
      if (request.method == 'POST' && request.uri.path == '/createEntry') {
        final body = await utf8.decoder.bind(request).join();
        final jsonBody = json.decode(body) as Map<String, dynamic>;
        final id = jsonBody['id'] as String?;
        final title = jsonBody['title'] as String?;
        final username = jsonBody['username'] as String?;
        final url = jsonBody['url'] as String?;
        final customFields = jsonBody['customFields'] as Map<String, dynamic>?;
        if (id == null) {
          await _writeJson(
            request.response,
            {'ok': false, 'error': 'Missing required fields.'},
          );
          return;
        }
        FileSource? source;
        KdbxOpenedFile? opened;
        for (final entry in kdbxBloc.openedFiles.entries) {
          if (entry.key.uuid == id || entry.key.displayName == id) {
            source = entry.key;
            opened = entry.value;
            break;
          }
        }
        if (source == null || opened == null) {
          await _writeJson(
            request.response,
            {'ok': false, 'error': 'Vault $id is not open.'},
          );
          return;
        }
        var file = opened.kdbxFile;
        // If the vault was opened with a transformed key it is read-only.
        // Re-open it with writable remembered credentials so the save below
        // can succeed.
        if (file.credentials is TransformedKeyCredentials) {
          await kdbxBloc.reopenWithWritableCredentials(source, opened);
          final reopened = kdbxBloc.fileForFileSource(source);
          if (reopened == null ||
              reopened.kdbxFile.credentials is TransformedKeyCredentials) {
            await _writeJson(
              request.response,
              {
                'ok': false,
                'error':
                    'Vault is read-only. Please unlock it with the master password.',
              },
            );
            return;
          }
          file = reopened.kdbxFile;
        }
        final entry = KdbxEntry.create(file, file.body.rootGroup);
        file.body.rootGroup.addEntry(entry);
        if (title != null && title.isNotEmpty) {
          entry.setString(KdbxKeyCommon.TITLE, PlainValue(title));
        }
        if (username != null && username.isNotEmpty) {
          entry.setString(KdbxKeyCommon.USER_NAME, PlainValue(username));
        }
        if (url != null && url.isNotEmpty) {
          entry.setString(KdbxKeyCommon.URL, PlainValue(url));
        }
        if (customFields != null) {
          for (final field in customFields.entries) {
            final key = field.key;
            final value = field.value;
            if (value is Map<String, dynamic>) {
              final text = value['value'] as String?;
              final protect = value['protect'] as bool? ?? false;
              if (text == null) {
                continue;
              }
              entry.setString(
                KdbxKey(key),
                protect ? ProtectedValue.fromString(text) : PlainValue(text),
              );
            } else if (value is String) {
              entry.setString(KdbxKey(key), PlainValue(value));
            }
          }
        }
        await kdbxBloc.saveFile(file);
        invalidateSession();
        await _writeJson(request.response, {
          'ok': true,
          'entryUuid': entry.uuid.uuid,
        });
        return;
      }
      if (request.method == 'POST' && request.uri.path == '/deleteEntry') {
        final body = await utf8.decoder.bind(request).join();
        final jsonBody = json.decode(body) as Map<String, dynamic>;
        final id = jsonBody['id'] as String?;
        final entryUuid = jsonBody['entryUuid'] as String?;
        if (id == null || entryUuid == null) {
          await _writeJson(
            request.response,
            {'ok': false, 'error': 'Missing required fields.'},
          );
          return;
        }
        FileSource? source;
        KdbxOpenedFile? opened;
        for (final entry in kdbxBloc.openedFiles.entries) {
          if (entry.key.uuid == id || entry.key.displayName == id) {
            source = entry.key;
            opened = entry.value;
            break;
          }
        }
        if (source == null || opened == null) {
          await _writeJson(
            request.response,
            {'ok': false, 'error': 'Vault $id is not open.'},
          );
          return;
        }
        var file = opened.kdbxFile;
        if (file.credentials is TransformedKeyCredentials) {
          await kdbxBloc.reopenWithWritableCredentials(source, opened);
          final reopened = kdbxBloc.fileForFileSource(source);
          if (reopened == null ||
              reopened.kdbxFile.credentials is TransformedKeyCredentials) {
            await _writeJson(
              request.response,
              {
                'ok': false,
                'error':
                    'Vault is read-only. Please unlock it with the master password.',
              },
            );
            return;
          }
          file = reopened.kdbxFile;
        }
        final entry = file.body.rootGroup.getAllEntries().firstWhere(
          (e) => _entryUuidMatches(entryUuid, e.uuid),
          orElse: () => throw StateError('Entry $entryUuid not found.'),
        );
        file.deleteEntry(entry);
        await kdbxBloc.saveFile(file);
        invalidateSession();
        await _writeJson(request.response, {'ok': true});
        return;
      }
      if (request.method == 'POST' && request.uri.path == '/updateEntry') {
        final body = await utf8.decoder.bind(request).join();
        final jsonBody = json.decode(body) as Map<String, dynamic>;
        final id = jsonBody['id'] as String?;
        final entryUuid = jsonBody['entryUuid'] as String?;
        final title = jsonBody['title'] as String?;
        final username = jsonBody['username'] as String?;
        final password = jsonBody['password'] as String?;
        final url = jsonBody['url'] as String?;
        final notes = jsonBody['notes'] as String?;
        final customFields = jsonBody['customFields'] as Map<String, dynamic>?;
        if (id == null || entryUuid == null) {
          await _writeJson(
            request.response,
            {'ok': false, 'error': 'Missing required fields.'},
          );
          return;
        }
        FileSource? source;
        KdbxOpenedFile? opened;
        for (final entry in kdbxBloc.openedFiles.entries) {
          if (entry.key.uuid == id || entry.key.displayName == id) {
            source = entry.key;
            opened = entry.value;
            break;
          }
        }
        if (source == null || opened == null) {
          await _writeJson(
            request.response,
            {'ok': false, 'error': 'Vault $id is not open.'},
          );
          return;
        }
        var file = opened.kdbxFile;
        if (file.credentials is TransformedKeyCredentials) {
          await kdbxBloc.reopenWithWritableCredentials(source, opened);
          final reopened = kdbxBloc.fileForFileSource(source);
          if (reopened == null ||
              reopened.kdbxFile.credentials is TransformedKeyCredentials) {
            await _writeJson(
              request.response,
              {
                'ok': false,
                'error':
                    'Vault is read-only. Please unlock it with the master password.',
              },
            );
            return;
          }
          file = reopened.kdbxFile;
        }
        final entry = file.body.rootGroup.getAllEntries().firstWhere(
          (e) => _entryUuidMatches(entryUuid, e.uuid),
          orElse: () => throw StateError('Entry $entryUuid not found.'),
        );
        if (title != null && title.isNotEmpty) {
          entry.setString(KdbxKeyCommon.TITLE, PlainValue(title));
        } else if (title != null && title.isEmpty) {
          entry.setString(KdbxKeyCommon.TITLE, null);
        }
        if (username != null) {
          entry.setString(
            KdbxKeyCommon.USER_NAME,
            username.isEmpty ? null : PlainValue(username),
          );
        }
        if (password != null) {
          entry.setString(
            KdbxKeyCommon.PASSWORD,
            password.isEmpty ? null : ProtectedValue.fromString(password),
          );
        }
        if (url != null) {
          entry.setString(
            KdbxKeyCommon.URL,
            url.isEmpty ? null : PlainValue(url),
          );
        }
        if (notes != null) {
          entry.setString(
            KdbxKey('Notes'),
            notes.isEmpty ? null : PlainValue(notes),
          );
        }
        if (customFields != null) {
          for (final field in customFields.entries) {
            final key = field.key;
            final value = field.value;
            if (value is Map<String, dynamic>) {
              final text = value['value'] as String?;
              final protect = value['protect'] as bool? ?? false;
              if (text == null) {
                continue;
              }
              entry.setString(
                KdbxKey(key),
                protect ? ProtectedValue.fromString(text) : PlainValue(text),
              );
            } else if (value is String) {
              entry.setString(KdbxKey(key), PlainValue(value));
            }
          }
        }
        await kdbxBloc.saveFile(file);
        invalidateSession();
        await _writeJson(request.response, {'ok': true});
        return;
      }
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    } catch (e, stackTrace) {
      _logger.warning('Host bridge request failed.', e, stackTrace);
      try {
        await _writeJson(
          request.response,
          {'ok': false, 'error': e.toString()},
        );
      } catch (_) {
        // 响应已关闭，忽略。
      }
    }
  }

  Future<List<Map<String, Object?>>> _getVaultSnapshot(
    KdbxBloc kdbxBloc,
  ) async {
    final cached = _vaultSnapshot;
    if (cached != null) {
      return cached;
    }
    final pending = _vaultSnapshotBuild;
    if (pending != null) {
      return pending;
    }

    final generation = _sessionGeneration;
    final build = _buildVaultSnapshot(kdbxBloc);
    _vaultSnapshotBuild = build;
    try {
      final result = await build;
      if (generation == _sessionGeneration) {
        _vaultSnapshot = result;
      }
      return result;
    } finally {
      if (identical(_vaultSnapshotBuild, build)) {
        _vaultSnapshotBuild = null;
      }
    }
  }

  Future<List<Map<String, Object?>>> _buildVaultSnapshot(
    KdbxBloc kdbxBloc,
  ) async {
    final vaults = <Map<String, Object?>>[];
    for (final entry in kdbxBloc.openedFiles.entries) {
      final file = entry.value.kdbxFile;
      // saveTo rotates the KDF salt, so transformed credentials are read after it.
      final Uint8List bytes;
      try {
        bytes = await file.saveTo((value) async => value);
      } catch (e, stackTrace) {
        _logger.warning(
          'Skipping ${entry.key.displayName}: cannot serialize.',
          e,
          stackTrace,
        );
        continue;
      }
      final transformed = file.transformedKeyCredentials;
      if (transformed == null) {
        _logger.finer(
          'Skipping ${entry.key.displayName}: no transformed key.',
        );
        continue;
      }
      vaults.add({
        'id': entry.key.uuid,
        'name': entry.key.displayName,
        'kdbxBase64': base64.encode(bytes),
        'transformedKeyBase64': base64.encode(transformed.transformedKey),
        'kdfFingerprint': transformed.kdfFingerprint,
      });
    }
    return vaults;
  }

  Future<Directory> _bridgeDir() async {
    final home = Platform.environment['HOME'] ?? '';
    final base = switch (OpenValutPlatform.operatingSystem) {
      'linux' => Platform.environment['XDG_CONFIG_HOME'] ?? '$home/.config',
      'macos' => '$home/Library/Application Support',
      'windows' => Platform.environment['APPDATA'] ?? '.',
      _ => '$home/.config',
    };
    final dir = Directory('$base/openvalut');
    await dir.create(recursive: true);
    return dir;
  }

  Future<void> _writeInfo(Directory dir, int port, String token) async {
    final f = File('${dir.path}/host-bridge.json');
    await f.writeAsString(json.encode({'port': port, 'token': token}));
    if (OpenValutPlatform.isLinux || OpenValutPlatform.isMacOS) {
      await Process.run('chmod', ['600', f.path]);
    }
  }

  Future<void> _writeJson(
    HttpResponse response,
    Map<String, Object?> data, {
    int statusCode = HttpStatus.ok,
  }) async {
    response.statusCode = statusCode;
    response.headers.contentType = ContentType.json;
    response.write(json.encode(data));
    await response.close();
  }

  static String _randomToken() {
    final rng = Random.secure();
    final b = Uint8List(32);
    for (var i = 0; i < b.length; i++) {
      b[i] = rng.nextInt(256);
    }
    return base64Url.encode(b).replaceAll('=', '');
  }
}
