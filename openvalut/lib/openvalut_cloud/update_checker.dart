import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:open_file/open_file.dart';
import 'package:openvalut/utils/app_locale.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/digests/sha256.dart';

final _logger = Logger('update_checker');

/// A release published by openvalut-server for this platform.
class UpdateInfo {
  const UpdateInfo({
    required this.platform,
    required this.versionName,
    required this.versionCode,
    required this.changelog,
    required this.downloadUrl,
    required this.sha256,
    required this.fileSize,
  });

  final String platform;
  final String versionName;
  final int versionCode;
  final String changelog;
  final String downloadUrl;
  final String sha256;
  final int fileSize;

  factory UpdateInfo.fromJson(Map<String, dynamic> json) => UpdateInfo(
    platform: json['platform'] as String,
    versionName: json['versionName'] as String,
    versionCode: json['versionCode'] as int,
    changelog: json['changelog'] as String? ?? '',
    downloadUrl: json['downloadUrl'] as String? ?? '',
    sha256: json['sha256'] as String? ?? '',
    fileSize: json['fileSize'] as int? ?? 0,
  );
}

/// Checks and installs OpenValut releases published to openvalut-server.
class UpdateChecker {
  UpdateChecker._();

  /// Platform tag used by the version table.
  static String platformTag() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    return 'linux';
  }

  /// Returns the newest release, or null when nothing is published yet.
  static Future<UpdateInfo?> checkForUpdate({required String baseUrl}) async {
    final uri = Uri.parse(
      '$baseUrl/api/versions/latest?platform=${platformTag()}',
    );
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode == 404) {
      return null;
    }
    if (resp.statusCode != 200) {
      throw HttpException('update check failed: ${resp.statusCode}');
    }
    final data = json.decode(resp.body) as Map<String, dynamic>;
    return UpdateInfo.fromJson(data['version'] as Map<String, dynamic>);
  }

  /// Downloads [info]'s artifact, verifies its SHA-256 and (on Android)
  /// opens the system installer. On desktop it only downloads and returns
  /// the path, so the user can install manually.
  static Future<String> downloadAndInstall(UpdateInfo info) async {
    final Directory dir;
    if (Platform.isAndroid) {
      final ext = await getExternalStorageDirectory();
      dir = Directory('${ext?.path ?? ''}/downloads');
    } else {
      dir = await getDownloadsDirectory() ?? Directory.systemTemp;
    }
    await dir.create(recursive: true);
    final file = File(
      '${dir.path}/openvalut-${info.versionName}-${info.versionCode}.${_artifactExtension()}',
    );
    if (!file.existsSync() || file.lengthSync() != info.fileSize) {
      final resp = await http
          .get(Uri.parse(info.downloadUrl))
          .timeout(const Duration(minutes: 10));
      if (resp.statusCode != 200) {
        throw HttpException('download failed: ${resp.statusCode}');
      }
      await file.writeAsBytes(resp.bodyBytes, flush: true);
    }
    if (info.sha256.isNotEmpty) {
      final actual = _sha256Hex(await file.readAsBytes());
      if (actual.toLowerCase() != info.sha256.toLowerCase()) {
        await file.delete();
        throw StateError(
          AppLocale.isChinese
              ? 'APK 校验失败，请重试'
              : 'APK verification failed. Try again.',
        );
      }
    }
    if (Platform.isAndroid) {
      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        throw StateError(
          AppLocale.isChinese
              ? '无法打开安装器: ${result.message}'
              : 'Could not open the installer: ${result.message}',
        );
      }
    }
    return file.path;
  }

  static String _artifactExtension() {
    if (Platform.isAndroid) return 'apk';
    if (Platform.isLinux) return 'deb';
    if (Platform.isMacOS) return 'dmg';
    if (Platform.isWindows) return 'msi';
    return 'bin';
  }

  static String _sha256Hex(Uint8List bytes) {
    final digest = SHA256Digest();
    final out = Uint8List(32);
    digest.update(bytes, 0, bytes.length);
    digest.doFinal(out, 0);
    return out.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
