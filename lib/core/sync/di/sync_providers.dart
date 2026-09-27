import 'package:async/async.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/network/di/network_providers.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';
import 'package:memox/core/sync/delete_batch_sync_adapter.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_scheduler.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_providers.g.dart';

/// The running sync, or null when this build has no API_BASE_URL.
@Riverpod(keepAlive: true)
SyncScheduler? syncScheduler(Ref ref) {
  if (!ref.watch(apiConfigProvider).isEnabled) {
    return null;
  }
  final db = ref.watch(databaseProvider);
  final store = SyncStore(db);
  final coordinator = SyncCoordinator(
    api: ref.watch(syncApiProvider),
    store: store,
    adapters: [DeckSyncAdapter(db), DeleteBatchSyncAdapter(db)],
  );
  final online = Connectivity().onConnectivityChanged
      .where((results) => !results.contains(ConnectivityResult.none))
      .map((_) {});
  final scheduler = SyncScheduler(
    run: coordinator.runOnce,
    triggers: StreamGroup.merge([store.outboxChanges().skip(1), online]),
  )..start();
  ref.onDispose(scheduler.dispose);
  return scheduler;
}
