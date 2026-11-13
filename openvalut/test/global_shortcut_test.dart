import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openvalut/ui/widgets/shortcut/openvalut_intents.dart';

void main() {
  testWidgets(
    'Actions.maybeInvoke from a descendant context finds the registered action',
    (tester) async {
      var invoked = false;
      BuildContext? descendantContext;

      await tester.pumpWidget(
        Actions(
          actions: {
            SearchIntent: CallbackAction(
              onInvoke: (intent) {
                invoked = true;
                return null;
              },
            ),
          },
          child: Builder(
            builder: (context) {
              // Mirrors the KeyboardHandler fix: capture a context below the
              // Actions widget, because Actions.maybeInvoke only walks
              // ancestors.
              descendantContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      Actions.maybeInvoke(descendantContext!, const SearchIntent());
      expect(invoked, isTrue);
    },
  );
}
