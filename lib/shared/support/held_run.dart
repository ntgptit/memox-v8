import 'package:flutter/foundation.dart';
import 'package:memox/core/error/failure.dart';

/// Runs [write] for a held flow: a dialog, sheet or screen that waits for it
/// and offers no way out meanwhile. Returns what [write] returned, or null
/// once it failed: a [Failure] goes to [onFailed], and so does a bug,
/// anything else, as null once reported (ADR-016). Either way the flow gets
/// its way out back, and is never held for good. A write whose own result
/// can be null tells a failure apart in [onFailed].
///
/// [write] holds the write alone. What follows a write that landed (a toast,
/// a pop, a cleared form, the next state) runs after this returns, outside
/// it: a bug there is reported by the framework and never reads as a failed
/// write, which would offer Retry and write twice (closing acceptance
/// REG-HELD-SCOPE).
Future<T?> runHeld<T>(
  Future<T> Function() write, {
  required void Function(Failure? failure) onFailed,
}) async {
  try {
    return await write();
  } on Failure catch (failure) {
    onFailed(failure);
    return null;
  } on Object catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stackTrace),
    );
    onFailed(null);
    return null;
  }
}
