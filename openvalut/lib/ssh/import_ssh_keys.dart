import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kdbx/kdbx.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/ssh/machine_identity.dart';
import 'package:openvalut/ssh/openssh_key.dart';
import 'package:path/path.dart' as p;
import 'package:pointycastle/digests/sha256.dart';
import 'package:provider/provider.dart';

final _logger = Logger('import_ssh_keys');

/// A private key found in `~/.ssh` that can be imported into the vault.
class LocalSshKeyCandidate {
  LocalSshKeyCandidate({
    required this.path,
    required this.key,
    required this.publicKeyLine,
    required this.label,
  });

  final String path;
  final ParsedSshPrivateKey key;
  final String? publicKeyLine;
  final String label;

  /// Short fingerprint (e.g. `SHA256:…`), or the algorithm if unavailable.
  String get fingerprint => _fingerprint(key);
}

/// Scans `~/.ssh` for importable OpenSSH private keys (ed25519 / RSA).
Future<List<LocalSshKeyCandidate>> scanLocalSshKeys([
  String? sshDirectory,
]) async {
  final sshDir = Directory(
    sshDirectory ?? '${Platform.environment['HOME']}/.ssh',
  );
  if (!await sshDir.exists()) {
    return const [];
  }
  final candidates = <LocalSshKeyCandidate>[];
  await for (final entity in sshDir.list()) {
    if (entity is! File) {
      continue;
    }
    final name = p.basename(entity.path);
    if (name.endsWith('.pub') ||
        name == 'config' ||
        name == 'known_hosts' ||
        name == 'authorized_keys' ||
        name.contains('known_hosts')) {
      continue;
    }
    try {
      final key = parseOpensshPrivateKey(await entity.readAsString());
      String? publicKeyLine;
      final pubFile = File('${entity.path}.pub');
      if (await pubFile.exists()) {
        publicKeyLine = (await pubFile.readAsString()).trim();
      } else {
        // No .pub companion (e.g. a .bak copy): derive the public key from
        // the private key so the vault entry always carries it.
        final algorithm = switch (key.keyType) {
          SshKeyType.ed25519 => 'ssh-ed25519',
          SshKeyType.rsa => 'ssh-rsa',
        };
        final comment = entity.path.split('/').last;
        publicKeyLine = '$algorithm ${base64.encode(key.publicKey)} $comment';
      }
      final comment =
          publicKeyLine != null && publicKeyLine.split(' ').length >= 3
          ? publicKeyLine.split(' ').skip(2).join(' ')
          : '';
      candidates.add(
        LocalSshKeyCandidate(
          path: entity.path,
          key: key,
          publicKeyLine: publicKeyLine,
          label: comment.isNotEmpty ? comment : name,
        ),
      );
    } catch (_) {
      // Not an OpenSSH private key; skip it.
    }
  }
  return candidates;
}

