import 'dart:io';

import 'package:openvalut/utils/platform.dart';
import 'package:openvalut/utils/secure_auto_unlock.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

final _logger = Logger('auto_unlock');

const _passwordFileName = 'openvalut.pw'; // NON-NLS

/// Tries to find an encrypted password file on a USB drive or internal
/// storage. The file must contain a base64-encoded AES-256-GCM ciphertext
/// produced by [encryptAutoUnlockPassword].
///
/// This is intentionally a debug/development convenience for the custom
/// sideload build and bypasses the manual password input.
Future<String?> findAutoUnlockPassword() async {
  if (!OpenValutPlatform.isAndroid) {
    return null;
  }

  final status = await Permission.manageExternalStorage.request();
  if (!status.isGranted) {
    _logger.info('manageExternalStorage not granted, opening app settings.');
    await openAppSettings();
    return null;
  }

  final candidates = <String>[
    '/sdcard/$_passwordFileName',
    '/storage/emulated/0/$_passwordFileName',
    '/storage/usbdisk/$_passwordFileName',
    '/storage/usbdisk0/$_passwordFileName',
    '/storage/usbdisk1/$_passwordFileName',
    '/mnt/usb_storage/$_passwordFileName',
  ];

  // Discover mounted USB/SD volumes from /proc/mounts without needing to
  // list protected directories like /storage.
  try {
    final mounts = await File('/proc/mounts').readAsString();
    for (final line in mounts.split('\n')) {
      final parts = line.split(' ');
      if (parts.length < 2) continue;
      final mountPoint = parts[1];
      if ((mountPoint.startsWith('/mnt/media_rw/') ||
              mountPoint.startsWith('/storage/')) &&
          mountPoint != '/storage/emulated' &&
          mountPoint != '/storage/self') {
        candidates.add('$mountPoint/$_passwordFileName');
      }
    }
  } catch (e, stackTrace) {
    _logger.fine('Unable to read /proc/mounts', e, stackTrace);
  }

  // Also scan mounted volumes under /storage and /mnt/media_rw if accessible.
  for (final dir in ['/storage', '/mnt/media_rw']) {
    try {
      final d = Directory(dir);
      if (d.existsSync()) {
        await for (final entity in d.list(followLinks: false)) {
          if (entity is Directory) {
            candidates.add('${entity.path}/$_passwordFileName');
          }
        }
      }
    } catch (e, stackTrace) {
      _logger.fine('Unable to scan $dir', e, stackTrace);
    }
  }

  for (final path in candidates) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        final encoded = (await file.readAsString()).trim();
        if (encoded.isEmpty) {
          continue;
        }
        final password = decryptAutoUnlockPassword(encoded);
        if (password != null && password.isNotEmpty) {
          _logger.info('Auto-unlock password file found at $path');
          return password;
        }
        // Fall back to treating the file as legacy plaintext for debugging.
        _logger.warning(
          'Could not decrypt $path; treating content as plaintext.',
        );
        return encoded;
      }
    } catch (e, stackTrace) {
      _logger.fine('Could not read $path', e, stackTrace);
    }
  }

  _logger.info('No auto-unlock password file found.');
  return null;
}
