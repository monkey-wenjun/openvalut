import 'dart:io';

import 'package:logging/logging.dart';
import 'package:openvalut/utils/path_utils.dart';

final _logger = Logger('ssh_config');

/// Manages the `IdentityAgent` reference inside `~/.ssh/config`.
///
/// The block OpenValut writes is wrapped in markers, so toggling the SSH agent
/// off removes exactly what we added and leaves the rest of the user's config
/// untouched. Enable is idempotent (existing config is preserved and the
/// block is merged in or refreshed).
class SshConfig {
  SshConfig._();

  static const markerStart = '# >>> OpenValut SSH Agent (managed) >>>'; // NON-NLS
  static const markerEnd = '# <<< OpenValut SSH Agent (managed) <<<'; // NON-NLS

  static String? _cachedSocketPath;

  /// Absolute path of the agent socket, resolved from the real app data
  /// directory (which differs per machine: `~/.openvalut/data` or the XDG
  /// config dir). ssh expands `~`, but an absolute path can never point at
  /// the wrong machine's location.
  static Future<String> resolveSocketPath() async {
    if (_cachedSocketPath != null) {
      return _cachedSocketPath!;
    }
    final base = await PathUtils().getAppDataDirectory();
    return _cachedSocketPath = '${base.path}/ssh-agent/agent.sock';
  }

  static String managedBlock(String socketPath) =>
      '$markerStart\n'
      'Host *\n'
      '    IdentityAgent $socketPath\n'
      '$markerEnd';

  /// Adds or refreshes the managed block in the ssh config. Returns true when
  /// the file was actually changed. [configPath] overrides the default
  /// `~/.ssh/config` (used by tests).
  static Future<bool> enable([
    String? configPath,
    String? socketPath,
  ]) async {
    final config = _configFile(configPath);
    if (config == null) {
      return false;
    }
    try {
      await config.parent.create(recursive: true);
      final existing = config.existsSync() ? config.readAsStringSync() : '';
      final block = managedBlock(socketPath ?? await resolveSocketPath());
      final updated = existing.contains(markerStart)
          ? _replaceManaged(existing, block)
          : existing.trimRight().isEmpty
          ? block
          : '${existing.trimRight()}\n\n$block';
      // Compare ignoring trailing whitespace, so a missing final newline
      // (e.g. from an earlier version) does not look like a real change.
      if (updated.trimRight() == existing.trimRight()) {
        return false;
      }
      final toWrite = updated.endsWith('\n') ? updated : '$updated\n';
      await config.writeAsString(toWrite, flush: true);
      _logger.info('SSH config updated at ${config.path}.');
      return true;
    } catch (e, stackTrace) {
      _logger.warning('Unable to update ssh config.', e, stackTrace);
      return false;
    }
  }

  /// Removes only the managed block. Returns true when the file changed.
  static Future<bool> disable([String? configPath]) async {
    final config = _configFile(configPath);
    if (config == null || !config.existsSync()) {
      return false;
    }
    try {
      final existing = config.readAsStringSync();
      if (!existing.contains(markerStart)) {
        return false;
      }
      final updated = _replaceManaged(existing, '').trimRight();
      await config.writeAsString(
        updated.isEmpty ? '' : '$updated\n',
        flush: true,
      );
      _logger.info('SSH agent reference removed from ${config.path}.');
      return true;
    } catch (e, stackTrace) {
      _logger.warning('Unable to remove ssh config block.', e, stackTrace);
      return false;
    }
  }

  /// Whether the user's config contains an `IdentityAgent` line outside the
  /// OpenValut managed block. ssh uses the first matching value, so such a line
  /// may take precedence over ours.
  static bool hasExternalIdentityAgent([String? configPath]) {
    final config = _configFile(configPath);
    if (config == null || !config.existsSync()) {
      return false;
    }
    try {
      final content = config.readAsStringSync();
      final managedStart = content.indexOf(markerStart);
      final managedEnd = content.indexOf(markerEnd);
      final before = managedStart >= 0 ? content.substring(0, managedStart) : content;
      final after = managedEnd >= 0 && managedEnd + markerEnd.length < content.length
          ? content.substring(managedEnd + markerEnd.length)
          : '';
      return '${before.trimRight()}\n$after'.contains('IdentityAgent');
    } catch (_) {
      return false;
    }
  }

  static File? _configFile(String? configPath) {
    if (configPath != null) {
      return File(configPath);
    }
    final home = Platform.environment['HOME'];
    return home == null ? null : File('$home/.ssh/config');
  }

  static String _replaceManaged(String content, String replacement) {
    final start = content.indexOf(markerStart);
    if (start < 0) {
      return content;
    }
    final end = content.indexOf(markerEnd, start);
    if (end < 0) {
      return content;
    }
    final before = content.substring(0, start).trimRight();
    var after = content.substring(end + markerEnd.length);
    while (after.startsWith('\n')) {
      after = after.substring(1);
    }
    final head = before.isEmpty ? '' : '$before\n\n';
    final tail = after.isEmpty ? '' : '\n$after';
    return '$head$replacement$tail';
  }
}
