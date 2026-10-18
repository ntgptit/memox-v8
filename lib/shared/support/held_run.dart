import 'package:flutter/foundation.dart';
import 'package:memox/core/error/failure.dart';

/// Runs [work] for a held flow: a dialog, sheet or screen that waits for it
/// and offers no way out meanwhile. A [Failure] goes to [onFailed]; so does a
/// bug, anything else, as null once reported (ADR-016). Either way the flow
/// gets its way out back, and is never held for good.
Future<void> runHeld(
  Future<void> Function() work, {
  required void Function(Failure? failure) onFailed,
}) async {
  try {
    await work();
  } on Failure catch (failure) {
    onFailed(failure);
  } on Object catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stackTrace),
    );
    onFailed(null);
  }
}
