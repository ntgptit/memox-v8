import 'package:memox/core/error/failure.dart';

/// Shut while the account switches, signs out, is deleted or is cleared
/// (auth spec R3). Every business write passes [check] in
/// `mappedTransaction`. Sync's pull, the reset and the account store write
/// on their own paths, so they are not stopped by it.
class MutationGate {
  var _closed = false;

  bool get isClosed => _closed;

  void close() => _closed = true;

  void open() => _closed = false;

  /// Throws [MutationBlockedFailure] while shut.
  void check() {
    if (_closed) throw const MutationBlockedFailure();
  }
}
