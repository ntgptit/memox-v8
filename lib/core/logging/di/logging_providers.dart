import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:memox/core/database/connection.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/console_sink.dart';
import 'package:memox/core/logging/log_api.dart';
import 'package:memox/core/logging/log_shipper.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/core/sync/sync_scheduler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'logging_providers.g.dart';

/// The device's log buffer (ADR-018 §3).
@Riverpod(keepAlive: true)
LogDatabase logDatabase(Ref ref) {
  final db = openLogDatabase();
  ref.onDispose(db.close);
  return db;
}

/// `log_push` through the Supabase project; main.dart has initialized it.
/// It waits for sync's session instead of signing in.
@Riverpod(keepAlive: true)
LogApi logApi(Ref ref) {
  final client = Supabase.instance.client;
  return LogApi(
    ensureSession: existingSessionOnly(
      () => client.auth.currentSession != null,
    ),
    rpc: (function, params) => client.rpc<Object?>(function, params: params),
  );
}

/// Pushes the buffer at start, every [_every] and when the network returns,
/// backing off like sync; null when this build names no Supabase project.
@Riverpod(keepAlive: true)
SyncScheduler? logScheduler(Ref ref) {
  if (!ref.watch(supabaseConfigProvider).isEnabled) return null;
  final shipper = LogShipper(
    ref.watch(logDatabaseProvider),
    ref.watch(logApiProvider),
  );
  final online = Connectivity().onConnectivityChanged
      .where((results) => !results.contains(ConnectivityResult.none))
      .map((_) {});
  final scheduler = SyncScheduler(
    run: shipper.runOnce,
    triggers: Stream<void>.periodic(_every),
    reconnects: online,
    // A failed push logs to the console only: into the buffer, it would grow
    // what it failed to empty (ADR-018 §3).
    logger: AppLogger(sinks: const [ConsoleSink()]),
  )..start();
  ref.onDispose(scheduler.dispose);
  return scheduler;
}

const _every = Duration(minutes: 5);
