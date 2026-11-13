import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the delete-snackbar workaround in entry_details.dart: hide the
/// snackbar explicitly after 1s unless it already closed on its own.
void showDeleteSnackBar(BuildContext menuContext) {
  final messenger = ScaffoldMessenger.of(menuContext);
  final navigator = Navigator.of(menuContext);
  navigator.pop();
  final controller = messenger.showSnackBar(
    const SnackBar(
      content: Text('deleted'),
      behavior: SnackBarBehavior.fixed,
      duration: Duration(seconds: 1),
    ),
  );
  var snackBarClosed = false;
  controller.closed.then(
    (_) => snackBarClosed = true,
    onError: (_) => snackBarClosed = true,
  );
  Timer(const Duration(seconds: 1), () {
    if (!snackBarClosed) {
      messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.timeout);
    }
  });
}

Widget buildApp({bool nestedNavigator = false}) {
  Widget listScreen() => Scaffold(
    body: Center(
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Builder(
                  builder: (detailsContext) => Scaffold(
                    appBar: AppBar(
                      actions: [
                        PopupMenuButton<VoidCallback>(
                          onSelected: (value) => value(),
                          itemBuilder: (menuContext) => [
                            PopupMenuItem<VoidCallback>(
                              value: () => showDeleteSnackBar(menuContext),
                              child: const ListTile(title: Text('delete')),
                            ),
                          ],
                        ),
                      ],
                    ),
                    body: const Center(child: Text('details')),
                  ),
                ),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ),
  );

  return MaterialApp(
    home: nestedNavigator
        ? Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => listScreen(),
            ),
          )
        : listScreen(),
  );
}

Future<void> deleteAndCheckDismiss(
  WidgetTester tester, {
  required int cycles,
}) async {
  await tester.pumpWidget(buildApp(nestedNavigator: cycles == 3));
  for (var cycle = 0; cycle < cycles; cycle++) {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<VoidCallback>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('delete'));
    await tester.pumpAndSettle();

    expect(find.text('deleted'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('deleted'), findsNothing);
  }
}

void main() {
  testWidgets('delete snackbar auto-dismisses after popup menu pop', (
    tester,
  ) async {
    await deleteAndCheckDismiss(tester, cycles: 1);
  });

  testWidgets('delete snackbar auto-dismisses on every delete', (tester) async {
    await deleteAndCheckDismiss(tester, cycles: 2);
  });

  testWidgets('delete snackbar dismisses inside a nested navigator', (
    tester,
  ) async {
    await deleteAndCheckDismiss(tester, cycles: 3);
  });
}
