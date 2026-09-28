import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/network/supabase_config.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';
import 'package:memox/core/sync/delete_batch_sync_adapter.dart';
import 'package:memox/core/sync/supabase_sync_api.dart';
import 'package:memox/core/sync/sync_commands.dart';
import 'package:memox/core/sync/sync_api.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_scheduler.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'sync_providers.g.dart';

@Riverpod(keepAlive: true)
SupabaseConfig supabaseConfig(Ref ref) => SupabaseConfig.environment;

/// Sync through the Supabase project; main.dart has initialized the client.
@Riverpod(keepAlive: true)
SyncApi syncApi(Ref ref) {
  final client = Supabase.instance.client;
  return SupabaseSyncApi(
    ensureSession: () async {
      if (client.auth.currentSession != null) {
        return;
      }
      await client.auth.signInAnonymously();
    },
    rpc: (function, params) => client.rpc<Object?>(function, params: params),
  );
}

@Riverpod(keepAlive: true)
SyncStore syncStore(Ref ref) => SyncStore(ref.watch(databaseProvider));

@Riverpod(keepAlive: true)
SyncCoordinator syncCoordinator(Ref ref) {
  final db = ref.watch(databaseProvider);
  return SyncCoordinator(
    api: ref.watch(syncApiProvider),
    store: ref.watch(syncStoreProvider),
    adapters: [DeckSyncAdapter(db), DeleteBatchSyncAdapter(db)],
    now: ref.watch(dayClockProvider).now,
  );
}

/// The running sync, or null when this build names no Supabase project.
@Riverpod(keepAlive: true)
SyncScheduler? syncScheduler(Ref ref) {
  if (!ref.watch(supabaseConfigProvider).isEnabled) {
    return null;
  }
  final store = ref.watch(syncStoreProvider);
  final clock = ref.watch(dayClockProvider);
  final online = Connectivity().onConnectivityChanged
      .where((results) => !results.contains(ConnectivityResult.none))
      .map((_) {});
  final scheduler = SyncScheduler(
    run: ref.watch(syncCoordinatorProvider).runOnce,
    triggers: store.outboxChanges().skip(1),
    reconnects: online,
    onSucceeded: () => store.recordSuccess(clock.now()),
    onFailed: (error) =>
        store.recordFailure(classifySyncFailure(error), clock.now()),
  )..start();
  ref.onDispose(scheduler.dispose);
  return scheduler;
}

/// What sync has done (screens 13, 23, 27); null when sync is off. Kept
/// alive: three screens read it and the Drift stream is cheap.
@Riverpod(keepAlive: true)
Stream<SyncStatus?> syncStatus(Ref ref) {
  if (!ref.watch(supabaseConfigProvider).isEnabled) {
    return Stream.value(null);
  }
  return ref.watch(syncStoreProvider).watchStatus();
}

/// Screen 27's commands; null when sync is off.
@Riverpod(keepAlive: true)
SyncCommands? syncCommands(Ref ref) {
  final scheduler = ref.watch(syncSchedulerProvider);
  if (scheduler == null) return null;
  return SyncCommands(
    scheduler: scheduler,
    coordinator: ref.watch(syncCoordinatorProvider),
    store: ref.watch(syncStoreProvider),
  );
}
