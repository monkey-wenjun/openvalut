import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _logger = Logger('installed_apps');

/// Same channel MainActivity registers for autofill metadata and keep-alive.
const _miscChannel = MethodChannel('app.openvalut/misc');

/// A user-launchable Android app, as shown in the launcher.
class InstalledApp {
  const InstalledApp({required this.label, required this.packageName});

  final String label;
  final String packageName;
}

/// Apps the user can open, label + packageName, sorted by label.
///
/// The entry editor uses this to link a credential to a native app without
/// the user having to type a package name. Only meaningful on Android; other
/// platforms return an empty list.
Future<List<InstalledApp>> fetchInstalledApps() async {
  if (!Platform.isAndroid) {
    return const [];
  }
  try {
    final result =
        await _miscChannel.invokeListMethod<dynamic>('getInstalledApps');
    if (result == null) {
      return const [];
    }
    return [
      for (final raw in result)
        if (raw is Map)
          InstalledApp(
            label: raw['label']?.toString() ?? '',
            packageName: raw['packageName']?.toString() ?? '',
          ),
    ];
  } catch (e) {
    _logger.warning('Unable to list installed apps: $e');
    return const [];
  }
}
