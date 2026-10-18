import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// For a plain test (no WidgetTester): what reaches
/// `FlutterError.reportError` from here on, until the test ends. A widget
/// test takes it with `expectBugReported` instead (test/support/held_bug.dart).
List<FlutterErrorDetails> captureReportedBugs() {
  final reported = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = reported.add;
  addTearDown(() => FlutterError.onError = previous);
  return reported;
}

/// The bug reached `FlutterError.reportError` once, as itself: a
/// `heldBug()` unless [bug] says what else was thrown.
void expectOneBugReported(List<FlutterErrorDetails> reported, {Matcher? bug}) =>
    expect(reported.single.exception, bug ?? isA<StateError>());
