import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/ui/widgets/shortcut/openvalut_intents.dart';
import 'package:openvalut/utils/constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

typedef LabelProvider = String Function(AppLocalizations loc);

final defaultOpenValutShortcuts = [
  OpenValutShortcut.def(
    key: LogicalKeyboardKey.keyF,
    intent: const SearchIntent(),
    label: (loc) => loc.searchButtonLabel,
  ),
  OpenValutShortcut.def(
    key: LogicalKeyboardKey.keyB,
    intent: CopyUsernameIntent(),
    label: (loc) => loc.shortcutCopyUsername,
  ),
  OpenValutShortcut.def(
    key: LogicalKeyboardKey.keyC,
    intent: CopyPasswordIntent(),
    label: (loc) => loc.shortcutCopyPassword,
  ),
  OpenValutShortcut.def(
    key: LogicalKeyboardKey.keyT,
    intent: CopyTotpIntent(),
    label: (loc) => loc.shortcutCopyTotp,
  ),
  OpenValutShortcut.all(
    key: const SingleActivator(LogicalKeyboardKey.arrowUp),
    intent: MoveUpIntent(),
    label: (loc) => loc.shortcutMoveUp,
  ),
  OpenValutShortcut.all(
    key: const SingleActivator(LogicalKeyboardKey.keyP, control: true),
    intent: MoveUpIntent(),
    label: (loc) => loc.shortcutMoveUp,
  ),
  OpenValutShortcut.all(
    key: const SingleActivator(LogicalKeyboardKey.arrowDown),
    intent: MoveDownIntent(),
    label: (loc) => loc.shortcutMoveDown,
  ),
  OpenValutShortcut.all(
    key: const SingleActivator(LogicalKeyboardKey.keyN, control: true),
    intent: MoveDownIntent(),
    label: (loc) => loc.shortcutMoveDown,
  ),
  OpenValutShortcut.def(
    key: LogicalKeyboardKey.keyG,
    intent: GeneratePasswordIntent(),
    label: (loc) => loc.shortcutGeneratePassword,
  ),
  OpenValutShortcut.def(
    key: LogicalKeyboardKey.keyU,
    intent: CopyUrlIntent(),
    label: (loc) => loc.shortcutCopyUrl,
  ),
  OpenValutShortcut.def(
    key: LogicalKeyboardKey.keyO,
    intent: OpenUrlIntent(),
    label: (loc) => loc.shortcutOpenUrl,
  ),
  OpenValutShortcut.all(
    key: const SingleActivator(LogicalKeyboardKey.escape),
    intent: CancelSearchFilterIntent(),
    label: (loc) => loc.shortcutCancelSearch,
  ),
  OpenValutShortcut.all(
    key: const CharacterActivator(CharConstants.questionMark),
    intent: KeyboardShortcutHelpIntent(),
    label: (loc) => loc.shortcutShortcutHelp,
  ),
];

class OpenValutShortcut {
  const OpenValutShortcut({
    required this.mac,
    required this.linux,
    required this.windows,
    required this.intent,
    required this.label,
  });
  OpenValutShortcut.def({
    required LogicalKeyboardKey key,
    required Intent intent,
    required LabelProvider label,
  }) : this(
         mac: SingleActivator(key, meta: true),
         linux: SingleActivator(key, control: true),
         windows: SingleActivator(key, control: true),
         intent: intent,
         label: label,
       );
  OpenValutShortcut.all({
    required ShortcutActivator key,
    required Intent intent,
    required LabelProvider label,
  }) : this(
         mac: key,
         linux: key,
         windows: key,
         intent: intent,
         label: label,
       );

  final ShortcutActivator mac;
  final ShortcutActivator linux;
  final ShortcutActivator windows;
  final Intent intent;
  final LabelProvider label;

  ShortcutActivator triggerForPlatform(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
        return linux;
      case TargetPlatform.iOS:
        return mac;
      case TargetPlatform.macOS:
        return mac;
      case TargetPlatform.windows:
        return windows;
    }
  }
}
