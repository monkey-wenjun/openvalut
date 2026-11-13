import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Desktop-only preference: keep the category sidebar permanently visible on
/// the left instead of using the collapsible drawer.
class SidebarPrefs {
  SidebarPrefs._();

  static const _key = 'persistent_sidebar_enabled';

  /// Live preference value; the password list listens to this so toggling the
  /// setting takes effect immediately without rebuilding the screen.
  static final ValueNotifier<bool> persistentEnabled = ValueNotifier(true);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    persistentEnabled.value = prefs.getBool(_key) ?? true;
  }

  static Future<void> setPersistentEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
    persistentEnabled.value = value;
  }
}
