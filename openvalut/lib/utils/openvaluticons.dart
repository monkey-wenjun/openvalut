// Place fonts/OpenValutIcons.ttf in your fonts/ directory and
// add the following to your pubspec.yaml
// flutter:
//   fonts:
//    - family: OpenValutIcons
//      fonts:
//       - asset: fonts/OpenValutIcons.ttf
import 'package:flutter/widgets.dart';
import 'package:string_literal_finder_annotations/string_literal_finder_annotations.dart';

class OpenValutIcons {
  OpenValutIcons._();

  @NonNls
  static const String _fontFamily = 'OpenValutIcons';

  static const IconData OpenValutLogo = IconData(
    0xe900,
    fontFamily: _fontFamily,
  );
}
