import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

// A held write that meets a bug, not a Failure (ADR-016, LIB-6): the flow
// gets its way out back and the bug reaches the logger.

/// What a use case throws when it has a bug.
StateError heldBug() => StateError('a bug, not a Failure');

/// The bug reached `FlutterError.reportError` once, as itself. The binding
/// keeps it for the test to take, where a test that swapped `onError` would
/// hang on its own failure.
void expectBugReported(WidgetTester tester) =>
    expect(tester.takeException(), isA<StateError>());

/// Taps [finder] and settles; answers what the async work the tap started
/// threw uncaught. In the app it reaches `PlatformDispatcher.onError`; the
/// test zone would fail the test on it instead (REG-HELD-SCOPE).
Future<List<Object>> tapKeepingUncaught(
  WidgetTester tester,
  Finder finder,
) async {
  final uncaught = <Object>[];
  await runZonedGuarded(
    () => tester.tap(finder),
    (error, _) => uncaught.add(error),
  );
  await tester.pumpAndSettle();
  return uncaught;
}

/// What `showMxSnackbar` throws with no toast host: the bug a test puts
/// after a landed write.
final Matcher isToastHostMissing = isA<FlutterError>().having(
  (error) => error.message,
  'message',
  contains('MxToastHost'),
);

/// Taps [finder], whose write lands and whose toast then meets its bug (the
/// screen pumped without a toast host): the bug is left uncaught as itself.
Future<void> tapThroughToastBug(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  final uncaught = await tapKeepingUncaught(tester, finder);
  expect(uncaught, [isToastHostMissing]);
}
