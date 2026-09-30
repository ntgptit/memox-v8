import 'package:memox/core/error/failure.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_scheduler.dart';
import 'package:memox/core/sync/sync_store.dart';

/// What the account coordinator needs from sync (auth spec §5).
abstract interface class SyncControl {
  /// No scheduled run starts; completes once a run in progress ended.
  Future<void> pause();

  void resume();

  Future<int> pendingCount();

  /// Pushes the outbox until it is empty.
  Future<void> pushPending();

  /// Pulls the whole library from version 0.
  Future<void> pullAll();

  /// Queues every local row, and the cursor back to 0 (#12).
  Future<void> markAllPending();
}

/// [SyncControl] over the app's scheduler, coordinator and store. A call
/// that never reached the server throws [OfflineFailure]; any other
/// transport error, [ServerFailure].
class AppSyncControl implements SyncControl {
  AppSyncControl({
    required this._scheduler,
    required this._coordinator,
    required this._store,
  });

  final SyncScheduler? _scheduler;
  final SyncCoordinator _coordinator;
  final SyncStore _store;

  @override
  Future<void> pause() => _scheduler?.pause() ?? Future<void>.value();

  @override
  void resume() => _scheduler?.resume();

  /// The outbox and the rows the server refused without a copy of its own:
  /// both exist on this device only (sync status spec §4, final review I2).
  @override
  Future<int> pendingCount() async =>
      await _store.pendingCount() + (await _store.rejections()).length;

  /// Throws [UnsentChangesFailure] when rows are still unsent after the
  /// push: refused ones, or ones the server did not answer.
  @override
  Future<void> pushPending() async {
    await _mapped(_coordinator.pushAll);
    final left = await pendingCount();
    if (left > 0) throw UnsentChangesFailure(count: left);
  }

  @override
  Future<void> pullAll() => _mapped(_coordinator.pullAll);

  @override
  Future<void> markAllPending() => _store.markAllPending();

  static Future<void> _mapped(Future<void> Function() call) async {
    try {
      await call();
    } on Failure {
      rethrow;
    } on Object catch (error, stackTrace) {
      final failure = classifySyncFailure(error) == SyncFailureKind.network
          ? OfflineFailure(cause: error)
          : ServerFailure(cause: error);
      Error.throwWithStackTrace(failure, stackTrace);
    }
  }
}