/// Shows a dialog listing importable local keys; imports the selected ones
/// into [group] (or the first open file's root group).
Future<List<String>> showImportSshKeysDialog(
  BuildContext context, {
  KdbxBloc? kdbxBloc,
  KdbxGroup? group,
}) async {
  final loc = AppLocalizations.of(context);
  final bloc = kdbxBloc ?? context.read<KdbxBloc>();
  final candidates = await scanLocalSshKeys();
  if (!context.mounted) {
    return const [];
  }
  if (candidates.isEmpty) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.importSshKeys),
        content: Text(loc.importSshKeysNoneFound),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.close),
          ),
        ],
      ),
    );
    return const [];
  }

  // 密码库中已有的 SSH 公钥指纹，用于去重：同一把密钥再次导入时
  // 提示已存在，避免生成重复条目。
  final existingFingerprints = _existingSshFingerprints(bloc);
  if (!context.mounted) {
    return const [];
  }
  final allAlreadyImported =
      candidates.isNotEmpty &&
      candidates.every(
        (c) => existingFingerprints.contains(c.fingerprint),
      );
  if (allAlreadyImported) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.importSshKeys),
        content: Text(loc.sshKeysAlreadyImported),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.close),
          ),
        ],
      ),
    );
    return const [];
  }

  final selected = <LocalSshKeyCandidate>{};
  final result = await showDialog<List<LocalSshKeyCandidate>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(loc.importSshKeys),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final candidate in candidates)
                CheckboxListTile(
                  value: selected.contains(candidate),
                  enabled: !existingFingerprints.contains(
                    candidate.fingerprint,
                  ),
                  title: Text(
                    candidate.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${candidate.fingerprint}'
                    '${existingFingerprints.contains(candidate.fingerprint) ? '\n${loc.sshSkippedAlreadyImported}' : ''}'
                    '\n${candidate.path}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selected.add(candidate);
                      } else {
                        selected.remove(candidate);
                      }
                    });
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(selected.toList()),
            child: Text(loc.importButton),
          ),
        ],
      ),
    ),
  );
  if (result == null || result.isEmpty || !context.mounted) {
    return const [];
  }

  final file = bloc.openedFilesKdbx.isNotEmpty
      ? (group?.file ?? bloc.openedFilesKdbx.first)
      : null;
  if (file == null) {
    return const [];
  }
  // SSH keys always land in the dedicated SSH key group.
  final targetGroup = ensureSshKeyGroup(file);
  final importedPaths = <String>[];
  for (final candidate in result) {
    final entry = bloc.createEntry(file: file, group: targetGroup);
    // Tag with this machine so same-named keys from different machines are
    // easy to tell apart and the agent only exposes this machine's keys.
    entry.label = '${candidate.label} (${MachineIdentity.hostname})';
    entry.setString(
      KdbxKey('ssh-machine'),
      PlainValue(MachineIdentity.tag),
    );
    entry.setString(
      KdbxKey('ssh-private-key'),
      PlainValue(File(candidate.path).readAsStringSync()),
    );
    if (candidate.publicKeyLine != null) {
      entry.setString(
        KdbxKey('ssh-public-key'),
        PlainValue(candidate.publicKeyLine!),
      );
    }
    importedPaths.add(candidate.path);
    _logger.info('Imported SSH key ${candidate.path} as ${entry.label}.');
  }
  // Pull in any older SSH entries that live in other groups.
  final moved = bloc.organizeSshKeyEntries();
  if (moved > 0) {
    _logger.info('Moved $moved existing SSH entries into the SSH group.');
  }
  await bloc.saveFile(file);

  // Offer to remove the local originals — explicit, because it is destructive.
  final delete = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(loc.importSshKeysDeleteTitle),
      content: Text(loc.importSshKeysDeleteBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(loc.keep),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(loc.delete),
        ),
      ],
    ),
  );
  if (delete == true) {
    for (final path in importedPaths) {
      try {
        final fileEntity = File(path);
        if (await fileEntity.exists()) {
          await fileEntity.delete();
        }
        final pub = File('$path.pub');
        if (await pub.exists()) {
          await pub.delete();
        }
      } catch (e, stackTrace) {
        _logger.warning('Unable to delete imported key $path.', e, stackTrace);
      }
    }
  }
  return importedPaths;
}

/// 收集密码库中已导入的 SSH 公钥指纹（遍历所有打开文件的全部条目）。
Set<String> _existingSshFingerprints(KdbxBloc bloc) {
  final fingerprints = <String>{};
  for (final file in bloc.openedFilesKdbx) {
    final entries = <KdbxEntry>[];
    void collect(KdbxGroup group) {
      entries.addAll(group.entries);
      group.groups.forEach(collect);
    }

    collect(file.body.rootGroup);
    for (final entry in entries) {
      final publicKey = entry.getString(KdbxKey('ssh-public-key'))?.getText();
      final fingerprint = publicKey == null
          ? null
          : fingerprintOfPublicKeyLine(publicKey);
      if (fingerprint != null) {
        fingerprints.add(fingerprint);
        continue;
      }
      final privateKey = entry.getString(KdbxKey('ssh-private-key'))?.getText();
      if (privateKey != null) {
        try {
          fingerprints.add(_fingerprint(parseOpensshPrivateKey(privateKey)));
        } catch (_) {
          // 无法解析的旧条目忽略，导入时会重新创建。
        }
      }
    }
  }
  return fingerprints;
}

/// 从 OpenSSH 公钥行（`ssh-ed25519 AAAA... comment`）计算 SHA256 指纹，
/// 与 [_fingerprint] 输出格式一致。
String? fingerprintOfPublicKeyLine(String line) {
  final parts = line.trim().split(RegExp(r'\s+'));
  if (parts.length < 2) {
    return null;
  }
  try {
    final bytes = base64.decode(parts[1]);
    final digest = SHA256Digest().process(bytes);
    return 'SHA256:${base64.encode(digest).replaceAll('=', '')}';
  } catch (_) {
    return null;
  }
}

String _fingerprint(ParsedSshPrivateKey key) {
  try {
    final digest = SHA256Digest().process(key.publicKey);
    return 'SHA256:${base64.encode(digest).replaceAll('=', '')}';
  } catch (_) {
    return key.keyType.name;
  }
}
