import 'package:shared_preferences/shared_preferences.dart';

/// Preferences for tracking incoming shares that have already been
/// automatically saved into the recipient's vault.
class SharePrefs {
  SharePrefs._();

  static const _autoSavedShareIdsKey = 'auto_saved_share_ids'; // NON-NLS

  /// Returns the set of incoming share ids already auto-saved locally.
  static Future<Set<String>> getAutoSavedShareIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_autoSavedShareIdsKey)?.toSet() ?? {};
  }

  /// Marks [shareId] as having been auto-saved so it is not saved again.
  static Future<void> markAutoSaved(String shareId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await getAutoSavedShareIds();
    ids.add(shareId);
    await prefs.setStringList(_autoSavedShareIdsKey, ids.toList());
  }
}
