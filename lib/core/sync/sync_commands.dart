import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_scheduler.dart';
import 'package:memox/core/sync/sync_store.dart';

/// Screen 27's three commands, over the running sync (sync status spec §5.2).
class SyncCommands {
  SyncCommands({
    required this._scheduler,
    required this._coordinator,
    required this._store,
  });

  final SyncScheduler _scheduler;
  final SyncCoordinator _coordinator;
  final SyncStore _store;

  Future<bool> syncNow() => _scheduler.syncNow();

  /// Try again: the refused rows go back to the outbox, then a run.
  Future<bool> retryRejected() async {
    await _coordinator.requeueRejected();
    return _scheduler.syncNow();
  }

  /// Keep on this device (R7).
  Future<void> keepRejectedOnDevice() => _store.forgetRejected();
}
