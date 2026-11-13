import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:openvalut/utils/app_locale.dart';
import 'package:openvalut/utils/path_utils.dart';
import 'package:openvalut/utils/platform.dart';
import 'package:openvalut/utils/secure_window.dart';
import 'package:openvalut/utils/unlock_prefs.dart';

import 'credential_server.dart';

final _logger = Logger('credential_server_controller');

/// Runs the local credential server while vaults are open.
///
/// On desktop it is exposed through the 0600 Unix socket
/// `~/.openvalut/data/openvalut.sock` (via the same C bridge the SSH agent
/// uses); the random token file (`openvalut.token`, 0600) stops other local
/// users from querying the loopback TCP port directly, and the CLI reads it
/// from the same app-data directory.
///
/// On Android the loopback TCP server itself is what other apps reach. The
/// random port and session token are published through a ContentProvider so the
/// companion apps (e.g. sshbot) can discover them; [onStatus] carries them to
/// the host channel which feeds the provider.
class CredentialServerController {
  CredentialServerController._();

  static final CredentialServerController instance =
      CredentialServerController._();

  final Random _random = Random.secure();
  CredentialServer? _server;
  Process? _bridge;
  String? _socketPath;
  String? _tokenPath;
  String? _portPath;
  bool _started = false;
  void Function(int? port, String? token)? _onStatus;
  DateTime? _lastAuthenticationAt;
  Future<bool>? _authenticationInProgress;

  static const _authenticationGracePeriod = Duration(seconds: 10);

  bool get isRunning => _started;

  String? get socketPath => _socketPath;

  Future<void> start({
    required CredentialProvider entries,
    required CredentialReferenceResolver resolveReference,
    required SudoResolver sudo,
    required PamSetupResolver pamSetup,
    CredentialExporter? export,
    void Function(int? port, String? token)? onStatus,
  }) async {
    if (_started) {
      return;
    }
    _onStatus = onStatus;
    final token = List.generate(
      32,
      (_) => _random.nextInt(16).toRadixString(16),
    ).join();
    final server = CredentialServer(
      entries: entries,
      resolveReference: resolveReference,
      sudo: sudo,
      pamSetup: pamSetup,
      export: export,
      authenticate: _authenticateRequest,
      token: token,
    );
    await server.start();
    _server = server;
    _started = true;
    onStatus?.call(server.port, token);

    final base = await PathUtils().getAppDataDirectory();
    final socketPath = '${base.path}/openvalut.sock';
    _socketPath = socketPath;
    final tokenPath = '${base.path}/openvalut.token';
    _tokenPath = tokenPath;
    final portPath = '${base.path}/openvalut.port';
    _portPath = portPath;
    try {
      File(tokenPath).writeAsStringSync(token);
      File(portPath).writeAsStringSync('${server.port}');
      await _chmod600(tokenPath);
      await _chmod600(portPath);
    } catch (e, stackTrace) {
      _logger.warning(
        'Unable to write credential server token.',
        e,
        stackTrace,
      );
      await stop();
      return;
    }

    // The Unix-socket bridge and the app-data token/port files are
    // desktop-only; on Android other apps discover the loopback server through
    // the ContentProvider instead.
    if (!OpenValutPlatform.isAndroid) {
      String? bridgePath;
      try {
        final executable = Platform.resolvedExecutable;
        final candidate = File(
          '${File(executable).parent.path}/openvalut-agent-bridge',
        );
        if (candidate.existsSync()) {
          bridgePath = candidate.path;
        }
      } catch (e, stackTrace) {
        _logger.warning(
          'Unable to locate openvalut-agent-bridge.',
          e,
          stackTrace,
        );
      }
      if (bridgePath == null) {
        _logger.warning(
          'openvalut-agent-bridge not found; credential socket unavailable.',
        );
        return;
      }
      try {
        _bridge = await Process.start(bridgePath, [
          '${server.port}',
          socketPath,
        ]);
        _logger.info('Credential socket: $socketPath');
        unawaited(
          _bridge!.exitCode.then((code) {
            _logger.warning('Credential bridge exited with code $code.');
          }),
        );
      } catch (e, stackTrace) {
        _logger.warning('Unable to start credential bridge.', e, stackTrace);
      }
    }
  }

  /// dart:io has no chmod; ask the shell (best effort, Linux/macOS).
  Future<void> _chmod600(String path) async {
    try {
      await Process.run('chmod', ['600', path]);
    } catch (e, stackTrace) {
      _logger.fine('Unable to chmod $path.', e, stackTrace);
    }
  }

  Future<bool> _authenticateRequest() {
    if (!OpenValutPlatform.isMacOS || !UnlockPrefs.fingerprintEnabled.value) {
      return Future.value(true);
    }
    final authenticatedAt = _lastAuthenticationAt;
    if (authenticatedAt != null &&
        DateTime.now().difference(authenticatedAt) <
            _authenticationGracePeriod) {
      return Future.value(true);
    }
    return _authenticationInProgress ??=
        SecureWindow.authenticate(
              AppLocale.isChinese
                  ? '验证指纹以允许命令行访问 OpenValut'
                  : 'Authenticate to allow command-line access to OpenValut',
            )
            .then((authenticated) {
              if (authenticated) {
                _lastAuthenticationAt = DateTime.now();
              }
              return authenticated;
            })
            .whenComplete(() {
              _authenticationInProgress = null;
            });
  }

  Future<void> stop() async {
    if (!_started) {
      await _removeStaleEndpointFiles();
      return;
    }
    _started = false;
    _lastAuthenticationAt = null;
    final onStatus = _onStatus;
    _onStatus = null;
    onStatus?.call(null, null);
    final bridge = _bridge;
    _bridge = null;
    if (bridge != null) {
      try {
        bridge.kill();
        await bridge.exitCode.timeout(const Duration(seconds: 2));
      } catch (_) {
        // Best effort.
      }
    }
    await _server?.stop();
    _server = null;
    final socketPath = _socketPath;
    _socketPath = null;
    final tokenPath = _tokenPath;
    _tokenPath = null;
    final portPath = _portPath;
    _portPath = null;
    await _removeEndpointFiles([socketPath, tokenPath, portPath]);
  }

  Future<void> _removeStaleEndpointFiles() async {
    final base = await PathUtils().getAppDataDirectory();
    if (_started) {
      return;
    }
    await _removeEndpointFiles([
      '${base.path}/openvalut.sock',
      '${base.path}/openvalut.token',
      '${base.path}/openvalut.port',
    ]);
  }

  Future<void> _removeEndpointFiles(Iterable<String?> paths) async {
    for (final path in paths) {
      if (path == null) {
        continue;
      }
      try {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e, stackTrace) {
        _logger.fine('Unable to remove $path.', e, stackTrace);
      }
    }
  }
}
