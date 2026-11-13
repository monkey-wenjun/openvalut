import 'package:autofill_service/autofill_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/utils/platform.dart';

final _logger = Logger('autofill_prefs');

/// The autofill preferences the Android autofill service reads, mirrored for the UI.
///
/// Deliberately *not* stored in `SharedPreferences`: the service reads
/// `design.codeux.autofill.prefs` through `AutofillPreferenceStore`, a different
/// file than the shared_preferences plugin's default store. A Dart-side copy
/// would be a second source of truth and the ignore list would silently never
/// take effect. Both the service and this activity run in the same process (the
/// `<service>` has no `android:process`), and the store is a singleton, so
/// `setPreferences` is visible to the very next fill request.
class AutofillPrefs {
  AutofillPrefs._();

  /// Apps that must never see an autofill suggestion, lowercased package names.
  static final ValueNotifier<Set<String>> ignoredPackages =
      ValueNotifier<Set<String>>(const <String>{});

  static AutofillPreferences _current = const AutofillPreferences();

  /// False when the platform channel is not there (non-Android builds, or an
  /// API level below the plugin's method-call handler). Writes are dropped in
  /// that case rather than throwing at every settings visit.
  static bool _available = false;

  static Future<void> load() async {
    if (!OpenValutPlatform.isAndroid) {
      return;
    }
    try {
      _current = await AutofillService().getPreferences();
      _available = true;
      ignoredPackages.value = _current.ignoredPackages;
    } on MissingPluginException catch (e) {
      _logger.info('Autofill preferences not available: $e');
    } catch (e, st) {
      _logger.warning('Unable to read autofill preferences', e, st);
    }
  }

  static Future<void> setIgnoredPackages(Set<String> packages) async {
    final next = _current.copyWith(
      ignoredPackages: packages.map((e) => e.toLowerCase()).toSet(),
    );
    if (!_available) {
      // Keep the notifier in sync so this screen does not look broken even
      // when the write had nowhere to go.
      _current = next;
      ignoredPackages.value = next.ignoredPackages;
      return;
    }
    await AutofillService().setPreferences(next);
    _current = next;
    ignoredPackages.value = next.ignoredPackages;
  }
}
