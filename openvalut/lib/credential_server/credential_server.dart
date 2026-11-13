import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:kdbx/kdbx.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/utils/otpauth.dart';
import 'package:otp/otp.dart';

final _logger = Logger('credential_server');

/// One searchable vault entry offered by the credential server.
class CredentialServerEntry {
  CredentialServerEntry({
    required this.uuid,
    required this.label,
    required this.username,
    required this.group,
    required this.file,
    this.allowed = true,
  });

  final String uuid;
  final String label;
  final String username;
  final String group;
  final String file;
  /// Read allow status. The credential server is deny-by-default and only
  /// exposes entries the owner allowed, so entries returned by `list`/`get`
  /// carry `allowed: true`; the field is kept so JSON consumers can audit
  /// the policy without trusting the filter implicitly.
  final bool allowed;

  Map<String, Object?> toJson() => {
    'uuid': uuid,
    'label': label,
    'username': username,
    'group': group,
    'file': file,
    'allowed': allowed,
  };
}

/// The entries currently open in the app, with their secrets.
typedef CredentialProvider = List<CredentialServerEntry> Function();

/// Resolves a Secret Reference (`ov://<vault>/<entry>/<field>`) to its value.
/// Returns a [String] for scalar fields or a TOTP map for the `totp` field.
typedef CredentialReferenceResolver = Object? Function(String reference);

/// Returns every entry with its decrypted fields, ready for CSV export.
typedef CredentialExporter = List<Map<String, Object?>> Function();

/// Sudo password accessor validated by a TOTP code for the current machine.
typedef SudoResolver =
    ({String username, String password})? Function(
      String totpCode,
    );

/// Writes the encrypted PAM TOTP file for the current machine from the
/// computer entry's OTP secret. Returns the written file path.
typedef PamSetupResolver = Future<String?> Function(String query);

/// Authenticates a credential-server request before any vault data is exposed.
typedef CredentialRequestAuthenticator = Future<bool> Function();

/// Serves vault credentials over a loopback TCP socket using newline-delimited
/// JSON. Only reachable through the 0600 Unix socket bridge while the vault is
/// unlocked; every request must carry the random session token.
///
/// Methods:
///  - `ping` → `{pong:true}`
///  - `list` → entries
///  - `get {query, field?}` → non-sensitive metadata (`label`, `group`,
///    `file`) only; passwords and TOTP are no longer returned directly.
///  - `resolve {reference}` → resolves a Secret Reference such as
///    `ov://Personal/GitHub/password` or `ov://Personal/GitHub/totp`.
///  - `sudo {totp}` → `{username, password}` for the current machine when the
///    provided TOTP code is valid.
class CredentialServer {
  CredentialServer({
    required CredentialProvider entries,
    required CredentialReferenceResolver resolveReference,
    required SudoResolver sudo,
    required PamSetupResolver pamSetup,
    required this.token,
    CredentialExporter? export,
    CredentialRequestAuthenticator? authenticate,
  }) : _entries = entries,
       _resolveReference = resolveReference,
       _sudo = sudo,
       _pamSetup = pamSetup,
       _export = export ?? (() => <Map<String, Object?>>[]),
       _authenticate = authenticate;

  final CredentialProvider _entries;
  final CredentialReferenceResolver _resolveReference;
  final SudoResolver _sudo;
  final PamSetupResolver _pamSetup;
  final CredentialExporter _export;
  final CredentialRequestAuthenticator? _authenticate;
  final String token;

  ServerSocket? _server;

  int? get port => _server?.port;

