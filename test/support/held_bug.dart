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
