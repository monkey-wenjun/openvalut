import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openvalut/ssh/ssh_config.dart';

void main() {
  late Directory dir;
  late String configPath;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('ssh_config_test_');
    configPath = '${dir.path}/config';
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  test('enable creates the managed block in a fresh config', () async {
    expect(await SshConfig.enable(configPath, '/tmp/sock'), isTrue);
    final content = File(configPath).readAsStringSync();
    expect(content, contains(SshConfig.markerStart));
    expect(content, contains('IdentityAgent /tmp/sock'));
    expect(SshConfig.hasExternalIdentityAgent(configPath), isFalse);
  });

  test('enable preserves existing user config and appends the block',
      () async {
    File(configPath).writeAsStringSync(
      'Host github.com\n'
      '    User git\n',
    );
    expect(await SshConfig.enable(configPath, '/tmp/sock'), isTrue);
    final content = File(configPath).readAsStringSync();
    expect(content, contains('Host github.com'));
    expect(content, contains('User git'));
    expect(content, contains(SshConfig.markerStart));
  });

  test('enable is idempotent', () async {
    expect(await SshConfig.enable(configPath, '/tmp/sock'), isTrue);
    expect(await SshConfig.enable(configPath, '/tmp/sock'), isFalse);
    final content = File(configPath).readAsStringSync();
    expect(
      content.split(SshConfig.markerStart).length - 1,
      1,
      reason: 'block must not be duplicated',
    );
  });

  test('disable removes only the managed block', () async {
    File(configPath).writeAsStringSync(
      'Host github.com\n'
      '    User git\n',
    );
    await SshConfig.enable(configPath, '/tmp/sock');
    expect(await SshConfig.disable(configPath), isTrue);
    final content = File(configPath).readAsStringSync();
    expect(content, isNot(contains(SshConfig.markerStart)));
    expect(content, isNot(contains('IdentityAgent')));
    expect(content, contains('Host github.com'));
    expect(content, contains('User git'));
    // Second disable is a no-op.
    expect(await SshConfig.disable(configPath), isFalse);
  });

  test('hasExternalIdentityAgent detects user-owned IdentityAgent lines',
      () async {
    File(configPath).writeAsStringSync(
      'Host *\n'
      '    IdentityAgent ~/.1password/agent.sock\n',
    );
    await SshConfig.enable(configPath, '/tmp/sock');
    expect(SshConfig.hasExternalIdentityAgent(configPath), isTrue);
  });

  test('resolveSocketPath points into the app data directory', () async {
    final path = await SshConfig.resolveSocketPath();
    expect(path, endsWith('/ssh-agent/agent.sock'));
    expect(path, isNot(contains('~')));
  });
}