  Future<void> start() async {
    await stop();
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    _logger.info('Credential server listening on 127.0.0.1:${server.port}');
    server.listen(
      (socket) => unawaited(_handle(socket)),
      onError: (Object error, StackTrace stackTrace) {
        _logger.warning('Credential server socket error.', error, stackTrace);
      },
    );
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close();
    }
  }

  Future<void> _handle(Socket socket) async {
    var buffer = '';
    try {
      await for (final chunk in socket) {
        buffer += utf8.decode(chunk);
        var newline = buffer.indexOf('\n');
        while (newline >= 0) {
          final line = buffer.substring(0, newline).trim();
          buffer = buffer.substring(newline + 1);
          if (line.isNotEmpty) {
            final response = await _handleLine(line);
            socket.add(utf8.encode('$response\n'));
          }
          newline = buffer.indexOf('\n');
        }
      }
    } catch (e, stackTrace) {
      _logger.fine('Credential server client error.', e, stackTrace);
    } finally {
      await socket.close();
    }
  }

  Future<String> _handleLine(String line) async {
    Map<String, Object?> request;
    try {
      request = (json.decode(line) as Map<Object?, Object?>)
          .cast<String, Object?>();
    } catch (_) {
      return _error(null, 'invalid json');
    }
    final id = request['id'];
    if (request['token'] != token) {
      return _error(id, 'unauthorized');
    }
    final method = request['method'];
    final params =
        (request['params'] as Map<Object?, Object?>?)
            ?.cast<String, Object?>() ??
        const {};
    try {
      final authenticate = _authenticate;
      if (method != 'ping' &&
          authenticate != null &&
          !await authenticate()) {
        return _error(id, 'biometric authentication failed');
      }
      switch (method) {
        case 'ping':
          return _ok(id, {'pong': true});
        case 'list':
          return _ok(id, {
            'entries': _entries().map((e) => e.toJson()).toList(),
          });
        case 'get':
          return _handleGet(id, params);
        case 'export':
          return _ok(id, {'entries': _export()});
        case 'resolve':
          return _handleResolve(id, params);
        case 'totp':
          return _error(
            id,
            'totp is no longer exposed directly; use resolve with a Secret Reference',
          );
        case 'sudo':
          return _handleSudo(id, params);
        case 'pamSetup':
          return await _handlePamSetup(id, params);
        default:
          return _error(id, 'unknown method: $method');
      }
    } catch (e, stackTrace) {
      _logger.warning('Credential server request failed.', e, stackTrace);
      return _error(id, e.toString());
    }
  }

  String _handleGet(Object? id, Map<String, Object?> params) {
    final query = (params['query'] as String? ?? '').trim().toLowerCase();
    final match = _matchEntry(query);
    if (match == null) {
      return _error(id, 'no matching entry');
    }
    final field = params['field'] as String?;
    final allowed = {'label', 'group', 'file', 'allowed'};
    final normalized = field?.toLowerCase() ?? 'label';
    if (!allowed.contains(normalized)) {
      return _error(
        id,
        'get only returns non-sensitive metadata; use resolve with a Secret Reference for $field',
      );
    }
    return _ok(id, switch (normalized) {
      'group' => match.group,
      'file' => match.file,
      'allowed' => match.allowed ? 'true' : 'false',
      _ => match.label,
    });
  }

  String _handleResolve(Object? id, Map<String, Object?> params) {
    final reference = (params['reference'] as String? ?? '').trim();
    if (reference.isEmpty) {
      return _error(id, 'missing reference');
    }
    final resolved = _resolveReference(reference);
    if (resolved == null) {
      return _error(id, 'unable to resolve reference');
    }
    return _ok(id, resolved);
  }

  String _handleSudo(Object? id, Map<String, Object?> params) {
    final totpCode = (params['totp'] as String? ?? '').trim();
    if (totpCode.isEmpty) {
      return _error(id, 'missing totp code');
    }
    final resolved = _sudo(totpCode);
    if (resolved == null) {
      return _error(id, 'invalid totp or computer not configured');
    }
    return _ok(id, {
      'username': resolved.username,
      'password': resolved.password,
    });
  }

  Future<String> _handlePamSetup(
    Object? id,
    Map<String, Object?> params,
  ) async {
    final query = params['query'] as String? ?? '';
    final path = await _pamSetup(query);
    if (path == null) {
      return _error(id, 'computer entry has no TOTP or machine id unavailable');
    }
    return _ok(id, {'path': path});
  }

  CredentialServerEntry? _matchEntry(String query) {
    final entries = _entries();
    if (query.isEmpty) {
      return entries.isEmpty ? null : entries.first;
    }
    // Exact label or username match wins; then substring.
    CredentialServerEntry? substring;
    for (final entry in entries) {
      final label = entry.label.toLowerCase();
      final username = entry.username.toLowerCase();
      if (label == query || username == query) {
        return entry;
      }
      if (substring == null &&
          (label.contains(query) || username.contains(query))) {
        substring = entry;
      }
    }
    return substring;
  }

  String _ok(Object? id, Object? data) => json.encode({
    'id': id,
    'ok': true,
    'data': data,
  });

  String _error(Object? id, String message) => json.encode({
    'id': id,
    'ok': false,
    'error': message,
  });
}

/// Generates the current TOTP code for a vault entry, mirroring the app's
/// own OTP handling (otpauth URI, KeeWeb query format or raw base32 secret).
({String code, int period, int remaining})? generateTotpForEntry(
  KdbxEntry entry, {
  required int Function() nowMillis,
}) {
  final value = entry.getString(KdbxKeyCommon.OTP)?.getText();
  if (value == null || value.isEmpty) {
    return null;
  }
  final OtpAuth otpAuth;
  try {
    if (value.startsWith(OtpAuth.URI_PREFIX)) {
      otpAuth = OtpAuth.fromUri(Uri.parse(value));
    } else {
      otpAuth =
          OtpAuth.fromQueryString(value) ??
          OtpAuth(secret: _base32Decode(value));
    }
  } catch (_) {
    return null;
  }
  final now = nowMillis();
  final code = OTP.generateTOTPCodeString(
    _base32Encode(otpAuth.secret),
    now,
    algorithm: otpAuth.algorithm,
    length: otpAuth.digits,
    interval: otpAuth.period,
    isGoogle: true,
  );
  return (
    code: code,
    period: otpAuth.period,
    remaining: otpAuth.period - (now ~/ 1000) % otpAuth.period,
  );
}

Uint8List _base32Decode(String value) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  final normalized = value.toUpperCase().replaceAll(RegExp('[^$alphabet]'), '');
  final bits = StringBuffer();
  for (final char in normalized.split('')) {
    final index = alphabet.indexOf(char);
    bits.write(index.toRadixString(2).padLeft(5, '0'));
  }
  final bytes = <int>[];
  for (var i = 0; i + 8 <= bits.length; i += 8) {
    bytes.add(int.parse(bits.toString().substring(i, i + 8), radix: 2));
  }
  return Uint8List.fromList(bytes);
}

String _base32Encode(Uint8List bytes) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  final bits = StringBuffer();
  for (final byte in bytes) {
    bits.write(byte.toRadixString(2).padLeft(8, '0'));
  }
  final out = StringBuffer();
  for (var i = 0; i + 5 <= bits.length; i += 5) {
    out.write(
      alphabet[int.parse(bits.toString().substring(i, i + 5), radix: 2)],
    );
  }
  return out.toString();
}
