import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/network/supabase_config.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';
import 'package:memox/core/sync/delete_batch_sync_adapter.dart';
import 'package:memox/core/sync/supabase_sync_api.dart';
import 'package:memox/core/sync/sync_api.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_scheduler.dart';
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

/// The running sync, or null when this build names no Supabase project.
@Riverpod(keepAlive: true)
SyncScheduler? syncScheduler(Ref ref) {
  if (!ref.watch(supabaseConfigProvider).isEnabled) {
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
    triggers: store.outboxChanges().skip(1),
    reconnects: online,
  )..start();
  ref.onDispose(scheduler.dispose);
  return scheduler;
}
