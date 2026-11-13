import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:openvalut/utils/path_utils.dart';

import 'ssh_agent.dart';

final _logger = Logger('ssh_agent_controller');

/// Owns the SSH agent while the app runs: starts it when vaults are open
/// (and the vault is the key source), stops it when everything is closed or
/// the app exits. Mirrors 1Password: no private key ever touches disk; ssh
/// only receives signatures.
class SshAgentController {
  SshAgentController._();

  static final SshAgentController instance = SshAgentController._();

  final SshAgentServer _server = SshAgentServer();
  Process? _bridge;
  String? _socketPath;
  bool _started = false;

  bool get isRunning => _started;

  /// The Unix socket path ssh clients should use
  /// (`IdentityAgent ~/.openvalut/agent.sock`), or null while stopped.
  String? get socketPath => _socketPath;

  /// Starts the agent and the Unix socket bridge. [identities] is evaluated
  /// per request, so keys added to the vault appear immediately.
  Future<void> start({
    required List<SshAgentIdentity> Function() identities,
  }) async {
    if (_started) {
      return;
    }
    await _server.start(identities);
    _started = true;

    final socketPath = await _prepareSocketPath();
    if (socketPath == null) {
      return;
    }
    _socketPath = socketPath;
    final bridgePath = _bridgeBinaryPath();
    if (bridgePath == null) {
      _logger.warning(
        'openvalut-agent-bridge not found next to the executable; '
        'the agent is only reachable over TCP (port ${_server.port}).',
      );
      return;
    }
    try {
      _bridge = await Process.start(bridgePath, [
        '${_server.port}',
        socketPath,
      ]);
      _logger.info('SSH agent socket: $socketPath (bridge ${_bridge!.pid})');
      unawaited(
        _bridge!.exitCode.then((code) {
          _logger.warning('openvalut-agent-bridge exited with code $code.');
        }),
      );
    } catch (e, stackTrace) {
      _logger.warning('Unable to start openvalut-agent-bridge.', e, stackTrace);
    }
  }

  /// Stops the agent and removes the socket.
  Future<void> stop() async {
    if (!_started) {
      return;
    }
    _started = false;
    final bridge = _bridge;
    _bridge = null;
    if (bridge != null) {
      try {
        bridge.kill();
        await bridge.exitCode.timeout(const Duration(seconds: 2));
      } catch (e) {
        _logger.fine('Bridge shutdown: $e');
      }
    }
    await _server.stop();
    final socketPath = _socketPath;
    _socketPath = null;
    if (socketPath != null) {
      try {
        final socket = File(socketPath);
        if (socket.existsSync()) {
          socket.deleteSync();
        }
      } catch (e, stackTrace) {
        _logger.fine('Unable to remove agent socket.', e, stackTrace);
      }
    }
  }

  Future<String?> _prepareSocketPath() async {
    final base = await PathUtils().getAppDataDirectory();
    final dir = Directory('${base.path}/ssh-agent');
    try {
      await dir.create(recursive: true);
    } catch (e, stackTrace) {
      _logger.warning('Unable to create ssh-agent directory.', e, stackTrace);
      return null;
    }
    return '${dir.path}/agent.sock';
  }

  String? _bridgeBinaryPath() {
    try {
      final executable = Platform.resolvedExecutable;
      final candidate = File(
        '${File(executable).parent.path}/openvalut-agent-bridge',
      );
      return candidate.existsSync() ? candidate.path : null;
    } catch (e, stackTrace) {
      _logger.warning(
        'Unable to locate openvalut-agent-bridge.',
        e,
        stackTrace,
      );
      return null;
    }
  }
}
