/// Runs the reminder operations of this isolate one at a time: Enable,
/// Disable and Reconcile each read the stored reminder, touch the platform
/// and save, and two of them interleaved can leave the stored reminder and
/// the pending alarm out of step (reminders spec §14). The background
/// Deliver runs in its own isolate and is not gated: it reads the settings
/// at fire time, and an overlap costs at most one late reminder (D12).
final class ReminderOperationGate {
  Future<void> _tail = Future<void>.value();

  /// Runs [operation] after every operation started before it has ended,
  /// failed or not. Its result, or its error, goes to this caller only.
  Future<T> run<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
